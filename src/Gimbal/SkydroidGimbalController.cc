/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SkydroidGimbalController.h"

#include <QtCore/QTimer>
#include <QtNetwork/QUdpSocket>

#include "QGCLoggingCategory.h"
#include "SettingsManager.h"
#include "SkydroidGimbalSettings.h"
#include "SkydroidRcInput.h"
#include "Vehicle.h"
#include "VideoSettings.h"

QGC_LOGGING_CATEGORY(SkydroidGimbalLog, "qgc.gimbal.skydroid")

namespace {
// The pod holds the last speed it was given, so a dropped datagram would leave
// the gimbal running. Resending the current state covers that and doubles as a
// keepalive.
constexpr int kRepeatIntervalMs = 200;

// Every command below is taken from Skydroid's own RCSDK, which drives the same pods:
// the gimbal ones from SkydroidGimbalControlCore, the camera ones from TopCameraCore.
constexpr const char *kPitchVerb = "#TPUG2wGSP";   // controlPitch: speed
constexpr const char *kYawVerb   = "#TPUG2wGSY";   // controlYaw: speed
constexpr const char *kVersion   = "#TPUD2rVER00"; // getCameraVersion

// Digital zoom (addZoomRatios / subtractZoomRatios). Each is a single step, so a held
// control repeats them, and there is no stop to send.
//
// #TPUG2wPTZ0A/0B used to be sent here as zoom. They are setGimbalAssemblyMode, so every
// zoom press re-set how the gimbal thinks it is mounted, which is what turned it over.
constexpr const char *kZoomIn  = "#TPUD2wDZM0A";
constexpr const char *kZoomOut = "#TPUD2wDZM0B";

constexpr const char *kCentre   = "#TPUG2wPTZ05";  // akey(MID)
constexpr const char *kLookDown = "#TPUG2wPTZ02";  // akey(DOWN)

constexpr const char *kMountHanging  = "#TPUG2wPTZ0A"; // setGimbalAssemblyMode(HOISTING)
constexpr const char *kMountInverted = "#TPUG2wPTZ0B"; // setGimbalAssemblyMode(INVERSION)

constexpr const char *kTakePhoto   = "#TPUD2wCAP01";   // takePicture
constexpr const char *kRecordStart = "#TPUD2wREC01";   // startRecordVideo
constexpr const char *kRecordStop  = "#TPUD2wREC00";   // stopRecordVideo
constexpr const char *kRecordQuery = "#TPUD2rREC00";   // getRecordVideoState

// Long enough for the pod to have acted on a record command before asking it what it
// is doing, so the button shows the camera's own state rather than a guess.
constexpr int kRecordQueryDelayMs = 500;

// The pod keeps the last speed it was given and _repeatTimer keeps resending it, so if
// RC input stops arriving while a stick is deflected the gimbal would turn until it
// came back. Past these ages a source counts as gone and anything it set moving stops.
//
// RC_CHANNELS from an autopilot over a telemetry radio can be as slow as 1-2 Hz, so the
// vehicle gets long enough not to cut in between normal packets. The remote controller
// is polled locally every 100 ms, so a few missed polls already mean it has stopped.
constexpr int kVehicleRcStaleMs = 2000;
constexpr int kRemoteRcStaleMs = 500;
constexpr int kRcWatchdogIntervalMs = 100;
}

SkydroidGimbalController::SkydroidGimbalController(QObject *parent)
    : QObject(parent)
{
    _repeatTimer = new QTimer(this);
    _repeatTimer->setInterval(kRepeatIntervalMs);
    connect(_repeatTimer, &QTimer::timeout, this, [this]() {
        if ((_pitchSpeed != 0) || (_yawSpeed != 0)) {
            _send(speedCommand(kPitchVerb, _pitchSpeed));
            _send(speedCommand(kYawVerb, _yawSpeed));
        }
        if (_zoomDirection > 0) {
            _send(kZoomIn);
        } else if (_zoomDirection < 0) {
            _send(kZoomOut);
        }
    });

    _rcWatchdog = new QTimer(this);
    _rcWatchdog->setInterval(kRcWatchdogIntervalMs);
    connect(_rcWatchdog, &QTimer::timeout, this, &SkydroidGimbalController::_checkRcStale);
    _rcWatchdog->start();

    _rcInput = new SkydroidRcInput(this);
    connect(_rcInput, &SkydroidRcInput::channelsReceived, this, &SkydroidGimbalController::_remoteChannels);
    connect(_rcInput, &SkydroidRcInput::stateChanged, this, &SkydroidGimbalController::rcChanged);

    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();
    connect(settings->rcControlEnabled(), &Fact::rawValueChanged, this, &SkydroidGimbalController::_rcControlEnabledChanged);
    connect(settings->enabled(), &Fact::rawValueChanged, this, &SkydroidGimbalController::_settingsChanged);
    connect(settings->address(), &Fact::rawValueChanged, this, &SkydroidGimbalController::_settingsChanged);
    connect(settings->port(),    &Fact::rawValueChanged, this, &SkydroidGimbalController::_settingsChanged);

    VideoSettings *videoSettings = SettingsManager::instance()->videoSettings();
    connect(videoSettings->rtspUrl(),     &Fact::rawValueChanged, this, &SkydroidGimbalController::thermalChanged);
    connect(videoSettings->videoSource(), &Fact::rawValueChanged, this, &SkydroidGimbalController::thermalChanged);
    connect(settings->thermalRtspUrl(),   &Fact::rawValueChanged, this, &SkydroidGimbalController::thermalChanged);

    _settingsChanged();
}

SkydroidGimbalController::~SkydroidGimbalController()
{
    _closeSocket();
}

QString SkydroidGimbalController::checksumHex(const QByteArray &body)
{
    quint8 sum = 0;
    for (const char c : body) {
        sum = static_cast<quint8>(sum + static_cast<quint8>(c));
    }
    return QStringLiteral("%1").arg(sum, 2, 16, QLatin1Char('0')).toUpper();
}

QByteArray SkydroidGimbalController::buildCommand(const QString &body)
{
    const QByteArray raw = body.toLatin1();
    return raw + checksumHex(raw).toLatin1();
}

QString SkydroidGimbalController::speedCommand(const QString &verb, int speed)
{
    const int clamped = qBound(-128, speed, 127);
    const quint8 asByte = static_cast<quint8>(static_cast<qint8>(clamped));
    return verb + QStringLiteral("%1").arg(asByte, 2, 16, QLatin1Char('0')).toUpper();
}

bool SkydroidGimbalController::parseReply(const QByteArray &datagram, QString *command, QString *data)
{
    // "#TP" + src + dst + length + r/w + 3 letter command, then data and 2 checksum digits
    constexpr int kHeaderLength = 10;
    constexpr int kChecksumLength = 2;

    const QByteArray frame = datagram.trimmed();
    if (!frame.startsWith("#TP") || (frame.size() < kHeaderLength + kChecksumLength)) {
        return false;
    }

    bool ok = false;
    const int dataLength = QByteArray(1, frame.at(5)).toInt(&ok, 16);
    if (!ok || (frame.size() != kHeaderLength + dataLength + kChecksumLength)) {
        return false;
    }

    const QByteArray body = frame.left(kHeaderLength + dataLength);
    if (checksumHex(body).toLatin1() != frame.right(kChecksumLength).toUpper()) {
        return false;
    }

    if (command) {
        *command = QString::fromLatin1(frame.mid(7, 3));
    }
    if (data) {
        *data = QString::fromLatin1(frame.mid(kHeaderLength, dataLength));
    }
    return true;
}

bool SkydroidGimbalController::thermalAvailable() const
{
    VideoSettings *videoSettings = SettingsManager::instance()->videoSettings();
    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();

    return (videoSettings->videoSource()->rawValue().toString() == QString::fromLatin1(VideoSettings::videoSourceRTSP))
           && !settings->thermalRtspUrl()->rawValue().toString().trimmed().isEmpty();
}

bool SkydroidGimbalController::thermalView() const
{
    if (!thermalAvailable()) {
        return false;
    }

    const QString url = SettingsManager::instance()->videoSettings()->rtspUrl()->rawValue().toString().trimmed();
    return url == SettingsManager::instance()->skydroidGimbalSettings()->thermalRtspUrl()->rawValue().toString().trimmed();
}

void SkydroidGimbalController::toggleThermal()
{
    if (!thermalAvailable()) {
        qCWarning(SkydroidGimbalLog) << "Thermal view needs an RTSP video source and a thermal stream URL";
        return;
    }

    // The two URLs are set outright rather than derived from one another: the C13's
    // thermal stream is on a different port as well as a different path, and a guess
    // from the current URL got the port wrong. Whatever the video was set to, this
    // always lands on one of the two known-good streams.
    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();
    const QString url = thermalView() ? settings->visibleRtspUrl()->rawValue().toString().trimmed()
                                      : settings->thermalRtspUrl()->rawValue().toString().trimmed();
    if (url.isEmpty()) {
        qCWarning(SkydroidGimbalLog) << "No visible camera stream URL to switch back to";
        return;
    }

    qCDebug(SkydroidGimbalLog) << "Switching video to" << url;
    // VideoManager restarts the stream on its own when the URL changes.
    SettingsManager::instance()->videoSettings()->rtspUrl()->setRawValue(url);
}

void SkydroidGimbalController::_settingsChanged()
{
    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();

    _updateRcInputActive();
    _closeSocket();

    if (!settings->enabled()->rawValue().toBool()) {
        _pitchSpeed = 0;
        _yawSpeed = 0;
        _zoomDirection = 0;
        _rcCmdPitch = 0;
        _rcCmdYaw = 0;
        _rcCmdZoom = 0;
        return;
    }

    _target = QHostAddress(settings->address()->rawValue().toString());
    _port   = static_cast<quint16>(settings->port()->rawValue().toUInt());

    if (_target.isNull() || (_port == 0)) {
        qCWarning(SkydroidGimbalLog) << "Bad pod address or port:"
                                     << settings->address()->rawValue().toString() << _port;
        return;
    }

    _openSocket();
}

void SkydroidGimbalController::_openSocket()
{
    if (_socket) {
        return;
    }

    _socket = new QUdpSocket(this);
    // The stock ground station lets the OS pick the source port, so the pod
    // replies to whatever it was addressed from.
    if (!_socket->bind()) {
        qCWarning(SkydroidGimbalLog) << "Could not bind a local socket:" << _socket->errorString();
        _socket->deleteLater();
        _socket = nullptr;
        return;
    }

    connect(_socket, &QUdpSocket::readyRead, this, &SkydroidGimbalController::_readPendingDatagrams);
    _repeatTimer->start();

    qCDebug(SkydroidGimbalLog) << "Talking to pod at" << _target.toString() << _port;
    queryVersion();
    _send(QString::fromLatin1(kRecordQuery));
}

void SkydroidGimbalController::_closeSocket()
{
    _repeatTimer->stop();

    if (_socket) {
        _socket->deleteLater();
        _socket = nullptr;
    }

    if (_active) {
        _active = false;
        emit activeChanged();
    }
}

void SkydroidGimbalController::_send(const QString &body)
{
    if (!_socket) {
        return;
    }

    const QByteArray datagram = buildCommand(body);
    if (_socket->writeDatagram(datagram, _target, _port) < 0) {
        qCDebug(SkydroidGimbalLog) << "Send failed:" << _socket->errorString();
        return;
    }

    _sentCount++;
    emit sentCountChanged();
}

void SkydroidGimbalController::_readPendingDatagrams()
{
    while (_socket && _socket->hasPendingDatagrams()) {
        QByteArray datagram;
        datagram.resize(static_cast<int>(_socket->pendingDatagramSize()));
        _socket->readDatagram(datagram.data(), datagram.size());

        if (!_active) {
            _active = true;
            emit activeChanged();
        }

        const QString message = QString::fromLatin1(datagram);
        qCDebug(SkydroidGimbalLog) << "Pod says:" << message;
        emit podReply(message);

        QString command;
        QString data;
        if (parseReply(datagram, &command, &data) && (command == QStringLiteral("REC"))) {
            if (data == QStringLiteral("01")) {
                _setRecording(true);
            } else if (data == QStringLiteral("00")) {
                _setRecording(false);
            }
        }
    }
}

void SkydroidGimbalController::queryVersion()
{
    _send(QString::fromLatin1(kVersion));
}

void SkydroidGimbalController::setPitchSpeed(int speed)
{
    const int clamped = qBound(-128, speed, 127);
    if (clamped == _pitchSpeed) {
        return;
    }

    _pitchSpeed = clamped;
    _send(speedCommand(kPitchVerb, _pitchSpeed));
    emit speedChanged();
}

void SkydroidGimbalController::setYawSpeed(int speed)
{
    const int clamped = qBound(-128, speed, 127);
    if (clamped == _yawSpeed) {
        return;
    }

    _yawSpeed = clamped;
    _send(speedCommand(kYawVerb, _yawSpeed));
    emit speedChanged();
}

void SkydroidGimbalController::stopMotion()
{
    setPitchSpeed(0);
    setYawSpeed(0);
    zoomStop();
}

void SkydroidGimbalController::zoomIn()
{
    _setZoomDirection(1);
}

void SkydroidGimbalController::zoomOut()
{
    _setZoomDirection(-1);
}

void SkydroidGimbalController::zoomStop()
{
    _setZoomDirection(0);
}

void SkydroidGimbalController::_setZoomDirection(int direction)
{
    if (direction == _zoomDirection) {
        return;
    }

    _zoomDirection = direction;

    // Stopping is just no longer stepping: the camera has no zoom stop command.
    if (direction > 0) {
        _send(QString::fromLatin1(kZoomIn));
    } else if (direction < 0) {
        _send(QString::fromLatin1(kZoomOut));
    }

    emit zoomChanged();
}

void SkydroidGimbalController::centerGimbal()
{
    _send(QString::fromLatin1(kCentre));
}

void SkydroidGimbalController::lookDown()
{
    _send(QString::fromLatin1(kLookDown));
}

void SkydroidGimbalController::setMountHanging()
{
    _send(QString::fromLatin1(kMountHanging));
}

void SkydroidGimbalController::setMountInverted()
{
    _send(QString::fromLatin1(kMountInverted));
}

void SkydroidGimbalController::takePhoto()
{
    _send(QString::fromLatin1(kTakePhoto));
}

void SkydroidGimbalController::toggleRecording()
{
    if (!_socket) {
        return;
    }

    const bool start = !_recording;
    _send(QString::fromLatin1(start ? kRecordStart : kRecordStop));

    // Shown straight away so the button answers the press; the camera's own reply to
    // the query below has the last word.
    _setRecording(start);
    QTimer::singleShot(kRecordQueryDelayMs, this, [this]() {
        _send(QString::fromLatin1(kRecordQuery));
    });
}

void SkydroidGimbalController::_setRecording(bool recording)
{
    if (recording == _recording) {
        return;
    }

    _recording = recording;
    emit recordingChanged();
}

void SkydroidGimbalController::setVehicle(Vehicle *vehicle)
{
    if (_vehicle) {
        disconnect(_vehicle, &Vehicle::rcChannelsChanged, this, &SkydroidGimbalController::_rcChannelsChanged);
    }

    _vehicle = vehicle;

    if (_vehicle) {
        connect(_vehicle, &Vehicle::rcChannelsChanged, this, &SkydroidGimbalController::_rcChannelsChanged);
        qCDebug(SkydroidGimbalLog) << "Following vehicle" << _vehicle->id() << "for RC input";
    } else if (_rcSource != RcSourceRemote) {
        qCDebug(SkydroidGimbalLog) << "No vehicle: RC gimbal control from the vehicle is inactive";
        _rcChannelCount = 0;
        _rcPitchPwm = -1;
        _rcYawPwm = -1;
        _rcZoomPwm = -1;
        _rcSource = RcSourceNone;
        _stopRcMotion();
        stopMotion();
    }
    // With the remote controller as the source, losing the vehicle changes nothing:
    // those sticks never went through it.

    emit rcChanged();
}

bool SkydroidGimbalController::rcConnected() const
{
    return (_rcInput->state() == SkydroidRcInput::Connected) || !_vehicle.isNull();
}

int SkydroidGimbalController::rcInputState() const
{
    return _rcInput->state();
}

QString SkydroidGimbalController::rcInputMessage() const
{
    return _rcInput->message();
}

void SkydroidGimbalController::_updateRcInputActive()
{
    // The SDK holds a port for as long as it is connected, which keeps the Skydroid
    // assistant app from connecting, so it is only held while it is needed.
    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();
    _rcInput->setActive(settings->enabled()->rawValue().toBool() && settings->rcControlEnabled()->rawValue().toBool());
}

bool SkydroidGimbalController::_remoteFresh() const
{
    return _remoteLastSample.isValid() && (_remoteLastSample.elapsed() < kRemoteRcStaleMs);
}

void SkydroidGimbalController::_stopRcMotion()
{
    if (!_rcDriving()) {
        return;
    }

    _rcCmdPitch = 0;
    _rcCmdYaw = 0;
    _rcCmdZoom = 0;
    stopMotion();
}

void SkydroidGimbalController::_rcControlEnabledChanged()
{
    // Switching RC control off must not leave the gimbal turning at whatever the stick
    // was last holding: nothing would ever send the stop.
    if (!SettingsManager::instance()->skydroidGimbalSettings()->rcControlEnabled()->rawValue().toBool()) {
        _stopRcMotion();
    }

    _updateRcInputActive();
}

void SkydroidGimbalController::_checkRcStale()
{
    if (_rcSource == RcSourceNone) {
        return;
    }

    const int staleMs = (_rcSource == RcSourceRemote) ? kRemoteRcStaleMs : kVehicleRcStaleMs;
    if (_rcLastSample.isValid() && (_rcLastSample.elapsed() < staleMs)) {
        return;
    }

    if (_rcDriving()) {
        qCWarning(SkydroidGimbalLog) << "RC input stopped arriving while the sticks were moving the gimbal; stopping it";
        _stopRcMotion();
    }

    qCDebug(SkydroidGimbalLog) << "RC source" << _rcSource << "went quiet";
    _rcSource = RcSourceNone;
    emit rcChanged();
}

int SkydroidGimbalController::_rawChannel(int channel, int channelCount, const int *pwmValues)
{
    if ((channel <= 0) || (channel > channelCount) || (channel > QGCMAVLink::maxRcChannels)) {
        return -1;
    }

    // Vehicle reports a channel it is not driving as -1, and some receivers send
    // 0 or UINT16_MAX for the same thing.
    const int pwm = pwmValues[channel - 1];
    if ((pwm <= 0) || (pwm >= 65535)) {
        return -1;
    }

    return pwm;
}

int SkydroidGimbalController::_channelToSpeed(int channel, int channelCount, const int *pwmValues, bool reversed) const
{
    const int pwm = _rawChannel(channel, channelCount, pwmValues);
    if (pwm < 0) {
        return 0;
    }

    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();
    const int rcMin    = settings->rcMin()->rawValue().toInt();
    const int rcMax    = settings->rcMax()->rawValue().toInt();
    const int deadband = settings->rcDeadband()->rawValue().toInt();
    const int maxSpeed = settings->maxSpeed()->rawValue().toInt();

    const int halfRange = (rcMax - rcMin) / 2;
    if (halfRange <= deadband) {
        return 0;
    }

    const int centre = rcMin + halfRange;
    int offset = pwm - centre;

    if (qAbs(offset) <= deadband) {
        return 0;
    }

    // Take the deadband out of the travel so the speed starts from zero at its
    // edge rather than jumping.
    offset += (offset > 0) ? -deadband : deadband;

    const double scaled = static_cast<double>(offset) / static_cast<double>(halfRange - deadband);
    const int speed = qRound(qBound(-1.0, scaled, 1.0) * maxSpeed);

    return reversed ? -speed : speed;
}

void SkydroidGimbalController::_rcChannelsChanged(int channelCount, int pwmValues[QGCMAVLink::maxRcChannels])
{
    _processRc(RcSourceVehicle, channelCount, pwmValues);
}

void SkydroidGimbalController::_remoteChannels(const QList<int> &channels)
{
    int pwmValues[QGCMAVLink::maxRcChannels];
    const int channelCount = qMin(static_cast<int>(channels.size()), static_cast<int>(QGCMAVLink::maxRcChannels));
    for (int i = 0; i < QGCMAVLink::maxRcChannels; i++) {
        pwmValues[i] = (i < channelCount) ? channels.at(i) : -1;
    }

    _processRc(RcSourceRemote, channelCount, pwmValues);
}

void SkydroidGimbalController::_processRc(RcSource source, int channelCount, const int *pwmValues)
{
    if (source == RcSourceRemote) {
        _remoteLastSample.restart();
    } else if (_remoteFresh()) {
        // The same sticks, read straight off the controller every 100 ms, are already
        // coming in. The autopilot's copy is older and slower, so it is not mixed in.
        return;
    }

    if (source != _rcSource) {
        qCDebug(SkydroidGimbalLog) << "RC source now" << source;
        _rcSource = source;
    }
    _rcLastSample.restart();

    _rcChannels.resize(qBound(0, channelCount, static_cast<int>(QGCMAVLink::maxRcChannels)));
    for (int i = 0; i < _rcChannels.size(); i++) {
        _rcChannels[i] = pwmValues[i];
    }

    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();

    // Recorded before the enable checks, so the settings page can still show that
    // channels are arriving when control itself is switched off. "No RC_CHANNELS
    // at all" and "channels arrive but never leave the deadband" look identical
    // from the outside and need opposite fixes.
    _rcChannelCount = channelCount;
    _rcPitchPwm = _rawChannel(settings->pitchChannel()->rawValue().toInt(), channelCount, pwmValues);
    _rcYawPwm   = _rawChannel(settings->yawChannel()->rawValue().toInt(), channelCount, pwmValues);
    _rcZoomPwm  = _rawChannel(settings->zoomChannel()->rawValue().toInt(), channelCount, pwmValues);
    _rcUpdateCount++;
    emit rcChanged();

    if (!_rcLogThrottle.isValid() || (_rcLogThrottle.elapsed() > 1000)) {
        _rcLogThrottle.restart();
        qCDebug(SkydroidGimbalLog) << "RC source" << source << "chancount" << channelCount
                                   << "pitch ch" << settings->pitchChannel()->rawValue().toInt() << "=" << _rcPitchPwm
                                   << "yaw ch" << settings->yawChannel()->rawValue().toInt() << "=" << _rcYawPwm
                                   << "zoom ch" << settings->zoomChannel()->rawValue().toInt() << "=" << _rcZoomPwm
                                   << "| enabled" << settings->enabled()->rawValue().toBool()
                                   << "rcControl" << settings->rcControlEnabled()->rawValue().toBool();
    }

    if (!settings->enabled()->rawValue().toBool() || !settings->rcControlEnabled()->rawValue().toBool()) {
        return;
    }

    const int pitch = _channelToSpeed(settings->pitchChannel()->rawValue().toInt(), channelCount, pwmValues,
                                      settings->pitchReversed()->rawValue().toBool());
    const int yaw = _channelToSpeed(settings->yawChannel()->rawValue().toInt(), channelCount, pwmValues,
                                    settings->yawReversed()->rawValue().toBool());

    // Zoom is a rate, not a position: anything outside the deadband means keep
    // zooming that way until the knob comes back.
    const int zoomSpeed = _channelToSpeed(settings->zoomChannel()->rawValue().toInt(), channelCount, pwmValues, false);
    const int zoom = (zoomSpeed > 0) ? 1 : ((zoomSpeed < 0) ? -1 : 0);

    // Only a change in what the sticks ask for is applied. A centred stick reports the
    // same zero in every packet, and applying it each time would cancel a gimbal page
    // button while it is held down.
    if (pitch != _rcCmdPitch) {
        _rcCmdPitch = pitch;
        setPitchSpeed(pitch);
    }
    if (yaw != _rcCmdYaw) {
        _rcCmdYaw = yaw;
        setYawSpeed(yaw);
    }
    if (zoom != _rcCmdZoom) {
        _rcCmdZoom = zoom;
        _setZoomDirection(zoom);
    }
}

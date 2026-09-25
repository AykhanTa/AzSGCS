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
#include "Vehicle.h"

QGC_LOGGING_CATEGORY(SkydroidGimbalLog, "qgc.gimbal.skydroid")

namespace {
// The pod holds the last speed it was given, so a dropped datagram would leave
// the gimbal running. Resending the current state covers that and doubles as a
// keepalive.
constexpr int kRepeatIntervalMs = 200;

constexpr const char *kPitchVerb = "#TPUG2wGSP";
constexpr const char *kYawVerb   = "#TPUG2wGSY";
constexpr const char *kZoomIn    = "#TPUG2wPTZ0A";
constexpr const char *kZoomOut   = "#TPUG2wPTZ0B";
constexpr const char *kPtzStop   = "#TPUG2wPTZ00";
constexpr const char *kVersion   = "#TPUD2rVER00";
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

    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();
    connect(settings->enabled(), &Fact::rawValueChanged, this, &SkydroidGimbalController::_settingsChanged);
    connect(settings->address(), &Fact::rawValueChanged, this, &SkydroidGimbalController::_settingsChanged);
    connect(settings->port(),    &Fact::rawValueChanged, this, &SkydroidGimbalController::_settingsChanged);

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

void SkydroidGimbalController::_settingsChanged()
{
    SkydroidGimbalSettings *settings = SettingsManager::instance()->skydroidGimbalSettings();

    _closeSocket();

    if (!settings->enabled()->rawValue().toBool()) {
        _pitchSpeed = 0;
        _yawSpeed = 0;
        _zoomDirection = 0;
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

    if (direction > 0) {
        _send(QString::fromLatin1(kZoomIn));
    } else if (direction < 0) {
        _send(QString::fromLatin1(kZoomOut));
    } else {
        _send(QString::fromLatin1(kPtzStop));
    }

    emit zoomChanged();
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
    } else {
        qCDebug(SkydroidGimbalLog) << "No vehicle: RC gimbal control is inactive";
        _rcChannelCount = 0;
        _rcPitchPwm = -1;
        _rcYawPwm = -1;
        _rcZoomPwm = -1;
        stopMotion();
    }

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
        qCDebug(SkydroidGimbalLog) << "RC chancount" << channelCount
                                   << "pitch ch" << settings->pitchChannel()->rawValue().toInt() << "=" << _rcPitchPwm
                                   << "yaw ch" << settings->yawChannel()->rawValue().toInt() << "=" << _rcYawPwm
                                   << "zoom ch" << settings->zoomChannel()->rawValue().toInt() << "=" << _rcZoomPwm
                                   << "| enabled" << settings->enabled()->rawValue().toBool()
                                   << "rcControl" << settings->rcControlEnabled()->rawValue().toBool();
    }

    if (!settings->enabled()->rawValue().toBool() || !settings->rcControlEnabled()->rawValue().toBool()) {
        return;
    }

    setPitchSpeed(_channelToSpeed(settings->pitchChannel()->rawValue().toInt(), channelCount, pwmValues,
                                  settings->pitchReversed()->rawValue().toBool()));
    setYawSpeed(_channelToSpeed(settings->yawChannel()->rawValue().toInt(), channelCount, pwmValues,
                                settings->yawReversed()->rawValue().toBool()));

    // Zoom is a rate, not a position: anything outside the deadband means keep
    // zooming that way until the knob comes back.
    const int zoom = _channelToSpeed(settings->zoomChannel()->rawValue().toInt(), channelCount, pwmValues, false);
    _setZoomDirection((zoom > 0) ? 1 : ((zoom < 0) ? -1 : 0));
}

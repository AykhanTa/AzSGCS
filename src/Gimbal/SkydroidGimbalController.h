/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
#pragma once

#include <QtCore/QByteArray>
#include <QtCore/QElapsedTimer>
#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QPointer>
#include <QtCore/QString>
#include <QtNetwork/QHostAddress>

#include "QGCMAVLink.h"

Q_DECLARE_LOGGING_CATEGORY(SkydroidGimbalLog)

class QUdpSocket;
class QTimer;
class Vehicle;

/// Control for a Skydroid camera pod (C01-C14) such as the C13.
///
/// These pods do not speak the MAVLink gimbal protocol that GimbalController
/// implements. They sit on the air unit's own network and take an ASCII
/// protocol over UDP, so this is a separate path rather than a backend for
/// GimbalController.
///
/// Wire format is the command text followed by a checksum:
///
///     #TPUG2wGSP + <speed as 2 upper-case hex digits> + <checksum>
///
/// where the checksum is the sum of every byte of the command, modulo 256,
/// again as two upper-case hex digits.
class SkydroidGimbalController : public QObject
{
    Q_OBJECT

    friend class SkydroidGimbalTest;

    Q_PROPERTY(bool    active       READ active       NOTIFY activeChanged)
    Q_PROPERTY(int     pitchSpeed   READ pitchSpeed   NOTIFY speedChanged)
    Q_PROPERTY(int     yawSpeed     READ yawSpeed     NOTIFY speedChanged)
    Q_PROPERTY(int     zoomDirection READ zoomDirection NOTIFY zoomChanged)
    Q_PROPERTY(quint64 sentCount    READ sentCount    NOTIFY sentCountChanged)

    // RC diagnostics. Without these there is no way to tell "no RC_CHANNELS is
    // arriving at all" apart from "the channels arrive but never leave the
    // deadband", and the two have completely different fixes.
    Q_PROPERTY(bool    rcConnected    READ rcConnected    NOTIFY rcChanged)
    Q_PROPERTY(int     rcChannelCount READ rcChannelCount NOTIFY rcChanged)
    Q_PROPERTY(int     rcPitchPwm     READ rcPitchPwm     NOTIFY rcChanged)
    Q_PROPERTY(int     rcYawPwm       READ rcYawPwm       NOTIFY rcChanged)
    Q_PROPERTY(int     rcZoomPwm      READ rcZoomPwm      NOTIFY rcChanged)
    Q_PROPERTY(quint64 rcUpdateCount  READ rcUpdateCount  NOTIFY rcChanged)

public:
    explicit SkydroidGimbalController(QObject *parent = nullptr);
    ~SkydroidGimbalController();

    /// Two upper-case hex digits: the sum of every byte in `body`, modulo 256.
    static QString checksumHex(const QByteArray &body);

    /// `body` plus its checksum - the bytes that go on the wire.
    static QByteArray buildCommand(const QString &body);

    /// Command body for a gimbal speed. `speed` is clamped to a signed byte and
    /// sent as its two's complement, which is how the pod reads it: the stock
    /// ground station nudges at +/-30.
    static QString speedCommand(const QString &verb, int speed);

    bool    active() const { return _active; }
    int     pitchSpeed() const { return _pitchSpeed; }
    int     yawSpeed() const { return _yawSpeed; }
    int     zoomDirection() const { return _zoomDirection; }
    quint64 sentCount() const { return _sentCount; }

    bool    rcConnected() const { return !_vehicle.isNull(); }
    int     rcChannelCount() const { return _rcChannelCount; }
    int     rcPitchPwm() const { return _rcPitchPwm; }
    int     rcYawPwm() const { return _rcYawPwm; }
    int     rcZoomPwm() const { return _rcZoomPwm; }
    quint64 rcUpdateCount() const { return _rcUpdateCount; }

    void setVehicle(Vehicle *vehicle);

public slots:
    /// Speeds are in protocol units, positive is up and to the right.
    void setPitchSpeed(int speed);
    void setYawSpeed(int speed);
    void stopMotion();

    void zoomIn();
    void zoomOut();
    void zoomStop();

    /// Ask the pod for its version. The reply is what marks the link active.
    void queryVersion();

signals:
    void activeChanged();
    void speedChanged();
    void zoomChanged();
    void sentCountChanged();
    void rcChanged();
    void podReply(const QString &message);

private slots:
    void _readPendingDatagrams();
    void _rcChannelsChanged(int channelCount, int pwmValues[QGCMAVLink::maxRcChannels]);
    void _settingsChanged();
    void _rcControlEnabledChanged();
    void _checkRcStale();

private:
    void _openSocket();
    void _closeSocket();
    void _send(const QString &body);
    void _setZoomDirection(int direction);

    /// True while the last thing the sticks asked for was motion.
    bool _rcDriving() const { return (_rcCmdPitch != 0) || (_rcCmdYaw != 0) || (_rcCmdZoom != 0); }

    /// Stops whatever the sticks set going and forgets it, so the next sample that asks
    /// for motion is applied afresh.
    void _stopRcMotion();

    /// Channel PWM to a speed in protocol units, or 0 inside the deadband.
    /// `channel` is 1-based; 0 means the axis is not bound.
    int  _channelToSpeed(int channel, int channelCount, const int *pwmValues, bool reversed) const;

    /// Raw PWM for a 1-based channel, or -1 when the channel is unbound or the
    /// receiver is not driving it.
    static int _rawChannel(int channel, int channelCount, const int *pwmValues);

    QUdpSocket      *_socket = nullptr;
    QTimer          *_repeatTimer = nullptr;
    QTimer          *_rcWatchdog = nullptr;
    QPointer<Vehicle> _vehicle;
    QHostAddress     _target;
    quint16          _port = 0;

    bool    _active = false;
    int     _pitchSpeed = 0;
    int     _yawSpeed = 0;
    int     _zoomDirection = 0;
    quint64 _sentCount = 0;

    int     _rcChannelCount = 0;
    int     _rcPitchPwm = -1;
    int     _rcYawPwm = -1;
    int     _rcZoomPwm = -1;
    quint64 _rcUpdateCount = 0;
    QElapsedTimer _rcLogThrottle;

    // What the sticks last asked for, kept apart from the live speeds so the gimbal page
    // buttons and the sticks do not undo each other.
    int     _rcCmdPitch = 0;
    int     _rcCmdYaw = 0;
    int     _rcCmdZoom = 0;
    QElapsedTimer _rcLastApplied;
};

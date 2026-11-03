/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
#pragma once

#include <QtCore/QElapsedTimer>
#include <QtCore/QList>
#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QPointer>
#include <QtCore/QString>

#include <functional>

#include "QGCMAVLink.h"

Q_DECLARE_LOGGING_CATEGORY(AmmoLauncherLog)

class QTimer;
class Vehicle;

/// The launcher's frames (data type, id). The flight controller builds the 5 byte
/// `A5 type id crc B6` frames, adds the CRC and waits for the launcher's ACK/NACK; the
/// station only names the frame in a MAVLink command.
///
///     ARM          F1 A0        Servo n      1F 01..0C
///     DISARM       F1 D0        Salvo        1F FF
namespace AmmoLauncherProtocol {

constexpr uint8_t kTypeArm   = 0xF1;
constexpr uint8_t kTypeServo = 0x1F;

constexpr uint8_t kIdArm    = 0xA0;
constexpr uint8_t kIdDisarm = 0xD0;
constexpr uint8_t kIdSalvo  = 0xFF;

/// DO_GRIPPER carries ARM (param1 0, param2 GRAB), servo n (n, RELEASE) and the salvo
/// (0, RELEASE). DISARM has no gripper form and goes as the raw frame: USER_1 with
/// param1 = data type, param2 = id.
constexpr int kCmdGripper  = MAV_CMD_DO_GRIPPER;
constexpr int kCmdRawFrame = MAV_CMD_USER_1;

/// NAMED_VALUE_FLOAT the flight controller sends at 1 Hz: 0 without the launcher's
/// heartbeat, else the launcher's servo count (8, 10 or 12).
constexpr const char *kSlotValueName = "MECH_SLOT";

struct MavCommand {
    int   command = 0;
    float param1  = 0;
    float param2  = 0;
};

/// The MAVLink command that sends the frame (data type, id).
MavCommand commandFor(uint8_t type, uint8_t id);

/// Servo count the flight controller reports in MECH_SLOT, 0 for none or an unknown
/// value.
int slotCountForValue(float value);

} // namespace AmmoLauncherProtocol

/// The ammunition launcher under the vehicle, driven through the flight controller.
///
/// Its arming is separate from the vehicle's. It can only be armed while the vehicle
/// is flying (or on the ground with the bench test setting), and firing is only
/// possible while it is armed. The flight controller reports the launcher's link and
/// servo count in MECH_SLOT; that count is the number of slots the panel draws.
/// Whether a slot is still loaded is not reported: a slot is marked empty here once
/// the flight controller has acknowledged firing it.
///
/// Commands go out one at a time as COMMAND_LONG and wait for their COMMAND_ACK, which
/// carries the launcher's answer. Retries on a lost ACK are the vehicle's own (the
/// flight controller recognises a repeat and does not fire twice). DISARM jumps the
/// queue and drops any firing still waiting.
class AmmoLauncherController : public QObject
{
    Q_OBJECT

    friend class AmmoLauncherTest;

    Q_PROPERTY(bool       connected        READ connected        NOTIFY connectedChanged)
    Q_PROPERTY(int        slotCount        READ slotCount        NOTIFY slotCountChanged)
    Q_PROPERTY(QList<int> slotStates       READ slotStates       NOTIFY slotStatesChanged)
    Q_PROPERTY(bool       armed            READ armed            NOTIFY armedChanged)
    Q_PROPERTY(bool       busy             READ busy             NOTIFY busyChanged)
    Q_PROPERTY(bool       flying           READ flying           NOTIFY flyingChanged)
    Q_PROPERTY(bool       groundArmAllowed READ groundArmAllowed NOTIFY groundArmAllowedChanged)
    Q_PROPERTY(bool       canArm           READ canArm           NOTIFY canArmChanged)
    Q_PROPERTY(bool       canFire          READ canFire          NOTIFY canFireChanged)
    Q_PROPERTY(QString    statusText       READ statusText       NOTIFY statusTextChanged)

public:
    enum SlotState {
        SlotReady    = 0,
        SlotSelected = 1,
        SlotEmpty    = 2,
    };
    Q_ENUM(SlotState)

    /// No MECH_SLOT for this long is a lost launcher, as is MECH_SLOT 0.
    static constexpr int kHeartbeatTimeoutMs = 3000;

    explicit AmmoLauncherController(QObject *parent = nullptr);
    ~AmmoLauncherController() override;

    void setVehicle(Vehicle *vehicle);

    bool connected() const { return _connected; }
    int slotCount() const { return _slotCount; }
    QList<int> slotStates() const { return _slotStates; }
    bool armed() const { return _armed; }
    bool busy() const { return !_queue.isEmpty(); }
    bool flying() const { return _flying; }
    /// The bench test setting (FlyViewSettings::ammoArmOnGround): arming without flying.
    bool groundArmAllowed() const { return _groundArmAllowed; }
    bool canArm() const;
    bool canFire() const;
    QString statusText() const;

    Q_INVOKABLE void arm();
    Q_INVOKABLE void disarm();
    /// Ready -> selected -> ready. Empty slots stay as they are.
    Q_INVOKABLE void toggleSlot(int index);
    Q_INVOKABLE void selectAll();
    Q_INVOKABLE void clearSelection();
    /// Fires the selected slots: one servo command each, or the salvo when every slot
    /// is loaded and selected.
    Q_INVOKABLE void fire();

signals:
    void connectedChanged();
    void slotCountChanged();
    void slotStatesChanged();
    void armedChanged();
    void busyChanged();
    void flyingChanged();
    void groundArmAllowedChanged();
    void canArmChanged();
    void canFireChanged();
    void statusTextChanged();
    /// A command the launcher or the flight controller refused or never answered.
    void commandFailed(const QString &message);

private slots:
    void _mavlinkMessageReceived(const mavlink_message_t &message);
    void _vehicleFlyingChanged(bool flying);
    void _checkHeartbeat();

private:
    struct Command {
        uint8_t type = 0;
        uint8_t id   = 0;
    };

    /// How a command ended: the COMMAND_ACK result, or no answer at all.
    enum class Result {
        Accepted,
        Denied,
        Failed,
        TemporarilyRejected,
        Unsupported,
        NoResponse,
    };

    void _handleSlotValue(float value);
    void _handleResult(int command, Result result);
    void _enqueue(uint8_t type, uint8_t id);
    void _sendHead();
    void _finishHead();
    /// Drops the servo commands still waiting and unselects their slots. With
    /// `headInFlight` a servo command at the head keeps its slots selected until its
    /// answer arrives.
    void _dropFiring(bool headInFlight);
    bool _send(const Command &command);
    void _linkLost();
    void _setConnected(bool connected);
    void _setSlotCount(int count);
    void _setArmed(bool armed);
    void _setFlying(bool flying);
    void _setGroundArmAllowed(bool allowed);
    void _setSlotStates(const QList<int> &states);
    void _fail(const QString &message);
    void _emitDerived();

    static QString _commandName(uint8_t type, uint8_t id);
    static QString _failureText(const Command &command, Result result);

    QPointer<Vehicle> _vehicle;

    bool _connected = false;
    int _slotCount = 0;
    QList<int> _slotStates;
    bool _armed = false;
    bool _flying = false;
    bool _groundArmAllowed = false;
    bool _lastCanArm = false;
    bool _lastCanFire = false;
    QString _lastStatusText;

    QList<Command> _queue;
    /// The head has gone out and its COMMAND_ACK is awaited.
    bool _headSent = false;
    QElapsedTimer _lastHeartbeat;
    QTimer *_heartbeatTimer = nullptr;

    /// Replaces the MAVLink transport in the unit tests.
    std::function<bool(const AmmoLauncherProtocol::MavCommand &)> _sendHook;
};

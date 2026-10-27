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

/// The launcher's 5 byte wire format:
///
///     0xA5  <data type>  <id>  <crc>  0xB6
///
///     ARM          F1 A0        Servo n      1F 01..0C
///     DISARM       F1 D0        Salvo        1F FF
///     ACK          01 <id>      NACK         00 <id>
///     HEARTBEAT    11 <08 | 10 | 12>   the id names the launcher: 8, 10 or 12 servos
namespace AmmoLauncherProtocol {

constexpr uint8_t kStart = 0xA5;
constexpr uint8_t kEnd   = 0xB6;
constexpr int     kPacketSize = 5;

constexpr uint8_t kTypeArm       = 0xF1;
constexpr uint8_t kTypeServo     = 0x1F;
constexpr uint8_t kTypeNack      = 0x00;
constexpr uint8_t kTypeAck       = 0x01;
constexpr uint8_t kTypeHeartbeat = 0x11;

constexpr uint8_t kIdArm    = 0xA0;
constexpr uint8_t kIdDisarm = 0xD0;
constexpr uint8_t kIdSalvo  = 0xFF;

/// The packets travel inside MAVLink TUNNEL messages with this payload type (a local,
/// unregistered code: anything above 32767).
constexpr uint16_t kTunnelPayloadType = 0xA5B6;

struct Packet {
    uint8_t type = 0;
    uint8_t id   = 0;
};

/// The CRC byte. The launcher's algorithm is not specified yet; this is the XOR of the
/// data type and the id, and the only place to change once it is.
uint8_t crc(uint8_t type, uint8_t id);

QByteArray build(uint8_t type, uint8_t id);

/// Servo count of the launcher a heartbeat id names, 0 for an unknown id. The ids read
/// as the decimal count written in hex: 0x08, 0x10 and 0x12.
int slotCountForHeartbeat(uint8_t id);

/// Splits a byte stream into packets. Bytes are kept across calls, so a packet split
/// over two TUNNEL messages still parses; a frame with a wrong end byte or CRC is
/// dropped and the search for the next start byte goes on from the byte after it.
class Parser
{
public:
    QList<Packet> feed(const QByteArray &bytes);
    void reset() { _buffer.clear(); }

private:
    QByteArray _buffer;
};

} // namespace AmmoLauncherProtocol

/// The ammunition launcher under the vehicle.
///
/// Its arming is separate from the vehicle's. It can only be armed while the vehicle
/// is flying, and firing is only possible while it is armed. The launcher announces
/// itself with a heartbeat whose id gives its servo count; that count is the number of
/// slots the panel draws. Whether a slot is still loaded is not reported: a slot is
/// marked empty here once the launcher has acknowledged firing it.
///
/// Commands go out one at a time and wait for their ACK or NACK, with retries on a
/// timeout. DISARM jumps the queue and drops any firing still waiting.
class AmmoLauncherController : public QObject
{
    Q_OBJECT

    friend class AmmoLauncherTest;

    Q_PROPERTY(bool       connected  READ connected  NOTIFY connectedChanged)
    Q_PROPERTY(int        slotCount  READ slotCount  NOTIFY slotCountChanged)
    Q_PROPERTY(QList<int> slotStates READ slotStates NOTIFY slotStatesChanged)
    Q_PROPERTY(bool       armed      READ armed      NOTIFY armedChanged)
    Q_PROPERTY(bool       busy       READ busy       NOTIFY busyChanged)
    Q_PROPERTY(bool       flying     READ flying     NOTIFY flyingChanged)
    Q_PROPERTY(bool       canArm     READ canArm     NOTIFY canArmChanged)
    Q_PROPERTY(bool       canFire    READ canFire    NOTIFY canFireChanged)
    Q_PROPERTY(QString    statusText READ statusText NOTIFY statusTextChanged)

public:
    enum SlotState {
        SlotReady    = 0,
        SlotSelected = 1,
        SlotEmpty    = 2,
    };
    Q_ENUM(SlotState)

    static constexpr int kHeartbeatTimeoutMs = 3000;
    static constexpr int kAckTimeoutMs       = 1000;
    static constexpr int kMaxRetries         = 2;

    explicit AmmoLauncherController(QObject *parent = nullptr);
    ~AmmoLauncherController() override;

    void setVehicle(Vehicle *vehicle);

    bool connected() const { return _connected; }
    int slotCount() const { return _slotCount; }
    QList<int> slotStates() const { return _slotStates; }
    bool armed() const { return _armed; }
    bool busy() const { return !_queue.isEmpty(); }
    bool flying() const { return _flying; }
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
    void canArmChanged();
    void canFireChanged();
    void statusTextChanged();
    /// A command the launcher refused or never answered.
    void commandFailed(const QString &message);

private slots:
    void _mavlinkMessageReceived(const mavlink_message_t &message);
    void _vehicleFlyingChanged(bool flying);
    void _checkHeartbeat();
    void _ackTimeout();

private:
    struct Command {
        uint8_t type    = 0;
        uint8_t id      = 0;
        int     retries = 0;
    };

    void _handleBytes(const QByteArray &bytes);
    void _handlePacket(const AmmoLauncherProtocol::Packet &packet);
    void _handleHeartbeat(uint8_t id);
    void _handleReply(bool ack, uint8_t id);
    void _enqueue(uint8_t type, uint8_t id);
    void _sendHead();
    void _finishHead();
    /// Drops the servo commands still waiting and unselects their slots. With
    /// `headInFlight` a servo command at the head keeps its slots selected until its
    /// reply arrives.
    void _dropFiring(bool headInFlight);
    bool _send(const QByteArray &packet);
    void _setConnected(bool connected);
    void _setSlotCount(int count);
    void _setArmed(bool armed);
    void _setFlying(bool flying);
    void _setSlotStates(const QList<int> &states);
    void _fail(const QString &message);
    void _emitDerived();

    static QString _commandName(uint8_t type, uint8_t id);

    QPointer<Vehicle> _vehicle;
    AmmoLauncherProtocol::Parser _parser;

    bool _connected = false;
    int _slotCount = 0;
    QList<int> _slotStates;
    bool _armed = false;
    bool _flying = false;
    bool _lastCanArm = false;
    bool _lastCanFire = false;
    QString _lastStatusText;

    QList<Command> _queue;
    QElapsedTimer _lastHeartbeat;
    QTimer *_heartbeatTimer = nullptr;
    QTimer *_ackTimer = nullptr;

    /// Replaces the MAVLink transport in the unit tests.
    std::function<bool(const QByteArray &)> _sendHook;
};

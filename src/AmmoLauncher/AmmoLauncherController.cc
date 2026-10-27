/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "AmmoLauncherController.h"

#include <QtCore/QTimer>

#include <cstring>

#include "LinkInterface.h"
#include "MAVLinkProtocol.h"
#include "QGCLoggingCategory.h"
#include "Vehicle.h"
#include "VehicleLinkManager.h"

QGC_LOGGING_CATEGORY(AmmoLauncherLog, "qgc.ammolauncher")

namespace AmmoLauncherProtocol {

uint8_t crc(uint8_t type, uint8_t id)
{
    return static_cast<uint8_t>(type ^ id);
}

QByteArray build(uint8_t type, uint8_t id)
{
    QByteArray packet(kPacketSize, '\0');
    packet[0] = static_cast<char>(kStart);
    packet[1] = static_cast<char>(type);
    packet[2] = static_cast<char>(id);
    packet[3] = static_cast<char>(crc(type, id));
    packet[4] = static_cast<char>(kEnd);
    return packet;
}

int slotCountForHeartbeat(uint8_t id)
{
    switch (id) {
    case 0x08: return 8;
    case 0x10: return 10;
    case 0x12: return 12;
    default:   return 0;
    }
}

QList<Packet> Parser::feed(const QByteArray &bytes)
{
    _buffer.append(bytes);

    QList<Packet> packets;
    qsizetype pos = 0;
    while (true) {
        const qsizetype start = _buffer.indexOf(static_cast<char>(kStart), pos);
        if (start < 0) {
            _buffer.clear();
            return packets;
        }
        if (_buffer.size() - start < kPacketSize) {
            _buffer.remove(0, start);
            return packets;
        }

        const uint8_t type = static_cast<uint8_t>(_buffer.at(start + 1));
        const uint8_t id   = static_cast<uint8_t>(_buffer.at(start + 2));
        const uint8_t sum  = static_cast<uint8_t>(_buffer.at(start + 3));
        const uint8_t end  = static_cast<uint8_t>(_buffer.at(start + 4));

        if ((end == kEnd) && (sum == crc(type, id))) {
            packets.append({ type, id });
            pos = start + kPacketSize;
        } else {
            qCDebug(AmmoLauncherLog) << "Dropping bad frame at" << start << _buffer.mid(start, kPacketSize).toHex(' ');
            pos = start + 1;
        }
    }
}

} // namespace AmmoLauncherProtocol

using namespace AmmoLauncherProtocol;

AmmoLauncherController::AmmoLauncherController(QObject *parent)
    : QObject(parent)
    , _heartbeatTimer(new QTimer(this))
    , _ackTimer(new QTimer(this))
{
    _heartbeatTimer->setInterval(500);
    (void) connect(_heartbeatTimer, &QTimer::timeout, this, &AmmoLauncherController::_checkHeartbeat);
    _heartbeatTimer->start();

    _ackTimer->setSingleShot(true);
    _ackTimer->setInterval(kAckTimeoutMs);
    (void) connect(_ackTimer, &QTimer::timeout, this, &AmmoLauncherController::_ackTimeout);

    _lastStatusText = statusText();
}

AmmoLauncherController::~AmmoLauncherController() = default;

void AmmoLauncherController::setVehicle(Vehicle *vehicle)
{
    if (vehicle == _vehicle) {
        return;
    }

    if (_vehicle) {
        // Best effort: the launcher must not stay armed under a vehicle we stop watching.
        if (_armed) {
            (void) _send(build(kTypeArm, kIdDisarm));
        }
        (void) disconnect(_vehicle, nullptr, this, nullptr);
    }

    _vehicle = vehicle;

    _queue.clear();
    _ackTimer->stop();
    _parser.reset();
    _setArmed(false);
    _setConnected(false);
    _setSlotCount(0);
    _setSlotStates({});

    if (_vehicle) {
        (void) connect(_vehicle, &Vehicle::mavlinkMessageReceived, this, &AmmoLauncherController::_mavlinkMessageReceived);
        (void) connect(_vehicle, &Vehicle::flyingChanged, this, &AmmoLauncherController::_vehicleFlyingChanged);
        _setFlying(_vehicle->flying());
    } else {
        _setFlying(false);
    }

    emit busyChanged();
    _emitDerived();
}

bool AmmoLauncherController::canArm() const
{
    return _connected && _flying && !_armed && !busy();
}

bool AmmoLauncherController::canFire() const
{
    return _connected && _armed && !busy() && _slotStates.contains(SlotSelected);
}

QString AmmoLauncherController::statusText() const
{
    if (!_connected) {
        return (_slotCount > 0) ? tr("Əlaqə yoxdur") : tr("Qoşulmayıb");
    }
    if (!_queue.isEmpty()) {
        const Command &head = _queue.first();
        if (head.type == kTypeArm) {
            return (head.id == kIdArm) ? tr("ARM edilir…") : tr("DISARM edilir…");
        }
        return tr("Atılır…");
    }
    if (_armed) {
        return tr("ARM");
    }
    return _flying ? tr("DISARM") : tr("Aparat yerdədir");
}

void AmmoLauncherController::arm()
{
    if (!_connected) {
        _fail(tr("Buraxıcı qoşulmayıb."));
        return;
    }
    if (!_flying) {
        _fail(tr("Aparat yerdə olarkən buraxıcı ARM edilə bilməz."));
        return;
    }
    if (_armed || busy()) {
        return;
    }
    _enqueue(kTypeArm, kIdArm);
}

void AmmoLauncherController::disarm()
{
    // Firing stops at once, whatever the launcher answers.
    _setArmed(false);
    _dropFiring(true);

    if (!_connected) {
        _emitDerived();
        return;
    }

    for (const Command &command : _queue) {
        if ((command.type == kTypeArm) && (command.id == kIdDisarm)) {
            _emitDerived();
            return;
        }
    }

    // Behind the command already on the wire, ahead of everything else.
    const bool wasBusy = busy();
    const Command disarmCommand { kTypeArm, kIdDisarm, 0 };
    if (_queue.isEmpty()) {
        _queue.append(disarmCommand);
        _sendHead();
    } else {
        _queue.insert(1, disarmCommand);
    }
    if (wasBusy != busy()) {
        emit busyChanged();
    }
    _emitDerived();
}

void AmmoLauncherController::toggleSlot(int index)
{
    if (!_connected || busy() || (index < 0) || (index >= _slotStates.size())) {
        return;
    }

    QList<int> states = _slotStates;
    if (states[index] == SlotReady) {
        states[index] = SlotSelected;
    } else if (states[index] == SlotSelected) {
        states[index] = SlotReady;
    } else {
        return;
    }
    _setSlotStates(states);
}

void AmmoLauncherController::selectAll()
{
    if (!_connected || busy()) {
        return;
    }

    QList<int> states = _slotStates;
    for (int &state : states) {
        if (state == SlotReady) {
            state = SlotSelected;
        }
    }
    _setSlotStates(states);
}

void AmmoLauncherController::clearSelection()
{
    if (busy()) {
        return;
    }

    QList<int> states = _slotStates;
    for (int &state : states) {
        if (state == SlotSelected) {
            state = SlotReady;
        }
    }
    _setSlotStates(states);
}

void AmmoLauncherController::fire()
{
    if (!canFire()) {
        if (!_armed) {
            _fail(tr("Atış üçün buraxıcı ARM edilməlidir."));
        }
        return;
    }

    const bool salvo = !_slotStates.isEmpty() && (_slotStates.count(SlotSelected) == _slotStates.size());
    if (salvo) {
        _enqueue(kTypeServo, kIdSalvo);
        return;
    }

    for (int i = 0; i < _slotStates.size(); i++) {
        if (_slotStates[i] == SlotSelected) {
            _enqueue(kTypeServo, static_cast<uint8_t>(i + 1));
        }
    }
}

void AmmoLauncherController::_mavlinkMessageReceived(const mavlink_message_t &message)
{
    if (message.msgid != MAVLINK_MSG_ID_TUNNEL) {
        return;
    }

    mavlink_tunnel_t tunnel{};
    mavlink_msg_tunnel_decode(&message, &tunnel);
    if (tunnel.payload_type != kTunnelPayloadType) {
        return;
    }

    const int length = qMin<int>(tunnel.payload_length, sizeof(tunnel.payload));
    _handleBytes(QByteArray(reinterpret_cast<const char *>(tunnel.payload), length));
}

void AmmoLauncherController::_handleBytes(const QByteArray &bytes)
{
    for (const Packet &packet : _parser.feed(bytes)) {
        _handlePacket(packet);
    }
}

void AmmoLauncherController::_handlePacket(const Packet &packet)
{
    switch (packet.type) {
    case kTypeHeartbeat:
        _handleHeartbeat(packet.id);
        break;
    case kTypeAck:
        _handleReply(true, packet.id);
        break;
    case kTypeNack:
        _handleReply(false, packet.id);
        break;
    default:
        qCDebug(AmmoLauncherLog) << "Ignoring packet" << Qt::hex << int(packet.type) << int(packet.id);
        break;
    }
}

void AmmoLauncherController::_handleHeartbeat(uint8_t id)
{
    const int count = slotCountForHeartbeat(id);
    if (count == 0) {
        qCWarning(AmmoLauncherLog) << "Unknown launcher heartbeat id" << Qt::hex << int(id);
        return;
    }

    _lastHeartbeat.restart();

    if (count != _slotCount) {
        // Another launcher: whatever was armed or selected belonged to the old one.
        if (_slotCount > 0) {
            qCWarning(AmmoLauncherLog) << "Launcher changed from" << _slotCount << "to" << count << "servos";
            if (_armed) {
                disarm();
            }
        }
        _setSlotCount(count);
        _setSlotStates(QList<int>(count, SlotReady));
    }

    _setConnected(true);
    _emitDerived();
}

void AmmoLauncherController::_handleReply(bool ack, uint8_t id)
{
    if (_queue.isEmpty() || (_queue.first().id != id)) {
        qCDebug(AmmoLauncherLog) << "Unexpected" << (ack ? "ACK" : "NACK") << Qt::hex << int(id);
        return;
    }

    const Command head = _queue.first();
    _ackTimer->stop();

    if (head.type == kTypeArm) {
        if (head.id == kIdArm) {
            if (ack) {
                _setArmed(true);
            } else {
                _fail(tr("Buraxıcı ARM komandasını rədd etdi."));
            }
        } else if (ack) {
            _setArmed(false);
        } else {
            _fail(tr("Buraxıcı DISARM komandasını rədd etdi."));
        }
    } else if (ack) {
        QList<int> states = _slotStates;
        if (head.id == kIdSalvo) {
            states.fill(SlotEmpty);
        } else if ((head.id >= 1) && (head.id <= states.size())) {
            states[head.id - 1] = SlotEmpty;
        }
        _setSlotStates(states);
    } else {
        _fail(tr("Buraxıcı %1 komandasını rədd etdi.").arg(_commandName(head.type, head.id)));
        _dropFiring(false);
    }

    _finishHead();
}

void AmmoLauncherController::_ackTimeout()
{
    if (_queue.isEmpty()) {
        return;
    }

    Command &head = _queue.first();
    if (head.retries < kMaxRetries) {
        head.retries++;
        qCDebug(AmmoLauncherLog) << "No reply, retry" << head.retries << _commandName(head.type, head.id);
        _sendHead();
        return;
    }

    _fail(tr("Buraxıcı %1 komandasına cavab vermədi.").arg(_commandName(head.type, head.id)));
    if (head.type == kTypeServo) {
        _dropFiring(false);
    }
    _finishHead();
}

void AmmoLauncherController::_enqueue(uint8_t type, uint8_t id)
{
    const bool wasBusy = busy();
    _queue.append({ type, id, 0 });
    if (!wasBusy) {
        _sendHead();
        emit busyChanged();
    }
    _emitDerived();
}

void AmmoLauncherController::_sendHead()
{
    if (_queue.isEmpty()) {
        return;
    }

    const Command &head = _queue.first();
    qCDebug(AmmoLauncherLog) << "Sending" << _commandName(head.type, head.id);
    if (!_send(build(head.type, head.id))) {
        qCWarning(AmmoLauncherLog) << "No link to send" << _commandName(head.type, head.id);
    }
    // A failed send is retried by the timeout like a lost packet.
    _ackTimer->start();
}

void AmmoLauncherController::_finishHead()
{
    if (!_queue.isEmpty()) {
        _queue.removeFirst();
    }

    if (_queue.isEmpty()) {
        emit busyChanged();
    } else {
        _sendHead();
    }
    _emitDerived();
}

void AmmoLauncherController::_dropFiring(bool headInFlight)
{
    // The head stays queued: it is on the wire, or it is about to be finished.
    for (qsizetype i = _queue.size() - 1; i >= 1; i--) {
        if (_queue.at(i).type == kTypeServo) {
            _queue.removeAt(i);
        }
    }

    QList<int> states = _slotStates;
    const bool headFiring = headInFlight && !_queue.isEmpty() && (_queue.first().type == kTypeServo);
    for (int i = 0; i < states.size(); i++) {
        if (states[i] != SlotSelected) {
            continue;
        }
        const bool inFlight = headFiring && ((_queue.first().id == kIdSalvo) || (_queue.first().id == i + 1));
        if (!inFlight) {
            states[i] = SlotReady;
        }
    }
    _setSlotStates(states);
}

bool AmmoLauncherController::_send(const QByteArray &packet)
{
    if (_sendHook) {
        return _sendHook(packet);
    }

    if (!_vehicle) {
        return false;
    }

    SharedLinkInterfacePtr sharedLink = _vehicle->vehicleLinkManager()->primaryLink().lock();
    if (!sharedLink) {
        return false;
    }

    uint8_t payload[sizeof(mavlink_tunnel_t::payload)] = {};
    const int length = qMin<int>(packet.size(), sizeof(payload));
    std::memcpy(payload, packet.constData(), length);

    mavlink_message_t message;
    (void) mavlink_msg_tunnel_pack_chan(MAVLinkProtocol::instance()->getSystemId(),
                                        MAVLinkProtocol::getComponentId(),
                                        sharedLink->mavlinkChannel(),
                                        &message,
                                        static_cast<uint8_t>(_vehicle->id()),
                                        MAV_COMP_ID_ALL,
                                        kTunnelPayloadType,
                                        static_cast<uint8_t>(length),
                                        payload);
    return _vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), message);
}

void AmmoLauncherController::_checkHeartbeat()
{
    if (!_connected || (_lastHeartbeat.isValid() && (_lastHeartbeat.elapsed() < kHeartbeatTimeoutMs))) {
        return;
    }

    qCWarning(AmmoLauncherLog) << "Launcher heartbeat lost";

    // Nothing can be sent now; the launcher has to disarm itself on the lost link.
    const bool wasBusy = busy();
    _queue.clear();
    _ackTimer->stop();
    _setArmed(false);
    _setConnected(false);
    _dropFiring(false);
    if (wasBusy) {
        emit busyChanged();
    }
    _fail(tr("Buraxıcı ilə əlaqə itdi."));
    _emitDerived();
}

void AmmoLauncherController::_vehicleFlyingChanged(bool flying)
{
    _setFlying(flying);
    if (!flying && _armed) {
        qCDebug(AmmoLauncherLog) << "Vehicle landed: disarming the launcher";
        disarm();
    }
    _emitDerived();
}

void AmmoLauncherController::_setConnected(bool connected)
{
    if (connected != _connected) {
        _connected = connected;
        emit connectedChanged();
    }
}

void AmmoLauncherController::_setSlotCount(int count)
{
    if (count != _slotCount) {
        _slotCount = count;
        emit slotCountChanged();
    }
}

void AmmoLauncherController::_setArmed(bool armed)
{
    if (armed != _armed) {
        _armed = armed;
        emit armedChanged();
    }
}

void AmmoLauncherController::_setFlying(bool flying)
{
    if (flying != _flying) {
        _flying = flying;
        emit flyingChanged();
    }
}

void AmmoLauncherController::_setSlotStates(const QList<int> &states)
{
    if (states != _slotStates) {
        _slotStates = states;
        emit slotStatesChanged();
    }
    _emitDerived();
}

void AmmoLauncherController::_fail(const QString &message)
{
    qCWarning(AmmoLauncherLog) << message;
    emit commandFailed(message);
}

void AmmoLauncherController::_emitDerived()
{
    if (canArm() != _lastCanArm) {
        _lastCanArm = canArm();
        emit canArmChanged();
    }
    if (canFire() != _lastCanFire) {
        _lastCanFire = canFire();
        emit canFireChanged();
    }
    const QString text = statusText();
    if (text != _lastStatusText) {
        _lastStatusText = text;
        emit statusTextChanged();
    }
}

QString AmmoLauncherController::_commandName(uint8_t type, uint8_t id)
{
    if (type == kTypeArm) {
        return (id == kIdArm) ? QStringLiteral("ARM") : QStringLiteral("DISARM");
    }
    if (id == kIdSalvo) {
        return tr("toplu atış");
    }
    return tr("servo %1").arg(id);
}

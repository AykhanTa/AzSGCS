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

#include <cmath>
#include <cstring>

#include "Fact.h"
#include "FlyViewSettings.h"
#include "QGCLoggingCategory.h"
#include "SettingsManager.h"
#include "Vehicle.h"

QGC_LOGGING_CATEGORY(AmmoLauncherLog, "qgc.ammolauncher")

namespace AmmoLauncherProtocol {

MavCommand commandFor(uint8_t type, uint8_t id)
{
    if (type == kTypeArm) {
        if (id == kIdArm) {
            return { kCmdGripper, 0, GRIPPER_ACTION_GRAB };
        }
        return { kCmdRawFrame, static_cast<float>(type), static_cast<float>(id) };
    }
    if (type == kTypeServo) {
        // The salvo is servo "0" released; servo n is n released.
        return { kCmdGripper, (id == kIdSalvo) ? 0.0f : static_cast<float>(id), GRIPPER_ACTION_RELEASE };
    }
    return { kCmdRawFrame, static_cast<float>(type), static_cast<float>(id) };
}

int slotCountForValue(float value)
{
    switch (static_cast<int>(std::lround(value))) {
    case 8:  return 8;
    case 10: return 10;
    case 12: return 12;
    default: return 0;
    }
}

} // namespace AmmoLauncherProtocol

using namespace AmmoLauncherProtocol;

AmmoLauncherController::AmmoLauncherController(QObject *parent)
    : QObject(parent)
    , _heartbeatTimer(new QTimer(this))
{
    _heartbeatTimer->setInterval(500);
    (void) connect(_heartbeatTimer, &QTimer::timeout, this, &AmmoLauncherController::_checkHeartbeat);
    _heartbeatTimer->start();

    Fact *armOnGround = SettingsManager::instance()->flyViewSettings()->ammoArmOnGround();
    _groundArmAllowed = armOnGround->rawValue().toBool();
    (void) connect(armOnGround, &Fact::rawValueChanged, this, [this](const QVariant &value) {
        _setGroundArmAllowed(value.toBool());
    });

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
            (void) _send({ kTypeArm, kIdDisarm });
        }
        (void) disconnect(_vehicle, nullptr, this, nullptr);
    }

    _vehicle = vehicle;

    _queue.clear();
    _headSent = false;
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
    return _connected && (_flying || _groundArmAllowed) && !_armed && !busy();
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
    if (_flying) {
        return tr("DISARM");
    }
    return _groundArmAllowed ? tr("DISARM (stend)") : tr("Aparat yerdədir");
}

void AmmoLauncherController::arm()
{
    if (!_connected) {
        _fail(tr("Buraxıcı qoşulmayıb."));
        return;
    }
    if (!_flying && !_groundArmAllowed) {
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

    // Behind the command already sent, ahead of everything else.
    const bool wasBusy = busy();
    const Command disarmCommand { kTypeArm, kIdDisarm };
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
    if (message.msgid != MAVLINK_MSG_ID_NAMED_VALUE_FLOAT) {
        return;
    }

    mavlink_named_value_float_t namedValue{};
    mavlink_msg_named_value_float_decode(&message, &namedValue);

    // The name is not null terminated when it fills the field.
    char name[sizeof(namedValue.name) + 1] = {};
    std::memcpy(name, namedValue.name, sizeof(namedValue.name));
    if (std::strcmp(name, kSlotValueName) != 0) {
        return;
    }

    _handleSlotValue(namedValue.value);
}

void AmmoLauncherController::_handleSlotValue(float value)
{
    const int count = slotCountForValue(value);
    if (count == 0) {
        if (value != 0.0f) {
            qCWarning(AmmoLauncherLog) << "Unknown launcher slot count" << value;
        }
        // The flight controller has lost the launcher's heartbeat.
        if (_connected) {
            _linkLost();
        }
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

void AmmoLauncherController::_handleResult(int command, Result result)
{
    if (!_headSent || _queue.isEmpty() || (commandFor(_queue.first().type, _queue.first().id).command != command)) {
        qCDebug(AmmoLauncherLog) << "Unexpected result for command" << command;
        return;
    }

    const Command head = _queue.first();
    const bool accepted = (result == Result::Accepted);

    if (head.type == kTypeArm) {
        if (accepted) {
            _setArmed(head.id == kIdArm);
        } else {
            _fail(_failureText(head, result));
        }
    } else if (accepted) {
        QList<int> states = _slotStates;
        if (head.id == kIdSalvo) {
            states.fill(SlotEmpty);
        } else if ((head.id >= 1) && (head.id <= states.size())) {
            states[head.id - 1] = SlotEmpty;
        }
        _setSlotStates(states);
    } else {
        // A refused or unanswered servo is not retried and cancels the rest of the
        // firing: the operator decides.
        _fail(_failureText(head, result));
        _dropFiring(false);
    }

    _finishHead();
}

void AmmoLauncherController::_enqueue(uint8_t type, uint8_t id)
{
    const bool wasBusy = busy();
    _queue.append({ type, id });
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

    const Command head = _queue.first();
    qCDebug(AmmoLauncherLog) << "Sending" << _commandName(head.type, head.id);
    _headSent = true;
    if (!_send(head)) {
        qCWarning(AmmoLauncherLog) << "No vehicle to send" << _commandName(head.type, head.id);
        _handleResult(commandFor(head.type, head.id).command, Result::NoResponse);
    }
}

void AmmoLauncherController::_finishHead()
{
    _headSent = false;
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
    // The head stays queued: it is sent, or it is about to be finished.
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

bool AmmoLauncherController::_send(const Command &command)
{
    const MavCommand mavCommand = commandFor(command.type, command.id);

    if (_sendHook) {
        return _sendHook(mavCommand);
    }

    if (!_vehicle) {
        return false;
    }

    // The controller lives as long as the application, so it outlives any command the
    // vehicle still has in flight. A late result for a command that is no longer the
    // head (after a vehicle change or a lost link) is ignored by _handleResult.
    static const Vehicle::MavCmdResultHandler resultHandler =
        [](void *resultHandlerData, int /*compId*/, const mavlink_command_ack_t &ack, Vehicle::MavCmdResultFailureCode_t failureCode) {
            auto *controller = static_cast<AmmoLauncherController *>(resultHandlerData);
            Result result = Result::Failed;
            if (failureCode == Vehicle::MavCmdResultFailureNoResponseToCommand) {
                result = Result::NoResponse;
            } else if (failureCode == Vehicle::MavCmdResultFailureDuplicateCommand) {
                result = Result::TemporarilyRejected;
            } else {
                switch (ack.result) {
                case MAV_RESULT_ACCEPTED:             result = Result::Accepted;            break;
                case MAV_RESULT_DENIED:               result = Result::Denied;              break;
                case MAV_RESULT_TEMPORARILY_REJECTED: result = Result::TemporarilyRejected; break;
                case MAV_RESULT_UNSUPPORTED:          result = Result::Unsupported;         break;
                default:                              result = Result::Failed;              break;
                }
            }
            controller->_handleResult(ack.command, result);
        };

    const Vehicle::MavCmdAckHandlerInfo_t handlerInfo { resultHandler, this, nullptr, nullptr };
    _vehicle->sendMavCommandWithHandler(&handlerInfo,
                                        MAV_COMP_ID_AUTOPILOT1,
                                        static_cast<MAV_CMD>(mavCommand.command),
                                        mavCommand.param1,
                                        mavCommand.param2);
    return true;
}

void AmmoLauncherController::_checkHeartbeat()
{
    if (!_connected || (_lastHeartbeat.isValid() && (_lastHeartbeat.elapsed() < kHeartbeatTimeoutMs))) {
        return;
    }

    _linkLost();
}

void AmmoLauncherController::_linkLost()
{
    qCWarning(AmmoLauncherLog) << "Launcher link lost";

    // Nothing reaches the launcher now; it has to disarm itself on the lost link.
    // Locally the launcher is disarmed and nothing is waited on any more.
    const bool wasBusy = busy();
    _queue.clear();
    _headSent = false;
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
    if (!flying && _armed && !_groundArmAllowed) {
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

void AmmoLauncherController::_setGroundArmAllowed(bool allowed)
{
    if (allowed == _groundArmAllowed) {
        return;
    }

    _groundArmAllowed = allowed;
    emit groundArmAllowedChanged();
    // Turning the bench test off on the ground disarms like a landing.
    if (!allowed && !_flying && _armed) {
        disarm();
    }
    _emitDerived();
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

QString AmmoLauncherController::_failureText(const Command &command, Result result)
{
    const QString name = _commandName(command.type, command.id);
    switch (result) {
    case Result::Denied:
        return tr("Buraxıcı %1 komandasını rədd etdi.").arg(name);
    case Result::Failed:
        return tr("Buraxıcı %1 komandasına cavab vermədi.").arg(name);
    case Result::TemporarilyRejected:
        return tr("%1: FC hazırda komandanı qəbul edə bilmir (mexanizm portu bağlıdır və ya növbə doludur).").arg(name);
    case Result::Unsupported:
        return tr("%1: FC bu komandanı dəstəkləmir.").arg(name);
    case Result::NoResponse:
        return tr("%1: FC cavab vermədi.").arg(name);
    case Result::Accepted:
        break;
    }
    return QString();
}

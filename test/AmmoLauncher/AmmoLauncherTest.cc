#include "AmmoLauncherTest.h"
#include "AmmoLauncherController.h"

#include <QtCore/QRegularExpression>
#include <QtTest/QSignalSpy>
#include <QtTest/QTest>

using namespace AmmoLauncherProtocol;

namespace {
using States = QList<int>;
constexpr int R = AmmoLauncherController::SlotReady;
constexpr int S = AmmoLauncherController::SlotSelected;
constexpr int E = AmmoLauncherController::SlotEmpty;

QString format(const MavCommand &command)
{
    return QStringLiteral("%1 %2 %3").arg(command.command).arg(command.param1).arg(command.param2);
}
}

void AmmoLauncherTest::init()
{
    UnitTest::init();
    _sent.clear();
    // Refused commands and lost links are part of the behaviour under test.
    ignoreLogMessage("qgc.ammolauncher", QtWarningMsg, QRegularExpression(QStringLiteral(".*")));
}

void AmmoLauncherTest::_setUp(AmmoLauncherController &controller, int slotCount, bool flying)
{
    controller._sendHook = [this](const MavCommand &command) {
        _sent.append(format(command));
        return true;
    };
    controller._setGroundArmAllowed(false);
    controller._setFlying(flying);
    controller._handleSlotValue(static_cast<float>(slotCount));
}

void AmmoLauncherTest::_accept(AmmoLauncherController &controller, uint8_t type, uint8_t id)
{
    controller._handleResult(commandFor(type, id).command, AmmoLauncherController::Result::Accepted);
}

void AmmoLauncherTest::_deny(AmmoLauncherController &controller, uint8_t type, uint8_t id)
{
    controller._handleResult(commandFor(type, id).command, AmmoLauncherController::Result::Denied);
}

void AmmoLauncherTest::_arm(AmmoLauncherController &controller)
{
    controller.arm();
    QCOMPARE(_sent.last(), _cmd(kTypeArm, kIdArm));
    _accept(controller, kTypeArm, kIdArm);
    QVERIFY(controller.armed());
    _sent.clear();
}

QString AmmoLauncherTest::_cmd(uint8_t type, uint8_t id)
{
    return format(commandFor(type, id));
}

void AmmoLauncherTest::_commandMappingTest()
{
    // The flight controller's table: DO_GRIPPER for ARM, servos and the salvo, the raw
    // frame (USER_1 data type / id) for DISARM.
    QCOMPARE(_cmd(kTypeArm, kIdArm), QStringLiteral("211 0 1"));
    QCOMPARE(_cmd(kTypeArm, kIdDisarm), QStringLiteral("31010 241 208"));
    QCOMPARE(_cmd(kTypeServo, 0x01), QStringLiteral("211 1 0"));
    QCOMPARE(_cmd(kTypeServo, 0x0C), QStringLiteral("211 12 0"));
    QCOMPARE(_cmd(kTypeServo, kIdSalvo), QStringLiteral("211 0 0"));

    QCOMPARE(slotCountForValue(8), 8);
    QCOMPARE(slotCountForValue(10), 10);
    QCOMPARE(slotCountForValue(12), 12);
    QCOMPARE(slotCountForValue(0), 0);
    QCOMPARE(slotCountForValue(9), 0);
}

void AmmoLauncherTest::_slotValueTest()
{
    AmmoLauncherController controller;

    // MECH_SLOT arrives as NAMED_VALUE_FLOAT; other names are not the launcher.
    auto send = [&controller](const char *name, float value) {
        mavlink_message_t message;
        (void) mavlink_msg_named_value_float_pack(1, MAV_COMP_ID_AUTOPILOT1, &message, 0, name, value);
        controller._mavlinkMessageReceived(message);
    };

    send("OTHER", 10);
    QVERIFY(!controller.connected());

    send(kSlotValueName, 10);
    QVERIFY(controller.connected());
    QCOMPARE(controller.slotCount(), 10);

    // A name that fills the whole 10 character field is not null terminated.
    send("MECH_SLOTS", 12);
    QCOMPARE(controller.slotCount(), 10);
}

void AmmoLauncherTest::_heartbeatTest()
{
    AmmoLauncherController controller;
    QVERIFY(!controller.connected());
    QCOMPARE(controller.slotCount(), 0);

    _setUp(controller, 10, true);
    QVERIFY(controller.connected());
    QCOMPARE(controller.slotCount(), 10);
    QCOMPARE(controller.slotStates(), States(10, R));

    // Another launcher resets the slots.
    controller.toggleSlot(0);
    controller._handleSlotValue(12);
    QCOMPARE(controller.slotCount(), 12);
    QCOMPARE(controller.slotStates(), States(12, R));
}

void AmmoLauncherTest::_armOnlyWhileFlyingTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 8, false);

    QSignalSpy failed(&controller, &AmmoLauncherController::commandFailed);
    QVERIFY(!controller.canArm());
    controller.arm();
    QVERIFY(_sent.isEmpty());
    QCOMPARE(failed.count(), 1);

    controller._vehicleFlyingChanged(true);
    QVERIFY(controller.canArm());
    controller.arm();
    QCOMPARE(_sent, QList<QString>{ _cmd(kTypeArm, kIdArm) });
    QVERIFY(controller.busy());
    QVERIFY(!controller.armed());

    // Selecting is allowed while disarmed, firing is not.
    _deny(controller, kTypeArm, kIdArm);
    QVERIFY(!controller.armed());
    QVERIFY(!controller.busy());
    QCOMPARE(failed.count(), 2);
    controller.toggleSlot(1);
    QVERIFY(!controller.canFire());

    controller.arm();
    _accept(controller, kTypeArm, kIdArm);
    QVERIFY(controller.armed());
    QVERIFY(controller.canFire());
}

void AmmoLauncherTest::_groundArmSettingTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 10, false);
    QVERIFY(!controller.canArm());

    // The bench test setting arms on the ground.
    controller._setGroundArmAllowed(true);
    QVERIFY(controller.canArm());
    _arm(controller);

    // Turning it off on the ground disarms like a landing.
    controller._setGroundArmAllowed(false);
    QVERIFY(!controller.armed());
    QCOMPARE(_sent, QList<QString>{ _cmd(kTypeArm, kIdDisarm) });
    _accept(controller, kTypeArm, kIdDisarm);
    QVERIFY(!controller.busy());
    QVERIFY(!controller.canArm());
}

void AmmoLauncherTest::_fireSelectedTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 10, true);
    _arm(controller);

    controller.toggleSlot(1);
    controller.toggleSlot(4);
    controller.toggleSlot(7);
    controller.toggleSlot(7);
    controller.fire();

    // One command at a time, each waiting for its COMMAND_ACK.
    QCOMPARE(_sent, QList<QString>{ _cmd(kTypeServo, 0x02) });
    QVERIFY(controller.busy());
    QVERIFY(!controller.canFire());

    _accept(controller, kTypeServo, 0x02);
    QCOMPARE(_sent.last(), _cmd(kTypeServo, 0x05));
    _accept(controller, kTypeServo, 0x05);
    QCOMPARE(_sent.size(), 2);
    QVERIFY(!controller.busy());

    States expected(10, R);
    expected[1] = E;
    expected[4] = E;
    QCOMPARE(controller.slotStates(), expected);

    // Empty slots cannot be selected again.
    controller.toggleSlot(1);
    QCOMPARE(controller.slotStates(), expected);
}

void AmmoLauncherTest::_salvoTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 12, true);
    _arm(controller);

    controller.selectAll();
    controller.fire();
    QCOMPARE(_sent, QList<QString>{ _cmd(kTypeServo, kIdSalvo) });
    _accept(controller, kTypeServo, kIdSalvo);
    QCOMPARE(controller.slotStates(), States(12, E));

    // With a slot already fired, "all" goes out servo by servo.
    AmmoLauncherController partial;
    _sent.clear();
    _setUp(partial, 8, true);
    _arm(partial);
    partial.toggleSlot(0);
    partial.fire();
    _accept(partial, kTypeServo, 0x01);
    _sent.clear();
    partial.selectAll();
    partial.fire();
    QCOMPARE(_sent, QList<QString>{ _cmd(kTypeServo, 0x02) });
}

void AmmoLauncherTest::_deniedDropsFiringTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 8, true);
    _arm(controller);

    QSignalSpy failed(&controller, &AmmoLauncherController::commandFailed);
    controller.toggleSlot(0);
    controller.toggleSlot(1);
    controller.fire();
    _deny(controller, kTypeServo, 0x01);

    QCOMPARE(failed.count(), 1);
    QCOMPARE(_sent.size(), 1);
    QVERIFY(!controller.busy());
    QCOMPARE(controller.slotStates(), States(8, R));
    QVERIFY(controller.armed());
}

void AmmoLauncherTest::_failedNotRetriedTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 8, true);
    _arm(controller);

    // No answer from the launcher (FAILED) or from the flight controller: the operator
    // decides, nothing is sent again.
    QSignalSpy failed(&controller, &AmmoLauncherController::commandFailed);
    controller.toggleSlot(2);
    controller.toggleSlot(3);
    controller.fire();
    controller._handleResult(commandFor(kTypeServo, 0x03).command, AmmoLauncherController::Result::Failed);
    QCOMPARE(failed.count(), 1);
    QCOMPARE(_sent, QList<QString>{ _cmd(kTypeServo, 0x03) });
    QCOMPARE(controller.slotStates(), States(8, R));

    _sent.clear();
    controller.toggleSlot(5);
    controller.fire();
    controller._handleResult(commandFor(kTypeServo, 0x06).command, AmmoLauncherController::Result::NoResponse);
    QCOMPARE(failed.count(), 2);
    QCOMPARE(_sent.size(), 1);
    QVERIFY(!controller.busy());

    // A result for a command that is not waiting is ignored.
    _accept(controller, kTypeServo, 0x06);
    QCOMPARE(controller.slotStates(), States(8, R));
}

void AmmoLauncherTest::_landingDisarmsTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 10, true);
    _arm(controller);

    controller._vehicleFlyingChanged(false);
    QVERIFY(!controller.armed());
    QCOMPARE(_sent, QList<QString>{ _cmd(kTypeArm, kIdDisarm) });
    _accept(controller, kTypeArm, kIdDisarm);
    QVERIFY(!controller.busy());
    QVERIFY(!controller.canArm());
}

void AmmoLauncherTest::_disarmDropsFiringTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 8, true);
    _arm(controller);

    controller.toggleSlot(0);
    controller.toggleSlot(1);
    controller.toggleSlot(2);
    controller.fire();
    controller.disarm();
    QVERIFY(!controller.armed());

    // Servo 1 is already sent; DISARM goes next and servos 2 and 3 never go.
    _accept(controller, kTypeServo, 0x01);
    QCOMPARE(_sent, (QList<QString>{ _cmd(kTypeServo, 0x01), _cmd(kTypeArm, kIdDisarm) }));
    _accept(controller, kTypeArm, kIdDisarm);
    QVERIFY(!controller.busy());

    States expected(8, R);
    expected[0] = E;
    QCOMPARE(controller.slotStates(), expected);
}

void AmmoLauncherTest::_heartbeatLossTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 8, true);
    _arm(controller);

    controller.toggleSlot(3);
    controller._lastHeartbeat.invalidate();
    controller._checkHeartbeat();

    QVERIFY(!controller.connected());
    QVERIFY(!controller.armed());
    QVERIFY(!controller.canArm());
    // The slots stay as they were: the same launcher may come back.
    QCOMPARE(controller.slotCount(), 8);
    QCOMPARE(controller.slotStates(), States(8, R));

    controller._handleSlotValue(8);
    QVERIFY(controller.connected());
    QVERIFY(controller.canArm());
}

void AmmoLauncherTest::_slotValueZeroTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 10, true);
    _arm(controller);

    controller.toggleSlot(0);
    controller.fire();
    QVERIFY(controller.busy());

    // MECH_SLOT 0: the flight controller has lost the launcher's heartbeat.
    QSignalSpy failed(&controller, &AmmoLauncherController::commandFailed);
    controller._handleSlotValue(0);
    QVERIFY(!controller.connected());
    QVERIFY(!controller.armed());
    QVERIFY(!controller.busy());
    QCOMPARE(failed.count(), 1);
    QCOMPARE(controller.slotStates(), States(10, R));
}

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
    controller._sendHook = [this](const QByteArray &packet) {
        _sent.append(packet);
        return true;
    };
    controller._setFlying(flying);
    const uint8_t heartbeat = (slotCount == 8) ? 0x08 : (slotCount == 10) ? 0x10 : 0x12;
    _receive(controller, kTypeHeartbeat, heartbeat);
}

void AmmoLauncherTest::_receive(AmmoLauncherController &controller, uint8_t type, uint8_t id)
{
    controller._handleBytes(build(type, id));
}

void AmmoLauncherTest::_arm(AmmoLauncherController &controller)
{
    controller.arm();
    QCOMPARE(_sent.last(), build(kTypeArm, kIdArm));
    _receive(controller, kTypeAck, kIdArm);
    QVERIFY(controller.armed());
    _sent.clear();
}

void AmmoLauncherTest::_packetTest()
{
    QCOMPARE(build(kTypeArm, kIdArm), QByteArray::fromHex("a5f1a051b6"));
    QCOMPARE(build(kTypeServo, 0x03), QByteArray::fromHex("a51f031cb6"));
    QCOMPARE(build(kTypeServo, kIdSalvo), QByteArray::fromHex("a51fffe0b6"));

    QCOMPARE(slotCountForHeartbeat(0x08), 8);
    QCOMPARE(slotCountForHeartbeat(0x10), 10);
    QCOMPARE(slotCountForHeartbeat(0x12), 12);
    QCOMPARE(slotCountForHeartbeat(0x0A), 0);
    QCOMPARE(slotCountForHeartbeat(0x0C), 0);
}

void AmmoLauncherTest::_parserTest()
{
    Parser parser;

    // Noise before a packet, a packet split over two reads, and a bad CRC between two
    // good packets.
    QList<Packet> packets = parser.feed(QByteArray::fromHex("0012a5f1"));
    QVERIFY(packets.isEmpty());
    packets = parser.feed(QByteArray::fromHex("a051b6"));
    QCOMPARE(packets.size(), 1);
    QCOMPARE(packets[0].type, kTypeArm);
    QCOMPARE(packets[0].id, kIdArm);

    QByteArray stream = build(kTypeAck, 0x02);
    stream += QByteArray::fromHex("a51f0300b6");
    stream += build(kTypeHeartbeat, 0x10);
    packets = parser.feed(stream);
    QCOMPARE(packets.size(), 2);
    QCOMPARE(packets[0].type, kTypeAck);
    QCOMPARE(packets[0].id, uint8_t(0x02));
    QCOMPARE(packets[1].type, kTypeHeartbeat);
    QCOMPARE(packets[1].id, uint8_t(0x10));

    // A start byte inside a broken frame still begins the next packet.
    packets = parser.feed(QByteArray::fromHex("a5a5f1d021b6"));
    QCOMPARE(packets.size(), 1);
    QCOMPARE(packets[0].id, kIdDisarm);
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

    // An unknown id is not a launcher.
    _receive(controller, kTypeHeartbeat, 0x0A);
    QCOMPARE(controller.slotCount(), 10);

    // Another launcher resets the slots.
    controller.toggleSlot(0);
    _receive(controller, kTypeHeartbeat, 0x12);
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
    QCOMPARE(_sent, QList<QByteArray>{ build(kTypeArm, kIdArm) });
    QVERIFY(controller.busy());
    QVERIFY(!controller.armed());

    // Selecting is allowed while disarmed, firing is not.
    controller._handleBytes(build(kTypeNack, kIdArm));
    QVERIFY(!controller.armed());
    QVERIFY(!controller.busy());
    QCOMPARE(failed.count(), 2);
    controller.toggleSlot(1);
    QVERIFY(!controller.canFire());

    controller.arm();
    _receive(controller, kTypeAck, kIdArm);
    QVERIFY(controller.armed());
    QVERIFY(controller.canFire());
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

    // One command at a time, each waiting for its ACK.
    QCOMPARE(_sent, QList<QByteArray>{ build(kTypeServo, 0x02) });
    QVERIFY(controller.busy());
    QVERIFY(!controller.canFire());

    _receive(controller, kTypeAck, 0x02);
    QCOMPARE(_sent.last(), build(kTypeServo, 0x05));
    _receive(controller, kTypeAck, 0x05);
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
    QCOMPARE(_sent, QList<QByteArray>{ build(kTypeServo, kIdSalvo) });
    _receive(controller, kTypeAck, kIdSalvo);
    QCOMPARE(controller.slotStates(), States(12, E));

    // With a slot already fired, "all" goes out servo by servo.
    AmmoLauncherController partial;
    _sent.clear();
    _setUp(partial, 8, true);
    _arm(partial);
    partial.toggleSlot(0);
    partial.fire();
    _receive(partial, kTypeAck, 0x01);
    _sent.clear();
    partial.selectAll();
    partial.fire();
    QCOMPARE(_sent, QList<QByteArray>{ build(kTypeServo, 0x02) });
}

void AmmoLauncherTest::_nackDropsFiringTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 8, true);
    _arm(controller);

    QSignalSpy failed(&controller, &AmmoLauncherController::commandFailed);
    controller.toggleSlot(0);
    controller.toggleSlot(1);
    controller.fire();
    _receive(controller, kTypeNack, 0x01);

    QCOMPARE(failed.count(), 1);
    QCOMPARE(_sent.size(), 1);
    QVERIFY(!controller.busy());
    QCOMPARE(controller.slotStates(), States(8, R));
    QVERIFY(controller.armed());
}

void AmmoLauncherTest::_retryTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 8, true);
    controller._ackTimer->setInterval(20);

    QSignalSpy failed(&controller, &AmmoLauncherController::commandFailed);
    controller.arm();
    QTRY_COMPARE_WITH_TIMEOUT(failed.count(), 1, 2000);

    // The first try and every retry.
    QCOMPARE(_sent.size(), 1 + AmmoLauncherController::kMaxRetries);
    for (const QByteArray &packet : _sent) {
        QCOMPARE(packet, build(kTypeArm, kIdArm));
    }
    QVERIFY(!controller.busy());
    QVERIFY(!controller.armed());
}

void AmmoLauncherTest::_landingDisarmsTest()
{
    AmmoLauncherController controller;
    _setUp(controller, 10, true);
    _arm(controller);

    controller._vehicleFlyingChanged(false);
    QVERIFY(!controller.armed());
    QCOMPARE(_sent, QList<QByteArray>{ build(kTypeArm, kIdDisarm) });
    _receive(controller, kTypeAck, kIdDisarm);
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

    // Servo 1 is already on the wire; DISARM goes next and servos 2 and 3 never go.
    _receive(controller, kTypeAck, 0x01);
    QCOMPARE(_sent, (QList<QByteArray>{ build(kTypeServo, 0x01), build(kTypeArm, kIdDisarm) }));
    _receive(controller, kTypeAck, kIdDisarm);
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

    _receive(controller, kTypeHeartbeat, 0x08);
    QVERIFY(controller.connected());
    QVERIFY(controller.canArm());
}

#include "SkydroidGimbalTest.h"
#include "SettingsManager.h"
#include "SkydroidGimbalController.h"
#include "SkydroidGimbalSettings.h"

#include <QtCore/QElapsedTimer>
#include <QtTest/QTest>

namespace {
constexpr int kPitchChannel = 9;

QList<Fact *> gimbalFacts()
{
    SkydroidGimbalSettings *s = SettingsManager::instance()->skydroidGimbalSettings();
    return { s->enabled(), s->address(), s->port(), s->rcControlEnabled(), s->pitchChannel(),
             s->yawChannel(), s->zoomChannel(), s->pitchReversed(), s->yawReversed(),
             s->maxSpeed(), s->rcDeadband(), s->rcMin(), s->rcMax() };
}
}

void SkydroidGimbalTest::init()
{
    UnitTest::init();

    _savedSettings.clear();
    for (Fact *fact : gimbalFacts()) {
        _savedSettings.insert(fact->name(), fact->rawValue());
    }

    // Loopback, so the controller has a socket to drive without putting anything on
    // a real network.
    SkydroidGimbalSettings *s = SettingsManager::instance()->skydroidGimbalSettings();
    s->address()->setRawValue(QStringLiteral("127.0.0.1"));
    s->port()->setRawValue(5000);
    s->enabled()->setRawValue(true);
    s->rcControlEnabled()->setRawValue(true);
    s->pitchChannel()->setRawValue(kPitchChannel);
    s->yawChannel()->setRawValue(10);
    s->zoomChannel()->setRawValue(11);
    s->pitchReversed()->setRawValue(false);
    s->yawReversed()->setRawValue(false);
    s->maxSpeed()->setRawValue(60);
    s->rcDeadband()->setRawValue(60);
    s->rcMin()->setRawValue(1000);
    s->rcMax()->setRawValue(2000);
}

void SkydroidGimbalTest::cleanup()
{
    for (Fact *fact : gimbalFacts()) {
        fact->setRawValue(_savedSettings.value(fact->name()));
    }

    UnitTest::cleanup();
}

void SkydroidGimbalTest::_sendRc(SkydroidGimbalController &controller, int channel, int pwm)
{
    int pwmValues[QGCMAVLink::maxRcChannels];
    for (int &value : pwmValues) {
        value = 1500;
    }
    pwmValues[channel - 1] = pwm;
    controller._rcChannelsChanged(16, pwmValues);
}

/// The expected values here were read out of the Skydroid ground station's own
/// binary, so they are what the pod is known to accept rather than a guess at
/// the protocol.

void SkydroidGimbalTest::_checksumTest()
{
    // "#TPPG2rGIC00" ships in the stock binary with its checksum already
    // attached as "35", which pins down both the byte range that is summed
    // (all of it, including the "#TP" header) and the formatting.
    QCOMPARE(SkydroidGimbalController::checksumHex(QByteArrayLiteral("#TPPG2rGIC00")), QStringLiteral("35"));

    // Sum is taken modulo 256 and always printed as two upper-case digits.
    QCOMPARE(SkydroidGimbalController::checksumHex(QByteArray()), QStringLiteral("00"));
    QCOMPARE(SkydroidGimbalController::checksumHex(QByteArrayLiteral("\x01")), QStringLiteral("01"));
    QCOMPARE(SkydroidGimbalController::checksumHex(QByteArrayLiteral("\xFF\x01")), QStringLiteral("00"));
    QCOMPARE(SkydroidGimbalController::checksumHex(QByteArrayLiteral("\xFF")), QStringLiteral("FF"));
}

void SkydroidGimbalTest::_speedEncodingTest()
{
    // The pod reads the speed as a signed byte, and the ground station masks it
    // to 0xFF before formatting, so negatives go out as two's complement.
    QCOMPARE(SkydroidGimbalController::speedCommand(QStringLiteral("#TPUG2wGSP"), 30),
             QStringLiteral("#TPUG2wGSP1E"));
    QCOMPARE(SkydroidGimbalController::speedCommand(QStringLiteral("#TPUG2wGSP"), -30),
             QStringLiteral("#TPUG2wGSPE2"));
    QCOMPARE(SkydroidGimbalController::speedCommand(QStringLiteral("#TPUG2wGSY"), 0),
             QStringLiteral("#TPUG2wGSY00"));

    // Out of range values clamp rather than wrapping into a different speed.
    QCOMPARE(SkydroidGimbalController::speedCommand(QStringLiteral("#TPUG2wGSY"), 5000),
             QStringLiteral("#TPUG2wGSY7F"));
    QCOMPARE(SkydroidGimbalController::speedCommand(QStringLiteral("#TPUG2wGSY"), -5000),
             QStringLiteral("#TPUG2wGSY80"));
}

void SkydroidGimbalTest::_knownCommandsTest()
{
    // video_up() in the stock ground station is pitch +30, video_down() is -30.
    QCOMPARE(SkydroidGimbalController::buildCommand(
                 SkydroidGimbalController::speedCommand(QStringLiteral("#TPUG2wGSP"), 30)),
             QByteArrayLiteral("#TPUG2wGSP1E6C"));
    QCOMPARE(SkydroidGimbalController::buildCommand(
                 SkydroidGimbalController::speedCommand(QStringLiteral("#TPUG2wGSP"), -30)),
             QByteArrayLiteral("#TPUG2wGSPE26D"));

    // A command that carries no payload still gets a checksum.
    const QByteArray version = SkydroidGimbalController::buildCommand(QStringLiteral("#TPUD2rVER00"));
    QCOMPARE(version.size(), 14);
    QVERIFY(version.startsWith(QByteArrayLiteral("#TPUD2rVER00")));
    QCOMPARE(SkydroidGimbalController::checksumHex(QByteArrayLiteral("#TPUD2rVER00")),
             QString::fromLatin1(version.right(2)));
}

void SkydroidGimbalTest::_rcDeflectionAppliesTest()
{
    SkydroidGimbalController controller;

    _sendRc(controller, kPitchChannel, 2000);
    QCOMPARE(controller.pitchSpeed(), 60);

    _sendRc(controller, kPitchChannel, 1500);
    QCOMPARE(controller.pitchSpeed(), 0);
}

void SkydroidGimbalTest::_rcCentredStickKeepsButtonTest()
{
    SkydroidGimbalController controller;

    // A gimbal page button held down while the sticks sit centred: every packet
    // reports the same centred sticks, and none of them may cancel the button.
    controller.setPitchSpeed(30);
    _sendRc(controller, kPitchChannel, 1500);
    _sendRc(controller, kPitchChannel, 1500);
    QCOMPARE(controller.pitchSpeed(), 30);

    // Moving the stick still takes over.
    _sendRc(controller, kPitchChannel, 1000);
    QCOMPARE(controller.pitchSpeed(), -60);
}

void SkydroidGimbalTest::_rcWatchdogStopsTest()
{
    SkydroidGimbalController controller;

    _sendRc(controller, kPitchChannel, 2000);
    QCOMPARE(controller.pitchSpeed(), 60);

    // No more samples: the gimbal must stop on its own, and not before RC_CHANNELS
    // at a slow telemetry rate could have been expected to arrive.
    QElapsedTimer elapsed;
    elapsed.start();
    QTRY_COMPARE_WITH_TIMEOUT(controller.pitchSpeed(), 0, 4000);
    QVERIFY2(elapsed.elapsed() >= 1800, qPrintable(QStringLiteral("stopped after %1 ms").arg(elapsed.elapsed())));

    // Once input comes back with the stick still deflected, it moves again.
    _sendRc(controller, kPitchChannel, 2000);
    QCOMPARE(controller.pitchSpeed(), 60);
}

void SkydroidGimbalTest::_rcDisableStopsTest()
{
    SkydroidGimbalController controller;

    _sendRc(controller, kPitchChannel, 2000);
    QCOMPARE(controller.pitchSpeed(), 60);

    SettingsManager::instance()->skydroidGimbalSettings()->rcControlEnabled()->setRawValue(false);
    QCOMPARE(controller.pitchSpeed(), 0);

    // With RC control off, samples no longer move it.
    _sendRc(controller, kPitchChannel, 2000);
    QCOMPARE(controller.pitchSpeed(), 0);
}

#include "SkydroidGimbalTest.h"
#include "SettingsManager.h"
#include "SkydroidGimbalController.h"
#include "SkydroidGimbalSettings.h"
#include "VideoSettings.h"

#include <QtCore/QElapsedTimer>
#include <QtNetwork/QUdpSocket>
#include <QtTest/QTest>

namespace {
constexpr int kPitchChannel = 9;

QList<Fact *> gimbalFacts()
{
    SkydroidGimbalSettings *s = SettingsManager::instance()->skydroidGimbalSettings();
    VideoSettings *v = SettingsManager::instance()->videoSettings();
    return { s->enabled(), s->address(), s->port(), s->rcControlEnabled(), s->pitchChannel(),
             s->yawChannel(), s->zoomChannel(), s->pitchReversed(), s->yawReversed(),
             s->maxSpeed(), s->rcDeadband(), s->rcMin(), s->rcMax(),
             s->visibleRtspUrl(), s->thermalRtspUrl(), v->videoSource(), v->rtspUrl() };
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

void SkydroidGimbalTest::_sendRemote(SkydroidGimbalController &controller, int channel, int pwm)
{
    QList<int> channels(16, 1500);
    channels[channel - 1] = pwm;
    controller._remoteChannels(channels);
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

void SkydroidGimbalTest::_remoteOverridesVehicleTest()
{
    SkydroidGimbalController controller;

    _sendRemote(controller, kPitchChannel, 2000);
    QCOMPARE(controller.pitchSpeed(), 60);
    QCOMPARE(controller.rcSource(), static_cast<int>(SkydroidGimbalController::RcSourceRemote));

    // While the controller's own values are fresh, the autopilot's slower copy of the
    // same sticks is not mixed in, even when it disagrees.
    _sendRc(controller, kPitchChannel, 1000);
    QCOMPARE(controller.pitchSpeed(), 60);
    QCOMPARE(controller.rcSource(), static_cast<int>(SkydroidGimbalController::RcSourceRemote));
}

void SkydroidGimbalTest::_remoteWatchdogTest()
{
    SkydroidGimbalController controller;

    _sendRemote(controller, kPitchChannel, 2000);
    QCOMPARE(controller.pitchSpeed(), 60);

    // Polled locally every 100 ms, so the remote controller gets a much shorter leash
    // than an autopilot on a telemetry radio.
    QElapsedTimer elapsed;
    elapsed.start();
    QTRY_COMPARE_WITH_TIMEOUT(controller.pitchSpeed(), 0, 2000);
    QVERIFY2(elapsed.elapsed() >= 400, qPrintable(QStringLiteral("stopped after %1 ms").arg(elapsed.elapsed())));
    QVERIFY2(elapsed.elapsed() < 1500, qPrintable(QStringLiteral("stopped after %1 ms").arg(elapsed.elapsed())));
    QCOMPARE(controller.rcSource(), static_cast<int>(SkydroidGimbalController::RcSourceNone));
}

void SkydroidGimbalTest::_vehicleTakesOverAfterRemoteTest()
{
    SkydroidGimbalController controller;

    _sendRemote(controller, kPitchChannel, 1500);
    QTRY_COMPARE_WITH_TIMEOUT(controller.rcSource(), static_cast<int>(SkydroidGimbalController::RcSourceNone), 2000);

    // With the remote controller gone quiet, RC_CHANNELS from the autopilot drive it.
    _sendRc(controller, kPitchChannel, 1000);
    QCOMPARE(controller.pitchSpeed(), -60);
    QCOMPARE(controller.rcSource(), static_cast<int>(SkydroidGimbalController::RcSourceVehicle));
}

void SkydroidGimbalTest::_vehicleLossKeepsRemoteTest()
{
    SkydroidGimbalController controller;

    _sendRemote(controller, kPitchChannel, 2000);
    QCOMPARE(controller.pitchSpeed(), 60);

    // Those sticks never went through a vehicle, so losing one changes nothing.
    controller.setVehicle(nullptr);
    QCOMPARE(controller.pitchSpeed(), 60);
    QCOMPARE(controller.rcSource(), static_cast<int>(SkydroidGimbalController::RcSourceRemote));
}

void SkydroidGimbalTest::_parseReplyTest()
{
    QString command;
    QString data;

    // A reply built the same way the pod builds it, checksum and all.
    const QByteArray recording = SkydroidGimbalController::buildCommand(QStringLiteral("#TPDU2rREC01"));
    QVERIFY(SkydroidGimbalController::parseReply(recording, &command, &data));
    QCOMPARE(command, QStringLiteral("REC"));
    QCOMPARE(data, QStringLiteral("01"));

    // Longer data, as the length digit says.
    const QByteArray version = SkydroidGimbalController::buildCommand(QStringLiteral("#TPDU6rVER1.2.30"));
    QVERIFY(SkydroidGimbalController::parseReply(version, &command, &data));
    QCOMPARE(command, QStringLiteral("VER"));
    QCOMPARE(data, QStringLiteral("1.2.30"));

    // A corrupted checksum, a length that disagrees with the frame, and something that
    // is not a frame at all are all refused rather than half read.
    QByteArray badChecksum = recording;
    badChecksum[badChecksum.size() - 1] = (badChecksum.at(badChecksum.size() - 1) == '0') ? '1' : '0';
    QVERIFY(!SkydroidGimbalController::parseReply(badChecksum, &command, &data));
    QVERIFY(!SkydroidGimbalController::parseReply(recording.left(recording.size() - 3), &command, &data));
    QVERIFY(!SkydroidGimbalController::parseReply(QByteArrayLiteral("hello"), &command, &data));
    QVERIFY(!SkydroidGimbalController::parseReply(QByteArray(), &command, &data));
}

void SkydroidGimbalTest::_thermalToggleTest()
{
    SkydroidGimbalSettings *s = SettingsManager::instance()->skydroidGimbalSettings();
    VideoSettings *v = SettingsManager::instance()->videoSettings();

    // The C13's thermal stream is on port 555, not the visible camera's 554, which is
    // what swapping the stream number alone got wrong.
    QCOMPARE(s->thermalRtspUrl()->rawDefaultValue().toString(), QStringLiteral("rtsp://192.168.144.108:555/stream=2"));
    QCOMPARE(s->visibleRtspUrl()->rawDefaultValue().toString(), QStringLiteral("rtsp://192.168.144.108:554/stream=1"));

    s->visibleRtspUrl()->setRawValue(s->visibleRtspUrl()->rawDefaultValue());
    s->thermalRtspUrl()->setRawValue(s->thermalRtspUrl()->rawDefaultValue());

    SkydroidGimbalController controller;

    // Not an RTSP source: nothing to switch.
    v->videoSource()->setRawValue(QString::fromLatin1(VideoSettings::videoSourceNoVideo));
    QVERIFY(!controller.thermalAvailable());

    v->videoSource()->setRawValue(QString::fromLatin1(VideoSettings::videoSourceRTSP));
    v->rtspUrl()->setRawValue(QStringLiteral("rtsp://192.168.144.108:554/stream=1"));
    QVERIFY(controller.thermalAvailable());
    QVERIFY(!controller.thermalView());

    controller.toggleThermal();
    QCOMPARE(v->rtspUrl()->rawValue().toString(), QStringLiteral("rtsp://192.168.144.108:555/stream=2"));
    QVERIFY(controller.thermalView());

    controller.toggleThermal();
    QCOMPARE(v->rtspUrl()->rawValue().toString(), QStringLiteral("rtsp://192.168.144.108:554/stream=1"));
    QVERIFY(!controller.thermalView());

    // The URL the earlier build left behind (thermal path on the visible port) is not a
    // working stream. One press lands on the real thermal stream, the next on visible.
    v->rtspUrl()->setRawValue(QStringLiteral("rtsp://192.168.144.108:554/stream=2"));
    QVERIFY(!controller.thermalView());
    controller.toggleThermal();
    QCOMPARE(v->rtspUrl()->rawValue().toString(), QStringLiteral("rtsp://192.168.144.108:555/stream=2"));
    controller.toggleThermal();
    QCOMPARE(v->rtspUrl()->rawValue().toString(), QStringLiteral("rtsp://192.168.144.108:554/stream=1"));
}

void SkydroidGimbalTest::_podCommandsOnTheWireTest()
{
    // Stands in for the pod, so what the controller puts on the wire can be read back.
    QUdpSocket pod;
    QVERIFY(pod.bind(QHostAddress::LocalHost, 0));
    SettingsManager::instance()->skydroidGimbalSettings()->port()->setRawValue(pod.localPort());

    SkydroidGimbalController controller;

    const auto receive = [&pod](const QString &body) {
        const QByteArray expected = SkydroidGimbalController::buildCommand(body);
        QElapsedTimer waited;
        waited.start();
        while (waited.elapsed() < 2000) {
            while (pod.hasPendingDatagrams()) {
                QByteArray datagram(static_cast<int>(pod.pendingDatagramSize()), Qt::Uninitialized);
                pod.readDatagram(datagram.data(), datagram.size());
                // Zoom used to go out as #TPUG2wPTZ0A/0B, which re-set how the gimbal
                // is mounted. Nothing but the mount commands may send those.
                if ((body != QStringLiteral("#TPUG2wPTZ0A")) && (body != QStringLiteral("#TPUG2wPTZ0B"))) {
                    if (datagram.startsWith("#TPUG2wPTZ0A") || datagram.startsWith("#TPUG2wPTZ0B")) {
                        return false;
                    }
                }
                if (datagram == expected) {
                    return true;
                }
            }
            (void) pod.waitForReadyRead(50);
        }
        return false;
    };

    controller.zoomIn();
    QVERIFY(receive(QStringLiteral("#TPUD2wDZM0A")));
    controller.zoomStop();
    controller.zoomOut();
    QVERIFY(receive(QStringLiteral("#TPUD2wDZM0B")));
    controller.zoomStop();

    controller.centerGimbal();
    QVERIFY(receive(QStringLiteral("#TPUG2wPTZ05")));
    controller.lookDown();
    QVERIFY(receive(QStringLiteral("#TPUG2wPTZ02")));
    controller.takePhoto();
    QVERIFY(receive(QStringLiteral("#TPUD2wCAP01")));

    QVERIFY(!controller.recording());
    controller.toggleRecording();
    QVERIFY(receive(QStringLiteral("#TPUD2wREC01")));
    QVERIFY(controller.recording());
    controller.toggleRecording();
    QVERIFY(receive(QStringLiteral("#TPUD2wREC00")));
    QVERIFY(!controller.recording());

    controller.setMountHanging();
    QVERIFY(receive(QStringLiteral("#TPUG2wPTZ0A")));
    controller.setMountInverted();
    QVERIFY(receive(QStringLiteral("#TPUG2wPTZ0B")));
}

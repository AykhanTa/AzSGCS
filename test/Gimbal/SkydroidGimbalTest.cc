#include "SkydroidGimbalTest.h"
#include "SkydroidGimbalController.h"

#include <QtTest/QTest>

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

#include "VehicleGoToOptionsTest.h"
#include "FlyViewSettings.h"
#include "MockLink.h"
#include "SettingsManager.h"
#include "Vehicle.h"

#include <QtTest/QTest>

namespace {

/// A point the default 1000 m goto limit allows.
QGeoCoordinate nearbyTarget(Vehicle *vehicle)
{
    return vehicle->coordinate().atDistanceAndAzimuth(100, 90);
}

constexpr int kWaitMs = 10000;

}

void VehicleGoToOptionsTest::cleanup()
{
    _disconnectMockLink();
    UnitTest::cleanup();
}

void VehicleGoToOptionsTest::_connect(MAV_AUTOPILOT autopilot)
{
    _connectMockLink(autopilot);

    QTRY_VERIFY_WITH_TIMEOUT(_vehicle->coordinate().isValid(), kWaitMs);
    QTRY_VERIFY_WITH_TIMEOUT(!qIsNaN(_vehicle->altitudeAMSL()->rawValue().toDouble()), kWaitMs);
    QTRY_VERIFY_WITH_TIMEOUT(!qIsNaN(_vehicle->altitudeRelative()->rawValue().toDouble()), kWaitMs);
    QTRY_VERIFY_WITH_TIMEOUT(_vehicle->homePosition().isValid() && !qIsNaN(_vehicle->homePosition().altitude()), kWaitMs);

    _mockLink->clearReceivedMavCommandCounts();
}

bool VehicleGoToOptionsTest::_nothingSent(Vehicle *vehicle)
{
    // Validation happens before anything is queued, so this holds right after the call.
    return !vehicle->isMavCommandPending(vehicle->defaultComponentId(), MAV_CMD_DO_REPOSITION) &&
           !vehicle->isMavCommandPending(vehicle->defaultComponentId(), MAV_CMD_DO_CHANGE_SPEED) &&
           !vehicle->goToActive();
}

void VehicleGoToOptionsTest::_px4AltitudeAndSpeed()
{
    _connect(MAV_AUTOPILOT_PX4);

    const QGeoCoordinate target = nearbyTarget(_vehicle);
    const double homeAMSL = _vehicle->homePosition().altitude();
    _vehicle->guidedModeGotoLocation(target, 0, 30 /* m above home */, 6 /* m/s */);

    // One reposition carries everything: no separate speed command.
    QTRY_COMPARE_WITH_TIMEOUT(_mockLink->receivedMavCommandCount(MAV_CMD_DO_REPOSITION), 1, kWaitMs);
    QCOMPARE(_mockLink->receivedMavCommandCount(MAV_CMD_DO_CHANGE_SPEED), 0);

    const MockLink::ReceivedMavCommand cmd = _mockLink->lastReceivedMavCommand(MAV_CMD_DO_REPOSITION);
    QCOMPARE(cmd.param1, 6.0f);
    QCOMPARE(static_cast<int>(cmd.param2) & MAV_DO_REPOSITION_FLAGS_CHANGE_MODE, static_cast<int>(MAV_DO_REPOSITION_FLAGS_CHANGE_MODE));
    QVERIFY(qAbs(cmd.param5 - target.latitude()) < 1e-5);
    QVERIFY(qAbs(cmd.param6 - target.longitude()) < 1e-5);
    QVERIFY(qAbs(cmd.param7 - (homeAMSL + 30)) < 0.01);
}

void VehicleGoToOptionsTest::_px4DefaultsKeepCurrent()
{
    _connect(MAV_AUTOPILOT_PX4);

    const double currentAMSL = _vehicle->altitudeAMSL()->rawValue().toDouble();
    _vehicle->guidedModeGotoLocation(nearbyTarget(_vehicle));

    QTRY_COMPARE_WITH_TIMEOUT(_mockLink->receivedMavCommandCount(MAV_CMD_DO_REPOSITION), 1, kWaitMs);
    const MockLink::ReceivedMavCommand cmd = _mockLink->lastReceivedMavCommand(MAV_CMD_DO_REPOSITION);
    QCOMPARE(cmd.param1, -1.0f);                            // PX4 default speed
    QVERIFY(qAbs(cmd.param7 - currentAMSL) < 1.0);          // altitude held
}

void VehicleGoToOptionsTest::_altitudeOutOfRangeRefused()
{
    _connect(MAV_AUTOPILOT_PX4);

    FlyViewSettings *const settings = SettingsManager::instance()->flyViewSettings();
    const double minAltitude = settings->guidedMinimumAltitude()->rawValue().toDouble();
    const double maxAltitude = settings->guidedMaximumAltitude()->rawValue().toDouble();

    _vehicle->guidedModeGotoLocation(nearbyTarget(_vehicle), 0, maxAltitude + 1);
    QVERIFY(_nothingSent(_vehicle));

    _vehicle->guidedModeGotoLocation(nearbyTarget(_vehicle), 0, minAltitude - 1);
    QVERIFY(_nothingSent(_vehicle));
}

void VehicleGoToOptionsTest::_speedOutOfRangeRefused()
{
    _connect(MAV_AUTOPILOT_PX4);

    _vehicle->guidedModeGotoLocation(nearbyTarget(_vehicle), 0, qQNaN(), 0);
    QVERIFY(_nothingSent(_vehicle));

    _vehicle->guidedModeGotoLocation(nearbyTarget(_vehicle), 0, qQNaN(), -3);
    QVERIFY(_nothingSent(_vehicle));

    // MockLink's PX4 parameters include MPC_XY_VEL_MAX, which caps a multirotor's speed.
    QVERIFY(_vehicle->haveMRSpeedLimits());
    _vehicle->guidedModeGotoLocation(nearbyTarget(_vehicle), 0, qQNaN(), _vehicle->maximumHorizontalSpeedMultirotor() + 1);
    QVERIFY(_nothingSent(_vehicle));
}

void VehicleGoToOptionsTest::_apmAltitudeAndSpeed()
{
    _connect(MAV_AUTOPILOT_ARDUPILOTMEGA);

    const QGeoCoordinate target = nearbyTarget(_vehicle);
    const double homeAMSL = _vehicle->homePosition().altitude();
    _vehicle->guidedModeGotoLocation(target, 0, 25 /* m above home */, 4 /* m/s */);

    // ArduPilot gets the speed as its own command, as ground speed for a copter.
    QTRY_COMPARE_WITH_TIMEOUT(_mockLink->receivedMavCommandCount(MAV_CMD_DO_CHANGE_SPEED), 1, kWaitMs);
    const MockLink::ReceivedMavCommand speedCmd = _mockLink->lastReceivedMavCommand(MAV_CMD_DO_CHANGE_SPEED);
    QCOMPARE(speedCmd.param1, 1.0f);
    QCOMPARE(speedCmd.param2, 4.0f);

    QTRY_COMPARE_WITH_TIMEOUT(_mockLink->receivedMavCommandCount(MAV_CMD_DO_REPOSITION), 1, kWaitMs);
    const MockLink::ReceivedMavCommand repositionCmd = _mockLink->lastReceivedMavCommand(MAV_CMD_DO_REPOSITION);
    QVERIFY(repositionCmd.commandInt);
    QVERIFY(qAbs(repositionCmd.param5 - target.latitude()) < 1e-6);
    QVERIFY(qAbs(repositionCmd.param6 - target.longitude()) < 1e-6);
    QVERIFY(qAbs(repositionCmd.param7 - (homeAMSL + 25)) < 0.01);
}

#include "VehicleGoToTargetTest.h"
#include "MockLink.h"
#include "Vehicle.h"

#include <QtTest/QTest>

namespace {

/// A point the default 1000 m goto limit allows.
QGeoCoordinate nearbyTarget(Vehicle *vehicle)
{
    return vehicle->coordinate().atDistanceAndAzimuth(100, 90);
}

}

void VehicleGoToTargetTest::init()
{
    UnitTest::init();
    _connectMockLink(MAV_AUTOPILOT_PX4);

    // guidedModeGotoLocation() needs a position and an altitude to send anything.
    QTRY_VERIFY_WITH_TIMEOUT(_vehicle->coordinate().isValid(), 10000);
    QTRY_VERIFY_WITH_TIMEOUT(!qIsNaN(_vehicle->altitudeAMSL()->rawValue().toDouble()), 10000);
}

void VehicleGoToTargetTest::cleanup()
{
    _disconnectMockLink();
    UnitTest::cleanup();
}

void VehicleGoToTargetTest::_gotoSetsTargetUntilModeLeft()
{
    // End to end through MockLink, which accepts the reposition and switches to Hold like PX4.
    _vehicle->setFlightMode(QStringLiteral("Position"));
    QTRY_COMPARE_WITH_TIMEOUT(_vehicle->flightMode(), QStringLiteral("Position"), 10000);

    const QGeoCoordinate target = nearbyTarget(_vehicle);
    _vehicle->guidedModeGotoLocation(target);

    QVERIFY(_vehicle->goToActive());
    QCOMPARE(_vehicle->goToCoordinate(), target);

    QTRY_COMPARE_WITH_TIMEOUT(_vehicle->flightMode(), _vehicle->gotoFlightMode(), 10000);
    QVERIFY(_vehicle->goToActive());

    _vehicle->setFlightMode(_vehicle->rtlFlightMode());
    QTRY_VERIFY_WITH_TIMEOUT(!_vehicle->goToActive(), 10000);
    QVERIFY(!_vehicle->goToCoordinate().isValid());
}

void VehicleGoToTargetTest::_modeBeforeEnteringKeepsTarget()
{
    // Right after the command the vehicle still reports the mode it was in. That is not a
    // departure from the goto, so it must not drop the target.
    _vehicle->setFlightMode(QStringLiteral("Position"));
    QTRY_COMPARE_WITH_TIMEOUT(_vehicle->flightMode(), QStringLiteral("Position"), 10000);

    _vehicle->_setGoToTarget(nearbyTarget(_vehicle));

    _vehicle->_goToFlightModeChanged(_vehicle->missionFlightMode());
    QVERIFY(_vehicle->goToActive());

    _vehicle->_goToFlightModeChanged(_vehicle->gotoFlightMode());
    QVERIFY(_vehicle->goToActive());

    _vehicle->_goToFlightModeChanged(_vehicle->missionFlightMode());
    QVERIFY(!_vehicle->goToActive());
}

void VehicleGoToTargetTest::_rejectedGotoClearsTarget()
{
    _vehicle->_setGoToTarget(nearbyTarget(_vehicle));
    QVERIFY(_vehicle->goToActive());

    _vehicle->_goToCommandResult(_vehicle->id(), MAV_COMP_ID_AUTOPILOT1, MAV_CMD_DO_REPOSITION, MAV_RESULT_DENIED, Vehicle::MavCmdResultCommandResultOnly);
    QVERIFY(!_vehicle->goToActive());
}

void VehicleGoToTargetTest::_unsupportedGotoClearsTarget()
{
    // A plugin reached through mavCommandResult has no fallback, so unsupported means the
    // vehicle is not going anywhere. (ArduPilot's fallback uses a result handler instead.)
    _vehicle->_setGoToTarget(nearbyTarget(_vehicle));

    _vehicle->_goToCommandResult(_vehicle->id(), MAV_COMP_ID_AUTOPILOT1, MAV_CMD_DO_REPOSITION, MAV_RESULT_UNSUPPORTED, Vehicle::MavCmdResultCommandResultOnly);
    QVERIFY(!_vehicle->goToActive());
}

void VehicleGoToTargetTest::_unrelatedCommandResultKeepsTarget()
{
    _vehicle->_setGoToTarget(nearbyTarget(_vehicle));

    // Another command failing says nothing about the goto.
    _vehicle->_goToCommandResult(_vehicle->id(), MAV_COMP_ID_AUTOPILOT1, MAV_CMD_DO_CHANGE_SPEED, MAV_RESULT_DENIED, Vehicle::MavCmdResultCommandResultOnly);
    QVERIFY(_vehicle->goToActive());

    // Once the goto's own ack has arrived, a later reposition result (an altitude change, say)
    // is not about this target either.
    _vehicle->_goToCommandResult(_vehicle->id(), MAV_COMP_ID_AUTOPILOT1, MAV_CMD_DO_REPOSITION, MAV_RESULT_ACCEPTED, Vehicle::MavCmdResultCommandResultOnly);
    _vehicle->_goToCommandResult(_vehicle->id(), MAV_COMP_ID_AUTOPILOT1, MAV_CMD_DO_REPOSITION, MAV_RESULT_DENIED, Vehicle::MavCmdResultCommandResultOnly);
    QVERIFY(_vehicle->goToActive());
}

void VehicleGoToTargetTest::_pauseClearsTarget()
{
    _vehicle->_setGoToTarget(nearbyTarget(_vehicle));
    _vehicle->_goToFlightModeChanged(_vehicle->gotoFlightMode());

    // PX4 pauses with a reposition to "here" and stays in Hold, so no mode change follows.
    _vehicle->pauseVehicle();
    QVERIFY(!_vehicle->goToActive());
}

void VehicleGoToTargetTest::_altitudeChangeKeepsTargetUnlessPaused()
{
    _vehicle->_setGoToTarget(nearbyTarget(_vehicle));
    _vehicle->_goToFlightModeChanged(_vehicle->gotoFlightMode());

    // PX4 keeps the current position setpoint when only the altitude changes.
    _vehicle->guidedModeChangeAltitude(5, false /* pauseVehicle */);
    QVERIFY(_vehicle->goToActive());

    _vehicle->guidedModeChangeAltitude(5, true /* pauseVehicle */);
    QVERIFY(!_vehicle->goToActive());
}

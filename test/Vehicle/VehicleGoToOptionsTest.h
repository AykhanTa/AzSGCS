#pragma once

#include "UnitTest.h"

class Vehicle;

/// Go To with a target altitude (above home) and speed: what reaches the autopilot, and what
/// is refused before anything is sent.
class VehicleGoToOptionsTest : public UnitTest
{
    Q_OBJECT

private slots:
    void cleanup() final;

    void _px4AltitudeAndSpeed();
    void _px4DefaultsKeepCurrent();
    void _altitudeOutOfRangeRefused();
    void _speedOutOfRangeRefused();
    void _apmAltitudeAndSpeed();

private:
    void _connect(MAV_AUTOPILOT autopilot);
    /// True once nothing for a goto is waiting on the vehicle and no target was set.
    bool _nothingSent(Vehicle *vehicle);
};

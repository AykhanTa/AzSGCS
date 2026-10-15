#pragma once

#include "UnitTest.h"

/// The goto target a vehicle keeps for the fly view (goToActive / goToCoordinate) must only
/// be shown while the vehicle is actually flying it.
class VehicleGoToTargetTest : public UnitTest
{
    Q_OBJECT

private slots:
    void init() final;
    void cleanup() final;

    void _gotoSetsTargetUntilModeLeft();
    void _modeBeforeEnteringKeepsTarget();
    void _rejectedGotoClearsTarget();
    void _unsupportedGotoClearsTarget();
    void _unrelatedCommandResultKeepsTarget();
    void _pauseClearsTarget();
    void _altitudeChangeKeepsTargetUnlessPaused();
};

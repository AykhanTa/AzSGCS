#pragma once

#include "UnitTest.h"

#include <QtCore/QByteArray>
#include <QtCore/QList>

class AmmoLauncherController;

class AmmoLauncherTest : public UnitTest
{
    Q_OBJECT

protected:
    void init() final;

private slots:
    void _packetTest();
    void _parserTest();
    void _heartbeatTest();
    void _armOnlyWhileFlyingTest();
    void _fireSelectedTest();
    void _salvoTest();
    void _nackDropsFiringTest();
    void _retryTest();
    void _landingDisarmsTest();
    void _disarmDropsFiringTest();
    void _heartbeatLossTest();

private:
    /// A controller wired to `_sent` instead of MAVLink, with a launcher of
    /// `slotCount` servos connected and the vehicle flying or not.
    void _setUp(AmmoLauncherController &controller, int slotCount, bool flying);
    static void _receive(AmmoLauncherController &controller, uint8_t type, uint8_t id);
    void _arm(AmmoLauncherController &controller);

    QList<QByteArray> _sent;
};

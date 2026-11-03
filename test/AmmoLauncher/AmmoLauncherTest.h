#pragma once

#include "UnitTest.h"

#include <QtCore/QList>
#include <QtCore/QString>

class AmmoLauncherController;

class AmmoLauncherTest : public UnitTest
{
    Q_OBJECT

protected:
    void init() final;

private slots:
    void _commandMappingTest();
    void _slotValueTest();
    void _heartbeatTest();
    void _armOnlyWhileFlyingTest();
    void _groundArmSettingTest();
    void _fireSelectedTest();
    void _salvoTest();
    void _deniedDropsFiringTest();
    void _failedNotRetriedTest();
    void _landingDisarmsTest();
    void _disarmDropsFiringTest();
    void _heartbeatLossTest();
    void _slotValueZeroTest();

private:
    /// A controller wired to `_sent` instead of MAVLink, with a launcher of
    /// `slotCount` servos connected and the vehicle flying or not.
    void _setUp(AmmoLauncherController &controller, int slotCount, bool flying);
    /// The COMMAND_ACK for the frame (type, id): accepted, or denied by the launcher.
    static void _accept(AmmoLauncherController &controller, uint8_t type, uint8_t id);
    static void _deny(AmmoLauncherController &controller, uint8_t type, uint8_t id);
    void _arm(AmmoLauncherController &controller);
    /// "command p1 p2" of the command that sends the frame (type, id).
    static QString _cmd(uint8_t type, uint8_t id);

    QList<QString> _sent;
};

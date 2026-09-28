#pragma once

#include "UnitTest.h"

#include <QtCore/QVariantMap>

class SkydroidGimbalController;

class SkydroidGimbalTest : public UnitTest
{
    Q_OBJECT

protected:
    void init() final;
    void cleanup() final;

private slots:
    void _checksumTest();
    void _speedEncodingTest();
    void _knownCommandsTest();
    void _rcDeflectionAppliesTest();
    void _rcCentredStickKeepsButtonTest();
    void _rcWatchdogStopsTest();
    void _rcDisableStopsTest();
    void _remoteOverridesVehicleTest();
    void _remoteWatchdogTest();
    void _vehicleTakesOverAfterRemoteTest();
    void _vehicleLossKeepsRemoteTest();
    void _parseReplyTest();
    void _thermalToggleTest();
    void _podCommandsOnTheWireTest();

private:
    /// Feeds one RC_CHANNELS sample with every channel centred except `channel`.
    static void _sendRc(SkydroidGimbalController &controller, int channel, int pwm);

    /// Same, as read off the Skydroid remote controller itself.
    static void _sendRemote(SkydroidGimbalController &controller, int channel, int pwm);

    QVariantMap _savedSettings;
};

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

private:
    /// Feeds one RC_CHANNELS sample with every channel centred except `channel`.
    static void _sendRc(SkydroidGimbalController &controller, int channel, int pwm);

    QVariantMap _savedSettings;
};

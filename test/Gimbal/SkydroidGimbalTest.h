#pragma once

#include "UnitTest.h"

class SkydroidGimbalTest : public UnitTest
{
    Q_OBJECT

private slots:
    void _checksumTest();
    void _speedEncodingTest();
    void _knownCommandsTest();
};

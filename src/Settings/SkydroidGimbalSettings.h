/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
#pragma once

#include <QtQmlIntegration/QtQmlIntegration>

#include "SettingsGroup.h"

class SkydroidGimbalSettings : public SettingsGroup
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    SkydroidGimbalSettings(QObject* parent = nullptr);
    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(enabled)
    DEFINE_SETTINGFACT(address)
    DEFINE_SETTINGFACT(port)
    DEFINE_SETTINGFACT(rcControlEnabled)
    DEFINE_SETTINGFACT(pitchChannel)
    DEFINE_SETTINGFACT(yawChannel)
    DEFINE_SETTINGFACT(zoomChannel)
    DEFINE_SETTINGFACT(pitchReversed)
    DEFINE_SETTINGFACT(yawReversed)
    DEFINE_SETTINGFACT(maxSpeed)
    DEFINE_SETTINGFACT(rcDeadband)
    DEFINE_SETTINGFACT(rcMin)
    DEFINE_SETTINGFACT(rcMax)
};

/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SkydroidGimbalSettings.h"

DECLARE_SETTINGGROUP(SkydroidGimbal, "SkydroidGimbal")
{
}

DECLARE_SETTINGSFACT(SkydroidGimbalSettings, enabled)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, address)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, port)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, visibleRtspUrl)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, thermalRtspUrl)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, rcControlEnabled)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, pitchChannel)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, yawChannel)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, zoomChannel)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, pitchReversed)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, yawReversed)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, maxSpeed)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, rcDeadband)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, rcMin)
DECLARE_SETTINGSFACT(SkydroidGimbalSettings, rcMax)

/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.Controls


// This class stores the data and functions of the check list but NOT the GUI (which is handled somewhere else).
PreFlightCheckButton {
    name:                           qsTr("Batareya")
    manualText:                     qsTr("Batareya konnektoru möhkəm bağlanıb?")
    telemetryFailure:               _batLow
    telemetryTextFailure:           allowTelemetryFailureOverride ?
                                        qsTr("Xəbərdarlıq - Batareyanın doldurulması 1%-dən aşağıdır.").arg(failurePercent) :
                                        qsTr("Batareyanın doldurulması %1%-dən aşağıdır. Zəhmət olmasa doldurun.").arg(failurePercent)
    allowTelemetryFailureOverride:  allowFailurePercentOverride

    property int    failurePercent:                 40
    property bool   allowFailurePercentOverride:    false
    property var    _batteryGroup:                  globals.activeVehicle && globals.activeVehicle.batteries.count ? globals.activeVehicle.batteries.get(0) : undefined
    property var    _batteryValue:                  _batteryGroup ? _batteryGroup.percentRemaining.value : 0
    property var    _batPercentRemaining:           isNaN(_batteryValue) ? 0 : _batteryValue
    property bool   _batLow:                        _batPercentRemaining < failurePercent
}

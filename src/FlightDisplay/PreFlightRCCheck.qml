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


PreFlightCheckButton {
    name:                   qsTr("Radio Kontrol")
    manualText:             qsTr("Siqnal qəbulu. Aralığı test edin və təsdiqləyin.")
    telemetryTextFailure:   qsTr("Siqnal yoxdur və ya etibarsız avtopilot-RC konfiqurasiyası. RC və konsolu yoxlayın.")
    telemetryFailure:       false//_unhealthySensors & Vehicle.SysStatusSensorRCReceiver

    property int _unhealthySensors: globals.activeVehicle ? globals.activeVehicle.sensorsUnhealthyBits : 0
}

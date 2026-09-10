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
    name:               qsTr("Sensorlar")
    telemetryFailure:   _unhealthySensors & _allCheckedSensors

    property int    _unhealthySensors:  globals.activeVehicle ? globals.activeVehicle.sensorsUnhealthyBits : 1
    property int    _allCheckedSensors: Vehicle.SysStatusSensor3dMag |
                                        Vehicle.SysStatusSensor3dAccel |
                                        Vehicle.SysStatusSensor3dGyro |
                                        Vehicle.SysStatusSensorAbsolutePressure |
                                        Vehicle.SysStatusSensorDifferentialPressure |
                                        Vehicle.SysStatusSensorGPS |
                                        Vehicle.SysStatusSensorAHRS

    on_UnhealthySensorsChanged: updateTelemetryTextFailure()

    Component.onCompleted: updateTelemetryTextFailure()

    function updateTelemetryTextFailure() {
        if(_unhealthySensors & _allCheckedSensors) {
            if (_unhealthySensors & Vehicle.SysStatusSensor3dMag)                       telemetryTextFailure = qsTr("Uğursuzluq. Maqnitometr problemləri. Konsolu yoxlayın.")
            else if(_unhealthySensors & Vehicle.SysStatusSensor3dAccel)                 telemetryTextFailure = qsTr("Uğursuzluq. Akselerometr problemləri. Konsolu yoxlayın.")
            else if(_unhealthySensors & Vehicle.SysStatusSensor3dGyro)                  telemetryTextFailure = qsTr("Uğursuzluq. Giroskop problemləri. Konsolu yoxlayın.")
            else if(_unhealthySensors & Vehicle.SysStatusSensorAbsolutePressure)        telemetryTextFailure = qsTr("Uğursuzluq. Barometr problemləri. Konsolu yoxlayın.")
            else if(_unhealthySensors & Vehicle.SysStatusSensorDifferentialPressure)    telemetryTextFailure = qsTr("Uğursuzluq. Hava sürəti sensoru problemləri. Konsolu yoxlayın.")
            else if(_unhealthySensors & Vehicle.SysStatusSensorAHRS)                    telemetryTextFailure = qsTr("Uğursuzluq. AHRS problemləri. Konsolu yoxlayın.")
            else if(_unhealthySensors & Vehicle.SysStatusSensorGPS)                     telemetryTextFailure = qsTr("Uğursuzluq. GPS problemləri. Konsolu yoxlayın.")
        }
    }
}

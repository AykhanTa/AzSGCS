/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQml.Models

import QGroundControl

import QGroundControl.Controls
import QGroundControl.FlightDisplay


Item {
    property var model: listModel
    PreFlightCheckModel {
        id:     listModel
        PreFlightCheckGroup {
            name: qsTr("Sabit Qanadın İlkin Yoxlamaları")

            PreFlightCheckButton {
                name:           qsTr("Aparat")
                manualText:     qsTr("Pərvanələr bərkidildimi? Qanadlar sabitlənirmi? Quyruq sabitləndimi?")
            }

            PreFlightBatteryCheck {
                failurePercent:                 40
                allowFailurePercentOverride:    false
            }

            PreFlightSensorsHealthCheck {
            }

            PreFlightGPSCheck {
                failureSatCount:        9
                allowOverrideSatCount:  true
            }

            PreFlightRCCheck {
            }
        }

        PreFlightCheckGroup {
            name: qsTr("Zəhmət olmasa təyyarəni arm vəziyyətinə gətirin")

            PreFlightCheckButton {
                name:            qsTr("Aktuatorlar")
                manualText:      qsTr("Bütün nəzarət səthlərini hərəkət etdirin. Düzgün işlədilərmi?")
            }

            PreFlightCheckButton {
                name:            qsTr("Motorlar")
                manualText:      qsTr("Pərvanələr sərbəstdirmi? O zaman yavaşca throttle artırın. Düzgün işləyirmi?")
            }

            PreFlightCheckButton {
                name:           qsTr("Missiya")
                manualText:     qsTr("Lütfən, missiyanın etibarlı olduğunu təsdiqləyin (yol nöqtələri etibarlıdır, ərazi toqquşması yoxdur).")
            }
        }

        PreFlightCheckGroup {
            name: qsTr("Başlamadan əvvəl son hazırlıqlar")

            // Check list item group 2 - Final checks before launch
            PreFlightCheckButton {
                name:           qsTr("Payload")
                manualText:     qsTr("Konfiqurasiya edildi və başladı? Yük qapağı bağlanıb?")
            }

            PreFlightCheckButton {
                name:           qsTr("Külək və hava")
                manualText:     qsTr("Platformanız üçün yaxşıdır? Küləkdə atılır?")
            }

            PreFlightCheckButton {
                name:           qsTr("Uçuş sahəsi")
                manualText:     qsTr("Maneələrdən/insanlardan azad olan sahə və yolu işə salın?")
            }
        }
    }
}


/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls


import QGroundControl.FactControls


QGCPopupDialog {
    title:      qsTr("RC To Param")
    buttons:    Dialog.Cancel | Dialog.Ok

    property alias tuningFact: controller.tuningFact

    onAccepted: QGroundControl.multiVehicleManager.activeVehicle.sendParamMapRC(tuningFact.name, scale.text, centerValue.text, tuningID.currentIndex, minValue.text, maxValue.text)

    RCToParamDialogController {
        id: controller
    }

    ColumnLayout {
        spacing: ScreenTools.defaultDialogControlSpacing

        QGCLabel {
            Layout.preferredWidth:  mainGrid.width
            Layout.fillWidth:       true
            wrapMode:               Text.WordWrap
            text:                   qsTr("RC Kanalını parametr dəyərinə bağlayın. Sazlama identifikatorları Radio Quraşdırma səhifəsindən RC Kanalına uyğunlaşdırıla bilər.")
        }

        QGCLabel {
            Layout.preferredWidth:  mainGrid.width
            Layout.fillWidth:       true
            text:                   qsTr("Təyyarıdən parametr yeniləməsi gözlənilir.")
            visible:                !controller.ready
        }

        GridLayout {
            id:             mainGrid
            columns:        2
            rowSpacing:     ScreenTools.defaultDialogControlSpacing
            columnSpacing:  ScreenTools.defaultDialogControlSpacing
            enabled:        controller.ready

            QGCLabel { text: qsTr("Parameter") }
            QGCLabel { text: tuningFact.name }

            QGCLabel { text: qsTr("Tuning ID") }
            QGCComboBox {
                id:                 tuningID
                Layout.fillWidth:   true
                currentIndex:       0
                model:              [ 1, 2, 3 ]
            }

            QGCLabel { text: qsTr("Scale") }
            QGCTextField {
                id:     scale
                text:   controller.scale.valueString
            }

            QGCLabel { text: qsTr("Center Value") }
            QGCTextField {
                id:     centerValue
                text:   controller.center.valueString
            }

            QGCLabel { text: qsTr("Min Value") }
            QGCTextField {
                id:     minValue
                text:   controller.min.valueString
            }

            QGCLabel { text: qsTr("Max Value") }
            QGCTextField {
                id:     maxValue
                text:   controller.max.valueString
            }
        }

        QGCLabel {
            Layout.preferredWidth:  mainGrid.width
            Layout.fillWidth:       true
            wrapMode:               Text.WordWrap
            text:                   qsTr("Dialoq qutusunu təsdiqləməzdən əvvəl bütün dəyərlərin düzgün olub olmadığını iki dəfə yoxlayın.")
        }
    }
}

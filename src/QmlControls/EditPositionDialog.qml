import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl

import QGroundControl.Controls
import QGroundControl.FactControls



QGCPopupDialog {
    id:         root
    title:      qsTr("Mövqeyi redaktə edin")
    buttons:    Dialog.Close

    property alias coordinate:                  controller.coordinate
    property bool  showSetPositionFromVehicle:  true

    property real _margin:          ScreenTools.defaultFontPixelWidth / 2
    property real _textFieldWidth:  ScreenTools.defaultFontPixelWidth * 20
    property bool _showGeographic:  coordinateSystemCombo.comboBox.currentIndex === 0
    property bool _showUTM:         coordinateSystemCombo.comboBox.currentIndex === 1
    property bool _showMGRS:        coordinateSystemCombo.comboBox.currentIndex === 2
    property bool _showVehicle:     coordinateSystemCombo.comboBox.currentIndex === 3

    EditPositionDialogController {
        id: controller

        Component.onCompleted: initValues()
    }

    ColumnLayout {
        spacing: _margin

        LabelledComboBox {
            id:                 coordinateSystemCombo
            Layout.fillWidth:   true
            label:              qsTr("Koordinat sistemi")
            model:              showSetPositionFromVehicle && globals.activeVehicle ? 
                                    [ qsTr("Coğrafi"), qsTr("Universal Transverse Mercator"), qsTr("Hərbi şəbəkəyə istinad"), qsTr("Təyyarənin yeri") ] :
                                    [ qsTr("Coğrafi"), qsTr("Universal Transverse Mercator"), qsTr("Hərbi şəbəkəyə istinad") ]
        }

        LabelledFactTextField {
            label:              qsTr("Latitude")
            fact:               controller.latitude
            textFieldPreferredWidth: _textFieldWidth
            Layout.fillWidth:   true
            visible:            _showGeographic
        }

        LabelledFactTextField {
            label:              qsTr("Longitude")
            fact:               controller.longitude
            textFieldPreferredWidth: _textFieldWidth
            Layout.fillWidth:   true
            visible:            _showGeographic
        }

        LabelledButton {
            label:               qsTr("Mövqeyi təyin edin")
            buttonText:          qsTr("Hərəkət edin")
            visible:             _showGeographic
            onClicked: {
                controller.setFromGeo()
                root.close()
            }
        }

        LabelledFactTextField {
            label:              qsTr("Zone")
            fact:               controller.zone
            textFieldPreferredWidth: _textFieldWidth
            Layout.fillWidth:   true
            visible:            _showUTM
        }

        LabelledFactComboBox {
            label:              qsTr("Hemisphere")
            fact:               controller.hemisphere
            indexModel:         false
            Layout.fillWidth:   true
            visible:            _showUTM
        }

        LabelledFactTextField {
            label:              qsTr("Easting")
            fact:               controller.easting
            textFieldPreferredWidth: _textFieldWidth
            Layout.fillWidth:   true
            visible:            _showUTM
        }

        LabelledFactTextField {
            label:              qsTr("Northing")
            fact:               controller.northing
            textFieldPreferredWidth: _textFieldWidth
            Layout.fillWidth:   true
            visible:            _showUTM
        }

        LabelledButton {
            label:               qsTr("Mövqeyi təyin edin")
            buttonText:          qsTr("Hərəkət edin")
            visible:             _showUTM
            onClicked: {
                controller.setFromUTM()
                root.close()
            }
        }

        LabelledFactTextField {
            label:              qsTr("MGRS")
            fact:               controller.mgrs
            visible:            _showMGRS
            textFieldPreferredWidth: _textFieldWidth
            Layout.fillWidth:   true
        }

        LabelledButton {
            label:               qsTr("Mövqeyi təyin edin")
            buttonText:          qsTr("Hərəkət edin")
            visible:             _showMGRS
            onClicked: {
                controller.setFromMGRS()
                root.close()
            }
        }

        LabelledButton {
            label:               qsTr("Mövqeyi təyin edin")
            buttonText:          qsTr("Hərəkət edin")
            visible:             _showVehicle
            onClicked: {
                controller.setFromVehicle()
                root.close()
            }
        }
    }
}

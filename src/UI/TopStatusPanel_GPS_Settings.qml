import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

AzPopupFrame {
    id: overlay

    title: qsTr("RTK GPS Tənzimləmələri")
    cardWidth: AzTheme.px(AzTheme.popupWideWidth)

    onCloseRequested: {
        if (typeof settingsLoader !== "undefined" && settingsLoader) {
            settingsLoader.source = ""
        } else {
            overlay.panelVisible = false
        }
    }

    readonly property real _groupPad: AzTheme.px(AzTheme.groupPadding)

    // ---- QGC facts/settings (QGC source ilə eyni) ----
    property var rtkSettings: QGroundControl.settingsManager.rtkSettings
    property var autoConnectFact: QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS

    readonly property int _trimble:    1
    readonly property int _septentrio: 2
    readonly property int _femtomes:   4
    readonly property int _ublox:      8
    readonly property int _all:        15

    readonly property int manufacturer: (rtkSettings && rtkSettings.baseReceiverManufacturers)
                                        ? rtkSettings.baseReceiverManufacturers.rawValue : 0
    readonly property int useFixedPosition: (rtkSettings && rtkSettings.useFixedBasePosition)
                                           ? rtkSettings.useFixedBasePosition.rawValue
                                           : BaseModeDefinition.BaseSurveyIn

    property int settingsDisplayId: _all

    function updateSettingsDisplayId() {
        switch (manufacturer) {
        case 0: settingsDisplayId = (_trimble | _septentrio | _femtomes | _ublox); break // All
        case 1: settingsDisplayId = _trimble; break
        case 2: settingsDisplayId = _septentrio; break
        case 3: settingsDisplayId = _femtomes; break
        case 4: settingsDisplayId = _ublox; break
        default: settingsDisplayId = _all; break
        }
    }

    Component.onCompleted: updateSettingsDisplayId()

    onManufacturerChanged: updateSettingsDisplayId()

    AzGroup {
        width: overlay.contentWidth

        // ---- AutoConnect ----
        AzSettingRow {
            label:        qsTr("Avtomatik qoşulma")
            controlWidth: autoConnectSwitch.implicitWidth
            visible:      !!(autoConnectFact && autoConnectFact.visible)

            AzSwitch {
                id:                     autoConnectSwitch
                anchors.verticalCenter: parent.verticalCenter
                checked:                !!(autoConnectFact && autoConnectFact.rawValue)
                onClicked: {
                    if (autoConnectFact) autoConnectFact.rawValue = !autoConnectFact.rawValue
                }
            }
        }

        // ---- Settings displayed ----
        AzSettingRow {
            label:   qsTr("Göstərilən tənzimləmələr")
            visible: !!(rtkSettings && rtkSettings.baseReceiverManufacturers && rtkSettings.baseReceiverManufacturers.visible)

            FactComboBox {
                anchors.fill: parent
                fact:         rtkSettings.baseReceiverManufacturers
            }
        }

        // ---- Survey-In / Specify position ----
        Item {
            width:  parent.width
            height: AzTheme.px(AzTheme.groupRowHeight)

            Row {
                x:                      overlay._groupPad
                anchors.verticalCenter: parent.verticalCenter
                spacing:                AzTheme.px(20)

                QGCRadioButton {
                    text: qsTr("Survey-In")
                    checked: useFixedPosition == BaseModeDefinition.BaseSurveyIn
                    onClicked: rtkSettings.useFixedBasePosition.rawValue = BaseModeDefinition.BaseSurveyIn
                    visible: settingsDisplayId & _all
                }

                QGCRadioButton {
                    text: qsTr("Mövqeyi göstər")
                    checked: useFixedPosition == BaseModeDefinition.BaseFixed
                    onClicked: rtkSettings.useFixedBasePosition.rawValue = BaseModeDefinition.BaseFixed
                    visible: settingsDisplayId & _all
                }
            }
        }

        // ---- Survey-In Accuracy ----
        Item {
            width:   parent.width
            height:  accuracySlider.implicitHeight + 2 * overlay._groupPad
            visible: (
                useFixedPosition == BaseModeDefinition.BaseSurveyIn
                && rtkSettings && rtkSettings.surveyInAccuracyLimit && rtkSettings.surveyInAccuracyLimit.visible
                && (settingsDisplayId & _ublox)
            )

            FactSlider {
                id:                accuracySlider
                x:                 overlay._groupPad
                y:                 overlay._groupPad
                width:             parent.width - 2 * overlay._groupPad
                label:             qsTr("Dəqiqlik")
                fact:              rtkSettings.surveyInAccuracyLimit
                majorTickStepSize: 0.1
            }
        }

        // ---- Survey-In Min Duration ----
        Item {
            width:   parent.width
            height:  minDurationSlider.implicitHeight + 2 * overlay._groupPad
            visible: (
                useFixedPosition == BaseModeDefinition.BaseSurveyIn
                && rtkSettings && rtkSettings.surveyInMinObservationDuration && rtkSettings.surveyInMinObservationDuration.visible
                && (settingsDisplayId & (_ublox | _femtomes | _trimble))
            )

            FactSlider {
                id:                minDurationSlider
                x:                 overlay._groupPad
                y:                 overlay._groupPad
                width:             parent.width - 2 * overlay._groupPad
                label:             qsTr("Minimum müddət")
                fact:              rtkSettings.surveyInMinObservationDuration
                majorTickStepSize: 10
            }
        }

        // ---- Fixed base position ----
        Item {
            width:   parent.width
            height:  fixedCol.implicitHeight + 2 * overlay._groupPad
            visible: (useFixedPosition == BaseModeDefinition.BaseFixed)

            ColumnLayout {
                id:      fixedCol
                x:       overlay._groupPad
                y:       overlay._groupPad
                width:   parent.width - 2 * overlay._groupPad
                spacing: AzTheme.px(8)

                LabelledFactTextField {
                    Layout.fillWidth: true
                    label: rtkSettings.fixedBasePositionLatitude.shortDescription
                    fact:  rtkSettings.fixedBasePositionLatitude
                    visible: (settingsDisplayId & _all)
                }

                LabelledFactTextField {
                    Layout.fillWidth: true
                    label: rtkSettings.fixedBasePositionLongitude.shortDescription
                    fact:  rtkSettings.fixedBasePositionLongitude
                    visible: (settingsDisplayId & _all)
                }

                LabelledFactTextField {
                    Layout.fillWidth: true
                    label: rtkSettings.fixedBasePositionAltitude.shortDescription
                    fact:  rtkSettings.fixedBasePositionAltitude
                    visible: (settingsDisplayId & _all)
                }

                LabelledFactTextField {
                    Layout.fillWidth: true
                    label: rtkSettings.fixedBasePositionAccuracy.shortDescription
                    fact:  rtkSettings.fixedBasePositionAccuracy
                    visible: (settingsDisplayId & _ublox)
                }

                LabelledButton {
                    Layout.fillWidth: true
                    label: qsTr("Cari baza mövqeyi")
                    buttonText: enabled ? qsTr("Yadda saxla") : qsTr("Hələ etibarlı deyil")
                    enabled: QGroundControl.gpsRtk.valid.value
                    visible: true

                    onClicked: {
                        rtkSettings.fixedBasePositionLatitude.rawValue  = QGroundControl.gpsRtk.currentLatitude.rawValue
                        rtkSettings.fixedBasePositionLongitude.rawValue = QGroundControl.gpsRtk.currentLongitude.rawValue
                        rtkSettings.fixedBasePositionAltitude.rawValue  = QGroundControl.gpsRtk.currentAltitude.rawValue
                        rtkSettings.fixedBasePositionAccuracy.rawValue  = QGroundControl.gpsRtk.currentAccuracy.rawValue
                    }
                }
            }
        }
    }
}

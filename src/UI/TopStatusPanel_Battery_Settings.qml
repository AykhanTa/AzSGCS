import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

/// Batareya tənzimləmələri — göstərilən dəyər, rəngləmə hədləri və aşağı batareya failsafe.
/// Məzmun BatteryIndicator.qml / PX4BatteryIndicator.qml ilə eynidir, yalnız
/// TopStatusPanel-in öz panel dizaynına salınıb.
AzPopupFrame {
    id: root

    title: qsTr("Batareya Tənzimləmələri")

    onCloseRequested: close()

    property var _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var _batterySettings: QGroundControl.settingsManager.batteryIndicatorSettings

    readonly property real _groupPad: AzTheme.px(AzTheme.groupPadding)

    FactPanelController { id: controller }

    function close() {
        if (typeof settingsLoader !== "undefined" && settingsLoader) {
            settingsLoader.source = ""
        } else {
            root.panelVisible = false
        }
    }

    /// Rəngləmə pilləsi — ikon + (sabit etiket və ya redaktə olunan həd)
    component ColorStep: ColumnLayout {
        property string iconSource: ""
        property color  iconColor:  "#FFFFFF"
        property string caption:    ""
        property var    thresholdFact: null

        spacing: AzTheme.px(8)

        QGCColoredImage {
            Layout.alignment:       Qt.AlignHCenter
            Layout.preferredWidth:  AzTheme.px(36)
            Layout.preferredHeight: Layout.preferredWidth
            source:                 iconSource
            color:                  iconColor
            fillMode:               Image.PreserveAspectFit
        }

        Text {
            Layout.alignment:       Qt.AlignHCenter
            Layout.preferredHeight: AzTheme.px(32)
            text:                   caption
            color:                  AzTheme.textSecondary
            verticalAlignment:      Text.AlignVCenter
            visible:                thresholdFact === null
            font.family:            AzTheme.fontFamily
            font.pixelSize:         AzTheme.fontPx(AzTheme.popupTextSize)
        }

        FactTextField {
            Layout.alignment:       Qt.AlignHCenter
            Layout.preferredWidth:  AzTheme.px(64)
            Layout.preferredHeight: AzTheme.px(32)
            fact:                   thresholdFact
            visible:                thresholdFact !== null
        }
    }

    // ---------------- Göstərilən dəyər ----------------
    AzSectionTitle { text: qsTr("Batareya Göstəricisi") }

    AzGroup {
        width: root.contentWidth

        AzSettingRow {
            label: qsTr("Göstərilən dəyər")

            FactComboBox {
                anchors.fill:   parent
                fact:           _batterySettings.valueDisplay
                indexModel:     false
                sizeToContents: false
            }
        }

        // Rəng pillələri — 100% / həd1 / həd2 / aşağı / kritik
        Item {
            width:  parent.width
            height: colorSteps.implicitHeight + colorCaption.height + 3 * root._groupPad

            Text {
                id:             colorCaption
                x:              root._groupPad
                y:              root._groupPad
                text:           qsTr("Rəngləmə")
                color:          AzTheme.textSecondary
                font.family:    AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
            }

            RowLayout {
                id:      colorSteps
                x:       root._groupPad
                y:       colorCaption.y + colorCaption.height + root._groupPad
                width:   parent.width - 2 * root._groupPad
                spacing: AzTheme.px(12)

                ColorStep {
                    Layout.fillWidth: true
                    iconSource: "/qmlimages/BatteryGreen.svg"
                    iconColor:  qgcPal.colorGreen
                    caption:    qsTr("100%")
                }

                ColorStep {
                    Layout.fillWidth: true
                    iconSource:    "/qmlimages/BatteryYellowGreen.svg"
                    iconColor:     qgcPal.colorYellowGreen
                    thresholdFact: _batterySettings.threshold1
                }

                ColorStep {
                    Layout.fillWidth: true
                    iconSource:    "/qmlimages/BatteryYellow.svg"
                    iconColor:     qgcPal.colorYellow
                    thresholdFact: _batterySettings.threshold2
                }

                ColorStep {
                    Layout.fillWidth: true
                    iconSource: "/qmlimages/BatteryOrange.svg"
                    iconColor:  qgcPal.colorOrange
                    caption:    qsTr("Aşağı")
                }

                ColorStep {
                    Layout.fillWidth: true
                    iconSource: "/qmlimages/BatteryCritical.svg"
                    iconColor:  qgcPal.colorRed
                    caption:    qsTr("Kritik")
                }
            }
        }
    }

    // ---------------- Aşağı batareya failsafe ----------------
    AzSectionTitle {
        text:    qsTr("Aşağı Batareya Failsafe")
        visible: !!_activeVehicle
    }

    AzGroup {
        width:   root.contentWidth
        visible: !!_activeVehicle

        AzSettingRow {
            label:   qsTr("Təyyarə Hərəkəti")
            visible: lowBatActCombo.fact !== null

            FactComboBox {
                id:             lowBatActCombo
                anchors.fill:   parent
                fact:           controller.getParameterFact(-1, "COM_LOW_BAT_ACT", false)
                indexModel:     false
                sizeToContents: false
            }
        }

        Item {
            width:   parent.width
            height:  failsafeSliders.implicitHeight + 2 * root._groupPad
            visible: lowBatActCombo.fact !== null

            ColumnLayout {
                id:      failsafeSliders
                x:       root._groupPad
                y:       root._groupPad
                width:   parent.width - 2 * root._groupPad
                spacing: AzTheme.px(12)

                FactSlider {
                    Layout.fillWidth:  true
                    label:             qsTr("Xəbərdarlıq Səviyyəsi")
                    fact:              controller.getParameterFact(-1, "BAT_LOW_THR", false)
                    visible:           fact !== null
                    majorTickStepSize: 5
                }

                FactSlider {
                    Layout.fillWidth:  true
                    label:             qsTr("Kritik Səviyyə")
                    fact:              controller.getParameterFact(-1, "BAT_CRIT_THR", false)
                    visible:           fact !== null
                    majorTickStepSize: 5
                }

                FactSlider {
                    Layout.fillWidth:  true
                    label:             qsTr("Fövqəladə Səviyyə")
                    fact:              controller.getParameterFact(-1, "BAT_EMERGEN_THR", false)
                    visible:           fact !== null
                    majorTickStepSize: 5
                }
            }
        }

        Text {
            x:                 root._groupPad
            width:             parent.width - 2 * root._groupPad
            height:            implicitHeight + 2 * root._groupPad
            verticalAlignment: Text.AlignVCenter
            text:              qsTr("Failsafe parametrləri təyyarədən oxunmayıb.")
            color:             AzTheme.textSecondary
            wrapMode:          Text.WordWrap
            visible:           lowBatActCombo.fact === null
            font.family:       AzTheme.fontFamily
            font.pixelSize:    AzTheme.fontPx(AzTheme.popupTextSize)
        }
    }

    // ---------------- Enerji konfiqurasiyası ----------------
    AzGroup {
        width:   root.contentWidth
        visible: !!_activeVehicle

        AzSettingRow {
            label:        qsTr("Təyyarə Enerjisi")
            controlWidth: configureButton.implicitWidth

            AzButton {
                id:        configureButton
                height:    parent.height
                text:      qsTr("Konfiqurasiya et")
                onClicked: {
                    root.close()
                    // Aparat Qurğusu → Enerji (menyu idx 6)
                    mainWindow.showVehicleSetupPage(6)
                }
            }
        }
    }

    QGCPalette { id: qgcPal }
}

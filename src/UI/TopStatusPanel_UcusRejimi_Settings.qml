import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

/// Uçuş rejimi tənzimləmələri — RTL hündürlüyü, GeoFence və rejim siyahısının idarəsi.
/// Məzmun PX4FlightModeIndicator.qml / FlightModeIndicator.qml ilə eynidir,
/// yalnız TopStatusPanel-in öz panel dizaynına salınıb (Batareya paneli kimi).
AzPopupFrame {
    id: root

    title: qsTr("Uçuş Rejimi Tənzimləmələri")
    cardWidth: AzTheme.px(AzTheme.popupWideWidth)

    onCloseRequested: close()

    property var _activeVehicle:      QGroundControl.multiVehicleManager.activeVehicle
    property var _flightModeSettings: QGroundControl.settingsManager.flightModeSettings
    property var _flyViewSettings:    QGroundControl.settingsManager.flyViewSettings

    property bool _px4:     _activeVehicle && _activeVehicle.px4Firmware
    property bool _apm:     _activeVehicle && _activeVehicle.apmFirmware

    readonly property real _groupPad: AzTheme.px(AzTheme.groupPadding)

    FactPanelController { id: controller }

    function close() {
        if (typeof settingsLoader !== "undefined" && settingsLoader) {
            settingsLoader.source = ""
        } else {
            root.panelVisible = false
        }
    }

    /// A GeoFence limit: the name with an on/off switch, the slider below.
    component FenceLimit: ColumnLayout {
        id: limit

        property string label
        property var    fact:     null
        property real   to:       100
        property real   tickStep: 10

        spacing: AzTheme.px(4)
        visible: fact !== null

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text:             limit.label
                color:            AzTheme.textCard
                font.family:      AzTheme.fontFamily
                font.weight:      Font.Medium
                font.pixelSize:   AzTheme.fontPx(AzTheme.popupTextSize)
            }

            QGCCheckBoxSlider {
                checked: limit.fact && limit.fact.value > 0

                property real prevValue: 0

                onClicked: {
                    var slider = limitSliderLoader.item as FactSlider
                    if (!limit.fact || !slider) {
                        return
                    }
                    if (checked) {
                        slider.setValue(prevValue !== 0 ? prevValue : slider.to)
                    } else {
                        prevValue = slider.value
                        slider.setValue(0)
                    }
                }
            }
        }

        // Built only when the parameter exists: without it the slider has no limits.
        Loader {
            id:               limitSliderLoader
            Layout.fillWidth: true
            active:           limit.fact !== null

            sourceComponent: FactSlider {
                fact:              limit.fact
                to:                limit.to
                majorTickStepSize: limit.tickStep
                enabled:           limit.fact && limit.fact.value > 0
            }
        }
    }

    // ---------------- Təyyarə yoxdur ----------------
    Text {
        width:          root.contentWidth
        text:           qsTr("Tənzimləmələr üçün təyyarə qoşulmalıdır.")
        color:          AzTheme.textSecondary
        wrapMode:       Text.WordWrap
        visible:        !_activeVehicle
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
    }

    // ---------------- RTL hündürlüyü ----------------
    AzSectionTitle {
        text:    qsTr("Evə Qayıtma")
        visible: _activeVehicle && _px4
    }

    AzGroup {
        width:   root.contentWidth
        visible: _activeVehicle && _px4

        Item {
            id:      rtlRow
            width:   parent.width
            height:  rtlSliderLoader.height + 2 * root._groupPad
            visible: rtlFact !== null

            property var rtlFact: controller.getParameterFact(-1, "RTL_RETURN_ALT", false)

            Loader {
                id:     rtlSliderLoader
                x:      root._groupPad
                y:      root._groupPad
                width:  parent.width - 2 * root._groupPad
                active: rtlRow.rtlFact !== null

                sourceComponent: FactSlider {
                    label:             qsTr("RTL Hündürlüyü")
                    fact:              rtlRow.rtlFact
                    to:                rtlRow.rtlFact.maxIsDefaultForType
                                       ? QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(121.92)
                                       : rtlRow.rtlFact.max
                    majorTickStepSize: 10
                }
            }
        }
    }

    // ---------------- GeoFence ----------------
    AzSectionTitle {
        text:    qsTr("GeoFence")
        visible: _activeVehicle && _px4
    }

    AzGroup {
        width:   root.contentWidth
        visible: _activeVehicle && _px4

        AzSettingRow {
            label: qsTr("Pozuntu Hərəkəti")

            FactComboBox {
                anchors.fill:   parent
                fact:           controller.getParameterFact(-1, "GF_ACTION", false)
                indexModel:     false
                sizeToContents: false
                visible:        fact !== null
            }
        }

        Item {
            width:  parent.width
            height: fenceLimits.implicitHeight + 2 * root._groupPad

            ColumnLayout {
                id:      fenceLimits
                x:       root._groupPad
                y:       root._groupPad
                width:   parent.width - 2 * root._groupPad
                spacing: AzTheme.px(16)

                FenceLimit {
                    Layout.fillWidth: true
                    label:            qsTr("Maksimum Məsafə")
                    fact:             controller.getParameterFact(-1, "GF_MAX_HOR_DIST", false)
                    to:               _flyViewSettings.maxGoToLocationDistance.value
                    tickStep:         500
                }

                FenceLimit {
                    Layout.fillWidth: true
                    label:            qsTr("Maksimum Hündürlük")
                    fact:             controller.getParameterFact(-1, "GF_MAX_VER_DIST", false)
                    to:               _flyViewSettings.guidedMaximumAltitude.value
                    tickStep:         10
                }
            }
        }
    }

    // ---------------- Ətraflı konfiqurasiya ----------------
    AzGroup {
        width:   root.contentWidth
        visible: !!_activeVehicle

        AzSettingRow {
            label:        qsTr("Uçuş Rejimləri")
            controlWidth: configureButton.implicitWidth

            AzButton {
                id:        configureButton
                height:    parent.height
                text:      qsTr("Konfiqurasiya et")
                onClicked: {
                    root.close()
                    // Aparat Qurğusu → Uçuş Rejimləri (menyu idx 4)
                    mainWindow.showVehicleSetupPage(4)
                }
            }
        }
    }
}

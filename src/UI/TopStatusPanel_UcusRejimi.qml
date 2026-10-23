import QtQuick

import QGroundControl
import QGroundControl.Controls

AzPopupFrame {
    id: root

    title:           qsTr("Uçuş Rejimi")
    settingsVisible: true
    cardWidth:       AzTheme.px(376)

    onCloseRequested:  close()
    onSettingsClicked: openSettings()

    // TopStatusPanel.qml loader-dən gələnlər
    property var  hostPanel: null
    property var  activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var  statusPanel: null   // TopStatusPanel-in özü

    function close() {
        // Loader-i bağla
        var hp = hostPanel || statusPanel
        if (hp && hp.closeFlightModePopup) {
            hp.closeFlightModePopup()
        } else if (typeof topStatusPanel !== "undefined" && topStatusPanel) {
            topStatusPanel.flightModePopupVisible = false
        }
    }

    function openSettings() {
        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
        if (!loaderExists) return

        var a = root.anchorItem
        var t = root.topPanelItem
        var src = "qrc:/qml/QGroundControl/UI/TopStatusPanel_UcusRejimi_Settings.qml"

        // Tənzimləmə paneli açılanda rejim siyahısı bağlanmalıdır, əks halda üst-üstə düşür.
        Qt.callLater(function() { root.close() })

        if (typeof settingsLoader.setSource === "function") {
            settingsLoader.setSource(src, {
                anchorItem: a,
                topPanelItem: t
            })
        } else {
            settingsLoader.source = src
            Qt.callLater(function() {
                if (!settingsLoader.item) return
                settingsLoader.item.anchorItem = a
                settingsLoader.item.topPanelItem = t
                if (settingsLoader.item.hasOwnProperty("reposition"))
                    settingsLoader.item.reposition()
            })
        }
    }

    function selectMode(label) {
        var vehicle = root.activeVehicle
        if (!vehicle) return

        if (label === "Takeoff") {
            if (!vehicle.takeoffVehicleSupported &&
                !vehicle.guidedTakeoffSupported &&
                !vehicle.startTakeoff) {
                console.warn("Bu təyyarə üçün Takeoff əmri dəstəklənmir")
                return
            }

            if (vehicle.guidedTakeoffSupported && vehicle.guidedModeTakeoff) {
                var targetAlt = 10
                if (vehicle.minimumTakeoffAltitudeMeters) {
                    targetAlt = vehicle.minimumTakeoffAltitudeMeters()
                }
                vehicle.guidedModeTakeoff(targetAlt)
            } else if (vehicle.startTakeoff) {
                vehicle.startTakeoff()
            } else {
                console.warn("Vehicle üzərində guidedModeTakeoff / startTakeoff tapılmadı")
            }
            return
        }

        if (!vehicle.flightModeSetAvailable) return
        vehicle.flightMode = label
    }

    ListModel {
        id: flightModeModel
    }

    function updateFlightModes() {
        flightModeModel.clear()

        var vehicle = root.activeVehicle
        if (!vehicle) return

        var modes = vehicle.flightModes
        if (!modes || modes.length === 0) return

        for (var i = 0; i < modes.length; i++) {
            flightModeModel.append({ label: modes[i] })
        }
        flightModeModel.append({ label: "Takeoff" })
    }

    Component.onCompleted: updateFlightModes()

    Text {
        visible:        flightModeModel.count === 0
        text:           qsTr("Uçuş rejimi mövcud deyil")
        color:          AzTheme.textSecondary
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
    }

    AzGroup {
        id:      modeGroup
        width:   root.contentWidth
        visible: flightModeModel.count > 0

        Repeater {
            model: flightModeModel

            delegate: Item {
                id:     modeItem
                width:  modeGroup.width
                height: AzTheme.px(46)

                readonly property bool isCurrent: !!root.activeVehicle && root.activeVehicle.flightMode === model.label

                Rectangle {
                    anchors.fill:    parent
                    anchors.margins: 1
                    radius:          AzTheme.px(AzTheme.groupRadius) - 1
                    visible:         modeMouse.containsMouse || modeMouse.pressed || modeItem.isCurrent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0;      color: modeItem.isCurrent ? AzTheme.activeTintStart : Qt.rgba(1, 1, 1, 0.02) }
                        GradientStop { position: 0.5982; color: modeItem.isCurrent ? AzTheme.activeTintEnd : Qt.rgba(1, 1, 1, modeMouse.pressed ? 0.08 : 0.04) }
                    }
                }

                Text {
                    anchors.left:           parent.left
                    anchors.leftMargin:     AzTheme.px(AzTheme.groupPadding)
                    anchors.right:          currentDot.left
                    anchors.rightMargin:    AzTheme.px(8)
                    anchors.verticalCenter: parent.verticalCenter
                    elide:                  Text.ElideRight
                    text:                   model.label
                    color:                  AzTheme.textCard
                    font.family:            AzTheme.fontFamily
                    font.weight:            modeItem.isCurrent ? Font.DemiBold : Font.Normal
                    font.pixelSize:         AzTheme.fontPx(AzTheme.popupTextSize)
                }

                Rectangle {
                    id:                     currentDot
                    anchors.right:          parent.right
                    anchors.rightMargin:    AzTheme.px(AzTheme.groupPadding)
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  Math.max(5, AzTheme.px(7))
                    height:                 width
                    radius:                 width / 2
                    color:                  AzTheme.statusGreen
                    visible:                modeItem.isCurrent
                }

                MouseArea {
                    id:           modeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.selectMode(model.label)
                }
            }
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) {
            root.activeVehicle = activeVehicle
            updateFlightModes()
        }
    }

    Connections {
        target: root.activeVehicle
        function onFlightModesChanged() {
            updateFlightModes()
        }
    }
}

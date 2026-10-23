import QtQuick

import QGroundControl
import QGroundControl.Controls

AzPopupFrame {
    id: vehiclePanel

    panelVisible: false
    title:        qsTr("Aparat Seçimi")
    cardWidth:    AzTheme.px(376)

    onCloseRequested: panelVisible = false

    readonly property var _mvm:           QGroundControl.multiVehicleManager
    readonly property var _activeVehicle: _mvm ? _mvm.activeVehicle : null
    readonly property int _vehicleCount:  (_mvm && _mvm.vehicles) ? _mvm.vehicles.count : 0

    function _selectVehicle(vehicle) {
        if (!vehicle) return
        QGroundControl.multiVehicleManager.activeVehicle = vehicle
        vehiclePanel.panelVisible = false
    }

    Text {
        visible:        vehiclePanel._vehicleCount === 0
        text:           qsTr("Qoşulu aparat yoxdur")
        color:          AzTheme.textSecondary
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
    }

    AzGroup {
        id:      vehicleGroup
        width:   vehiclePanel.contentWidth
        visible: vehiclePanel._vehicleCount > 0

        Repeater {
            model: vehiclePanel._vehicleCount

            delegate: Item {
                id: vehicleRow

                property var  vehicle:  vehiclePanel._mvm.vehicles.get(index)
                property bool isActive: !!(vehiclePanel._activeVehicle && vehicle && vehiclePanel._activeVehicle.id === vehicle.id)

                width:  vehicleGroup.width
                height: AzTheme.px(46)

                Rectangle {
                    anchors.fill:    parent
                    anchors.margins: 1
                    radius:          AzTheme.px(AzTheme.groupRadius) - 1
                    visible:         rowMouse.containsMouse || rowMouse.pressed || vehicleRow.isActive
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0;      color: vehicleRow.isActive ? AzTheme.activeTintStart : Qt.rgba(1, 1, 1, 0.02) }
                        GradientStop { position: 0.5982; color: vehicleRow.isActive ? AzTheme.activeTintEnd : Qt.rgba(1, 1, 1, rowMouse.pressed ? 0.08 : 0.04) }
                    }
                }

                Rectangle {
                    id:                     activeDot
                    anchors.left:           parent.left
                    anchors.leftMargin:     AzTheme.px(AzTheme.groupPadding)
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  Math.max(5, AzTheme.px(7))
                    height:                 width
                    radius:                 width / 2
                    color:                  vehicleRow.isActive ? AzTheme.statusGreen : AzTheme.mutedText
                }

                Text {
                    anchors.left:           activeDot.right
                    anchors.leftMargin:     AzTheme.px(12)
                    anchors.right:          activeLabel.left
                    anchors.rightMargin:    AzTheme.px(8)
                    anchors.verticalCenter: parent.verticalCenter
                    elide:                  Text.ElideRight
                    text:                   vehicleRow.vehicle ? qsTr("Aparat %1").arg(vehicleRow.vehicle.id) : ""
                    color:                  AzTheme.textCard
                    font.family:            AzTheme.fontFamily
                    font.weight:            vehicleRow.isActive ? Font.DemiBold : Font.Normal
                    font.pixelSize:         AzTheme.fontPx(AzTheme.popupTextSize)
                }

                Text {
                    id:                     activeLabel
                    anchors.right:          parent.right
                    anchors.rightMargin:    AzTheme.px(AzTheme.groupPadding)
                    anchors.verticalCenter: parent.verticalCenter
                    visible:                vehicleRow.isActive
                    text:                   qsTr("Aktiv")
                    color:                  AzTheme.statusGreen
                    font.family:            AzTheme.fontFamily
                    font.pixelSize:         AzTheme.fontPx(13)
                }

                MouseArea {
                    id:           rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    vehiclePanel._selectVehicle(vehicleRow.vehicle)
                }
            }
        }
    }

    Text {
        width:          vehiclePanel.contentWidth
        wrapMode:       Text.WordWrap
        text:           qsTr("Keçmək üçün aparata basın.")
        color:          AzTheme.textSecondary
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(13)
    }
}

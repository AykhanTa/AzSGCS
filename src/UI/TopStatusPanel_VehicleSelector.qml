import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl

Rectangle {
    id: vehiclePanel

    property bool panelVisible: false
    property var  anchorItem:   null
    property var  topPanelItem: null

    visible:      panelVisible
    width:        260
    height:       contentCol.implicitHeight + 32
    color:        "#1e1e1e"
    radius:       10
    z:            9500
    border.color: "#444"
    border.width: 1

    function reposition() {
        if (!anchorItem || !parent) return
        // host = Loader; host.parent = mainWindow.contentItem (the real viewport)
        var host = vehiclePanel.parent
        var viewport = host && host.parent ? host.parent : host
        if (!viewport) return
        // anchorItem coords mapped into viewport (which shares Loader's origin at 0,0)
        var anchorTopLeft = anchorItem.mapToItem(viewport, 0, 0)
        var preferredX = anchorTopLeft.x + anchorItem.width - vehiclePanel.width

        // Y: bütün top status panelin altında, bir az məsafə ilə açılsın (üstünə düşməsin)
        var gap = 10
        var preferredY = topPanelItem
            ? (topPanelItem.mapToItem(viewport, 0, topPanelItem.height).y + gap)
            : (anchorTopLeft.y + anchorItem.height + gap)
        vehiclePanel.x = Math.max(8, Math.min(preferredX, viewport.width  - vehiclePanel.width  - 8))
        vehiclePanel.y = Math.max(8, Math.min(preferredY, viewport.height - vehiclePanel.height - 8))
    }

    onPanelVisibleChanged: { if (panelVisible) Qt.callLater(reposition) }
    onAnchorItemChanged:   { if (panelVisible) Qt.callLater(reposition) }

    readonly property var _mvm:           QGroundControl.multiVehicleManager
    readonly property var _activeVehicle: _mvm ? _mvm.activeVehicle : null
    readonly property int _vehicleCount:  (_mvm && _mvm.vehicles) ? _mvm.vehicles.count : 0

    function _selectVehicle(vehicle) {
        if (!vehicle) return
        QGroundControl.multiVehicleManager.activeVehicle = vehicle
        vehiclePanel.panelVisible = false
    }

    Column {
        id: contentCol
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.margins: 16
        spacing: 10

        RowLayout {
            width: parent.width
            spacing: 6

            Text {
                text: qsTr("Aparat Seçimi")
                color: "white"
                font.pixelSize: 13
                font.weight: Font.Medium
                Layout.fillWidth: true
            }

            Rectangle {
                width: 20; height: 20; radius: 4
                color: closeMouse.containsMouse ? "#553333" : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "x"
                    color: closeMouse.containsMouse ? "white" : "#888"
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: vehiclePanel.panelVisible = false
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#333" }

        Text {
            visible: vehiclePanel._vehicleCount === 0
            width:   parent.width
            horizontalAlignment: Text.AlignHCenter
            text:    qsTr("Qoşulu aparat yoxdur")
            color:   "#777"
            font.pixelSize: 11
            font.italic:    true
            topPadding:    4
            bottomPadding: 4
        }

        Column {
            width:   parent.width
            spacing: 6
            visible: vehiclePanel._vehicleCount > 0

            Repeater {
                model: vehiclePanel._vehicleCount

                Rectangle {
                    id: vehicleRow

                    property var vehicle: vehiclePanel._mvm.vehicles.get(index)
                    property bool isActive: vehiclePanel._activeVehicle && vehicle && vehiclePanel._activeVehicle.id === vehicle.id

                    width:  parent.width
                    height: 36
                    radius: 6
                    color:  isActive
                            ? "#1a5533"
                            : (rowMouse.containsMouse ? "#2a2a2a" : "#252525")
                    border.color: isActive ? "#33aa66" : "#333"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin:  10
                        anchors.rightMargin: 10
                        spacing: 8

                        Rectangle {
                            width:  8; height: 8; radius: 4
                            color:  vehicleRow.isActive ? "#00cc44" : "#666"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: vehicleRow.vehicle
                                  ? ("Vehicle " + vehicleRow.vehicle.id)
                                  : ""
                            color: "white"
                            font.pixelSize: 12
                            font.weight: vehicleRow.isActive ? Font.Medium : Font.Normal
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: vehicleRow.isActive
                            text:    "Aktiv"
                            color:   "#33aa66"
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    vehiclePanel._selectVehicle(vehicleRow.vehicle)
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#333" }

        Text {
            text:  qsTr("Aparat seçin – kliklə keçid")
            color: "#555"
            font.pixelSize: 10
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: overlay
    anchors.fill: parent
    color: "#00000080"
    z: 100

    // Loader-dən gələnlər
    property bool panelVisible: true
    property Item anchorItem: null
    property Item topPanelItem: null

    visible: panelVisible

    readonly property string _azIconBase: "qrc:/res/AZSHIELD_ICON/"
    readonly property string _uiQrcBase:  "qrc:/qml/QGroundControl/UI/"

    // QGC data
    readonly property var _veh: QGroundControl.multiVehicleManager.activeVehicle
    readonly property var _gps: _veh ? _veh.gps : null
    readonly property var _rtk: QGroundControl.gpsRtk

    readonly property string _na: qsTr("N/A")
    readonly property string _valueNA: qsTr("–.––")

    // -------- responsive helpers
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : Math.max(12, Qt.application.font.pixelSize)
    readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : Math.max(8,  Qt.application.font.pixelSize * 0.60)
    readonly property bool _compact: (width < 900) || (height < 650) || (_hasScreenTools && ScreenTools.isShortScreen)

    readonly property real _edge: Math.round(Math.max(8, _fontH * (_compact ? 0.75 : 0.95)))
    readonly property real _gap:  Math.round(Math.max(6, _fontH * (_compact ? 0.55 : 0.75)))
    readonly property real _pad:  Math.round(Math.max(8, _fontH * (_compact ? 0.50 : 0.70)))

    // Top panelin altından başlama (kiçik ekranda top panelin üstünə çıxmasın)
    readonly property real _yMin: topPanelItem ? (topPanelItem.height + _gap) : _edge
    readonly property real _maxCardH: Math.max(200, overlay.height - _yMin - _edge)

    function factText(f, fallback) {
        if (f === null || f === undefined) return fallback
        if (f.enumStringValue !== undefined && f.enumStringValue !== "") return f.enumStringValue
        if (f.valueString !== undefined && f.valueString !== "") return f.valueString
        if (f.rawValue !== undefined && f.rawValue !== null) return String(f.rawValue)
        if (f.value !== undefined && f.value !== null) return String(f.value)
        return fallback
    }

    function reposition() {
        var x = (overlay.width  - card.width) / 2
        var y = _yMin

        if (anchorItem) {
            var p = anchorItem.mapToItem(overlay, 0, anchorItem.height)
            x = p.x + (anchorItem.width / 2) - (card.width / 2)
            y = p.y + _gap
        } else if (topPanelItem) {
            y = topPanelItem.height + _gap
        }

        y = Math.max(y, _yMin)

        card.x = _clamp(x, _edge, overlay.width  - card.width  - _edge)
        card.y = _clamp(y, _yMin, overlay.height - card.height - _edge)
    }

    function closeSelf() {
        if ((typeof settingsLoader !== "undefined") && settingsLoader) {
            settingsLoader.source = ""
        } else {
            overlay.panelVisible = false
        }
    }


    Component.onCompleted: Qt.callLater(reposition)
    onWidthChanged: Qt.callLater(reposition)
    onHeightChanged: Qt.callLater(reposition)
    onAnchorItemChanged: Qt.callLater(reposition)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onClicked: overlay.closeSelf()
        onWheel: (wheel) => { wheel.accepted = true }
    }

    WheelHandler {
        target: overlay
        //propagationPhase: PointerHandler.BubblePhase
        onWheel: (wheel) => { wheel.accepted = true }
    }


    Rectangle {
        id: card
        color: "#2A2A2A"
        radius: 8
        border.width: 1
        border.color: "#444444"
        clip: true

        width: Math.min(_compact ? 420 : 460, overlay.width - (_edge * 2))
        readonly property real _rowH: Math.max(40, Math.round(_fontH * 2.6))
        readonly property real _valBoxW: Math.round(_clamp(width * 0.36, 120, 180))

        // kontent qədər hündürlük (lazım olsa scroll)
        readonly property real _desiredH: titleBar.height + (2 * _pad) + contentLayout.implicitHeight
        height: Math.min(_desiredH, _maxCardH)

        onWidthChanged: Qt.callLater(reposition)
        onHeightChanged: Qt.callLater(reposition)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => { mouse.accepted = true }
            onWheel: (wheel) => { wheel.accepted = true }
        }


        // Title bar
        Rectangle {
            id: titleBar
            width: parent.width
            height: 39
            color: "#3D3B3B"
            radius: 4
            anchors.top: parent.top

            // Settings (sol)
            Image {
                source: _azIconBase + "TopStatusPanel_Settings.svg"
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader
                        if (!loaderExists) return

                        const src = _uiQrcBase + "TopStatusPanel_GPS_Settings.qml"
                        if (typeof settingsLoader.setSource === "function") {
                            settingsLoader.setSource(src, {
                                panelVisible: true,
                                anchorItem: overlay.anchorItem,
                                topPanelItem: overlay.topPanelItem
                            })
                        } else {
                            settingsLoader.source = src
                            Qt.callLater(function() {
                                if (!settingsLoader.item) return
                                settingsLoader.item.panelVisible = true
                                settingsLoader.item.anchorItem = overlay.anchorItem
                                settingsLoader.item.topPanelItem = overlay.topPanelItem
                                if (settingsLoader.item.hasOwnProperty("reposition"))
                                    settingsLoader.item.reposition()
                            })
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("GPS Status")
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            // Close (sağ)
            Image {
                source: _azIconBase + "TopStatusPanel_Cixis.svg"
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof settingsLoader !== "undefined" && settingsLoader) {
                            settingsLoader.source = ""
                        } else {
                            overlay.panelVisible = false
                        }
                    }
                }
            }
        }

        // Content (drag scroll də işləyir)
        Flickable {
            id: contentFlick
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: _pad
            clip: true

            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            contentWidth: width
            contentHeight: contentLayout.implicitHeight
            interactive: contentHeight > height + 2

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

            ColumnLayout {
                id: contentLayout
                width: contentFlick.width
                spacing: 10

                // ----- Vehicle GPS Status -----
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Vehicle GPS Status")
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                    visible: !!_veh
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: !!_veh

                    Text {
                        text: qsTr("Satellites")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 12; text: _gps ? factText(_gps.count, _na) : _na }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: !!_veh

                    Text {
                        text: qsTr("GPS Lock")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 12; text: _gps ? factText(_gps.lock, _na) : _na }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: !!_veh

                    Text {
                        text: qsTr("HDOP")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 12; text: _gps ? factText(_gps.hdop, _valueNA) : _valueNA }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: !!_veh

                    Text {
                        text: qsTr("VDOP")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 12; text: _gps ? factText(_gps.vdop, _valueNA) : _valueNA }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: !!_veh

                    Text {
                        text: qsTr("Course Over Ground")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 12; text: _gps ? factText(_gps.courseOverGround, _valueNA) : _valueNA }
                    }
                }

                // ----- RTK GPS Status -----
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    visible: _rtk && _rtk.connected && _rtk.connected.value
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("RTK GPS Status")
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                    visible: _rtk && _rtk.connected && _rtk.connected.value
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: _rtk && _rtk.connected && _rtk.connected.value

                    Text {
                        text: qsTr("Status")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            color: "white"
                            font.pixelSize: 12
                            text: (_rtk && _rtk.active && _rtk.active.value) ? qsTr("Survey-in Active") : qsTr("RTK Streaming")
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: _rtk && _rtk.connected && _rtk.connected.value

                    Text {
                        text: qsTr("Satellites")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 12; text: (_rtk && _rtk.numSatellites) ? String(_rtk.numSatellites.value) : _na }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: _rtk && _rtk.connected && _rtk.connected.value

                    Text {
                        text: qsTr("Duration")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 12; text: (_rtk && _rtk.currentDuration) ? (String(_rtk.currentDuration.value) + " s") : _na }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: card._rowH
                    radius: 4
                    color: "#3D3B3B"
                    visible: _rtk && _rtk.connected && _rtk.connected.value && _rtk.currentAccuracy && _rtk.currentAccuracy.value > 0

                    Text {
                        text: (_rtk && _rtk.valid && _rtk.valid.value) ? qsTr("Accuracy") : qsTr("Current Accuracy")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        width: card._valBoxW; height: 24; radius: 4
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#2A2A2A"; border.color: "#666666"; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            color: "white"
                            font.pixelSize: 12
                            text: _rtk.currentAccuracy.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
                        }
                    }
                }
            }
        }
    }
}

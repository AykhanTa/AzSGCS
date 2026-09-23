import QtQuick 2.15
import QtQuick.Controls

import QGroundControl.Controls
import QtQuick.Layouts 1.15

Rectangle {
    id: udpPanel

    property bool panelVisible: false
    property var  anchorItem:   null
    property var  topPanelItem: null

    visible:      panelVisible
    width:        300
    height:       contentCol.implicitHeight + 32

    color:        "#1e1e1e"
    radius:       10
    z:            9500
    border.color: "#444"
    border.width: 1

    function reposition() {
        if (!anchorItem || !parent) return
        // host = Loader; host.parent = mainWindow.contentItem (the real viewport)
        var host = udpPanel.parent
        var viewport = host && host.parent ? host.parent : host
        if (!viewport) return
        // anchorItem coords mapped into viewport (which shares Loader's origin at 0,0)
        var anchorTopLeft = anchorItem.mapToItem(viewport, 0, 0)
        var preferredX = anchorTopLeft.x + anchorItem.width - udpPanel.width

        // Y: bütün top status panelin altında, bir az məsafə ilə açılsın (üstünə düşməsin)
        var gap = 10
        var preferredY = topPanelItem
            ? (topPanelItem.mapToItem(viewport, 0, topPanelItem.height).y + gap)
            : (anchorTopLeft.y + anchorItem.height + gap)
        udpPanel.x = Math.max(8, Math.min(preferredX, viewport.width  - udpPanel.width  - 8))
        udpPanel.y = Math.max(8, Math.min(preferredY, viewport.height - udpPanel.height - 8))
    }

    onPanelVisibleChanged: { if (panelVisible) Qt.callLater(reposition) }
    onAnchorItemChanged:   { if (panelVisible) Qt.callLater(reposition) }

    readonly property bool   _act:       (typeof externalPositionManager !== "undefined") ? externalPositionManager.extActive   : false
    readonly property double _rawLat:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.extLat      : 0.0
    readonly property double _rawLon:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.extLon      : 0.0
    readonly property real   _rawAlt:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.extAlt      : 0.0
    readonly property real   _rawSpd:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.extSpd      : 0.0
    readonly property int    _rawPkt:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.pktCount    : 0
    readonly property bool   _listening: (typeof externalPositionManager !== "undefined") ? externalPositionManager.isListening : false
    readonly property int    _curPort:   (typeof externalPositionManager !== "undefined") ? externalPositionManager.listenPort  : 15550
    readonly property bool   _sending:   (typeof externalPositionManager !== "undefined") ? externalPositionManager.sendEnabled : false

    property double dispLat: 0.0
    property double dispLon: 0.0
    property real   dispAlt: 0.0
    property real   dispSpd: 0.0
    property int    dispPkt: 0
    property bool   hasData: false

    property string portInput: ""
    property string portError: ""

    property bool actWatcher: _act
    property int  pktWatcher: _rawPkt

    onActWatcherChanged: { if (_act) _refreshDisplay() }
    onPktWatcherChanged: { if (_act) _refreshDisplay() }

    function _refreshDisplay() {
        dispLat = _rawLat
        dispLon = _rawLon
        dispAlt = _rawAlt
        dispSpd = _rawSpd
        dispPkt = _rawPkt
        hasData = true
    }

    function _clearDisplayData() {
        dispLat = 0.0
        dispLon = 0.0
        dispAlt = 0.0
        dispSpd = 0.0
        dispPkt = 0
        hasData = false
    }

    Component.onCompleted: {
        portInput = _curPort.toString()
    }

    function applyPort() {
        var p = parseInt(portInput, 10)
        if (isNaN(p) || p < 1024 || p > 65535) {
            portError = qsTr("Port 1024–65535 arasında olmalıdır")
            return
        }
        portError = ""
        _clearDisplayData()
        if (typeof externalPositionManager !== "undefined") {
            externalPositionManager.startListening(p)
        }
    }

    function toggleListening() {
        if (typeof externalPositionManager === "undefined") return
        if (_listening) {
            _clearDisplayData()
            externalPositionManager.stopListening()
        } else {
            applyPort()
        }
    }

    Column {
        id: contentCol
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.margins: 16
        spacing: 10

        // Başlıq
        RowLayout {
            width: parent.width
            spacing: 6

            Text {
                text: "UDP Xarici Pozisiya"
                color: "white"
                font.pixelSize: 13
                font.weight: Font.Medium
                Layout.fillWidth: true
            }

            Rectangle {
                width: 8; height: 8; radius: 4
                color: udpPanel._act ? "#00cc44" : "#cc0000"
                SequentialAnimation on opacity {
                    running: udpPanel._act
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 600 }
                    NumberAnimation { to: 1.0; duration: 600 }
                }
            }

            Text {
                text:  udpPanel._act      ? qsTr("Canlı")    :
                       udpPanel._listening ? qsTr("Gözləyir") : "Passiv"
                color: udpPanel._act      ? "#00cc44"  :
                       udpPanel._listening ? "#ccaa00"  : "#cc4444"
                font.pixelSize: 11
            }

            Rectangle {
                width: 20; height: 20; radius: 4
                color: closeMouse.containsMouse ? "#553333" : "transparent"
                // An icon, not a glyph. This used to be U+2715 from Dingbats, which
                // Roboto does not carry, so on Android the button was blank. Also
                // no longer dimmed until hovered: a touch screen never hovers.
                QGCColoredImage {
                    anchors.centerIn: parent
                    width:  Math.round(parent.width * 0.6)
                    height: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/res/AZSHIELD_ICON/TopStatusPanel_Cixis.svg"
                    color: closeMouse.containsMouse ? "white" : "#CCCCCC"
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: udpPanel.panelVisible = false
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#333" }

        // Port
        Column {
            width: parent.width
            spacing: 6

            Text { text: qsTr("Dinlənilən Port"); color: "#aaa"; font.pixelSize: 11 }

            RowLayout {
                width: parent.width
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 32; radius: 6
                    color: "#2a2a2a"
                    border.color: portField.activeFocus ? "#4488ff" : "#555"
                    border.width: 1

                    TextInput {
                        id: portField
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: Text.AlignVCenter
                        text: udpPanel.portInput
                        color: "white"
                        font.pixelSize: 13
                        font.family: "monospace"
                        inputMethodHints: Qt.ImhDigitsOnly
                        selectByMouse: true
                        onTextChanged: { udpPanel.portInput = text; udpPanel.portError = "" }
                        onAccepted: udpPanel.applyPort()
                    }
                }

                Rectangle {
                    width: 80; height: 32; radius: 6
                    color: udpPanel._listening
                           ? (toggleMouse.containsMouse ? "#aa2222" : "#882222")
                           : (toggleMouse.containsMouse ? "#226644" : "#1a5533")
                    border.color: udpPanel._listening ? "#cc3333" : "#33aa66"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: udpPanel._listening ? qsTr("Dayandır") : qsTr("Başlat")
                        color: "white"; font.pixelSize: 12; font.weight: Font.Medium
                    }
                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: udpPanel.toggleListening()
                    }
                }
            }

            Text {
                visible: udpPanel.portError !== ""
                text: udpPanel.portError
                color: "#ff6666"; font.pixelSize: 10
            }

            Text {
                visible: udpPanel._listening
                text: "Aktiv port: " + udpPanel._curPort
                color: "#55aa77"; font.pixelSize: 10
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#333" }

        // MAVLink toggle
        RowLayout {
            width: parent.width

            Text {
                text: qsTr("Avtopilota göndər")
                color: "white"; font.pixelSize: 12
                Layout.fillWidth: true
            }

            Rectangle {
                width: 44; height: 24; radius: 12
                color: udpPanel._sending ? "#227744" : "#444"
                border.color: udpPanel._sending ? "#33aa66" : "#666"
                border.width: 1

                Rectangle {
                    width: 20; height: 20; radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    x: udpPanel._sending ? parent.width - width - 2 : 2
                    color: "white"
                    Behavior on x { NumberAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof externalPositionManager !== "undefined")
                            externalPositionManager.sendEnabled = !udpPanel._sending
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#333" }

        // Gözləmə mesajları
        Text {
            visible: udpPanel._listening && !udpPanel.hasData
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Məlumat gözlənilir...")
            color: "#777"; font.pixelSize: 11; font.italic: true
            topPadding: 4; bottomPadding: 4
        }

        Text {
            visible: !udpPanel._listening && !udpPanel.hasData
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Dinləmə başladılmayıb")
            color: "#555"; font.pixelSize: 11; font.italic: true
            topPadding: 4; bottomPadding: 4
        }

        // Məlumat cədvəli
        GridLayout {
            visible: udpPanel.hasData
            width: parent.width
            columns: 2
            rowSpacing: 8
            columnSpacing: 12

            Text { text: "Enlik";      color: "#888"; font.pixelSize: 11 }
            Text {
                text: udpPanel.dispLat.toFixed(6) + " °"
                color: "white"; font.pixelSize: 12; font.family: "monospace"
                Layout.fillWidth: true
            }

            Text { text: "Uzunluq";    color: "#888"; font.pixelSize: 11 }
            Text {
                text: udpPanel.dispLon.toFixed(6) + " °"
                color: "white"; font.pixelSize: 12; font.family: "monospace"
            }

            Text { text: qsTr("Hündürlük"); color: "#888"; font.pixelSize: 11 }
            Text {
                text: udpPanel.dispAlt.toFixed(1) + " m"
                color: "white"; font.pixelSize: 12; font.family: "monospace"
            }

            Text { text: qsTr("Sürət");     color: "#888"; font.pixelSize: 11 }
            Text {
                text: udpPanel.dispSpd.toFixed(1) + " m/s"
                color: {
                    var s = udpPanel.dispSpd
                    if (s < 3.0)  return "#55aa77"  // yavaş — yaşıl
                    if (s < 10.0) return "#ccaa00"  // orta  — sarı
                    return "#cc4444"                 // sürətli — qırmızı
                }
                font.pixelSize: 12; font.family: "monospace"
            }

            Text { text: qsTr("Paket sayı"); color: "#888"; font.pixelSize: 11 }
            Text {
                text: udpPanel.dispPkt.toString()
                color: "#aaa"; font.pixelSize: 12; font.family: "monospace"
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#333" }

        Text {
            text: "Format: JSON  { lat, lon, alt, spd }"
            color: "#555"; font.pixelSize: 10
            bottomPadding: 4
        }
    }
}

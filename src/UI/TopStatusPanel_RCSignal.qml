import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QGroundControl

Rectangle {
    id: overlay
    anchors.fill: parent
    z: 100
    color: "#00000080"
    clip: true

    // settingsLoader bəzi scope-larda olmaya bilər -> crash olmasın
    readonly property bool _hasSettingsLoader: (typeof settingsLoader !== "undefined") && settingsLoader !== null

    // TopStatusPanel-dən gələn anchor
    property Item anchorItem: null
    property Item topPanelItem: null

    // Digər panellər kimi idarə olunsun
    property bool panelVisible: true
    visible: panelVisible

    // ---- QGC istinadları ----
    readonly property var _veh: QGroundControl.multiVehicleManager.activeVehicle

    // ---- ScreenTools fallback ----
    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : Math.max(12, Qt.application.font.pixelSize)
    readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : Math.max(8,  Qt.application.font.pixelSize * 0.60)

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    readonly property real _edgePad: Math.max(10, _fontW * 1.0)

    // ✅ 1) Top paneldən daha aşağı açılması üçün məsafə (əvvəl 8 idi -> böyütdük)
    readonly property real _dropGap: Math.max(24, _fontH * 1.4)

    // ✅ TopStatusPanel-in altından minimum “clearance”
    readonly property real _minTopClearance: topPanelItem
                                            ? (topPanelItem.height + Math.max(12, _fontH * 0.9))
                                            : _edgePad

    // Panel ölçüsü (böyük ekranda 376x252 qalır, kiçikdə sıxılır)
    readonly property real _panelW: Math.max(280, Math.min(376, overlay.width  - _edgePad * 2))
    readonly property real _panelH: Math.max(220, Math.min(252, overlay.height - _edgePad * 2))

    readonly property real _titleH: Math.max(36, Math.round(_fontH * 2.2))
    readonly property real _rowH:   Math.max(40, Math.round(_fontH * 2.4))
    readonly property real _valueW: Math.max(80, Math.min(110, Math.round(_panelW * 0.26)))

    // ---- Fact/Value helper ----
    function _factVal(f) {
        if (f === null || f === undefined) return NaN
        if (f.rawValue !== undefined) return f.rawValue
        if (f.value    !== undefined) return f.value
        return f
    }

    // ---- RC məlumatları ----
    function rssiVal() {
        if (!_veh) return null
        var r = _factVal(_veh.rcRSSI)
        if (isNaN(r) || r < 0 || r > 100) return null
        return Math.round(r)
    }

    function chanCount() {
        if (!_veh) return null
        var c = NaN
        if (_veh.rcChannelCount !== undefined) c = _factVal(_veh.rcChannelCount)
        else if (_veh.rcChannels !== undefined) c = _factVal(_veh.rcChannels)
        else if (_veh.channelCount !== undefined) c = _factVal(_veh.channelCount)
        if (isNaN(c) || c <= 0) return null
        return Math.round(c)
    }

    function rcFailsafe() {
        if (!_veh) return null
        if (_veh.rcFailsafe !== undefined) return !!_factVal(_veh.rcFailsafe)
        if (_veh.failsafe   !== undefined) return !!_factVal(_veh.failsafe)
        var r = rssiVal()
        if (r === null) return null
        return (r < 5)
    }

    function rcConnected() { return rssiVal() !== null }

    function updateModel() {
        if (rcSignalModel.count < 4) return
        rcSignalModel.setProperty(0, "value", rcConnected() ? "Connected" : "Disconnected")
        var r = rssiVal()
        rcSignalModel.setProperty(1, "value", r === null ? "n/a" : (r + "%"))
        var c = chanCount()
        rcSignalModel.setProperty(2, "value", c === null ? "n/a" : String(c))
        var f = rcFailsafe()
        rcSignalModel.setProperty(3, "value", f === null ? "n/a" : (f ? "Yes" : "No"))
    }

    function closePopup() {
        panelVisible = false
        if (_hasSettingsLoader) settingsLoader.source = ""
    }

    // ---- Anchor altında yerləşdirmə ----
    function reposition() {
        if (!popup) return

        var x = Math.round((overlay.width - popup.width) / 2)
        var y = Math.round((overlay.height - popup.height) / 2)

        if (anchorItem) {
            // Anchor-un mərkəzi + altı
            var p = anchorItem.mapToItem(overlay, anchorItem.width / 2, anchorItem.height)
            x = p.x - popup.width / 2
            y = p.y + _dropGap

            // Aşağı sığmırsa yuxarı aç
            if (y + popup.height + _edgePad > overlay.height) {
                var pTop = anchorItem.mapToItem(overlay, anchorItem.width / 2, 0)
                y = pTop.y - _dropGap - popup.height
            }
        }

        // ✅ 2) TopStatusPanel-ə yapışmasın -> minimum aşağıdan başlasın
        y = Math.max(y, _minTopClearance)

        // Clamp
        x = _clamp(x, _edgePad, overlay.width  - _edgePad - popup.width)
        y = _clamp(y, _edgePad, overlay.height - _edgePad - popup.height)

        popup.x = Math.round(x)
        popup.y = Math.round(y)
    }

    onAnchorItemChanged: Qt.callLater(reposition)
    onTopPanelItemChanged: Qt.callLater(reposition)
    onWidthChanged: if (visible) Qt.callLater(reposition)
    onHeightChanged: if (visible) Qt.callLater(reposition)
    onVisibleChanged: {
        if (visible) {
            updateModel()
            Qt.callLater(reposition)
        }
    }

    Component.onCompleted: {
        updateModel()
        Qt.callLater(reposition)
    }

    // Canlı yeniləmə
    Timer {
        interval: 500
        running: overlay.panelVisible
        repeat: true
        onTriggered: updateModel()
    }

    // ✅ Wheel arxa map-a keçməsin (overlay səviyyəsində)
    // ✅ Arxa UI-ni blokla + wheel map-a keçməsin
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: function(wheel) { wheel.accepted = true }
        onClicked: {} // boş klikləri udur
    }


    // ---- Popup ----
    Rectangle {
        id: popup
        width: overlay._panelW
        height: overlay._panelH
        color: "#2A2A2A"
        radius: 8
        z: 2

        // ✅ Popup içində də wheel udulsun (mütləq)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onClicked: {}                 // klik overlay-ə keçməsin
            onWheel: (wheel) => { wheel.accepted = true } // ✅ scroll overlay-ə/map-a keçməsin
        }

        // ==== Title bar ====
        Rectangle {
            width: parent.width
            height: overlay._titleH
            color: "#3D3B3B"
            radius: 4
            anchors.top: parent.top

            Text {
                anchors.centerIn: parent
                text: "RC Signals"
                color: "white"
                font.pixelSize: Math.max(13, Math.round(overlay._fontH * 0.95))
                font.bold: true
            }

            Image {
                source: "qrc:/res/AZSHIELD_ICON/TopStatusPanel_Cixis.svg"
                width: Math.max(18, Math.round(overlay._fontH * 1.3))
                height: width
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: closePopup()
                    onWheel: (wheel) => { wheel.accepted = true }
                }
            }
        }

        // ==== RC məlumatları ====
        Column {
            spacing: Math.max(6, Math.round(overlay._fontH * 0.45))
            anchors.top: parent.top
            anchors.topMargin: overlay._titleH + 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12

            ListModel {
                id: rcSignalModel
                ListElement { label: "Status";   value: "Disconnected" }
                ListElement { label: "RSSI";     value: "n/a" }
                ListElement { label: "Channels"; value: "n/a" }
                ListElement { label: "Failsafe"; value: "n/a" }
            }

            Repeater {
                model: rcSignalModel

                delegate: Rectangle {
                    width: parent.width
                    height: overlay._rowH
                    color: "#3D3B3B"
                    radius: 4

                    Item {
                        anchors.fill: parent
                        anchors.margins: 12

                        Text {
                            text: model.label
                            color: "white"
                            font.pixelSize: Math.max(13, Math.round(overlay._fontH * 0.95))
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: overlay._valueW
                            height: Math.max(24, Math.round(overlay._fontH * 1.6))
                            radius: 4
                            color: "#2A2A2A"
                            border.color: "#666666"
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right

                            Text {
                                text: model.value
                                color: "white"
                                font.pixelSize: Math.max(12, Math.round(overlay._fontH * 0.85))
                                anchors.centerIn: parent
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}

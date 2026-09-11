import QtQuick 2.15
import QtQuick.Controls 2.15
import QGroundControl

// ====================================================== Battery kliklənəndə açılan panel (ANCHOR + RESPONSIVE) ======================================================

Item {
    id: batteryPopup
    anchors.fill: parent
    z: 100
    visible: panelVisible

    // Loader-dən gələnlər
    property bool panelVisible: true
    property Item anchorItem: null       // Klik olunan status block (Batareya)
    property Item topPanelItem: null     // TopStatusPanel (hündürlük üçün)

    // QRC path-lar (istəsən file:/// saxla, amma qrc daha düzgündür)
    readonly property string _azIconBase: "qrc:/res/AZSHIELD_ICON/"

    // Qısa istinadlar
    readonly property var _veh: QGroundControl.multiVehicleManager.activeVehicle
    readonly property var _bat: _veh && _veh.batteries && _veh.batteries.count > 0
                                ? _veh.batteries.get(0) : null

    // ----------------------------
    // Responsive helpers
    // ----------------------------
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : Math.max(12, Qt.application.font.pixelSize)
    readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : Math.max(8,  Qt.application.font.pixelSize * 0.60)

    readonly property real _pad:  Math.max(10, _fontH * 0.6)
    readonly property real _gapY: Math.max(8,  _fontH * 0.55)

    // TopStatusPanel-in alt sərhədi (reposition() doldurur)
    property real _scrimY: 0

    // Panel ölçüləri (kiçik ekranda clamp)
    readonly property real _panelW: {
        var avail = Math.max(1, width - (_pad * 2))
        var w = Math.min(376, avail)
        w = Math.max(240, w)
        w = Math.min(w, avail)
        return Math.round(w)
    }

    readonly property real _panelH: {
        var maxH = Math.max(1, height - (_scrimY + _gapY) - _pad)
        var h = Math.min(253, maxH)
        h = Math.max(220, h)
        h = Math.min(h, maxH)
        return Math.round(h)
    }

    // ----------------------------
    // Modeli yeniləyən funksiya
    // ----------------------------
    function updateBatteryModel() {
        // Charge State
        var chargeStateText = "n/a"
        if (_bat && _bat.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
            chargeStateText = _bat.chargeState.enumStringValue
        }
        batteryModel.setProperty(0, "value", chargeStateText)

        // Remaining
        var remainingText = "n/a"
        if (_bat) {
            if (!isNaN(_bat.timeRemaining.rawValue)) {
                remainingText = _bat.timeRemainingStr.value
            } else if (!isNaN(_bat.percentRemaining.rawValue)) {
                var percent = _bat.percentRemaining.rawValue
                if (percent < 0) {
                    remainingText = "0%"
                } else if (percent > 98.9) {
                    remainingText = "100%"
                } else {
                    remainingText = _bat.percentRemaining.valueString + _bat.percentRemaining.units
                }
            }
        }
        batteryModel.setProperty(1, "value", remainingText)

        // Voltage
        var voltText = "n/a"
        if (_bat && !isNaN(_bat.voltage.rawValue)) {
            voltText = _bat.voltage.valueString + " " + _bat.voltage.units
        }
        batteryModel.setProperty(2, "value", voltText)

        // Consumed (mAh)
        var consumedText = "n/a"
        if (_bat && !isNaN(_bat.mahConsumed.rawValue)) {
            consumedText = _bat.mahConsumed.valueString + " " + _bat.mahConsumed.units
        }
        batteryModel.setProperty(3, "value", consumedText)
    }

    // Panel görünəndə yenilə
    onVisibleChanged: if (visible) { updateBatteryModel(); Qt.callLater(reposition) }

    // Canlı yeniləmə (panel açıqkən)
    Timer {
        interval: 500
        running: batteryPopup.visible
        repeat: true
        onTriggered: updateBatteryModel()
    }

    // ----------------------------
    // Arxa fon (TopStatusPanel üstünü örtməsin deyə y=top panel altından başlayır)
    // ----------------------------
    Rectangle {
        id: scrim
        x: 0
        y: batteryPopup._scrimY
        width: parent.width
        height: Math.max(0, parent.height - y)
        color: "#00000080"
    }

    // Scrim üzərində wheel arxaya keçməsin
    MouseArea {
        x: 0
        y: scrim.y
        width: scrim.width
        height: scrim.height
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: (wheel) => { wheel.accepted = true }
        // istəsən kliklə bağlansın:
        // onClicked: batteryPopup.closePanel()
    }

    function closePanel() {
        if (typeof settingsLoader !== "undefined" && settingsLoader) {
            settingsLoader.source = ""
        } else {
            panelVisible = false
        }
    }

    // ----------------------------
    // Panelin yerləşməsi (Batareya blokunun altına)
    // ----------------------------
    function reposition() {
        if (!batteryPopup.visible) return

        // Top panel bottom Y (settingsLoader koordinatında)
        var topBottomY = 0
        if (topPanelItem) {
            var pTop = topPanelItem.mapToItem(batteryPopup, 0, topPanelItem.height)
            topBottomY = pTop.y
        }
        batteryPopup._scrimY = topBottomY

        // Anchor center X
        var anchorCX = batteryPopup.width / 2
        if (anchorItem) {
            var pA = anchorItem.mapToItem(batteryPopup, anchorItem.width / 2, anchorItem.height)
            anchorCX = pA.x
        }

        var px = anchorCX - (panel.width / 2)
        px = _clamp(px, _pad, batteryPopup.width - panel.width - _pad)

        var py = topBottomY + _gapY
        // aşağıdan kənara çıxmasın
        var maxY = batteryPopup.height - panel.height - _pad
        if (py > maxY) py = Math.max(topBottomY + _gapY, maxY)

        panel.x = Math.round(px)
        panel.y = Math.round(py)
    }

    // ölçü dəyişəndə də yerini düzəlt
    onWidthChanged:  Qt.callLater(reposition)
    onHeightChanged: Qt.callLater(reposition)
    onAnchorItemChanged: Qt.callLater(reposition)
    onTopPanelItemChanged: Qt.callLater(reposition)

    // ======================================================
    // Panel content
    // ======================================================
    Rectangle {
        id: panel
        width: batteryPopup._panelW
        height: batteryPopup._panelH
        color: "#2A2A2A"
        radius: 8
        border.width: 1
        border.color: "#111111"
        clip: true

        // Panel üzərində wheel arxaya keçməsin
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onWheel: (wheel) => { wheel.accepted = true }
        }

        // ==== Title bar ====
        Rectangle {
            width: parent.width
            height: 39
            color: "#3D3B3B"
            radius: 4
            anchors.top: parent.top

            Text {
                anchors.centerIn: parent
                text: "Battery"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            Image {
                source: batteryPopup._azIconBase + "TopStatusPanel_Settings.svg"
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                fillMode: Image.PreserveAspectFit
                visible: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
                        if (!loaderExists) return

                        // Batareya popup-un öz property-ləri olmalıdır:
                        // batteryPopup.anchorItem və batteryPopup.topPanelItem
                        var a = batteryPopup.anchorItem
                        var t = batteryPopup.topPanelItem

                       // var src = "file:///C:/Users/user/qgroundcontrol/src/UI/TopStatusPanel_Battery_Settings.qml"
                        var src = "qrc:/qml/QGroundControl/UI/TopStatusPanel_Battery_Settings.qml"



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
                }

            }

            // Sağ icon (çıxış)
            Image {
                source: batteryPopup._azIconBase + "TopStatusPanel_Cixis.svg"
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    onClicked: batteryPopup.closePanel()
                }
            }
        }

        // ==== Battery məlumatları ====
        Column {
            spacing: 6
            anchors.top: parent.top
            anchors.topMargin: 50
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12

            ListModel {
                id: batteryModel
                ListElement { label: "Charge State"; value: "n/a" }
                ListElement { label: "Remaining";    value: "n/a" }
                ListElement { label: "Voltage";      value: "n/a" }
                ListElement { label: "Consumed";     value: "n/a" }
            }

            Repeater {
                model: batteryModel
                delegate: Rectangle {
                    width: parent.width
                    height: 44
                    color: "#3D3B3B"
                    radius: 4

                    Item {
                        anchors.fill: parent
                        anchors.margins: 12

                        Text {
                            text: model.label
                            color: "white"
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                        }

                        Rectangle {
                            width: 80
                            height: 24
                            radius: 4
                            color: "#2A2A2A"
                            border.color: "#666666"
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right

                            Text {
                                text: model.value
                                color: "white"
                                font.pixelSize: 12
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }
        }
    }
}

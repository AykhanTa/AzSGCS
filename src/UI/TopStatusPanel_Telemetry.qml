import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: telemetryOverlay
    anchors.fill: parent
    z: 100
    color: "#00000000"     // istəsən "#00000080" et -> arxanı azca qaraldacaq
    clip: true

    // Loader idarəsi üçün
    property bool panelVisible: true
    visible: panelVisible

    // ✅ TopStatusPanel-dən gələcək anchor
    property Item anchorItem: null
    property Item topPanelItem: null

    // ---- Vehicle ----
    readonly property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    // ---- Responsive helpers ----
    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : Math.max(12, Qt.application.font.pixelSize)
    readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : Math.max(8,  Qt.application.font.pixelSize * 0.60)

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    readonly property bool _compact: (width < 950) || (height < 720) || (_hasScreenTools && ScreenTools.isShortScreen)

    readonly property real _edgePad:  Math.max(10, _fontW * 1.0)
    readonly property real _dropGap:  Math.max(18, _fontH * 1.3)

    // Panel top bar-a yapışmasın
    readonly property real _minTopClearance: topPanelItem
                                            ? (topPanelItem.height + _dropGap)
                                            : _edgePad

    // Böyük ekranda daha “geniş” olsun (sənin istədiyin kimi)
    readonly property real _panelW: {
        var maxAvail = width - _edgePad * 2

        // Kiçik ekranda tam en olmasın (dar panel)
        if (_compact) {
            return Math.max(320, Math.min(420, maxAvail))   // 420-ni istəsən 380 elə
        }

        // Böyük ekranda daha geniş ola bilər
        return Math.min(450, maxAvail)
    }


    // Hündürlük: böyükdə 640, kiçikdə ekrana görə
    readonly property real _panelH: Math.min(
                                        height - _edgePad * 2,
                                        _compact ? Math.round(height * 0.80) : 640
                                   )

    readonly property real _headerH:   Math.max(40, Math.round(_fontH * 2.4))
    readonly property real _rowH:      Math.max(50, Math.round(_fontH * 2.7))
    readonly property real _innerPad:  Math.max(10, _fontW * 1.05)
    readonly property real _gap:       Math.max(10, _fontH * 0.65)

    function closePanel() {
        panelVisible = false
        // İstəsən loader-i də boşalt (stabil bağlanma üçün)
        if ((typeof settingsLoader !== "undefined") && settingsLoader) {
            settingsLoader.source = ""
        }
    }

    function reposition() {
        if (!popup) return

        var x = Math.round((width - popup.width) / 2)
        var y = _minTopClearance

        if (anchorItem) {
            // anchor-un altından aç
            var p = anchorItem.mapToItem(telemetryOverlay, anchorItem.width / 2, anchorItem.height)
            x = p.x - popup.width / 2
            y = p.y + _dropGap

            // aşağı sığmırsa yuxarı aç
            if (y + popup.height + _edgePad > telemetryOverlay.height) {
                var pTop = anchorItem.mapToItem(telemetryOverlay, anchorItem.width / 2, 0)
                y = pTop.y - _dropGap - popup.height
            }
        }

        // top paneli kəsməsin
        y = Math.max(y, _minTopClearance)

        // kənarlardan çıxmasın
        x = _clamp(x, _edgePad, telemetryOverlay.width  - _edgePad - popup.width)
        y = _clamp(y, _edgePad, telemetryOverlay.height - _edgePad - popup.height)

        popup.x = Math.round(x)
        popup.y = Math.round(y)
    }

    Component.onCompleted: Qt.callLater(reposition)
    onVisibleChanged: if (visible) Qt.callLater(reposition)
    onAnchorItemChanged: Qt.callLater(reposition)
    onTopPanelItemChanged: Qt.callLater(reposition)
    onWidthChanged: if (visible) Qt.callLater(reposition)
    onHeightChanged: if (visible) Qt.callLater(reposition)

    // ✅ Click outside -> close
    MouseArea {
        anchors.fill: parent
        onClicked: closePanel()
    }

    Rectangle {
        id: popup
        width: telemetryOverlay._panelW
        height: telemetryOverlay._panelH
        radius: 8
        color: "#1E1E1E"
        border.width: 1
        border.color: "#333333"
        clip: true
        z: 2

        // ✅ Wheel event map-a keçməsin
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton   // klikləri bloklamır
            onWheel: function(wheel) {
                wheel.accepted = true
            }
        }

        // ---------------- HEADER ----------------
        Rectangle {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: telemetryOverlay._headerH
            color: "#3d3b3b"

            QGCLabel {
                anchors.centerIn: parent
                text: qsTr("TELEMETRİYA")
                font.pointSize: (typeof ScreenTools !== "undefined") ? ScreenTools.mediumFontPointSize : 12
                font.bold: true
                color: "white"
            }

            Rectangle {
                id: closeButton
                width: Math.max(24, Math.round(telemetryOverlay._fontH * 1.6))
                height: width
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: telemetryOverlay._innerPad
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "#CCCCCC"
                    font.pixelSize: Math.max(18, Math.round(telemetryOverlay._fontH * 1.35))
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: closePanel()
                }
            }
        }

        // ---------------- BODY (scrollable) ----------------
        Flickable {
            id: bodyFlick
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: telemetryOverlay._innerPad

            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            contentWidth: width
            contentHeight: bodyCol.implicitHeight
            interactive: contentHeight > height + 2

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

            ColumnLayout {
                id: bodyCol
                width: bodyFlick.width
                spacing: telemetryOverlay._gap

                function rssiColor(v) {
                    if (!telemetryOverlay._activeVehicle || v === 0) return "#CCCCCC"
                    if (v >= -60) return "#00FF00"
                    if (v >= -70) return "#FFFF00"
                    if (v >= -80) return "#FFA500"
                    return "#FF0000"
                }

                // ----- helper row template (copy/paste style) -----
                Rectangle {
                    Layout.fillWidth: true
                    height: telemetryOverlay._rowH
                    radius: 6
                    color: "#3A3A3A"
                    border.color: "#4A4A4A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: telemetryOverlay._innerPad

                        QGCLabel {
                            text: qsTr("Yerli RSSI:")
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QGCLabel {
                            text: telemetryOverlay._activeVehicle
                                  ? (telemetryOverlay._activeVehicle.telemetryLRSSI !== 0
                                     ? telemetryOverlay._activeVehicle.telemetryLRSSI + " dBm"
                                     : qsTr("Yoxdur"))
                                  : qsTr("Aktiv aparat yoxdur")
                            color: telemetryOverlay._activeVehicle
                                   ? bodyCol.rssiColor(telemetryOverlay._activeVehicle.telemetryLRSSI)
                                   : "#CCCCCC"
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: telemetryOverlay._rowH
                    radius: 6
                    color: "#3A3A3A"
                    border.color: "#4A4A4A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: telemetryOverlay._innerPad

                        QGCLabel {
                            text: qsTr("Uzaq RSSI:")
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QGCLabel {
                            text: telemetryOverlay._activeVehicle
                                  ? (telemetryOverlay._activeVehicle.telemetryRRSSI !== 0
                                     ? telemetryOverlay._activeVehicle.telemetryRRSSI + " dBm"
                                     : qsTr("Yoxdur"))
                                  : qsTr("Aktiv aparat yoxdur")
                            color: telemetryOverlay._activeVehicle
                                   ? bodyCol.rssiColor(telemetryOverlay._activeVehicle.telemetryRRSSI)
                                   : "#CCCCCC"
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: telemetryOverlay._rowH
                    radius: 6
                    color: "#3A3A3A"
                    border.color: "#4A4A4A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: telemetryOverlay._innerPad

                        QGCLabel {
                            text: qsTr("RX Səhvləri:")
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QGCLabel {
                            text: telemetryOverlay._activeVehicle ? telemetryOverlay._activeVehicle.telemetryRXErrors : qsTr("Aktiv aparat yoxdur")
                            color: "#CCCCCC"
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: telemetryOverlay._rowH
                    radius: 6
                    color: "#3A3A3A"
                    border.color: "#4A4A4A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: telemetryOverlay._innerPad

                        QGCLabel {
                            text: qsTr("Düzəldilən Səhvlər:")
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QGCLabel {
                            text: telemetryOverlay._activeVehicle ? telemetryOverlay._activeVehicle.telemetryFixed : qsTr("Aktiv aparat yoxdur")
                            color: "#CCCCCC"
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: telemetryOverlay._rowH
                    radius: 6
                    color: "#3A3A3A"
                    border.color: "#4A4A4A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: telemetryOverlay._innerPad

                        QGCLabel {
                            text: qsTr("TX Buffer:")
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QGCLabel {
                            text: telemetryOverlay._activeVehicle ? telemetryOverlay._activeVehicle.telemetryTXBuffer : qsTr("Aktiv aparat yoxdur")
                            color: "#CCCCCC"
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: telemetryOverlay._rowH
                    radius: 6
                    color: "#3A3A3A"
                    border.color: "#4A4A4A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: telemetryOverlay._innerPad

                        QGCLabel {
                            text: qsTr("Yerli Səs-Küy:")
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QGCLabel {
                            text: telemetryOverlay._activeVehicle
                                  ? (telemetryOverlay._activeVehicle.telemetryLNoise !== 0
                                     ? telemetryOverlay._activeVehicle.telemetryLNoise + " dBm"
                                     : qsTr("Yoxdur"))
                                  : qsTr("Aktiv aparat yoxdur")
                            color: "#CCCCCC"
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: telemetryOverlay._rowH
                    radius: 6
                    color: "#3A3A3A"
                    border.color: "#4A4A4A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: telemetryOverlay._innerPad

                        QGCLabel {
                            text: qsTr("Uzaq Səs-Küy:")
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        QGCLabel {
                            text: telemetryOverlay._activeVehicle
                                  ? (telemetryOverlay._activeVehicle.telemetryRNoise !== 0
                                     ? telemetryOverlay._activeVehicle.telemetryRNoise + " dBm"
                                     : qsTr("Yoxdur"))
                                  : qsTr("Aktiv aparat yoxdur")
                            color: "#CCCCCC"
                            font.bold: true
                        }
                    }
                }

                // ✅ RSSI BAR — saxladım, sadəcə Layout ilə
                Rectangle {
                    Layout.fillWidth: true
                    height: telemetryOverlay._rowH
                    color: "#2A2A2A"
                    border.color: "#3A3A3A"
                    border.width: 2
                    radius: 6

                    Rectangle {
                        id: rssiBar
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2

                        width: {
                            if (!telemetryOverlay._activeVehicle || telemetryOverlay._activeVehicle.telemetryLRSSI === 0) return 0
                            var rssi = telemetryOverlay._activeVehicle.telemetryLRSSI
                            var normalized = Math.max(0, Math.min(1, (rssi + 100) / 70))
                            return normalized * (parent.width - 4)
                        }

                        color: {
                            if (!telemetryOverlay._activeVehicle || telemetryOverlay._activeVehicle.telemetryLRSSI === 0) return "#3A3A3A"
                            var rssi = telemetryOverlay._activeVehicle.telemetryLRSSI
                            if (rssi >= -60) return "#00FF00"
                            if (rssi >= -70) return "#FFFF00"
                            if (rssi >= -80) return "#FFA500"
                            return "#FF0000"
                        }
                        radius: 4

                        Behavior on width { NumberAnimation { duration: 500 } }
                    }

                    QGCLabel {
                        anchors.centerIn: parent
                        text: {
                            if (!telemetryOverlay._activeVehicle || telemetryOverlay._activeVehicle.telemetryLRSSI === 0) return qsTr("Telemetri Yoxdur")
                            var rssi = telemetryOverlay._activeVehicle.telemetryLRSSI
                            if (rssi >= -60) return qsTr("Əla Siqnal")
                            if (rssi >= -70) return qsTr("Yaxşı Siqnal")
                            if (rssi >= -80) return qsTr("Orta Siqnal")
                            return qsTr("Zəif Siqnal")
                        }
                        color: "#2A2A2A"
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(60, Math.round(telemetryOverlay._fontH * 3.2))
                    color: "#3A3A3A"
                    radius: 6

                    QGCLabel {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: qsTr("Telemetriya RSSI dəyərləri siqnal gücünü göstərir. Daha yüksək dəyərlər daha yaxşıdır.")
                        wrapMode: Text.WordWrap
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: 8
                    }
                }

                Item { Layout.preferredHeight: 2; Layout.fillWidth: true }
            }
        }
    }
}

import QtQuick

import QGroundControl
import QGroundControl.Controls

AzPopupFrame {
    id: telemetryOverlay

    title: qsTr("Telemetriya")

    onCloseRequested: closePanel()

    // ---- Vehicle ----
    readonly property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    readonly property real _lrssi: _activeVehicle ? _activeVehicle.telemetryLRSSI : 0

    function closePanel() {
        panelVisible = false
        // İstəsən loader-i də boşalt (stabil bağlanma üçün)
        if ((typeof settingsLoader !== "undefined") && settingsLoader) {
            settingsLoader.source = ""
        }
    }

    function rssiColor(v) {
        if (!_activeVehicle || v === 0) return AzTheme.textCard
        if (v >= -60) return AzTheme.statusGreen
        if (v >= -70) return AzTheme.statusYellow
        if (v >= -80) return AzTheme.statusOrange
        return AzTheme.statusRed
    }

    function dbmText(v) {
        if (!_activeVehicle) return qsTr("Aparat yoxdur")
        return v !== 0 ? (v + " dBm") : qsTr("Əlaqə yoxdur")
    }

    function countText(v) {
        return _activeVehicle ? String(v) : qsTr("Aparat yoxdur")
    }

    AzGroup {
        width: telemetryOverlay.contentWidth

        AzInfoRow {
            label:      qsTr("Yerli RSSI")
            value:      telemetryOverlay.dbmText(telemetryOverlay._lrssi)
            valueColor: telemetryOverlay.rssiColor(telemetryOverlay._lrssi)
        }
        AzInfoRow {
            readonly property real rssi: _activeVehicle ? _activeVehicle.telemetryRRSSI : 0
            label:      qsTr("Uzaq RSSI")
            value:      telemetryOverlay.dbmText(rssi)
            valueColor: telemetryOverlay.rssiColor(rssi)
        }
        AzInfoRow { label: qsTr("RX səhvləri");        value: telemetryOverlay.countText(_activeVehicle ? _activeVehicle.telemetryRXErrors : 0) }
        AzInfoRow { label: qsTr("Düzəldilən səhvlər"); value: telemetryOverlay.countText(_activeVehicle ? _activeVehicle.telemetryFixed : 0) }
        AzInfoRow { label: qsTr("TX bufer");           value: telemetryOverlay.countText(_activeVehicle ? _activeVehicle.telemetryTXBuffer : 0) }
        AzInfoRow { label: qsTr("Yerli səs-küy");      value: telemetryOverlay.dbmText(_activeVehicle ? _activeVehicle.telemetryLNoise : 0) }
        AzInfoRow { label: qsTr("Uzaq səs-küy");       value: telemetryOverlay.dbmText(_activeVehicle ? _activeVehicle.telemetryRNoise : 0) }

        // Local RSSI from -100 dBm (empty) to -30 dBm (full).
        Item {
            id:     signalRow
            width:  parent.width
            height: AzTheme.px(AzTheme.groupRowHeight)

            readonly property bool  _noLink: !telemetryOverlay._activeVehicle || telemetryOverlay._lrssi === 0

            Text {
                anchors.left:           parent.left
                anchors.leftMargin:     AzTheme.px(AzTheme.groupPadding)
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (signalRow._noLink) return qsTr("Telemetriya yoxdur")
                    var rssi = telemetryOverlay._lrssi
                    if (rssi >= -60) return qsTr("Əla siqnal")
                    if (rssi >= -70) return qsTr("Yaxşı siqnal")
                    if (rssi >= -80) return qsTr("Orta siqnal")
                    return qsTr("Zəif siqnal")
                }
                color:          signalRow._noLink ? AzTheme.textSecondary : telemetryOverlay.rssiColor(telemetryOverlay._lrssi)
                font.family:    AzTheme.fontFamily
                font.weight:    Font.Medium
                font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
            }

            Rectangle {
                id:                     rssiTrack
                anchors.right:          parent.right
                anchors.rightMargin:    AzTheme.px(AzTheme.groupPadding)
                anchors.verticalCenter: parent.verticalCenter
                width:                  Math.min(AzTheme.px(240), parent.width * 0.5)
                height:                 AzTheme.px(10)
                radius:                 height / 2
                color:                  AzTheme.pillBottom
                border.width:           1
                border.color:           AzTheme.groupBorder

                Rectangle {
                    x:      1
                    y:      1
                    height: parent.height - 2
                    radius: height / 2
                    width:  signalRow._noLink ? 0
                                                  : Math.max(0, Math.min(1, (telemetryOverlay._lrssi + 100) / 70)) * (parent.width - 2)
                    color:  telemetryOverlay.rssiColor(telemetryOverlay._lrssi)

                    Behavior on width { NumberAnimation { duration: 500 } }
                }
            }
        }
    }

    Text {
        width:          telemetryOverlay.contentWidth
        wrapMode:       Text.WordWrap
        text:           qsTr("Telemetriya RSSI dəyərləri siqnal gücünü göstərir. Daha yüksək dəyərlər daha yaxşıdır.")
        color:          AzTheme.textSecondary
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(13)
    }
}

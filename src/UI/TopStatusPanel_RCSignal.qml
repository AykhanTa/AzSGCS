import QtQuick

import QGroundControl
import QGroundControl.Controls

AzPopupFrame {
    id: overlay

    title:     qsTr("RC Siqnalı")

    onCloseRequested: closePopup()

    // settingsLoader bəzi scope-larda olmaya bilər -> crash olmasın
    readonly property bool _hasSettingsLoader: (typeof settingsLoader !== "undefined") && settingsLoader !== null

    readonly property var _veh: QGroundControl.multiVehicleManager.activeVehicle

    // The RC values are plain properties without change signals; a tick re-reads them.
    property int _tick: 0

    Timer {
        interval: 500
        running:  overlay.panelVisible
        repeat:   true
        onTriggered: overlay._tick++
    }

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

    function closePopup() {
        panelVisible = false
        if (_hasSettingsLoader) settingsLoader.source = ""
    }

    AzGroup {
        width: overlay.contentWidth

        AzInfoRow {
            readonly property bool connected: overlay._tick >= 0 && overlay.rcConnected()
            label:      qsTr("Vəziyyət")
            value:      connected ? qsTr("Qoşulub") : qsTr("Qoşulmayıb")
            valueColor: connected ? AzTheme.statusGreen : AzTheme.textCard
        }

        AzInfoRow {
            readonly property var rssi: overlay._tick >= 0 ? overlay.rssiVal() : null
            label: qsTr("RSSI")
            value: rssi === null ? qsTr("n/a") : (rssi + "%")
        }

        AzInfoRow {
            readonly property var failsafe: overlay._tick >= 0 ? overlay.rcFailsafe() : null
            label:      qsTr("Failsafe")
            value:      failsafe === null ? qsTr("n/a") : (failsafe ? qsTr("Bəli") : qsTr("Xeyr"))
            valueColor: failsafe === true ? AzTheme.statusRed : AzTheme.textCard
        }

        AzInfoRow {
            readonly property var channels: overlay._tick >= 0 ? overlay.chanCount() : null
            label: qsTr("Kanallar")
            value: channels === null ? qsTr("n/a") : String(channels)
        }
    }
}

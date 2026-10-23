import QtQuick

import QGroundControl
import QGroundControl.Controls

AzPopupFrame {
    id: overlay

    title:           qsTr("GPS")
    settingsVisible: true

    onCloseRequested:  closeSelf()
    onSettingsClicked: openSettings()

    readonly property string _uiQrcBase:  "qrc:/qml/QGroundControl/UI/"

    // QGC data
    readonly property var _veh: QGroundControl.multiVehicleManager.activeVehicle
    readonly property var _gps: _veh ? _veh.gps : null
    readonly property var _rtk: QGroundControl.gpsRtk
    readonly property bool _rtkConnected: !!(_rtk && _rtk.connected && _rtk.connected.value)

    readonly property string _na: qsTr("n/a")
    readonly property string _valueNA: qsTr("–.––")

    function factText(f, fallback) {
        if (f === null || f === undefined) return fallback
        if (f.enumStringValue !== undefined && f.enumStringValue !== "") return f.enumStringValue
        if (f.valueString !== undefined && f.valueString !== "") return f.valueString
        if (f.rawValue !== undefined && f.rawValue !== null) return String(f.rawValue)
        if (f.value !== undefined && f.value !== null) return String(f.value)
        return fallback
    }

    function closeSelf() {
        if ((typeof settingsLoader !== "undefined") && settingsLoader) {
            settingsLoader.source = ""
        } else {
            overlay.panelVisible = false
        }
    }

    function openSettings() {
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

    // ----- Vehicle GPS Status -----
    AzSectionTitle {
        text: _veh ? qsTr("Aparatın GPS vəziyyəti") : qsTr("Aparat qoşulmayıb")
    }

    AzGroup {
        width:   overlay.contentWidth
        visible: !!_veh

        AzInfoRow { label: qsTr("Peyklər");          value: _gps ? factText(_gps.count, _na) : _na }
        AzInfoRow { label: qsTr("GPS kilidi");       value: _gps ? factText(_gps.lock, _na) : _na }
        AzInfoRow { label: qsTr("HDOP");             value: _gps ? factText(_gps.hdop, _valueNA) : _valueNA }
        AzInfoRow { label: qsTr("VDOP");             value: _gps ? factText(_gps.vdop, _valueNA) : _valueNA }
        AzInfoRow { label: qsTr("Yer üzrə istiqamət"); value: _gps ? factText(_gps.courseOverGround, _valueNA) : _valueNA }
    }

    // ----- RTK GPS Status -----
    AzSectionTitle {
        visible: overlay._rtkConnected
        text:    qsTr("RTK GPS vəziyyəti")
    }

    AzGroup {
        width:   overlay.contentWidth
        visible: overlay._rtkConnected

        AzInfoRow {
            label: qsTr("Vəziyyət")
            value: (_rtk && _rtk.active && _rtk.active.value) ? qsTr("Survey-in aktivdir") : qsTr("RTK yayımlanır")
        }
        AzInfoRow {
            label: qsTr("Peyklər")
            value: (_rtk && _rtk.numSatellites) ? String(_rtk.numSatellites.value) : _na
        }
        AzInfoRow {
            label: qsTr("Müddət")
            value: (_rtk && _rtk.currentDuration) ? (String(_rtk.currentDuration.value) + " s") : _na
        }
        AzInfoRow {
            visible: !!(_rtk && _rtk.currentAccuracy && _rtk.currentAccuracy.value > 0)
            label:   (_rtk && _rtk.valid && _rtk.valid.value) ? qsTr("Dəqiqlik") : qsTr("Cari dəqiqlik")
            value:   visible ? (_rtk.currentAccuracy.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString) : ""
        }
    }
}

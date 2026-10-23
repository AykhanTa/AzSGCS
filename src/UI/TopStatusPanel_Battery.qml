import QtQuick

import QGroundControl
import QGroundControl.Controls

// ====================================================== Battery kliklənəndə açılan panel ======================================================

AzPopupFrame {
    id: batteryPopup

    title:           qsTr("Batareya")
    settingsVisible: true

    onCloseRequested:  closePanel()
    onSettingsClicked: openSettings()

    // Qısa istinadlar
    readonly property var _veh: QGroundControl.multiVehicleManager.activeVehicle
    readonly property var _bat: _veh && _veh.batteries && _veh.batteries.count > 0
                                ? _veh.batteries.get(0) : null

    function chargeStateText() {
        if (_bat && _bat.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
            return _bat.chargeState.enumStringValue
        }
        return qsTr("n/a")
    }

    function remainingText() {
        if (_bat) {
            if (!isNaN(_bat.timeRemaining.rawValue)) {
                return _bat.timeRemainingStr.value
            }
            if (!isNaN(_bat.percentRemaining.rawValue)) {
                var percent = _bat.percentRemaining.rawValue
                if (percent < 0) return "0%"
                if (percent > 98.9) return "100%"
                return _bat.percentRemaining.valueString + _bat.percentRemaining.units
            }
        }
        return qsTr("n/a")
    }

    function factText(fact) {
        if (_bat && fact && !isNaN(fact.rawValue)) {
            return fact.valueString + " " + fact.units
        }
        return qsTr("n/a")
    }

    function closePanel() {
        if (typeof settingsLoader !== "undefined" && settingsLoader) {
            settingsLoader.source = ""
        } else {
            panelVisible = false
        }
    }

    function openSettings() {
        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
        if (!loaderExists) return

        var a = batteryPopup.anchorItem
        var t = batteryPopup.topPanelItem
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

    AzGroup {
        width: batteryPopup.contentWidth

        AzInfoRow { label: qsTr("Doldurma vəziyyəti"); value: batteryPopup.chargeStateText() }
        AzInfoRow { label: qsTr("Qalan");              value: batteryPopup.remainingText() }
        AzInfoRow { label: qsTr("Gərginlik");          value: batteryPopup.factText(batteryPopup._bat ? batteryPopup._bat.voltage : null) }
        AzInfoRow { label: qsTr("İstifadə olunub");    value: batteryPopup.factText(batteryPopup._bat ? batteryPopup._bat.mahConsumed : null) }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Item {
    id: topStatusPanel

    readonly property string _azIconBase: "qrc:/res/AZSHIELD_ICON/"
    readonly property string _azV2IconBase: "qrc:/res/AZSHIELD_ICON/v2/"
    readonly property string _uiQrcBase:  "qrc:/qml/QGroundControl/UI/"

    readonly property var _mw: (typeof mainWindow !== "undefined") ? mainWindow : null
    readonly property bool _planVisible: Boolean(_mw && _mw.planView && _mw.planView.visible)

    readonly property var _overlayHost: (_mw && _mw.contentItem) ? _mw.contentItem
                                : ((topStatusPanel.window && topStatusPanel.window.contentItem) ? topStatusPanel.window.contentItem : topStatusPanel)


    //udp
    readonly property bool   _extActive: (typeof externalPositionManager !== "undefined")
                                         ? externalPositionManager.extActive : false
    readonly property double _extLat:    (typeof externalPositionManager !== "undefined")
                                         ? externalPositionManager.extLat : 0.0
    readonly property double _extLon:    (typeof externalPositionManager !== "undefined")
                                         ? externalPositionManager.extLon : 0.0
    readonly property real   _extAlt:    (typeof externalPositionManager !== "undefined")
                                         ? externalPositionManager.extAlt : 0.0
    readonly property int    _extPkt:    (typeof externalPositionManager !== "undefined")
                                         ? externalPositionManager.pktCount : 0


    property bool _pendingOpenStatusOverlay: false
    property Item _statusAnchorItem: null

    property bool flightModePopupVisible: false
    property Item flightModePopupAnchorItem: null

    function openFlightModePopup(anchorItem) {
        if (flightModePopupVisible) {
            closeFlightModePopup()
            return
        }

        const loaderExists = typeof settingsLoader !== "undefined" && settingsLoader !== null
        if (loaderExists) {
            settingsLoader.source = ""
        }

        flightModePopupAnchorItem = anchorItem
        flightModePopupVisible = true

        flightModePopupLoader.setSource(_uiQrcBase + "TopStatusPanel_UcusRejimi.qml", {
            anchorItem:   anchorItem,
            topPanelItem: topStatusPanel,
            hostPanel:    topStatusPanel,
            statusPanel:  topStatusPanel
        })
    }

    function closeFlightModePopup() {
        flightModePopupVisible = false
        flightModePopupAnchorItem = null
        flightModePopupLoader.source = ""
    }

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    // Figma "StatusBar" (padding 12, cards 8 px apart, 62 px kebab column at the right
    // end), made lower than the 80/64 px of the frame: the bar is 64 px and the cards
    // 52 px. AzTheme.px() scales all of it with the window.
    readonly property real _padH:      AzTheme.px(12)
    readonly property real _blockMaxW: AzTheme.px(280)

    // One width for every card: the longest title plus a little room, at most the
    // frame's 280 px. Titles do not change at run time, so the cards do not jump when
    // a value does; a caption longer than the card is elided.
    readonly property real _blockW: {
        var widest = 0
        var cards = statusRow.children
        for (var i = 0; i < cards.length; ++i) {
            if (cards[i].naturalWidth !== undefined) {
                widest = Math.max(widest, cards[i].naturalWidth)
            }
        }
        return Math.min(_blockMaxW, widest + AzTheme.px(20))
    }
    readonly property real _blockH:    AzTheme.px(52)
    readonly property real _blockGap:  AzTheme.px(8)
    readonly property real _menuW:     AzTheme.px(62)
    readonly property real _progressH: Math.max(2, AzTheme.px(2))

    height: AzTheme.px(64)
    z: 200

    property bool userHidden: false
    visible: !userHidden && !_planVisible

    signal exitRequested()

    property string disconnectButtonText: qsTr("Bağlantını kəs")

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool _showLargeProgress: false
    property bool hasNewMessages: false

    property string defaultGPSValue: "n/a"
    property string defaultBatteryValue: "n/a"
    property string defaultFlightMode: "n/a"
    property string defaultRCSignal: "n/a"
    property string defaultTelemetry: "n/a"

    property var _batterySettings: QGroundControl.settingsManager.batteryIndicatorSettings
    property Fact _indicatorDisplay: _batterySettings.valueDisplay
    property bool _showPercentage: _indicatorDisplay.rawValue === 0
    property bool _showVoltage:    _indicatorDisplay.rawValue === 1
    property bool _showBoth:       _indicatorDisplay.rawValue === 2
    property int threshold1: _batterySettings.threshold1.rawValue
    property int threshold2: _batterySettings.threshold2.rawValue

    property var _failsafeSettings: QGroundControl.settingsManager.batteryFailsafeSettings

    FactPanelController { id: batteryController }

    property var _batteryFailsafeEnable: batteryController.parameterExists(-1, "BATT_FS_LOW_ACT")
                                      ? batteryController.getParameterFact(-1, "BATT_FS_LOW_ACT", false) : null
    property var _batteryFailsafePercent: batteryController.parameterExists(-1, "BATT_LOW_PERC")
                                       ? batteryController.getParameterFact(-1, "BATT_LOW_PERC", false) : null
    property var _batteryCriticalVoltage: batteryController.parameterExists(-1, "BATT_CRT_VOLT")
                                        ? batteryController.getParameterFact(-1, "BATT_CRT_VOLT", false) : null
    property var _batteryEmergencyVoltage: batteryController.parameterExists(-1, "BATT_EMER_VOLT")
                                         ? batteryController.getParameterFact(-1, "BATT_EMER_VOLT", false) : null

    property bool isConnected: _activeVehicle ? true : false

    function disconnectVehicle() {
        console.log("=== BAĞLANTI KESME İŞLEMİ BAŞLATILDI ===")

        disconnectButtonText = qsTr("Bağlantı kəsildi")

        if (_activeVehicle) {
            console.log("Aktif araç var, bağlantı kesiliyor:", _activeVehicle.id)
            if (_activeVehicle.link) {
                console.log("Araç link'i kesiliyor:", _activeVehicle.link.linkConfiguration.name)
                _activeVehicle.link.disconnect()
            }
        }

        var linkManager = QGroundControl.linkManager
        if (linkManager) {
            console.log("LinkManager bağlantıları kesiliyor...")

            if (linkManager.sharedLink && linkManager.sharedLink.isConnected) {
                console.log("SharedLink kesiliyor:", linkManager.sharedLink.linkConfiguration.name)
                linkManager.sharedLink.disconnect()
            }

            console.log("Link konfigürasyonları kontrol ediliyor...")
            for (var i = 0; i < linkManager.linkConfigurations.count; i++) {
                var linkConfig = linkManager.linkConfigurations.get(i)
                if (linkConfig && linkConfig.link && linkConfig.link.isConnected) {
                    console.log("Link konfigürasyonu kesiliyor:", linkConfig.name, "- Tür:", linkConfig.type)
                    linkConfig.link.disconnect()
                }
            }
        }

        var vehicleManager = QGroundControl.multiVehicleManager
        if (vehicleManager) {
            console.log("VehicleManager temizleniyor...")
            vehicleManager.activeVehicle = null

            if (vehicleManager.vehicles && vehicleManager.vehicles.count > 0) {
                console.log("Araç listesi temizleniyor, sayı:", vehicleManager.vehicles.count)
            }
        }

        resetToDefaultValues()

        console.log("=== BAĞLANTI KESME İŞLEMİ TAMAMLANDI ===")
        Qt.callLater(function() { checkConnectionStatus() })
    }

    function checkConnectionStatus() {
        console.log("📡 Bağlantı durumu kontrol ediliyor...")

        var linkManager = QGroundControl.linkManager
        var vehicleManager = QGroundControl.multiVehicleManager

        var activeLinks = 0
        var activeVehicles = 0

        if (linkManager) {
            if (linkManager.sharedLink && linkManager.sharedLink.isConnected) {
                console.log("❌ SharedLink hala bağlı:", linkManager.sharedLink.linkConfiguration.name)
                activeLinks++
            }
            for (var i = 0; i < linkManager.linkConfigurations.count; i++) {
                var linkConfig = linkManager.linkConfigurations.get(i)
                if (linkConfig && linkConfig.link && linkConfig.link.isConnected) {
                    console.log("❌ Link konfigürasyonu hala bağlı:", linkConfig.name)
                    activeLinks++
                }
            }
        }

        if (vehicleManager) {
            if (vehicleManager.activeVehicle) {
                console.log("❌ Aktif araç hala var:", vehicleManager.activeVehicle.id)
                activeVehicles++
            }
            if (vehicleManager.vehicles && vehicleManager.vehicles.count > 0) {
                console.log("❌ Araç listesinde", vehicleManager.vehicles.count, "araç var")
                activeVehicles += vehicleManager.vehicles.count
            }
        }

        if (activeLinks === 0 && activeVehicles === 0) {
            console.log("✅ TÜM BAĞLANTILAR BAŞARIYLA KESİLDİ")
        } else {
            console.log("⚠️ HALA", activeLinks, "aktif link ve", activeVehicles, "aktif araç var")
        }
    }

    function checklistIconColor() {
        const v = _veh

        if (!v) {
            return AzTheme.textCard
        }

        return (v.checkListState === Vehicle.CheckListPassed) ? AzTheme.statusGreen : AzTheme.statusRed
    }

    function resetToDefaultValues() {

        defaultGPSValue = "n/a"
        defaultBatteryValue = "n/a"
        defaultFlightMode = "n/a"
        defaultRCSignal = "n/a"
        defaultTelemetry = "n/a"

        hasNewMessages = false
        isConnected = false
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) {
            isConnected = activeVehicle ? true : false

            if (activeVehicle) {
                disconnectButtonText = qsTr("Bağlantını kəs")
            }

            if (!activeVehicle) {
                disconnectButtonText = qsTr("Bağlantı kəsildi")
                topStatusPanel.resetToDefaultValues()
            }
        }
    }

    // Qeyd: keçmiş "QGroundControl.linkManager onLinkConnected/onLinkDisconnected"
    // və "batteryIndicatorSettings onValueDisplayChanged/onThreshold*Changed"
    // Connections blokları silindi — hədəf obyektlərdə bu adda siqnal yoxdur,
    // ona görə heç vaxt işləməyirdilər (konsolda warning verirdilər).
    // Bağlantı mətni artıq yuxarıdakı işlək onActiveVehicleChanged ilə idarə olunur;
    // batareya göstəriciləri isə _showPercentage/threshold1/threshold2 binding-ləri
    // vasitəsilə avtomatik yenilənir (Fact.rawValue NOTIFY).

    Connections { target: _batteryFailsafeEnable;   function onRawValueChanged() { console.log("BATT_FS_LOW_ACT changed:", _batteryFailsafeEnable.rawValue) } }
    Connections { target: _batteryFailsafePercent;  function onRawValueChanged() { console.log("BATT_LOW_PERC changed:", _batteryFailsafePercent.rawValue) } }
    Connections { target: _batteryCriticalVoltage;  function onRawValueChanged() { console.log("BATT_CRT_VOLT changed:", _batteryCriticalVoltage.rawValue) } }
    Connections { target: _batteryEmergencyVoltage; function onRawValueChanged() { console.log("BATT_EMER_VOLT changed:", _batteryEmergencyVoltage.rawValue) } }

    property string _commLostText:      qsTr("Əlaqələr İtirildi")
    property string _readyToFlyText:    qsTr("Uçmağa Hazır")
    property string _notReadyToFlyText: qsTr("Hazır deyil")
    property string _disconnectedText:  qsTr("Bağlantı Yoxdur")
    property string _armedText:         qsTr("Armed")
    property string _flyingText:        qsTr("Uçuşda")
    property string _landingText:       qsTr("Eniş")

    property bool _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : true
    property bool _healthAndArmingChecksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false

    function getDetailedIhaStatus() {
        const statusIcon = _azIconBase + "Status.svg"
        const checklist  = _azIconBase + "Checklist.svg"
        const flightMode = _azIconBase + "FlightMode.svg"

        if (!_activeVehicle) {
            return { text: _disconnectedText, color: "white", icon: statusIcon, statusLabel: qsTr("Status") }
        }

        if (_activeVehicle.vehicleLinkManager.communicationLost) {
            return { text: _commLostText, color: "white", icon: statusIcon, statusLabel: qsTr("Status") }
        }

        if (_activeVehicle.armed) {
            var statusColor = "white"

            if (_healthAndArmingChecksSupported) {
                if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                    if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                        statusColor = "white"
                    }
                } else {
                    statusColor = "white"
                }
            }

            if (_activeVehicle.flying) {
                return { text: _flyingText, color: statusColor, icon: flightMode, statusLabel: qsTr("Aktiv") }
            } else if (_activeVehicle.landing) {
                return { text: _landingText, color: statusColor, icon: flightMode, statusLabel: qsTr("Aktiv") }
            } else {
                return { text: _armedText, color: statusColor, icon: flightMode, statusLabel: qsTr("Aktiv") }
            }
        } else {
            if (_healthAndArmingChecksSupported) {
                if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                    return { text: _readyToFlyText, color: "white", icon: checklist, statusLabel: qsTr("Hazır") }
                } else {
                    return { text: _notReadyToFlyText, color: "white", icon: statusIcon, statusLabel: qsTr("Status") }
                }
            } else if (_activeVehicle.readyToFlyAvailable) {
                if (_activeVehicle.readyToFly) {
                    return { text: _readyToFlyText, color: "white", icon: checklist, statusLabel: qsTr("Hazır") }
                } else {
                    return { text: _notReadyToFlyText, color: "white", icon: statusIcon, statusLabel: qsTr("Status") }
                }
            } else {
                var setupOk = _activeVehicle.autopilotPlugin && _activeVehicle.autopilotPlugin.setupComplete
                var sensorsOk = _activeVehicle.allSensorsHealthy
                if (setupOk && sensorsOk) {
                    return { text: _readyToFlyText, color: "white", icon: checklist, statusLabel: qsTr("Hazır") }
                } else {
                    return { text: _notReadyToFlyText, color: "white", icon: statusIcon, statusLabel: qsTr("Status") }
                }
            }
        }
    }

    function safeBatteryPercent(battery) {
        if (!battery || !battery.percentRemaining) return NaN
        var percent = battery.percentRemaining.rawValue
        if (percent < 0) return 0
        if (percent > 100) return 100
        return percent
    }

    function _batteryHasData(battery) {
        if (!battery) return false
        var pOk = battery.percentRemaining && !isNaN(battery.percentRemaining.rawValue) && battery.percentRemaining.rawValue >= 0
        var vOk = battery.voltage && !isNaN(battery.voltage.rawValue) && battery.voltage.rawValue > 0
        var tOk = battery.timeRemaining && !isNaN(battery.timeRemaining.rawValue)
        return pOk || vOk || tOk
    }

    function safeBatteryValueText(battery) {
        if (!_veh || !battery || !_batteryHasData(battery)) {
            return qsTr("Qoşulmayıb")
        }

        var percentStr = ""
        var voltageStr = ""

        var showPct  = _showPercentage || _showBoth
        var showVolt = _showVoltage    || _showBoth

        if (showPct) {
            var percent = safeBatteryPercent(battery)
            if (!isNaN(percent)) {
                percentStr = (percent > 98.9 ? "100%" : Math.round(percent) + "%")
            }
        }

        if (showVolt) {
            var hasVoltage = battery.voltage && !isNaN(battery.voltage.rawValue) && battery.voltage.rawValue > 0
            if (hasVoltage) {
                voltageStr = battery.voltage.valueString + " " + battery.voltage.units
            }
        }

        if (_showBoth) {
            if (percentStr !== "" && voltageStr !== "") return percentStr + " / " + voltageStr
            if (percentStr !== "") return percentStr
            if (voltageStr !== "") return voltageStr
            return "n/a"
        }

        if (_showPercentage) return (percentStr !== "" ? percentStr : "n/a")
        if (_showVoltage)    return (voltageStr !== "" ? voltageStr : "n/a")

        return "n/a"
    }

    function checkBatteryFailsafe(battery) {
        if (!battery) return ""

        if (!_batteryFailsafeEnable || !_batteryFailsafePercent || !_batteryCriticalVoltage || !_batteryEmergencyVoltage) {
            return checkBatteryFailsafeLegacy(battery)
        }

        if (_batteryFailsafeEnable.rawValue === 0) return ""

        var percent = safeBatteryPercent(battery)
        if (isNaN(percent)) return ""

        var voltage = battery.voltage ? battery.voltage.rawValue : NaN

        var warningLevel = _batteryFailsafePercent.rawValue
        var criticalVoltage = _batteryCriticalVoltage.rawValue
        var emergencyVoltage = _batteryEmergencyVoltage.rawValue

        if (!isNaN(voltage) && voltage <= emergencyVoltage) {
            var action = ""
            switch(_batteryFailsafeEnable.rawValue) {
                case 1: action = "Warning"; break
                case 2: action = "Land"; break
                case 3: action = "Return to Launch"; break
                default: action = "Disabled"
            }
            return "⚠️ EMERGENCY: " + voltage.toFixed(1) + "V - " + action
        } else if (!isNaN(voltage) && voltage <= criticalVoltage) {
            return "⚠️ CRITICAL: " + voltage.toFixed(1) + "V - Return to launch"
        } else if (percent <= warningLevel) {
            return "⚠️ WARNING: " + percent.toFixed(0) + "% - Land soon"
        }

        return ""
    }

    function checkBatteryFailsafeLegacy(battery) {
        if (!battery || !_failsafeSettings) return ""

        var percent = safeBatteryPercent(battery)
        if (isNaN(percent)) return ""

        var warningLevel  = _failsafeSettings.lowBatteryTrigger.rawValue
        var criticalLevel = _failsafeSettings.criticalBatteryTrigger.rawValue
        var emergencyLevel = _failsafeSettings.emergencyBatteryTrigger.rawValue

        if (percent <= emergencyLevel) {
            var emergencyAction = _failsafeSettings.lowBatteryAction.enumStringValue
            return "⚠️ EMERGENCY: " + percent.toFixed(0) + "% - Action: " + emergencyAction
        } else if (percent <= criticalLevel) {
            return "⚠️ CRITICAL: " + percent.toFixed(0) + "% - Return to launch"
        } else if (percent <= warningLevel) {
            return "⚠️ WARNING: " + percent.toFixed(0) + "% - Land soon"
        }

        return ""
    }

    function openMessageOverlay(anchorItem) {
        if (topStatusPanel.flightModePopupVisible) {
            topStatusPanel.closeFlightModePopup()
        }

        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
        if (loaderExists) {
            settingsLoader.source = ""
        }

        if (statusMessageLoader.item && statusMessageLoader.item.visible) {
            if (statusMessageLoader.item.close) {
                statusMessageLoader.item.close()
            }
            topStatusPanel.hasNewMessages = false
            return
        }

        topStatusPanel.hasNewMessages = false
        topStatusPanel._pendingOpenStatusOverlay = true
        topStatusPanel._statusAnchorItem = anchorItem ? anchorItem : null

        if (statusMessageLoader.item && statusMessageLoader.item.open) {
            statusMessageLoader.item.anchorItem = topStatusPanel._statusAnchorItem
            statusMessageLoader.item.open()
            topStatusPanel._pendingOpenStatusOverlay = false
        } else {
            statusMessageLoader.active = true
        }
    }

    function openTelemetry(anchorItem) {
        const loaderExists = typeof settingsLoader !== "undefined" && settingsLoader !== null
        if (!loaderExists) return

        const src = settingsLoader.source ? settingsLoader.source.toString() : ""
        const isTelemetry = src.includes("TopStatusPanel_Telemetry.qml")

        if (isTelemetry && settingsLoader.item) {
            if (settingsLoader.item.panelVisible) {
                settingsLoader.item.panelVisible = false
                return
            } else {
                settingsLoader.item.panelVisible = true
                if (settingsLoader.item.hasOwnProperty("anchorItem"))   settingsLoader.item.anchorItem = anchorItem
                if (settingsLoader.item.hasOwnProperty("topPanelItem")) settingsLoader.item.topPanelItem = topStatusPanel
                if (settingsLoader.item.hasOwnProperty("reposition"))   settingsLoader.item.reposition()
                return
            }
        }

        if (settingsLoader.setSource) {
            settingsLoader.setSource(_uiQrcBase + "TopStatusPanel_Telemetry.qml", {
                panelVisible: true,
                anchorItem: anchorItem,
                topPanelItem: topStatusPanel
            })
        } else {
            settingsLoader.source = _uiQrcBase + "TopStatusPanel_Telemetry.qml"
            Qt.callLater(function() {
                if (!settingsLoader.item) return
                settingsLoader.item.panelVisible = true
                if (settingsLoader.item.hasOwnProperty("anchorItem"))   settingsLoader.item.anchorItem = anchorItem
                if (settingsLoader.item.hasOwnProperty("topPanelItem")) settingsLoader.item.topPanelItem = topStatusPanel
                if (settingsLoader.item.hasOwnProperty("reposition"))   settingsLoader.item.reposition()
            })
        }
    }

    function openRCSignalPopup(anchorItem) {
        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
        if (!loaderExists) return

        const src = _uiQrcBase + "TopStatusPanel_RCSignal.qml"

        if (settingsLoader.source && settingsLoader.source.toString().includes("TopStatusPanel_RCSignal.qml")) {
            settingsLoader.source = ""
            return
        }

        if (typeof settingsLoader.setSource === "function") {
            settingsLoader.setSource(src, {
                anchorItem:   anchorItem,
                topPanelItem: topStatusPanel,
                panelVisible: true
            })
        } else {
            settingsLoader.source = src
            Qt.callLater(function() {
                if (settingsLoader.item) {
                    settingsLoader.item.anchorItem = anchorItem
                    settingsLoader.item.topPanelItem = topStatusPanel
                    if (settingsLoader.item.hasOwnProperty("reposition")) {
                        settingsLoader.item.reposition()
                    }
                }
            })
        }
    }

    function openGPSPopup(anchorItem) {
        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
        if (!loaderExists) return

        const src = _uiQrcBase + "TopStatusPanel_GPS.qml"
        const cur = settingsLoader.source ? settingsLoader.source.toString() : ""

        if (cur.includes("TopStatusPanel_GPS.qml")) {
            settingsLoader.source = ""
            return
        }

        if (typeof settingsLoader.setSource === "function") {
            settingsLoader.setSource(src, {
                panelVisible: true,
                anchorItem: anchorItem,
                topPanelItem: topStatusPanel
            })
        } else {
            settingsLoader.source = src
            Qt.callLater(function() {
                if (!settingsLoader.item) return
                settingsLoader.item.panelVisible = true
                settingsLoader.item.anchorItem = anchorItem
                settingsLoader.item.topPanelItem = topStatusPanel
                if (settingsLoader.item.hasOwnProperty("reposition")) {
                    settingsLoader.item.reposition()
                }
            })
        }
    }

    function openVehicleSelectorPopup(anchorItem) {
        // Yalnız bir panel açıq qalsın — UDP paneli açıqdırsa bağla.
        if (udpPanelLoader.item && udpPanelLoader.item.panelVisible) {
            udpPanelLoader.item.panelVisible = false
        }
        if (vehicleSelectorLoader.item && vehicleSelectorLoader.status === Loader.Ready) {
            if (vehicleSelectorLoader.item.panelVisible) {
                vehicleSelectorLoader.item.panelVisible = false
                return
            }
            vehicleSelectorLoader.item.anchorItem   = anchorItem
            vehicleSelectorLoader.item.topPanelItem = topStatusPanel
            vehicleSelectorLoader.item.panelVisible = true
            vehicleSelectorLoader.item.reposition()
            return
        }

        vehicleSelectorLoader.anchorItemRef = anchorItem
        vehicleSelectorLoader.active = true
    }

    function openUdpPositionPopup(anchorItem) {
        // Yalnız bir panel açıq qalsın — Aparat paneli açıqdırsa bağla.
        if (vehicleSelectorLoader.item && vehicleSelectorLoader.item.panelVisible) {
            vehicleSelectorLoader.item.panelVisible = false
        }
        if (udpPanelLoader.item && udpPanelLoader.status === Loader.Ready) {
            if (udpPanelLoader.item.panelVisible) {
                udpPanelLoader.item.panelVisible = false
                return
            }
            udpPanelLoader.item.anchorItem   = anchorItem
            udpPanelLoader.item.topPanelItem = topStatusPanel
            udpPanelLoader.item.panelVisible = true
            udpPanelLoader.item.reposition()
            return
        }

        udpPanelLoader.anchorItemRef = anchorItem
        udpPanelLoader.active = true
    }
    function openBatteryPopup(anchorItem) {
        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
        if (!loaderExists) return

        const src = _uiQrcBase + "TopStatusPanel_Battery.qml"

        if (settingsLoader.source && settingsLoader.source.toString().includes("TopStatusPanel_Battery.qml")) {
            settingsLoader.source = ""
            return
        }

        if (typeof settingsLoader.setSource === "function") {
            settingsLoader.setSource(src, {
                panelVisible: true,
                anchorItem: anchorItem,
                topPanelItem: topStatusPanel
            })
        } else {
            settingsLoader.source = src
            Qt.callLater(function() {
                if (!settingsLoader.item) return
                settingsLoader.item.panelVisible = true
                settingsLoader.item.anchorItem = anchorItem
                settingsLoader.item.topPanelItem = topStatusPanel
                if (settingsLoader.item.hasOwnProperty("reposition")) {
                    settingsLoader.item.reposition()
                }
            })
        }
    }

    function openChecklist(anchorItem) {
        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
        if (!loaderExists) return

        const src = _uiQrcBase + "TopStatusPanel_Checklist.qml"

        if (settingsLoader.source && settingsLoader.source.toString().includes("TopStatusPanel_Checklist.qml")) {
            settingsLoader.source = ""
            return
        }

        if (_veh) {
            _veh.checkListState = Vehicle.CheckListFailed
        }

        settingsLoader.setSource(src, {
            panelVisible: true,
            anchorItem: anchorItem,
            topPanelItem: topStatusPanel
        })
    }

    readonly property var _activeVeh: QGroundControl.multiVehicleManager.activeVehicle

    Connections {
        target: _activeVeh
        function onNewFormattedMessage(message) {
            if (message && message.length > 0) {
                topStatusPanel.hasNewMessages = true
            }
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) {
            if (activeVehicle) {
                topStatusPanel.hasNewMessages = false
            }
        }
    }

    readonly property var _veh: QGroundControl.multiVehicleManager.activeVehicle
    readonly property var _bat: _veh && _veh.batteries && _veh.batteries.count > 0 ? _veh.batteries.get(0) : null

    // Red: no link, link lost or not ready. Green: ready or armed. Blue: in the air.
    function statusAccent(statusText) {
        if (statusText === _flyingText || statusText === _landingText) return AzTheme.statusBlue
        if (statusText === _readyToFlyText || statusText === _armedText) return AzTheme.statusGreen
        return AzTheme.statusRed
    }

    function statusGlow(statusText) {
        if (statusText === _flyingText || statusText === _landingText) return AzTheme.statusBlueGlow
        if (statusText === _readyToFlyText || statusText === _armedText) return AzTheme.statusGreenGlow
        return AzTheme.statusRedGlow
    }

    function gpsIconColor() {
        const v = _veh
        const g = v && v.gps ? v.gps : null
        const gpsCount = g && g.count ? g.count.rawValue : NaN

        if (!g) return AzTheme.textCard
        if (isNaN(gpsCount) || gpsCount <= 0) return AzTheme.statusRed
        return AzTheme.statusGreen
    }

    function batteryIconColor() {
        const b = _bat
        if (!b) return AzTheme.textCard

        const st = b.chargeState ? b.chargeState.rawValue : undefined
        if (st === MAVLink.MAV_BATTERY_CHARGE_STATE_LOW) return AzTheme.statusOrange
        if (st === MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL ||
                st === MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY ||
                st === MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED ||
                st === MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY) return AzTheme.statusRed

        const p = safeBatteryPercent(b)
        if (!isNaN(p)) {
            if (p > threshold1) return AzTheme.statusGreen
            if (p > threshold2) return AzTheme.statusYellow
            return AzTheme.statusOrange
        }

        return AzTheme.textCard
    }

    function flightModeIconColor() {
        return (_veh && _veh.flightMode && _veh.flightMode !== "n/a") ? AzTheme.statusGreen : AzTheme.textCard
    }

    function _factVal(f) {
        if (f === null || f === undefined) return NaN
        if (f.rawValue !== undefined) return f.rawValue
        if (f.value !== undefined)    return f.value
        return f
    }

    readonly property bool _vehReady: _veh ? true : false
    readonly property real _rssi: _vehReady ? _factVal(_veh.rcRSSI) : NaN
    readonly property bool _rssiOk: !isNaN(_rssi) && _rssi >= 0 && _rssi <= 100

    function rcIconColor() {
        if (!_vehReady)  return AzTheme.textCard
        if (!_rssiOk)    return AzTheme.statusRed
        if (_rssi <= 40) return AzTheme.statusYellow
        if (_rssi >= 70) return AzTheme.statusGreen
        return AzTheme.statusOrange
    }

    function rcQualityLabel() {
        if (!_vehReady) return "n/a"
        if (!_rssiOk) return qsTr("RC yoxdur")
        if (_rssi >= 70) return qsTr("Əla")
        if (_rssi >= 40) return qsTr("Yaxşı")
        return qsTr("Zəif")
    }

    function rcValueText() {
        if (!_vehReady) return "n/a"
        if (!_rssiOk) return qsTr("RC yoxdur")
        return rcQualityLabel() + " (" + Math.round(_rssi) + "%)"
    }

    function telemetryIconColor() {
        if (!_vehReady) return AzTheme.textCard

        var rssi = _veh.telemetryLRSSI
        if (rssi === undefined || rssi === null || rssi === 0) return AzTheme.statusRed
        if (rssi >= -60) return AzTheme.statusGreen
        if (rssi >= -80) return AzTheme.statusOrange
        return AzTheme.statusRed
    }

    function telemetryQualityLabel() {
        if (!_vehReady) return "n/a"
        var rssi = _veh.telemetryLRSSI
        if (rssi === 0 || rssi === undefined || rssi === null) return qsTr("Telemetriya yox")

        if (rssi >= -60) return qsTr("Əla")
        if (rssi >= -80) return qsTr("Yaxşı")
        return qsTr("Zəif")
    }

    function telemetryValueText() {
        if (!_vehReady) return qsTr("Əlaqə yoxdur")
        var rssi = _veh.telemetryLRSSI
        if (rssi === 0 || rssi === undefined || rssi === null) return "Telemetriya yoxdur"
        return telemetryQualityLabel() + " (" + rssi + " dBm)"
    }

    // Which card's panel is open, so the card can show it.
    readonly property bool   _hasSettingsLoader:  (typeof settingsLoader !== "undefined") && settingsLoader !== null
    readonly property string _settingsSource:     _hasSettingsLoader && settingsLoader.source ? settingsLoader.source.toString() : ""
    readonly property bool   _settingsPanelShown: _hasSettingsLoader && settingsLoader.item ? settingsLoader.item.panelVisible !== false : false

    // The settings loader file names each card's panels live in (its settings included).
    readonly property var _settingsFilesOf: ({
        "checklist": "TopStatusPanel_Checklist",
        "flightMode": "TopStatusPanel_UcusRejimi",
        "rcSignal":   "TopStatusPanel_RCSignal",
        "telemetry":  "TopStatusPanel_Telemetry",
        "battery":    "TopStatusPanel_Battery",
        "gps":        "TopStatusPanel_GPS"
    })

    // Only one card panel is open at a time: before a card toggles its own panel, every
    // other card's panel closes.
    function closeOtherPanels(blockId) {
        if (blockId !== "status" && statusMessageLoader.item && statusMessageLoader.item.visible) {
            statusMessageLoader.item.close()
        }
        if (blockId !== "flightMode" && flightModePopupVisible) {
            closeFlightModePopup()
        }
        if (_hasSettingsLoader && _settingsSource !== "") {
            var keep = _settingsFilesOf[blockId]
            if (!keep || _settingsSource.indexOf(keep) < 0) {
                settingsLoader.source = ""
            }
        }
        if (blockId !== "vehicle" && vehicleSelectorLoader.item && vehicleSelectorLoader.item.panelVisible) {
            vehicleSelectorLoader.item.panelVisible = false
        }
        if (blockId !== "udpPosition" && udpPanelLoader.item && udpPanelLoader.item.panelVisible) {
            udpPanelLoader.item.panelVisible = false
        }
    }

    function blockPanelOpen(blockId) {
        function settingsShows(fileName) {
            return _settingsPanelShown && _settingsSource.indexOf(fileName) >= 0
        }
        switch (blockId) {
        case "status":      return !!(statusMessageLoader.item && statusMessageLoader.item.visible)
        case "checklist":   return settingsShows("TopStatusPanel_Checklist")
        case "flightMode":  return flightModePopupVisible || settingsShows("TopStatusPanel_UcusRejimi")
        case "rcSignal":    return settingsShows("TopStatusPanel_RCSignal")
        case "telemetry":   return settingsShows("TopStatusPanel_Telemetry")
        case "battery":     return settingsShows("TopStatusPanel_Battery")
        case "gps":         return settingsShows("TopStatusPanel_GPS")
        case "vehicle":     return !!(vehicleSelectorLoader.item && vehicleSelectorLoader.item.panelVisible)
        case "udpPosition": return !!(udpPanelLoader.item && udpPanelLoader.item.panelVisible)
        }
        return false
    }

    // =========================
    //  Bar background: linear-gradient(155deg), box-shadow 0 8px 16px rgba(0, 0, 0, 0.28)
    // =========================
    RectangularShadow {
        anchors.fill: barBackground
        offset.y:     AzTheme.px(8)
        blur:         AzTheme.px(16)
        color:        AzTheme.topBarShadow
    }

    AzGradientRect {
        id:            barBackground
        anchors.fill:  parent
        angle:         AzTheme.panelGradientAngle
        startColor:    AzTheme.panelGradientStart
        startPosition: AzTheme.panelGradientStartPos
        endColor:      AzTheme.panelGradientEnd
        endPosition:   AzTheme.panelGradientEndPos
    }

    Component {
        id: statusBlockComponent

        Item {
            id: block

            property url    icon:      ""
            property real   iconW:     24
            property real   iconH:     24
            property color  iconColor: AzTheme.textCard
            // Stable, never translated key used for all dispatch/comparisons.
            // Never branch on `label` - it changes with the UI language.
            property string blockId:   ""
            property string label:     ""
            property string valueText: ""
            property var    battery:   null

            property string tooltipText: ""
            property bool   showTooltip: false

            readonly property bool isStatusBlock: blockId === "status"
            readonly property bool isClickable:   isStatusBlock || (blockId === "checklist") || (blockId === "udpPosition") || (blockId === "vehicle") || topStatusPanel.isConnected
            readonly property bool isActive:      topStatusPanel.blockPanelOpen(blockId)

            // The status card is red, green or blue with the vehicle state and pulses its
            // glow when that changes. The other cards only tint their icon; the flight
            // mode card glows briefly when the mode changes.
            property string currentStatus: ""
            property color  modeChangeGlow: "transparent"
            readonly property color accentColor: isStatusBlock ? topStatusPanel.statusAccent(currentStatus) : iconColor
            readonly property color glowColor:   isStatusBlock ? topStatusPanel.statusGlow(currentStatus) : modeChangeGlow

            // Width this card's title needs: icon at 20, text 12 after it, 16 to the right
            // edge (28 on the status card, which has the dot there). All cards take the
            // widest of these (topStatusPanel._blockW).
            readonly property real _rightInset:   AzTheme.px(isStatusBlock ? 28 : 16)
            readonly property real naturalWidth:  Math.ceil(AzTheme.px(20) + blockIcon.width + AzTheme.px(12) + titleText.implicitWidth + _rightInset)

            // Icon and text are centred on the card as one group; the two lines stay
            // left-aligned inside it so they line up with each other and the icon.
            readonly property real _leftInset:  AzTheme.px(16)
            readonly property real _textGap:    AzTheme.px(12)
            readonly property real _textRoom:   Math.max(0, width - _leftInset - _rightInset - blockIcon.width - _textGap)
            readonly property real _textW:      Math.min(_textRoom, Math.max(titleText.implicitWidth, valueTextItem.implicitWidth))
            readonly property real _contentX:   _leftInset + (width - _leftInset - _rightInset - (blockIcon.width + _textGap + _textW)) / 2

            width:  topStatusPanel._blockW
            height: topStatusPanel._blockH

            function updateStatus() {
                var statusText = topStatusPanel.getDetailedIhaStatus().text
                if (statusText === currentStatus) {
                    return
                }
                currentStatus = statusText
                glowPulse.restart()
            }

            // box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2)
            RectangularShadow {
                anchors.fill: cardBackground
                offset.y:     AzTheme.px(8)
                blur:         AzTheme.px(20)
                radius:       cardBackground.radius
                color:        AzTheme.cardShadow
            }

            // linear-gradient(145deg, #25272A, #181B1E), 1 px #353A3F, radius 14
            AzGradientRect {
                id:            cardBackground
                anchors.fill:  parent
                angle:         AzTheme.cardGradientAngle
                startColor:    AzTheme.cardGradientStart
                startPosition: AzTheme.cardGradientStartPos
                endColor:      AzTheme.cardGradientEnd
                endPosition:   AzTheme.cardGradientEndPos
                radius:        AzTheme.px(AzTheme.cardRadius)
                borderWidth:   1
                borderColor:   block.isActive ? AzTheme.activeBorder
                                              : ((mouseArea.containsMouse && block.isClickable) ? AzTheme.cardHoverBorder : AzTheme.cardBorder)
            }

            // Open panel: the blue tint of the kebab button's hover.
            Rectangle {
                anchors.fill:    parent
                anchors.margins: 1
                radius:          cardBackground.radius - 1
                visible:         block.isActive
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0;      color: AzTheme.activeTintStart }
                    GradientStop { position: 0.5982; color: AzTheme.activeTintEnd }
                }
            }

            // inset 0 1px 0 rgba(255, 255, 255, 0.024)
            Rectangle {
                x:      cardBackground.radius
                y:      1
                width:  parent.width - (2 * cardBackground.radius)
                height: 1
                color:  AzTheme.cardTopHighlight
            }

            AzRadialGlow {
                id:           glow
                anchors.fill: parent
                radius:       cardBackground.radius
                color:        block.glowColor
                visible:      block.glowColor.a > 0
            }

            SequentialAnimation {
                id:    glowPulse
                loops: 3
                NumberAnimation { target: glow; property: "opacity"; to: 0.15; duration: 250 }
                NumberAnimation { target: glow; property: "opacity"; to: 1.0;  duration: 250 }
                onStopped: glow.opacity = 1.0
            }

            Timer {
                id:       modeChangeStopTimer
                interval: 1600
                onTriggered: block.modeChangeGlow = "transparent"
            }

            Connections {
                target: topStatusPanel._veh
                function onFlightModeChanged() {
                    if (block.blockId === "flightMode") {
                        block.modeChangeGlow = AzTheme.modeChangeGlow
                        glowPulse.restart()
                        modeChangeStopTimer.restart()
                    }
                }
            }

            onValueTextChanged: {
                if (isStatusBlock) {
                    updateStatus()
                }
            }

            Component.onCompleted: {
                if (isStatusBlock) {
                    updateStatus()
                    statusCheckTimer.start()
                }
            }

            // Not every input of getDetailedIhaStatus() notifies, so poll it as before.
            Timer {
                id:       statusCheckTimer
                interval: 1000
                repeat:   true
                onTriggered: block.updateStatus()
            }

            ToolTip {
                id:      batteryTooltip
                visible: block.showTooltip && block.tooltipText !== ""
                text:    block.tooltipText
                delay:   500
                timeout: 3000

                background: Rectangle {
                    color:        AzTheme.cardGradientEnd
                    border.color: AzTheme.cardHoverBorder
                    radius:       AzTheme.px(8)
                }

                contentItem: Text {
                    text:           batteryTooltip.text
                    color:          AzTheme.textCard
                    font.family:    AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(12)
                }
            }

            // The icon sits level with the title, not centred on the card.
            QGCColoredImage {
                id:                           blockIcon
                x:                            Math.round(block._contentX)
                anchors.verticalCenter:       parent.verticalCenter
                anchors.verticalCenterOffset: -AzTheme.px(6)
                width:                        AzTheme.px(block.iconW)
                height:                       AzTheme.px(block.iconH)
                source:                       block.icon
                color:                        block.accentColor

                // filter: drop-shadow(0 0 16px rgba(255, 52, 67, 0.25)) on the status icon
                layer.enabled: block.isStatusBlock
                layer.effect: MultiEffect {
                    shadowEnabled:          true
                    shadowColor:            Qt.rgba(block.accentColor.r, block.accentColor.g, block.accentColor.b, 0.25)
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset:   0
                    blurMax:                AzTheme.px(16)
                    shadowBlur:             1.0
                }
            }

            Text {
                id:                           titleText
                anchors.left:                 blockIcon.right
                anchors.leftMargin:           block._textGap
                width:                        block._textW
                anchors.verticalCenter:       parent.verticalCenter
                anchors.verticalCenterOffset: -AzTheme.px(11)
                text:                         block.label
                color:                        AzTheme.textCard
                font.family:                  AzTheme.fontFamily
                font.weight:                  Font.DemiBold
                font.pixelSize:               AzTheme.fontPx(18)
                elide:                        Text.ElideRight
            }

            Text {
                id:                           valueTextItem
                anchors.left:                 blockIcon.right
                anchors.leftMargin:           block._textGap
                width:                        block._textW
                anchors.verticalCenter:       parent.verticalCenter
                anchors.verticalCenterOffset: AzTheme.px(10)
                color:                        AzTheme.textSecondary
                font.family:                  AzTheme.fontFamily
                font.pixelSize:               AzTheme.fontPx(14)
                elide:                        Text.ElideRight
                text: {
                    if (block.battery) return topStatusPanel.safeBatteryValueText(block.battery)
                    if (block.valueText && block.valueText.length > 0) return block.valueText
                    return "n/a"
                }
            }

            // Status dot: 7 px, box-shadow 0 0 7px in the same colour
            RectangularShadow {
                anchors.fill: statusDot
                visible:      block.isStatusBlock
                radius:       statusDot.radius
                blur:         AzTheme.px(7)
                color:        block.accentColor
            }

            Rectangle {
                id:      statusDot
                visible: block.isStatusBlock
                x:       parent.width - AzTheme.px(20)
                y:       AzTheme.px(9)
                width:   Math.max(4, AzTheme.px(7))
                height:  width
                radius:  width / 2
                color:   block.accentColor
            }

            MouseArea {
                id:           mouseArea
                anchors.fill: parent
                cursorShape:  block.isClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                hoverEnabled: true

                onEntered: {
                    if (block.isClickable && block.blockId === "battery") {
                        block.tooltipText = topStatusPanel.checkBatteryFailsafe(topStatusPanel._bat)
                        if (block.tooltipText !== "") {
                            block.showTooltip = true
                        }
                    }
                }

                onExited: block.showTooltip = false

                onClicked: {
                    if (!block.isClickable) return

                    topStatusPanel.closeOtherPanels(block.blockId)

                    if (block.blockId === "disconnect") {
                        topStatusPanel.disconnectVehicle()
                        return
                    }

                    if (block.blockId === "status") {
                        topStatusPanel.openMessageOverlay(block)
                        return
                    }

                    if (block.blockId === "telemetry") {
                        topStatusPanel.openTelemetry(block)
                        return
                    }

                    if (block.blockId === "checklist") {
                        topStatusPanel.openChecklist(block)
                        return
                    }

                    if (block.blockId === "flightMode") {
                        topStatusPanel.openFlightModePopup(block)
                        return
                    }

                    if (block.blockId === "battery") {
                        topStatusPanel.openBatteryPopup(block)
                        return
                    }

                    if (block.blockId === "rcSignal") {
                        topStatusPanel.openRCSignalPopup(block)
                        return
                    }

                    if (block.blockId === "gps") {
                        topStatusPanel.openGPSPopup(block)
                        return
                    }
                    if (block.blockId === "vehicle") {
                        topStatusPanel.openVehicleSelectorPopup(block)
                        return
                    }
                    if (block.blockId === "udpPosition") {
                        topStatusPanel.openUdpPositionPopup(block)
                        return
                    }
                }
            }
        }
    }

    // =========================
    //  Cards: 280x64, 8 px apart, padding 8/12; the strip scrolls when they do not fit
    // =========================
    Flickable {
        id:             statusFlick
        anchors.left:   parent.left
        anchors.right:  menuArea.left
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        clip:               true
        flickableDirection: Flickable.HorizontalFlick
        interactive:        contentWidth > width
        boundsBehavior:     Flickable.StopAtBounds

        contentWidth:  statusRow.implicitWidth
        contentHeight: height

        // Land on the nearest card's left edge instead of stopping mid-card.
        onMovementEnded: {
            var target = contentX
            var bestDistance = Infinity
            for (var i = 0; i < statusRow.children.length; ++i) {
                var cardX = statusRow.children[i].x - statusRow.leftPadding
                var distance = Math.abs(cardX - contentX)
                if (distance < bestDistance) {
                    bestDistance = distance
                    target = cardX
                }
            }
            var maxX = Math.max(0, contentWidth - width)
            statusSnap.to = Math.min(maxX, Math.max(0, target))
            statusSnap.restart()
        }

        NumberAnimation {
            id:          statusSnap
            target:      statusFlick
            property:    "contentX"
            duration:    140
            easing.type: Easing.OutCubic
        }

        Row {
            id:            statusRow
            height:        statusFlick.height
            spacing:       topStatusPanel._blockGap
            leftPadding:   topStatusPanel._padH
            rightPadding:  topStatusPanel._padH
            topPadding:    Math.max(0, (height - topStatusPanel._blockH) / 2)

            function addBlock(props) {
                var obj = statusBlockComponent.createObject(statusRow, props)
                if (!obj) {
                    console.warn("Status block create failed")
                    return null
                }

                if (props.blockId === "battery") {
                    obj.tooltipText = Qt.binding(function() {
                        return topStatusPanel.checkBatteryFailsafe(topStatusPanel._bat)
                    })
                }

                return obj
            }

            Component.onCompleted: {
                addBlock({
                    icon: _azV2IconBase + "top_status.svg",
                    blockId: "status",
                    label: qsTr("Status"),
                    valueText: Qt.binding(function () { return topStatusPanel.getDetailedIhaStatus().text })
                })

                addBlock({
                    icon: _azV2IconBase + "top_checklist.svg",
                    iconW: 26,
                    iconH: 26,
                    iconColor: Qt.binding(function () { return topStatusPanel.checklistIconColor() }),
                    blockId: "checklist",
                    label: qsTr("Yoxlama Paneli"),
                    valueText: Qt.binding(function () {
                        var v = topStatusPanel._veh
                        if (!v) return qsTr("Yoxlama siyahısı")
                        return (v.checkListState === Vehicle.CheckListPassed) ? qsTr("Keçdi") : qsTr("Davam edir")
                    })
                })

                addBlock({
                    icon: _azV2IconBase + "top_flightmode.svg",
                    iconColor: Qt.binding(function () { return topStatusPanel.flightModeIconColor() }),
                    blockId: "flightMode",
                    label: qsTr("Uçuş Rejimi"),
                    valueText: Qt.binding(function () {
                        var v = topStatusPanel._veh
                        if (!v) return "n/a"
                        if (v.flightMode && v.flightMode.length > 0) return v.flightMode
                        return "n/a"
                    })
                })

                addBlock({
                    icon: _azV2IconBase + "top_rc.svg",
                    iconColor: Qt.binding(function () { return topStatusPanel.rcIconColor() }),
                    blockId: "rcSignal",
                    label: qsTr("RC Siqnalı"),
                    valueText: Qt.binding(function () { return topStatusPanel.rcValueText() })
                })

                addBlock({
                    icon: _azV2IconBase + "top_telemetry.svg",
                    iconColor: Qt.binding(function () { return topStatusPanel.telemetryIconColor() }),
                    blockId: "telemetry",
                    label: qsTr("Telemetriya"),
                    valueText: Qt.binding(function () { return topStatusPanel.telemetryValueText() })
                })

                addBlock({
                    icon: _azV2IconBase + "top_battery.svg",
                    iconColor: Qt.binding(function () { return topStatusPanel.batteryIconColor() }),
                    blockId: "battery",
                    label: qsTr("Batareya"),
                    battery: Qt.binding(function(){ return topStatusPanel._bat }),
                    valueText: Qt.binding(function() {
                        var battery = topStatusPanel._bat
                        if (!battery) return "n/a"

                        var batteryValue = topStatusPanel.safeBatteryValueText(battery)
                        var failsafeStatus = topStatusPanel.checkBatteryFailsafe(battery)

                        if (failsafeStatus !== "") return "⚠️ " + batteryValue
                        return batteryValue
                    })
                })

                addBlock({
                    icon: _azV2IconBase + "top_gps.svg",
                    iconColor: Qt.binding(function () { return topStatusPanel.gpsIconColor() }),
                    blockId: "gps",
                    label: "GPS",
                    valueText: Qt.binding(function () {
                        var v = topStatusPanel._veh
                        return (v && v.gps && v.gps.count && v.gps.count.valueString !== undefined)
                                ? v.gps.count.valueString
                                : "n/a"
                    })
                })

                addBlock({
                    icon: _azV2IconBase + "top_vehicle.svg",
                    iconW: 30,
                    blockId: "vehicle",
                    label: qsTr("Aparat"),
                    valueText: Qt.binding(function () {
                        var mvm = QGroundControl.multiVehicleManager
                        var av  = mvm ? mvm.activeVehicle : null
                        if (!av) return "Yoxdur"
                        var count = (mvm && mvm.vehicles) ? mvm.vehicles.count : 0
                        var label = "Vehicle " + av.id
                        if (count > 1) label += "  (" + count + ")"
                        return label
                    })
                })

                addBlock({
                    icon: _azV2IconBase + "top_udp.svg",
                    blockId: "udpPosition",
                    label: qsTr("UDP Pozisiya"),
                    valueText: Qt.binding(function () {
                        if (!topStatusPanel._extActive) return qsTr("Gözləyir...")
                        return topStatusPanel._extLat.toFixed(5)
                               + " / "
                               + topStatusPanel._extLon.toFixed(5)
                    })
                })
            }
        }
    }

    // Thin scroll indicator along the bottom edge, shown while the strip moves.
    ScrollBar {
        id: statusHScrollBar
        orientation: Qt.Horizontal
        policy: ScrollBar.AsNeeded
        // Nothing attaches this bar to the Flickable, so `active` would stay
        // false and AsNeeded would never paint it. Drive it by hand: the style
        // fades the bar in while the strip moves and back out afterwards.
        active: statusFlick.moving || statusFlick.dragging

        anchors.left:   statusFlick.left
        anchors.right:  statusFlick.right
        anchors.bottom: parent.bottom
        // Basic style pads the bar by 2 on each side, which left the 4px-high
        // groove with a zero-height thumb - nothing was ever drawn.
        padding: 0
        height:  Math.max(3, AzTheme.px(4))

        size:     statusFlick.visibleArea.widthRatio
        position: statusFlick.visibleArea.xPosition
        // Yalnız istifadəçi göstəricini sürüşdürəndə contentX-i yenilə (binding loop olmasın)
        onPositionChanged: {
            if (pressed) {
                statusFlick.contentX = position * statusFlick.contentWidth
            }
        }
    }

    Connections {
        target: statusFlick
        function onContentXChanged() {
            if (topStatusPanel.flightModePopupVisible && flightModePopupLoader.item && flightModePopupLoader.item.reposition) {
                flightModePopupLoader.item.reposition()
            }
            if ((typeof settingsLoader !== "undefined") && settingsLoader && settingsLoader.item && settingsLoader.item.reposition) {
                settingsLoader.item.reposition()
            }
        }
    }

    // =========================
    //  Kebab menu at the right end: linear-gradient(180deg, #0F1215, #0B0D0F),
    //  a 42 px button with three #C8CACD dots
    // =========================
    Item {
        id:             menuArea
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        width:          topStatusPanel._menuW

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.topBarMenuTop }
                GradientStop { position: 1; color: AzTheme.topBarMenuBottom }
            }
        }

        Item {
            id:               menuButton
            anchors.centerIn: parent
            width:            AzTheme.px(42)
            height:           width

            // linear-gradient(90deg, rgba(29, 78, 216, 0.04), rgba(37, 99, 235, 0.09))
            Rectangle {
                anchors.centerIn: parent
                width:            AzTheme.px(36)
                height:           width
                radius:           AzTheme.px(9.2)
                visible:          menuMouse.containsMouse || menuMouse.pressed || windowMenu.visible
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0;      color: AzTheme.activeTintStart }
                    GradientStop { position: 0.5982; color: AzTheme.activeTintEnd }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing:          AzTheme.px(4.5)

                Repeater {
                    model: 3
                    Rectangle {
                        width:  Math.max(3, AzTheme.px(3.75))
                        height: width
                        radius: width / 2
                        color:  AzTheme.topBarMenuIcon
                    }
                }
            }

            MouseArea {
                id:           menuMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    windowMenu.visible ? windowMenu.close() : windowMenu.open()
            }
        }

        Popup {
            id:          windowMenu
            y:           menuArea.height + AzTheme.px(6)
            x:           menuArea.width - width - AzTheme.px(8)
            padding:     AzTheme.px(6)
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
            // A Shape's implicit size follows its path, which follows the popup, so
            // size the popup from its content alone.
            implicitWidth:  contentItem.implicitWidth + leftPadding + rightPadding
            implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding

            background: AzGradientRect {
                angle:         AzTheme.panelGradientAngle
                startColor:    AzTheme.menuSelectedBottom
                startPosition: AzTheme.panelGradientStartPos
                endColor:      AzTheme.panelGradientEnd
                endPosition:   AzTheme.panelGradientEndPos
                radius:        AzTheme.px(AzTheme.cardRadius)
                borderColor:   AzTheme.panelBorder
                borderWidth:   1
            }

            contentItem: Column {
                spacing: AzTheme.px(2)

                Repeater {
                    model: [ { text: qsTr("Çıxış"), icon: "menu_exit.svg" } ]

                    delegate: Item {
                        width:  AzTheme.px(220)
                        height: AzTheme.px(44)

                        Rectangle {
                            anchors.fill: parent
                            radius:       AzTheme.px(8)
                            visible:      menuItemMouse.containsMouse || menuItemMouse.pressed
                            color:        Qt.rgba(1, 1, 1, 0.05)
                            border.width: 1
                            border.color: AzTheme.panelBorder
                        }

                        Image {
                            id:                     menuItemIcon
                            x:                      AzTheme.px(12)
                            anchors.verticalCenter: parent.verticalCenter
                            width:                  AzTheme.px(18)
                            height:                 width
                            sourceSize.width:       width
                            sourceSize.height:      height
                            fillMode:               Image.PreserveAspectFit
                            source:                 _azV2IconBase + modelData.icon
                        }

                        Text {
                            anchors.left:           menuItemIcon.right
                            anchors.leftMargin:     AzTheme.px(12)
                            anchors.verticalCenter: parent.verticalCenter
                            text:                   modelData.text
                            color:                  AzTheme.textCard
                            font.family:            AzTheme.fontFamily
                            font.pixelSize:         AzTheme.fontPx(16)
                        }

                        MouseArea {
                            id:           menuItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                windowMenu.close()
                                topStatusPanel.exitRequested()
                            }
                        }
                    }
                }
            }
        }
    }

    // Parameter download progress along the bottom edge.
    Rectangle {
        anchors.bottom: parent.bottom
        height:         topStatusPanel._progressH
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          AzTheme.statusGreen
        visible:        !_showLargeProgress
    }

    Loader {
        id: statusMessageLoader

        parent: topStatusPanel._overlayHost
        anchors.fill: parent
        z: 9999

        active: false
        asynchronous: true
        source: _uiQrcBase + "TopStatusMessage.qml"

        onLoaded: {
            if (!item) return

            if (item.hasOwnProperty("statusPanelItem")) {
                item.statusPanelItem = topStatusPanel
            }
            item.anchorItem = topStatusPanel._statusAnchorItem

            if (topStatusPanel._pendingOpenStatusOverlay && item.open) {
                item.open()
                topStatusPanel._pendingOpenStatusOverlay = false
            }
        }
    }

    Loader {
        id: flightModePopupLoader

        parent: (_mw && _mw.contentItem) ? _mw.contentItem : topStatusPanel
        anchors.fill: parent

        // The source is set by openFlightModePopup() with the panel's anchor as initial
        // properties: set after an asynchronous load, the card would first show at the
        // left edge and then jump under the "Uçuş Rejimi" card.
        active: topStatusPanel.flightModePopupVisible
        asynchronous: true
    }


    Loader {
        id: udpPanelLoader

        property var anchorItemRef: null

        parent: (_mw && _mw.contentItem) ? _mw.contentItem : topStatusPanel
        anchors.fill: parent

        active:      false
        asynchronous: false
        source:      _uiQrcBase + "TopStatusPanel_UDPPosition.qml"
        z:           9500

        onLoaded: {
            if (!item) return
            item.anchorItem   = udpPanelLoader.anchorItemRef
            item.topPanelItem = topStatusPanel
            item.panelVisible = true
            item.reposition()
        }
    }

    Loader {
        id: vehicleSelectorLoader

        property var anchorItemRef: null

        parent: (_mw && _mw.contentItem) ? _mw.contentItem : topStatusPanel
        anchors.fill: parent

        active:       false
        asynchronous: false
        source:       _uiQrcBase + "TopStatusPanel_VehicleSelector.qml"
        z:            9500

        onLoaded: {
            if (!item) return
            item.anchorItem   = vehicleSelectorLoader.anchorItemRef
            item.topPanelItem = topStatusPanel
            item.panelVisible = true
            item.reposition()
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) {
            if (vehicleSelectorLoader.item && vehicleSelectorLoader.item.panelVisible) {
                vehicleSelectorLoader.item.panelVisible = false
            }
        }
    }

}

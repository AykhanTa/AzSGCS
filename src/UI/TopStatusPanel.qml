import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id: topStatusPanel

    readonly property string _azIconBase: "qrc:/res/AZSHIELD_ICON/"
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

    property bool flightModePopupVisible: false
    property Item flightModePopupAnchorItem: null

    function openFlightModePopup(anchorItem) {
        const loaderExists = typeof settingsLoader !== "undefined" && settingsLoader !== null
        if (loaderExists) {
            settingsLoader.source = ""
        }

        flightModePopupAnchorItem = anchorItem
        flightModePopupVisible = true

        if (flightModePopupLoader.item) {
            flightModePopupLoader.item.anchorItem    = flightModePopupAnchorItem
            flightModePopupLoader.item.activeVehicle = topStatusPanel._veh
            flightModePopupLoader.item.statusPanel   = topStatusPanel

            if (flightModePopupLoader.item.hasOwnProperty("reposition")) {
                flightModePopupLoader.item.reposition()
            }
        }
    }

    function closeFlightModePopup() {
        flightModePopupVisible = false
        flightModePopupAnchorItem = null
    }

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : Math.max(12, Qt.application.font.pixelSize)
    readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : Math.max(8,  Qt.application.font.pixelSize * 0.60)

    readonly property real _hMargin:     Math.max(_fontW * 0.7, 6)
    readonly property real _vMargin:     Math.max(_fontH * 0.25, 4)
    readonly property real _inBlockPad:  Math.max(_fontW * 0.6, 4)
    readonly property real _blockSpace:  Math.max(_fontW * 0.6, 6)
    readonly property real _iconSize:    Math.round(_clamp(_fontH * 1.45, 22, 26))

    readonly property real _controlSize: Math.round(_clamp(_fontH * 1.20, 18, 20))
    readonly property real _controlIcon: Math.round(_controlSize * 0.9)

    readonly property int  _blockCount: 8
    readonly property real _blockMinW:  Math.max(_fontW * 12, 118)
    readonly property real _blockMaxW:  Math.max(_fontW * 28, 320)

    readonly property real _progressH:   Math.max(3, height * 0.05)
    readonly property real _statusAreaW: statusFlick.width
    readonly property real _idealBlockW: (_statusAreaW - (_blockSpace * (_blockCount - 1))) / _blockCount
    readonly property real _blockW:      _clamp(_idealBlockW, _blockMinW, _blockMaxW)

    height: Math.round(_clamp(_fontH * 4.0, 56, 64))

    readonly property int _labelFontPx: Math.max(10, Math.round(_fontH * 0.78))
    readonly property int _valueFontPx: Math.max(10, Math.round(_fontH * 0.74))

    color: "black"
    clip: true
    z: 200

    property bool userHidden: false
    visible: !userHidden && !_planVisible

    signal minimizeRequested()
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

    readonly property real _rowSpacing: {
        if (_statusAreaW <= 0) return _blockSpace
        if (_idealBlockW > _blockMaxW) {
            var s = (_statusAreaW - (_blockMaxW * _blockCount)) / (_blockCount - 1)
            return Math.max(_blockSpace, s)
        }
        return _blockSpace
    }

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
            return "white"
        }

        return (v.checkListState === Vehicle.CheckListPassed) ? "green" : "red"
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
    property string _disconnectedText:  qsTr("Bağlantı Yox")
    property string _armedText:         qsTr("Armed")
    property string _flyingText:        qsTr("Flying")
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

    function openMessageOverlay() {
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

        if (statusMessageLoader.item && statusMessageLoader.item.open) {
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

    function openChecklist() {

        if (_veh) {
            _veh.checkListState = Vehicle.CheckListFailed
        }

        var comp = Qt.createComponent("qrc:/qml/QGroundControl/FlightDisplay/FlyViewPreFlightChecklistPopup.qml")

        function createPopup() {
            var obj = comp.createObject(_mw ? _mw : topStatusPanel)
            if (obj && obj.open) {
                obj.open()
            }
        }

        if (comp.status === Component.Ready) {
            createPopup()
        } else {
            comp.statusChanged.connect(function() {
                if (comp.status === Component.Ready) {
                    createPopup()
                }
            })
        }
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

    function gpsStatusIcon() {
        const v = _veh
        const g = v && v.gps ? v.gps : null
        const gpsCount = g && g.count ? g.count.rawValue : NaN

        if (!g) return _azIconBase + "GPS.svg"
        if (isNaN(gpsCount) || gpsCount <= 0) return _azIconBase + "GPSgirmizi.svg"
        return _azIconBase + "GPSyasil.svg"
    }

    function batterySvg() {
        const b = _bat
        if (!b) return "/qmlimages/Battery.svg"

        const st = b.chargeState ? b.chargeState.rawValue : undefined

        if (st === MAVLink.MAV_BATTERY_CHARGE_STATE_LOW)      return "/qmlimages/BatteryOrange.svg"
        if (st === MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL) return "/qmlimages/BatteryCritical.svg"
        if (st === MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY ||
                st === MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED ||
                st === MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY) return "/qmlimages/BatteryEMERGENCY.svg"

        const p = safeBatteryPercent(b)
        if (!isNaN(p)) {
            if (p > threshold1) return "/qmlimages/BatteryGreen.svg"
            if (p > threshold2) return "/qmlimages/BatteryYellowGreen.svg"
            return "/qmlimages/BatteryYellow.svg"
        }

        return "/qmlimages/Battery.svg"
    }

    function flightModeColor() {
        if (_veh && _veh.flightMode && _veh.flightMode === "AUTO") return "green"
        return "white"
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

    function rcIconSource() {
        if (!_vehReady) return _azIconBase + "RCSignal.svg"
        if (!_rssiOk)   return _azIconBase + "RCSignalRed.svg"
        if (_rssi <= 40) return _azIconBase + "RCSignalYellow.svg"
        if (_rssi >= 70) return _azIconBase + "RCSignalGreen.svg"
        return _azIconBase + "RCSignalOrange.svg"
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

    function telemetryIconSource() {
        if (!_vehReady) return _azIconBase + "Telemetri.svg"

        var rssi = _veh.telemetryLRSSI
        if (rssi === undefined || rssi === null || rssi === 0) {
            return _azIconBase + "TelemetriRed.svg"
        }

        if (rssi >= -60) return _azIconBase + "TelemetriGreen.svg"
        if (rssi >= -80) return _azIconBase + "TelemetriOrange.svg"
        return _azIconBase + "TelemetriRed.svg"
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
        if (!_vehReady) return qsTr("Aparat yox")
        var rssi = _veh.telemetryLRSSI
        if (rssi === 0 || rssi === undefined || rssi === null) return "Telemetriya yoxdur"
        return telemetryQualityLabel() + " (" + rssi + " dBm)"
    }

    function batteryColor() {
        const b = _bat
        if (!b) return QGroundControl.globalPalette.text

        const st = b.chargeState ? b.chargeState.rawValue : undefined
        if (st === MAVLink.MAV_BATTERY_CHARGE_STATE_LOW) return QGroundControl.globalPalette.colorOrange
        if (st === MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL) return QGroundControl.globalPalette.colorRed
        if (st === MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY ||
                st === MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED ||
                st === MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY) return QGroundControl.globalPalette.colorRed

        const p = safeBatteryPercent(b)
        if (!isNaN(p)) {
            if (p > threshold1) return QGroundControl.globalPalette.colorGreen
            if (p > threshold2) return QGroundControl.globalPalette.colorYellowGreen
            return QGroundControl.globalPalette.colorYellow
        }

        return QGroundControl.globalPalette.text
    }

    Row {
        id: windowControls
        spacing: Math.max(topStatusPanel._fontW * 0.6, 6)
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: topStatusPanel._vMargin
        anchors.rightMargin: topStatusPanel._hMargin
        z: 10

        Rectangle {
            width: topStatusPanel._controlSize
            height: topStatusPanel._controlSize
            radius: Math.max(4, topStatusPanel._controlSize * 0.30)
            color: "transparent"

            Image {
                source: _azIconBase + "exit.svg"
                anchors.centerIn: parent
                width: topStatusPanel._controlIcon
                height: topStatusPanel._controlIcon
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: topStatusPanel.exitRequested()
            }
        }
    }

    Component {
        id: statusBlockComponent

        Rectangle {
            id: block

            property url icon: ""
            // Stable, never translated key used for all dispatch/comparisons.
            // Never branch on `label` - it changes with the UI language.
            property string blockId: ""
            property string label: ""
            property string valueText: ""
            property var battery: null

            property color normalColor: "#2b2b2b"
            property color baseColor: normalColor
            property color hoverColor: "#3a3a3a"
            property bool isHovered: false

            property color iconColor: "white"
            property color targetIconColor: "white"

            property string tooltipText: ""
            property bool showTooltip: false

            width: topStatusPanel._blockW
            height: (parent && parent.height > 0)
                    ? parent.height
                    : (topStatusPanel.height - (topStatusPanel._vMargin * 2) - (topStatusPanel._progressH + 2))

            radius: 8
            color: isHovered ? hoverColor : baseColor
            clip: true

            function restoreColorBinding() {
                block.color = Qt.binding(function() {
                    return block.isHovered ? block.hoverColor : block.baseColor
                })
            }

            property bool isStatusBlock: blockId === "status"
            property bool isClickable: isStatusBlock || (blockId === "checklist") || (blockId === "udpPosition") || (blockId === "vehicle") || topStatusPanel.isConnected

            property string currentStatus: ""

            ToolTip {
                id: batteryTooltip
                visible: block.showTooltip && block.tooltipText !== ""
                text: block.tooltipText
                delay: 500
                timeout: 3000

                background: Rectangle {
                    color: "#2A2A2A"
                    border.color: "#666666"
                    radius: 4
                }

                contentItem: Text {
                    text: batteryTooltip.text
                    color: "white"
                    font.pixelSize: 11
                }
            }

            onLabelChanged: {
                if (isStatusBlock) {
                    updateBlinkEffect()
                }
            }

            function updateBlinkEffect() {
                readyToFlyBlinkAnimation.stop()
                connectionLostBlinkAnimation.stop()
                notReadyBlinkAnimation.stop()
                armBlinkAnimation.stop()
                flyingBlinkAnimation.stop()

                var status = topStatusPanel.getDetailedIhaStatus()
                currentStatus = status.text

                block.baseColor = block.normalColor
                block.hoverColor = "#3a3a3a"
                block.iconColor = "white"

                if (currentStatus === topStatusPanel._readyToFlyText) {
                    block.targetIconColor = "green"
                    readyToFlyBlinkAnimation.start()
                } else if (currentStatus === topStatusPanel._commLostText ||
                           currentStatus === topStatusPanel._disconnectedText) {
                    block.targetIconColor = "#FF0000"
                    connectionLostBlinkAnimation.start()
                } else if (currentStatus === topStatusPanel._notReadyToFlyText) {
                    block.targetIconColor = "#FF0000"
                    notReadyBlinkAnimation.start()
                } else if (currentStatus === topStatusPanel._armedText) {
                    block.targetIconColor = "green"
                    armBlinkAnimation.start()
                } else if (currentStatus === topStatusPanel._flyingText ||
                           currentStatus === topStatusPanel._landingText) {
                    block.targetIconColor = "#0066FF"
                    flyingBlinkAnimation.start()
                } else {
                    block.iconColor = "white"
                    block.targetIconColor = "white"
                    restoreColorBinding()
                }
            }

            SequentialAnimation {
                id: readyToFlyBlinkAnimation
                PropertyAnimation { target: block; property: "color"; to: "green"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: "green"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                onStopped: {
                    block.iconColor = block.targetIconColor
                    restoreColorBinding()
                }
            }

            SequentialAnimation {
                id: connectionLostBlinkAnimation
                PropertyAnimation { target: block; property: "color"; to: "#FF0000"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: "#FF0000"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                onStopped: {
                    block.iconColor = block.targetIconColor
                    restoreColorBinding()
                }
            }

            SequentialAnimation {
                id: notReadyBlinkAnimation
                PropertyAnimation { target: block; property: "color"; to: "#FF0000"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: "#FF0000"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                onStopped: {
                    block.iconColor = block.targetIconColor
                    restoreColorBinding()
                }
            }

            SequentialAnimation {
                id: armBlinkAnimation
                PropertyAnimation { target: block; property: "color"; to: "green"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: "green"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                onStopped: {
                    block.iconColor = block.targetIconColor
                    restoreColorBinding()
                }
            }

            SequentialAnimation {
                id: flyingBlinkAnimation
                PropertyAnimation { target: block; property: "color"; to: "#0066FF"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: "#0066FF"; duration: 250 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 250 }
                onStopped: {
                    block.iconColor = block.targetIconColor
                    restoreColorBinding()
                }
            }

            SequentialAnimation {
                id: modeChangeBlinkAnimation
                running: false
                loops: 1
                PropertyAnimation { target: block; property: "color"; to: "#EECC44"; duration: 150 }
                PropertyAnimation { target: block; property: "color"; to: block.normalColor; duration: 150 }
            }

            Timer {
                id: modeChangeStopTimer
                interval: 3000
                repeat: false
                running: false
                onTriggered: {
                    modeChangeBlinkAnimation.stop()
                    restoreColorBinding()
                }
            }

            Connections {
                target: topStatusPanel._veh
                function onFlightModeChanged() {
                    if (block.blockId === "flightMode") {
                        modeChangeBlinkAnimation.start()
                        modeChangeStopTimer.restart()
                    }
                }
            }

            Component.onCompleted: {
                if (isStatusBlock) {
                    updateBlinkEffect()
                    statusCheckTimer.start()
                }
            }

            Timer {
                id: statusCheckTimer
                interval: 1000
                running: false
                repeat: true
                onTriggered: {
                    if (block.isStatusBlock) {
                        var newStatus = topStatusPanel.getDetailedIhaStatus().text
                        if (newStatus !== block.currentStatus) {
                            block.updateBlinkEffect()
                        }
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                enabled: block.isClickable

                onEntered: {
                    if (block.isClickable) {
                        block.isHovered = true
                        if (block.blockId === "battery") {
                            block.tooltipText = topStatusPanel.checkBatteryFailsafe(topStatusPanel._bat)
                            if (block.tooltipText !== "") {
                                block.showTooltip = true
                            }
                        }
                    }
                }

                onExited: {
                    block.isHovered = false
                    block.showTooltip = false
                }

                onClicked: {
                    if (!block.isClickable) return

                    if (block.blockId !== "flightMode" && topStatusPanel.flightModePopupVisible) {
                        topStatusPanel.closeFlightModePopup()
                    }

                    if (block.blockId === "disconnect") {
                        topStatusPanel.disconnectVehicle()
                        return
                    }

                    if (block.blockId === "status") {
                        topStatusPanel.openMessageOverlay()
                        return
                    }

                    if (block.blockId === "telemetry") {
                        topStatusPanel.openTelemetry(block)
                        return
                    }

                    if (block.blockId === "checklist") {
                        topStatusPanel.openChecklist()
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

            Item {
                anchors.fill: parent
                anchors.margins: topStatusPanel._inBlockPad

                Column {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: Math.max(2, topStatusPanel._fontH * 0.12)

                    RowLayout {
                        width: parent.width
                        spacing: topStatusPanel._inBlockPad

                        Item { Layout.fillWidth: true }

                        Item {
                            Layout.preferredWidth:  topStatusPanel._iconSize
                            Layout.preferredHeight: topStatusPanel._iconSize

                            Image {
                                anchors.fill: parent
                                visible: block.blockId === "battery"
                                source: topStatusPanel.batterySvg()
                                fillMode: Image.PreserveAspectFit
                            }

                            QGCColoredImage {
                                anchors.fill: parent
                                visible: block.blockId === "flightMode"
                                source: block.icon
                                fillMode: Image.PreserveAspectFit
                                color: topStatusPanel._veh && topStatusPanel._veh.flightMode && topStatusPanel._veh.flightMode !== "n/a"
                                       ? "#00FF00" : "white"
                            }

                            Image {
                                anchors.fill: parent
                                visible: block.blockId === "telemetry"
                                source: topStatusPanel.telemetryIconSource()
                                fillMode: Image.PreserveAspectFit
                                cache: false
                                asynchronous: false
                            }

                            Image {
                                anchors.fill: parent
                                visible: block.blockId === "rcSignal"
                                source: topStatusPanel.rcIconSource()
                                fillMode: Image.PreserveAspectFit
                                cache: false
                                asynchronous: false
                            }

                            Image {
                                anchors.fill: parent
                                visible: block.blockId === "disconnect"
                                source: _azIconBase + "disconnect.svg"
                                fillMode: Image.PreserveAspectFit
                            }

                            QGCColoredImage {
                                anchors.fill: parent
                                visible: block.blockId === "checklist"
                                source: block.icon
                                fillMode: Image.PreserveAspectFit
                                color: topStatusPanel.checklistIconColor()
                            }

                            Image {
                                anchors.fill: parent
                                visible: !block.isStatusBlock &&
                                         block.blockId !== "checklist" &&
                                         block.blockId !== "battery" &&
                                         block.blockId !== "flightMode" &&
                                         block.blockId !== "telemetry" &&
                                         block.blockId !== "rcSignal" &&
                                         block.blockId !== "disconnect"
                                source: block.icon
                                fillMode: Image.PreserveAspectFit
                                cache: false
                                asynchronous: false
                            }

                            QGCColoredImage {
                                anchors.fill: parent
                                visible: block.isStatusBlock
                                source: block.icon
                                fillMode: Image.PreserveAspectFit
                                color: block.iconColor
                            }
                        }

                        Text {
                            text: block.label
                            color: "white"
                            font.pixelSize: topStatusPanel._labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            verticalAlignment: Text.AlignVCenter
                            Layout.maximumWidth: Math.max(60, parent.width - topStatusPanel._iconSize - (topStatusPanel._inBlockPad * 2))
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                        font.pixelSize: topStatusPanel._valueFontPx
                        color: "white"

                        text: {
                            if (block.battery) return topStatusPanel.safeBatteryValueText(block.battery)
                            if (block.valueText && block.valueText.length > 0) return block.valueText
                            return "n/a"
                        }
                    }
                }
            }
        }
    }

    Flickable {
        id: statusFlick
        anchors.left: parent.left
        anchors.right: windowControls.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        anchors.leftMargin: topStatusPanel._hMargin
        anchors.rightMargin: topStatusPanel._hMargin
        anchors.topMargin: topStatusPanel._vMargin
        anchors.bottomMargin: topStatusPanel._vMargin + topStatusPanel._progressH + 2

        clip: true
        flickableDirection: Flickable.HorizontalFlick
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds

        contentWidth: statusRow.implicitWidth
        contentHeight: statusRow.height

        Row {
            id: statusRow
            height: statusFlick.height
            spacing: topStatusPanel._rowSpacing

            function addBlock(props) {
                var obj = statusBlockComponent.createObject(statusRow, props)
                if (!obj) {
                    console.warn("Status block create failed")
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
                    icon: Qt.binding(function () { return topStatusPanel.getDetailedIhaStatus().icon }),
                    blockId: "status",
                    label: Qt.binding(function () { return topStatusPanel.getDetailedIhaStatus().statusLabel }),
                    valueText: Qt.binding(function () { return topStatusPanel.getDetailedIhaStatus().text })
                })

                addBlock({
                    icon: _azIconBase + "Checklist.svg",
                    blockId: "checklist",
                    label: qsTr("Yoxlama Paneli"),
                    valueText: Qt.binding(function () {
                        var v = topStatusPanel._veh
                        if (!v) return qsTr("Yoxlama siyahısı")
                        return (v.checkListState === Vehicle.CheckListPassed) ? qsTr("Keçdi") : qsTr("Davam edir")
                    })
                })

                addBlock({
                    icon: _azIconBase + "FlightMode.svg",
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
                    icon: _azIconBase + "RCSignal.svg",
                    blockId: "rcSignal",
                    label: qsTr("RC Siqnalı"),
                    valueText: Qt.binding(function () { return topStatusPanel.rcValueText() })
                })

                addBlock({
                    icon: _azIconBase + "Telemetri.svg",
                    blockId: "telemetry",
                    label: qsTr("Telemetriya"),
                    valueText: Qt.binding(function () { return topStatusPanel.telemetryValueText() })
                })

                addBlock({
                    icon: Qt.binding(function () { return topStatusPanel.batterySvg() }),
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
                    icon: Qt.binding(function () { return topStatusPanel.gpsStatusIcon() }),
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
                    icon: _azIconBase + "FlightMode.svg",
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
                    icon: _azIconBase + "GPS.svg",
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

    // Horizontal scroll göstəricisi — düymələrin İÇİNDƏ deyil, ALTINDA ayrılmış zolaqda
    // yerləşir ki, buttonların üstünə düşməsin.
    ScrollBar {
        id: statusHScrollBar
        orientation: Qt.Horizontal
        policy: ScrollBar.AsNeeded

        anchors.left:      statusFlick.left
        anchors.right:     statusFlick.right
        anchors.top:       statusFlick.bottom
        anchors.topMargin: 1
        height: Math.max(4, topStatusPanel._progressH)

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

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        height: topStatusPanel._progressH
        width: _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color: QGroundControl.globalPalette.colorGreen
        visible: !_showLargeProgress
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

        active: topStatusPanel.flightModePopupVisible
        asynchronous: true
        source: _uiQrcBase + "TopStatusPanel_UcusRejimi.qml"

        onLoaded: {
            if (!item) return

            if (item.hasOwnProperty("anchorItem"))
                item.anchorItem = topStatusPanel.flightModePopupAnchorItem

            if (item.hasOwnProperty("topPanelItem"))
                item.topPanelItem = topStatusPanel

            if (item.hasOwnProperty("hostPanel"))
                item.hostPanel = topStatusPanel

            if (item.hasOwnProperty("statusPanel"))
                item.statusPanel = topStatusPanel

            item.statusPanel = topStatusPanel

            if (item.hasOwnProperty("reposition"))
                item.reposition()
        }
    }


    Loader {
        id: udpPanelLoader

        property var anchorItemRef: null

        // ÖNƏMLİ: anchors.fill YOX — panel öz ölçüsündə olsun
        parent: (_mw && _mw.contentItem) ? _mw.contentItem : topStatusPanel

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

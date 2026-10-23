




import QtQuick
import QtQml.Models
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    property var  _guidedController:  globals.guidedControllerFlyView
    property var  _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property var  _unitsConversion:   QGroundControl.unitsConversion
    property var  _flyViewSettings:   QGroundControl.settingsManager.flyViewSettings

    // Altitude
    property real _altStepAppUnits:   10.0
    property real currentAltitude:    _activeVehicle ? _activeVehicle.altitudeRelative.value : 0

    // Speed
    property real _speedStepAppUnits: 1.0
    property real currentSpeed:       _activeVehicle ? _activeVehicle.airSpeed.value : 0

    // Son verilən komandalar
    property real lastAppliedAltitude: 0
    property real lastAppliedSpeed:    0

    // Panellərin görünmə state-ləri
    property bool altPanelVisible:   false
    property bool speedPanelVisible: false

    // FlyViewActionFlyout.qml paneli düymənin yanında açmaq üçün
    property var changeAltActionRef:   changeAltAction
    property var changeSpeedActionRef: changeSpeedAction

    function parseUserFloat(str, fallback) {
        var s = ("" + str).trim()
        if (!s.length) return fallback
        s = s.replace(",", ".")
        var v = parseFloat(s)
        if (isNaN(v)) return fallback
        return v
    }

    function applyAltitudeTarget(targetAltApp) {
        if (!_guidedController || !_activeVehicle) return
        if (!_guidedController.showChangeAlt) return

        var currentAltApp = _activeVehicle.altitudeRelative.value
        var minAltApp = _flyViewSettings ? _flyViewSettings.guidedMinimumAltitude.value : currentAltApp - 1000
        var maxAltApp = _flyViewSettings ? _flyViewSettings.guidedMaximumAltitude.value : currentAltApp + 1000

        var newAltApp = targetAltApp
        if (newAltApp < minAltApp) newAltApp = minAltApp
        if (newAltApp > maxAltApp) newAltApp = maxAltApp

        var deltaApp = newAltApp - currentAltApp
        if (Math.abs(deltaApp) < 1e-3) return

        var deltaMeters = _unitsConversion ? _unitsConversion.appSettingsVerticalDistanceUnitsToMeters(deltaApp) : deltaApp
        lastAppliedAltitude = newAltApp
        _activeVehicle.guidedModeChangeAltitude(deltaMeters, false)
    }

    function applySpeedTarget(targetSpeedApp) {
        if (!_guidedController || !_activeVehicle) return
        if (!_guidedController.showChangeSpeed) return

        var currentSpeedApp = _activeVehicle.airSpeed.value
        var minSpeedApp = 0.5
        var maxSpeedApp = 50.0

        var newSpeedApp = targetSpeedApp
        if (newSpeedApp < minSpeedApp) newSpeedApp = minSpeedApp
        if (newSpeedApp > maxSpeedApp) newSpeedApp = maxSpeedApp
        if (Math.abs(newSpeedApp - currentSpeedApp) < 1e-3) return

        var speedMetersPerSecond = _unitsConversion
                                   ? _unitsConversion.appSettingsSpeedUnitsToMetersSecond(newSpeedApp)
                                   : newSpeedApp
        lastAppliedSpeed = newSpeedApp
        _activeVehicle.guidedModeChangeGroundSpeedMetersSecond(speedMetersPerSecond)
    }

    function applyHoldMode() {
        if (!_activeVehicle) return
        _activeVehicle.flightMode = "Hold"
    }

    readonly property string _iconBase: "qrc:/res/AZSHIELD_ICON/v2/"

    // The six commands of the design come first; the checklist and gripper only show
    // when they apply. `current` marks the command whose flight mode is active.
    model: [
        GuidedActionTakeoff {
            text:       qsTr("Qalxış")
            iconSource: _root._iconBase + "fly_takeoff.svg"
        },

        GuidedActionLand {
            property bool current: !!_root._activeVehicle && _root._activeVehicle.flightMode === _root._activeVehicle.landFlightMode
            text:       qsTr("Eniş")
            iconSource: _root._iconBase + "fly_land.svg"
        },

        GuidedActionRTL {
            property bool current: !!_root._activeVehicle && _root._activeVehicle.flightMode === _root._activeVehicle.rtlFlightMode
            text:       qsTr("Qayıt")
            iconSource: _root._iconBase + "fly_rtl.svg"
        },

        ToolStripAction {
            id: holdAction
            property bool current: !!_activeVehicle && (_activeVehicle.flightMode === "Hold" || _activeVehicle.flightMode === _activeVehicle.pauseFlightMode)
            text: qsTr("Hold")
            iconSource: _root._iconBase + "fly_hold.svg"
            enabled: _activeVehicle &&
                     _activeVehicle.armed &&
                     _activeVehicle.flying &&
                     (_activeVehicle.flightMode === "Guided" ||
                      _activeVehicle.flightMode === "Mission" ||
                      _activeVehicle.flightMode === "Position" ||
                      _activeVehicle.flightMode === "Altitude" ||
                      _activeVehicle.flightMode === "Stabilized" ||
                      _activeVehicle.flightMode === "Acro")
            onTriggered: applyHoldMode()
        },

        ToolStripAction {
            id: changeAltAction
            text: qsTr("Yüksəklik")
            iconSource: _root._iconBase + "fly_altitude.svg"
            onTriggered: {
                _root.altPanelVisible   = !_root.altPanelVisible
                _root.speedPanelVisible = false
            }
        },

        ToolStripAction {
            id: changeSpeedAction
            text: qsTr("Sürət")
            iconSource: _root._iconBase + "fly_speed.svg"
            onTriggered: {
                _root.speedPanelVisible = !_root.speedPanelVisible
                _root.altPanelVisible   = false
            }
        },

        PreFlightCheckListShowAction { onTriggered: _root.displayPreFlightChecklist() },

        GuidedActionGripper { }
    ]
}

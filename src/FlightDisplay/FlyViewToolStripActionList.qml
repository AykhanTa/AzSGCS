




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

    // FlyViewToolStrip.qml panelin yerini button-a görə hesablamaq üçün
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

    model: [
        ToolStripAction {
            id: view3DIcon
            property bool _viewer3DEnabled: QGroundControl.settingsManager.viewer3DSettings.enabled.rawValue
            property bool _is3DViewOpen:    viewer3DWindow && viewer3DWindow.isOpen

            visible:    _viewer3DEnabled
            text:       _is3DViewOpen ? qsTr("Fly") : qsTr("3D View")
            iconSource: _is3DViewOpen ? "/qml/images/PaperPlane.svg" : "/qml/QGroundControl/Viewer3D/City3DMapIcon.svg"

            onTriggered: {
                if (!viewer3DWindow) return
                if (_is3DViewOpen) viewer3DWindow.close()
                else viewer3DWindow.open()
            }
        },

        PreFlightCheckListShowAction { onTriggered: _root.displayPreFlightChecklist() },

        GuidedActionTakeoff { },
        GuidedActionLand   { },
        GuidedActionRTL    { },

        ToolStripAction {
            id: holdAction
            text: qsTr("Hold")
            iconSource: "qrc:/res/AZSHIELD_ICON/Hold.svg"
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
            text: qsTr("Altitude")
            iconSource: "qrc:/res/AZSHIELD_ICON/Altitude.svg"
            onTriggered: {
                _root.altPanelVisible   = !_root.altPanelVisible
                _root.speedPanelVisible = false
            }
        },

        ToolStripAction {
            id: changeSpeedAction
            text: qsTr("Speed")
            iconSource: "qrc:/res/AZSHIELD_ICON/Speed.svg"
            onTriggered: {
                _root.speedPanelVisible = !_root.speedPanelVisible
                _root.altPanelVisible   = false
            }
        },

        GuidedActionGripper { }
    ]
}

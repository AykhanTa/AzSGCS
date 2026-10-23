






















import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

Item {
    id: root

    // InstrumentPanel <-> Telemetry arası (istəsən saxla)
    property real spacing: ScreenTools.defaultFontPixelHeight * 0.45

    property bool showFlightPanel: mainWindow.showFlightPanel

    implicitWidth:  Math.max(_w(instrumentPanel), _w(telemetryBar))

    implicitHeight: _h(instrumentPanel)
                    + (_h(instrumentPanel) > 0 && telemetryBar.visible ? spacing : 0)
                    + _h(telemetryBar)

    width:  implicitWidth
    height: implicitHeight

    function _h(i) {
        if (!i || !i.visible) return 0
        return (i.height > 0) ? i.height : i.implicitHeight
    }
    function _w(i) {
        if (!i || !i.visible) return 0
        return (i.width > 0) ? i.width : i.implicitWidth
    }

    FlyViewInstrumentPanel {
        id: instrumentPanel
        anchors.top: parent.top
        anchors.right: parent.right
        visible: QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
    }

    TelemetryValuesBar {
        id: telemetryBar
        extraWidth: instrumentPanel.extraValuesWidth
        settingsGroup: factValueGrid.telemetryBarSettingsGroup
        specificVehicleForCard: null

        visible: showFlightPanel

        // No width here on purpose: the bar clamps itself against the font size
        // and adds the instrument panel's extraValuesWidth. Overriding it with a
        // fixed width threw both away, and the bar clips, so the values were cut
        // off rather than reported.

        anchors.right: parent.right
        anchors.rightMargin: 0

        anchors.top: instrumentPanel.visible ? instrumentPanel.bottom : parent.top
        anchors.topMargin: instrumentPanel.visible ? root.spacing : 0

        z: QGroundControl.zOrderWidgets + 1
    }
}

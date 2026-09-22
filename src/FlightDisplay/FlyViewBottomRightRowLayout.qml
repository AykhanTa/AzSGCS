






















import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

Item {
    id: root

    // InstrumentPanel <-> Telemetry arası (istəsən saxla)
    property real spacing: ScreenTools.defaultFontPixelHeight * 0.45

    // ✅ Telemetry <-> ToolStrip arası 0 olsun (bitşik)
    property real telemetryToolStripSpacing: 0

    property bool showFlightPanel: mainWindow.showFlightPanel
    property bool showRightToolStrip: true

    // Telemetry bar and tool strip share a right edge, so they share a width.
    // It is in font heights rather than pixels: the text inside them scales
    // with the font and a pixel constant does not, so the two only agreed at
    // one DPI. Used when the bar is hidden; otherwise the bar's own width wins.
    property real rightElementsWidth: ScreenTools.defaultFontPixelHeight * 17.4

    implicitWidth:  Math.max(_w(instrumentPanel), _w(telemetryBar), _w(toolStripRight))

    implicitHeight: _h(instrumentPanel)
                    + (_h(instrumentPanel) > 0 && telemetryBar.visible ? spacing : 0)
                    + _h(telemetryBar)
                    + (((_h(instrumentPanel) + _h(telemetryBar)) > 0) && toolStripRight.visible
                       ? (telemetryBar.visible ? telemetryToolStripSpacing : spacing)
                       : 0)
                    + _h(toolStripRight)

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

    FlyViewToolStrip {
        id: toolStripRight

        visible: showFlightPanel
                 && showRightToolStrip
                 && mainWindow.isFlyViewActive
                 && !QGroundControl.videoManager.fullScreen

        verticalMode: false

        // Follow the bar so the right edges line up, falling back to the shared
        // width when it is hidden. HorizontalToolStrip splits whatever height it
        // is given between two button rows while the labels scale with the font,
        // so this has to grow with the font or the labels outgrow the buttons.
        width: telemetryBar.visible ? telemetryBar.width : root.rightElementsWidth
        height: ScreenTools.defaultFontPixelHeight * 6.3

        anchors.right: parent.right
        anchors.rightMargin: 0

        anchors.top: telemetryBar.visible
                     ? telemetryBar.bottom
                     : (instrumentPanel.visible ? instrumentPanel.bottom : parent.top)

        // ✅ Telemetry görünürsə: bitşik
        anchors.topMargin: telemetryBar.visible
                           ? root.telemetryToolStripSpacing   // 0
                           : (instrumentPanel.visible ? root.spacing : 0)

        z: QGroundControl.zOrderWidgets + 1
    }
}

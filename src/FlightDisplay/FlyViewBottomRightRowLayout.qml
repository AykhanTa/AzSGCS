






















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

    // ✅ YENİ: Həm Telemetry, həm də ToolStrip üçün ortaq en ölçüsü.
    // 308-i 350 etdik. Ehtiyac olarsa, 380, 400 kimi artırıb-azalda bilərsiniz.
    property real rightElementsWidth: 330

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

        // ✅ DƏYİŞİKLİK: Eni yuxarıdakı ortaq dəyərə bağladıq
        width: root.rightElementsWidth

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

        // ✅ DƏYİŞİKLİK: 308 əvəzinə ortaq en ölçüsünü istifadə edirik
        width: root.rightElementsWidth
        height: 120

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


import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

/// Value of a telemetry value in the card style of the design ("0.0 m"): white Poppins,
/// or the value's range colour when it has one.
Text {
    property var    instrumentValueData:            null

    readonly property bool _hasColor: instrumentValueData.isValidColor(instrumentValueData.currentColor)

    Layout.fillWidth: true
    elide:            Text.ElideRight
    opacity:          instrumentValueData.currentOpacity
    color:            _hasColor ? instrumentValueData.currentColor : AzTheme.textCard
    font.family:      AzTheme.fontFamily
    font.pixelSize:   AzTheme.fontPx(14)
    text:             valueText()

    function valueText() {
        if (instrumentValueData.fact) {
            return instrumentValueData.fact.enumOrValueString + (instrumentValueData.showUnits ? " " + instrumentValueData.fact.units : "")
        } else {
            return qsTr("--.--")
        }
    }
}

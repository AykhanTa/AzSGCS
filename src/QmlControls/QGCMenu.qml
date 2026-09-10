import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

/// Kontekst menyusu — plan panelindəki açılan panellərlə eyni dizayndadır.
Menu {
    id: control

    padding: Math.max(4, ScreenTools.defaultFontPixelWidth * 0.4)

    property color panelColor:  "#2A2A2A"
    property color panelBorder: "#6E6E6E"

    background: Rectangle {
        implicitWidth:  Math.max(160, ScreenTools.defaultFontPixelWidth * 18)
        color:          control.panelColor
        radius:         10
        border.width:   1
        border.color:   control.panelBorder
    }
}

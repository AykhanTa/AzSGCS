import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls


RadioButton {
    id:             control
    font.family:    ScreenTools.normalFontFamily
    font.pointSize: ScreenTools.defaultFontPointSize

   // property color  textColor:  _qgcPal.text
    property color textColor: "white"
    property var    _qgcPal:    QGCPalette { colorGroupEnabled: enabled }
    property bool   _noText:    text === ""

    // Screens in the new design declare azInputStyle: a dark ring with a green dot
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    indicator: Rectangle {
        implicitWidth:          control._az ? AzTheme.px(20) : ScreenTools.radioButtonIndicatorSize
        implicitHeight:         width
        color:                  control._az ? AzTheme.pillBottom : "white"
        border.color:           control._az ? (control.checked ? AzTheme.statusGreen : AzTheme.cardHoverBorder) : "black"
        border.width:           control._az ? (control.checked ? 2 : 1) : 1
        radius:                 height / 2
        opacity:                control.enabled ? 1 : 0.5
        x:                      control.leftPadding
        y:                      parent.height / 2 - height / 2
        Rectangle {
            anchors.centerIn:   parent
            // Width should be an odd number to be centralized by the parent properly
            width:              2 * Math.floor(parent.width / 4) + 1
            height:             width
            antialiasing:       true
            radius:             height * 0.5
            color:              control._az ? AzTheme.statusGreen : "black"
            visible:            control.checked
        }
    }

    contentItem: Text {
        text:               control.text
        font.family:        control._az ? AzTheme.fontFamily : control.font.pointSize
        font.pointSize:     control.font.pointSize
        font.bold:          control.font.bold
        color:              control._az ? AzTheme.textCard : control.textColor
        opacity:            enabled ? 1.0 : 0.3
        verticalAlignment:  Text.AlignVCenter
        leftPadding:        control.indicator.width + (_noText ? 0 : ScreenTools.defaultFontPixelWidth * 0.25)
    }

}

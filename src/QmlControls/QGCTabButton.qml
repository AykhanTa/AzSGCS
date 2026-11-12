// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// import QtQuick
// import QtQuick.Controls

// import QGroundControl
// import QGroundControl.Controls




// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// // import QtQuick
// // import QtQuick.Controls

// // import QGroundControl
// // import QGroundControl.Controls




// import QtQuick
// import QtQuick.Controls

// import QGroundControl
// import QGroundControl.Controls


/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls


TabButton {
    id:             control
    topPadding:     _verticalPadding
    bottomPadding:  _verticalPadding
    leftPadding:    _horizontalPadding
    rightPadding:   _horizontalPadding
    focusPolicy:    Qt.ClickFocus
    //implicitWidth:  Math.max(implicitBackgroundWidth + leftInset + rightInset, implicitContentWidth + leftPadding + rightPadding)
    //implicitHeight:     Math.max(implicitBackgroundHeight + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding)

    property bool   primary:        false                               ///< primary button for a group of buttons
    property real   pointSize:      ScreenTools.defaultFontPointSize    ///< Point size for button text
    property bool   showBorder:     qgcPal.globalTheme === QGCPalette.Light
    property real   backRadius:     ScreenTools.buttonBorderRadius
    property real   heightFactor:   0.5

    property bool   _showHighlight:     enabled && (pressed | checked)
    property int    _horizontalPadding: ScreenTools.defaultFontPixelWidth
    property int    _verticalPadding:   Math.round(ScreenTools.defaultFontPixelHeight * heightFactor)
    property bool   _showIcon:          control.icon.source != ""

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    // Screens in the new design declare azInputStyle (see QGCLabel._az).
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    background: Rectangle {
        id:             backRect
        implicitWidth:  ScreenTools.implicitButtonWidth
        implicitHeight: control._az ? AzTheme.px(36) : ScreenTools.implicitButtonHeight
        radius:         control._az ? AzTheme.px(AzTheme.menuSelectedRadius) : 0
        border.width:   control._az ? (control.checked ? 1 : 0) : (showBorder ? 1 : 0)
        border.color:   control._az ? AzTheme.menuSelectedBorder : qgcPal.buttonBorder
        color:          control._az ? (control.hovered && !control.checked ? Qt.rgba(1, 1, 1, 0.04) : "transparent")
                                    : "#3D3B3B"//_showHighlight ? qgcPal.buttonHighlight : qgcPal.button
        gradient:       (control._az && control.checked) ? selectedGradient : null

        Gradient {
            id: selectedGradient
            GradientStop { position: 0; color: AzTheme.menuSelectedTop }
            GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
        }
    }

    contentItem: Item {
        implicitWidth:  _showIcon ? icon.width : text.implicitWidth
        implicitHeight: _showIcon ? icon.height : text.implicitHeight
        baselineOffset: text.y + text.baselineOffset

        QGCColoredImage {
            id:                     icon
            anchors.centerIn:       parent
            source:                 control.icon.source
            height:                 source === "" ? 0 : ScreenTools.defaultFontPixelHeight
            width:                  height
            color:                  control._az ? (control.checked ? AzTheme.textPrimary : AzTheme.textSecondary)
                                                : (_showHighlight ? qgcPal.buttonHighlightText : qgcPal.buttonText)
            fillMode:               Image.PreserveAspectFit
            sourceSize.height:      height
            visible:                _showIcon
        }

        Text {
            id:                     text
            anchors.centerIn:       parent
            antialiasing:           true
            text:                   control.text
            font.pointSize:         control._az ? -1 : 14//control.pointSize
            font.pixelSize:         control._az ? AzTheme.fontPx(14) : -1
            font.family:            control._az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
            font.weight:            (control._az && control.checked) ? Font.Medium : Font.Normal
            color:                  control._az ? (control.checked ? AzTheme.textPrimary : AzTheme.textSecondary)
                                                : (_showHighlight ? "#7DFF03" : qgcPal.buttonText)
            visible:                !_showIcon
        }
    }
}

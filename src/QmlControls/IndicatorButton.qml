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



/// Works just like a regular button but it can have a red indicator on the right side displayed
QGCButton {

    property bool indicatorGreen: false ///< true: no indicator shown, false: red indicator shown
    // In the new design (azInputStyle) the button keeps its panel look and the
    // indicator is the design's red status dot.
    backgroundColor: _az ? AzTheme.buttonBottom : "black"

    Rectangle {
        anchors.rightMargin:    _az ? AzTheme.px(10) : ScreenTools.defaultFontPixelWidth / 3
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        width:                  radius * 2
        height:                 width
        radius:                 _az ? AzTheme.px(4) : (ScreenTools.defaultFontPixelHeight * .75) / 2
        color:                  _az ? AzTheme.statusRed : "red"
        visible:                enabled && !indicatorGreen
    }
}

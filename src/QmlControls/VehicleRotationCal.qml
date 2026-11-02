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


Rectangle {
    // Indicates whether calibration is valid for this control
    property bool calValid: false

    // Indicates whether the control is currently being calibrated
    property bool calInProgress: false

    // Text to show while calibration is in progress
    property string calInProgressText: qsTr("Hold Still")

    // Image source
    property var imageSource: ""

    property var __qgcPal: QGCPalette { colorGroupEnabled: enabled }

    // Screens in the new design declare azInputStyle: a status card outlined in the
    // step's colour (orange in progress, green done, red to do) with a status label.
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true
    readonly property color _azStateColor: calInProgress ? AzTheme.statusOrange : (calValid ? AzTheme.statusGreen : AzTheme.statusRed)

    color:  _az ? _azStateColor : (calInProgress ? "yellow" : (calValid ? "green" : "red"))
    radius: _az ? AzTheme.px(12) : 0

    Rectangle {
        readonly property int inset: _az ? 2 : 5

        x:      inset
        y:      inset
        width:  parent.width - (inset * 2)
        height: parent.height - (inset * 2)
        radius: _az ? AzTheme.px(10) : 0
        color:  _az ? AzTheme.cardGradientEnd : qgcPal.windowShade

        Image {
            width:      parent.width
            height:     parent.height
            source:     imageSource
            fillMode:   Image.PreserveAspectFit
            smooth: true
        }

        QGCLabel {
            width:                  parent.width
            height:                 parent.height
            horizontalAlignment:    Text.AlignHCenter
            verticalAlignment:      Text.AlignBottom
            bottomPadding:          _az ? AzTheme.px(8) : 0
            font.pointSize:         ScreenTools.mediumFontPointSize
            color:                  _az ? _azStateColor : qgcPal.text
            text:                   calInProgress ? calInProgressText : (calValid ? qsTr("Tamamlandı") : qsTr("Tamamlanmayıb"))
        }
    }
}

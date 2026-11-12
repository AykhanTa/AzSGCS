import QtQuick
import QtQuick.Controls

import QGroundControl

import QGroundControl.Controls


TabBar {
    id: control

    // Screens in the new design declare azInputStyle (see QGCLabel._az).
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    // A pill container in the new design; the tabs take the side menu's selected box.
    leftPadding:    _az ? AzTheme.px(4) : 0
    rightPadding:   _az ? AzTheme.px(4) : 0
    topPadding:     _az ? AzTheme.px(4) : 0
    bottomPadding:  _az ? AzTheme.px(4) : 0
    spacing:        _az ? AzTheme.px(4) : 1

    background: Rectangle {
        color:          control._az ? AzTheme.pillBottom : qgcPal.window
        radius:         control._az ? AzTheme.px(10) : 0
        border.width:   control._az ? 1 : 0
        border.color:   AzTheme.groupBorder
    }
}

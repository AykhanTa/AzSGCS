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
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls


AbstractButton   {
    id:             control
    checkable:      true
    padding:        0

    property bool   _showBorder: qgcPal.globalTheme === QGCPalette.Light

    // Screens in the new design declare azInputStyle: AzSwitch's look, green when on.
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

    contentItem: Item {
        implicitWidth:  (label.visible ? label.contentWidth + ScreenTools.defaultFontPixelWidth : 0) + indicator.width 
        // The new design's switch is taller than a text line, so stacked rows must not overlap.
        implicitHeight: Math.max(label.contentHeight, indicator.height)

        QGCLabel { 
            id:             label
            anchors.left:   parent.left
            text:           visible ? control.text : "X"
            visible:        control.text !== ""
        }
    
        Rectangle {
            id:                     indicator
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            height:                 control._az ? AzTheme.px(24) : ScreenTools.defaultFontPixelHeight
            width:                  control._az ? AzTheme.px(44) : height * 2
            radius:                 height / 2
            color:                  control._az ? (control.checked ? AzTheme.statusGreen : AzTheme.pillBottom)
                                                : (control.checked ? qgcPal.primaryButton : qgcPal.button)
            border.width:           (control._az || _showBorder) ? 1 : 0
            border.color:           control._az ? (control.checked ? AzTheme.statusGreen : AzTheme.groupBorder) : qgcPal.buttonBorder
            opacity:                (control._az && !control.enabled) ? 0.45 : 1

            Rectangle {
                readonly property real _inset: control._az ? AzTheme.px(3) : 1

                anchors.verticalCenter: parent.verticalCenter
                x:                      checked ? indicator.width - width - _inset : _inset
                height:                 parent.height - 2 * _inset
                width:                  height
                radius:                 height / 2
                color:                  control._az ? AzTheme.textCard : qgcPal.buttonText

                Behavior on x { enabled: control._az; NumberAnimation { duration: 150 } }
            }
        }
    }
}

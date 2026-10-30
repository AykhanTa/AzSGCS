import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls

// The Plan view's tool strip, on the collapsed side menu of the fly view: 80 px wide,
// the 155deg panel gradient with a 1 px right border and its shadow on the map.
Item {
    id:     _root
    width:  AzTheme.px(80)

    property alias  model:  repeater.model

    property var _dropPanel: dropPanel

    function simulateClick(buttonIndex) {
        var button = repeater.itemAt(buttonIndex) as ToolStripHoverButton
        if (!button) {
            return
        }
        if (button.checkable) {
            button.checked = !button.checked
        }
        button.clicked()
    }

    signal dropped(int index)

    readonly property real _sideMargin: AzTheme.px(8)

    // 64 is the height a tool wants. When the strip cannot fit them all they share out
    // what there is instead, down to a floor that still takes a touch: the strip does
    // scroll, but a tool below the fold reads as missing, and on the Plan view that hid
    // the button for reopening the bottom panel.
    readonly property real _buttonHeight: {
        var count = 0
        for (var i = 0; i < repeater.count; i++) {
            var button = repeater.itemAt(i)
            if (button && button.visible) {
                count++
            }
        }
        if (count <= 0) {
            return AzTheme.px(64)
        }
        var room = flickable.height - (toolStripColumn.spacing * (count - 1))
        return Math.max(ScreenTools.minTouchPixels * 1.2, Math.min(AzTheme.px(64), room / count))
    }

    RectangularShadow {
        anchors.fill: stripBackground
        offset.x:     AzTheme.px(12)
        blur:         AzTheme.px(35)
        color:        AzTheme.panelShadow
    }

    AzGradientRect {
        id:            stripBackground
        anchors.fill:  parent
        angle:         AzTheme.panelGradientAngle
        startColor:    AzTheme.panelGradientStart
        startPosition: AzTheme.panelGradientStartPos
        endColor:      AzTheme.panelGradientEnd
        endPosition:   AzTheme.panelGradientEndPos
    }

    Rectangle {
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        width:          1
        color:          AzTheme.panelBorder
    }

    DeadMouseArea {
        anchors.fill: parent
    }

    QGCFlickable {
        id:                 flickable
        anchors.fill:       parent
        anchors.topMargin:  AzTheme.px(12)
        anchors.bottomMargin: AzTheme.px(12)
        contentHeight:      toolStripColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        Column {
            id:      toolStripColumn
            x:       _root._sideMargin
            width:   flickable.width - (2 * _root._sideMargin)
            spacing: AzTheme.px(6)

            Repeater {
                id: repeater

                ToolStripHoverButton {
                    id:                 buttonTemplate
                    width:              toolStripColumn.width
                    height:             _root._buttonHeight
                    toolStripAction:    modelData
                    dropPanel:          _root._dropPanel
                    onDropped: (index) => _root.dropped(index)

                    onCheckedChanged: {
                        // We deal with exclusive check state manually since usinug autoExclusive caused all sorts of crazt problems
                        if (checked) {
                            for (var i=0; i<repeater.count; i++) {
                                if (i != index) {
                                    var button = repeater.itemAt(i)
                                    if (button && button.checked) {
                                        button.checked = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ToolStripDropPanel {
        id:         dropPanel
        toolStrip:  _root
    }
}

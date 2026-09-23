import QtQuick
import QtQuick.Controls

import QGroundControl


import QGroundControl.Controls

Rectangle {
    id:         _root
    color:      qgcPal.toolbarBackground
    width:      70
    height:     956
    radius:     ScreenTools.defaultFontPixelWidth / 2

    Rectangle {
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            width: 2
            color: "black"
        }


    property alias  model:              repeater.model
    property real   maxHeight           ///< Maximum height for control, determines whether text is hidden to make control shorter
    property alias  title:              titleLabel.text
    property var    fontSize:           ScreenTools.smallFontPointSize

    property var _dropPanel: dropPanel

    function simulateClick(buttonIndex) {
        buttonIndex = buttonIndex + 1 // skip over title label
        var button = toolStripColumn.children[buttonIndex]
        if (button.checkable) {
            button.checked = !button.checked
        }
        button.clicked()
    }

    signal dropped(int index)

    // 80 is the height a button wants. When the strip cannot fit them all they
    // share out what there is instead, down to a floor that still takes a touch:
    // the strip does scroll, but an action below the fold reads as missing, and
    // on the Plan view that hid the button for reopening the bottom panel.
    readonly property real _buttonHeight: {
        var count = repeater.count
        if (count <= 0) {
            return 80
        }
        var room = flickable.height - (titleLabel.visible ? titleLabel.height : 0)
                   - (toolStripColumn.spacing * count)
        return Math.max(ScreenTools.minTouchPixels * 1.6, Math.min(80, room / count))
    }

    DeadMouseArea {
        anchors.fill: parent
    }

    QGCFlickable {
        id:                 flickable
        anchors.margins:    ScreenTools.defaultFontPixelWidth * 0.4
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right
        height:             parent.height - anchors.margins * 2
        contentHeight:      toolStripColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        Column {
            id:             toolStripColumn
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelWidth * 0.25

            QGCLabel {
                id:                     titleLabel
                anchors.left:           parent.left
                anchors.right:          parent.right
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.mediumFontPointSize
                visible:                title != ""
            }

            Repeater {
                id: repeater

                ToolStripHoverButton {
                    id:                 buttonTemplate
                    anchors.left:       toolStripColumn.left
                    anchors.right:      toolStripColumn.right
                    height:             _root._buttonHeight
                    radius:             ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:      _root.fontSize
                    toolStripAction:    modelData
                    dropPanel:          _dropPanel
                    onDropped: (index) => _root.dropped(index)

                    onCheckedChanged: {
                        // We deal with exclusive check state manually since usinug autoExclusive caused all sorts of crazt problems
                        if (checked) {
                            for (var i=0; i<repeater.count; i++) {
                                if (i != index) {
                                    var button = repeater.itemAt(i)
                                    if (button.checked) {
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



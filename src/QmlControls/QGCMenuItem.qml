import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

MenuItem {
    id: control

    // MenuItem doesn't support !visible so we have to hack it in
    height: visible ? implicitHeight : 0

    implicitHeight: Math.max(32, ScreenTools.defaultFontPixelHeight * 1.8)
    padding:        0

    property color accentColor: "#00C853"

    readonly property real _pad: Math.max(8, ScreenTools.defaultFontPixelWidth * 0.9)

    HoverHandler { id: menuItemHover; enabled: control.enabled }

    background: Rectangle {
        radius: 8
        color: control.down ? "#565454"
                            : ((control.enabled && (menuItemHover.hovered || control.highlighted)) ? "#3A3A3A" : "transparent")
        opacity: control.enabled ? 1.0 : 0.45

        Behavior on color { ColorAnimation { duration: 110 } }

        Rectangle {
            anchors.left:           parent.left
            anchors.leftMargin:     2
            anchors.verticalCenter: parent.verticalCenter
            width:                  3
            height:                 parent.height * 0.55
            radius:                 1.5
            color:                  control.accentColor
            visible:                control.enabled && (menuItemHover.hovered || control.highlighted || control.down)
        }
    }

    contentItem: QGCLabel {
        text:                control.text
        color:               "#FFFFFF"
        font.pointSize:      ScreenTools.defaultFontPointSize
        verticalAlignment:   Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        leftPadding:         control._pad
        rightPadding:        control._pad
        opacity:             control.enabled ? 1.0 : 0.6
    }
}

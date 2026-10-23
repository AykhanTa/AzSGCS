import QtQuick

import QGroundControl.Controls

// A bare icon with a round hover/press tint, as the ✕ and gear in a panel header.
Item {
    id: control

    property string iconSource
    property real   iconSize:  AzTheme.px(20)
    property color  iconColor: AzTheme.textCard

    signal clicked()

    implicitWidth:  Math.max(AzTheme.px(32), iconSize + AzTheme.px(12))
    implicitHeight: implicitWidth

    Rectangle {
        anchors.fill: parent
        radius:       width / 2
        color:        Qt.rgba(1, 1, 1, mouseArea.pressed ? 0.12 : 0.06)
        visible:      mouseArea.containsMouse || mouseArea.pressed
    }

    QGCColoredImage {
        anchors.centerIn:  parent
        width:             control.iconSize
        height:            width
        sourceSize.height: height
        fillMode:          Image.PreserveAspectFit
        source:            control.iconSource
        color:             control.enabled ? control.iconColor : AzTheme.mutedText
    }

    MouseArea {
        id:           mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    control.clicked()
    }
}

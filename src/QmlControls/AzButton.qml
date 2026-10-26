import QtQuick

import QGroundControl.Controls

// The panel button of the mock-ups ("ARM"): radius 8, a dark vertical gradient with a
// 1 px border. `danger` is the bright red variant of the ammunition panel's "At" button,
// used for DISARM, Stop and the like. An optional icon sits left of the text.
Item {
    id: control

    property string text
    property string iconSource
    property bool   danger: false
    property real   minimumWidth: AzTheme.px(90)
    property real   textSize:     AzTheme.popupTextSize

    signal clicked()

    implicitWidth:  Math.max(minimumWidth, content.implicitWidth + AzTheme.px(32))
    implicitHeight: AzTheme.px(AzTheme.buttonHeight)
    opacity:        enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius:       AzTheme.px(8)
        border.width: 1
        border.color: mouseArea.containsMouse && control.enabled
                      ? (control.danger ? AzTheme.dangerHoverBorder : AzTheme.cardHoverBorder)
                      : (control.danger ? AzTheme.dangerBorder : AzTheme.buttonBorder)
        gradient: Gradient {
            GradientStop { position: 0; color: control.danger ? AzTheme.dangerTop : AzTheme.buttonTop }
            GradientStop { position: 1; color: control.danger ? AzTheme.dangerBottom : AzTheme.buttonBottom }
        }

        Rectangle {
            anchors.fill:    parent
            radius:          parent.radius
            color:           control.danger ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.06)
            visible:         mouseArea.pressed
        }
    }

    Row {
        id:               content
        anchors.centerIn: parent
        spacing:          AzTheme.px(10)

        QGCColoredImage {
            anchors.verticalCenter: parent.verticalCenter
            width:                  visible ? Math.round(label.font.pixelSize * 1.15) : 0
            height:                 width
            sourceSize.height:      height
            fillMode:               Image.PreserveAspectFit
            source:                 control.iconSource
            color:                  AzTheme.textPrimary
            visible:                control.iconSource !== ""
        }

        Text {
            id:                     label
            anchors.verticalCenter: parent.verticalCenter
            text:                   control.text
            color:                  control.danger ? AzTheme.textPrimary : AzTheme.textCard
            font.family:            AzTheme.fontFamily
            font.weight:            Font.Medium
            font.pixelSize:         AzTheme.fontPx(control.textSize)
        }
    }

    MouseArea {
        id:           mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked:    control.clicked()
    }
}

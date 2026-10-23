import QtQuick

// The panel button of the mock-ups ("ARM"): 40 px, radius 8, a dark vertical gradient
// with a 1 px border. `danger` is the red variant for DISARM, Stop and the like.
Item {
    id: control

    property string text
    property bool   danger: false
    property real   minimumWidth: AzTheme.px(90)

    signal clicked()

    implicitWidth:  Math.max(minimumWidth, label.implicitWidth + AzTheme.px(32))
    implicitHeight: AzTheme.px(AzTheme.buttonHeight)
    opacity:        enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius:       AzTheme.px(8)
        border.width: 1
        border.color: mouseArea.containsMouse && control.enabled
                      ? (control.danger ? AzTheme.statusRed : AzTheme.cardHoverBorder)
                      : (control.danger ? AzTheme.dangerBorder : AzTheme.buttonBorder)
        gradient: Gradient {
            GradientStop { position: 0; color: control.danger ? AzTheme.dangerTop : AzTheme.buttonTop }
            GradientStop { position: 1; color: control.danger ? AzTheme.dangerBottom : AzTheme.buttonBottom }
        }

        Rectangle {
            anchors.fill:    parent
            radius:          parent.radius
            color:           Qt.rgba(1, 1, 1, 0.06)
            visible:         mouseArea.pressed
        }
    }

    Text {
        id:               label
        anchors.centerIn: parent
        text:             control.text
        color:            AzTheme.textCard
        font.family:      AzTheme.fontFamily
        font.weight:      Font.Medium
        font.pixelSize:   AzTheme.fontPx(AzTheme.popupTextSize)
    }

    MouseArea {
        id:           mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked:    control.clicked()
    }
}

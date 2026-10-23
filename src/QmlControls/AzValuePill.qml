import QtQuick

// The value box on the right of a panel row: 116x36, radius 8, a dark gradient with
// a 1 px border. It grows for a longer value.
Item {
    id: control

    property string text
    property color  textColor: AzTheme.textCard

    implicitWidth:  Math.max(AzTheme.px(AzTheme.pillWidth), label.implicitWidth + AzTheme.px(20))
    implicitHeight: AzTheme.px(AzTheme.pillHeight)

    Rectangle {
        anchors.fill: parent
        radius:       AzTheme.px(8)
        border.width: 1
        border.color: AzTheme.groupBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.pillTop }
            GradientStop { position: 1; color: AzTheme.pillBottom }
        }
    }

    Text {
        id:                  label
        anchors.centerIn:    parent
        width:               Math.min(implicitWidth, control.width - AzTheme.px(12))
        horizontalAlignment: Text.AlignHCenter
        elide:               Text.ElideRight
        text:                control.text
        color:               control.textColor
        font.family:         AzTheme.fontFamily
        font.pixelSize:      AzTheme.fontPx(AzTheme.popupTextSize)
    }
}

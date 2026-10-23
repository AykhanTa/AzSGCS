import QtQuick

// One row of an AzGroup table: the name on the left, the value in a pill on the right.
Item {
    id: control

    property string label
    property string value
    property color  valueColor: AzTheme.textCard

    width:          parent ? parent.width : implicitWidth
    implicitHeight: AzTheme.px(AzTheme.groupRowHeight)

    Text {
        anchors.left:           parent.left
        anchors.leftMargin:     AzTheme.px(AzTheme.groupPadding)
        anchors.right:          pill.left
        anchors.rightMargin:    AzTheme.px(12)
        anchors.verticalCenter: parent.verticalCenter
        elide:                  Text.ElideRight
        text:                   control.label
        color:                  AzTheme.textCard
        font.family:            AzTheme.fontFamily
        font.weight:            Font.Medium
        font.pixelSize:         AzTheme.fontPx(AzTheme.popupTextSize)
    }

    AzValuePill {
        id:                     pill
        anchors.right:          parent.right
        anchors.rightMargin:    AzTheme.px(AzTheme.groupPadding)
        anchors.verticalCenter: parent.verticalCenter
        width:                  Math.min(implicitWidth, control.width * 0.55)
        text:                   control.value
        textColor:              control.valueColor
    }
}

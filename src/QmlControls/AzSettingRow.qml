import QtQuick

// A settings row inside an AzGroup: the name on the left, a control on the right.
Item {
    id: control

    property string label
    property real   controlWidth: Math.min(AzTheme.px(220), width * 0.45)
    default property alias content: controlSlot.data

    width:          parent ? parent.width : implicitWidth
    implicitHeight: AzTheme.px(AzTheme.groupRowHeight)

    Text {
        anchors.left:           parent.left
        anchors.leftMargin:     AzTheme.px(AzTheme.groupPadding)
        anchors.right:          controlSlot.left
        anchors.rightMargin:    AzTheme.px(12)
        anchors.verticalCenter: parent.verticalCenter
        elide:                  Text.ElideRight
        text:                   control.label
        color:                  AzTheme.textCard
        font.family:            AzTheme.fontFamily
        font.weight:            Font.Medium
        font.pixelSize:         AzTheme.fontPx(AzTheme.popupTextSize)
    }

    Item {
        id:                     controlSlot
        anchors.right:          parent.right
        anchors.rightMargin:    AzTheme.px(AzTheme.groupPadding)
        anchors.verticalCenter: parent.verticalCenter
        width:                  control.controlWidth
        height:                 AzTheme.px(AzTheme.pillHeight)
    }
}

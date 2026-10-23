import QtQuick

// An on/off switch for panel rows. It only reports clicks; the owner flips `checked`.
Item {
    id: control

    property bool checked: false

    signal clicked()

    implicitWidth:  AzTheme.px(44)
    implicitHeight: AzTheme.px(24)
    opacity:        enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius:       height / 2
        color:        control.checked ? AzTheme.statusGreen : AzTheme.pillBottom
        border.width: 1
        border.color: control.checked ? AzTheme.statusGreen : AzTheme.groupBorder

        Rectangle {
            width:                  parent.height - AzTheme.px(6)
            height:                 width
            radius:                 width / 2
            anchors.verticalCenter: parent.verticalCenter
            x:                      control.checked ? parent.width - width - AzTheme.px(3) : AzTheme.px(3)
            color:                  AzTheme.textCard

            Behavior on x { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    control.clicked()
    }
}

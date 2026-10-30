import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

/// A row of the Plan view's drop-down menus (a mission item's hamburger), as the top
/// bar's window menu draws them: left-aligned text, a faint tint on hover and the side
/// menu's selected box while pressed.
Button {
    id: control

    focusPolicy: Qt.ClickFocus
    padding:     0

    implicitHeight: AzTheme.px(38)
    implicitWidth:  Math.max(AzTheme.px(260), contentItem.implicitWidth)
    opacity:        enabled ? 1.0 : 0.45

    readonly property real _pad: AzTheme.px(12)

    HoverHandler { id: hoverHandler; enabled: control.enabled }

    background: Item {
        Rectangle {
            anchors.fill: parent
            visible:      control.down
            radius:       AzTheme.px(AzTheme.menuSelectedRadius)
            border.width: 1
            border.color: AzTheme.menuSelectedBorder
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible:      !control.down && hoverHandler.hovered
            radius:       AzTheme.px(AzTheme.menuSelectedRadius)
            color:        Qt.rgba(1, 1, 1, 0.06)
        }
    }

    contentItem: Text {
        text:                control.text
        color:               AzTheme.textCard
        font.family:         AzTheme.fontFamily
        font.pixelSize:      AzTheme.fontPx(AzTheme.popupTextSize)
        verticalAlignment:   Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        leftPadding:         control._pad
        rightPadding:        control._pad
        elide:               Text.ElideRight
    }
}

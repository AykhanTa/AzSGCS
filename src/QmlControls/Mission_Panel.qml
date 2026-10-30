import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

/// A segment of the Plan view's layer selector (Missiya / Fence / Ralli). The active one
/// is the side menu's selected box with white text; the others are flat, their text
/// grey, a faint tint on hover.
TabButton {
    id: control

    focusPolicy: Qt.ClickFocus

    readonly property bool _active: checked

    padding:        0
    leftPadding:    AzTheme.px(10)
    rightPadding:   AzTheme.px(10)
    implicitHeight: AzTheme.px(36)
    opacity:        enabled ? 1.0 : 0.45

    HoverHandler { id: hoverHandler; enabled: control.enabled }

    // linear-gradient(180deg, #30353A, #202428), 1 px #5D646B, radius 8
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible:      control._active
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
            visible:      !control._active && hoverHandler.hovered
            radius:       AzTheme.px(AzTheme.menuSelectedRadius)
            color:        Qt.rgba(1, 1, 1, 0.05)
        }
    }

    contentItem: Text {
        text:                control.text
        color:               control._active ? AzTheme.textPrimary
                                             : (hoverHandler.hovered ? AzTheme.textCard : AzTheme.textSecondary)
        font.family:         AzTheme.fontFamily
        font.weight:         Font.Medium
        font.pixelSize:      AzTheme.fontPx(14)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment:   Text.AlignVCenter
        elide:               Text.ElideRight
    }
}

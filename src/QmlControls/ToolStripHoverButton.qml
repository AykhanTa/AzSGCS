import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

// A tool of the Plan view's strip: the icon over its name, on the side menu's item
// style. A checked tool (its panel open, or Waypoint waiting for a map click) gets the
// side menu's selected box, hover its faint outline. An orange dot on the icon marks
// an action that has something pending (the plan's unsaved changes on "Fayl").
Button {
    id:             control
    padding:        0
    hoverEnabled:   !ScreenTools.isMobile
    enabled:        toolStripAction ? toolStripAction.enabled : true
    visible:        toolStripAction ? toolStripAction.visible : true
    imageSource:    toolStripAction ? (toolStripAction.showAlternateIcon ? toolStripAction.alternateIconSource : toolStripAction.iconSource) : ""
    text:           toolStripAction ? toolStripAction.text : ""
    checked:        toolStripAction ? toolStripAction.checked : false
    checkable:      toolStripAction ? (!!toolStripAction.dropPanelComponent || toolStripAction.checkable) : false
    opacity:        enabled ? 1 : 0.35

    property var    toolStripAction:    undefined
    property var    dropPanel:          undefined
    property real   radius:             AzTheme.px(AzTheme.menuSelectedRadius)
    property string imageSource
    property real   iconSize:           AzTheme.px(24)

    readonly property bool _highlighted: checked || pressed
    readonly property bool _pending:     !!toolStripAction && toolStripAction.showAlternateIcon

    signal dropped(int index)

    onCheckedChanged: {
        if (toolStripAction) {
            toolStripAction.checked = checked
        }
    }

    onClicked: {
        if (mainWindow.allowViewSwitch()) {
            dropPanel.hide()
            if (!toolStripAction.dropPanelComponent) {
                toolStripAction.triggered(this)
            } else if (checked) {
                var panelEdgeTopPoint = mapToItem(dropPanel.toolStrip, width, 0)
                dropPanel.show(panelEdgeTopPoint, toolStripAction.dropPanelComponent, this)
                checked = true
                control.dropped(index)
            }
        } else if (checkable) {
            checked = !checked
        }
    }

    contentItem: Item {
        Column {
            anchors.centerIn: parent
            width:            parent.width - AzTheme.px(6)
            spacing:          AzTheme.px(5)

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width:                    control.iconSize
                height:                   control.iconSize

                Image {
                    anchors.fill:      parent
                    sourceSize.width:  width
                    sourceSize.height: height
                    fillMode:          Image.PreserveAspectFit
                    mipmap:            true
                    source:            control.imageSource
                    visible:           source != "" && !!control.toolStripAction && control.toolStripAction.fullColorIcon
                }

                QGCColoredImage {
                    anchors.fill:      parent
                    sourceSize.height: height
                    fillMode:          Image.PreserveAspectFit
                    source:            control.imageSource
                    color:             control._highlighted ? AzTheme.textPrimary : AzTheme.textCard
                    visible:           source != "" && !(control.toolStripAction && control.toolStripAction.fullColorIcon)
                }

                Rectangle {
                    anchors.horizontalCenter: parent.right
                    anchors.verticalCenter:   parent.top
                    width:                    Math.max(6, AzTheme.px(8))
                    height:                   width
                    radius:                   width / 2
                    color:                    AzTheme.statusOrange
                    visible:                  control._pending
                }
            }

            Text {
                width:               parent.width
                text:                control.text
                visible:             text !== ""
                color:               control._highlighted ? AzTheme.textPrimary : AzTheme.textCard
                font.family:         AzTheme.fontFamily
                font.pixelSize:      AzTheme.fontPx(11)
                horizontalAlignment: Text.AlignHCenter
                wrapMode:            Text.WordWrap
                maximumLineCount:    2
                elide:               Text.ElideRight
                lineHeight:          0.9
            }
        }
    }

    // linear-gradient(180deg, #30353A, #202428), 1 px #5D646B, radius 8
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible:      control._highlighted
            radius:       control.radius
            border.width: 1
            border.color: AzTheme.menuSelectedBorder
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible:      !control._highlighted && control.hovered && control.enabled
            radius:       control.radius
            color:        Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: AzTheme.panelBorder
        }
    }
}

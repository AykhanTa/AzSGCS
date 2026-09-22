// import QtQuick
// import QtQuick.Controls

// import QGroundControl
// import QGroundControl.Controls




import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

Button {
    id:             control
    width:          contentLayoutItem.contentWidth + (contentMargins * 2)
    height:         width
    hoverEnabled:   !ScreenTools.isMobile
    enabled:        toolStripAction.enabled
    visible:        toolStripAction.visible
    imageSource:    toolStripAction.showAlternateIcon ? modelData.alternateIconSource : modelData.iconSource
    text:           toolStripAction.text
    checked:        toolStripAction.checked
    checkable:      toolStripAction.dropPanelComponent || modelData.checkable

    property var    toolStripAction:    undefined
    property var    dropPanel:          undefined
    property alias  radius:             buttonBkRect.radius
    property alias  fontPointSize:      innerText.font.pointSize
    property alias  imageSource:        innerImage.source
    property alias  contentWidth:       innerText.contentWidth


    property real iconSize: ScreenTools.defaultFontPixelHeight * 1.6
    property real textSize: ScreenTools.defaultFontPixelHeight *0.5

    property bool forceImageScale11: false
    property real imageScale:        forceImageScale11 && (text == "") ? 0.6 : 0.5
    property real contentMargins:    innerText.height * 0.15
    property real verticalOffset:    3

    property color accentColor: "#00C853"

    // From the palette, because the strip behind this sits on qgcPal.toolbarBackground
    // and that is white under the light theme the Plan view uses. The old #E4E4E4 was
    // picked for a dark strip and came out invisible there -- so the only icons that
    // showed were the disabled ones, still painted a darker #7E7E7E.
    property color _currentContentColor:  (checked || pressed)
                                          ? accentColor
                                          : qgcPal.text   // already dimmed when disabled,
                                                          // via colorGroupEnabled below
    property color _currentContentColorSecondary:  (checked || pressed) ? "#FFFFFF" : accentColor

    signal dropped(int index)

    onCheckedChanged: toolStripAction.checked = checked

    onClicked: {
        if (mainWindow.allowViewSwitch()) {
            dropPanel.hide()
            if (!toolStripAction.dropPanelComponent) {
                toolStripAction.triggered(this)
            } else if (checked) {
                var panelEdgeTopPoint = mapToItem(_root, width, 0)
                dropPanel.show(panelEdgeTopPoint, toolStripAction.dropPanelComponent, this)
                checked = true
                control.dropped(index)
            }
        } else if (checkable) {
            checked = !checked
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

    contentItem: Item {
        id:                 contentLayoutItem
        anchors.fill:       parent
        anchors.margins:    contentMargins
        anchors.topMargin:  contentMargins + 2

        Column {
            anchors.centerIn:   parent
            anchors.verticalCenterOffset: control.verticalOffset
            spacing:        contentMargins * 1.2

            Image {
                id:                         innerImageColorful
                height:                     control.iconSize * 0.8
                width:                      control.iconSize * 0.8
                smooth:                     true
                mipmap:                     true
                fillMode:                   Image.PreserveAspectFit
                antialiasing:               true
                sourceSize.height:          height
                sourceSize.width:           width
                anchors.horizontalCenter:   parent.horizontalCenter
                source:                     control.imageSource
                visible:                    source != "" && modelData.fullColorIcon
            }

            QGCColoredImage {
                id:                         innerImage
                height:                     control.iconSize * 0.8
                width:                      control.iconSize * 0.8
                smooth:                     true
                mipmap:                     true
                color:                      _currentContentColor
                fillMode:                   Image.PreserveAspectFit
                antialiasing:               true
                sourceSize.height:          height
                sourceSize.width:           width
                anchors.horizontalCenter:   parent.horizontalCenter
                visible:                    source != "" && !modelData.fullColorIcon

                QGCColoredImage {
                    id:                         innerImageSecondColor
                    source:                     modelData.alternateIconSource
                    height:                     control.iconSize * 0.8
                    width:                      control.iconSize * 0.8
                    smooth:                     true
                    mipmap:                     true
                    color:                      _currentContentColorSecondary
                    fillMode:                   Image.PreserveAspectFit
                    antialiasing:               true
                    sourceSize.height:          height
                    sourceSize.width:           width
                    anchors.horizontalCenter:   parent.horizontalCenter
                    visible:                    source != "" && modelData.biColorIcon
                }
            }

            QGCLabel {
                id:                         innerText
                text:                       control.text
                color:                      _currentContentColor
                anchors.horizontalCenter:   parent.horizontalCenter
                font.bold:                  true
                font.pointSize:             control.textSize
                horizontalAlignment:        Text.AlignHCenter
                wrapMode:                   Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount:           2
            }
        }
    }

    background: Rectangle {
        id:             buttonBkRect
        anchors.fill:   parent
        // Tints of the text colour rather than fixed greys, for the same reason: a
        // #333333 hover behind a dark icon hides it once the strip is light.
        color:          control.pressed ? Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.22)
                                        : (control.checked ? Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.16)
                                                           : ((control.enabled && control.hovered) ? Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.10) : "transparent"))

        Behavior on color { ColorAnimation { duration: 120 } }

        // Seçili aləti bildirən yaşıl sol kənar
        Rectangle {
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            width:                  3
            height:                 parent.height * 0.6
            radius:                 1.5
            color:                  control.accentColor
            visible:                control.checked || control.pressed
        }
    }
}

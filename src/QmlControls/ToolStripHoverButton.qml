// import QtQuick
// import QtQuick.Controls

// import QGroundControl
// import QGroundControl.Controls


// Button {
//     id:             control
//     width:          contentLayoutItem.contentWidth + (contentMargins * 2)
//     height:         width
//     hoverEnabled:   !ScreenTools.isMobile
//     enabled:        toolStripAction.enabled
//     visible:        toolStripAction.visible
//     imageSource:    toolStripAction.showAlternateIcon ? modelData.alternateIconSource : modelData.iconSource
//     text:           toolStripAction.text
//     checked:        toolStripAction.checked
//     checkable:      toolStripAction.dropPanelComponent || modelData.checkable

//     property var    toolStripAction:    undefined
//     property var    dropPanel:          undefined
//     property alias  radius:             buttonBkRect.radius
//     property alias  fontPointSize:      innerText.font.pointSize
//     property alias  imageSource:        innerImage.source
//     property alias  contentWidth:       innerText.contentWidth

//     property real iconSize: ScreenTools.defaultFontPixelHeight * 1.5

//     property bool forceImageScale11: false
//     property real imageScale:        forceImageScale11 && (text == "") ? 0.8 : 0.6
//     property real contentMargins:    innerText.height * 0.1
//     property real verticalOffset:    5  // DAHA KIÇİK DƏYƏR

//     property color _currentContentColor:  (checked || pressed) ? qgcPal.buttonHighlightText : qgcPal.buttonText
//     property color _currentContentColorSecondary:  (checked || pressed) ? qgcPal.buttonText : qgcPal.buttonHighlight

//     signal dropped(int index)

//     onCheckedChanged: toolStripAction.checked = checked

//     onClicked: {
//         if (mainWindow.allowViewSwitch()) {
//             dropPanel.hide()
//             if (!toolStripAction.dropPanelComponent) {
//                 toolStripAction.triggered(this)
//             } else if (checked) {
//                 var panelEdgeTopPoint = mapToItem(_root, width, 0)
//                 dropPanel.show(panelEdgeTopPoint, toolStripAction.dropPanelComponent, this)
//                 checked = true
//                 control.dropped(index)
//             }
//         } else if (checkable) {
//             checked = !checked
//         }
//     }

//     QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

//     contentItem: Item {
//         id:                 contentLayoutItem
//         anchors.fill:       parent
//         anchors.margins:    contentMargins
//         anchors.topMargin:  contentMargins + 2  // ÜSTDƏN BOŞLUQ ƏLAVƏ ET

//         Column {
//             anchors.centerIn:   parent
//             anchors.verticalCenterOffset: control.verticalOffset
//             spacing:        contentMargins * 1.5  // DAHA AZ SPACING

//             Image {
//                 id:                         innerImageColorful
//                 height:                     contentLayoutItem.height * imageScale * 0.9  // DAHA KIÇİK İCON
//                 width:                      contentLayoutItem.width  * imageScale * 0.9
//                 smooth:                     true
//                 mipmap:                     true
//                 fillMode:                   Image.PreserveAspectFit
//                 antialiasing:               true
//                 sourceSize.height:          height
//                 sourceSize.width:           width
//                 anchors.horizontalCenter:   parent.horizontalCenter
//                 source:                     control.imageSource
//                 visible:                    source != "" && modelData.fullColorIcon
//             }

//             QGCColoredImage {
//                 id:                         innerImage
//                 height:                     contentLayoutItem.height * imageScale * 0.9  // DAHA KIÇİK İCON
//                 width:                      contentLayoutItem.width  * imageScale * 0.9
//                 smooth:                     true
//                 mipmap:                     true
//                 color:                      _currentContentColor
//                 fillMode:                   Image.PreserveAspectFit
//                 antialiasing:               true
//                 sourceSize.height:          height
//                 sourceSize.width:           width
//                 anchors.horizontalCenter:   parent.horizontalCenter
//                 visible:                    source != "" && !modelData.fullColorIcon

//                 QGCColoredImage {
//                     id:                         innerImageSecondColor
//                     source:                     modelData.alternateIconSource
//                     height:                     contentLayoutItem.height * imageScale * 0.9
//                     width:                      contentLayoutItem.width  * imageScale * 0.9
//                     smooth:                     true
//                     mipmap:                     true
//                     color:                      _currentContentColorSecondary
//                     fillMode:                   Image.PreserveAspectFit
//                     antialiasing:               true
//                     sourceSize.height:          height
//                     sourceSize.width:           width
//                     anchors.horizontalCenter:   parent.horizontalCenter
//                     visible:                    source != "" && modelData.biColorIcon
//                 }
//             }

//             QGCLabel {
//                 id:                         innerText
//                 text:                       control.text
//                 color:                      _currentContentColor
//                 anchors.horizontalCenter:   parent.horizontalCenter
//                 font.bold:                  !innerImage.visible && !innerImageColorful.visible
//                 opacity:                    !innerImage.visible ? 0.8 : 1.0
//                 font.pointSize:             ScreenTools.mediumFontPointSize  // DAHA KIÇİK YAZI
//             }
//         }
//     }

//     background: Rectangle {
//         id:             buttonBkRect
//         color:          (control.checked || control.pressed) ?
//                             "#434343" :
//                             ((control.enabled && control.hovered) ? "#9D9D9D" : qgcPal.toolbarBackground)
//         anchors.fill:   parent
//     }
// }


// import QtQuick
// import QtQuick.Controls

// import QGroundControl
// import QGroundControl.Controls

// Button {
//     id:             control
//     width:          contentLayoutItem.contentWidth + (contentMargins * 2)
//     height:         width
//     hoverEnabled:   !ScreenTools.isMobile
//     enabled:        toolStripAction.enabled
//     visible:        toolStripAction.visible
//     imageSource:    toolStripAction.showAlternateIcon ? modelData.alternateIconSource : modelData.iconSource
//     text:           toolStripAction.text
//     checked:        toolStripAction.checked
//     checkable:      toolStripAction.dropPanelComponent || modelData.checkable

//     property var    toolStripAction:    undefined
//     property var    dropPanel:          undefined
//     property alias  radius:             buttonBkRect.radius
//     property alias  fontPointSize:      innerText.font.pointSize
//     property alias  imageSource:        innerImage.source
//     property alias  contentWidth:       innerText.contentWidth

//     // YENİ: Icon ve yazı boyutları için property'ler
//     property real iconSize: ScreenTools.defaultFontPixelHeight * 1.5  // DAHA KÜÇÜK İCON
//     property real textSize: ScreenTools.largeFontPointSize *8          // DAHA BÜYÜK YAZI

//     property bool forceImageScale11: false
//     property real imageScale:        forceImageScale11 && (text == "") ? 0.6 : 0.5  // DAHA KÜÇÜK İCON SCALE
//     property real contentMargins:    innerText.height * 0.15  // Biraz daha fazla margin
//     property real verticalOffset:    3  // Daha az offset

//     property color _currentContentColor:  (checked || pressed) ? qgcPal.buttonHighlightText : qgcPal.buttonText
//     property color _currentContentColorSecondary:  (checked || pressed) ? qgcPal.buttonText : qgcPal.buttonHighlight

//     signal dropped(int index)

//     onCheckedChanged: toolStripAction.checked = checked

//     onClicked: {
//         if (mainWindow.allowViewSwitch()) {
//             dropPanel.hide()
//             if (!toolStripAction.dropPanelComponent) {
//                 toolStripAction.triggered(this)
//             } else if (checked) {
//                 var panelEdgeTopPoint = mapToItem(_root, width, 0)
//                 dropPanel.show(panelEdgeTopPoint, toolStripAction.dropPanelComponent, this)
//                 checked = true
//                 control.dropped(index)
//             }
//         } else if (checkable) {
//             checked = !checked
//         }
//     }

//     QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

//     contentItem: Item {
//         id:                 contentLayoutItem
//         anchors.fill:       parent
//         anchors.margins:    contentMargins
//         anchors.topMargin:  contentMargins + 2

//         Column {
//             anchors.centerIn:   parent
//             anchors.verticalCenterOffset: control.verticalOffset
//             spacing:        contentMargins * 1.2  // Icon ve yazı arasında daha az boşluk

//             Image {
//                 id:                         innerImageColorful
//                 height:                     control.iconSize * 0.8  // SABİT KÜÇÜK BOYUT
//                 width:                      control.iconSize * 0.8
//                 smooth:                     true
//                 mipmap:                     true
//                 fillMode:                   Image.PreserveAspectFit
//                 antialiasing:               true
//                 sourceSize.height:          height
//                 sourceSize.width:           width
//                 anchors.horizontalCenter:   parent.horizontalCenter
//                 source:                     control.imageSource
//                 visible:                    source != "" && modelData.fullColorIcon
//             }

//             QGCColoredImage {
//                 id:                         innerImage
//                 height:                     control.iconSize * 0.8  // SABİT KÜÇÜK BOYUT
//                 width:                      control.iconSize * 0.8
//                 smooth:                     true
//                 mipmap:                     true
//                 color:                      _currentContentColor
//                 fillMode:                   Image.PreserveAspectFit
//                 antialiasing:               true
//                 sourceSize.height:          height
//                 sourceSize.width:           width
//                 anchors.horizontalCenter:   parent.horizontalCenter
//                 visible:                    source != "" && !modelData.fullColorIcon

//                 QGCColoredImage {
//                     id:                         innerImageSecondColor
//                     source:                     modelData.alternateIconSource
//                     height:                     control.iconSize * 0.8  // SABİT KÜÇÜK BOYUT
//                     width:                      control.iconSize * 0.8
//                     smooth:                     true
//                     mipmap:                     true
//                     color:                      _currentContentColorSecondary
//                     fillMode:                   Image.PreserveAspectFit
//                     antialiasing:               true
//                     sourceSize.height:          height
//                     sourceSize.width:           width
//                     anchors.horizontalCenter:   parent.horizontalCenter
//                     visible:                    source != "" && modelData.biColorIcon
//                 }
//             }

//             QGCLabel {
//                 id:                         innerText
//                 text:                       control.text
//                 color:                      _currentContentColor
//                 anchors.horizontalCenter:   parent.horizontalCenter
//                 font.bold:                  true  // DAHA KALIN YAZI
//                 font.pointSize:             control.textSize  // BÜYÜK YAZI BOYUTU
//                 horizontalAlignment:        Text.AlignHCenter
//                 wrapMode:                   Text.WrapAtWordBoundaryOrAnywhere
//                 maximumLineCount:           2  // Uzun metinler için 2 satır
//             }
//         }
//     }

//     background: Rectangle {
//         id:             buttonBkRect
//         color:          (control.checked || control.pressed) ?
//                             "#434343" :
//                             ((control.enabled && control.hovered) ? "#9D9D9D" : qgcPal.toolbarBackground)
//         anchors.fill:   parent
//     }
// }


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

    property color _currentContentColor:  (checked || pressed)
                                          ? accentColor
                                          : (control.enabled ? "#E4E4E4" : "#7E7E7E")
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
        color:          control.pressed ? "#4A4A4A"
                                        : (control.checked ? "#3A3A3A"
                                                           : ((control.enabled && control.hovered) ? "#333333" : "transparent"))

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

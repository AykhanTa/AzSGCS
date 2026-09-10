import QtQuick
import QtQuick.Controls

import QGroundControl


import QGroundControl.Controls

Rectangle {
    id:         _root
    color:      qgcPal.toolbarBackground
    width:      70
    height:     956
    radius:     ScreenTools.defaultFontPixelWidth / 2

    Rectangle {
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            width: 2
            color: "black"
        }


    property alias  model:              repeater.model
    property real   maxHeight           ///< Maximum height for control, determines whether text is hidden to make control shorter
    property alias  title:              titleLabel.text
    property var    fontSize:           ScreenTools.smallFontPointSize

    property var _dropPanel: dropPanel

    function simulateClick(buttonIndex) {
        buttonIndex = buttonIndex + 1 // skip over title label
        var button = toolStripColumn.children[buttonIndex]
        if (button.checkable) {
            button.checked = !button.checked
        }
        button.clicked()
    }

    signal dropped(int index)

    DeadMouseArea {
        anchors.fill: parent
    }

    QGCFlickable {
        id:                 flickable
        anchors.margins:    ScreenTools.defaultFontPixelWidth * 0.4
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right
        height:             parent.height - anchors.margins * 2
        contentHeight:      toolStripColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        Column {
            id:             toolStripColumn
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelWidth * 0.25

            QGCLabel {
                id:                     titleLabel
                anchors.left:           parent.left
                anchors.right:          parent.right
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.mediumFontPointSize
                visible:                title != ""
            }

            Repeater {
                id: repeater

                ToolStripHoverButton {
                    id:                 buttonTemplate
                    anchors.left:       toolStripColumn.left
                    anchors.right:      toolStripColumn.right
                    height:             80
                    radius:             ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:      _root.fontSize
                    toolStripAction:    modelData
                    dropPanel:          _dropPanel
                    onDropped: (index) => _root.dropped(index)

                    onCheckedChanged: {
                        // We deal with exclusive check state manually since usinug autoExclusive caused all sorts of crazt problems
                        if (checked) {
                            for (var i=0; i<repeater.count; i++) {
                                if (i != index) {
                                    var button = repeater.itemAt(i)
                                    if (button.checked) {
                                        button.checked = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ToolStripDropPanel {
        id:         dropPanel
        toolStrip:  _root
    }
}


// Rectangle {
//     id:         _root
//     color:      qgcPal.toolbarBackground
//     width:      80
//     height:     956
//     topRightRadius: 6
//     bottomRightRadius: 6

//     border {
//         width: 0
//         color: "transparent"
//     }

//     property alias  model:              repeater.model
//     property real   maxHeight:          956
//     property alias  title:              titleLabel.text
//     property var    fontSize:           ScreenTools.smallFontPointSize

//     property var _dropPanel: dropPanel


//     Rectangle {
//         anchors {
//             left: parent.left
//             right: parent.right
//             top: parent.top
//         }
//         height: 5
//         color: "black"
//     }

//     // ✅ SAĞDAN QARA XƏTT - BÜTÜN HÜNDÜRLÜYÜ QAPATMASIN
//     Rectangle {
//         anchors {
//             right: parent.right
//             top: parent.top
//             bottom: parent.bottom
//         }
//         width: 5
//         color: "black"
//     }

//     function simulateClick(buttonIndex) {
//         buttonIndex = buttonIndex + 1 // skip over title label
//         var button = toolStripColumn.children[buttonIndex]
//         if (button.checkable) {
//             button.checked = !button.checked
//         }
//         button.clicked()
//     }

//     signal dropped(int index)

//     DeadMouseArea {
//         anchors.fill: parent
//     }

//     // ✅ FLICKABLE-I YENİ ÖLÇÜLƏRƏ UYĞUNLAŞDIR
//     QGCFlickable {
//         id:                 flickable
//         anchors.margins:    ScreenTools.defaultFontPixelWidth * 0.4
//         anchors.top:        parent.top
//         anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 0.4 + 2  // Yuxarı xətt üçün margin
//         anchors.left:       parent.left
//         anchors.right:      parent.right
//         anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 0.4 + 2  // Sağ xətt üçün margin
//         anchors.bottom:     parent.bottom  // ✅ AŞAĞIYA QƏDƏR UZANSIN
//         contentHeight:      toolStripColumn.height
//         flickableDirection: Flickable.VerticalFlick
//         clip:               true

//         Column {
//             id:             toolStripColumn
//             anchors.left:   parent.left
//             anchors.right:  parent.right
//             spacing:        ScreenTools.defaultFontPixelWidth * 0.25

//             QGCLabel {
//                 id:                     titleLabel
//                 anchors.left:           parent.left
//                 anchors.right:          parent.right
//                 horizontalAlignment:    Text.AlignHCenter
//                 font.pointSize:         ScreenTools.smallFontPointSize
//                 visible:                title != ""
//             }

//             Repeater {
//                 id: repeater

//                 ToolStripHoverButton {
//                     id:                 buttonTemplate
//                     anchors.left:       toolStripColumn.left
//                     anchors.right:      toolStripColumn.right
//                     height:             60  // ✅ DÜYMƏLƏRİN HÜNDÜRLÜYÜNÜ ARTIR
//                     radius:             ScreenTools.defaultFontPixelWidth / 2
//                     fontPointSize:      _root.fontSize
//                     toolStripAction:    modelData
//                     dropPanel:          _dropPanel
//                     onDropped: (index) => _root.dropped(index)

//                     onCheckedChanged: {
//                         if (checked) {
//                             for (var i=0; i<repeater.count; i++) {
//                                 if (i != index) {
//                                     var button = repeater.itemAt(i)
//                                     if (button.checked) {
//                                         button.checked = false
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     ToolStripDropPanel {
//         id:         dropPanel
//         toolStrip:  _root
//     }
// }

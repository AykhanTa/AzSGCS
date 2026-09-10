// import QtQuick
// import QtQuick.Controls

// import QGroundControl

// import QGroundControl.Controls

// QGCFlickable {
//     height:         outerEditorRect.height
//     contentHeight:  outerEditorRect.height
//     clip:           true

//     property var controller ///< RallyPointController

//     readonly property real  _margin: ScreenTools.defaultFontPixelWidth / 2
//     readonly property real  _radius: ScreenTools.defaultFontPixelWidth / 2

//     Rectangle {
//         id:     outerEditorRect
//         width:  parent.width
//         height: innerEditorRect.y + innerEditorRect.height + (_margin * 2)
//         radius: _radius
//         color:  qgcPal.missionItemEditor

//         QGCLabel {
//             id:                 editorLabel
//             anchors.margins:    _margin
//             anchors.left:       parent.left
//             anchors.top:        parent.top
//             text:               qsTr("Rally Points")
//         }

//         Rectangle {
//             id:                 innerEditorRect
//             anchors.margins:    _margin
//             anchors.left:       parent.left
//             anchors.right:      parent.right
//             anchors.top:        editorLabel.bottom
//             height:             infoLabel.height + (_margin * 2)
//             color:              qgcPal.windowShadeDark
//             radius:             _radius

//             QGCLabel {
//                 id:                 infoLabel
//                 anchors.margins:    _margin
//                 anchors.top:        parent.top
//                 anchors.left:       parent.left
//                 anchors.right:      parent.right
//                 wrapMode:           Text.WordWrap
//                 font.pointSize:     ScreenTools.smallFontPointSize
//                 text:               qsTr("Rally Points provide alternate landing points when performing a Return to Launch (RTL).")
//             }

//             /*
//             QGCLabel {
//                 id:                 helpLabel
//                 anchors.margins:    _margin
//                 anchors.left:       parent.left
//                 anchors.right:      parent.right
//                 anchors.top:        infoLabel.bottom
//                 wrapMode:           Text.WordWrap
//                 text:               controller.supported ?
//                                         qsTr("Click in the map to add new rally points.") :
//                                         qsTr("This vehicle does not support Rally Points.")
//             }
//             */
//         }
//     }
// }





import QtQuick
import QtQuick.Controls

import QGroundControl

import QGroundControl.Controls

QGCFlickable {
    height:         outerEditorRect.height
    contentHeight:  outerEditorRect.height
    clip:           true

    property var controller ///< RallyPointController

    readonly property real  _margin: ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _radius: ScreenTools.defaultFontPixelWidth / 2

    Rectangle {
        id:     outerEditorRect
        width:  parent.width
        height: 180//innerEditorRect.y + innerEditorRect.height + (_margin * 2)
        radius: _radius
        color:  qgcPal.missionItemEditor

        QGCLabel {
            id:                 editorLabel
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.top:        parent.top
            text:               qsTr("Rally Points")
            font.pointSize:     12
        }

        Rectangle {
            id:                 innerEditorRect
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        editorLabel.bottom
            height:             76//infoLabel.height + (_margin * 2)
            color:              qgcPal.windowShadeDark
            radius:             _radius

            QGCLabel {
                y:15
                id:                 infoLabel
                anchors.margins:    _margin
                //anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                wrapMode:           Text.WordWrap
                font.pointSize:     10//ScreenTools.smallFontPointSize
                text:               qsTr("Rally Points, Return to Launch (RTL) yerinə yetirərkən alternativ enmə nöqtələri təmin edir.")
            }

            /*
            QGCLabel {
                id:                 helpLabel
                anchors.margins:    _margin
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.top:        infoLabel.bottom
                wrapMode:           Text.WordWrap
                text:               controller.supported ?
                                        qsTr("Click in the map to add new rally points.") :
                                        qsTr("This vehicle does not support Rally Points.")
            }
            */
        }
    }
}

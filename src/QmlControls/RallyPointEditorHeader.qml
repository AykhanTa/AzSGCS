




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
    readonly property real  _radius: AzTheme.px(12)

    Rectangle {
        id:     outerEditorRect
        width:  parent.width
        height: 180//innerEditorRect.y + innerEditorRect.height + (_margin * 2)
        // A mission item card of the Missiya tab
        radius:       _radius
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }

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
            color:              AzTheme.groupFill
            border.width:       1
            border.color:       AzTheme.groupBorder
            radius:             AzTheme.px(AzTheme.groupRadius)

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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls



QGCPopupDialog {
    id:         root
    title:      qsTr("Missiya əmrini seçin")
    buttons:    Dialog.Cancel

    property var    vehicle
    property var    missionItem
    property var    map
    property bool   flyThroughCommandsAllowed

    ColumnLayout {
        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.4)

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            spacing: ScreenTools.defaultFontPixelWidth

            QGCLabel {
                text:       qsTr("Kateqoriya:")
                font.bold:  true
                color:      "#FFFFFF"
            }

            QGCComboBox {
                id:                     categoryCombo
                Layout.preferredWidth:  30 * ScreenTools.defaultFontPixelWidth
                model:                  QGroundControl.missionCommandTree.categoriesForVehicle(vehicle)

                function categorySelected(category) {
                    commandList.model = QGroundControl.missionCommandTree.getCommandsForCategory(vehicle, category, flyThroughCommandsAllowed)
                }

                Component.onCompleted: {
                    var category  = missionItem.category
                    currentIndex = find(category)
                    categorySelected(category)
                }

                onActivated: (index) => { categorySelected(textAt(index)) }
            }
        }

        Repeater {
            id:                 commandList
            Layout.fillWidth:   true

            delegate: Rectangle {
                id:     commandRow
                width:  parent.width
                height: commandColumn.height + ScreenTools.defaultFontPixelHeight
                radius: 10
                color:  commandMouse.pressed ? "#454545" : (commandMouse.containsMouse ? "#3A3A3A" : "#2F2F2F")
                border.width: 1
                border.color: commandMouse.containsMouse ? "#00C853" : "#4A4A4A"

                property var mavCmdInfo: modelData
                property bool _current:  missionItem.command === mavCmdInfo.command

                Behavior on color { ColorAnimation { duration: 120 } }

                // Hazırkı / seçilən əmri bildirən sol kənar
                Rectangle {
                    anchors.left:           parent.left
                    anchors.leftMargin:     2
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  3
                    height:                 parent.height * 0.6
                    radius:                 1.5
                    color:                  "#00C853"
                    visible:                commandRow._current || commandMouse.containsMouse
                }

                Column {
                    id:                 commandColumn
                    anchors.margins:    ScreenTools.defaultFontPixelWidth
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        parent.top
                    spacing:            2

                    QGCLabel {
                        text:           mavCmdInfo.friendlyName
                        color:          "#FFFFFF"
                        font.bold:      true
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }

                    QGCLabel {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        text:               mavCmdInfo.description
                        wrapMode:           Text.WordWrap
                        color:              "#B9B9B9"
                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.92
                    }
                }

                MouseArea {
                    id:             commandMouse
                    anchors.fill:   parent
                    hoverEnabled:   true
                    cursorShape:    Qt.PointingHandCursor
                    onClicked: {
                        missionItem.setMapCenterHintForCommandChange(map.center)
                        missionItem.command = mavCmdInfo.command
                        root.close()
                    }
                }
            }
        }
    }
}

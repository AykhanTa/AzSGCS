import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQml
import QtQuick.Layouts

import QGroundControl


import QGroundControl.Controls
import QGroundControl.FactControls



/// Mission item edit control
Rectangle {
    id:             _root
    height:         _currentItem ? (editorLoader.y + editorLoader.height + _innerMargin) : (topRowLayout.y + topRowLayout.height + _margin)
    // Kartlar xəritənin üstündə oturduğu üçün fon tam qeyri-şəffafdır —
    // əks halda altdakı xəritə mətni oxunmaz edir.
    color:          _currentItem ? "#3D3B3B" : (_hoverHandler.hovered ? "#343434" : "#2B2B2B")
    radius:         _radius
    opacity:        1.0
    border.width:   _readyForSave ? 1 : 2
    border.color:   _readyForSave ? (_currentItem ? "#00C853" : "#5A5A5A") : qgcPal.warningText

    Behavior on color { ColorAnimation { duration: 130 } }

    HoverHandler { id: _hoverHandler }

    property var    map                 ///< Map control
    property var    masterController
    property var    missionItem         ///< MissionItem associated with this editor
    property bool   readOnly            ///< true: read only view, false: full editing view

    signal clicked
    signal remove
    signal selectNextNotReadyItem

    property var    _masterController:          masterController
    property var    _missionController:         _masterController.missionController
    property bool   _currentItem:               missionItem.isCurrentItem
    property color  _outerTextColor:            _currentItem ? qgcPal.primaryButtonText : qgcPal.text
    property bool   _noMissionItemsAdded:       ListView.view.model.count === 1
    property real   _sectionSpacer:             ScreenTools.defaultFontPixelWidth / 2  // spacing between section headings
    property bool   _singleComplexItem:         _missionController.complexMissionItemNames.length === 1
    property bool   _readyForSave:              missionItem.readyForSaveState === VisualMissionItem.ReadyForSave

    readonly property real  _editFieldWidth:    Math.min(width - _innerMargin * 2, ScreenTools.defaultFontPixelWidth * 12)
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth * 0.7
    readonly property real  _innerMargin:       2
    readonly property real  _radius:            10
    readonly property real  _hamburgerSize:     commandPicker.height * 0.75
    readonly property real  _trashSize:         commandPicker.height * 0.75
    readonly property bool  _waypointsOnlyMode: QGroundControl.corePlugin.options.missionWaypointsOnly

    QGCPalette {
        id: qgcPal
        colorGroupEnabled: enabled
    }

    FocusScope {
        id:             currentItemScope
        anchors.fill:   parent

        MouseArea {
            anchors.fill:   parent
            onClicked: {
                if (mainWindow.allowViewSwitch()) {
                    currentItemScope.focus = true
                    _root.clicked()
                }
            }
        }
    }

    Component {
        id: editPositionDialog

        EditPositionDialog {
            coordinate:             missionItem.isSurveyItem ?  missionItem.centerCoordinate : missionItem.coordinate
            onCoordinateChanged:    missionItem.isSurveyItem ?  missionItem.centerCoordinate = coordinate : missionItem.coordinate = coordinate
        }
    }

    Row {
        id:                 topRowLayout
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      rightButtonRow.left
        anchors.rightMargin: _margin * 0.5
        anchors.top:        parent.top
        spacing:            _margin

        // Sıra nömrəsi nişanı — hansı elementin neçənci olduğu dərhal görünsün
        Rectangle {
            id:                     sequenceBadge
            anchors.verticalCenter: parent.verticalCenter
            width:                  Math.max(20, ScreenTools.defaultFontPixelHeight * 1.35)
            height:                 width
            radius:                 width / 2
            color:                  _currentItem ? "#00C853" : "#4A4A4A"
            visible:                _readyForSave

            Behavior on color { ColorAnimation { duration: 130 } }

            QGCLabel {
                anchors.centerIn:   parent
                text:               missionItem.sequenceNumber === 0 ? "S" : missionItem.sequenceNumber
                color:              _currentItem ? "#0E0E0E" : "#E4E4E4"
                font.bold:          true
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }

        Rectangle {
            id:                     notReadyForSaveIndicator
            anchors.verticalCenter: parent.verticalCenter
            width:                  Math.max(20, ScreenTools.defaultFontPixelHeight * 1.35)
            height:                 width
            border.width:           1
            border.color:           qgcPal.warningText
            color:                  "white"
            radius:                 width / 2
            visible:                !_readyForSave

            QGCLabel {
                id:                 readyForSaveLabel
                anchors.centerIn:   parent
                //: Indicator in Plan view to show mission item is not ready for save/send
                text:               qsTr("?")
                color:              qgcPal.warningText
                font.bold:          true
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }

        Item {
            id:                     commandPicker
            anchors.verticalCenter: parent.verticalCenter
            height:                 ScreenTools.implicitComboBoxHeight
            width:                  innerLayout.width
            visible:                !commandLabel.visible

            RowLayout {
                id:                     innerLayout
                anchors.verticalCenter: parent.verticalCenter
                spacing:                _padding

                property real _padding: ScreenTools.comboBoxPadding

                QGCLabel {
                    text:           missionItem.commandName
                    font.bold:      true
                    font.pointSize: ScreenTools.defaultFontPointSize
                    color:          _outerTextColor
                }

                QGCColoredImage {
                    height:             ScreenTools.defaultFontPixelWidth
                    width:              height
                    fillMode:           Image.PreserveAspectFit
                    smooth:             true
                    antialiasing:       true
                    color:              qgcPal.text
                    source:             "/qmlimages/arrow-down.png"
                }
            }

            QGCMouseArea {
                fillItem:   parent
                onClicked:  commandDialog.createObject(mainWindow).open()
            }

            Component {
                id: commandDialog

                MissionCommandDialog {
                    vehicle:                    masterController.controllerVehicle
                    missionItem:                _root.missionItem
                    map:                        _root.map
                    flyThroughCommandsAllowed:  true //_missionController.flyThroughCommandsAllowed
                }
            }
        }

        QGCLabel {
            id:                     commandLabel
            anchors.verticalCenter: parent.verticalCenter
            height:                 ScreenTools.implicitComboBoxHeight
            visible:                !missionItem.isCurrentItem || !missionItem.isSimpleItem || _waypointsOnlyMode || missionItem.isTakeoffItem
            verticalAlignment:      Text.AlignVCenter
            text:                   missionItem.commandName
            color:                  _outerTextColor
            font.bold:              true
            font.pointSize:         ScreenTools.defaultFontPointSize
            elide:                  Text.ElideRight
        }
    }

    // Sağ tərəfdəki əməliyyat düymələri
    Row {
        id:                     rightButtonRow
        anchors.margins:        _margin
        anchors.right:          parent.right
        anchors.verticalCenter: topRowLayout.verticalCenter
        spacing:                _margin * 0.8

        QGCColoredImage {
            id:                     deleteButton
            anchors.verticalCenter: parent.verticalCenter
            height:                 _hamburgerSize
            width:                  height
            sourceSize.height:      height
            fillMode:               Image.PreserveAspectFit
            mipmap:                 true
            smooth:                 true
            color:                  deleteMouse.containsMouse ? qgcPal.warningText : qgcPal.text
            visible:                _currentItem && missionItem.sequenceNumber !== 0
            source:                 "/res/TrashDelete.svg"

            MouseArea {
                id:             deleteMouse
                anchors.fill:   parent
                hoverEnabled:   true
                cursorShape:    Qt.PointingHandCursor
                onClicked:      remove()
            }
        }

        QGCColoredImage {
            id:                     hamburger
            anchors.verticalCenter: parent.verticalCenter
            width:                  _hamburgerSize
            height:                 _hamburgerSize
            sourceSize.height:      _hamburgerSize
            source:                 "qrc:/qmlimages/Hamburger.svg"
            visible:                missionItem.isCurrentItem && missionItem.sequenceNumber !== 0
            color:                  hamburgerMouse.containsMouse ? "#00C853" : qgcPal.text

            MouseArea {
                id:             hamburgerMouse
                anchors.fill:   parent
                hoverEnabled:   true
                cursorShape:    Qt.PointingHandCursor
                onClicked: {
                    currentItemScope.focus = true
                    var position = Qt.point(width / 2, height / 2)
                    // For some strange reason using mainWindow in mapToItem doesn't work, so we use globals.parent instead which also gets us mainWindow
                    position = mapToItem(globals.parent, position)
                    var dropPanel = hamburgerMenuDropPanelComponent.createObject(mainWindow, { clickRect: Qt.rect(position.x, position.y, 0, 0) })
                    dropPanel.open()
                }
            }
        }
    }

    Component {
        id: hamburgerMenuDropPanelComponent

        DropPanel {
            id: hamburgerMenuDropPanel

            sourceComponent: Component {
                ColumnLayout {
                    id:      menuColumn
                    spacing: Math.max(4, ScreenTools.defaultFontPixelHeight * 0.28)

                    // Ən uzun bənd ("Əvvəlki element mövqeyinə keçin") kəsilməsin deyə
                    readonly property real _menuW: Math.max(260, ScreenTools.defaultFontPixelWidth * 32)
                    readonly property real _itemH: Math.max(34, ScreenTools.defaultFontPixelHeight * 1.9)

                    // Menyu başlığı — hansı elementə aid olduğu görünsün
                    RowLayout {
                        Layout.fillWidth:   true
                        Layout.bottomMargin: 2
                        spacing:            8

                        Rectangle {
                            width:  Math.max(20, ScreenTools.defaultFontPixelHeight * 1.35)
                            height: width
                            radius: width / 2
                            color:  "#00C853"

                            QGCLabel {
                                anchors.centerIn:   parent
                                text:               missionItem.sequenceNumber
                                color:              "#0E0E0E"
                                font.bold:          true
                                font.pointSize:     ScreenTools.smallFontPointSize
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth:   true
                            text:               missionItem.commandName
                            color:              "#FFFFFF"
                            font.bold:          true
                            font.pointSize:     ScreenTools.defaultFontPointSize
                            elide:              Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.fillWidth:       true
                        Layout.preferredHeight: 1
                        color:                  "#4A4A4A"
                    }

                    MissionMenuButton {
                        Layout.fillWidth:       true
                        Layout.minimumWidth:    menuColumn._menuW
                        Layout.preferredHeight: menuColumn._itemH
                        text:                   qsTr("Təyyarə mövqeyinə keçin")
                        enabled:                _activeVehicle && missionItem.specifiesCoordinate

                        onClicked: {
                            missionItem.coordinate = _activeVehicle.coordinate
                            hamburgerMenuDropPanel.close()
                        }

                        property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
                    }

                    MissionMenuButton {
                        Layout.fillWidth:       true
                        Layout.minimumWidth:    menuColumn._menuW
                        Layout.preferredHeight: menuColumn._itemH
                        text:                   qsTr("Əvvəlki element mövqeyinə keçin")
                        enabled:                _missionController.previousCoordinate.isValid
                        onClicked: {
                            missionItem.coordinate = _missionController.previousCoordinate
                            hamburgerMenuDropPanel.close()
                        }
                    }

                    MissionMenuButton {
                        Layout.fillWidth:       true
                        Layout.minimumWidth:    menuColumn._menuW
                        Layout.preferredHeight: menuColumn._itemH
                        text:                   qsTr("Mövqeyi redaktə edin...")
                        enabled:                missionItem.specifiesCoordinate
                        onClicked: {
                            editPositionDialog.createObject(mainWindow).open()
                            hamburgerMenuDropPanel.close()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth:       true
                        Layout.preferredHeight: 1
                        color:                  "#4A4A4A"
                        visible:                QGroundControl.corePlugin.showAdvancedUI
                    }

                    QGCCheckBoxSlider {
                        Layout.fillWidth:   true
                        text:               qsTr("Bütün dəyərləri göstərin")
                        visible:            QGroundControl.corePlugin.showAdvancedUI
                        checked:            missionItem.isSimpleItem ? missionItem.rawEdit : false
                        enabled:            missionItem.isSimpleItem && !_waypointsOnlyMode

                        onClicked: {
                            missionItem.rawEdit = checked
                            if (missionItem.rawEdit && !missionItem.friendlyEditAllowed) {
                                missionItem.rawEdit = false
                                checked = false
                                mainWindow.showMessageDialog(qsTr("Missiya redaktəsi"), qsTr("Siz Sadə Rejimdə göstərilə bilməyən missiya elementinə dəyişikliklər etdiniz"))
                            }
                            hamburgerMenuDropPanel.close()
                        }
                    }
                }
            }
        }
    }


    /*
    QGCLabel {
        id:                     notReadyForSaveLabel
        anchors.margins:        _margin
        anchors.left:           notReadyForSaveIndicator.right
        anchors.right:          parent.right
        anchors.top:            commandPicker.bottom
        visible:                _currentItem && !_readyForSave
        text:                   missionItem.readyForSaveState === VisualMissionItem.NotReadyForSaveTerrain ?
                                    qsTr("Incomplete: Waiting on terrain data.") :
                                    qsTr("Incomplete: Item not fully specified.")
        wrapMode:               Text.WordWrap
        horizontalAlignment:    Text.AlignHCenter
        color:                  qgcPal.warningText
    }

*/

    Loader {
        id:                 editorLoader
        anchors.margins:    _innerMargin
        anchors.left:       parent.left
        anchors.top:        topRowLayout.bottom
        source:             _currentItem ? missionItem.editorQml : ""
        asynchronous:       true

        property var    masterController:   _masterController
        property real   availableWidth:     _root.width - (anchors.margins * 2) ///< How wide the editor should be
        property var    editorRoot:         _root
    }
} // Rectangle

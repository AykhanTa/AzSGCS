



/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQml.Models
import QtQuick.Layouts

import QGroundControl

import QGroundControl.Controls
import QGroundControl.FlightDisplay

ColumnLayout {
    id: checkListRoot

    // Siyahının elementləri ilə eyni yığcamlıq eşiyi.
    readonly property bool _compact: ScreenTools.isShortScreen

    spacing: AzTheme.px(12)

    property real _verticalMargin: ScreenTools.defaultFontPixelHeight * (_compact ? 0.3 : 0.5)

    Loader {
        id:     modelContainer
        source: "qrc:/qml/QGroundControl/FlightDisplay/DefaultChecklist.qml"

        onLoaded: {
            Qt.callLater(function() {
                restartChecklist()
            })
        }
    }

    property bool allChecksPassed: false
    property var  vehicleCopy:     globals.activeVehicle

    // Width for the groups and their buttons; 0 keeps their own fixed width.
    property real listWidth: 0

    function restartChecklist() {
        delayedGroupPassed.stop()

        allChecksPassed = false

        if (globals.activeVehicle) {
            globals.activeVehicle.checkListState = Vehicle.CheckListFailed
        }

        if (checkListRepeater.model && checkListRepeater.model.reset) {
            checkListRepeater.model.reset()
        }
    }

    onVehicleCopyChanged: {
        _updateModel()
        Qt.callLater(function() {
            restartChecklist()
        })
    }

    onAllChecksPassedChanged: {
        if (!globals.activeVehicle) {
            return
        }

        if (allChecksPassed) {
            globals.activeVehicle.checkListState = Vehicle.CheckListPassed
        } else {
            globals.activeVehicle.checkListState = Vehicle.CheckListFailed
        }
    }

    function _handleGroupPassedChanged(index, passed) {
        if (passed) {
            var group = checkListRepeater.itemAt(index)
            if (group) {
                group._checked = false
            }

            if (index + 1 < checkListRepeater.count) {
                group = checkListRepeater.itemAt(index + 1)
                if (group) {
                    group.enabled = true
                    group._checked = true
                }
            }
        }

        var allPassed = true
        for (var i = 0; i < checkListRepeater.count; i++) {
            var item = checkListRepeater.itemAt(i)
            if (!item || !item.passed) {
                allPassed = false
                break
            }
        }

        allChecksPassed = allPassed
    }

    //-- Pick a checklist model that matches the current airframe type (if any)
    function _updateModel() {
        var vehicle = globals.activeVehicle
        if (!vehicle) {
            vehicle = QGroundControl.multiVehicleManager.offlineEditingVehicle
        }

        if (!vehicle) {
            modelContainer.source = "qrc:/qml/QGroundControl/FlightDisplay/DefaultChecklist.qml"
            return
        }

        if (vehicle.multiRotor) {
            modelContainer.source = "qrc:/qml/QGroundControl/FlightDisplay/MultiRotorChecklist.qml"
        } else if (vehicle.vtol) {
            modelContainer.source = "qrc:/qml/QGroundControl/FlightDisplay/VTOLChecklist.qml"
        } else if (vehicle.rover) {
            modelContainer.source = "qrc:/qml/QGroundControl/FlightDisplay/RoverChecklist.qml"
        } else if (vehicle.sub) {
            modelContainer.source = "qrc:/qml/QGroundControl/FlightDisplay/SubChecklist.qml"
        } else if (vehicle.fixedWing) {
            modelContainer.source = "qrc:/qml/QGroundControl/FlightDisplay/FixedWingChecklist.qml"
        } else {
            modelContainer.source = "qrc:/qml/QGroundControl/FlightDisplay/DefaultChecklist.qml"
        }
    }

    Component.onCompleted: {
        _updateModel()
        Qt.callLater(function() {
            restartChecklist()
        })
    }

    onVisibleChanged: {
        if (visible) {
            _updateModel()
            Qt.callLater(function() {
                restartChecklist()
            })
        }
    }

    // We delay the updates when a group passes so the user can see all items green for a moment prior to hiding
    Timer {
        id:       delayedGroupPassed
        interval: 750

        property int index

        onTriggered: _handleGroupPassedChanged(index, true /* passed */)
    }

    function groupPassedChanged(index, passed) {
        if (passed) {
            delayedGroupPassed.index = index
            delayedGroupPassed.restart()
        } else {
            delayedGroupPassed.stop()
            _handleGroupPassedChanged(index, passed)
        }
    }

    // Header/title of checklist
    RowLayout {
        Layout.fillWidth: true
        spacing:          0

        Text {
            Layout.fillWidth: true
            text:             allChecksPassed ? qsTr("Keçdi") : qsTr("Davam edir")
            color:            allChecksPassed ? AzTheme.statusGreen : AzTheme.textSecondary
            font.family:      AzTheme.fontFamily
            font.pixelSize:   AzTheme.fontPx(AzTheme.popupTextSize)
        }

        AzIconButton {
            Layout.alignment: Qt.AlignVCenter
            iconSource:       "/qmlimages/MapSyncBlack.svg"
            onClicked:        restartChecklist()
        }
    }

    // All check list items
    Repeater {
        id:    checkListRepeater
        model: modelContainer.item ? modelContainer.item.model : null

        onItemAdded: (index, item) => {
            if (item.contentWidth === undefined) {
                return
            }
            var ownWidth = item.contentWidth
            item.contentWidth = Qt.binding(function() { return checkListRoot.listWidth > 0 ? checkListRoot.listWidth : ownWidth })
        }
    }
}

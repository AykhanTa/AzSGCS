// // import QtQuick
// // import QtQuick.Controls
// // import QtQuick.Layouts
// // import QtQuick.Dialogs

// // import QGroundControl
// // import QGroundControl.Controls

// // Rectangle {
// //     id: _root
// //     width: parent.width
// //     height: ScreenTools.toolbarHeight
// //     color: qgcPal.toolbarBackground

// //     property var planMasterController

// //     property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
// //     property real _controllerProgressPct: planMasterController.missionController.progressPct

// //     QGCPalette { id: qgcPal }

// //     /// Bottom single pixel divider
// //     Rectangle {
// //         anchors.left: parent.left
// //         anchors.right: parent.right
// //         anchors.bottom: parent.bottom
// //         height: 1
// //         color: "black"
// //         visible: qgcPal.globalTheme === QGCPalette.Light
// //     }

// //     QGCToolBarButton {
// //         id: qgcButton
// //         height: parent.height
// //         icon.source: "/res/QGCLogoFull.svg"
// //         logo: true
// //         onClicked: mainWindow.showToolSelectDialog()
// //     }

// //     QGCFlickable {
// //         id: toolsFlickable
// //         anchors.bottomMargin: 1
// //         anchors.left: qgcButton.right
// //         anchors.top: parent.top
// //         anchors.bottom: parent.bottom
// //         anchors.right: parent.right
// //         contentWidth: toolIndicators.width
// //         flickableDirection: Flickable.HorizontalFlick

// //         PlanToolBarIndicators {
// //             id: toolIndicators
// //             anchors.top: parent.top
// //             anchors.bottom: parent.bottom
// //             planMasterController: _root.planMasterController
// //         }
// //     }

// //     // Small mission download progress bar
// //     Rectangle {
// //         id: progressBar
// //         anchors.left: parent.left
// //         anchors.bottom: parent.bottom
// //         height: 4
// //         width: _controllerProgressPct * parent.width
// //         color: qgcPal.colorGreen
// //         visible: false

// //         onVisibleChanged: {
// //             if (visible) {
// //                 largeProgressBar._userHide = false
// //             }
// //         }
// //     }

// //     // Large mission download progress bar
// //     Rectangle {
// //         id: largeProgressBar
// //         anchors.bottom: parent.bottom
// //         anchors.left: parent.left
// //         anchors.right: parent.right
// //         height: parent.height
// //         color: qgcPal.window
// //         visible: _showLargeProgress

// //         property bool _userHide: false
// //         property bool _showLargeProgress: progressBar.visible && !_userHide && qgcPal.globalTheme === QGCPalette.Light

// //         Connections {
// //             target: QGroundControl.multiVehicleManager
// //             function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
// //         }

// //         Rectangle {
// //             anchors.top: parent.top
// //             anchors.bottom: parent.bottom
// //             width: _controllerProgressPct * parent.width
// //             color: qgcPal.colorGreen
// //         }

// //         QGCLabel {
// //             anchors.centerIn: parent
// //             text: qsTr("Syncing Mission")
// //             font.pointSize: ScreenTools.largeFontPointSize
// //             visible: _controllerProgressPct !== 1
// //         }

// //         QGCLabel {
// //             anchors.centerIn: parent
// //             text: qsTr("Done")
// //             font.pointSize: ScreenTools.largeFontPointSize
// //             visible: _controllerProgressPct === 1
// //         }

// //         QGCLabel {
// //             anchors.margins: _margin
// //             anchors.right: parent.right
// //             anchors.bottom: parent.bottom
// //             text: qsTr("Click anywhere to hide")

// //             property real _margin: ScreenTools.defaultFontPixelWidth / 2
// //         }

// //         MouseArea {
// //             anchors.fill: parent
// //             onClicked: largeProgressBar._userHide = true
// //         }
// //     }

// //     // Progress bar
// //     Connections {
// //         target: planMasterController.missionController

// //         function onProgressPctChanged(progressPct) {
// //             if (progressPct === 1) {
// //                 if (_root.visible) {
// //                     resetProgressTimer.start()
// //                 } else {
// //                     progressBar.visible = false
// //                 }
// //             } else if (progressPct > 0) {
// //                 progressBar.visible = true
// //             }
// //         }
// //     }

// //     Timer {
// //         id: resetProgressTimer
// //         interval: 3000
// //         onTriggered: progressBar.visible = false
// //     }
// // }


// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts
// import QtQuick.Dialogs

// import QGroundControl
// import QGroundControl.Controls

// Rectangle {
//     id: _root
//     clip: true

//     readonly property real _toolbarH: Math.max(ScreenTools.toolbarHeight,
//                                               ScreenTools.defaultFontPixelHeight * 4.2)

//     implicitHeight: _toolbarH
//     width:  parent ? parent.width : implicitWidth
//     height: _toolbarH

//     Layout.fillWidth: true
//     Layout.preferredHeight: _toolbarH
//     Layout.minimumHeight: _toolbarH

//     color: "#1e1e1e"
//     z:     QGroundControl.zOrderWidgets

//     property var planMasterController

//     property var  _activeVehicle:            QGroundControl.multiVehicleManager.activeVehicle
//     property real _controllerProgressPct:    planMasterController.missionController.progressPct

//     property var  _missionController:        planMasterController.missionController
//     property var  _currentMissionItem:       _missionController ? _missionController.currentPlanViewItem : null

//     property bool _currentMissionItemValid:  _currentMissionItem && _currentMissionItem !== undefined && _currentMissionItem !== null
//     property bool _curreItemIsFlyThrough:    _currentMissionItemValid && _currentMissionItem.specifiesCoordinate && !_currentMissionItem.isStandaloneCoordinate
//     property bool _currentItemIsVTOLTakeoff: _currentMissionItemValid && _currentMissionItem.command == 84

//     property real _altDifference: _currentMissionItemValid ? _currentMissionItem.altDifference : NaN
//     property real _gradient:      _currentMissionItemValid && _currentMissionItem.distance > 0 ?
//                                   (_currentItemIsVTOLTakeoff ? 0 :
//                                    (Math.atan(_currentMissionItem.altDifference / _currentMissionItem.distance) * (180.0 / Math.PI)))
//                                   : NaN
//     property real _azimuth:       _currentMissionItemValid ? _currentMissionItem.azimuth : NaN
//     property real _heading:       _currentMissionItemValid ? _currentMissionItem.missionVehicleYaw : NaN
//     property real _distance:      _currentMissionItemValid ? _currentMissionItem.distance : NaN

//     property real _missionPlannedDistance: _missionController ? _missionController.missionPlannedDistance : NaN
//     property real _missionTime:            _missionController ? _missionController.missionTime : 0
//     property real _missionMaxTelemetry:    _missionController ? _missionController.missionMaxTelemetry : NaN
//     property int  _missionItemCount:       _missionController ? _missionController.visualItems.count : 0

//     property bool _controllerDirty:          planMasterController ? planMasterController.dirty : false
//     property bool _controllerSyncInProgress: planMasterController ? planMasterController.syncInProgress : false
//     property bool _controllerOffline:        planMasterController ? planMasterController.offline : true
//     property bool _containsItems:            planMasterController ? planMasterController.containsItems : false

//     // UTMSP
//     property bool _utmspEnabled: QGroundControl.utmspSupported

//     // Text-lər
//     property string _altDifferenceText:            isNaN(_altDifference) ? "-.-" : _altDifference.toFixed(1) + " m"
//     property string _gradientText:                 isNaN(_gradient) ? "-.-" : _gradient.toFixed(0) + "°"
//     property string _azimuthText:                  isNaN(_azimuth) ? "-.-" : Math.round(_azimuth) % 360
//     property string _headingText:                  isNaN(_heading) ? "-.-" : Math.round(_heading) % 360
//     property string _distanceText:                 isNaN(_distance) ? "-.-" : _distance.toFixed(1) + " m"
//     property string _missionPlannedDistanceText:   isNaN(_missionPlannedDistance) ? "-.-" : _missionPlannedDistance.toFixed(0) + " m"
//     property string _missionMaxTelemetryText:      isNaN(_missionMaxTelemetry) ? "-.-" : _missionMaxTelemetry.toFixed(0) + " m"

//     function getMissionTime() {
//         if (!_missionTime) {
//             return "00:00:00"
//         }
//         var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
//         var days = Qt.formatDateTime(t, "dd")
//         var complete

//         if (days == 31) {
//             days = "0"
//             complete = Qt.formatTime(t, "hh:mm:ss")
//         } else {
//             complete = days + " days " + Qt.formatTime(t, "hh:mm:ss")
//         }
//         return complete
//     }

//     QGCPalette { id: qgcPal }

//     // ============================================================
//     // ✅ Font scale: ekran daralanda (scroll lazım olanda) yazılar kiçilsin
//     //    (contentWidth-a bağlamırıq ki, binding loop olmasın)
//     // ============================================================
//     readonly property real _rightMostX: uploadButton.x + uploadButton.width + ScreenTools.defaultFontPixelWidth * 2
//     readonly property bool _needHScroll: _root.width < _rightMostX
//     readonly property real _fontScale: _needHScroll ? Math.max(0.75, _root.width / _rightMostX) : 1.0

//     // ============================================================
//     // ✅ RESPONSIVE: ekran daralanda toolbar horizontal scroll olacaq
//     // ============================================================
//     QGCFlickable {
//         id: barFlick
//         anchors.fill: parent
//         clip: true

//         flickableDirection: Flickable.HorizontalFlick
//         boundsBehavior: Flickable.StopAtBounds
//         interactive: contentWidth > width

//         contentHeight: height
//         contentWidth:  contentItemRoot.width

//         ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

//         Item {
//             id: contentItemRoot
//             height: barFlick.height

//             // childrenRect.x nəzərə alınsın deyə x+width
//             width: Math.max(barFlick.width,
//                             childrenRect.x + childrenRect.width + ScreenTools.defaultFontPixelWidth * 2)

//             // ------------------- UI -------------------

//             Rectangle {
//                 id: missionPlannerTitle
//                 x: 20
//                 y: parent.height / 2 - height / 2
//                 width: missionPlannerRow.width + 40
//                 height: 50
//                 color: "transparent"
//                 border.color: missionPlannerMouseArea.containsMouse ? "#555" : "transparent"
//                 border.width: 1
//                 radius: 4

//                 Row {
//                     id: missionPlannerRow
//                     anchors.centerIn: parent
//                     spacing: 12
//                     height: parent.height

//                     Image {
//                         id: missionPlannerIcon
//                         anchors.verticalCenter: parent.verticalCenter
//                         source: "file:///C:/Users/User/qgroundcontrol/resources/AZSHIELD_ICON/Home.svg"
//                         width: 32
//                         height: 32
//                         fillMode: Image.PreserveAspectFit

//                         Rectangle {
//                             anchors.fill: parent
//                             color: "#00ff00"
//                             visible: missionPlannerIcon.status === Image.Error
//                             radius: 4
//                             border.color: "#ffffff"
//                             border.width: 2

//                             QGCLabel {
//                                 anchors.centerIn: parent
//                                 text: "AZ"
//                                 font.pointSize: 12 * _fontScale
//                                 font.bold: true
//                                 color: "white"
//                             }
//                         }
//                     }

//                     QGCLabel {
//                         id: missionPlannerText
//                         anchors.verticalCenter: parent.verticalCenter
//                         text: "Missiya Planlama"
//                         font.pointSize: 18 * _fontScale
//                         font.bold: true
//                         color: missionPlannerMouseArea.containsMouse ? "#3D3B3B" : "white"
//                     }
//                 }

//                 QGCMouseArea {
//                     id: missionPlannerMouseArea
//                     anchors.fill: parent
//                     hoverEnabled: true
//                     cursorShape: Qt.PointingHandCursor
//                     onClicked: {
//                         if (mainWindow.allowViewSwitch()) {
//                             mainWindow.showFlyView()
//                         }
//                     }
//                 }
//             }

//             QGCLabel {
//                 x: 360
//                 y: parent.height / 2 - height / 2
//                 text: "Selected \nWayPoint:"
//                 font.pointSize: 14 * _fontScale
//                 color: "white"
//                 font.bold: true
//             }

//             QGCLabel { x: 500; y: 11;   text: "Alt diff:";  font.pointSize: 14 * _fontScale; color: "white" }
//             QGCLabel { x: 570; y: 11;   text: _altDifferenceText; font.pointSize: 14 * _fontScale; color: "white" }

//             QGCLabel { x: 500; y: 38.2; text: "Gradient:"; font.pointSize: 14 * _fontScale; color: "white" }
//             QGCLabel { x: 590; y: 38.2; text: _gradientText; font.pointSize: 14 * _fontScale; color: "white" }

//             QGCLabel { x: 670; y: 11;   text: "Azimuth:";  font.pointSize: 14 * _fontScale; color: "white" }
//             QGCLabel { x: 760; y: 11;   text: _azimuthText; font.pointSize: 14 * _fontScale; color: "white" }

//             QGCLabel { x: 670; y: 38.2; text: "Heading:";  font.pointSize: 14 * _fontScale; color: "white" }
//             QGCLabel { x: 760; y: 38.2; text: _headingText; font.pointSize: 14 * _fontScale; color: "white" }

//             QGCLabel {
//                 x: 835
//                 y: parent.height / 2 - height / 2
//                 text: "Dist prev \nWP:"
//                 font.pointSize: 14 * _fontScale
//                 color: "white"
//             }

//             QGCLabel {
//                 x: 930
//                 y: parent.height / 2 - height / 2
//                 text: _distanceText
//                 font.pointSize: 14 * _fontScale
//                 color: "white"
//             }

//             Rectangle {
//                 x: 1050
//                 y: 0.59
//                 width: 1
//                 height: parent.height
//                 color: "#333333"
//             }

//             QGCLabel {
//                 x: 1080
//                 y: parent.height / 2 - height / 2
//                 text: "Total \nMission:"
//                 font.pointSize: 14 * _fontScale
//                 color: "white"
//                 font.bold: true
//             }

//             QGCLabel { x: 1213.84; y: 12.84; text: "Distance:"; font.pointSize: 14 * _fontScale; color: "white" }
//             QGCLabel { x: 1310.5;  y: 12.84; text: _missionPlannedDistanceText; font.pointSize: 14 * _fontScale; color: "white" }

//             QGCLabel { x: 1213.81; y: 38.2;  text: "Time:"; font.pointSize: 14 * _fontScale; color: "white" }
//             QGCLabel { x: 1271;    y: 38.2;  text: getMissionTime(); font.pointSize: 14 * _fontScale; color: "white" }

//             QGCLabel {
//                 x: 1440
//                 y: parent.height / 2 - height / 2
//                 text: "Max telem \ndist:"
//                 font.pointSize: 14 * _fontScale
//                 color: "white"
//             }

//             QGCLabel {
//                 x: 1560
//                 y: 26.84
//                 text: _missionMaxTelemetryText
//                 font.pointSize: 14 * _fontScale
//                 color: "white"
//             }

//             Rectangle {
//                 id: uploadButton
//                 x: _controllerDirty ? 1665 : 1759.02
//                 y: 18.59
//                 width: _controllerDirty ? 220 : 101
//                 height: 41
//                 color: _controllerDirty ? "#E4EFFA" : "#B8B8B8"
//                 radius: 4
//                 border.color: "#555555"
//                 border.width: 1

//                 QGCLabel {
//                     anchors.centerIn: parent
//                     text: _controllerDirty ? "Yükləmə Tələb olunur" : "Yüklə"
//                     font.pointSize: 16 * _fontScale
//                     color: _controllerDirty ? "black" : "white"
//                 }

//                 QGCMouseArea {
//                     anchors.fill: parent
//                     cursorShape: Qt.PointingHandCursor
//                     hoverEnabled: true

//                     onClicked: {
//                         if (!_controllerOffline && !_controllerSyncInProgress && _containsItems) {
//                             if (_utmspEnabled) {
//                                 QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true)
//                             }
//                             planMasterController.upload()
//                         }
//                     }
//                 }

//                 PropertyAnimation on opacity {
//                     easing.type: Easing.OutQuart
//                     from: 0.5
//                     to: 1
//                     loops: Animation.Infinite
//                     running: _controllerDirty && !_controllerSyncInProgress
//                     alwaysRunToEnd: true
//                     duration: 2000
//                 }

//                 opacity: (!_controllerOffline && !_controllerSyncInProgress && _containsItems) ? 1.0 : 0.5
//             }
//         }
//     }

//     // Scroll-dan asılı olmayan alt separator
//     Rectangle {
//         z: 10
//         anchors.left:   parent.left
//         anchors.right:  parent.right
//         anchors.bottom: parent.bottom
//         height: 1
//         color: "#333333"
//     }

//     // ==================== Progress bars (sabit) ====================
//     Rectangle {
//         id:             progressBar
//         z:              20
//         anchors.left:   parent.left
//         anchors.bottom: parent.bottom
//         height:         4
//         width:          _controllerProgressPct * parent.width
//         color:          qgcPal.colorGreen
//         visible:        false

//         onVisibleChanged: {
//             if (visible) {
//                 largeProgressBar._userHide = false
//             }
//         }
//     }

//     Rectangle {
//         id:             largeProgressBar
//         z:              30
//         anchors.bottom: parent.bottom
//         anchors.left:   parent.left
//         anchors.right:  parent.right
//         height:         parent.height
//         color:          qgcPal.window
//         visible:        _showLargeProgress

//         property bool _userHide:          false
//         property bool _showLargeProgress: progressBar.visible && !_userHide && qgcPal.globalTheme === QGCPalette.Light

//         Connections {
//             target: QGroundControl.multiVehicleManager
//             function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
//         }

//         Rectangle {
//             anchors.top:    parent.top
//             anchors.bottom: parent.bottom
//             width:          _controllerProgressPct * parent.width
//             color:          qgcPal.colorGreen
//         }

//         QGCLabel {
//             anchors.centerIn: parent
//             text: qsTr("Syncing Mission")
//             font.pointSize: ScreenTools.largeFontPointSize
//             visible: _controllerProgressPct !== 1
//         }

//         QGCLabel {
//             anchors.centerIn: parent
//             text: qsTr("Done")
//             font.pointSize: ScreenTools.largeFontPointSize
//             visible: _controllerProgressPct === 1
//         }

//         QGCLabel {
//             anchors.margins: _margin
//             anchors.right: parent.right
//             anchors.bottom: parent.bottom
//             text: qsTr("Click anywhere to hide")
//             property real _margin: ScreenTools.defaultFontPixelWidth / 2
//         }

//         MouseArea {
//             anchors.fill: parent
//             onClicked: largeProgressBar._userHide = true
//         }
//     }

//     // ==================== Signals / Timers ====================
//     Connections {
//         target: planMasterController.missionController
//         function onProgressPctChanged(progressPct) {
//             if (progressPct === 1) {
//                 if (_root.visible) {
//                     resetProgressTimer.start()
//                 } else {
//                     progressBar.visible = false
//                 }
//             } else if (progressPct > 0) {
//                 progressBar.visible = true
//             }
//         }
//     }

//     Timer {
//         id: resetProgressTimer
//         interval: 3000
//         onTriggered: progressBar.visible = false
//     }

//     Connections {
//         target: _missionController
//         function onCurrentPlanViewItemChanged() { _currentMissionItem = _missionController.currentPlanViewItem }
//         function onMissionPlannedDistanceChanged() { _missionPlannedDistance = _missionController.missionPlannedDistance }
//         function onMissionTimeChanged() { _missionTime = _missionController.missionTime }
//         function onMissionMaxTelemetryChanged() { _missionMaxTelemetry = _missionController.missionMaxTelemetry }
//         function onVisualItemsChanged() {
//             _missionItemCount = _missionController.visualItems.count
//             _missionPlannedDistance = _missionController.missionPlannedDistance
//             _missionTime = _missionController.missionTime
//             _missionMaxTelemetry = _missionController.missionMaxTelemetry
//         }
//     }

//     Connections {
//         target: planMasterController
//         function onDirtyChanged() { _controllerDirty = planMasterController.dirty }
//         function onSyncInProgressChanged() { _controllerSyncInProgress = planMasterController.syncInProgress }
//         function onOfflineChanged() { _controllerOffline = planMasterController.offline }
//         function onContainsItemsChanged() { _containsItems = planMasterController.containsItems }
//     }

//     Component.onCompleted: {
//         if (_missionController) {
//             _missionPlannedDistance = _missionController.missionPlannedDistance
//             _missionTime = _missionController.missionTime
//             _missionMaxTelemetry = _missionController.missionMaxTelemetry
//             _missionItemCount = _missionController.visualItems.count
//         }
//     }
// }


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: _root
    width: parent.width
    height: ScreenTools.toolbarHeight
    color: qgcPal.toolbarBackground

    property var planMasterController

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _controllerProgressPct: planMasterController.missionController.progressPct

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "black"
        visible: qgcPal.globalTheme === QGCPalette.Light
    }

    QGCToolBarButton {
        id: qgcButton
        height: parent.height
        //icon.source: "file:///C:/Users/user/qgroundcontrol/resources/AZSHIELD_ICON/Home.svg"
        icon.source: "qrc:/res/AZSHIELD_ICON/Home.svg"
        logo: true
        onClicked: {
                        if (mainWindow.allowViewSwitch()) {
                            mainWindow.showFlyView()
                        }
        }
    }

    QGCFlickable {
        id: toolsFlickable
        anchors.bottomMargin: 1
        anchors.left: qgcButton.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        contentWidth: toolIndicators.width
        flickableDirection: Flickable.HorizontalFlick

        PlanToolBarIndicators {
            id: toolIndicators
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            planMasterController: _root.planMasterController
        }
    }

    // Small mission download progress bar
    Rectangle {
        id: progressBar
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: 4
        width: _controllerProgressPct * parent.width
        color: qgcPal.colorGreen
        visible: false

        onVisibleChanged: {
            if (visible) {
                largeProgressBar._userHide = false
            }
        }
    }

    // Large mission download progress bar
    Rectangle {
        id: largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height
        color: qgcPal.window
        visible: _showLargeProgress

        property bool _userHide: false
        property bool _showLargeProgress: progressBar.visible && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: _controllerProgressPct * parent.width
            color: qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn: parent
            text: qsTr("Syncing Mission")
            font.pointSize: ScreenTools.largeFontPointSize
            visible: _controllerProgressPct !== 1
        }

        QGCLabel {
            anchors.centerIn: parent
            text: qsTr("Done")
            font.pointSize: ScreenTools.largeFontPointSize
            visible: _controllerProgressPct === 1
        }

        QGCLabel {
            anchors.margins: _margin
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: qsTr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill: parent
            onClicked: largeProgressBar._userHide = true
        }
    }

    // Progress bar
    Connections {
        target: planMasterController.missionController

        function onProgressPctChanged(progressPct) {
            if (progressPct === 1) {
                if (_root.visible) {
                    resetProgressTimer.start()
                } else {
                    progressBar.visible = false
                }
            } else if (progressPct > 0) {
                progressBar.visible = true
            }
        }
    }

    Timer {
        id: resetProgressTimer
        interval: 3000
        onTriggered: progressBar.visible = false
    }
}

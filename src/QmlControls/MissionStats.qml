// // import QtQuick
// // import QtQuick.Controls
// // import QtQuick.Layouts
// // import QtQuick.Dialogs

// // import QGroundControl
// // import QGroundControl.Controls
// // import QGroundControl.FactControls
// // import QGroundControl.UTMSP

// // Rectangle {
// //     required property var planMasterController

// //     id: missionStats
// //     implicitWidth: mainLayout.implicitWidth + (_margins * 2)
// //     implicitHeight: mainLayout.implicitHeight + (_margins * 2)
// //     color: Qt.rgba(_windowColor.r, _windowColor.g, _windowColor.b, 0.8)

// //     property var _planMasterController: planMasterController
// //     property color _windowColor: QGroundControl.globalPalette.window
// //     property var _currentMissionItem: _planMasterController.missionController.currentPlanViewItem ///< Mission item to display status for

// //     property var missionItems: _controllerValid ? _planMasterController.missionController.visualItems : undefined
// //     property real missionPlannedDistance: _controllerValid ? _planMasterController.missionController.missionPlannedDistance : NaN
// //     property real missionTime: _controllerValid ? _planMasterController.missionController.missionTime : 0
// //     property real missionMaxTelemetry: _controllerValid ? _planMasterController.missionController.missionMaxTelemetry : NaN
// //     property bool _controllerValid: _planMasterController !== undefined && _planMasterController !== null

// //     property bool _currentMissionItemValid: _currentMissionItem && _currentMissionItem !== undefined && _currentMissionItem !== null
// //     property bool _currentItemIsVTOLTakeoff: _currentMissionItemValid && _currentMissionItem.command == 84
// //     property bool _missionValid: missionItems !== undefined

// //     property real _dataFontSize: ScreenTools.defaultFontPointSize
// //     property real _largeValueWidth: ScreenTools.defaultFontPixelWidth * 8
// //     property real _mediumValueWidth: ScreenTools.defaultFontPixelWidth * 4
// //     property real _smallValueWidth: ScreenTools.defaultFontPixelWidth * 3
// //     property real _labelToValueSpacing: ScreenTools.defaultFontPixelWidth
// //     property real _rowSpacing: ScreenTools.isMobile ? 1 : 0
// //     property real _distance: _currentMissionItemValid ? _currentMissionItem.distance : NaN
// //     property real _altDifference: _currentMissionItemValid ? _currentMissionItem.altDifference : NaN
// //     property real _azimuth: _currentMissionItemValid ? _currentMissionItem.azimuth : NaN
// //     property real _heading: _currentMissionItemValid ? _currentMissionItem.missionVehicleYaw : NaN
// //     property real _missionPlannedDistance: _missionValid ? missionPlannedDistance : NaN
// //     property real _missionMaxTelemetry: _missionValid ? missionMaxTelemetry : NaN
// //     property real _missionTime: _missionValid ? missionTime : 0
// //     property int _batteryChangePoint: _controllerValid ? _planMasterController.missionController.batteryChangePoint : -1
// //     property int _batteriesRequired: _controllerValid ? _planMasterController.missionController.batteriesRequired : -1
// //     property bool _batteryInfoAvailable: _batteryChangePoint >= 0 || _batteriesRequired >= 0
// //     property real _gradient: _currentMissionItemValid && _currentMissionItem.distance > 0 ?
// //                                                     (_currentItemIsVTOLTakeoff ?
// //                                                          0 : (Math.atan(_currentMissionItem.altDifference / _currentMissionItem.distance) * (180.0/Math.PI)))
// //                                                   : NaN

// //     property string _distanceText: isNaN(_distance) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_distance).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
// //     property string _altDifferenceText: isNaN(_altDifference) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altDifference).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
// //     property string _gradientText: isNaN(_gradient) ? "-.-" : _gradient.toFixed(0) + qsTr(" deg")
// //     property string _azimuthText: isNaN(_azimuth) ? "-.-" : Math.round(_azimuth) % 360
// //     property string _headingText: isNaN(_azimuth) ? "-.-" : Math.round(_heading) % 360
// //     property string _missionPlannedDistanceText: isNaN(_missionPlannedDistance) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPlannedDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
// //     property string _missionMaxTelemetryText: isNaN(_missionMaxTelemetry) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionMaxTelemetry).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
// //     property string _batteryChangePointText: _batteryChangePoint < 0 ? qsTr("N/A") : _batteryChangePoint
// //     property string _batteriesRequiredText: _batteriesRequired < 0 ? qsTr("N/A") : _batteriesRequired

// //     readonly property real _margins: ScreenTools.defaultFontPixelWidth

// //     function getMissionTime() {
// //         var totalSeconds = Number(_missionTime)
// //         if (!totalSeconds) {
// //             return "00:00:00"
// //         }

// //         var hours = Math.floor(totalSeconds / 3600)
// //         var minutes = Math.floor((totalSeconds % 3600) / 60)
// //         var seconds = Math.floor(totalSeconds % 60)

// //         var hoursText = hours < 10 ? "0" + hours : String(hours)
// //         var minutesText = minutes < 10 ? "0" + minutes : String(minutes)
// //         var secondsText = seconds < 10 ? "0" + seconds : String(seconds)

// //         return hoursText + ":" + minutesText + ":" + secondsText
// //     }

// //     QGCFlickable {
// //         anchors.margins: _margins
// //         anchors.fill: parent
// //         flickableDirection: Flickable.HorizontalFlick
// //         contentWidth: mainLayout.implicitWidth

// //         RowLayout {
// //             id: mainLayout
// //             spacing: ScreenTools.defaultFontPixelWidth * 2

// //             GridLayout {
// //                 columns: 8
// //                 rowSpacing: _rowSpacing
// //                 columnSpacing: _labelToValueSpacing

// //                 QGCLabel {
// //                     text: qsTr("Selected Waypoint")
// //                     Layout.columnSpan: 8
// //                     font.pointSize: ScreenTools.smallFontPointSize
// //                 }

// //                 QGCLabel { text: qsTr("Alt diff:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: _altDifferenceText
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _mediumValueWidth
// //                 }

// //                 Item { width: 1; height: 1 }

// //                 QGCLabel { text: qsTr("Azimuth:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: _azimuthText
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _smallValueWidth
// //                 }

// //                 Item { width: 1; height: 1 }

// //                 QGCLabel { text: qsTr("Dist prev WP:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: _distanceText
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _largeValueWidth
// //                 }

// //                 QGCLabel { text: qsTr("Gradient:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: _gradientText
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _mediumValueWidth
// //                 }

// //                 Item { width: 1; height: 1 }

// //                 QGCLabel { text: qsTr("Heading:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: _headingText
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _smallValueWidth
// //                 }
// //             }

// //             GridLayout {
// //                 columns: 5
// //                 rowSpacing: _rowSpacing
// //                 columnSpacing: _labelToValueSpacing

// //                 QGCLabel {
// //                     text: qsTr("Total Mission")
// //                     Layout.columnSpan: 5
// //                     font.pointSize: ScreenTools.smallFontPointSize
// //                 }

// //                 QGCLabel { text: qsTr("Distance:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: _missionPlannedDistanceText
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _largeValueWidth
// //                 }

// //                 Item { width: 1; height: 1 }

// //                 QGCLabel { text: qsTr("Max telem dist:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: _missionMaxTelemetryText
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _largeValueWidth
// //                 }

// //                 QGCLabel { text: qsTr("Time:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: getMissionTime()
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _largeValueWidth
// //                 }
// //             }

// //             GridLayout {
// //                 columns: 3
// //                 rowSpacing: _rowSpacing
// //                 columnSpacing: _labelToValueSpacing
// //                 visible: _batteryInfoAvailable

// //                 QGCLabel {
// //                     text: qsTr("Battery")
// //                     Layout.columnSpan: 3
// //                     font.pointSize: ScreenTools.smallFontPointSize
// //                 }

// //                 QGCLabel { text: qsTr("Batteries required:"); font.pointSize: _dataFontSize; }
// //                 QGCLabel {
// //                     text: _batteriesRequiredText
// //                     font.pointSize: _dataFontSize
// //                     Layout.minimumWidth: _mediumValueWidth
// //                 }
// //             }
// //         }
// //     }
// // }


// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts
// import QtQuick.Dialogs

// import QGroundControl
// import QGroundControl.Controls
// import QGroundControl.FactControls
// import QGroundControl.UTMSP

// Rectangle {
//     required property var planMasterController

//     id: missionStats
//     implicitWidth:  mainLayout.implicitWidth + (_margins * 2)
//     implicitHeight: mainLayout.implicitHeight + (_margins * 2)
//     color: Qt.rgba(_windowColor.r, _windowColor.g, _windowColor.b, 0.8)

//     property var   _planMasterController: planMasterController
//     property color _windowColor: QGroundControl.globalPalette.window
//     property var   _currentMissionItem: _planMasterController.missionController.currentPlanViewItem

//     property var  missionItems:         _controllerValid ? _planMasterController.missionController.visualItems : undefined
//     property real missionPlannedDistance:_controllerValid ? _planMasterController.missionController.missionPlannedDistance : NaN
//     property real missionTime:          _controllerValid ? _planMasterController.missionController.missionTime : 0
//     property real missionMaxTelemetry:  _controllerValid ? _planMasterController.missionController.missionMaxTelemetry : NaN
//     property bool _controllerValid:     _planMasterController !== undefined && _planMasterController !== null

//     property bool _currentMissionItemValid: _currentMissionItem && _currentMissionItem !== undefined && _currentMissionItem !== null
//     property bool _currentItemIsVTOLTakeoff: _currentMissionItemValid && _currentMissionItem.command == 84
//     property bool _missionValid: missionItems !== undefined

//     // =========================================================
//     // ✅ FONT / SEPARATOR SETTINGS (İstədiyiniz dəyişikliklər buradadır)
//     // =========================================================
//     readonly property real  _fontScale:        ScreenTools.isMobile ? 1.25 : 1.20
//     readonly property real  _headerFontSize:   ScreenTools.defaultFontPointSize * 1.10 * _fontScale
//     readonly property real  _labelFontSize:    ScreenTools.defaultFontPointSize * 1.00 * _fontScale
//     readonly property real  _valueFontSize:    ScreenTools.defaultFontPointSize * 1.10 * _fontScale

//     readonly property real  _separatorThickness: Math.max(1, Math.round(ScreenTools.defaultFontPixelHeight * 0.06))
//     readonly property color _separatorColor: Qt.rgba(QGroundControl.globalPalette.text.r,
//                                                      QGroundControl.globalPalette.text.g,
//                                                      QGroundControl.globalPalette.text.b,
//                                                      0.25)

//     // Layout spacing-lər (font böyüdüyü üçün bir az artırılıb)
//     property real _labelToValueSpacing: ScreenTools.defaultFontPixelWidth * 1.25
//     property real _rowSpacing:          ScreenTools.defaultFontPixelHeight * 0.35

//     // Value width-lər də böyüdülüb (clipping olmasın)
//     property real _largeValueWidth:  ScreenTools.defaultFontPixelWidth * (9  * _fontScale)
//     property real _mediumValueWidth: ScreenTools.defaultFontPixelWidth * (5  * _fontScale)
//     property real _smallValueWidth:  ScreenTools.defaultFontPixelWidth * (3.5* _fontScale)

//     property real _distance: _currentMissionItemValid ? _currentMissionItem.distance : NaN
//     property real _altDifference: _currentMissionItemValid ? _currentMissionItem.altDifference : NaN
//     property real _azimuth: _currentMissionItemValid ? _currentMissionItem.azimuth : NaN
//     property real _heading: _currentMissionItemValid ? _currentMissionItem.missionVehicleYaw : NaN
//     property real _missionPlannedDistance: _missionValid ? missionPlannedDistance : NaN
//     property real _missionMaxTelemetry: _missionValid ? missionMaxTelemetry : NaN
//     property real _missionTime: _missionValid ? missionTime : 0
//     property int  _batteryChangePoint: _controllerValid ? _planMasterController.missionController.batteryChangePoint : -1
//     property int  _batteriesRequired:  _controllerValid ? _planMasterController.missionController.batteriesRequired : -1
//     property bool _batteryInfoAvailable: _batteryChangePoint >= 0 || _batteriesRequired >= 0
//     property real _gradient: _currentMissionItemValid && _currentMissionItem.distance > 0 ?
//                                 (_currentItemIsVTOLTakeoff ? 0 :
//                                  (Math.atan(_currentMissionItem.altDifference / _currentMissionItem.distance) * (180.0/Math.PI)))
//                              : NaN

//     property string _distanceText: isNaN(_distance) ? "-.-"
//                             : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_distance).toFixed(1)
//                               + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
//     property string _altDifferenceText: isNaN(_altDifference) ? "-.-"
//                             : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altDifference).toFixed(1)
//                               + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
//     property string _gradientText: isNaN(_gradient) ? "-.-" : _gradient.toFixed(0) + qsTr(" deg")
//     property string _azimuthText:  isNaN(_azimuth) ? "-.-" : Math.round(_azimuth) % 360
//     property string _headingText:  isNaN(_azimuth) ? "-.-" : Math.round(_heading) % 360
//     property string _missionPlannedDistanceText: isNaN(_missionPlannedDistance) ? "-.-"
//                             : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPlannedDistance).toFixed(0)
//                               + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
//     property string _missionMaxTelemetryText: isNaN(_missionMaxTelemetry) ? "-.-"
//                             : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionMaxTelemetry).toFixed(0)
//                               + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
//     property string _batteryChangePointText: _batteryChangePoint < 0 ? qsTr("N/A") : _batteryChangePoint
//     property string _batteriesRequiredText:  _batteriesRequired < 0  ? qsTr("N/A") : _batteriesRequired

//     readonly property real _margins: ScreenTools.defaultFontPixelWidth

//     function getMissionTime() {
//         var totalSeconds = Number(_missionTime)
//         if (!totalSeconds) {
//             return "00:00:00"
//         }

//         var hours   = Math.floor(totalSeconds / 3600)
//         var minutes = Math.floor((totalSeconds % 3600) / 60)
//         var seconds = Math.floor(totalSeconds % 60)

//         var hoursText   = hours   < 10 ? "0" + hours   : String(hours)
//         var minutesText = minutes < 10 ? "0" + minutes : String(minutes)
//         var secondsText = seconds < 10 ? "0" + seconds : String(seconds)

//         return hoursText + ":" + minutesText + ":" + secondsText
//     }

//     QGCFlickable {
//         anchors.margins: _margins
//         anchors.fill: parent
//         flickableDirection: Flickable.HorizontalFlick
//         contentWidth: mainLayout.implicitWidth

//         RowLayout {
//             id: mainLayout
//             spacing: ScreenTools.defaultFontPixelWidth * 1.5

//             // =========================================================
//             // Selected Waypoint
//             // =========================================================
//             GridLayout {
//                 columns: 8
//                 rowSpacing: _rowSpacing
//                 columnSpacing: _labelToValueSpacing

//                 QGCLabel {
//                     text: qsTr("Selected Waypoint")
//                     Layout.columnSpan: 8
//                     font.pointSize: _headerFontSize
//                     font.bold: true
//                 }

//                 // ✅ Nazik xətt (section içi)
//                 Rectangle {
//                     Layout.columnSpan: 8
//                     Layout.fillWidth: true
//                     height: _separatorThickness
//                     color: _separatorColor
//                 }

//                 QGCLabel { text: qsTr("Alt diff:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: _altDifferenceText
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _mediumValueWidth
//                 }

//                 Item { width: 1; height: 1 }

//                 QGCLabel { text: qsTr("Azimuth:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: _azimuthText
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _smallValueWidth
//                 }

//                 Item { width: 1; height: 1 }

//                 QGCLabel { text: qsTr("Dist prev WP:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: _distanceText
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _largeValueWidth
//                 }

//                 QGCLabel { text: qsTr("Gradient:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: _gradientText
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _mediumValueWidth
//                 }

//                 Item { width: 1; height: 1 }

//                 QGCLabel { text: qsTr("Heading:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: _headingText
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _smallValueWidth
//                 }
//             }

//             // ✅ Section-lar arası nazik VERTICAL xətt
//             Rectangle {
//                 width: _separatorThickness
//                 Layout.fillHeight: true
//                 color: _separatorColor
//             }

//             // =========================================================
//             // Total Mission
//             // =========================================================
//             GridLayout {
//                 columns: 5
//                 rowSpacing: _rowSpacing
//                 columnSpacing: _labelToValueSpacing

//                 QGCLabel {
//                     text: qsTr("Total Mission")
//                     Layout.columnSpan: 5
//                     font.pointSize: _headerFontSize
//                     font.bold: true
//                 }

//                 // ✅ Nazik xətt (section içi)
//                 Rectangle {
//                     Layout.columnSpan: 5
//                     Layout.fillWidth: true
//                     height: _separatorThickness
//                     color: _separatorColor
//                 }

//                 QGCLabel { text: qsTr("Distance:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: _missionPlannedDistanceText
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _largeValueWidth
//                 }

//                 Item { width: 1; height: 1 }

//                 QGCLabel { text: qsTr("Max telem dist:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: _missionMaxTelemetryText
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _largeValueWidth
//                 }

//                 QGCLabel { text: qsTr("Time:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: getMissionTime()
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _largeValueWidth
//                 }
//             }

//             // ✅ Battery bölməsi yoxdursa, separator da görünməsin
//             Rectangle {
//                 width: _separatorThickness
//                 Layout.fillHeight: true
//                 color: _separatorColor
//                 visible: _batteryInfoAvailable
//             }

//             // =========================================================
//             // Battery
//             // =========================================================
//             GridLayout {
//                 columns: 3
//                 rowSpacing: _rowSpacing
//                 columnSpacing: _labelToValueSpacing
//                 visible: _batteryInfoAvailable

//                 QGCLabel {
//                     text: qsTr("Battery")
//                     Layout.columnSpan: 3
//                     font.pointSize: _headerFontSize
//                     font.bold: true
//                 }

//                 // ✅ Nazik xətt (section içi)
//                 Rectangle {
//                     Layout.columnSpan: 3
//                     Layout.fillWidth: true
//                     height: _separatorThickness
//                     color: _separatorColor
//                 }

//                 QGCLabel { text: qsTr("Batteries required:"); font.pointSize: _labelFontSize }
//                 QGCLabel {
//                     text: _batteriesRequiredText
//                     font.pointSize: _valueFontSize
//                     font.bold: true
//                     Layout.minimumWidth: _mediumValueWidth
//                 }
//             }
//         }
//     }
// }


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.UTMSP

Rectangle {
    required property var planMasterController

    id: missionStats

    // ✅ Panel eni bir az dar olsun (maksimum limit)
    readonly property real _maxStatsWidth: ScreenTools.defaultFontPixelWidth * (ScreenTools.isMobile ? 72 : 95)

    implicitWidth:  mainLayout.implicitWidth + (_margins * 2)
    implicitHeight: mainLayout.implicitHeight + (_margins * 2)



    color: Qt.rgba(_windowColor.r, _windowColor.g, _windowColor.b, 0.8)

    property var   _planMasterController: planMasterController
    property color _windowColor: QGroundControl.globalPalette.window
    property var   _currentMissionItem: _planMasterController.missionController.currentPlanViewItem

    property var  missionItems:         _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property real missionPlannedDistance:_controllerValid ? _planMasterController.missionController.missionPlannedDistance : NaN
    property real missionTime:          _controllerValid ? _planMasterController.missionController.missionTime : 0
    property real missionMaxTelemetry:  _controllerValid ? _planMasterController.missionController.missionMaxTelemetry : NaN
    property bool _controllerValid:     _planMasterController !== undefined && _planMasterController !== null

    property bool _currentMissionItemValid: _currentMissionItem && _currentMissionItem !== undefined && _currentMissionItem !== null
    property bool _currentItemIsVTOLTakeoff: _currentMissionItemValid && _currentMissionItem.command == 84
    property bool _missionValid: missionItems !== undefined

    // =========================================================
    // ✅ FONT / SEPARATOR SETTINGS
    // =========================================================
    readonly property real _vSepWidth: _separatorThickness
    readonly property real _hSepHeight: _separatorThickness


    readonly property real  _fontScale:        ScreenTools.isMobile ? 1.25 : 1.20
    readonly property real  _headerFontSize:   ScreenTools.defaultFontPointSize * 1.10 * _fontScale
    readonly property real  _labelFontSize:    ScreenTools.defaultFontPointSize * 1.00 * _fontScale
    readonly property real  _valueFontSize:    ScreenTools.defaultFontPointSize * 1.10 * _fontScale

    readonly property real  _separatorThickness: Math.max(1, Math.round(ScreenTools.defaultFontPixelHeight * 0.06))
    readonly property color _separatorColor: Qt.rgba(QGroundControl.globalPalette.text.r,
                                                     QGroundControl.globalPalette.text.g,
                                                     QGroundControl.globalPalette.text.b,
                                                     0.25)

    // ✅ Cədvəl görkəmi üçün
    readonly property real _cellVMargin: ScreenTools.defaultFontPixelHeight * 0.18
    readonly property real _valueColMinWidth: ScreenTools.defaultFontPixelWidth * (ScreenTools.isMobile ? 14 : 16)

    // Section-lar arası spacing
    readonly property real _sectionSpacing: ScreenTools.defaultFontPixelWidth * 1.1

    // ✅ Stats bitəndən sonra boşluq
    readonly property real _endPadding: ScreenTools.defaultFontPixelWidth * 3.0

    property real _distance: _currentMissionItemValid ? _currentMissionItem.distance : NaN
    property real _altDifference: _currentMissionItemValid ? _currentMissionItem.altDifference : NaN
    property real _azimuth: _currentMissionItemValid ? _currentMissionItem.azimuth : NaN
    property real _heading: _currentMissionItemValid ? _currentMissionItem.missionVehicleYaw : NaN
    property real _missionPlannedDistance: _missionValid ? missionPlannedDistance : NaN
    property real _missionMaxTelemetry: _missionValid ? missionMaxTelemetry : NaN
    property real _missionTime: _missionValid ? missionTime : 0
    property int  _batteryChangePoint: _controllerValid ? _planMasterController.missionController.batteryChangePoint : -1
    property int  _batteriesRequired:  _controllerValid ? _planMasterController.missionController.batteriesRequired : -1
    property bool _batteryInfoAvailable: _batteryChangePoint >= 0 || _batteriesRequired >= 0

    property real _gradient: _currentMissionItemValid && _currentMissionItem.distance > 0 ?
                                (_currentItemIsVTOLTakeoff ? 0 :
                                 (Math.atan(_currentMissionItem.altDifference / _currentMissionItem.distance) * (180.0/Math.PI)))
                             : NaN

    property string _distanceText: isNaN(_distance) ? "-.-"
                            : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_distance).toFixed(1)
                              + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _altDifferenceText: isNaN(_altDifference) ? "-.-"
                            : QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altDifference).toFixed(1)
                              + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
    property string _gradientText: isNaN(_gradient) ? "-.-" : _gradient.toFixed(0) + qsTr(" deg")
    property string _azimuthText:  isNaN(_azimuth) ? "-.-" : Math.round(_azimuth) % 360

    // ✅ Kiçik fix: heading NaN yoxlaması
    property string _headingText:  isNaN(_heading) ? "-.-" : Math.round(_heading) % 360

    property string _missionPlannedDistanceText: isNaN(_missionPlannedDistance) ? "-.-"
                            : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPlannedDistance).toFixed(0)
                              + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _missionMaxTelemetryText: isNaN(_missionMaxTelemetry) ? "-.-"
                            : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionMaxTelemetry).toFixed(0)
                              + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property string _batteryChangePointText: _batteryChangePoint < 0 ? qsTr("N/A") : _batteryChangePoint
    property string _batteriesRequiredText:  _batteriesRequired < 0  ? qsTr("N/A") : _batteriesRequired

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    function getMissionTime() {
        var totalSeconds = Number(_missionTime)
        if (!totalSeconds) {
            return "00:00:00"
        }

        var hours   = Math.floor(totalSeconds / 3600)
        var minutes = Math.floor((totalSeconds % 3600) / 60)
        var seconds = Math.floor(totalSeconds % 60)

        var hoursText   = hours   < 10 ? "0" + hours   : String(hours)
        var minutesText = minutes < 10 ? "0" + minutes : String(minutes)
        var secondsText = seconds < 10 ? "0" + seconds : String(seconds)

        return hoursText + ":" + minutesText + ":" + secondsText
    }

    QGCFlickable {
        anchors.margins: _margins
        anchors.fill: parent
        flickableDirection: Flickable.HorizontalFlick
        contentWidth: mainLayout.implicitWidth

        interactive: contentWidth > width
        RowLayout {
            id: mainLayout
            spacing: _sectionSpacing

            // =========================================================
            // Selected Waypoint (Table format)
            // =========================================================
            GridLayout {
                // L1 | V1 | L2 | V2 üçün 3 vertical xətt sütunu
                columns: 7
                rowSpacing: 0
                columnSpacing: 0

                // Header
                QGCLabel {
                    text: qsTr("Seçilmiş Waypoint")
                    Layout.columnSpan: 7
                    font.pointSize: _headerFontSize
                    font.bold: true
                }

                // Header altı xətt
                Rectangle {
                    Layout.columnSpan: 7
                    Layout.fillWidth: true
                    height: _hSepHeight
                    color: _separatorColor
                }

                // --- ROW 1: Alt diff | Azimuth
                QGCLabel { text: qsTr("Alt diff:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }   // L1-V1
                QGCLabel { text: _altDifferenceText; font.pointSize: _valueFontSize; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.minimumWidth: _valueColMinWidth; Layout.margins: _cellVMargin }

                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }   // V1-L2 (mərkəz)
                QGCLabel { text: qsTr("Azimuth:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }   // L2-V2
                QGCLabel { text: _azimuthText; font.pointSize: _valueFontSize; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.minimumWidth: _valueColMinWidth; Layout.margins: _cellVMargin }

                Rectangle { Layout.columnSpan: 7; Layout.fillWidth: true; height: _hSepHeight; color: _separatorColor } // row altı

                // --- ROW 2: Dist prev WP | Gradient
                QGCLabel { text: qsTr("Dist prev WP:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel { text: _distanceText; font.pointSize: _valueFontSize; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.minimumWidth: _valueColMinWidth; Layout.margins: _cellVMargin }

                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel { text: qsTr("Gradient:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel { text: _gradientText; font.pointSize: _valueFontSize; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.minimumWidth: _valueColMinWidth; Layout.margins: _cellVMargin }

                Rectangle { Layout.columnSpan: 7; Layout.fillWidth: true; height: _hSepHeight; color: _separatorColor }

                // --- ROW 3: Heading | (boş)
                QGCLabel { text: qsTr("Heading:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel { text: _headingText; font.pointSize: _valueFontSize; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.minimumWidth: _valueColMinWidth; Layout.margins: _cellVMargin }

                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                Item { }      // L2 boş
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                Item { }      // V2 boş
            }

            // ✅ Section-lar arası nazik VERTICAL xətt
            Rectangle {
                width: _separatorThickness
                Layout.fillHeight: true
                color: _separatorColor
            }

            // =========================================================
            // Total Mission (Table format)
            // =========================================================
            GridLayout {
                columns: 7
                rowSpacing: 0
                columnSpacing: 0

                QGCLabel {
                    text: qsTr("Ümumi Missiya")
                    Layout.columnSpan: 7
                    font.pointSize: _headerFontSize
                    font.bold: true
                }

                Rectangle {
                    Layout.columnSpan: 7
                    Layout.fillWidth: true
                    height: _hSepHeight
                    color: _separatorColor
                }

                // Row 1: Distance | Max telem dist
                QGCLabel { text: qsTr("Məsafə:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel { text: _missionPlannedDistanceText; font.pointSize: _valueFontSize; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.minimumWidth: _valueColMinWidth; Layout.margins: _cellVMargin }

                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel { text: qsTr("Max telem dist:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel { text: _missionMaxTelemetryText; font.pointSize: _valueFontSize; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.minimumWidth: _valueColMinWidth; Layout.margins: _cellVMargin }

                Rectangle { Layout.columnSpan: 7; Layout.fillWidth: true; height: _hSepHeight; color: _separatorColor }

                // Row 2: Time | (boş)
                QGCLabel { text: qsTr("Vaxt:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel { text: getMissionTime(); font.pointSize: _valueFontSize; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.minimumWidth: _valueColMinWidth; Layout.margins: _cellVMargin }

                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                Item { }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                Item { }
            }

            // ✅ Battery bölməsi yoxdursa, separator da görünməsin
            Rectangle {
                width: _separatorThickness
                Layout.fillHeight: true
                color: _separatorColor
                visible: _batteryInfoAvailable
            }

            // =========================================================
            // Battery (Table format)
            // =========================================================
            GridLayout {
                columns: 3
                rowSpacing: 0
                columnSpacing: 0
                visible: _batteryInfoAvailable

                QGCLabel {
                    text: qsTr("Batareya")
                    Layout.columnSpan: 3
                    font.pointSize: _headerFontSize
                    font.bold: true
                }

                Rectangle {
                    Layout.columnSpan: 3
                    Layout.fillWidth: true
                    height: _hSepHeight
                    color: _separatorColor
                }

                QGCLabel { text: qsTr("Tələb olunan batareyalar:"); font.pointSize: _labelFontSize; Layout.margins: _cellVMargin }
                Rectangle { width: _vSepWidth; Layout.fillHeight: true; color: _separatorColor }
                QGCLabel {
                    text: _batteriesRequiredText
                    font.pointSize: _valueFontSize
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    Layout.minimumWidth: _valueColMinWidth
                    Layout.margins: _cellVMargin
                }
            }

            // ✅ Stats bitəndən sonra boşluq (scroll-un sonunda “hava” olsun)
            // Item {
            //     implicitWidth: _endPadding
            //     implicitHeight: 1
            // }
        }
    }
}

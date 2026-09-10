// // /****************************************************************************
// //  *
// //  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
// //  *
// //  * QGroundControl is licensed according to the terms in the file
// //  * COPYING.md in the root of the source code directory.
// //  *
// //  ****************************************************************************/

// // import QtQuick
// // import QtQuick.Layouts
// // import QtQuick.Controls

// // import QGroundControl
// // import QGroundControl.Controls

// // ColumnLayout {
// //     property var    instrumentValueData:            null
// //     property bool   settingsUnlocked:               false
// //     property alias  contentWidth:                   label.contentWidth
// //     property real   _uniformFontSize:               _root ? _root.uniformFontSize : 11

// //     property var    _rgFontSizes:                   [ ScreenTools.defaultFontPointSize, ScreenTools.smallFontPointSize, ScreenTools.mediumFontPointSize, ScreenTools.largeFontPointSize ]
// //     property var    _rgFontSizeRatios:              [ 1, ScreenTools.smallFontPointRatio, ScreenTools.mediumFontPointRatio, ScreenTools.largeFontPointRatio ]
// //     property real   _doubleDescent:                 ScreenTools.defaultFontDescent * 2
// //     property real   _tightDefaultFontHeight:        ScreenTools.defaultFontPixelHeight - _doubleDescent
// //     property var    _rgFontSizeTightHeights:        [ _tightDefaultFontHeight * _rgFontSizeRatios[0] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[1] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[2] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[3] + 2 ]
// //     property real   _tightHeight:                   _rgFontSizeTightHeights[instrumentValueData.factValueGrid.fontSize]
// //     property real   _fontSize:                      _rgFontSizes[instrumentValueData.factValueGrid.fontSize]
// //     property real   _horizontalLabelSpacing:        ScreenTools.defaultFontPixelWidth
// //     property real   _width:                         0
// //     property real   _height:                        0

// //     // Value için dikdörtgen container
// //     Rectangle {
// //         id: valueContainer
// //        // Layout.fillWidth: true
// //         Layout.fillWidth: false
// //                 readonly property int horizontalPadding: 8
// //                 Layout.preferredWidth: label.contentWidth + horizontalPadding * 2
// //                 implicitWidth: label.contentWidth + horizontalPadding * 2
// //         Layout.preferredHeight: _tightHeight + 5
// //         Layout.topMargin: 1.5
// //         Layout.bottomMargin: 1.5
// //         Layout.leftMargin: 1  // ← Sola 5px boşluk eklendi
// //         color: "transparent"
// //         border.color: instrumentValueData.isValidColor(instrumentValueData.currentColor) ? instrumentValueData.currentColor : qgcPal.text
// //         border.width: 1
// //         radius: 3
// //         opacity: instrumentValueData.currentOpacity * 1

// //         // Value label'ı - dikdörtgen içinde
// //         QGCLabel {
// //             id: label
// //             anchors.centerIn: parent
// //             anchors.verticalCenterOffset: -1
// //             font.pointSize: _fontSize
// //             color: "#FFFFFF"
// //             text: valueText()
// //             font.pixelSize: 14

// //             function valueText() {
// //                 if (instrumentValueData.fact) {
// //                     return instrumentValueData.fact.enumOrValueString + (instrumentValueData.showUnits ? " " + instrumentValueData.fact.units : "")
// //                 } else {
// //                     return qsTr("--.--")
// //                 }
// //             }
// //         }

// //         // Value altı çizgisi - dikdörtgenin içinde
// //         Rectangle {
// //             anchors.left: parent.left
// //             anchors.right: parent.right
// //             anchors.bottom: parent.bottom
// //             height: 1
// //             color: instrumentValueData.isValidColor(instrumentValueData.currentColor) ? instrumentValueData.currentColor : qgcPal.text
// //             opacity: instrumentValueData.currentOpacity * 0.5
// //         }
// //     }
// // }

// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

ColumnLayout {
    property var    instrumentValueData:            null
    property bool   settingsUnlocked:               false
    property real   contentWidth:                   100  // SABİT genişlik
    property real   _uniformFontSize:               (_root && _root.uniformFontSize !== undefined) ? _root.uniformFontSize : 11

    property var    _rgFontSizes:                   [ ScreenTools.defaultFontPointSize, ScreenTools.smallFontPointSize, ScreenTools.mediumFontPointSize, ScreenTools.largeFontPointSize ]
    property var    _rgFontSizeRatios:              [ 1, ScreenTools.smallFontPointRatio, ScreenTools.mediumFontPointRatio, ScreenTools.largeFontPointRatio ]
    property real   _doubleDescent:                 ScreenTools.defaultFontDescent * 2
    property real   _tightDefaultFontHeight:        ScreenTools.defaultFontPixelHeight - _doubleDescent
    property var    _rgFontSizeTightHeights:        [ _tightDefaultFontHeight * _rgFontSizeRatios[0] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[1] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[2] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[3] + 2 ]
    property real   _tightHeight:                   _rgFontSizeTightHeights[instrumentValueData.factValueGrid.fontSize]
    property real   _fontSize:                      _rgFontSizes[instrumentValueData.factValueGrid.fontSize]
    property real   _horizontalLabelSpacing:        ScreenTools.defaultFontPixelWidth

    // Value için dikdörtgen container
    Rectangle {
        id: valueContainer
        Layout.fillWidth: true
        Layout.preferredHeight: _tightHeight + 5
        Layout.topMargin: 1.5
        Layout.bottomMargin: 1.5
        Layout.leftMargin: 1
        color: "transparent"
        border.color: instrumentValueData.isValidColor(instrumentValueData.currentColor) ? instrumentValueData.currentColor : qgcPal.text
        border.width: 1
        radius: 3
        opacity: instrumentValueData.currentOpacity * 1

        // Value label'ı - dikdörtgen içinde
        Text {
            id: label
            anchors.fill: parent
            anchors.margins: 2
            color: "#FFFFFF"
            text: valueText()
            font.pixelSize: 14
            font.family: ScreenTools.normalFontFamily
            antialiasing: true
            elide: Text.ElideRight  // Uzun text'leri ... ile kısalt

            function valueText() {
                if (instrumentValueData.fact) {
                    return instrumentValueData.fact.enumOrValueString + (instrumentValueData.showUnits ? " " + instrumentValueData.fact.units : "")
                } else {
                    return qsTr("--.--")
                }
            }
        }

        // Value altı çizgisi - dikdörtgenin içinde
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: instrumentValueData.isValidColor(instrumentValueData.currentColor) ? instrumentValueData.currentColor : qgcPal.text
            opacity: instrumentValueData.currentOpacity * 0.5
        }
    }
}






// import QtQuick
// import QtQuick.Layouts

// import QGroundControl
// import QGroundControl.Controls

// Item {
//     id: root
//     property var instrumentValueData: null

//     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

//     readonly property int _fontIndex: {
//         if (!instrumentValueData || !instrumentValueData.factValueGrid) return 0
//         var i = instrumentValueData.factValueGrid.fontSize
//         return Math.max(0, Math.min(3, i))
//     }

//     readonly property var  _rgFontSizes:  [ ScreenTools.defaultFontPointSize, ScreenTools.smallFontPointSize, ScreenTools.mediumFontPointSize, ScreenTools.largeFontPointSize ]
//     readonly property real _fontPt:       _rgFontSizes[_fontIndex]

//     readonly property real _cellH: Math.max(22, ScreenTools.defaultFontPixelHeight * 1.55)

//     implicitHeight: _cellH
//     implicitWidth:  _cellH * 3.2

//     readonly property color _borderColor: {
//         if (instrumentValueData && instrumentValueData.isValidColor && instrumentValueData.isValidColor(instrumentValueData.currentColor)) {
//             return instrumentValueData.currentColor
//         }
//         return qgcPal.text
//     }

//     readonly property real _op: instrumentValueData ? instrumentValueData.currentOpacity : 1.0

//     readonly property string _valueText: {
//         if (instrumentValueData && instrumentValueData.fact) {
//             var t = instrumentValueData.fact.enumOrValueString
//             if (instrumentValueData.showUnits && instrumentValueData.fact.units && instrumentValueData.fact.units !== "") {
//                 t += " " + instrumentValueData.fact.units
//             }
//             return t
//         }
//         return qsTr("--.--")
//     }

//     Rectangle {
//         id: valueContainer
//         anchors.fill: parent
//         radius: 3
//         color: "transparent"
//         border.color: _borderColor
//         border.width: 1
//         opacity: _op
//         clip: true

//         Text {
//             id: valueTextItem
//             anchors.fill: parent
//             anchors.margins: 4

//             text: _valueText
//             color: "white"

//             // ✅ Fit: dəyər kəsilməsin
//             font.pointSize: _fontPt
//             fontSizeMode: Text.Fit
//             minimumPointSize: Math.max(7, _fontPt - 4)

//             verticalAlignment: Text.AlignVCenter
//             horizontalAlignment: Text.AlignLeft
//             wrapMode: Text.NoWrap
//             elide: Text.ElideNone
//         }

//         Rectangle {
//             anchors.left: parent.left
//             anchors.right: parent.right
//             anchors.bottom: parent.bottom
//             height: 1
//             color: _borderColor
//             opacity: _op * 0.5
//         }
//     }
// }






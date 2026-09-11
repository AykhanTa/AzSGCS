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
// //     property var    instrumentValueData:        null

// //     property var    _rgFontSizes:               [ ScreenTools.defaultFontPointSize, ScreenTools.smallFontPointSize, ScreenTools.mediumFontPointSize, ScreenTools.largeFontPointSize ]
// //     property var    _rgFontSizeRatios:          [ 1, ScreenTools.smallFontPointRatio, ScreenTools.mediumFontPointRatio, ScreenTools.largeFontPointRatio ]
// //     property real   _doubleDescent:             ScreenTools.defaultFontDescent * 2
// //     property real   _tightDefaultFontHeight:    ScreenTools.defaultFontPixelHeight - _doubleDescent
// //     property var    _rgFontSizeTightHeights:    [ _tightDefaultFontHeight * _rgFontSizeRatios[0] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[1] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[2] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[3] + 2 ]
// //     property real   _tightHeight:               _rgFontSizeTightHeights[instrumentValueData.factValueGrid.fontSize]
// //     property bool   _iconVisible:               instrumentValueData.rangeType === InstrumentValueData.IconSelectRange || instrumentValueData.icon
// //     property var    _color:                     instrumentValueData.isValidColor(instrumentValueData.currentColor) ? instrumentValueData.currentColor : qgcPal.text

// //     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

// //     // Icon için container
// //     ColumnLayout {
// //         visible: _iconVisible
// //         spacing: 2

// //         // Icon ve : işareti
// //         RowLayout {
// //             spacing: 0
// //             Layout.leftMargin: 15

// //             QGCColoredImage {
// //                 id:                         valueIcon
// //                 Layout.alignment:           Qt.AlignVCenter
// //                 height:                     _tightHeight * 0.75
// //                 width:                      _tightHeight * 0.85
// //                 sourceSize.height:          height
// //                 fillMode:                   Image.PreserveAspectFit
// //                 mipmap:                     true
// //                 smooth:                     true
// //                 color:                      _color
// //                 opacity:                    instrumentValueData.currentOpacity

// //                 readonly property string iconPrefix: "/InstrumentValueIcons/"

// //                 function updateIcon() {
// //                     if (instrumentValueData.rangeType === InstrumentValueData.IconSelectRange) {
// //                         valueIcon.source = instrumentValueData.currentIcon != "" ? iconPrefix + instrumentValueData.currentIcon : "";
// //                     } else if (instrumentValueData.icon) {
// //                         valueIcon.source = instrumentValueData.icon != "" ? iconPrefix + instrumentValueData.icon : "";
// //                     } else {
// //                         valueIcon.source = ""
// //                     }
// //                 }

// //                 Connections {
// //                     target:                 instrumentValueData
// //                     function onRangeTypeChanged() { valueIcon.updateIcon() }
// //                     function onCurrentIconChanged() { valueIcon.updateIcon() }
// //                     function onIconChanged() { valueIcon.updateIcon() }
// //                 }
// //                 Component.onCompleted:      updateIcon();
// //             }

// //             QGCLabel {
// //                 Layout.alignment: Qt.AlignVCenter
// //                 text: ": "
// //                 color: _color
// //                 opacity: instrumentValueData.currentOpacity
// //                 font.pixelSize: 14
// //                 visible: valueIcon.source != ""
// //             }
// //         }

// //         // Icon altı çizgisi
// //         Rectangle {
// //             Layout.fillWidth: true
// //             Layout.leftMargin: 15
// //             height: 1
// //             color: _color
// //             opacity: instrumentValueData.currentOpacity * 0.5
// //         }
// //     }

// //     // Label için container
// //     ColumnLayout {
// //         visible: !_iconVisible
// //         spacing: 2

// //         QGCLabel {
// //             id: labelText
// //             Layout.alignment:   Qt.AlignVCenter
// //             Layout.fillWidth:   true
// //             Layout.leftMargin:  15
// //             height:             _tightHeight
// //             font.pointSize:     ScreenTools.smallFontPointSize
// //             text:               instrumentValueData.text + ": "
// //             color:              _color
// //             opacity:            instrumentValueData.currentOpacity
// //             font.pixelSize:     14
// //             horizontalAlignment: Text.AlignLeft
// //         }

// //         // Label altı çizgisi
// //         Rectangle {
// //             Layout.fillWidth: true
// //             Layout.leftMargin: 15
// //             height: 1
// //             color: _color
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
    property var    instrumentValueData:        null
    property real   labelWidth:                 labelText ? (labelText.implicitWidth + 15) : 0

    property var    _rgFontSizes:               [ ScreenTools.defaultFontPointSize, ScreenTools.smallFontPointSize, ScreenTools.mediumFontPointSize, ScreenTools.largeFontPointSize ]
    property var    _rgFontSizeRatios:          [ 1, ScreenTools.smallFontPointRatio, ScreenTools.mediumFontPointRatio, ScreenTools.largeFontPointRatio ]
    property real   _doubleDescent:             ScreenTools.defaultFontDescent * 2
    property real   _tightDefaultFontHeight:    ScreenTools.defaultFontPixelHeight - _doubleDescent
    property var    _rgFontSizeTightHeights:    [ _tightDefaultFontHeight * _rgFontSizeRatios[0] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[1] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[2] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[3] + 2 ]
    property real   _tightHeight:               _rgFontSizeTightHeights[instrumentValueData.factValueGrid.fontSize]
    property bool   _iconVisible:               instrumentValueData.rangeType === InstrumentValueData.IconSelectRange || instrumentValueData.icon
    property var    _color:                     instrumentValueData.isValidColor(instrumentValueData.currentColor) ? instrumentValueData.currentColor : qgcPal.text

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    // Icon için container
    ColumnLayout {
        visible: _iconVisible
        spacing: 2

        // Icon ve : işareti
        RowLayout {
            spacing: 0
            Layout.leftMargin: 15

            QGCColoredImage {
                id:                         valueIcon
                Layout.alignment:           Qt.AlignVCenter
                height:                     _tightHeight * 0.75
                width:                      _tightHeight * 0.85
                sourceSize.height:          height
                fillMode:                   Image.PreserveAspectFit
                mipmap:                     true
                smooth:                     true
                color:                      _color
                opacity:                    instrumentValueData.currentOpacity

                readonly property string iconPrefix: "/InstrumentValueIcons/"

                function updateIcon() {
                    if (instrumentValueData.rangeType === InstrumentValueData.IconSelectRange) {
                        valueIcon.source = instrumentValueData.currentIcon != "" ? iconPrefix + instrumentValueData.currentIcon : "";
                    } else if (instrumentValueData.icon) {
                        valueIcon.source = instrumentValueData.icon != "" ? iconPrefix + instrumentValueData.icon : "";
                    } else {
                        valueIcon.source = ""
                    }
                }

                Connections {
                    target:                 instrumentValueData
                    function onRangeTypeChanged() { valueIcon.updateIcon() }
                    function onCurrentIconChanged() { valueIcon.updateIcon() }
                    function onIconChanged() { valueIcon.updateIcon() }
                }
                Component.onCompleted:      updateIcon();
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: ": "
                color: _color
                opacity: instrumentValueData.currentOpacity
                font.pixelSize: 14
                font.family: ScreenTools.normalFontFamily
                antialiasing: true
                visible: valueIcon.source != ""
            }
        }

        // Icon altı çizgisi
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 15
            height: 1
            color: _color
            opacity: instrumentValueData.currentOpacity * 0.5
        }
    }

    // Label için container
    ColumnLayout {
        visible: !_iconVisible
        spacing: 2

        Text {
            id: labelText
            Layout.alignment:   Qt.AlignVCenter
            Layout.fillWidth:   true
            Layout.leftMargin:  15
            height:             _tightHeight
            text:               instrumentValueData.text + ": "
            color:              _color
            opacity:            instrumentValueData.currentOpacity
            font.pixelSize:     14
            font.family:        ScreenTools.normalFontFamily
            antialiasing:       true
            horizontalAlignment: Text.AlignLeft

            onTextChanged: {
                // Label genişliği değiştiğinde parent'a bildir
                if (parent && parent.parent) {
                    parent.parent.labelWidth = implicitWidth + 15
                }
            }

            Component.onCompleted: {
                if (parent && parent.parent) {
                    parent.parent.labelWidth = implicitWidth + 15
                }
            }
        }

        // Label altı çizgisi
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 15
            height: 1
            color: _color
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

//     // layout üçün: label-in təxmini eni (HorizontalFactValueGrid-də lazım ola bilər)
//     property real labelWidth: labelTextItem.implicitWidth + _leftPad

//     readonly property real _leftPad: Math.max(6, ScreenTools.defaultFontPixelWidth * 0.6)

//     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

//     readonly property int _fontIndex: {
//         if (!instrumentValueData || !instrumentValueData.factValueGrid) return 0
//         var i = instrumentValueData.factValueGrid.fontSize
//         return Math.max(0, Math.min(3, i))
//     }

//     readonly property var  _rgFontSizes:  [ ScreenTools.defaultFontPointSize, ScreenTools.smallFontPointSize, ScreenTools.mediumFontPointSize, ScreenTools.largeFontPointSize ]
//     readonly property real _fontPt:       _rgFontSizes[_fontIndex]

//     readonly property real _cellH: Math.max(22, ScreenTools.defaultFontPixelHeight * 1.55)

//     readonly property bool _iconVisible: {
//         if (!instrumentValueData) return false
//         return instrumentValueData.rangeType === InstrumentValueData.IconSelectRange || instrumentValueData.icon
//     }

//     readonly property color _color: {
//         if (instrumentValueData && instrumentValueData.isValidColor && instrumentValueData.isValidColor(instrumentValueData.currentColor)) {
//             return instrumentValueData.currentColor
//         }
//         return qgcPal.text
//     }

//     readonly property real _op: instrumentValueData ? instrumentValueData.currentOpacity : 1.0

//     implicitHeight: _cellH
//     implicitWidth: Math.max(iconRow.implicitWidth, labelRow.implicitWidth)

//     Row {
//         id: iconRow
//         anchors.left: parent.left
//         anchors.verticalCenter: parent.verticalCenter
//         spacing: 4
//         visible: _iconVisible

//         Item { width: _leftPad; height: 1 }

//         QGCColoredImage {
//             id: valueIcon
//             height: _cellH * 0.55
//             width:  height
//             sourceSize.height: height
//             fillMode: Image.PreserveAspectFit
//             mipmap: true
//             smooth: true
//             color: _color
//             opacity: _op

//             readonly property string iconPrefix: "/InstrumentValueIcons/"

//             function updateIcon() {
//                 if (!instrumentValueData) {
//                     valueIcon.source = ""
//                     return
//                 }
//                 if (instrumentValueData.rangeType === InstrumentValueData.IconSelectRange) {
//                     valueIcon.source = instrumentValueData.currentIcon !== "" ? iconPrefix + instrumentValueData.currentIcon : ""
//                 } else if (instrumentValueData.icon) {
//                     valueIcon.source = instrumentValueData.icon !== "" ? iconPrefix + instrumentValueData.icon : ""
//                 } else {
//                     valueIcon.source = ""
//                 }
//             }

//             Connections {
//                 target: instrumentValueData
//                 function onRangeTypeChanged()    { valueIcon.updateIcon() }
//                 function onCurrentIconChanged()  { valueIcon.updateIcon() }
//                 function onIconChanged()         { valueIcon.updateIcon() }
//             }
//             Component.onCompleted: updateIcon()
//         }

//         Text {
//             text: ":"
//             color: _color
//             opacity: _op
//             font.pointSize: _fontPt
//             verticalAlignment: Text.AlignVCenter
//             visible: valueIcon.source !== ""
//         }
//     }

//     Row {
//         id: labelRow
//         anchors.left: parent.left
//         anchors.verticalCenter: parent.verticalCenter
//         spacing: 4
//         visible: !_iconVisible

//         Item { width: _leftPad; height: 1 }

//         Text {
//             id: labelTextItem
//             text: (instrumentValueData ? (instrumentValueData.text + ":") : "--:")
//             color: _color
//             opacity: _op
//             font.pointSize: _fontPt
//             verticalAlignment: Text.AlignVCenter
//             wrapMode: Text.NoWrap
//             elide: Text.ElideRight
//         }
//     }
// }



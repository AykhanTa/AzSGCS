// // /****************************************************************************
// //  *
// //  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
// //  *
// //  * QGroundControl is licensed according to the terms in the file
// //  * COPYING.md in the root of the source code directory.
// //  *
// //  ****************************************************************************/

// // import QtQuick
// // import QtCharts

// // import QGroundControl

// // import QGroundControl.Controls


// // Rectangle {
// //     id:         root
// //     radius:     ScreenTools.defaultFontPixelWidth * 0.5
// //     color:      qgcPal.window
// //     opacity:    0.80
// //     clip:       true

// //     property var missionController

// //     signal setCurrentSeqNum(int seqNum)

// //     property real _margins:                 ScreenTools.defaultFontPixelWidth / 2
// //     property var  _visualItems:             missionController.visualItems
// //     property real _altRange:                _maxAMSLAltitude - _minAMSLAltitude
// //     property real _indicatorSpacing:        5
// //     property real _minAMSLAltitude:         isNaN(terrainProfile.minAMSLAlt) ? 0 : terrainProfile.minAMSLAlt
// //     property real _maxAMSLAltitude:         isNaN(terrainProfile.maxAMSLAlt) ? 100 : terrainProfile.maxAMSLAlt
// //     property real _missionTotalDistance:    isNaN(missionController.missionTotalDistance) ? 100 : missionController.missionTotalDistance
// //     property var  _unitsConversion:         QGroundControl.unitsConversion

// //     QGCPalette { id: qgcPal }

// //     QGCLabel {
// //         id:                     titleLabel
// //         anchors.top:            parent.bottom
// //         width:                  parent.height
// //         font.pointSize:         ScreenTools.smallFontPointSize
// //         text:                   qsTr("Height AMSL (%1)").arg(_unitsConversion.appSettingsVerticalDistanceUnitsString)
// //         horizontalAlignment:    Text.AlignHCenter
// //         rotation:               -90
// //         transformOrigin:        Item.TopLeft
// //     }

// //     QGCFlickable {
// //         id:                 terrainProfileFlickable
// //         anchors.top:        parent.top
// //         anchors.bottom:     parent.bottom
// //         anchors.leftMargin: titleLabel.contentHeight
// //         anchors.left:       parent.left
// //         anchors.right:      parent.right
// //         clip:               true

// //         Item {
// //             height: terrainProfileFlickable.height
// //             width:  terrainProfileFlickable.width

// //             ChartView {
// //                 id:                 chart
// //                 anchors.fill:       parent
// //                 margins.top:        0
// //                 margins.right:      0
// //                 margins.bottom:     0
// //                 margins.left:       0
// //                 backgroundColor:    "transparent"
// //                 legend.visible:     false
// //                 antialiasing:       true

// //                 ValueAxis {
// //                     id:                         axisX
// //                     min:                        0
// //                     max:                        _unitsConversion.metersToAppSettingsHorizontalDistanceUnits(missionController.missionTotalDistance)
// //                     lineVisible:                true
// //                     labelsFont.family:          ScreenTools.fixedFontFamily
// //                     labelsFont.pointSize:       ScreenTools.smallFontPointSize
// //                     labelsColor:                qgcPal.text
// //                     tickCount:                  5
// //                     gridLineColor:              applyOpacity(qgcPal.text, 0.25)
// //                 }

// //                 ValueAxis {
// //                     id:                         axisY
// //                     min:                        _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_minAMSLAltitude)
// //                     max:                        _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_maxAMSLAltitude)
// //                     lineVisible:                true
// //                     labelsFont.family:          ScreenTools.fixedFontFamily
// //                     labelsFont.pointSize:       ScreenTools.smallFontPointSize
// //                     labelsColor:                qgcPal.text
// //                     tickCount:                  4
// //                     gridLineColor:              applyOpacity(qgcPal.text, 0.25)
// //                 }

// //                 LineSeries {
// //                     id:         lineSeries
// //                     axisX:      axisX
// //                     axisY:      axisY
// //                     visible:    true

// //                     XYPoint { x: 0; y: _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_minAMSLAltitude) }
// //                     XYPoint { x: _unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionTotalDistance); y: _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_maxAMSLAltitude) }
// //                 }
// //             }

// //             TerrainProfile {
// //                 id:                 terrainProfile
// //                 x:                  chart.plotArea.x
// //                 y:                  chart.plotArea.y
// //                 height:             chart.plotArea.height
// //                 visibleWidth:       chart.plotArea.width
// //                 missionController:  root.missionController

// //                 Repeater {
// //                     model: missionController.visualItems

// //                     Item {
// //                         id:             topLevelItem
// //                         anchors.fill:   parent
// //                         visible:        object.specifiesCoordinate && !object.standaloneCoordinate

// //                         Rectangle {
// //                             id:         simpleItem
// //                             height:     terrainProfile.height
// //                             width:      1
// //                             color:      qgcPal.text
// //                             x:          (object.distanceFromStart * terrainProfile.pixelsPerMeter)
// //                             visible:    object.isSimpleItem || object.isSingleItem

// //                             MissionItemIndexLabel {
// //                                 anchors.horizontalCenter:   parent.horizontalCenter
// //                                 anchors.bottom:             parent.bottom
// //                                 small:                      true
// //                                 checked:                    object.isCurrentItem
// //                                 label:                      object.abbreviation.charAt(0)
// //                                 index:                      object.abbreviation.charAt(0) > 'A' && object.abbreviation.charAt(0) < 'z' ? -1 : object.sequenceNumber
// //                                 onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
// //                             }
// //                         }

// //                         Rectangle {
// //                             id:         complexItemEntry
// //                             height:     terrainProfile.height
// //                             width:      1
// //                             color:      qgcPal.text
// //                             x:          (object.distanceFromStart * terrainProfile.pixelsPerMeter)
// //                             visible:    complexItem.visible

// //                             MissionItemIndexLabel {
// //                                 anchors.horizontalCenter:   parent.horizontalCenter
// //                                 anchors.bottom:             parent.bottom
// //                                 small:                      true
// //                                 checked:                    object.isCurrentItem
// //                                 index:                      object.sequenceNumber
// //                                 onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
// //                             }
// //                         }

// //                         Rectangle {
// //                             id:         complexItemExit
// //                             height:     terrainProfile.height
// //                             width:      1
// //                             color:      qgcPal.text
// //                             x:          ((object.distanceFromStart + object.complexDistance) * terrainProfile.pixelsPerMeter)
// //                             visible:    complexItem.visible

// //                             MissionItemIndexLabel {
// //                                 anchors.horizontalCenter:   parent.horizontalCenter
// //                                 anchors.bottom:             parent.bottom
// //                                 small:                      true
// //                                 checked:                    object.isCurrentItem
// //                                 index:                      object.lastSequenceNumber
// //                                 onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
// //                             }
// //                         }

// //                         Rectangle {
// //                             id:             complexItem
// //                             anchors.bottom: parent.bottom
// //                             x:              (object.distanceFromStart * terrainProfile.pixelsPerMeter)
// //                             width:          complexItem.visible ? object.complexDistance * terrainProfile.pixelsPerMeter : 0
// //                             height:         patternNameLabel.height
// //                             color:          "green"
// //                             opacity:        0.5
// //                             visible:        !object.isSimpleItem && !object.isSingleItem

// //                             QGCMouseArea {
// //                                 anchors.fill:   parent
// //                                 onClicked:      root.setCurrentSeqNum(object.sequenceNumber)
// //                             }

// //                             QGCLabel {
// //                                 id:                         patternNameLabel
// //                                 anchors.horizontalCenter:   parent.horizontalCenter
// //                                 text:                       complexItem.visible ? object.patternName : ""
// //                             }
// //                         }
// //                     }
// //                 }
// //             }
// //         }
// //     }

// //     function applyOpacity(colorIn, opacity){
// //         return Qt.rgba(colorIn.r, colorIn.g, colorIn.b, opacity)
// //     }
// // }




// import QtQuick
// import QtCharts

// import QGroundControl

// import QGroundControl.Controls


// Rectangle {
//     id:         root
//     radius:     ScreenTools.defaultFontPixelWidth * 0.5
//     color:      "#3B3939"
//     border.color: "#9D9D9D"
//     border.width: 2
//     opacity:    0.90
//     clip:       true

//     property var missionController

//     signal setCurrentSeqNum(int seqNum)

//     property real _margins:                 ScreenTools.defaultFontPixelWidth / 2
//     property var  _visualItems:             missionController.visualItems
//     property real _altRange:                _maxAMSLAltitude - _minAMSLAltitude
//     property real _indicatorSpacing:        5
//     property real _minAMSLAltitude:         isNaN(terrainProfile.minAMSLAlt) ? 0 : terrainProfile.minAMSLAlt
//     property real _maxAMSLAltitude:         isNaN(terrainProfile.maxAMSLAlt) ? 100 : terrainProfile.maxAMSLAlt
//     property real _missionTotalDistance:    isNaN(missionController.missionTotalDistance) ? 100 : missionController.missionTotalDistance

//     QGCPalette { id: qgcPal }

//     QGCLabel {
//         id:                     titleLabel
//         anchors.top:            parent.bottom
//         width:                  parent.height
//         font.pointSize:         12
//         text:                   qsTr("Height AMSL (m)")  // METRE olarak değiştirildi
//         horizontalAlignment:    Text.AlignHCenter
//         rotation:               -90
//         transformOrigin:        Item.TopLeft
//         color:                  "white"
//         font.bold:              true
//     }

//     QGCFlickable {
//         id:                 terrainProfileFlickable
//         anchors.top:        parent.top
//         anchors.bottom:     parent.bottom
//         anchors.leftMargin: titleLabel.contentHeight
//         anchors.left:       parent.left
//         anchors.right:      parent.right
//         clip:               true

//         Item {
//             height: terrainProfileFlickable.height
//             width:  terrainProfileFlickable.width

//             ChartView {
//                 id:                 chart
//                 anchors.fill:       parent
//                 margins.top:        20
//                 margins.right:      0
//                 margins.bottom:     0
//                 margins.left:       0
//                 backgroundColor:    "transparent"
//                 legend.visible:     false
//                 antialiasing:       true

//                 ValueAxis {
//                     id:                         axisX
//                     min:                        0
//                     max:                        missionController.missionTotalDistance / 1000  // KM olarak göster
//                     lineVisible:                true
//                     labelsFont.family:          ScreenTools.fixedFontFamily
//                     labelsFont.pointSize:       ScreenTools.middleFontPointSize
//                     labelsColor:                "white"
//                     tickCount:                  5
//                     gridLineColor:              "#9D9D9D"
//                     color:                      "#9D9D9D"
//                     labelsFont.bold:            true
//                 }

//                 ValueAxis {
//                     id:                         axisY
//                     min:                        _minAMSLAltitude  // METRE olarak doğrudan
//                     max:                        _maxAMSLAltitude  // METRE olarak doğrudan
//                     lineVisible:                true
//                     labelsFont.family:          ScreenTools.fixedFontFamily
//                     labelsFont.pointSize:       ScreenTools.middleFontPointSize
//                     labelsColor:                "white"  // Beyaz yapıldı
//                     tickCount:                  4
//                     gridLineColor:              "#9D9D9D"
//                     color:                      "#9D9D9D"
//                     labelsFont.bold:            true
//                 }

//                 LineSeries {
//                     id:         lineSeries
//                     axisX:      axisX
//                     axisY:      axisY
//                     visible:    true
//                     color:      "white"

//                     XYPoint { x: 0; y: _minAMSLAltitude }  // Metre olarak
//                     XYPoint { x: missionController.missionTotalDistance / 1000; y: _maxAMSLAltitude }  // Metre olarak
//                 }
//             }

//             TerrainProfile {
//                 id:                 terrainProfile
//                 x:                  chart.plotArea.x
//                 y:                  chart.plotArea.y
//                 height:             chart.plotArea.height
//                 visibleWidth:       chart.plotArea.width
//                 missionController:  root.missionController

//                 Repeater {
//                     model: missionController.visualItems

//                     Item {
//                         id:             topLevelItem
//                         anchors.fill:   parent
//                         visible:        object.specifiesCoordinate && !object.standaloneCoordinate

//                         Rectangle {
//                             id:         simpleItem
//                             height:     terrainProfile.height
//                             width:      1
//                             color:      "white"   // Beyaz yapıldı
//                             x:          (object.distanceFromStart * terrainProfile.pixelsPerMeter)
//                             visible:    object.isSimpleItem || object.isSingleItem

//                             MissionItemIndexLabel {
//                                 anchors.horizontalCenter:   parent.horizontalCenter
//                                 anchors.bottom:             parent.bottom
//                                 small:                      true
//                                 checked:                    object.isCurrentItem
//                                 label:                      object.abbreviation.charAt(0)
//                                 index:                      object.abbreviation.charAt(0) > 'A' && object.abbreviation.charAt(0) < 'z' ? -1 : object.sequenceNumber
//                                 onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
//                             }
//                         }

//                         Rectangle {
//                             id:         complexItemEntry
//                             height:     terrainProfile.height
//                             width:      1
//                             color:      "white"  // Beyaz yapıldı
//                             x:          (object.distanceFromStart * terrainProfile.pixelsPerMeter)
//                             visible:    complexItem.visible

//                             MissionItemIndexLabel {
//                                 anchors.horizontalCenter:   parent.horizontalCenter
//                                 anchors.bottom:             parent.bottom
//                                 small:                      true
//                                 checked:                    object.isCurrentItem
//                                 index:                      object.sequenceNumber
//                                 onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
//                             }
//                         }

//                         Rectangle {
//                             id:         complexItemExit
//                             height:     terrainProfile.height
//                             width:      1
//                             color:      "#9D9D9D"
//                             x:          ((object.distanceFromStart + object.complexDistance) * terrainProfile.pixelsPerMeter)
//                             visible:    complexItem.visible

//                             MissionItemIndexLabel {
//                                 anchors.horizontalCenter:   parent.horizontalCenter
//                                 anchors.bottom:             parent.bottom
//                                 small:                      true
//                                 checked:                    object.isCurrentItem
//                                 index:                      object.lastSequenceNumber
//                                 onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
//                             }
//                         }

//                         Rectangle {
//                             id:             complexItem
//                             anchors.bottom: parent.bottom
//                             x:              (object.distanceFromStart * terrainProfile.pixelsPerMeter)
//                             width:          complexItem.visible ? object.complexDistance * terrainProfile.pixelsPerMeter : 0
//                             height:         patternNameLabel.height
//                             color:          "green"
//                             opacity:        0.5
//                             visible:        !object.isSimpleItem && !object.isSingleItem

//                             QGCMouseArea {
//                                 anchors.fill:   parent
//                                 onClicked:      root.setCurrentSeqNum(object.sequenceNumber)
//                             }

//                             QGCLabel {
//                                 id:                         patternNameLabel
//                                 anchors.horizontalCenter:   parent.horizontalCenter
//                                 text:                       complexItem.visible ? object.patternName : ""
//                                 color:                      "white"  // Beyaz yapıldı
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     function applyOpacity(colorIn, opacity){
//         return Qt.rgba(colorIn.r, colorIn.g, colorIn.b, opacity)
//     }
// }



import QtQuick
import QtCharts

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id:         root
    radius:     12
    // ❗ Kök elementə opacity vermək oxları və yazıları da solğunlaşdırırdı —
    //    əvəzinə yalnız fon qatı yarımşəffafdır, məzmun tam kəskin qalır.
    color:      "transparent"
    clip:       true

    property var missionController

    // Dizayn rəngləri
    readonly property color panelBg:     "#141414"
    readonly property color panelBorder: "#6E6E6E"
    readonly property color plotBg:      "#1E1E1E"
    readonly property color gridColor:   "#3A3A3A"
    readonly property color labelColor:  "#CFCFCF"
    readonly property color accentColor: "#00C853"

    Rectangle {
        anchors.fill:   parent
        radius:         root.radius
        color:          root.panelBg
        opacity:        0.92
        border.width:   1
        border.color:   root.panelBorder
    }

    signal setCurrentSeqNum(int seqNum)

    property real _margins:                 ScreenTools.defaultFontPixelWidth / 2
    property var  _visualItems:             missionController.visualItems
    property real _altRange:                _maxAMSLAltitude - _minAMSLAltitude
    property real _indicatorSpacing:        5
    property real _minAMSLAltitude:         isNaN(terrainProfile.minAMSLAlt) ? 0 : terrainProfile.minAMSLAlt
    property real _maxAMSLAltitude:         isNaN(terrainProfile.maxAMSLAlt) ? 100 : terrainProfile.maxAMSLAlt
    property real _missionTotalDistance:    isNaN(missionController.missionTotalDistance) ? 100 : missionController.missionTotalDistance
    property var  _unitsConversion:         QGroundControl.unitsConversion

    QGCPalette { id: qgcPal }

    QGCLabel {
        id:                     titleLabel
        anchors.top:            parent.bottom
        width:                  parent.height
        font.pointSize:         ScreenTools.smallFontPointSize
        font.bold:              true
        color:                  root.labelColor
        text:                   qsTr("Height AMSL (%1)").arg(_unitsConversion.appSettingsVerticalDistanceUnitsString)
        horizontalAlignment:    Text.AlignHCenter
        rotation:               -90
        transformOrigin:        Item.TopLeft
    }

    QGCFlickable {
        id:                 terrainProfileFlickable
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        anchors.leftMargin: titleLabel.contentHeight
        anchors.left:       parent.left
        anchors.right:      parent.right
        clip:               true

        Item {
            height: terrainProfileFlickable.height
            width:  terrainProfileFlickable.width

            // Qrafik sahəsini fondan ayıran zolaq
            Rectangle {
                x:      chart.plotArea.x
                y:      chart.plotArea.y
                width:  chart.plotArea.width
                height: chart.plotArea.height
                color:  root.plotBg
                radius: 6
                border.width: 1
                border.color: root.gridColor
            }

            ChartView {
                id:                 chart
                anchors.fill:       parent
                margins.top:        0
                margins.right:      0
                margins.bottom:     0
                margins.left:       0
                backgroundColor:    "transparent"
                legend.visible:     false
                antialiasing:       true

                ValueAxis {
                    id:                         axisX
                    min:                        0
                    max:                        _unitsConversion.metersToAppSettingsHorizontalDistanceUnits(missionController.missionTotalDistance)
                    lineVisible:                true
                    labelsFont.family:          ScreenTools.fixedFontFamily
                    labelsFont.pointSize:       ScreenTools.smallFontPointSize
                    labelsColor:                root.labelColor
                    color:                      root.gridColor
                    tickCount:                  5
                    gridLineColor:              root.gridColor
                }

                ValueAxis {
                    id:                         axisY
                    min:                        _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_minAMSLAltitude)
                    max:                        _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_maxAMSLAltitude)
                    lineVisible:                true
                    labelsFont.family:          ScreenTools.fixedFontFamily
                    labelsFont.pointSize:       ScreenTools.smallFontPointSize
                    labelsColor:                root.labelColor
                    color:                      root.gridColor
                    tickCount:                  4
                    gridLineColor:              root.gridColor
                }

                LineSeries {
                    id:         lineSeries
                    axisX:      axisX
                    axisY:      axisY
                    visible:    true

                    XYPoint { x: 0; y: _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_minAMSLAltitude) }
                    XYPoint { x: _unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionTotalDistance); y: _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_maxAMSLAltitude) }
                }
            }

            TerrainProfile {
                id:                 terrainProfile
                x:                  chart.plotArea.x
                y:                  chart.plotArea.y
                height:             chart.plotArea.height
                visibleWidth:       chart.plotArea.width
                missionController:  root.missionController

                Repeater {
                    model: missionController.visualItems

                    Item {
                        id:             topLevelItem
                        anchors.fill:   parent
                        visible:        object.specifiesCoordinate && !object.standaloneCoordinate

                        Rectangle {
                            id:         simpleItem
                            height:     terrainProfile.height
                            width:      1
                            color:      "#8A8A8A"
                            x:          (object.distanceFromStart * terrainProfile.pixelsPerMeter)
                            visible:    object.isSimpleItem || object.isSingleItem

                            MissionItemIndexLabel {
                                anchors.horizontalCenter:   parent.horizontalCenter
                                anchors.bottom:             parent.bottom
                                small:                      true
                                checked:                    object.isCurrentItem
                                label:                      object.abbreviation.charAt(0)
                                index:                      object.abbreviation.charAt(0) > 'A' && object.abbreviation.charAt(0) < 'z' ? -1 : object.sequenceNumber
                                onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
                            }
                        }

                        Rectangle {
                            id:         complexItemEntry
                            height:     terrainProfile.height
                            width:      1
                            color:      "#8A8A8A"
                            x:          (object.distanceFromStart * terrainProfile.pixelsPerMeter)
                            visible:    complexItem.visible

                            MissionItemIndexLabel {
                                anchors.horizontalCenter:   parent.horizontalCenter
                                anchors.bottom:             parent.bottom
                                small:                      true
                                checked:                    object.isCurrentItem
                                index:                      object.sequenceNumber
                                onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
                            }
                        }

                        Rectangle {
                            id:         complexItemExit
                            height:     terrainProfile.height
                            width:      1
                            color:      "#8A8A8A"
                            x:          ((object.distanceFromStart + object.complexDistance) * terrainProfile.pixelsPerMeter)
                            visible:    complexItem.visible

                            MissionItemIndexLabel {
                                anchors.horizontalCenter:   parent.horizontalCenter
                                anchors.bottom:             parent.bottom
                                small:                      true
                                checked:                    object.isCurrentItem
                                index:                      object.lastSequenceNumber
                                onClicked:                  root.setCurrentSeqNum(object.sequenceNumber)
                            }
                        }

                        Rectangle {
                            id:             complexItem
                            anchors.bottom: parent.bottom
                            x:              (object.distanceFromStart * terrainProfile.pixelsPerMeter)
                            width:          complexItem.visible ? object.complexDistance * terrainProfile.pixelsPerMeter : 0
                            height:         patternNameLabel.height
                            radius:         4
                            color:          root.accentColor
                            opacity:        0.35
                            visible:        !object.isSimpleItem && !object.isSingleItem

                            QGCMouseArea {
                                anchors.fill:   parent
                                onClicked:      root.setCurrentSeqNum(object.sequenceNumber)
                            }

                            QGCLabel {
                                id:                         patternNameLabel
                                anchors.horizontalCenter:   parent.horizontalCenter
                                text:                       complexItem.visible ? object.patternName : ""
                                color:                      "#FFFFFF"
                                font.bold:                  true
                            }
                        }
                    }
                }
            }
        }
    }

    function applyOpacity(colorIn, opacity){
        return Qt.rgba(colorIn.r, colorIn.g, colorIn.b, opacity)
    }
}

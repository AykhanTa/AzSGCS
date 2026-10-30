




import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning

import QGroundControl

import QGroundControl.Controls

import QGroundControl.FactControls

QGCFlickable {
    id:             root
    contentHeight:  geoFenceEditorRect.height
    clip:           true

    property var    myGeoFenceController
    property var    flightMap

    readonly property real  _editFieldWidth:    Math.min(width - _margin * 2, ScreenTools.defaultFontPixelWidth * 15)
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _radius:            AzTheme.px(12)

    Rectangle {
        id:     geoFenceEditorRect
        anchors.left:   parent.left
        anchors.right:  parent.right
        height: geoFenceItems.y + geoFenceItems.height + (_margin * 2)
        // A mission item card of the Missiya tab
        radius:       _radius
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }

        QGCLabel {
            id:                 geoFenceLabel
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.top:        parent.top
            text:               qsTr("GeoFence")
            font.pointSize:12
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
        }

        Rectangle {
            id:                 geoFenceItems
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        geoFenceLabel.bottom
            height:             fenceColumn.y + fenceColumn.height + (_margin * 2)
            color:              "transparent"

            Column {
                id:                 fenceColumn
                anchors.margins:    _margin
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            _margin

                QGCLabel {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    wrapMode:           Text.WordWrap
                    font.pointSize:     10//myGeoFenceController.supported ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                    text:               myGeoFenceController.supported ?
                                            qsTr("GeoFencing sizə uçmaq istədiyiniz ərazinin ətrafında virtual hasar qurmağa imkan verir.") :
                                            qsTr("Bu təyyarə GeoFence-i dəstəkləmir.")
                }

                Column {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    spacing:            _margin
                    visible:            myGeoFenceController.supported

                    Repeater {
                        model: myGeoFenceController.params

                        Item {
                            width:  fenceColumn.width
                            height: textField.height

                            property bool showCombo: modelData.enumStrings.length > 0

                            QGCLabel {
                                id:                 textFieldLabel
                                anchors.baseline:   textField.baseline
                                anchors.left:       parent.left
                                anchors.right:      textField.left
                                anchors.rightMargin: ScreenTools.defaultFontPixelWidth / 2
                                elide:              Text.ElideRight
                                text:               myGeoFenceController.paramLabels[index]
                            }

                            FactTextField {
                                id:             textField
                                anchors.right:  parent.right
                                width:          _editFieldWidth
                                showUnits:      true
                                fact:           modelData
                                visible:        !parent.showCombo
                            }

                            FactComboBox {
                                id:             comboField
                                anchors.right:  parent.right
                                width:          _editFieldWidth
                                indexModel:     false
                                fact:           showCombo ? modelData : _nullFact
                                visible:        parent.showCombo

                                property var _nullFact: Fact { }
                            }
                        }
                    }
                    SectionHeader {
                        id:             insertSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("GeoFence daxil edin")
                    }

                    Rectangle {
                        anchors.left:  parent.left
                        anchors.right: parent.right
                        height: fenceButtons.height + 20
                        radius: 3
                        color: "transparent"
                        visible: insertSection.checked

                        Column {
                            id: fenceButtons
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: _margin

                            // Polygon Fence Button
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 40
                                radius: 3
                                color: "transparent"

                                QGCButton {
                                    anchors.fill: parent
                                    text: qsTr("Polygon Fence")
                                    onClicked: {
                                        var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                                        var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false /* clipToViewPort */)
                                        var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false /* clipToViewPort */)
                                        myGeoFenceController.addInclusionPolygon(topLeftCoord, bottomRightCoord)
                                    }
                                }
                            }

                            // Circular Fence Button
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 40
                                radius: 3
                                color: "transparent"

                                QGCButton {
                                    anchors.fill: parent
                                    text: qsTr("Circular Fence")
                                    onClicked: {
                                        var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                                        var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false /* clipToViewPort */)
                                        var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false /* clipToViewPort */)
                                        myGeoFenceController.addInclusionCircle(topLeftCoord, bottomRightCoord)
                                    }
                                }
                            }
                        }
                    }

                    SectionHeader {
                        id:             polygonSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("Polygon Fences")
                    }

                    QGCLabel {
                        text:       qsTr("Yoxdur")
                        visible:    polygonSection.checked && myGeoFenceController.polygons.count === 0
                    }

                    GridLayout {
                        Layout.fillWidth:   true
                        columns:            3
                        flow:               GridLayout.TopToBottom
                        visible:            polygonSection.checked && myGeoFenceController.polygons.count > 0

                        QGCLabel {
                            text:                 qsTr("Daxiletmə")
                            Layout.column:        0
                            Layout.alignment:     Qt.AlignHCenter
                            Layout.fillWidth:     true
                            Layout.minimumWidth:  0
                            horizontalAlignment:  Text.AlignHCenter
                            elide:                Text.ElideRight
                             color: AzTheme.textCard
                        }

                        Repeater {
                              model: myGeoFenceController.polygons

                              // Toggle buton - kırmızı ve yeşil
                              Rectangle {
                                  width: 40
                                  height: 20
                                  radius: 10
                                  color: object.inclusion ? "#00FF00" : "#FF0000" // Yeşil: açık, Kırmızı: kapalı
                                  Layout.alignment: Qt.AlignHCenter

                                  Rectangle {
                                      x: object.inclusion ? parent.width - width - 2 : 2
                                      y: 2
                                      width: 16
                                      height: 16
                                      radius: 8
                                      color: AzTheme.textCard
                                      Behavior on x { NumberAnimation { duration: 100 } }
                                  }

                                  MouseArea {
                                      anchors.fill: parent
                                      onClicked: object.inclusion = !object.inclusion
                                  }
                              }
                          }

                        QGCLabel {
                            text:                 qsTr("Redaktə et")
                            Layout.column:        1
                            Layout.alignment:     Qt.AlignHCenter
                            Layout.fillWidth:     true
                            Layout.minimumWidth:  0
                            horizontalAlignment:  Text.AlignHCenter
                            elide:                Text.ElideRight
                             color: AzTheme.textCard
                        }

                        Repeater {
                            model: myGeoFenceController.polygons

                            QGCRadioButton {
                                checked:            _interactive
                                Layout.alignment:   Qt.AlignHCenter

                                property bool _interactive: object.interactive

                                on_InteractiveChanged: checked = _interactive

                                onClicked: {
                                    myGeoFenceController.clearAllInteractive()
                                    object.interactive = checked
                                }
                            }
                        }

                        QGCLabel {
                            text:                 qsTr("Sil")
                            Layout.column:        2
                            Layout.alignment:     Qt.AlignHCenter
                            Layout.fillWidth:     true
                            Layout.minimumWidth:  0
                            horizontalAlignment:  Text.AlignHCenter
                            elide:                Text.ElideRight
                             color: AzTheme.textCard
                        }

                        Repeater {
                              model: myGeoFenceController.polygons

                              // Delete butonu yerine çöp kutusu ikonu
                              QGCButton {
                                  Layout.alignment:       Qt.AlignHCenter
                                  Layout.minimumWidth:    0
                                  Layout.preferredWidth:  Math.max(30, ScreenTools.defaultFontPixelHeight * 1.8)
                                  Layout.preferredHeight: Layout.preferredWidth
                                  onClicked:          myGeoFenceController.deletePolygon(index)
                                  backgroundColor: "#3D3B3B"

                                  // Çöp kutusu ikonu
                                  QGCColoredImage {
                                      anchors.centerIn: parent
                                      source: "qrc:/res/AZSHIELD_ICON/trash.svg"
                                      width: 20
                                      height: 20
                                      color: AzTheme.textCard
                                  }
                              }
                          }
                    } // GridLayout
                // ---------------------------------------------------------
                    SectionHeader {
                        id:             circleSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("Circular Fences")
                    }

                    QGCLabel {
                        text:       qsTr("Yoxdur")
                        visible:    circleSection.checked && myGeoFenceController.circles.count === 0
                    }

                    GridLayout {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        columns:            4
                        flow:               GridLayout.TopToBottom
                        visible:            polygonSection.checked && myGeoFenceController.circles.count > 0

                        QGCLabel {
                            text:                 qsTr("Daxiletmə")
                            Layout.column:        0
                            Layout.alignment:     Qt.AlignHCenter
                            Layout.fillWidth:     true
                            Layout.minimumWidth:  0
                            horizontalAlignment:  Text.AlignHCenter
                            elide:                Text.ElideRight
                            color: AzTheme.textCard
                        }

                        // Repeater {
                        //     model: myGeoFenceController.circles

                        //     QGCCheckBox {
                        //         checked:            object.inclusion
                        //         onClicked:          object.inclusion = checked
                        //         Layout.alignment:   Qt.AlignHCenter
                        //     }
                        // }
                        Repeater {
                            model: myGeoFenceController.circles

                            // Toggle buton - kırmızı ve yeşil
                            Rectangle {
                                width: 40
                                height: 20
                                radius: 10
                                color: object.inclusion ? "#00FF00" : "#FF0000" // Yeşil: açık, Kırmızı: kapalı
                                Layout.alignment: Qt.AlignHCenter

                                Rectangle {
                                    x: object.inclusion ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: AzTheme.textCard
                                    Behavior on x { NumberAnimation { duration: 100 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: object.inclusion = !object.inclusion
                                }
                            }
                        }

                        QGCLabel {
                            text:                 qsTr("Redaktə et")
                            Layout.column:        1
                            Layout.alignment:     Qt.AlignHCenter
                            Layout.fillWidth:     true
                            Layout.minimumWidth:  0
                            horizontalAlignment:  Text.AlignHCenter
                            elide:                Text.ElideRight
                             color: AzTheme.textCard
                        }

                        Repeater {
                            model: myGeoFenceController.circles

                            QGCRadioButton {
                                checked:            _interactive
                                Layout.alignment:   Qt.AlignHCenter

                                property bool _interactive: object.interactive

                                on_InteractiveChanged: checked = _interactive

                                onClicked: {
                                    myGeoFenceController.clearAllInteractive()
                                    object.interactive = checked
                                }
                            }
                        }

                        QGCLabel {
                            text:                 qsTr("Radius")
                            Layout.column:        2
                            Layout.alignment:     Qt.AlignHCenter
                            Layout.fillWidth:     true
                            Layout.minimumWidth:  0
                            horizontalAlignment:  Text.AlignHCenter
                            elide:                Text.ElideRight
                             color: AzTheme.textCard
                        }

                        Repeater {
                            model: myGeoFenceController.circles

                            FactTextField {
                                fact:                   object.radius
                                // Yer çatmayanda layout bütün elementləri minimuma
                                // doğru sıxır, ona görə burada həlledici olan
                                // minimumdur: dəyər + vahid ("1000.0 m") sığmalıdır.
                                // Sütun başlıqlarının minimumu 0-dır, sıxılmanı
                                // onlar udur.
                                Layout.fillWidth:       true
                                Layout.minimumWidth:    Math.max(60, ScreenTools.defaultFontPixelWidth * 7)
                                Layout.alignment:       Qt.AlignHCenter
                            }
                        }

                        QGCLabel {
                            text:                 qsTr("Sil")
                            Layout.column:        3
                            Layout.alignment:     Qt.AlignHCenter
                            Layout.fillWidth:     true
                            Layout.minimumWidth:  0
                            horizontalAlignment:  Text.AlignHCenter
                            elide:                Text.ElideRight
                            color: AzTheme.textCard
                        }

                        Repeater {
                            model: myGeoFenceController.circles

                            Rectangle {
                                implicitWidth:  30
                                implicitHeight: 30
                                radius: 3
                                color: "transparent"
                                Layout.alignment: Qt.AlignHCenter

                                QGCColoredImage {
                                    anchors.centerIn: parent
                                    source: "qrc:/res/AZSHIELD_ICON/trash.svg"
                                    width: 20
                                    height: 20
                                    color: AzTheme.textCard
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: myGeoFenceController.deleteCircle(index)
                                }
                            }
                        }
                    } // GridLayout

                    SectionHeader {
                        id:             breachReturnSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           qsTr("Qayıdış nöqtəsi")
                    }

                    QGCButton {
                        text:               qsTr("Qayıdış nöqtəsi əlavə et")
                        visible:            breachReturnSection.visible && !myGeoFenceController.breachReturnPoint.isValid
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        backgroundColor: "#8F8F8F"
                        font.bold: true
                        onClicked: myGeoFenceController.breachReturnPoint = flightMap.center
                    }

                    QGCButton {
                        text: qsTr("Qayıdış nöqtəsini sil")
                        visible: breachReturnSection.visible && myGeoFenceController.breachReturnPoint.isValid
                        anchors.left: parent.left
                        anchors.right: parent.right
                        backgroundColor: "#8F8F8F"
                        onClicked: {
                            myGeoFenceController.breachReturnPoint = QtPositioning.coordinate()
                        }
                    }

                    // ❗ Əvvəl sabit 300px en və 132px boşluqla qurulmuşdu — panel
                    //    daha dar olduğu üçün dəyər sahəsi kənara çıxırdı.
                    Rectangle {
                        id:             altitudeRectangle
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height:         Math.max(42, ScreenTools.defaultFontPixelHeight * 2.3)
                        radius:         8
                        color:          "#2A2A2A"
                        visible:        breachReturnSection.visible && myGeoFenceController.breachReturnPoint.isValid

                        readonly property real pad:    Math.max(10, ScreenTools.defaultFontPixelWidth)
                        readonly property real fieldW: Math.max(90, Math.min(150, width * 0.42))

                        RowLayout {
                            anchors.fill:           parent
                            anchors.leftMargin:     altitudeRectangle.pad
                            anchors.rightMargin:    altitudeRectangle.pad
                            spacing:                altitudeRectangle.pad * 0.6

                            QGCLabel {
                                text:                qsTr("Hündürlük")
                                color:               "#FFFFFF"
                                Layout.fillWidth:    true
                                Layout.minimumWidth: 0
                                Layout.alignment:    Qt.AlignVCenter
                                elide:               Text.ElideRight
                            }

                            FactTextField {
                                fact:                   myGeoFenceController.breachReturnAltitude
                                Layout.preferredWidth:  altitudeRectangle.fieldW
                                Layout.minimumWidth:    0
                                Layout.alignment:       Qt.AlignRight | Qt.AlignVCenter
                            }
                        }
                    }

                }
            }
        }
    } // Rectangle
}

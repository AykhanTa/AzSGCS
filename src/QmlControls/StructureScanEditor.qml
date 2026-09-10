import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl


import QGroundControl.Controls
import QGroundControl.FactControls

import QGroundControl.FlightMap

// Editor for Survery mission items
Rectangle {
    id:         _root
    height:     visible ? (editorColumn.height + (_margin * 2)) : 0
    width:      availableWidth
    color:      qgcPal.windowShadeDark
    radius:     _radius

    // The following properties must be available up the hierarchy chain
    //property real   availableWidth    ///< Width for control
    //property var    missionItem       ///< Mission Item for editor

    property real   _margin:                    ScreenTools.defaultFontPixelWidth / 2
    property real   _fieldWidth:                ScreenTools.defaultFontPixelWidth * 10.5
    property var    _vehicle:                   QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _cameraMinTriggerInterval:  missionItem.cameraCalc.minTriggerInterval.rawValue

    function polygonCaptureStarted() {
        missionItem.clearPolygon()
    }

    function polygonCaptureFinished(coordinates) {
        for (var i=0; i<coordinates.length; i++) {
            missionItem.addPolygonCoordinate(coordinates[i])
        }
    }

    function polygonAdjustVertex(vertexIndex, vertexCoordinate) {
        missionItem.adjustPolygonCoordinate(vertexIndex, vertexCoordinate)
    }

    function polygonAdjustStarted() { }
    function polygonAdjustFinished() { }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ColumnLayout {
        id:                 editorColumn
        anchors.margins:    _margin
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right

        QGCLabel {
                id:                 wizardLabel
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                horizontalAlignment:    Text.AlignHCenter
                text:               qsTr("Strukturu təsvir edən çoxbucaqlı yaratmaq üçün Poliqon Alətlərindən istifadə edin.")
                visible:        !missionItem.structurePolygon.isValid || missionItem.wizardMode
            }

        ColumnLayout {
            Layout.fillWidth:   true
            spacing:        _margin
            visible:        !wizardLabel.visible

            QGCTabBar {
                id:             tabBar
                Layout.fillWidth:   true

                Component.onCompleted: currentIndex = 0

                QGCTabButton { text: qsTr("Grid") }
                QGCTabButton { text: qsTr("Camera") }
            }

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            _margin
                visible:            tabBar.currentIndex == 0

                QGCLabel {
                    Layout.fillWidth:   true
                    text:           qsTr("Qeyd: Poliqon təyyarənin uçuş yolunu deyil, strukturun səthini təmsil edir.")
                    wrapMode:       Text.WordWrap
                    font.pointSize: ScreenTools.smallFontPointSize
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    text:           qsTr("XƏBƏRDARLIQ: Foto interval kamera tərəfindən dəstəklənən minimum intervaldan (%1 saniyə) aşağıdır.").arg(_cameraMinTriggerInterval.toFixed(1))
                    wrapMode:       Text.WordWrap
                    color:          qgcPal.warningText
                    visible:        missionItem.cameraShots > 0 && _cameraMinTriggerInterval !== 0 && _cameraMinTriggerInterval > missionItem.timeBetweenShots
                }

                CameraCalcGrid {
                    Layout.fillWidth:   true
                    cameraCalc:                     missionItem.cameraCalc
                    vehicleFlightIsFrontal:         false
                    distanceToSurfaceLabel:         qsTr("Skan məsafəsi")
                    frontalDistanceLabel:           qsTr("Layer Hündürlüyü")
                    sideDistanceLabel:              qsTr("Tətik məsafəsi")
                }

                SectionHeader {
                    id:             scanHeader
                    Layout.fillWidth:   true
                    text:           qsTr("Skan edin")
                }

                ColumnLayout {
                    Layout.fillWidth:   true
                    spacing:        _margin
                    visible:        scanHeader.checked

                    GridLayout {
                        Layout.fillWidth:   true
                        columnSpacing:  _margin
                        rowSpacing:     _margin
                        columns:        2

                        FactComboBox {
                            fact:               missionItem.startFromTop
                            indexModel:         true
                            model:              [ qsTr("Skanı Aşağıdan Başlayın"), qsTr("Skanı yuxarıdan başlayın") ]
                            Layout.columnSpan:  2
                            Layout.fillWidth:   true
                        }

                        QGCLabel {
                            text:       qsTr("Struktur Hündürlüyü")
                        }
                        FactTextField {
                            fact:               missionItem.structureHeight
                            Layout.fillWidth:   true
                        }

                        QGCLabel { text: qsTr("Scan Bottom Alt") }
                        AltitudeFactTextField {
                            fact:               missionItem.scanBottomAlt
                            altitudeMode:       QGroundControl.AltitudeModeRelative
                            Layout.fillWidth:   true
                        }

                        QGCLabel { text: qsTr("Giriş/Çıxış Alt") }
                        AltitudeFactTextField {
                            fact:               missionItem.entranceAlt
                            altitudeMode:       QGroundControl.AltitudeModeRelative
                            Layout.fillWidth:   true
                        }

                        QGCLabel {
                            text:       qsTr("Gimbal Pitch")
                            visible:    missionItem.cameraCalc.isManualCamera
                        }
                        FactTextField {
                            fact:               missionItem.gimbalPitch
                            Layout.fillWidth:   true
                            visible:            missionItem.cameraCalc.isManualCamera
                        }
                    }

                    Item {
                        height: ScreenTools.defaultFontPixelHeight / 2
                        width:  1
                    }

                    QGCButton {
                        text:       qsTr("Giriş nöqtəsini çevirin")
                        onClicked:  missionItem.rotateEntryPoint()
                    }
                } // Column - Scan

                SectionHeader {
                    id:             statsHeader
                    Layout.fillWidth:   true
                    text:           qsTr("Statistika")
                }

                Grid {
                    columns:        2
                    columnSpacing:  ScreenTools.defaultFontPixelWidth
                    visible:        statsHeader.checked

                    QGCLabel { text: qsTr("Layers") }
                    QGCLabel { text: missionItem.layers.valueString }

                    QGCLabel { text: qsTr("Layer Height") }
                    QGCLabel { text: missionItem.cameraCalc.adjustedFootprintFrontal.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString }

                    QGCLabel { text: qsTr("Top Layer Alt") }
                    QGCLabel { text: QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(missionItem.topFlightAlt).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString }

                    QGCLabel { text: qsTr("Bottom Layer Alt") }
                    QGCLabel { text: QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(missionItem.bottomFlightAlt).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString }

                    QGCLabel { text: qsTr("Foto sayı") }
                    QGCLabel { text: missionItem.cameraShots }

                    QGCLabel { text: qsTr("Foto interval") }
                    QGCLabel { text: missionItem.timeBetweenShots.toFixed(1) + " " + qsTr("secs") }

                    QGCLabel { text: qsTr("Tətik məsafəsi") }
                    QGCLabel { text: missionItem.cameraCalc.adjustedFootprintSide.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString }
                }
            } // Grid Column

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            _margin
                visible:            tabBar.currentIndex == 1

                CameraCalcCamera {
                    Layout.fillWidth:   true
                    cameraCalc: missionItem.cameraCalc
                }
            }
        }
    }
}

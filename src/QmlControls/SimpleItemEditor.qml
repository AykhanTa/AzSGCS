import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl


import QGroundControl.Controls
import QGroundControl.FactControls


// Editor for Simple mission items
Rectangle {
    id:     simpleItemEditor

    width:  availableWidth
    height: editorColumn.height + (_margin * 2)
    //color:  qgcPal.windowShadeDark
    color: "transparent"
    radius: _radius

    property bool _specifiesAltitude:       missionItem.specifiesAltitude
    property real _margin:                  ScreenTools.defaultFontPixelHeight / 2
    property real _altRectMargin:           ScreenTools.defaultFontPixelWidth / 2
    property var  _controllerVehicle:       missionItem.masterController.controllerVehicle
    property int  _globalAltMode:           missionItem.masterController.missionController.globalAltitudeMode
    property bool _globalAltModeIsMixed:    _globalAltMode == QGroundControl.AltitudeModeMixed
    property real _radius:                  ScreenTools.defaultFontPixelWidth / 2

    // Sağdakı dəyər sahələrinin eni — etiket solda, dəyər sağda eyni xətt üzrə
    readonly property real _fieldW: Math.max(80, Math.min(130, availableWidth * 0.38))

    function updateAltitudeModeText() {
        if (missionItem.altitudeMode === QGroundControl.AltitudeModeRelative) {
            altModeLabel.text = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeRelative)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeAbsolute) {
            altModeLabel.text = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeAbsolute)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeCalcAboveTerrain) {
            altModeLabel.text = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeCalcAboveTerrain)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
            altModeLabel.text = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeTerrainFrame)
        } else {
            altModeLabel.text = qsTr("Internal Error")
        }
    }

    Component.onCompleted: updateAltitudeModeText()

    Connections {
        target:                 missionItem
        function onAltitudeModeChanged() { updateAltitudeModeText() }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
    Component { id: altModeDialogComponent; AltModeDialog { } }

    Column {
        id:                 editorColumn
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        spacing:            _margin

        QGCLabel {
            width:          parent.width
            wrapMode:       Text.WordWrap
            font.pointSize: ScreenTools.smallFontPointSize
            text:           missionItem.rawEdit ?
                                qsTr("Bütün əmrlərə/parametrlərə təkmil girişi təmin edir. Çox diqqətli olun!") :
                                missionItem.commandDescription
        }

        ColumnLayout {
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _margin
            visible:            missionItem.isTakeoffItem && missionItem.wizardMode // Hack special case for takeoff item

            QGCLabel {
                text:               qsTr("Move '%1' %2 to the %3 location. %4")
                .arg(_controllerVehicle.vtol ? qsTr("T") : qsTr("T"))
                .arg(_controllerVehicle.vtol ? qsTr("Transition Direction") : qsTr("Takeoff"))
                .arg(_controllerVehicle.vtol ? qsTr("desired") : qsTr("climbout"))
                .arg(_controllerVehicle.vtol ? (qsTr("Başlamadan keçid istiqamətinə qədər olan məsafənin keçidi başa çatdırmaq üçün kifayət qədər uzaq olduğundan əmin olun.")) : "")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            !initialClickLabel.visible
            }

            QGCLabel {
                text:               qsTr("Maneələrdən uzaq durun və küləyə doğru gedin.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            !initialClickLabel.visible
            }

            QGCButton {
                text:               qsTr("Done")
                Layout.fillWidth:   true
                visible:            !initialClickLabel.visible
                onClicked: {
                    missionItem.wizardMode = false
                }
            }

            QGCLabel {
                id:                 initialClickLabel
                text:               missionItem.launchTakeoffAtSameLocation ?
                                        qsTr("Planlaşdırılan uçuş yerini təyin etmək üçün xəritədə klikləyin.") :
                                        qsTr("Planlaşdırılmış Başlama yerini təyin etmək üçün xəritədə klikləyin.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            missionItem.isTakeoffItem && !missionItem.launchCoordinate.isValid
            }
        }

        Column {
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _altRectMargin
            visible:            !missionItem.wizardMode

            ColumnLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                spacing:        0
                visible:        _specifiesAltitude

                QGCLabel {
                    Layout.fillWidth:   true
                    wrapMode:           Text.WordWrap
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               qsTr("Aşağıdakı hündürlük yerin təxmini hündürlüyünü göstərir. Normal olaraq, orijinal işə salınma yerinə enmək üçün 0-dır.")
                    visible:            missionItem.isLandCommand
                }

                // Etiket solda, dəyər sahəsi sağda — eyni sətirdə
                RowLayout {
                    Layout.fillWidth:   true
                    Layout.topMargin:   _altRectMargin
                    spacing:            _altRectMargin

                    MouseArea {
                        Layout.fillWidth:       true
                        Layout.minimumWidth:    0
                        Layout.preferredHeight: altLabelRow.implicitHeight
                        Layout.alignment:       Qt.AlignVCenter
                        cursorShape:            _globalAltModeIsMixed ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onClicked: {
                            if (_globalAltModeIsMixed) {
                                var removeModes = []
                                var updateFunction = function(altMode){ missionItem.altitudeMode = altMode }
                                if (!_controllerVehicle.supportsTerrainFrame) {
                                    removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                                }
                                if (!QGroundControl.corePlugin.options.showMissionAbsoluteAltitude && missionItem.altitudeMode !== QGroundControl.AltitudeModeAbsolute) {
                                    removeModes.push(QGroundControl.AltitudeModeAbsolute)
                                }
                                removeModes.push(QGroundControl.AltitudeModeMixed)
                                altModeDialogComponent.createObject(mainWindow, { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }).open()
                            }
                        }

                        RowLayout {
                            id:             altLabelRow
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing:        _altRectMargin * 0.8

                            QGCLabel {
                                text:               qsTr("Hündürlük")
                                font.pointSize:     ScreenTools.smallFontPointSize
                                Layout.alignment:   Qt.AlignVCenter
                            }
                            QGCLabel {
                                id:                 altModeLabel
                                Layout.fillWidth:   true
                                Layout.minimumWidth: 0
                                Layout.alignment:   Qt.AlignVCenter
                                elide:              Text.ElideRight
                                font.pointSize:     ScreenTools.smallFontPointSize
                                visible:            _globalAltMode !== QGroundControl.AltitudeModeRelative
                            }
                            QGCColoredImage {
                                height:             ScreenTools.defaultFontPixelHeight / 2
                                width:              height
                                Layout.alignment:   Qt.AlignVCenter
                                source:             "/res/DropArrow.svg"
                                color:              qgcPal.text
                                visible:            _globalAltModeIsMixed
                            }
                        }
                    }

                    FactTextField {
                        id:                     altField
                        Layout.preferredWidth:  _fieldW
                        Layout.minimumWidth:    0
                        Layout.alignment:       Qt.AlignRight | Qt.AlignVCenter
                        fact:                   missionItem.altitude
                    }
                }

                QGCLabel {
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               qsTr("Actual AMSL alt sent: %1 %2").arg(missionItem.amslAltAboveTerrain.valueString).arg(missionItem.amslAltAboveTerrain.units)
                    visible:            missionItem.altitudeMode === QGroundControl.AltitudeModeCalcAboveTerrain
                }
            }

            ColumnLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                spacing:        _margin

                Repeater {
                    model: missionItem.comboboxFacts

                    ColumnLayout {
                        Layout.fillWidth:   true
                        spacing:            0

                        QGCLabel {
                            font.pointSize:      ScreenTools.smallFontPointSize
                            text:                object.name
                            visible:             object.name !== ""
                            Layout.fillWidth:    true
                            Layout.minimumWidth: 0
                            elide:               Text.ElideRight
                        }

                        FactComboBox {
                            Layout.fillWidth:   true
                            Layout.minimumWidth: 0
                            sizeToContents:     false
                            indexModel:         false
                            model:              object.enumStrings
                            fact:               object
                        }
                    }
                }
            }

            // Hər sətir öz RowLayout-udur: etiket artıq eni udur, sahənin eni
            // isə simpleItemEditor._fieldW ilə məhdudlaşır. Əvvəlki iki sütunlu GridLayout-da
            // sütunun eni ən enli elementin minimumu qədər olurdu və cüt
            // panelə sığmayanda sahələr sağ kənardan çıxırdı.
            ColumnLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                spacing:        simpleItemEditor._margin

                Repeater {
                    model: missionItem.textFieldFacts

                    RowLayout {
                        Layout.fillWidth:   true
                        spacing:            simpleItemEditor._altRectMargin

                        QGCLabel {
                            text:                object.name
                            Layout.fillWidth:    true
                            Layout.minimumWidth: 0
                            Layout.alignment:    Qt.AlignVCenter
                            elide:               Text.ElideRight
                        }

                        FactTextField {
                            showUnits:              true
                            fact:                   object
                            Layout.preferredWidth:  simpleItemEditor._fieldW
                            Layout.maximumWidth:    simpleItemEditor._fieldW
                            Layout.minimumWidth:    0
                            Layout.alignment:       Qt.AlignRight | Qt.AlignVCenter
                            enabled:                !object.readOnly
                        }
                    }
                }

                Repeater {
                    model: missionItem.nanFacts

                    RowLayout {
                        Layout.fillWidth:   true
                        spacing:            simpleItemEditor._altRectMargin

                        QGCCheckBox {
                            text:                object.name
                            checked:             !isNaN(object.rawValue)
                            onClicked:           object.rawValue = checked ? 0 : NaN
                            textWrapMode:        Text.Wrap
                            Layout.fillWidth:    true
                            Layout.minimumWidth: 0
                            Layout.alignment:    Qt.AlignVCenter
                        }

                        FactTextField {
                            showUnits:              true
                            fact:                   object
                            Layout.preferredWidth:  simpleItemEditor._fieldW
                            Layout.maximumWidth:    simpleItemEditor._fieldW
                            Layout.minimumWidth:    0
                            Layout.alignment:       Qt.AlignRight | Qt.AlignVCenter
                            enabled:                !isNaN(object.rawValue)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth:   true
                    spacing:            simpleItemEditor._altRectMargin
                    visible:            missionItem.speedSection.available

                    QGCCheckBox {
                        id:                  flightSpeedCheckbox
                        text:                qsTr("Flight Speed")
                        checked:             missionItem.speedSection.specifyFlightSpeed
                        onClicked:           missionItem.speedSection.specifyFlightSpeed = checked
                        textWrapMode:        Text.Wrap
                        Layout.fillWidth:    true
                        Layout.minimumWidth: 0
                        Layout.alignment:    Qt.AlignVCenter
                    }

                    FactTextField {
                        fact:                   missionItem.speedSection.flightSpeed
                        Layout.preferredWidth:  simpleItemEditor._fieldW
                        Layout.maximumWidth:    simpleItemEditor._fieldW
                        Layout.minimumWidth:    0
                        Layout.alignment:       Qt.AlignRight | Qt.AlignVCenter
                        enabled:                flightSpeedCheckbox.checked
                    }
                }
            }

            CameraSection {
                checked:    missionItem.cameraSection.settingsSpecified
                visible:    missionItem.cameraSection.available
            }
        }
    }
}

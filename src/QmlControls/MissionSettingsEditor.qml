// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts

// import QGroundControl


// import QGroundControl.Controls
// import QGroundControl.FactControls









import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

// Editor for Mission Settings
Rectangle {
    id:                 valuesRect
    width:              availableWidth
    height:             valuesColumn.implicitHeight + (_pad * 2)
    color:              "#3D3B3B"
    visible:            missionItem.isCurrentItem
    radius:             12
    border.width:       1
    border.color:       "#9D9D9D"

    property var    _masterControler:               masterController
    property var    _missionController:             _masterControler.missionController
    property var    _controllerVehicle:             _masterControler.controllerVehicle
    property bool   _vehicleHasHomePosition:        _controllerVehicle.homePosition.isValid
    property bool   _showCruiseSpeed:               !_controllerVehicle.multiRotor
    property bool   _showHoverSpeed:                _controllerVehicle.multiRotor || _controllerVehicle.vtol
    property bool   _multipleFirmware:              !QGroundControl.singleFirmwareSupport
    property bool   _multipleVehicleTypes:          !QGroundControl.singleVehicleSupport
    property bool   _mobile:                        ScreenTools.isMobile
    property var    _savePath:                      QGroundControl.settingsManager.appSettings.missionSavePath
    property var    _fileExtension:                 QGroundControl.settingsManager.appSettings.missionFileExtension
    property var    _appSettings:                   QGroundControl.settingsManager.appSettings
    property bool   _waypointsOnlyMode:             QGroundControl.corePlugin.options.missionWaypointsOnly
    property bool   _showCameraSection:             (_waypointsOnlyMode || QGroundControl.corePlugin.showAdvancedUI) && !_controllerVehicle.apmFirmware
    property bool   _simpleMissionStart:            QGroundControl.corePlugin.options.showSimpleMissionStart
    property bool   _showFlightSpeed:               !_controllerVehicle.vtol && !_simpleMissionStart && !_controllerVehicle.apmFirmware
    property bool   _allowFWVehicleTypeSelection:   _noMissionItemsAdded && !globals.activeVehicle

    readonly property string _firmwareLabel:    qsTr("Firmware")
    readonly property string _vehicleLabel:     qsTr("Vehicle")

    // ---- Ölçü sistemi: hər şey panel eninə görə hesablanır, sabit koordinat yoxdur ----
    readonly property real _pad:    Math.max(8,  ScreenTools.defaultFontPixelWidth  * 0.9)
    readonly property real _rowH:   Math.max(42, ScreenTools.defaultFontPixelHeight * 2.3)
    readonly property real _ctrlW:  Math.max(96, Math.min(155, (availableWidth - _pad * 2) * 0.46))
    readonly property real _margin: _pad * 0.6

    QGCPalette { id: qgcPal }
    Component { id: altModeDialogComponent; AltModeDialog { } }

    Connections {
        target: _controllerVehicle
        function onSupportsTerrainFrameChanged() {
            if (!_controllerVehicle.supportsTerrainFrame && _missionController.globalAltitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
                _missionController.globalAltitudeMode = QGroundControl.AltitudeModeCalcAboveTerrain
            }
        }
    }

    // ==========================================================
    // Təkrar istifadə olunan hissələr
    // (inline komponentlər xarici id-lərə baxa bilmədiyi üçün
    //  lazımi ölçülər property kimi ötürülür)
    // ==========================================================

    /// Etiket solda, kontrol sağda — sabit enli sətir
    component SettingRow: Rectangle {
        id: srow

        property alias  label:   srowLabel.text
        property real   pad:     8
        property real   ctrlW:   120
        property real   rowH:    38
        default property alias content: srowContent.data

        width:  parent ? parent.width : 0
        height: rowH
        radius: 8
        color:  "#2A2A2A"

        QGCLabel {
            id: srowLabel
            anchors.left:           parent.left
            anchors.leftMargin:     srow.pad
            anchors.right:          srowContent.left
            anchors.rightMargin:    srow.pad * 0.6
            anchors.verticalCenter: parent.verticalCenter
            color:                  "#FFFFFF"
            font.pointSize:         ScreenTools.defaultFontPointSize
            elide:                  Text.ElideRight
            maximumLineCount:       2
            wrapMode:               Text.WordWrap
        }

        Item {
            id: srowContent
            anchors.right:          parent.right
            anchors.rightMargin:    srow.pad
            anchors.verticalCenter: parent.verticalCenter
            width:                  srow.ctrlW
            height:                 Math.max(28, srow.rowH - 12)
        }
    }

    /// Açılıb-bağlanan blok
    component SectionBlock: Item {
        id: sec

        property string title:    ""
        property bool   expanded: false
        property real   pad:      8
        default property alias content: secContent.data

        width:  parent ? parent.width : 0
        height: secHeader.height + (expanded ? (secContent.implicitHeight + sec.pad * 0.8) : 0)
        clip:   true

        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.InOutQuad } }

        Rectangle {
            id: secHeader
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         Math.max(40, ScreenTools.defaultFontPixelHeight * 2.2)
            radius:         8
            color:          secMouse.containsMouse ? "#3A3A3A" : "#2A2A2A"

            Behavior on color { ColorAnimation { duration: 120 } }

            // Açıq olduğunu bildirən sol kənar
            Rectangle {
                anchors.left:           parent.left
                anchors.leftMargin:     1
                anchors.verticalCenter: parent.verticalCenter
                width:                  3
                height:                 parent.height * 0.55
                radius:                 1.5
                color:                  "#00C853"
                visible:                sec.expanded
            }

            QGCLabel {
                anchors.left:           parent.left
                anchors.leftMargin:     sec.pad
                anchors.right:          secChevron.left
                anchors.rightMargin:    sec.pad * 0.5
                anchors.verticalCenter: parent.verticalCenter
                text:                   sec.title
                color:                  "#FFFFFF"
                font.bold:              true
                font.pointSize:         ScreenTools.defaultFontPointSize
                elide:                  Text.ElideRight
            }

            QGCColoredImage {
                id: secChevron
                anchors.right:          parent.right
                anchors.rightMargin:    sec.pad
                anchors.verticalCenter: parent.verticalCenter
                width:                  Math.max(10, ScreenTools.defaultFontPixelHeight * 0.45)
                height:                 width
                source:                 "/res/DropArrow.svg"
                color:                  "#CFCFCF"
                rotation:               sec.expanded ? 180 : 0

                Behavior on rotation { NumberAnimation { duration: 140 } }
            }

            MouseArea {
                id: secMouse
                anchors.fill:   parent
                hoverEnabled:   true
                cursorShape:    Qt.PointingHandCursor
                onClicked:      sec.expanded = !sec.expanded
            }
        }

        Column {
            id: secContent
            anchors.top:        secHeader.bottom
            anchors.topMargin:  sec.pad * 0.8
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            sec.pad * 0.6
            visible:            sec.expanded
        }
    }

    /// Blok daxilindəki izahat mətni
    component NoteLabel: QGCLabel {
        width:               parent ? parent.width : 0
        wrapMode:            Text.WordWrap
        horizontalAlignment: Text.AlignLeft
        font.pointSize:      ScreenTools.defaultFontPointSize * 0.95
        color:               "#B9B9B9"
    }

    // ==========================================================
    // Məzmun
    // ==========================================================
    Column {
        id:                 valuesColumn
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.margins:    valuesRect._pad
        spacing:            valuesRect._pad * 0.7

        // ---------- Bütün yüksəkliklər ----------
        SettingRow {
            label:  qsTr("Bütün yüksəkliklər")
            pad:    valuesRect._pad
            ctrlW:  valuesRect._ctrlW
            rowH:   valuesRect._rowH

            Rectangle {
                anchors.fill:   parent
                radius:         6
                color:          altModeMouse.containsMouse ? "#4A4A4A" : "#3D3B3B"
                border.width:   1
                border.color:   "#5D5B5B"

                Behavior on color { ColorAnimation { duration: 120 } }

                QGCLabel {
                    id:                     altModeLabel
                    anchors.left:           parent.left
                    anchors.leftMargin:     6
                    anchors.right:          altModeArrow.left
                    anchors.rightMargin:    4
                    anchors.verticalCenter: parent.verticalCenter
                    text:                   QGroundControl.altitudeModeShortDescription(_missionController.globalAltitudeMode)
                    font.pointSize:         ScreenTools.defaultFontPointSize
                    elide:                  Text.ElideRight
                }

                QGCColoredImage {
                    id:                     altModeArrow
                    anchors.right:          parent.right
                    anchors.rightMargin:    6
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  Math.max(9, ScreenTools.defaultFontPixelHeight * 0.4)
                    height:                 width
                    source:                 "/res/DropArrow.svg"
                    color:                  altModeLabel.color
                }

                MouseArea {
                    id:             altModeMouse
                    anchors.fill:   parent
                    hoverEnabled:   true
                    cursorShape:    Qt.PointingHandCursor
                    onClicked: {
                        var removeModes = []
                        var updateFunction = function(altMode){ _missionController.globalAltitudeMode = altMode }
                        if (!_controllerVehicle.supportsTerrainFrame) {
                            removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                        }
                        if (!_noMissionItemsAdded) {
                            if (_missionController.globalAltitudeMode !== QGroundControl.AltitudeModeRelative) {
                                removeModes.push(QGroundControl.AltitudeModeRelative)
                            }
                            if (_missionController.globalAltitudeMode !== QGroundControl.AltitudeModeAbsolute) {
                                removeModes.push(QGroundControl.AltitudeModeAbsolute)
                            }
                            if (_missionController.globalAltitudeMode !== QGroundControl.AltitudeModeCalcAboveTerrain) {
                                removeModes.push(QGroundControl.AltitudeModeCalcAboveTerrain)
                            }
                            if (_missionController.globalAltitudeMode !== QGroundControl.AltitudeModeTerrainFrame) {
                                removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                            }
                        }
                        altModeDialogComponent.createObject(mainWindow, { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }).open()
                    }
                }
            }
        }

        // ---------- İlkin waypoint hündürlüyü ----------
        SettingRow {
            label:  qsTr("İlkin Waypoint Hündürlüyü")
            pad:    valuesRect._pad
            ctrlW:  valuesRect._ctrlW
            rowH:   valuesRect._rowH

            FactTextField {
                anchors.fill: parent
                fact:         QGroundControl.settingsManager.appSettings.defaultMissionItemAltitude
            }
        }

        // ---------- Uçuş sürəti ----------
        Rectangle {
            width:      parent.width
            height:     valuesRect._rowH
            radius:     8
            color:      "#2A2A2A"
            visible:    _showFlightSpeed

            QGCCheckBox {
                id:                     flightSpeedCheckBox
                anchors.left:           parent.left
                anchors.leftMargin:     valuesRect._pad
                anchors.right:          flightSpeedField.left
                anchors.rightMargin:    valuesRect._pad * 0.6
                anchors.verticalCenter: parent.verticalCenter
                text:                   qsTr("Uçuş sürəti")
                checked:                missionItem.speedSection.specifyFlightSpeed
                onClicked:              missionItem.speedSection.specifyFlightSpeed = checked
            }

            FactTextField {
                id:                     flightSpeedField
                anchors.right:          parent.right
                anchors.rightMargin:    valuesRect._pad
                anchors.verticalCenter: parent.verticalCenter
                width:                  valuesRect._ctrlW
                height:                 Math.max(28, valuesRect._rowH - 12)
                fact:                   missionItem.speedSection.flightSpeed
                enabled:                flightSpeedCheckBox.checked
                opacity:                enabled ? 1.0 : 0.5
            }
        }

        // ---------- Kamera ----------
        Column {
            width:      parent.width
            spacing:    valuesRect._pad * 0.6
            visible:    !_simpleMissionStart

            CameraSection {
                id:         cameraSection
                checked:    !_waypointsOnlyMode && missionItem.cameraSection.settingsSpecified
                visible:    _showCameraSection
            }

            NoteLabel {
                text:    qsTr("Yuxarıdakı kamera əmrləri missiya başladıqdan dərhal sonra qüvvəyə minəcək.")
                visible: _showCameraSection && cameraSection.checked
            }

            // ---------- Təyyarə məlumatı ----------
            SectionBlock {
                id:         vehicleInfoSection
                title:      qsTr("Təyyarə Məlumatı")
                pad:        valuesRect._pad
                visible:    !_waypointsOnlyMode

                SettingRow {
                    label:      _firmwareLabel
                    pad:        valuesRect._pad
                    ctrlW:      valuesRect._ctrlW
                    rowH:       valuesRect._rowH
                    visible:    _multipleFirmware

                    FactComboBox {
                        anchors.fill:   parent
                        fact:           QGroundControl.settingsManager.appSettings.offlineEditingFirmwareClass
                        indexModel:     false
                        sizeToContents: false
                        visible:        _allowFWVehicleTypeSelection

                        background: Rectangle {
                            color:          "#3D3B3B"
                            radius:         6
                            border.color:   "#5D5B5B"
                            border.width:   1
                        }
                    }

                    QGCLabel {
                        anchors.fill:           parent
                        verticalAlignment:      Text.AlignVCenter
                        horizontalAlignment:    Text.AlignRight
                        text:                   _controllerVehicle.firmwareTypeString
                        font.pointSize:         ScreenTools.defaultFontPointSize
                        elide:                  Text.ElideRight
                        visible:                !_allowFWVehicleTypeSelection
                    }
                }

                SettingRow {
                    label:      _vehicleLabel
                    pad:        valuesRect._pad
                    ctrlW:      valuesRect._ctrlW
                    rowH:       valuesRect._rowH
                    visible:    _multipleVehicleTypes

                    FactComboBox {
                        anchors.fill:   parent
                        fact:           QGroundControl.settingsManager.appSettings.offlineEditingVehicleClass
                        indexModel:     false
                        sizeToContents: false
                        visible:        _allowFWVehicleTypeSelection

                        background: Rectangle {
                            color:          "#3D3B3B"
                            radius:         6
                            border.color:   "#5D5B5B"
                            border.width:   1
                        }
                    }

                    QGCLabel {
                        anchors.fill:           parent
                        verticalAlignment:      Text.AlignVCenter
                        horizontalAlignment:    Text.AlignRight
                        text:                   _controllerVehicle.vehicleTypeString
                        font.pointSize:         ScreenTools.defaultFontPointSize
                        elide:                  Text.ElideRight
                        visible:                !_allowFWVehicleTypeSelection
                    }
                }

                NoteLabel {
                    text:    qsTr("Aşağıdakı sürət dəyərləri yalnız ümumi missiya vaxtını hesablamaq üçündür; missiyanın faktiki uçuş sürətinə təsir etmir.")
                    visible: _showCruiseSpeed || _showHoverSpeed
                }

                SettingRow {
                    label:      qsTr("Kruiz sürəti")
                    pad:        valuesRect._pad
                    ctrlW:      valuesRect._ctrlW
                    rowH:       valuesRect._rowH
                    visible:    _showCruiseSpeed

                    FactTextField {
                        anchors.fill:   parent
                        fact:           QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed
                    }
                }

                SettingRow {
                    label:      qsTr("Hover sürəti")
                    pad:        valuesRect._pad
                    ctrlW:      valuesRect._ctrlW
                    rowH:       valuesRect._rowH
                    visible:    _showHoverSpeed

                    FactTextField {
                        anchors.fill:   parent
                        fact:           QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed
                    }
                }
            }

            // ---------- Başlama mövqeyi ----------
            SectionBlock {
                id:         launchPositionSection
                title:      qsTr("Başlama mövqeyi")
                pad:        valuesRect._pad
                visible:    !_vehicleHasHomePosition

                SettingRow {
                    label:  qsTr("Hündürlük")
                    pad:    valuesRect._pad
                    ctrlW:  valuesRect._ctrlW
                    rowH:   valuesRect._rowH

                    FactTextField {
                        anchors.fill:   parent
                        fact:           missionItem.plannedHomePositionAltitude
                    }
                }

                NoteLabel {
                    text: qsTr("Uçuş zamanı təyyarə tərəfindən müəyyən edilmiş faktiki mövqe.")
                }

                QGCButton {
                    width:           parent.width
                    text:            qsTr("Xəritə Mərkəzinə Ayarlayın")
                    backgroundColor: "#474747"
                    onClicked:       missionItem.coordinate = map.center
                }
            }
        } // Column
    } // Column
} // Rectangle

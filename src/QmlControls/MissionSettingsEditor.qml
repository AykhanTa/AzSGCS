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
    color:              "transparent"
    visible:            missionItem.isCurrentItem

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

        width:        parent ? parent.width : 0
        height:       rowH
        radius:       AzTheme.px(AzTheme.groupRadius)
        color:        AzTheme.groupFill
        border.width: 1
        border.color: AzTheme.groupBorder

        QGCLabel {
            id: srowLabel
            anchors.left:           parent.left
            anchors.leftMargin:     srow.pad
            anchors.right:          srowContent.left
            anchors.rightMargin:    srow.pad * 0.6
            anchors.verticalCenter: parent.verticalCenter
            color:                  AzTheme.textCard
            font.pixelSize:         AzTheme.fontPx(13)
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
            radius:         AzTheme.px(AzTheme.groupRadius)
            color:          AzTheme.groupFill
            border.width:   1
            border.color:   secMouse.containsMouse ? AzTheme.cardHoverBorder : AzTheme.groupBorder

            Behavior on color { ColorAnimation { duration: 120 } }

            // Açıq olduğunu bildirən sol kənar
            Rectangle {
                anchors.left:           parent.left
                anchors.leftMargin:     1
                anchors.verticalCenter: parent.verticalCenter
                width:                  3
                height:                 parent.height * 0.55
                radius:                 1.5
                color:                  AzTheme.statusGreen
                visible:                sec.expanded
            }

            QGCLabel {
                anchors.left:           parent.left
                anchors.leftMargin:     sec.pad
                anchors.right:          secChevron.left
                anchors.rightMargin:    sec.pad * 0.5
                anchors.verticalCenter: parent.verticalCenter
                text:                   sec.title
                color:                  AzTheme.textCard
                font.weight:            Font.Medium
                font.pixelSize:         AzTheme.fontPx(14)
                elide:                  Text.ElideRight
            }

            QGCColoredImage {
                id: secChevron
                anchors.right:          parent.right
                anchors.rightMargin:    sec.pad
                anchors.verticalCenter: parent.verticalCenter
                width:                  Math.max(10, ScreenTools.defaultFontPixelHeight * 0.45)
                height:                 width
                source:                 "qrc:/res/AZSHIELD_ICON/v2/popup_chevron.svg"
                color:                  AzTheme.textSecondary
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
        font.pixelSize:      AzTheme.fontPx(12)
        color:               AzTheme.textSecondary
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
                radius:         AzTheme.px(8)
                color:          AzTheme.pillBottom
                border.width:   1
                border.color:   altModeMouse.containsMouse ? AzTheme.cardHoverBorder : AzTheme.panelBorder

                Behavior on color { ColorAnimation { duration: 120 } }

                QGCLabel {
                    id:                     altModeLabel
                    anchors.left:           parent.left
                    anchors.leftMargin:     AzTheme.px(8)
                    anchors.right:          altModeArrow.left
                    anchors.rightMargin:    4
                    anchors.verticalCenter: parent.verticalCenter
                    text:                   QGroundControl.altitudeModeShortDescription(_missionController.globalAltitudeMode)
                    font.pixelSize:         AzTheme.fontPx(13)
                    elide:                  Text.ElideRight
                }

                QGCColoredImage {
                    id:                     altModeArrow
                    anchors.right:          parent.right
                    anchors.rightMargin:    AzTheme.px(8)
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  AzTheme.px(14)
                    height:                 width
                    sourceSize.height:      height
                    source:                 "qrc:/res/AZSHIELD_ICON/v2/popup_chevron.svg"
                    color:                  AzTheme.textSecondary
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
            id:         flightSpeedRow
            width:      parent.width
            // This is the only row whose label shares its line with a checkbox, so
            // it is the first to run out of width. Rather than pick a line count
            // that suits one screen, the row grows to whatever the wrapped label
            // needs - two lines on a G30, three on the narrower G20.
            height:     Math.max(valuesRect._rowH, flightSpeedCheckBox.implicitHeight + valuesRect._pad)
            radius:       AzTheme.px(AzTheme.groupRadius)
            color:        AzTheme.groupFill
            border.width: 1
            border.color: AzTheme.groupBorder
            visible:      _showFlightSpeed

            QGCCheckBox {
                id:                     flightSpeedCheckBox
                anchors.left:           parent.left
                anchors.leftMargin:     valuesRect._pad
                anchors.right:          flightSpeedField.left
                anchors.rightMargin:    valuesRect._pad * 0.6
                anchors.verticalCenter: parent.verticalCenter
                textWrapMode:           Text.Wrap
                spacing:                ScreenTools.defaultFontPixelWidth * 0.4
                text:                   qsTr("Uçuş sürəti")
                checked:                missionItem.speedSection.specifyFlightSpeed
                onClicked:              missionItem.speedSection.specifyFlightSpeed = checked
            }

            FactTextField {
                id:                     flightSpeedField
                anchors.right:          parent.right
                anchors.rightMargin:    valuesRect._pad
                anchors.verticalCenter: parent.verticalCenter
                // Holds a speed like "15.0", so it takes only what that needs and
                // leaves the rest of the row to the label, which needs it more.
                width:                  Math.min(valuesRect._ctrlW, ScreenTools.defaultFontPixelWidth * 6)
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
                    onClicked:       missionItem.coordinate = map.center
                }
            }
        } // Column
    } // Column
} // Rectangle

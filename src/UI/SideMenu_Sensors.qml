// Sensor calibration, in the new design: the vehicle setup page header, the
// calibration buttons with a red dot until done, the status log and the orientation
// steps on group boxes, and a green progress bar.

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

Item {
    id: _root

    // The buttons, labels, combo boxes and the orientation steps take the new
    // design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ======================
    // Click blocker
    // ======================
    Item {
        anchors.fill: parent
        z: 0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onWheel: (wheel) => { wheel.accepted = true }
        }
    }

    // ======================
    // Responsive
    // ======================
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property bool _stacked: (width < 1000) || ScreenTools.isShortScreen

    // Bu səhifə SetupView kontekstindən kənarda yüklənir, ona görə "vehicleComponent"
    // scope-da olmur. Sensors VehicleComponent-ini birbaşa autopilot plugin-dən götürürük
    // ki, airspeedCalSupported düzgün hesablansın (yalnız sabitqanad/VTOL/airship + uyğun
    // hava sürəti parametrləri olduqda true olur).
    readonly property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    readonly property var _sensorsVehicleComponent: {
        var v = _activeVehicle
        // parametersReady yoxlanışı həm binding dependency verir, həm də
        // vehicleComponents-in vaxtından əvvəl çağırılmasının qarşısını alır.
        if (!v || !v.parameterManager || !v.parameterManager.parametersReady) return null
        var ap = v.autopilotPlugin
        if (!ap || ap.vehicleComponents.length === 0) return null
        return ap.findKnownVehicleComponent(AutoPilotPlugin.KnownSensorsVehicleComponent)
    }

    readonly property real _m:            AzTheme.px(_compact ? 12 : 16)
    readonly property real _side:         AzTheme.px(_stacked ? 12 : 20)
    readonly property real _top:          AzTheme.px(20)
    readonly property real _maxContentW:  1700

    // Right button panel width (wide-da)
    property int _buttonWidth: {
        var minW = ScreenTools.defaultFontPixelWidth * 16
        var maxW = ScreenTools.defaultFontPixelWidth * 24
        var w    = Math.floor(width * 0.22)
        w = Math.max(minW, w)
        w = Math.min(maxW, w)
        return w
    }

    // ======================
    // Original flags/signals
    // ======================
    property bool   showSensorCalibrationCompass:   true
    property bool   showSensorCalibrationGyro:      true
    property bool   showSensorCalibrationAccel:     true
    property bool   showSensorCalibrationLevel:     true
    property bool   showSensorCalibrationAirspeed:  true
    property bool   showSetOrientations:            true
    property bool   showNextButton:                 false

    signal nextButtonClicked

    readonly property string boardRotationText: qsTr("Əgər oriyentasiya uçuş istiqamətində olarsa, select ROTATION_NONE.")
    readonly property string compassRotationText: qsTr("Əgər oriyentasiya uçuş istiqamətində olarsa, select ROTATION_NONE.")

    readonly property string compassHelp:   qsTr("Kompas kalibrləməsi üçün siz təyyarənizi bir sıra mövqelərdə fırlatmalısınız.")
    readonly property string gyroHelp:      qsTr("Gyroskopun kalibrlənməsi üçün siz təyyarənizi səthə qoymalı və hərəkətsiz qoymalısınız.")
    readonly property string accelHelp:     qsTr("Akselerometrin kalibrlənməsi üçün siz təyyarənizi altı tərəfdən mükəmməl düz bir səthə yerləşdirməli və hər bir istiqamət üzrə hərəkətsiz bir neçə saniyə saxlamalısınız.")
    readonly property string levelHelp:     qsTr("Üfüqü düzəltmək üçün təyyarəni öz səviyyəli uçuş vəziyyətinə salıb hərəkətsiz tərk etməlisiniz.")
    readonly property string airspeedHelp:  qsTr("Hava sürətinin kalibrlənməsi üçün siz hava sürəti sensorunuzu hər hansı küləkdən uzaq tutmalı və sonra sensora üfləməlisiniz. Kalibrləmə zamanı sensora toxunmayın və ya heç bir deşikə mane olmayın.")

    readonly property string statusTextAreaDefaultText: qsTr("Kalibrləməyə başlamaq üçün düymələrdən birini seçin.")

    property string preCalibrationDialogType
    property string preCalibrationDialogHelp

    // ======================
    // Facts / Params
    // ======================
    property Fact cal_mag0_id:      controller.getParameterFact(-1, "CAL_MAG0_ID")
    property Fact cal_mag1_id:      controller.getParameterFact(-1, "CAL_MAG1_ID")
    property Fact cal_mag2_id:      controller.getParameterFact(-1, "CAL_MAG2_ID")
    property Fact cal_mag0_rot:     controller.getParameterFact(-1, "CAL_MAG0_ROT")
    property Fact cal_mag1_rot:     controller.getParameterFact(-1, "CAL_MAG1_ROT")
    property Fact cal_mag2_rot:     controller.getParameterFact(-1, "CAL_MAG2_ROT")

    property Fact cal_gyro0_id:     controller.getParameterFact(-1, "CAL_GYRO0_ID")
    property Fact cal_acc0_id:      controller.getParameterFact(-1, "CAL_ACC0_ID")

    property Fact sens_board_rot:   controller.getParameterFact(-1, "SENS_BOARD_ROT")
    property Fact sens_dpres_off:   controller.getParameterFact(-1, "SENS_DPRES_OFF")

    // Id >= 0 => compass available, rot < 0 => internal compass
    property bool showCompass0Rot: cal_mag0_id.value > 0 && cal_mag0_rot.value >= 0
    property bool showCompass1Rot: cal_mag1_id.value > 0 && cal_mag1_rot.value >= 0
    property bool showCompass2Rot: cal_mag2_id.value > 0 && cal_mag2_rot.value >= 0

    property bool   _sensorsHaveFixedOrientation:       QGroundControl.corePlugin.options.sensorsHaveFixedOrientation
    property bool   _wifiReliableForCalibration:        QGroundControl.corePlugin.options.wifiReliableForCalibration
    property string _calMagIdParamFormat:               "CAL_MAG#_ID"
    property string _calMagRotParamFormat:              "CAL_MAG#_ROT"
    property bool   _allMagsDisabled:                   controller.parameterExists(-1, "SYS_HAS_MAG") ? controller.getParameterFact(-1, "SYS_HAS_MAG").value === 0 : false
    property bool   _boardOrientationChangeAllowed:     !_sensorsHaveFixedOrientation && setOrientationsDialogShowBoardOrientation
    property bool   _compassOrientationChangeAllowed:   !_sensorsHaveFixedOrientation
    property int    _arbitrarilyLargeMaxMagIndex:       50

    function currentMagParamCount() {
        if (_allMagsDisabled) {
            return 0
        } else {
            for (var index=0; index<_arbitrarilyLargeMaxMagIndex; index++) {
                var magIdParam = _calMagIdParamFormat.replace("#", index)
                if (!controller.parameterExists(-1, magIdParam)) {
                    return index
                }
            }
            console.warn("SensorSetup.qml:currentMagParamCount internal error")
            return -1
        }
    }

    function currentExternalMagCount() {
        if (_allMagsDisabled) {
            return 0
        } else {
            var externalMagCount = 0
            for (var index=0; index<_arbitrarilyLargeMaxMagIndex; index++) {
                var magIdParam = _calMagIdParamFormat.replace("#", index)
                if (controller.parameterExists(-1, magIdParam)) {
                    var calMagIdFact = controller.getParameterFact(-1, magIdParam)
                    var calMagRotFact = controller.getParameterFact(-1, _calMagRotParamFormat.replace("#", index))
                    if (calMagIdFact.value > 0 && calMagRotFact.value >= 0) {
                        externalMagCount++
                    }
                } else {
                    return externalMagCount
                }
            }
            console.warn("SensorSetup.qml:currentExternalMagCount internal error")
            return 0
        }
    }

    function orientationsButtonVisible() {
        if (_sensorsHaveFixedOrientation || !showSetOrientations) {
            return false
        } else if (_boardOrientationChangeAllowed) {
            return true
        } else if (_compassOrientationChangeAllowed && !_allMagsDisabled) {
            for (var index=0; index<_arbitrarilyLargeMaxMagIndex; index++) {
                var magIdParam = _calMagIdParamFormat.replace("#", index)
                if (controller.parameterExists(-1, magIdParam)) {
                    var calMagIdFact  = controller.getParameterFact(-1, magIdParam)
                    var calMagRotFact = controller.getParameterFact(-1, _calMagRotParamFormat.replace("#", index))
                    if (calMagIdFact.value > 0 && calMagRotFact.value >= 0) {
                        return true
                    }
                }
            }
            return false
        } else {
            return false
        }
    }

    // ======================
    // WIDE ekranda statusHolder hündürlüyünü "qalan sahəyə" görə hesabla
    // -> orientasiya blokları maksimum böyüyür, boş sahə qalmır, lazımsız page scroll yaranmır
    // ======================
    function _calcStatusHolderHeight() {
        var minH = ScreenTools.defaultFontPixelHeight * 18

        // Kiçik ekranda mövcud davranışı saxlayırıq (səndə artıq düzgündür)
        if (_root._stacked) {
            return Math.max(
                        minH,
                        Math.round(_root.height * (controller.showOrientationCalArea ? 0.78 : 0.62))
                        )
        }

        // Wide: content-in ümumi hündürlüyünü ekrana "tam oturt"
        // statusHolder = pageH - header - alt boşluq - column spacing - mainCol fixed hissələr
        var headerH   = headerCol.implicitHeight
        var outerSp   = contentCol.spacing
        var bottomGap = bottomSpacer.Layout.preferredHeight

        var fixedMain = progressBar.implicitHeight
                      + factoryResetRow.implicitHeight
                      + (mainCol.spacing * 2)

        // 2px ehtiyat (yuvarlaqlaşdırma səbəbilə scroll çıxmasın)
        var target = pageFlick.height - _root._top - headerH - bottomGap - (outerSp * 2) - fixedMain - 2

        if (target < minH) target = minH
        return target
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    SensorsComponentController {
        id:                         controller
        statusLog:                  statusTextArea
        progressBar:                progressBar
        compassButton:              compassButton
        gyroButton:                 gyroButton
        accelButton:                accelButton
        airspeedButton:             airspeedButton
        levelButton:                levelButton
        cancelButton:               cancelButton
        setOrientationsButton:      setOrientationsButton
        orientationCalAreaHelpText: orientationCalAreaHelpText

        onResetStatusTextArea: statusLog.text = statusTextAreaDefaultText

        onMagCalComplete: {
            setOrientationsButton.visible               = orientationsButtonVisible()
            setOrientationsDialogShowBoardOrientation   = false
            setOrientationsDialogComponent.createObject(mainWindow, { title: qsTr("Compass Calibration Complete"), showRebootVehicleButton: true }).open()
        }

        onWaitingForCancelChanged: {
            if (controller.waitingForCancel) {
                waitForCancelDialogComponent.createObject(mainWindow).open()
            }
        }
    }

    Component.onCompleted: {
        var usingUDP = controller.usingUDPLink()
        if (usingUDP && !_wifiReliableForCalibration) {
            mainWindow.showMessageDialog(
                        qsTr("Sensor Calibration"),
                        qsTr("Performing sensor calibration over a WiFi connection is known to be unreliable. You should disconnect and perform calibration using a direct USB connection instead.")
                        )
        }
    }

    // ======================
    // Dialogs
    // ======================
    Component {
        id: waitForCancelDialogComponent
        QGCSimpleMessageDialog {
            title:      qsTr("Calibration Cancel")
            text:       qsTr("Waiting for Vehicle to response to Cancel. This may take a few seconds.")
            buttons:    0

            Connections {
                target: controller
                onWaitingForCancelChanged: {
                    if (!controller.waitingForCancel) {
                        close()
                    }
                }
            }
        }
    }

    Component {
        id: preCalibrationDialogComponent
        QGCPopupDialog {
            buttons: Dialog.Cancel | Dialog.Ok

            onAccepted: {
                if (preCalibrationDialogType == "gyro") {
                    controller.calibrateGyro()
                } else if (preCalibrationDialogType == "accel") {
                    controller.calibrateAccel()
                } else if (preCalibrationDialogType == "level") {
                    controller.calibrateLevel()
                } else if (preCalibrationDialogType == "compass") {
                    controller.calibrateCompass()
                } else if (preCalibrationDialogType == "airspeed") {
                    controller.calibrateAirspeed()
                }
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    Layout.minimumWidth:    ScreenTools.defaultFontPixelWidth * 50
                    Layout.preferredWidth:  innerColumn.width
                    wrapMode:               Text.WordWrap
                    text:                   preCalibrationDialogHelp
                }

                Column {
                    id:         innerColumn
                    spacing:    parent.spacing

                    QGCLabel {
                        id:         boardRotationHelp
                        wrapMode:   Text.WordWrap
                        visible:    !_sensorsHaveFixedOrientation && (preCalibrationDialogType == "accel" || preCalibrationDialogType == "compass")
                        text:       qsTr("Kalibrləmədən əvvəl avtopilot oriyentasiyasını təyin edin.")
                    }

                    Column {
                        visible:    boardRotationHelp.visible
                        QGCLabel { text: qsTr("Avtopilot Orientasiyası") }

                        FactComboBox {
                            sizeToContents: true
                            fact:           sens_board_rot
                        }

                        QGCLabel {
                            wrapMode:   Text.WordWrap
                            text:       qsTr("ROTATION_NONE uçuş istiqamətində komponent nöqtələrini göstərir.")
                        }
                    }

                    QGCLabel {
                        wrapMode:   Text.WordWrap
                        text:       qsTr("Kalibrləməyə başlamaq üçün Ok klikləyin..")
                    }
                }
            }
        }
    }

    property bool setOrientationsDialogShowBoardOrientation: true

    Component {
        id: setOrientationsDialogComponent

        QGCPopupDialog {
            buttons: Dialog.Ok
            property bool showRebootVehicleButton: true

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    text:       qsTr("Uçuşdan əvvəl təyyarəni yenidən işə salın..")
                    visible:    showRebootVehicleButton
                }

                QGCButton {
                    text:       qsTr("Reboot Vehicle")
                    visible:    showRebootVehicleButton
                    onClicked:  { controller.vehicle.rebootVehicle(); close() }
                }

                QGCLabel {
                    text:       qsTr("Orientasiyaları lazım olduqda tənzimləyin.\n\nROTATION_NONE uçuş istiqamətində komponent nöqtələrini göstərir.")
                    visible:    _boardOrientationChangeAllowed || (_compassOrientationChangeAllowed && currentExternalMagCount() !== 0)
                }

                Column {
                    visible: _boardOrientationChangeAllowed
                    QGCLabel { text: qsTr("Avtopilot Orientasiyası") }
                    FactComboBox { sizeToContents: true; fact: sens_board_rot }
                }

                Repeater {
                    model: _compassOrientationChangeAllowed ? currentMagParamCount() : 0

                    Column {
                        visible: calMagIdFact.value > 0 && calMagRotFact.value >= 0

                        property Fact calMagIdFact:  controller.getParameterFact(-1, _calMagIdParamFormat.replace("#", index))
                        property Fact calMagRotFact: controller.getParameterFact(-1, _calMagRotParamFormat.replace("#", index))

                        QGCLabel { text: qsTr("Mag %1 Orientation").arg(index) }
                        FactComboBox { sizeToContents: true; fact: parent.calMagRotFact }
                    }
                }
            }
        }
    }

    // ======================
    // MAIN UI
    // ======================
    QGCFlickable {
        id: pageFlick
        z: 1
        anchors.fill: parent
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        contentWidth: width

        readonly property real _scrollTol: 2
        readonly property real _contentH: contentCol.implicitHeight + _root._top
        contentHeight: (_contentH <= height + _scrollTol) ? height : _contentH
        interactive:  _contentH > height + _scrollTol

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        ColumnLayout {
            id: contentCol
            width: Math.min(pageFlick.width - (_root._side * 2), _root._maxContentW)
            x: (pageFlick.width - width) / 2
            y: _root._top
            spacing: _root._m

            // -------- Header
            ColumnLayout {
                id: headerCol
                Layout.fillWidth: true
                spacing: AzTheme.px(6)

                Text {
                    text: qsTr("Sensor Kalibrləməsi")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(_root._compact ? 18 : 20)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Kompas, giroskop, akselerometr və digər sensorları kalibrləyin və oriyentasiyanı tənzimləyin.")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(13)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // -------- Body
            GridLayout {
                id: bodyGrid
                Layout.fillWidth: true
                columns: _root._stacked ? 1 : 2
                columnSpacing: _root._m
                rowSpacing: _root._m

                // ===== Buttons panel
                Item {
                    id: buttonsPanel
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: _root._stacked
                    Layout.preferredWidth: _root._stacked ? bodyGrid.width : _root._buttonWidth
                    Layout.row: _root._stacked ? 0 : 0
                    Layout.column: _root._stacked ? 0 : 1

                    implicitHeight: buttonsFlow.implicitHeight

                    Flow {
                        id: buttonsFlow
                        width: parent.width
                        spacing: Math.max(8, _root._m * 0.7)

                        readonly property real _minBtnW: ScreenTools.defaultFontPixelWidth * 18
                        readonly property int  cols: _root._stacked
                                                    ? Math.max(1, Math.min(3, Math.floor((width + spacing) / (_minBtnW + spacing))))
                                                    : 1
                        readonly property real btnW: Math.floor((width - spacing * (cols - 1)) / cols)

                        IndicatorButton {
                            id:             compassButton
                            width:          buttonsFlow.btnW
                            text:           qsTr("Kompas")
                            indicatorGreen: cal_mag0_id.value !== 0
                            visible:        !_allMagsDisabled && QGroundControl.corePlugin.options.showSensorCalibrationCompass && showSensorCalibrationCompass

                            onClicked: {
                                preCalibrationDialogType = "compass"
                                preCalibrationDialogHelp = compassHelp
                                preCalibrationDialogComponent.createObject(mainWindow, { title: qsTr("Calibrate Compass") }).open()
                            }
                        }

                        IndicatorButton {
                            id:             gyroButton
                            width:          buttonsFlow.btnW
                            text:           qsTr("Giroskop")
                            indicatorGreen: cal_gyro0_id.value !== 0
                            visible:        QGroundControl.corePlugin.options.showSensorCalibrationGyro && showSensorCalibrationGyro

                            onClicked: {
                                preCalibrationDialogType = "gyro"
                                preCalibrationDialogHelp = gyroHelp
                                preCalibrationDialogComponent.createObject(mainWindow, { title: qsTr("Calibrate Gyro") }).open()
                            }
                        }

                        IndicatorButton {
                            id:             accelButton
                            width:          buttonsFlow.btnW
                            text:           qsTr("Akselerometr")
                            indicatorGreen: cal_acc0_id.value !== 0
                            visible:        QGroundControl.corePlugin.options.showSensorCalibrationAccel && showSensorCalibrationAccel

                            onClicked: {
                                preCalibrationDialogType = "accel"
                                preCalibrationDialogHelp = accelHelp
                                preCalibrationDialogComponent.createObject(mainWindow, { title: qsTr("Calibrate Accelerometer") }).open()
                            }
                        }

                        IndicatorButton {
                            id:             levelButton
                            width:          buttonsFlow.btnW
                            text:           qsTr("Üfüq Səviyyəsi")
                            indicatorGreen: true
                            enabled:        cal_acc0_id.value !== 0 && cal_gyro0_id.value !== 0
                            visible:        QGroundControl.corePlugin.options.showSensorCalibrationLevel && showSensorCalibrationLevel

                            onClicked: {
                                preCalibrationDialogType = "level"
                                preCalibrationDialogHelp = levelHelp
                                preCalibrationDialogComponent.createObject(mainWindow, { title: qsTr("Level Horizon") }).open()
                            }
                        }

                        IndicatorButton {
                            id:             airspeedButton
                            width:          buttonsFlow.btnW
                            text:           qsTr("Hava sürəti")
                            visible:        (_root._sensorsVehicleComponent && _root._sensorsVehicleComponent.airspeedCalSupported) &&
                                                QGroundControl.corePlugin.options.showSensorCalibrationAirspeed &&
                                                showSensorCalibrationAirspeed
                            indicatorGreen: sens_dpres_off.value !== 0

                            onClicked: {
                                preCalibrationDialogType = "airspeed"
                                preCalibrationDialogHelp = airspeedHelp
                                preCalibrationDialogComponent.createObject(mainWindow, { title: qsTr("Calibrate Airspeed") }).open()
                            }
                        }

                        QGCButton {
                            id:         cancelButton
                            width:      buttonsFlow.btnW
                            text:       qsTr("Ləğv et")
                            enabled:    false
                            onClicked:  controller.cancelCalibration()
                        }

                        QGCButton {
                            id:         nextButton
                            width:      buttonsFlow.btnW
                            text:       qsTr("Next")
                            visible:    showNextButton
                            onClicked:  _root.nextButtonClicked()
                        }

                        QGCButton {
                            id:         setOrientationsButton
                            width:      buttonsFlow.btnW
                            text:       qsTr("Orientasiyalar")
                            visible:    orientationsButtonVisible()

                            onClicked:  {
                                setOrientationsDialogShowBoardOrientation = true
                                setOrientationsDialogComponent.createObject(mainWindow, { title: qsTr("İstiqamətləri təyin edin"), showRebootVehicleButton: false }).open()
                            }
                        }
                    }
                }

                // ===== Main panel
                Item {
                    id: mainPanel
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    Layout.row: _root._stacked ? 1 : 0
                    Layout.column: 0

                    implicitHeight: mainCol.implicitHeight

                    ColumnLayout {
                        id: mainCol
                        width: parent.width
                        spacing: _root._m

                        ProgressBar {
                            id: progressBar
                            Layout.fillWidth: true

                            background: Rectangle {
                                implicitHeight: AzTheme.px(8)
                                radius:         height / 2
                                color:          AzTheme.slotEmpty
                            }

                            contentItem: Item {
                                implicitHeight: AzTheme.px(8)

                                Rectangle {
                                    width:  progressBar.visualPosition * parent.width
                                    height: parent.height
                                    radius: height / 2
                                    color:  AzTheme.statusGreen
                                }
                            }
                        }

                        Item {
                            id: statusHolder
                            Layout.fillWidth: true

                            // ✅ Wide ekranda bütün qalan sahəni doldur (bloklar böyüsün)
                            Layout.preferredHeight: _calcStatusHolderHeight()

                            TextArea {
                                id:             statusTextArea
                                anchors.fill:   parent
                                readOnly:       true
                                text:           statusTextAreaDefaultText
                                color:          AzTheme.textCard
                                font.family:    AzTheme.fontFamily
                                font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                                wrapMode:       TextEdit.WordWrap
                                padding:        AzTheme.px(AzTheme.groupPadding)

                                background: Rectangle {
                                    color:        AzTheme.groupFill
                                    radius:       AzTheme.px(AzTheme.groupRadius)
                                    border.width: 1
                                    border.color: AzTheme.groupBorder
                                }
                            }

                            Rectangle {
                                id:         orientationCalArea
                                anchors.fill: parent
                                visible:    controller.showOrientationCalArea
                                color:      AzTheme.groupFill
                                radius:     AzTheme.px(AzTheme.groupRadius)
                                border.width: 1
                                border.color: AzTheme.groupBorder

                                QGCLabel {
                                    id:                 orientationCalAreaHelpText
                                    anchors.top:        parent.top
                                    anchors.left:       parent.left
                                    anchors.right:      parent.right
                                    anchors.margins:    _root._m
                                    wrapMode:           Text.WordWrap
                                    font.pixelSize:     AzTheme.fontPx(15)
                                }

                                // ✅ ORIENTATION GRID: Böyük ekranda 3 sütun, kiçik ekranda 2 sütun
                                Item {
                                    id: calGridArea
                                    anchors.top: orientationCalAreaHelpText.bottom
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    // Wide ekranda daha çox sahə qalsın deyə margin bir az azaldılıb
                                    anchors.margins: _root._stacked ? Math.max(8, _root._m * 0.75)
                                                                   : Math.max(6, _root._m * 0.55)

                                    // Wide ekranda gap bir az az -> kartlar böyüyür
                                    readonly property real gap: _root._stacked ? Math.max(10, _root._m * 0.75)
                                                                              : Math.max(8,  _root._m * 0.55)

                                    readonly property int cols: _root._stacked
                                                               ? ((width < 520) ? 1 : 2)
                                                               : 3
                                    readonly property int totalItems: 6
                                    readonly property int rows: Math.ceil(totalItems / cols)

                                    readonly property real sizeByWidth:  Math.floor((width  - gap * (cols - 1)) / cols)
                                    readonly property real sizeByHeight: Math.floor((height - gap * (rows - 1)) / rows)

                                    // readonly property real indicatorSize: {
                                    //     var s = _root._stacked ? sizeByWidth : Math.min(sizeByWidth, sizeByHeight)
                                    //     // 1px ehtiyat (scroll "tıx-tıx" çıxmasın)
                                    //     s = Math.floor(s) - 1
                                    //     return Math.max(120, s)
                                    // }

                                    readonly property real indicatorSize: {
                                        var sW = sizeByWidth
                                        var sH = sizeByHeight
                                        var s

                                        if (_root._stacked) {
                                            // Kiçik/stacked: əvvəlki böyük variantın bir az kiçildilmişi
                                            var stackScale = 0.92     // 1.0 = əvvəlki tam böyük, 0.90-0.95 arası oynat
                                            s = sW * stackScale

                                            // G20 kimi wide-but-short ekranda həddən artıq böyüməsin
                                            var maxS = _root._compact ? 300 : 360
                                            s = Math.min(s, maxS)
                                        } else {
                                            // Böyük ekranda: həm en, həm hündürlüyə görə otursun
                                            s = Math.min(sW, sH)
                                        }

                                        // Çox balacalaşmasın (amma sütun enini də aşmasın)
                                        var minS = _root._compact ? 140 : 160
                                        s = Math.max(minS, s)
                                        s = Math.min(sW, s)

                                        s = Math.floor(s) - 1
                                        return Math.max(90, s)
                                    }



                                    readonly property real gridW: cols * indicatorSize + gap * (cols - 1)
                                    readonly property real gridH: rows * indicatorSize + gap * (rows - 1)

                                    Flickable {
                                        id: calFlick
                                        anchors.fill: parent
                                        clip: true
                                        boundsBehavior: Flickable.StopAtBounds

                                        contentWidth:  width
                                        contentHeight: Math.max(height, calContent.height)
                                        interactive:   calGrid.height > height + 2

                                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                                        Item {
                                            id: calContent
                                            width: calFlick.width
                                            height: Math.max(calFlick.height, calGrid.height)

                                            Grid {
                                                id: calGrid
                                                columns: calGridArea.cols
                                                spacing: calGridArea.gap

                                                width: calGridArea.gridW
                                                height: calGridArea.gridH

                                                x: Math.max(0, (calContent.width - width) / 2)
                                                y: calFlick.interactive ? 0 : Math.max(0, (calContent.height - height) / 2)

                                                VehicleRotationCal {
                                                    width:              calGridArea.indicatorSize
                                                    height:             calGridArea.indicatorSize
                                                    visible:            controller.orientationCalDownSideVisible
                                                    calValid:           controller.orientationCalDownSideDone
                                                    calInProgress:      controller.orientationCalDownSideInProgress
                                                    calInProgressText:  controller.orientationCalDownSideRotate ? qsTr("Çevirin") : qsTr("Hələ tutun")
                                                    imageSource:        controller.orientationCalDownSideRotate ? "qrc:///qmlimages/VehicleDownRotate.png" : "qrc:///qmlimages/VehicleDown.png"
                                                }
                                                VehicleRotationCal {
                                                    width:              calGridArea.indicatorSize
                                                    height:             calGridArea.indicatorSize
                                                    visible:            controller.orientationCalUpsideDownSideVisible
                                                    calValid:           controller.orientationCalUpsideDownSideDone
                                                    calInProgress:      controller.orientationCalUpsideDownSideInProgress
                                                    calInProgressText:  controller.orientationCalUpsideDownSideRotate ? qsTr("Çevirin") : qsTr("Hələ tutun")
                                                    imageSource:        controller.orientationCalUpsideDownSideRotate ? "qrc:///qmlimages/VehicleUpsideDownRotate.png" : "qrc:///qmlimages/VehicleUpsideDown.png"
                                                }
                                                VehicleRotationCal {
                                                    width:              calGridArea.indicatorSize
                                                    height:             calGridArea.indicatorSize
                                                    visible:            controller.orientationCalNoseDownSideVisible
                                                    calValid:           controller.orientationCalNoseDownSideDone
                                                    calInProgress:      controller.orientationCalNoseDownSideInProgress
                                                    calInProgressText:  controller.orientationCalNoseDownSideRotate ? qsTr("Çevirin") : qsTr("Hələ tutun")
                                                    imageSource:        controller.orientationCalNoseDownSideRotate ? "qrc:///qmlimages/VehicleNoseDownRotate.png" : "qrc:///qmlimages/VehicleNoseDown.png"
                                                }
                                                VehicleRotationCal {
                                                    width:              calGridArea.indicatorSize
                                                    height:             calGridArea.indicatorSize
                                                    visible:            controller.orientationCalTailDownSideVisible
                                                    calValid:           controller.orientationCalTailDownSideDone
                                                    calInProgress:      controller.orientationCalTailDownSideInProgress
                                                    calInProgressText:  controller.orientationCalTailDownSideRotate ? qsTr("Çevirin") : qsTr("Hələ tutun")
                                                    imageSource:        controller.orientationCalTailDownSideRotate ? "qrc:///qmlimages/VehicleTailDownRotate.png" : "qrc:///qmlimages/VehicleTailDown.png"
                                                }
                                                VehicleRotationCal {
                                                    width:              calGridArea.indicatorSize
                                                    height:             calGridArea.indicatorSize
                                                    visible:            controller.orientationCalLeftSideVisible
                                                    calValid:           controller.orientationCalLeftSideDone
                                                    calInProgress:      controller.orientationCalLeftSideInProgress
                                                    calInProgressText:  controller.orientationCalLeftSideRotate ? qsTr("Çevirin") : qsTr("Hələ tutun")
                                                    imageSource:        controller.orientationCalLeftSideRotate ? "qrc:///qmlimages/VehicleLeftRotate.png" : "qrc:///qmlimages/VehicleLeft.png"
                                                }
                                                VehicleRotationCal {
                                                    width:              calGridArea.indicatorSize
                                                    height:             calGridArea.indicatorSize
                                                    visible:            controller.orientationCalRightSideVisible
                                                    calValid:           controller.orientationCalRightSideDone
                                                    calInProgress:      controller.orientationCalRightSideInProgress
                                                    calInProgressText:  controller.orientationCalRightSideRotate ? qsTr("Çevirin") : qsTr("Hələ tutun")
                                                    imageSource:        controller.orientationCalRightSideRotate ? "qrc:///qmlimages/VehicleRightRotate.png" : "qrc:///qmlimages/VehicleRight.png"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ===== Zavod sıfırlama düyməsi (sənin stilində)
                        RowLayout {
                            id: factoryResetRow
                            Layout.fillWidth: true
                            Item { Layout.fillWidth: true }

                            AzButton {
                                id: factoryResetRect
                                text: qsTr("Zavod parametrlərinə sıfırlama")
                                danger: true
                                enabled: !controller.waitingForCancel
                                onClicked: controller.resetFactoryParameters()
                            }
                        }
                    }
                }
            }

            Item {
                id: bottomSpacer
                Layout.preferredHeight: _root._m
                Layout.fillWidth: true
            }
        }
    }
}

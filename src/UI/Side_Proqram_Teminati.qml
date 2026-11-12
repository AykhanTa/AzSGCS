import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

// Firmware upgrade, in the new design: the vehicle setup page header, then a status card
// with the progress bar and the upgrade log. The page follows the frame's size (it used
// to be a fixed 1548x862 under a header placed with negative offsets).
SetupPage {
    id:             firmwarePage

    pageComponent:  firmwarePageComponent
    pageName:       qsTr("Proqram təminatı")
    showAdvanced:   globals.activeVehicle && globals.activeVehicle.apmFirmware

    // The dialog, buttons, combo boxes and labels take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property real _side:    AzTheme.px(_compact ? 12 : 20)

    Component {
        id: firmwarePageComponent

        ColumnLayout {
            x:       firmwarePage._side
            width:   Math.max(0, firmwarePage.availableWidth - 2 * firmwarePage._side)
            height:  Math.max(AzTheme.px(320), firmwarePage.availableHeight - firmwarePage._side)
            spacing: AzTheme.px(16)

            // İstifadəçi görünüşlü mətnlər
            readonly property string title:             qsTr("Proqram təminatı Quraşdırma")
            readonly property string highlightPrefix:   "<font color=\"" + AzTheme.statusOrange + "\">"

            readonly property string highlightSuffix:   "</font>"
            readonly property string welcomeText:       qsTr("%1 Pixhawk cihazlarında və SiK Radiolarında proqram təminatını təkmilləşdirə bilərsiniz.").arg(QGroundControl.appName)
            readonly property string welcomeTextSingle: qsTr("Avtopilot proqram təminatını ən son versiyaya yeniləyin")
            readonly property string plugInText:        "<big>" + highlightPrefix + qsTr("Cihazınızı qoşun") + highlightSuffix + qsTr(" USB vasitəsilə ") + highlightPrefix + qsTr("başlamaq") + highlightSuffix + qsTr(" proqram təminatı yeniləməsinə.") + "</big>"
            readonly property string flashFailText:     qsTr("Təkmilləşdirmə uğursuz olarsa, qoşulduğunuzdan əmin olun ") + highlightPrefix + qsTr("birbaşa") + highlightSuffix + qsTr(" kompüterinizdə güclü USB portuna, USB hub vasitəsilə deyil. ") +
                                                        qsTr("Yalnız USB ilə gücləndiyindən əmin olun, ") + highlightPrefix + qsTr("batareya deyil") + highlightSuffix + "."
            readonly property string qgcUnplugText1:    qsTr("Nəqliyyat vasitələrinə bütün %1 bağlantılar olmalıdır ").arg(QGroundControl.appName) + highlightPrefix + qsTr("ayrılıb") + highlightSuffix + qsTr(" proqram təminatı yeniləmədən əvvəl.")
            readonly property string qgcUnplugText2:    highlightPrefix + "<big>" + qsTr("Zəhmət olmasa Pixhawk və/və ya Radiounu USB-dən ayırın.") + "</big>" + highlightSuffix

            readonly property int _defaultFimwareTypePX4:   12
            readonly property int _defaultFimwareTypeAPM:   3

            property var    _firmwareUpgradeSettings:   QGroundControl.settingsManager.firmwareUpgradeSettings
            property var    _defaultFirmwareFact:       _firmwareUpgradeSettings.defaultFirmwareType
            property bool   _defaultFirmwareIsPX4:      true

            property string firmwareWarningMessage
            property bool   firmwareWarningMessageVisible:  false
            property bool   initialBoardSearch:             true
            property string firmwareName

            property bool _singleFirmwareMode:          QGroundControl.corePlugin.options.firmwareUpgradeSingleURL.length != 0

            function setupPageCompleted() {
                controller.startBoardSearch()
                _defaultFirmwareIsPX4 = _defaultFirmwareFact.rawValue === _defaultFimwareTypePX4
            }

            QGCFileDialog {
                id:                 customFirmwareDialog
                title:              qsTr("Proqram təminatı Faylını Seçin")
                nameFilters:        [qsTr("Proqram təminatı Faylları (*.px4 *.apj *.bin *.ihx)"), qsTr("Bütün Fayllar (*)")]
                folder:             QGroundControl.settingsManager.appSettings.logSavePath
                onAcceptedForLoad: (file) => {
                    controller.flashFirmwareUrl(file)
                    close()
                }
            }

            FirmwareUpgradeController {
                id:             controller
                progressBar:    progressBar
                statusLog:      statusTextArea

                property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

                onActiveVehicleChanged: {
                    if (!globals.activeVehicle) {
                        statusTextArea.append(plugInText)
                    }
                }

                onNoBoardFound: {
                    initialBoardSearch = false
                    if (!QGroundControl.multiVehicleManager.activeVehicleAvailable) {
                        statusTextArea.append(plugInText)
                    }
                }

                onBoardGone: {
                    initialBoardSearch = false
                    if (!QGroundControl.multiVehicleManager.activeVehicleAvailable) {
                        statusTextArea.append(plugInText)
                    }
                }

                onBoardFound: {
                    if (initialBoardSearch) {
                        statusTextArea.append(qgcUnplugText1)
                        statusTextArea.append(qgcUnplugText2)

                        var availableDevices = controller.availableBoardsName()
                        if (availableDevices.length > 1) {
                            statusTextArea.append(highlightPrefix + qsTr("Bir neçə cihaz tapıldı! Proqram təminatı yeniləməsi üçün bütün cihazları ayırın.") + highlightSuffix)
                            statusTextArea.append(qsTr("Tapılan [%1]: ").arg(availableDevices.length) + availableDevices.join(", "))
                        }
                        if (QGroundControl.multiVehicleManager.activeVehicle) {
                            QGroundControl.multiVehicleManager.activeVehicle.vehicleLinkManager.autoDisconnect = true
                        }
                    } else {
                        statusTextArea.append(highlightPrefix + qsTr("Cihaz tapıldı") + highlightSuffix + ": " + controller.boardType)
                    }
                }

                onShowFirmwareSelectDlg:    firmwareSelectDialogComponent.createObject(mainWindow).open()
                onError:                    statusTextArea.append(flashFailText)
            }

            Component {
                id: firmwareSelectDialogComponent

                QGCPopupDialog {
                    id:         firmwareSelectDialog
                    title:      qsTr("Proqram Təminatı Quraşdırma")
                    buttons:    Dialog.Ok | Dialog.Cancel

                    property bool showFirmwareTypeSelection:    _advanced.checked

                    function firmwareVersionChanged(model) {
                        firmwareWarningMessageVisible = false
                        firmwareBuildTypeCombo.model = null
                        firmwareBuildTypeCombo.model = model
                        firmwareBuildTypeCombo.currentIndex = 1
                        firmwareBuildTypeCombo.currentIndex = 0
                    }

                    function updatePX4VersionDisplay() {
                        var versionString = ""
                        if (_advanced.checked) {
                            switch (controller.selectedFirmwareBuildType) {
                            case FirmwareUpgradeController.StableFirmware:
                                versionString = controller.px4StableVersion
                                break
                            case FirmwareUpgradeController.BetaFirmware:
                                versionString = controller.px4BetaVersion
                                break
                            }
                        } else {
                            versionString = controller.px4StableVersion
                        }
                        px4FlightStackRadio.text = qsTr("PX4 Pro ") + versionString
                    }

                    Component.onCompleted: {
                        firmwarePage.advanced = false
                        firmwarePage.showAdvanced = false
                        updatePX4VersionDisplay()
                    }

                    Connections {
                        target:     controller
                        onError:    reject()
                    }

                    onAccepted: {
                        if (_singleFirmwareMode) {
                            controller.flashSingleFirmwareMode(controller.selectedFirmwareBuildType)
                        } else {
                            var firmwareBuildType = firmwareBuildTypeCombo.model.get(firmwareBuildTypeCombo.currentIndex).firmwareType
                            var vehicleType = FirmwareUpgradeController.DefaultVehicleFirmware

                            var stack = apmFlightStack.checked ? FirmwareUpgradeController.AutoPilotStackAPM : FirmwareUpgradeController.AutoPilotStackPX4
                            if (apmFlightStack.checked) {
                                if (firmwareBuildType === FirmwareUpgradeController.CustomFirmware) {
                                    vehicleType = apmVehicleTypeCombo.currentIndex
                                } else {
                                    if (controller.apmFirmwareNames.length === 0) {
                                        mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("p\Proqram təminatı siyahısı hələ yüklənməyib və ya mövcud deyil."))
                                        firmwareSelectDialog.preventClose = true
                                        return
                                    }
                                    if (ardupilotFirmwareSelectionCombo.currentIndex == -1) {
                                        mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("Lütfən, lövhə tipini seçin."))
                                        firmwareSelectDialog.preventClose = true
                                        return
                                    }

                                    var firmwareUrl = controller.apmFirmwareUrls[ardupilotFirmwareSelectionCombo.currentIndex]
                                    if (firmwareUrl == "") {
                                        mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("Mövcud seçim üçün proqram təminatı tapılmadı."))
                                        firmwareSelectDialog.preventClose = true
                                        return
                                    }
                                    controller.flashFirmwareUrl(controller.apmFirmwareUrls[ardupilotFirmwareSelectionCombo.currentIndex])
                                    return
                                }
                            }
                            if (firmwareBuildType === FirmwareUpgradeController.CustomFirmware) {
                                customFirmwareDialog.openForLoad()
                            } else {
                                controller.flash(stack, firmwareBuildType, vehicleType)
                            }
                        }
                    }

                    function reject() {
                        statusTextArea.append(highlightPrefix + qsTr("Yeniləmə ləğv edildi") + highlightSuffix)
                        statusTextArea.append("------------------------------------------")
                        controller.cancel()
                        close()
                    }

                    ListModel {
                        id: firmwareBuildTypeList

                        ListElement {
                            text:           qsTr("Standart Versiya (stabil)")
                            firmwareType:   FirmwareUpgradeController.StableFirmware
                        }
                        ListElement {
                            text:           qsTr("Beta Testi (beta)")
                            firmwareType:   FirmwareUpgradeController.BetaFirmware
                        }
                        ListElement {
                            text:           qsTr("İnkişafçı Versiyası (master)")
                            firmwareType:   FirmwareUpgradeController.DeveloperFirmware
                        }
                        ListElement {
                            text:           qsTr("Özəl proqram təminatı faylı...")
                            firmwareType:   FirmwareUpgradeController.CustomFirmware
                        }
                    }

                    ListModel {
                        id: singleFirmwareModeTypeList

                        ListElement {
                            text:           qsTr("Standart Versiya")
                            firmwareType:   FirmwareUpgradeController.StableFirmware
                        }
                        ListElement {
                            text:           qsTr("Özəl proqram təminatı faylı...")
                            firmwareType:   FirmwareUpgradeController.CustomFirmware
                        }
                    }

                    ColumnLayout {
                        width:      Math.max(ScreenTools.defaultFontPixelWidth * 40, firmwareRadiosColumn.width)
                        spacing:    globals.defaultTextHeight / 2

                        QGCLabel {
                            Layout.fillWidth:   true
                            wrapMode:           Text.WordWrap
                            text:               (_singleFirmwareMode || !QGroundControl.apmFirmwareSupported) ? _singleFirmwareLabel : _pixhawkLabel

                            readonly property string _pixhawkLabel:          qsTr("Tapılan Pixhawk lövhə. Aşağıdakı uçuş yığınlarından birini seçə bilərsiniz:")
                            readonly property string _singleFirmwareLabel:   qsTr("Yeniləmək üçün Ok düyməsini basın.")
                        }

                        Column {
                            id:         firmwareRadiosColumn
                            spacing:    0

                            visible: !_singleFirmwareMode && QGroundControl.apmFirmwareSupported

                            Component.onCompleted: {
                                if(!QGroundControl.apmFirmwareSupported) {
                                    _defaultFirmwareFact.rawValue = _defaultFimwareTypePX4
                                    firmwareVersionChanged(firmwareBuildTypeList)
                                }
                            }

                            QGCRadioButton {
                                id:             px4FlightStackRadio
                                text:           qsTr("PX4 Pro ")
                                font.bold:      _defaultFirmwareIsPX4
                                checked:        _defaultFirmwareIsPX4

                                onClicked: {
                                    _defaultFirmwareFact.rawValue = _defaultFimwareTypePX4
                                    firmwareVersionChanged(firmwareBuildTypeList)
                                }
                            }

                            QGCRadioButton {
                                id:             apmFlightStack
                                text:           qsTr("ArduPilot")
                                font.bold:      !_defaultFirmwareIsPX4
                                checked:        !_defaultFirmwareIsPX4

                                onClicked: {
                                    _defaultFirmwareFact.rawValue = _defaultFimwareTypeAPM
                                    firmwareVersionChanged(firmwareBuildTypeList)
                                }
                            }
                        }

                        FactComboBox {
                            Layout.fillWidth:   true
                            visible:            apmFlightStack.checked
                            fact:               _firmwareUpgradeSettings.apmChibiOS
                            indexModel:         false
                        }

                        FactComboBox {
                            id:                 apmVehicleTypeCombo
                            Layout.fillWidth:   true
                            visible:            apmFlightStack.checked
                            fact:               _firmwareUpgradeSettings.apmVehicleType
                            indexModel:         false
                        }

                        QGCComboBox {
                            id:                 ardupilotFirmwareSelectionCombo
                            Layout.fillWidth:   true
                            visible:            apmFlightStack.checked && !controller.downloadingFirmwareList && controller.apmFirmwareNames.length !== 0
                            model:              controller.apmFirmwareNames
                            onModelChanged:     currentIndex = controller.apmFirmwareNamesBestIndex
                        }

                        QGCLabel {
                            Layout.fillWidth:   true
                            wrapMode:           Text.WordWrap
                            text:               qsTr("Mövcud proqram təminatı siyahısı yüklənir...")
                            visible:            controller.downloadingFirmwareList
                        }

                        QGCLabel {
                            Layout.fillWidth:   true
                            wrapMode:           Text.WordWrap
                            text:               qsTr("Proqram təminatı mövcud deyil")
                            visible:            !controller.downloadingFirmwareList && (QGroundControl.apmFirmwareSupported && controller.apmFirmwareNames.length === 0)
                        }

                        QGCCheckBox {
                            id:         _advanced
                            text:       qsTr("Ətraflı parametrlər")
                            checked:    false

                            onClicked: {
                                firmwareBuildTypeCombo.currentIndex = 0
                                firmwareWarningMessageVisible = false
                                updatePX4VersionDisplay()
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth:   true
                            wrapMode:           Text.WordWrap
                            visible:            showFirmwareTypeSelection
                            text:               _singleFirmwareMode ?  qsTr("Standart versiyanı seçin və ya fayl sistemindən seçin (əvvəlcədən yüklənmiş):") :
                                                                      qsTr("Yuxarıdakı uçuş yığını üçün hansı versiyanı quraşdırmaq istədiyinizi seçin:")
                        }

                        QGCComboBox {
                            id:                 firmwareBuildTypeCombo
                            Layout.fillWidth:   true
                            visible:            showFirmwareTypeSelection
                            textRole:           "text"
                            model:              _singleFirmwareMode ? singleFirmwareModeTypeList : firmwareBuildTypeList

                            onActivated: (index) => {
                                controller.selectedFirmwareBuildType = model.get(index).firmwareType
                                if (model.get(index).firmwareType === FirmwareUpgradeController.BetaFirmware) {
                                    firmwareWarningMessageVisible = true
                                    firmwareVersionWarningLabel.text = qsTr("XƏBƏRDARLIQ: BETA PROQRAM TƏMİNATI. ") +
                                            qsTr("Bu proqram təminatı yalnız beta testçilər üçün nəzərdə tutulub. ") +
                                            qsTr("Uçuş testi keçirilsə də, kod aktiv olaraq dəyişir. ") +
                                            qsTr("Normal əməliyyat üçün istifadə etməyin.")
                                } else if (model.get(index).firmwareType === FirmwareUpgradeController.DeveloperFirmware) {
                                    firmwareWarningMessageVisible = true
                                    firmwareVersionWarningLabel.text = qsTr("XƏBƏRDARLIQ: İNKIŞAFÇI VERSİYA (master). ") +
                                            qsTr("Bu proqram təminatı uçuş testindən keçməyib. ") +
                                            qsTr("Yalnız inkişafçılar üçün nəzərdə tutulub. ") +
                                            qsTr("Propellersiz sınaqlar aparın. ") +
                                            qsTr("Əlavə təhlükəsizlik tədbirləri olmadan uçmayın. ") +
                                            qsTr("İstifadə zamanı forumları aktiv izləyin.")
                                } else {
                                    firmwareWarningMessageVisible = false
                                }
                                updatePX4VersionDisplay()
                            }
                        }

                        QGCLabel {
                            id:                 firmwareVersionWarningLabel
                            Layout.fillWidth:   true
                            wrapMode:           Text.WordWrap
                            visible:            firmwareWarningMessageVisible
                        }
                    } // ColumnLayout
                } // QGCPopupDialog
            } // Component - firmwareSelectDialogComponent

            // Header
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: AzTheme.px(firmwarePage._compact ? 4 : 12)
                spacing: AzTheme.px(6)

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Proqram Təminatı Konfiqurasiyası")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(firmwarePage._compact ? 18 : 20)
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Cihaz Proqram Təminatı Parametrləri")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(13)
                    wrapMode: Text.WordWrap
                }
            }

            // The status card: the progress bar and the upgrade log
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: AzTheme.px(firmwarePage._compact ? 14 : 18)
                    spacing: AzTheme.px(12)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: AzTheme.px(12)

                        Text {
                            Layout.fillWidth: true
                            text: title
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(16)
                            elide: Text.ElideRight
                        }

                        QGCButton {
                            id:         flashBootloaderButton
                            text:       qsTr("ChibiOS Bootloader Quraşdır")
                            visible:    firmwarePage.advanced
                            onClicked:  if (globals.activeVehicle) globals.activeVehicle.flashBootloader()
                        }
                    }

                    // A dark rounded track with a green fill
                    ProgressBar {
                        id:                     progressBar
                        Layout.fillWidth:       true
                        visible:                !flashBootloaderButton.visible

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

                    // The upgrade log on a group box
                    TextArea {
                        id:                 statusTextArea
                        Layout.fillWidth:   true
                        Layout.fillHeight:  true
                        readOnly:           true
                        wrapMode:           TextEdit.WordWrap
                        textFormat:         TextEdit.RichText
                        text:               _singleFirmwareMode ? welcomeTextSingle : welcomeText
                        color:              AzTheme.textCard
                        font.family:        AzTheme.fontFamily
                        font.pixelSize:     AzTheme.fontPx(AzTheme.popupTextSize)
                        padding:            AzTheme.px(AzTheme.groupPadding)

                        background: Rectangle {
                            color:        AzTheme.groupFill
                            radius:       AzTheme.px(AzTheme.groupRadius)
                            border.width: 1
                            border.color: AzTheme.groupBorder
                        }
                    }
                }
            }
        } // ColumnLayout
    } // Component
} // SetupPage

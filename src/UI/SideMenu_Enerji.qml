import QtQuick 2.15
import QtQuick.Controls 2.15
//import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Controls 1.0
import QGroundControl.AutoPilotPlugins.PX4 1.0

// Power setup, in the new design: the vehicle setup page header, one status card with
// group box rows, the battery summary, the new text fields and combo boxes, and the
// panel's buttons.
Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    // The fields, combo boxes, check boxes and labels take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ---- Responsive ölçülər ----
    readonly property real _m:            AzTheme.px(_compact ? 12 : 16)
    readonly property real _side:         AzTheme.px(_compact ? 12 : 20)
    readonly property real _editorH:      AzTheme.px(36)

    // Çərçivə səhifəsi ilə eyni eşik — kiçik ekranlarda başlıq yığcamlaşır.
    readonly property bool _compact:      (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property real _fieldW:       Math.max(170, Math.min(240, width * 0.22))        // normal editor eni
    readonly property real _editorWideW:  Math.max(340, Math.min(520, width * 0.50))        // field+button kimi geniş editor üçün
    readonly property bool _wideTop:      width >= 1100                                      // batareya info sağda/üstə
    readonly property bool _wideForm:     width >= 900                                       // form sətrləri 2 sütun/1 sütun

    // ---- Backend ----
    PowerComponentController {
        id: controller
        onOldFirmware: mainWindow.showMessageDialog(qsTr("ESC kalibrləmə"),
                                                   qsTr("%1 cannot perform ESC Calibration with this version of firmware. You will need to upgrade to a newer firmware.").arg(QGroundControl.appName))
        onNewerFirmware: mainWindow.showMessageDialog(qsTr("ESC kalibrləmə"),
                                                     qsTr("%1 cannot perform ESC Calibration with this version of firmware. You will need to upgrade %1.").arg(QGroundControl.appName))
        onDisconnectBattery: mainWindow.showMessageDialog(qsTr(qsTr("ESC Kalibrləmə uğursuz oldu")),
                                                         qsTr("You must disconnect the battery prior to performing ESC Calibration. Disconnect your battery and try again."))
        onConnectBattery: escCalibrationDlgComponent.createObject(mainWindow).open()
        onCalibrationFailed: console.log(qsTr("ESC Kalibrləmə uğursuz oldu"))
        onCalibrationSuccess: console.log(qsTr("ESC Kalibrləmə müvəffəqiyyəti"))
    }

    BatteryParams {
        id: batParams
        controller: controller
        batteryIndex: 1
    }

    property var  qgcPal: QGroundControl.globalPalette
    property bool parametersReady: batParams.battSource != null && batParams.battSource.rawValue !== undefined
    property bool showUAVCAN: false

    // Altdakı UI-a klik getməsin (amma kontent üst qatdadır, işləyəcək)
    MouseArea {
        anchors.fill: parent
        z: 1
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
    }

    // ---- Inline component: label + editor sətri (genişdə yan-yana, darda alt-alta) ----
    // A group box row: #191D20, 1 px #353A3F, radius 8
    component FormRow: Rectangle {
        id: row
        Layout.fillWidth: true
        radius: AzTheme.px(AzTheme.groupRadius)
        color: AzTheme.groupFill
        border.width: 1
        border.color: AzTheme.groupBorder

        property alias title: titleText.text
        property bool  wide: root._wideForm
        property real  editorPreferredWidth: root._fieldW
        default property alias editor: editorSlot.data

        implicitHeight: grid.implicitHeight + AzTheme.px(20)

        GridLayout {
            id: grid
            anchors.fill: parent
            anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
            anchors.rightMargin: AzTheme.px(10)
            anchors.topMargin: AzTheme.px(10)
            anchors.bottomMargin: AzTheme.px(10)
            columns: row.wide ? 2 : 1
            columnSpacing: AzTheme.px(16)
            rowSpacing: AzTheme.px(8)

            Text {
                id: titleText
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                id: editorSlot
                Layout.fillWidth: !row.wide
                Layout.preferredWidth: row.wide ? row.editorPreferredWidth : -1
                Layout.minimumWidth: row.wide ? 160 : 0
                implicitHeight: childrenRect.height
            }
        }
    }

    // A section title inside the card
    component SectionTitle: Text {
        Layout.fillWidth: true
        Layout.topMargin: AzTheme.px(6)
        color: AzTheme.textCard
        font.family: AzTheme.fontFamily
        font.weight: Font.Medium
        font.pixelSize: AzTheme.fontPx(15)
        wrapMode: Text.WordWrap
    }

    // Help text under a row
    component HelpText: Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: AzTheme.textSecondary
        font.family: AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(13)
    }

    // A red-tinted warning line with the error icon
    component WarningLine: RowLayout {
        property alias text: warningText.text

        Layout.fillWidth: true
        spacing: AzTheme.px(8)

        QGCColoredImage {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: AzTheme.px(18)
            Layout.preferredHeight: AzTheme.px(18)
            source: "qrc:/res/AZSHIELD_ICON/bx_error.svg"
            sourceSize.height: AzTheme.px(18)
            fillMode: Image.PreserveAspectFit
            color: AzTheme.statusRed
        }

        Text {
            id: warningText
            Layout.fillWidth: true
            color: AzTheme.statusRed
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: AzTheme.fontPx(13)
            wrapMode: Text.WordWrap
        }
    }

    // ---- Scrollable page ----
    QGCFlickable {
        id: flick
        z: 2
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentCol.implicitHeight + AzTheme.px(20) + root._side
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentCol
            width: flick.width
            spacing: root._m

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root._side
            anchors.rightMargin: root._side
            anchors.topMargin: AzTheme.px(20)
            anchors.bottomMargin: root._side

            // --- Header ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: AzTheme.px(6)

                Text {
                    text: qsTr("Güc Parametrləri")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(root._compact ? 18 : 20)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Batareya və enerji idarəetməsini konfiqurasiya edin")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(13)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // --- Loading card: the vehicle state and what to expect ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: AzTheme.px(200)
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                visible: !parametersReady

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 2 * root._side
                    spacing: AzTheme.px(10)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: AzTheme.px(12)
                        height: width
                        radius: width / 2
                        color: globals.activeVehicle ? AzTheme.statusOrange : AzTheme.mutedText
                    }

                    Text {
                        width: parent.width
                        text: globals.activeVehicle ? qsTr("Parametrlər yüklənir...") : qsTr("Aktiv aparat yoxdur")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: AzTheme.fontPx(17)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: globals.activeVehicle ? qsTr("Avtopilot bağlantısını gözləyin")
                                                    : qsTr("Qoşulduqdan sonra batareya parametrləri görünəcək.")
                        color: AzTheme.textSecondary
                        font.family: AzTheme.fontFamily
                        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // --- Main card ---
            Rectangle {
                id: mainCard
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                visible: parametersReady

                implicitHeight: cardContent.implicitHeight + (root._m * 2)

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: root._m
                    spacing: root._m

                    // Title
                    Text {
                        text: qsTr("Batareya")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: AzTheme.fontPx(16)
                        Layout.fillWidth: true
                    }

                    // Top area: form + battery summary (genişdə sağda, darda üstə)
                    GridLayout {
                        id: topGrid
                        Layout.fillWidth: true
                        columns: root._wideTop ? 2 : 1
                        columnSpacing: root._m
                        rowSpacing: root._m

                        // Battery summary: a group box with the pack drawing and its limits
                        Rectangle {
                            id: batterySummary
                            Layout.row: 0
                            Layout.column: root._wideTop ? 1 : 0
                            Layout.fillWidth: !root._wideTop
                            Layout.preferredWidth: root._wideTop ? AzTheme.px(340) : -1
                            Layout.alignment: Qt.AlignTop

                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            visible: parametersReady && batParams.battSource.rawValue != -1

                            implicitHeight: summaryCol.implicitHeight + 2 * root._m

                            ColumnLayout {
                                id: summaryCol
                                anchors.fill: parent
                                anchors.margins: root._m
                                spacing: AzTheme.px(10)

                                QGCColoredImage {
                                    id: batteryImage
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: AzTheme.px(110)
                                    Layout.preferredHeight: AzTheme.px(150)
                                    sourceSize.height: height
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    color: AzTheme.textSecondary
                                    cache: false
                                    source: {
                                        if (!parametersReady) return "/qmlimages/PowerComponentBattery_01cell.svg"
                                        switch (batParams.battNumCells.value) {
                                        case 1: return "/qmlimages/PowerComponentBattery_01cell.svg"
                                        case 2: return "/qmlimages/PowerComponentBattery_02cell.svg"
                                        case 3: return "/qmlimages/PowerComponentBattery_03cell.svg"
                                        case 4: return "/qmlimages/PowerComponentBattery_04cell.svg"
                                        case 5: return "/qmlimages/PowerComponentBattery_05cell.svg"
                                        case 6: return "/qmlimages/PowerComponentBattery_06cell.svg"
                                        default: return "/qmlimages/PowerComponentBattery_01cell.svg"
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    color: AzTheme.groupBorder
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: AzTheme.px(8)
                                    Text { text: qsTr("Max Batareya"); color: AzTheme.textSecondary; font.family: AzTheme.fontFamily; font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize) }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: parametersReady ? (batParams.battNumCells.value * batParams.battHighVolt.value).toFixed(1) + " V" : "0.0 V"
                                        color: AzTheme.statusGreen; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: AzTheme.px(8)
                                    Text { text: qsTr("Min Batareya"); color: AzTheme.textSecondary; font.family: AzTheme.fontFamily; font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize) }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: parametersReady ? (batParams.battNumCells.value * batParams.battLowVolt.value).toFixed(1) + " V" : "0.0 V"
                                        color: AzTheme.statusRed; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                                    }
                                }
                            }
                        }

                        // Form area
                        ColumnLayout {
                            id: formCol
                            Layout.row: root._wideTop ? 0 : 1
                            Layout.column: 0
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: AzTheme.px(8)

                            // Source
                            FormRow {
                                title: qsTr("Mənbə")
                                FactComboBox {
                                    width: parent.width
                                    height: root._editorH
                                    fact: batParams.battSource
                                    indexModel: false
                                    enabled: parametersReady
                                }
                            }

                            // Battery settings when source enabled
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: AzTheme.px(8)
                                visible: parametersReady && batParams.battSource.rawValue != -1

                                FormRow {
                                    title: qsTr("Elementlərin sayı (ardıcıl)")
                                    FactTextField {
                                        width: parent.width
                                        height: root._editorH
                                        fact: batParams.battNumCells
                                        enabled: parametersReady
                                    }
                                }

                                FormRow {
                                    title: qsTr("Boş gərginlik (hər element üçün)")
                                    FactTextField {
                                        width: parent.width
                                        height: root._editorH
                                        fact: batParams.battLowVolt
                                        enabled: parametersReady
                                    }
                                }

                                FormRow {
                                    title: qsTr("Tam dolu gərginlik (hər element üçün)")
                                    FactTextField {
                                        width: parent.width
                                        height: root._editorH
                                        fact: batParams.battHighVolt
                                        enabled: parametersReady
                                    }
                                }

                                // Voltage Divider
                                FormRow {
                                    title: qsTr("Gərginlik bölücü")
                                    wide: root._wideForm
                                    editorPreferredWidth: root._editorWideW
                                    visible: parametersReady && batParams.battVoltageDividerAvailable

                                    Flow {
                                        id: vdFlow
                                        width: parent.width
                                        spacing: AzTheme.px(10)

                                        FactTextField {
                                            id: vdField
                                            width: root._wideForm
                                                   ? Math.max(170, vdFlow.width - (vdCalc.width + vdFlow.spacing))
                                                   : vdFlow.width
                                            height: root._editorH
                                            fact: batParams.battVoltageDivider
                                            enabled: parametersReady
                                        }

                                        AzButton {
                                            id: vdCalc
                                            width: root._wideForm ? AzTheme.px(150) : vdFlow.width
                                            height: root._editorH
                                            text: qsTr("Hesabla")
                                            enabled: parametersReady
                                            onClicked: calcVoltageDividerDlgComponent.createObject(mainWindow).open()
                                        }
                                    }
                                }

                                HelpText {
                                    visible: parametersReady && batParams.battVoltageDividerAvailable
                                    text: {
                                        if (!parametersReady) return qsTr("Parametrlər yüklənir...")
                                        if (batParams.battSource.rawValue == 0) {
                                            return qsTr("Əgər aparatın göndərdiyi batareya gərginliyi voltmetrlə çöldən ölçdüyünüz gərginlikdən xeyli fərqlənirsə, bunu düzəltmək üçün gərginlik vurucusunun dəyərini tənzimləyə bilərsiniz. Yeni dəyərin hesablanmasına kömək üçün “Hesabla” düyməsinə klikləyin.")
                                        } else if (batParams.battSource.rawValue == 1) {
                                            return "For analog pin voltage sensing: If the battery voltage reported by the vehicle is largely different than the voltage read externally using a voltmeter you can adjust the voltage multiplier value to correct this."
                                        } else if (batParams.battSource.rawValue == 2) {
                                            return "For onboard 3DR power sensing: Voltage divider calibration for 3DR power module."
                                        } else if (batParams.battSource.rawValue == 3) {
                                            return "For PX4 power sensing: Voltage divider calibration for PX4 power module."
                                        } else {
                                            return "If the battery voltage reported by the vehicle is largely different than the voltage read externally using a voltmeter you can adjust the voltage multiplier value to correct this."
                                        }
                                    }
                                }

                                // Amps per volt
                                FormRow {
                                    title: qsTr("Volt başına amper")
                                    wide: root._wideForm
                                    editorPreferredWidth: root._editorWideW
                                    visible: parametersReady && batParams.battAmpsPerVoltAvailable

                                    Flow {
                                        id: apvFlow
                                        width: parent.width
                                        spacing: AzTheme.px(10)

                                        FactTextField {
                                            id: apvField
                                            width: root._wideForm
                                                   ? Math.max(170, apvFlow.width - (apvCalc.width + apvFlow.spacing))
                                                   : apvFlow.width
                                            height: root._editorH
                                            fact: batParams.battAmpsPerVolt
                                            enabled: parametersReady
                                        }

                                        AzButton {
                                            id: apvCalc
                                            width: root._wideForm ? AzTheme.px(150) : apvFlow.width
                                            height: root._editorH
                                            text: qsTr("Hesabla")
                                            enabled: parametersReady
                                            onClicked: calcAmpsPerVoltDlgComponent.createObject(mainWindow).open()
                                        }
                                    }
                                }

                                HelpText {
                                    visible: parametersReady && batParams.battAmpsPerVoltAvailable
                                    text: {
                                        if (!parametersReady) return qsTr("Parametrlər yüklənir...")
                                        if (batParams.battSource.rawValue == 0) {
                                            return qsTr("Əgər aparatın göndərdiyi cərəyan dəyəri ampermetrlə kənardan ölçdüyünüz dəyərdən xeyli fərqlənirsə, bunu düzəltmək üçün “volt başına amper” parametrini tənzimləyə bilərsiniz. Yeni dəyərin hesablanması üçün “Hesabla” düyməsinə klikləyin.")
                                        } else if (batParams.battSource.rawValue == 1) {
                                            return "For analog pin current sensing: Calibrate the current sensor by comparing with external current meter readings."
                                        } else if (batParams.battSource.rawValue == 2) {
                                            return "For 3DR power module: Current sensor calibration for 3DR power module."
                                        } else if (batParams.battSource.rawValue == 3) {
                                            return "For PX4 power module: Current sensor calibration for PX4 power module."
                                        } else {
                                            return "If the current draw reported by the vehicle is largely different than the current read externally using a current meter you can adjust the amps per volt value to correct this."
                                        }
                                    }
                                }
                            }

                            // Message when battery source disabled
                            HelpText {
                                visible: parametersReady && batParams.battSource.rawValue == -1
                                text: "Battery monitoring is disabled. No battery parameters will be available."
                            }

                            // ----- ESC Calibration section -----
                            SectionTitle {
                                text: "ESC PWM Minimum and Maximum Calibration"
                                visible: parametersReady
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: AzTheme.px(AzTheme.groupRadius)
                                color: AzTheme.groupFill
                                border.width: 1
                                border.color: AzTheme.groupBorder
                                visible: parametersReady
                                implicitHeight: escGrid.implicitHeight + AzTheme.px(28)

                                GridLayout {
                                    id: escGrid
                                    anchors.fill: parent
                                    anchors.margins: AzTheme.px(14)
                                    columns: root._wideForm ? 2 : 1
                                    columnSpacing: AzTheme.px(16)
                                    rowSpacing: AzTheme.px(12)

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: AzTheme.px(8)

                                        WarningLine {
                                            text: qsTr("XƏBƏRDARLIQ: ESC kalibrləməsini aparmazdan əvvəl pervanelər mütləq aparatdan çıxarılmalıdır.")
                                        }

                                        HelpText {
                                            text: qsTr("Bu əməliyyat üçün USB bağlantısından istifadə etməlisiniz.")
                                        }
                                    }

                                    AzButton {
                                        Layout.alignment: root._wideForm ? Qt.AlignRight : Qt.AlignLeft
                                        Layout.fillWidth: !root._wideForm
                                        Layout.preferredWidth: root._wideForm ? AzTheme.px(150) : -1
                                        text: qsTr("Kalibrlə")
                                        positive: true
                                        enabled: parametersReady
                                        onClicked: controller.calibrateEsc()
                                    }
                                }
                            }

                            // ----- UAVCAN toggle -----
                            QGCCheckBox {
                                Layout.topMargin: AzTheme.px(6)
                                text: qsTr("UAVCAN parametrlərini göstər")
                                checked: root.showUAVCAN
                                visible: parametersReady
                                onClicked: root.showUAVCAN = checked
                            }

                            // ----- UAV Bus Configuration -----
                            SectionTitle {
                                text: qsTr("UAV şin konfiqurasiyası")
                                visible: parametersReady && root.showUAVCAN
                            }

                            FormRow {
                                title: qsTr("Dəyişiklik üçün yenidən başladılması tələb olunur")
                                visible: parametersReady && root.showUAVCAN

                                FactComboBox {
                                    width: parent.width
                                    height: root._editorH
                                    fact: controller.getParameterFact(-1, "UAVCAN_ENABLE", false)
                                    indexModel: false
                                    enabled: parametersReady
                                }
                            }

                            // ----- UAVCAN Motor Assignment -----
                            SectionTitle {
                                text: qsTr("UAVCAN mühərrik indeksinin və fırlanma istiqamətinin təyini")
                                visible: parametersReady && root.showUAVCAN
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: AzTheme.px(AzTheme.groupRadius)
                                color: AzTheme.groupFill
                                border.width: 1
                                border.color: AzTheme.groupBorder
                                visible: parametersReady && root.showUAVCAN
                                implicitHeight: assignCol.implicitHeight + AzTheme.px(28)

                                ColumnLayout {
                                    id: assignCol
                                    anchors.fill: parent
                                    anchors.margins: AzTheme.px(14)
                                    spacing: AzTheme.px(8)

                                    WarningLine {
                                        text: qsTr("XƏBƏRDARLIQ: ESC kalibrləməsini aparmazdan əvvəl pervanelər mütləq aparatdan çıxarılmalıdır.")
                                    }

                                    HelpText {
                                        text: qsTr("ESC parametrlərinə yalnız təyinat (assignment) tamamlandıqdan sonra redaktorda çıxış mümkün olacaq.")
                                    }

                                    HelpText {
                                        text: qsTr("Prosesi başladın, sonra mühərrik indekslərinin sırasına uyğun olaraq hər mühərriki öz fırlanma istiqamətində hərəkətə gətirin.")
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: AzTheme.px(10)

                                        AzButton {
                                            width: root._wideForm ? AzTheme.px(180) : parent.width
                                            text: qsTr("Təyinata başla")
                                            positive: true
                                            enabled: parametersReady
                                            onClicked: controller.startBusConfigureActuators()
                                        }

                                        AzButton {
                                            width: root._wideForm ? AzTheme.px(180) : parent.width
                                            text: qsTr("Təyinatı dayandır")
                                            enabled: parametersReady
                                            onClicked: controller.stopBusConfigureActuators()
                                        }
                                    }
                                }
                            }
                        } // formCol
                    } // topGrid
                } // cardContent
            } // mainCard
        } // contentCol
    } // flick

    // ---- Dialog components (səndəki kimi saxlanılıb) ----
    Component {
        id: calcVoltageDividerDlgComponent

        QGCPopupDialog {
            title:      qsTr("Gərginlik bölücü hesablayın")
            buttons:    Dialog.Close

            property var _controller: controller
            property FactGroup _batteryFactGroup: controller.vehicle.getFactGroup("battery0")

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    Layout.preferredWidth:  gridLayout.width
                    wrapMode:               Text.WordWrap
                    text:                   qsTr("Xarici voltmetrdən istifadə edərək batareyanın gərginliyini ölçün və aşağıdakı dəyəri daxil edin. Yeni gərginlik çarpanını təyin etmək üçün Hesabla klikləyin.")
                }

                GridLayout {
                    id:         gridLayout
                    columns:    2

                    QGCLabel { text: qsTr("Ölçülmüş gərginlik:") }
                    QGCTextField { id: measuredVoltage; numericValuesOnly: true }

                    QGCLabel { text: qsTr("Təyyarənin gərginliyi:") }
                    QGCLabel { text: _batteryFactGroup.voltage.valueString }

                    QGCLabel { text: qsTr("Gərginlik bölücü:") }
                    FactLabel { fact: batParams.battVoltageDivider }
                }

                QGCButton {
                    text: qsTr("Hesablayın")

                    onClicked:  {
                        var measuredVoltageValue = parseFloat(measuredVoltage.text)
                        if (measuredVoltageValue === 0 || isNaN(measuredVoltageValue)) {
                            return
                        }
                        var newVoltageDivider = (measuredVoltageValue * batParams.battVoltageDivider.value) / _batteryFactGroup.voltage.value
                        if (newVoltageDivider > 0) {
                            batParams.battVoltageDivider.value = newVoltageDivider
                        }
                    }
                }
            }
        }
    }

    Component {
        id: calcAmpsPerVoltDlgComponent

        QGCPopupDialog {
            title:      qsTr("Volta amperi hesablayın")
            buttons:    Dialog.Close

            property var _controller: controller
            property FactGroup _batteryFactGroup: controller.vehicle.getFactGroup("battery0")

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    Layout.preferredWidth:  gridLayout.width
                    wrapMode:               Text.WordWrap
                    text:                   qsTr("Xarici cərəyan sayğacından istifadə edərək cari çəkilişi ölçün və aşağıdakı dəyəri daxil edin. Hər volt üçün yeni amperləri təyin etmək üçün Hesabla düyməsini klikləyin.")
                }

                GridLayout {
                    id:         gridLayout
                    columns:    2

                    QGCLabel { text: qsTr("Ölçülmüş cərəyan:") }
                    QGCTextField { id: measuredCurrent; numericValuesOnly: true }

                    QGCLabel { text: qsTr("Təyyarə cərəyanı:") }
                    QGCLabel { text: _batteryFactGroup.current.valueString }

                    QGCLabel { text: qsTr("Volta amper:") }
                    FactLabel { fact: batParams.battAmpsPerVolt }
                }

                QGCButton {
                    text: qsTr("Hesablayın")

                    onClicked:  {
                        var measuredCurrentValue = parseFloat(measuredCurrent.text)
                        if (measuredCurrentValue === 0 || isNaN(measuredCurrentValue)) {
                            return
                        }
                        var newAmpsPerVolt = (measuredCurrentValue * batParams.battAmpsPerVolt.value) / _batteryFactGroup.current.value
                        if (newAmpsPerVolt != 0) {
                            batParams.battAmpsPerVolt.value = newAmpsPerVolt
                        }
                    }
                }
            }
        }
    }

    Component {
        id: escCalibrationDlgComponent

        QGCPopupDialog {
            id:                     escCalibrationDlg
            title:                  qsTr("ESC kalibrləmə")
            buttons:                Dialog.Ok
            acceptButtonEnabled:    false

            Connections {
                target: controller

                onBatteryConnected:     textLabel.text = qsTr("Kalibrləmə həyata keçirilir. Bu bir neçə saniyə çəkəcək...")
                onCalibrationFailed:    { escCalibrationDlg.acceptButtonEnabled = true; textLabel.text = qsTr("ESC Kalibrləmə uğursuz oldu. ") + errorMessage }
                onCalibrationSuccess:   { escCalibrationDlg.acceptButtonEnabled = true; textLabel.text = qsTr("Kalibrləmə tamamlandı. İstəsəniz, batareyanı indi ayıra bilərsiniz.") }
            }

            ColumnLayout {
                QGCLabel {
                    id:                     textLabel
                    wrapMode:               Text.WordWrap
                    text:                   qsTr("XƏBƏRDARLIQ: ESC kalibrlənməsini həyata keçirməzdən əvvəl rekvizitlər təyyarədən çıxarılmalıdır. Batareyanı indi qoşun və kalibrləmə başlayacaq.")
                    Layout.fillWidth:       true
                    Layout.maximumWidth:    mainWindow.width / 2
                }
            }
        }
    }
}

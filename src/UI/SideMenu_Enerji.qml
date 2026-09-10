import QtQuick 2.15
import QtQuick.Controls 2.15
//import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Controls 1.0
import QGroundControl.AutoPilotPlugins.PX4 1.0
//import QGroundControl.ScreenTools 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "black"

    // ---- Responsive ölçülər ----
    readonly property real _m:            Math.max(12, ScreenTools.defaultFontPixelHeight * 0.75)
    readonly property real _side:         Math.max(12, _m * 0.9)
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
    component FormRow: Rectangle {
        id: row
        Layout.fillWidth: true
        radius: 6
        color: "#2A2A2A"

        property alias title: titleText.text
        property bool  wide: root._wideForm
        property real  editorPreferredWidth: root._fieldW
        default property alias editor: editorSlot.data

        implicitHeight: grid.implicitHeight + 28

        GridLayout {
            id: grid
            anchors.fill: parent
            anchors.margins: 14
            columns: row.wide ? 2 : 1
            columnSpacing: 16
            rowSpacing: 10

            Text {
                id: titleText
                color: "#FFFFFF"
                font.pixelSize: 16
                font.bold: true
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

    // ---- Scrollable page ----
    QGCFlickable {
        id: flick
        z: 2
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentCol.implicitHeight + root._side
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
            anchors.topMargin: 0
            anchors.bottomMargin: root._side

            // --- Header (yuxarı boşluqsuz) ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("Güc Parametrləri")
                    color: "white"
                    font.pixelSize: 26
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Batareya və enerji idarəetməsini konfiqurasiya edin")
                    color: "#E8E8E8"
                    font.pixelSize: 16
                    font.bold: false
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // --- Loading card ---
            Rectangle {
                Layout.fillWidth: true
                radius: 16
                color: "#3D3B3B"
                border.width: 1
                border.color: "#9D9D9D"
                visible: !parametersReady
                implicitHeight: 220

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 2 * root._side
                    text: qsTr("Parametrlər yüklənir...\nAvtopilot bağlantısını gözləyin")
                    color: "#FFFFFF"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            // --- Main card ---
            Rectangle {
                id: mainCard
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                radius: 16
                color: "#3D3B3B"
                border.width: 1
                border.color: "#9D9D9D"
                visible: parametersReady

                implicitHeight: cardContent.implicitHeight + (root._m * 2)

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: root._m
                    spacing: root._m

                    // Title
                    Text {
                        text: "Batareya"
                        color: "#FFFFFF"
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }

                    // Top area: form + battery summary (genişdə sağda, darda üstə)
                    GridLayout {
                        id: topGrid
                        Layout.fillWidth: true
                        columns: root._wideTop ? 2 : 1
                        columnSpacing: root._m
                        rowSpacing: root._m

                        // Battery summary box
                        Rectangle {
                            id: batterySummary
                            Layout.row: 0
                            Layout.column: root._wideTop ? 1 : 0
                            Layout.fillWidth: !root._wideTop
                            Layout.preferredWidth: root._wideTop ? 360 : -1
                            Layout.alignment: Qt.AlignTop

                            radius: 10
                            color: "#232323"
                            visible: parametersReady && batParams.battSource.rawValue != -1

                            implicitHeight: summaryCol.implicitHeight + 2 * root._m

                            ColumnLayout {
                                id: summaryCol
                                anchors.fill: parent
                                anchors.margins: root._m
                                spacing: 10

                                QGCColoredImage {
                                    id: batteryImage
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 110
                                    Layout.preferredHeight: 160
                                    sourceSize.height: height
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    color: qgcPal.text
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

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "Max Batareya:"; color: "#FFFFFF"; font.pixelSize: 14; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: parametersReady ? (batParams.battNumCells.value * batParams.battHighVolt.value).toFixed(1) + " V" : "0.0 V"
                                        color: "#FFFFFF"; font.pixelSize: 14
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "Min Batareya:"; color: "#FFFFFF"; font.pixelSize: 14; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: parametersReady ? (batParams.battNumCells.value * batParams.battLowVolt.value).toFixed(1) + " V" : "0.0 V"
                                        color: "#FFFFFF"; font.pixelSize: 14
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
                            spacing: 10

                            // Source
                            FormRow {
                                title: qsTr("Mənbə")
                                FactComboBox {
                                    width: parent.width
                                    height: 34
                                    fact: batParams.battSource
                                    indexModel: false
                                    enabled: parametersReady

                                    background: Rectangle {
                                        color: "#3D3B3B"
                                        radius: 4
                                        border.color: "#9D9D9D"
                                        border.width: 0.5
                                    }

                                    contentItem: Text {
                                        text: parametersReady ? parent.currentText : qsTr("Yüklənir...")
                                        color: parametersReady ? "#FFFFFF" : "#888888"
                                        font.pixelSize: 16
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.fill: parent
                                    }
                                }
                            }

                            // Battery settings when source enabled
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                visible: parametersReady && batParams.battSource.rawValue != -1

                                FormRow {
                                    title: qsTr("Elementlərin sayı (ardıcıl)")
                                    FactTextField {
                                        width: parent.width
                                        height: 34
                                        fact: batParams.battNumCells
                                        showUnits: true
                                        enabled: parametersReady

                                        background: Rectangle {
                                            color: parametersReady ? "white" : "#E0E0E0"
                                            radius: 4
                                            border.color: "#9D9D9D"
                                            border.width: 0.5
                                        }
                                    }
                                }

                                FormRow {
                                    title: qsTr("Boş gərginlik (hər element üçün)")
                                    Rectangle {
                                        width: parent.width
                                        height: 34
                                        color: parametersReady ? "white" : "#E0E0E0"
                                        radius: 4

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 6

                                            FactTextField {
                                                Layout.fillWidth: true
                                                height: 34
                                                fact: batParams.battLowVolt
                                                showUnits: false
                                                enabled: parametersReady

                                                background: Rectangle { color: "transparent"; border.width: 0 }
                                            }

                                            Text {
                                                text: "V"
                                                color: parametersReady ? "#000000" : "#888888"
                                                font.pixelSize: 16
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
                                    }
                                }

                                FormRow {
                                    title: qsTr("Tam dolu gərginlik (hər element üçün)")
                                    Rectangle {
                                        width: parent.width
                                        height: 34
                                        color: parametersReady ? "white" : "#E0E0E0"
                                        radius: 4

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 6

                                            FactTextField {
                                                Layout.fillWidth: true
                                                height: 34
                                                fact: batParams.battHighVolt
                                                showUnits: false
                                                enabled: parametersReady

                                                background: Rectangle { color: "transparent"; border.width: 0 }
                                            }

                                            Text {
                                                text: "V"
                                                color: parametersReady ? "#000000" : "#888888"
                                                font.pixelSize: 16
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
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
                                        spacing: 12

                                        FactTextField {
                                            id: vdField
                                            width: root._wideForm
                                                   ? Math.max(170, vdFlow.width - (vdCalc.width + vdFlow.spacing))
                                                   : vdFlow.width
                                            height: 34
                                            fact: batParams.battVoltageDivider
                                            enabled: parametersReady

                                            background: Rectangle {
                                                color: parametersReady ? "white" : "#E0E0E0"
                                                radius: 4
                                                border.color: "#9D9D9D"
                                                border.width: 0.5
                                            }
                                        }

                                        Rectangle {
                                            id: vdCalc
                                            width: root._wideForm ? 197 : vdFlow.width
                                            height: 34
                                            color: parametersReady ? "#3D3B3B" : "#5D5B5B"
                                            radius: 4
                                            border.color: "#9D9D9D"
                                            border.width: 0.5

                                            Text {
                                                text: "Hesabla"
                                                color: parametersReady ? "#FFFFFF" : "#888888"
                                                font.pixelSize: 16
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parametersReady
                                                onClicked: calcVoltageDividerDlgComponent.createObject(mainWindow).open()
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 13
                                    color: "#FFFFFF"
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
                                        spacing: 12

                                        FactTextField {
                                            id: apvField
                                            width: root._wideForm
                                                   ? Math.max(170, apvFlow.width - (apvCalc.width + apvFlow.spacing))
                                                   : apvFlow.width
                                            height: 34
                                            fact: batParams.battAmpsPerVolt
                                            enabled: parametersReady

                                            background: Rectangle {
                                                color: parametersReady ? "white" : "#E0E0E0"
                                                radius: 4
                                                border.color: "#9D9D9D"
                                                border.width: 0.5
                                            }
                                        }

                                        Rectangle {
                                            id: apvCalc
                                            width: root._wideForm ? 197 : apvFlow.width
                                            height: 34
                                            color: parametersReady ? "#3D3B3B" : "#5D5B5B"
                                            radius: 4
                                            border.color: "#9D9D9D"
                                            border.width: 0.5

                                            Text {
                                                text: "Calculate"
                                                color: parametersReady ? "#FFFFFF" : "#888888"
                                                font.pixelSize: 16
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parametersReady
                                                onClicked: calcAmpsPerVoltDlgComponent.createObject(mainWindow).open()
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: 13
                                    color: "#FFFFFF"
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
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                font.pixelSize: 16
                                color: "#FFFFFF"
                                visible: parametersReady && batParams.battSource.rawValue == -1
                                text: "Battery monitoring is disabled. No battery parameters will be available."
                            }

                            // ----- ESC Calibration section -----
                            Text {
                                Layout.fillWidth: true
                                text: "ESC PWM Minimum and Maximum Calibration"
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                font.bold: true
                                wrapMode: Text.WordWrap
                                visible: parametersReady
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 6
                                color: "#2A2A2A"
                                visible: parametersReady
                                implicitHeight: escGrid.implicitHeight + 28

                                GridLayout {
                                    id: escGrid
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    columns: root._wideForm ? 2 : 1
                                    columnSpacing: 16
                                    rowSpacing: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: qsTr("XƏBƏRDARLIQ: ESC kalibrləməsini aparmazdan əvvəl pervanelər mütləq aparatdan çıxarılmalıdır.")
                                            color: "#FF6B6B"
                                            font.pixelSize: 14
                                            font.bold: true
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: qsTr("Bu əməliyyat üçün USB bağlantısından istifadə etməlisiniz.")
                                            color: "#FFFFFF"
                                            font.pixelSize: 14
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Rectangle {
                                        Layout.alignment: root._wideForm ? Qt.AlignRight : Qt.AlignLeft
                                        Layout.fillWidth: !root._wideForm
                                        Layout.preferredWidth: root._wideForm ? 197 : -1
                                        height: 37
                                        color: parametersReady ? "#3D3B3B" : "#5D5B5B"
                                        radius: 4
                                        border.color: "#9D9D9D"
                                        border.width: 0.5

                                        Text {
                                            text: qsTr("Kalibrlə")
                                            color: parametersReady ? "#FFFFFF" : "#888888"
                                            font.pixelSize: 16
                                            anchors.centerIn: parent
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: parametersReady
                                            onClicked: controller.calibrateEsc()
                                        }
                                    }
                                }
                            }

                            // ----- UAVCAN toggle -----
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                visible: parametersReady

                                Rectangle {
                                    width: 22
                                    height: 22
                                    color: "#3D3B3B"
                                    radius: 3
                                    border.color: "#9D9D9D"
                                    border.width: 1

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        color: "#FFFFFF"
                                        radius: 2
                                        anchors.centerIn: parent
                                        visible: root.showUAVCAN
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.showUAVCAN = !root.showUAVCAN
                                    }
                                }

                                Text {
                                    text: qsTr("UAVCAN parametrlərini göstər")
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            // ----- UAV Bus Configuration -----
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("UAV şin konfiqurasiyası")
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                font.bold: true
                                visible: parametersReady && root.showUAVCAN
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 6
                                color: "#2A2A2A"
                                visible: parametersReady && root.showUAVCAN
                                implicitHeight: uavGrid.implicitHeight + 28

                                GridLayout {
                                    id: uavGrid
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    columns: root._wideForm ? 3 : 1
                                    columnSpacing: 16
                                    rowSpacing: 10

                                    Text {
                                        text: qsTr("UAV şin konfiqurasiyası")
                                        color: "#FFFFFF"
                                        font.pixelSize: 16
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: qsTr("Dəyişiklik üçün yenidən başladılması tələb olunur")
                                        color: "#FFFFFF"
                                        font.pixelSize: 14
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    FactComboBox {
                                        Layout.fillWidth: !root._wideForm
                                        Layout.preferredWidth: root._wideForm ? 197 : -1
                                        height: 34
                                        fact: controller.getParameterFact(-1, "UAVCAN_ENABLE", false)
                                        indexModel: false
                                        enabled: parametersReady

                                        background: Rectangle {
                                            color: "#3D3B3B"
                                            radius: 4
                                            border.color: "#9D9D9D"
                                            border.width: 0.5
                                        }

                                        contentItem: Text {
                                            text: parametersReady ? parent.currentText : qsTr("Yüklənir...")
                                            color: parametersReady ? "#FFFFFF" : "#888888"
                                            font.pixelSize: 16
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.fill: parent
                                        }
                                    }
                                }
                            }

                            // ----- UAVCAN Motor Assignment -----
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("UAVCAN mühərrik indeksinin və fırlanma istiqamətinin təyini")
                                color: "#FFFFFF"
                                font.pixelSize: 13
                                font.bold: true
                                visible: parametersReady && root.showUAVCAN
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 6
                                color: "#2A2A2A"
                                visible: parametersReady && root.showUAVCAN
                                implicitHeight: assignCol.implicitHeight + 28

                                ColumnLayout {
                                    id: assignCol
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 8

                                    Text {
                                        text: qsTr("XƏBƏRDARLIQ: ESC kalibrləməsini aparmazdan əvvəl pervanelər mütləq aparatdan çıxarılmalıdır.")
                                        color: "#FF6B6B"
                                        font.pixelSize: 12
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: qsTr("ESC parametrlərinə yalnız təyinat (assignment) tamamlandıqdan sonra redaktorda çıxış mümkün olacaq.")
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: qsTr("Prosesi başladın, sonra mühərrik indekslərinin sırasına uyğun olaraq hər mühərriki öz fırlanma istiqamətində hərəkətə gətirin.")
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        Rectangle {
                                            width: root._wideForm ? 180 : parent.width
                                            height: 32
                                            color: parametersReady ? "#3D3B3B" : "#5D5B5B"
                                            radius: 4
                                            border.color: "#9D9D9D"
                                            border.width: 0.5

                                            Text {
                                                text: qsTr("Təyinata başla")
                                                color: parametersReady ? "#FFFFFF" : "#888888"
                                                font.pixelSize: 14
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parametersReady
                                                onClicked: controller.startBusConfigureActuators()
                                            }
                                        }

                                        Rectangle {
                                            width: root._wideForm ? 180 : parent.width
                                            height: 32
                                            color: parametersReady ? "#3D3B3B" : "#5D5B5B"
                                            radius: 4
                                            border.color: "#9D9D9D"
                                            border.width: 0.5

                                            Text {
                                                text: qsTr("Təyinatı dayandır")
                                                color: parametersReady ? "#FFFFFF" : "#888888"
                                                font.pixelSize: 14
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parametersReady
                                                onClicked: controller.stopBusConfigureActuators()
                                            }
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

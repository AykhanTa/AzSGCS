import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
//import QtQuick.Dialogs 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

Rectangle {
    id: root
    anchors.fill: parent
    color: "#000000"

    // ------------------ Data ------------------
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _mavlinkSettings:           _settingsManager.mavlinkSettings
    property var    _appSettings:               _settingsManager.appSettings
    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property string _notConnectedStr:           qsTr("Təyyarə qoşulmayıb")
    property bool   _isAPM:                     _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool   _showAPMStreamRates:        QGroundControl.apmFirmwareSupported && _settingsManager.apmMavlinkStreamRateSettings.visible && _isAPM
    property var    _apmStartMavlinkStreams:    _mavlinkSettings.apmStartMavlinkStreams

    // ------------------ Responsive metrics (same approach) ------------------
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100

    readonly property real sidePadding: Math.max(10, ScreenTools.defaultFontPixelWidth  * (phone ? 0.9 : tablet ? 1.2 : 1.6))
    readonly property real gap:         Math.max(10, ScreenTools.defaultFontPixelWidth  * (phone ? 0.9 : tablet ? 1.2 : 1.6))

    readonly property real fontScale: {
        var w = Math.max(1, width)
        var s = w / 1400.0
        s = Math.min(1.0, s)
        return Math.max(0.90, Math.min(1.0, s))
    }

    readonly property real titleFontPx: Math.max(18, ScreenTools.defaultFontPixelHeight * (phone ? 1.15 : 1.25) * fontScale)
    readonly property real descFontPx:  Math.max(12, ScreenTools.defaultFontPixelHeight * (phone ? 0.92 : 0.98) * fontScale)
    readonly property real labelFontPx: Math.max(11, ScreenTools.defaultFontPixelHeight * (phone ? 0.90 : 0.88) * fontScale)

    readonly property real availableW: Math.max(0, width - 2 * sidePadding)

    // Blok ölçüləri Uçuş Görünüşü səhifəsi ilə eynidir (Fly_ViewSettings.qml)
    readonly property real minColW: (tablet ? 520 : 720)
    readonly property real maxColW: 820

    readonly property int columns: (phone || availableW < (2 * minColW + gap)) ? 1 : 2

    readonly property real panelW: (columns === 1)
                                        ? availableW
                                        : Math.min(maxColW, Math.floor((availableW - gap) / 2))

    readonly property real rowPadX: Math.max(12, ScreenTools.defaultFontPixelWidth * 1.2)
    readonly property real rowPadY: Math.max(8,  ScreenTools.defaultFontPixelHeight * 0.6)
    readonly property real rowMinH: Math.max(48, ScreenTools.defaultFontPixelHeight * 2.6)

    // Sətirlərdəki kontrolların sabit eni — bütün bloklarda combobox/textbox eyni ölçüdə
    // və eyni xətt üzrə düzülsün deyə (digər tənzimləmə səhifələri ilə eyni formula).
    readonly property real ctrlW: Math.max(140, Math.min(260, panelW * (phone ? 0.60 : 0.42)))

    readonly property real wheelStepPx: Math.max(60, ScreenTools.defaultFontPixelHeight * 3.2)

    // ===== Equal-height rows (for 2-column desktop view) =====
    readonly property real row1H: {
        if (columns < 2) return 0
        var a = (groundStationPanel && groundStationPanel.visible) ? groundStationPanel.desiredH : 0
        var b = (signingPanel && signingPanel.visible) ? signingPanel.desiredH : 0
        return Math.max(a, b)
    }
    readonly property real row2H: {
        if (columns < 2) return 0
        var a = (forwardingPanel && forwardingPanel.visible) ? forwardingPanel.desiredH : 0
        var b = (loggingPanel && loggingPanel.visible) ? loggingPanel.desiredH : 0
        return Math.max(a, b)
    }
    readonly property real row3H: {
        if (columns < 2) return 0
        var a = (streamRatesPanel && streamRatesPanel.visible) ? streamRatesPanel.desiredH : 0
        var b = (linkStatusPanel && linkStatusPanel.visible) ? linkStatusPanel.desiredH : 0
        return Math.max(a, b)
    }

    // ------------------ Map arxaya keçməsin (click/drag + wheel) ------------------
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onPressed:  (m) => { m.accepted = true }
        onReleased: (m) => { m.accepted = true }
        onClicked:  (m) => { m.accepted = true }
        onPositionChanged: (m) => { m.accepted = true }
    }

    // ------------------ Header (NO extra top boşluq) ------------------
    Column {
        id: headerArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: sidePadding
        anchors.rightMargin: sidePadding
        anchors.topMargin: 0
        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.6)

        Text {
            text: qsTr("MAVLink & Telemetri Tənzimləmələri")
            color: "white"
            font.pixelSize: 26
            font.bold: true
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Text {
            text: qsTr("Uçuş zamanı MAVLink rabitə parametrlərini, loglamanı və məlumat ötürmə sürətlərini idarə edir.")
            color: "#E8E8E8"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#FFFFFF"
            opacity: 0.25
        }
    }

    // ------------------ Main scroll area (no horizontal scroll) ------------------
    QGCFlickable {
        id: flick
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.4)

        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        contentWidth: width
        contentHeight: contentColumn.implicitHeight + sidePadding

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        // WheelHandler {
        //     acceptedDevices: PointerDevice.Mouse
        //     onWheel: (event) => {
        //         event.accepted = true
        //         var delta = (event.pixelDelta.y !== 0)
        //                   ? event.pixelDelta.y
        //                   : (event.angleDelta.y / 120.0) * root.wheelStepPx
        //         var maxY = Math.max(0, flick.contentHeight - flick.height)
        //         flick.contentY = Math.max(0, Math.min(maxY, flick.contentY - delta))
        //     }
        // }

        Column {
            id: contentColumn
            width: flick.width
            spacing: gap

            Flow {
                id: panelFlow
                x: sidePadding
                width: Math.max(0, flick.width - 2 * sidePadding)
                spacing: gap
                height: childrenRect.height

                // ================== Ground Station ==================
                Rectangle {
                    id: groundStationPanel
                    width: Math.min(root.panelW, panelFlow.width)
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"

                    readonly property real pad: Math.max(14, ScreenTools.defaultFontPixelWidth * 1.2)
                    readonly property real desiredH: gsLayout.implicitHeight + pad * 2
                    height: (root.columns > 1 && signingPanel && signingPanel.visible) ? root.row1H : desiredH

                    ColumnLayout {
                        id: gsLayout
                        anchors.fill: parent
                        anchors.margins: groundStationPanel.pad
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                        Text {
                            text: qsTr("Yer stansiyası")
                            color: "#FFFFFF"
                            font.pixelSize: Math.max(15, ScreenTools.defaultFontPixelHeight * 1.05 * root.fontScale)
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // MAVLink System ID
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _mavlinkSettings.gcsMavlinkSystemID.visible
                            implicitHeight: Math.max(root.rowMinH, gsIdGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: gsIdGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("MAVLink Sistem İD")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactTextField {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                    fact: _mavlinkSettings.gcsMavlinkSystemID
                                }
                            }
                        }

                        // Emit heartbeat
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _mavlinkSettings.sendGCSHeartbeat.visible
                            implicitHeight: Math.max(root.rowMinH, hbGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: hbGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Emit heartbeat")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    fact: _mavlinkSettings.sendGCSHeartbeat
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ================== MAVLink 2 Signing ==================
                Rectangle {
                    id: signingPanel
                    width: Math.min(root.panelW, panelFlow.width)
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"
                    visible: _mavlinkSettings.mavlink2SigningKey.visible

                    readonly property real pad: Math.max(14, ScreenTools.defaultFontPixelWidth * 1.2)
                    readonly property real desiredH: signingLayout.implicitHeight + pad * 2
                    height: (root.columns > 1 && groundStationPanel && groundStationPanel.visible) ? root.row1H : desiredH

                    ColumnLayout {
                        id: signingLayout
                        anchors.fill: parent
                        anchors.margins: signingPanel.pad
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                        Text {
                            text: qsTr("MAVLink 2 İmzalanması")
                            color: "#FFFFFF"
                            font.pixelSize: Math.max(15, ScreenTools.defaultFontPixelHeight * 1.05 * root.fontScale)
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: qsTr("İmza açarları yalnız təhlükəsiz keçidlər vasitəsilə təyyarəyə göndərilməlidir.")
                            color: "#CCCCCC"
                            font.pixelSize: Math.max(12, ScreenTools.defaultFontPixelHeight * 0.92 * root.fontScale)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Signing Key
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            implicitHeight: Math.max(root.rowMinH, keyGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: keyGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Açar")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                }

                                FactTextField {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _mavlinkSettings.mavlink2SigningKey
                                    onTextChanged: sendToVehiclePrompt.visible = true
                                }
                            }
                        }

                        // Send button + prompt
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            implicitHeight: Math.max(root.rowMinH + 30, sendCol.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            ColumnLayout {
                                id: sendCol
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: Math.max(6, root.gap * 0.4)

                                RowLayout {
                                    Layout.fillWidth: true

                                    QGCButton {
                                        text: qsTr("Təyyarəyə göndərin")
                                        enabled: _activeVehicle
                                        Layout.preferredWidth: root.phone ? -1 : 220
                                        Layout.fillWidth: root.phone
                                        onClicked: {
                                            sendToVehiclePrompt.visible = false
                                            if (_activeVehicle) _activeVehicle.sendSetupSigning()
                                        }
                                    }

                                    Item { Layout.fillWidth: true; visible: !root.phone }
                                }

                                QGCLabel {
                                    id: sendToVehiclePrompt
                                    Layout.fillWidth: true
                                    text: qsTr("İmza açarı dəyişdi. Lazım gələrsə, Təyyarə(lər)ə göndərməyi unutmayın.")
                                    color: "yellow"
                                    visible: false
                                    wrapMode: Text.WordWrap
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ================== MAVLink Forwarding ==================
                Rectangle {
                    id: forwardingPanel
                    width: Math.min(root.panelW, panelFlow.width)
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"

                    readonly property real pad: Math.max(14, ScreenTools.defaultFontPixelWidth * 1.2)
                    readonly property real desiredH: fwdLayout.implicitHeight + pad * 2
                    height: (root.columns > 1 && loggingPanel && loggingPanel.visible) ? root.row2H : desiredH

                    ColumnLayout {
                        id: fwdLayout
                        anchors.fill: parent
                        anchors.margins: forwardingPanel.pad
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                        Text {
                            text: qsTr("MAVLink Yönləndirilməsi")
                            color: "#FFFFFF"
                            font.pixelSize: Math.max(15, ScreenTools.defaultFontPixelHeight * 1.05 * root.fontScale)
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Enable Forwarding
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _mavlinkSettings.forwardMavlink.visible
                            implicitHeight: Math.max(root.rowMinH, fwdOnGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: fwdOnGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Aktivləşdirin")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                }

                                FactCheckBoxSlider {
                                    fact: _mavlinkSettings.forwardMavlink
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                }
                            }
                        }

                        // Host Name
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _mavlinkSettings.forwardMavlinkHostName.visible
                            implicitHeight: Math.max(root.rowMinH, hostGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: hostGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Host adı")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                }

                                FactTextField {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _mavlinkSettings.forwardMavlinkHostName
                                    enabled: _mavlinkSettings.forwardMavlink.rawValue
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ================== Logging ==================
                Rectangle {
                    id: loggingPanel
                    width: Math.min(root.panelW, panelFlow.width)
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"
                    visible: !_disableAllDataPersistence

                    readonly property real pad: Math.max(14, ScreenTools.defaultFontPixelWidth * 1.2)
                    readonly property real desiredH: logLayout.implicitHeight + pad * 2
                    height: (root.columns > 1 && forwardingPanel && forwardingPanel.visible) ? root.row2H : desiredH

                    ColumnLayout {
                        id: logLayout
                        anchors.fill: parent
                        anchors.margins: loggingPanel.pad
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                        Text {
                            text: qsTr("Logging")
                            color: "#FFFFFF"
                            font.pixelSize: Math.max(15, ScreenTools.defaultFontPixelHeight * 1.05 * root.fontScale)
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Save log after each flight
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _mavlinkSettings.telemetrySave.visible
                            implicitHeight: Math.max(root.rowMinH, s1Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: s1Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Hər uçuşdan sonra logu yadda saxlayın")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    fact: _mavlinkSettings.telemetrySave
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                }
                            }
                        }

                        // Save logs even if vehicle was not armed
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _mavlinkSettings.telemetrySaveNotArmed.visible
                            implicitHeight: Math.max(root.rowMinH, s2Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: s2Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Təyyarə armed olmasa belə, logları qeyd edin")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    fact: _mavlinkSettings.telemetrySaveNotArmed
                                    enabled: _mavlinkSettings.telemetrySave.rawValue
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                }
                            }
                        }

                        // Save CSV log of telemetry data
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _mavlinkSettings.saveCsvTelemetry.visible
                            implicitHeight: Math.max(root.rowMinH, s3Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: s3Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Telemetriya məlumatlarının CSV logunu yadda saxlayın")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    fact: _mavlinkSettings.saveCsvTelemetry
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ================== Stream Rates (ArduPilot Only) ==================
                Rectangle {
                    id: streamRatesPanel
                    width: Math.min(root.panelW, panelFlow.width)
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"
                    visible: _showAPMStreamRates

                    readonly property real pad: Math.max(14, ScreenTools.defaultFontPixelWidth * 1.2)
                    readonly property real desiredH: srLayout.implicitHeight + pad * 2
                    height: (root.columns > 1 && linkStatusPanel && linkStatusPanel.visible) ? root.row3H : desiredH

                    ColumnLayout {
                        id: srLayout
                        anchors.fill: parent
                        anchors.margins: streamRatesPanel.pad
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                        Text {
                            text: qsTr("Stream Rates (ArduPilot Only)")
                            color: "#FFFFFF"
                            font.pixelSize: Math.max(15, ScreenTools.defaultFontPixelHeight * 1.05 * root.fontScale)
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Controlled by vehicle
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            implicitHeight: Math.max(root.rowMinH, srCtlGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: srCtlGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Təyyarə tərəfindən idarə olunur")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    fact: _apmStartMavlinkStreams
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                }
                            }
                        }

                        // Helper for stream rate rows
                        function _rateRow(labelText, factObj, visibleExpr) {
                            // dummy: QML-in JS functionu ilə component yaratmaq olmur; aşağıda eyni pattern copy/paste verilib.
                        }

                        // Raw Sensors
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _settingsManager.apmMavlinkStreamRateSettings.streamRateRawSensors.visible
                            implicitHeight: Math.max(root.rowMinH, srRawGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: srRawGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Raw Sensorları")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateRawSensors
                                    indexModel: false
                                    enabled: _apmStartMavlinkStreams.rawValue
                                }
                            }
                        }

                        // Extended Status
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtendedStatus.visible
                            implicitHeight: Math.max(root.rowMinH, srExtGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: srExtGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Extended Status")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtendedStatus
                                    indexModel: false
                                    enabled: _apmStartMavlinkStreams.rawValue
                                }
                            }
                        }

                        // RC Channels
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _settingsManager.apmMavlinkStreamRateSettings.streamRateRCChannels.visible
                            implicitHeight: Math.max(root.rowMinH, srRcGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: srRcGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("RC Kanalları")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateRCChannels
                                    indexModel: false
                                    enabled: _apmStartMavlinkStreams.rawValue
                                }
                            }
                        }

                        // Position
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _settingsManager.apmMavlinkStreamRateSettings.streamRatePosition.visible
                            implicitHeight: Math.max(root.rowMinH, srPosGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: srPosGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Position")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _settingsManager.apmMavlinkStreamRateSettings.streamRatePosition
                                    indexModel: false
                                    enabled: _apmStartMavlinkStreams.rawValue
                                }
                            }
                        }

                        // Extra 1
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra1.visible
                            implicitHeight: Math.max(root.rowMinH, srE1Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: srE1Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Extra 1")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra1
                                    indexModel: false
                                    enabled: _apmStartMavlinkStreams.rawValue
                                }
                            }
                        }

                        // Extra 2
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra2.visible
                            implicitHeight: Math.max(root.rowMinH, srE2Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: srE2Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Extra 2")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra2
                                    indexModel: false
                                    enabled: _apmStartMavlinkStreams.rawValue
                                }
                            }
                        }

                        // Extra 3
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            visible: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra3.visible
                            implicitHeight: Math.max(root.rowMinH, srE3Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: srE3Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Extra 3")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                    Layout.fillWidth: root.phone
                                    Layout.alignment: Qt.AlignRight
                                    fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra3
                                    indexModel: false
                                    enabled: _apmStartMavlinkStreams.rawValue
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ================== Link Status ==================
                Rectangle {
                    id: linkStatusPanel
                    width: Math.min(root.panelW, panelFlow.width)
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"

                    readonly property real pad: Math.max(14, ScreenTools.defaultFontPixelWidth * 1.2)
                    readonly property real desiredH: lsLayout.implicitHeight + pad * 2
                    height: (root.columns > 1 && streamRatesPanel && streamRatesPanel.visible) ? root.row3H : desiredH

                    ColumnLayout {
                        id: lsLayout
                        anchors.fill: parent
                        anchors.margins: linkStatusPanel.pad
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                        Text {
                            text: qsTr("Link Status (Cari Təyyarə)")
                            color: "#FFFFFF"
                            font.pixelSize: Math.max(15, ScreenTools.defaultFontPixelHeight * 1.05 * root.fontScale)
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Total sent
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            implicitHeight: Math.max(root.rowMinH, ls1Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: ls1Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Göndərilən ümumi mesajlar (hesablanmış)")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                                QGCLabel {
                                    text: _activeVehicle ? _activeVehicle.mavlinkSentCount : _notConnectedStr
                                    color: "#CCCCCC"
                                    font.pixelSize: root.labelFontPx
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // Total received
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            implicitHeight: Math.max(root.rowMinH, ls2Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: ls2Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Cəmi qəbul edilən mesajlar")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                                QGCLabel {
                                    text: _activeVehicle ? _activeVehicle.mavlinkReceivedCount : _notConnectedStr
                                    color: "#CCCCCC"
                                    font.pixelSize: root.labelFontPx
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // Total loss
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            implicitHeight: Math.max(root.rowMinH, ls3Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: ls3Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Ümumi mesaj itkisi")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                                QGCLabel {
                                    text: _activeVehicle ? _activeVehicle.mavlinkLossCount : _notConnectedStr
                                    color: "#CCCCCC"
                                    font.pixelSize: root.labelFontPx
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // Loss rate
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            implicitHeight: Math.max(root.rowMinH, ls4Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: ls4Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Zərər dərəcəsi:")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                }
                                QGCLabel {
                                    text: _activeVehicle ? _activeVehicle.mavlinkLossPercent.toFixed(0) + "%" : _notConnectedStr
                                    color: "#CCCCCC"
                                    font.pixelSize: root.labelFontPx
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                }
                            }
                        }

                        // Signing
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: "#2A2A2A"
                            implicitHeight: Math.max(root.rowMinH, ls5Grid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: ls5Grid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("İmzalama:")
                                    color: "white"
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                }
                                QGCLabel {
                                    text: _activeVehicle ? (_activeVehicle.mavlinkSigning ? qsTr("On") : qsTr("Off")) : _notConnectedStr
                                    color: "#CCCCCC"
                                    font.pixelSize: root.labelFontPx
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            Item { width: 1; height: sidePadding }
        }
    }
    // ✅ Wheel həmişə root-da tutulur -> arxadakı map zoom etməyəcək
    WheelHandler {
        id: globalWheel
        acceptedDevices: PointerDevice.Mouse

        onWheel: (event) => {
            event.accepted = true

            var delta = (event.pixelDelta.y !== 0)
                      ? event.pixelDelta.y
                      : (event.angleDelta.y / 120.0) * root.wheelStepPx

            // Flick sahəsinin üstündədirsə -> flick scroll
            var p = flick.mapFromItem(root, event.x, event.y)
            var overFlick = (p.x >= 0 && p.y >= 0 && p.x < flick.width && p.y < flick.height)

            if (overFlick) {
                var maxY = Math.max(0, flick.contentHeight - flick.height)
                flick.contentY = Math.max(0, Math.min(maxY, flick.contentY - delta))
            }
            // Əks halda sadəcə wheel-i uduruq (map-ə getməsin)
        }
    }

}

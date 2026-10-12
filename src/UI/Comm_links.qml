
import QtQuick 2.15
import QtQuick.Controls 2.15
//import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

SettingsPage {
    id: root

    property var _linkManager:         QGroundControl.linkManager
    property var _autoConnectSettings: QGroundControl.settingsManager.autoConnectSettings

    // ------------------ Responsive metrics ------------------
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool narrow: width < 900
    readonly property bool tiny:   width < 560

    readonly property real sidePad: Math.max(12, ScreenTools.defaultFontPixelWidth  * (phone ? 1.0 : 1.6))
    readonly property real gap:     Math.max(10, ScreenTools.defaultFontPixelHeight * (phone ? 0.70 : 0.95))

    readonly property real titlePx: Math.max(18, ScreenTools.defaultFontPixelHeight * (phone ? 1.15 : 1.55))
    readonly property real descPx:  Math.max(12, ScreenTools.defaultFontPixelHeight * (phone ? 0.95 : 1.05))
    readonly property real sectionPx: Math.max(14, ScreenTools.defaultFontPixelHeight * (tiny ? 0.92 : phone ? 1.00 : 1.15))
    readonly property real labelPx:   Math.max(10, ScreenTools.defaultFontPixelHeight * (tiny ? 0.78 : phone ? 0.90 : 1.00))

    readonly property real rowPadX: Math.max(12, ScreenTools.defaultFontPixelWidth  * 1.2)
    readonly property real rowPadY: Math.max(8,  ScreenTools.defaultFontPixelHeight * 0.6)
    readonly property real rowMinH: Math.max(46, ScreenTools.defaultFontPixelHeight * 2.5)
    readonly property real wheelStepPx: Math.max(60, ScreenTools.defaultFontPixelHeight * 3.2)

    // ================== Wheel blok (map-ə keçməsin) ==================
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        onWheel: (event) => {
            event.accepted = true
            var f = scrollView.contentItem
            if (!f) return
            var delta = (event.pixelDelta.y !== 0)
                      ? event.pixelDelta.y
                      : (event.angleDelta.y / 120.0) * root.wheelStepPx
            var maxY = Math.max(0, f.contentHeight - f.height)
            f.contentY = Math.max(0, Math.min(maxY, f.contentY - delta))
        }
    }

    // ================== Header (no top gap, left/top aligned) ==================
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.6)

        QGCLabel {
            text: qsTr("Rabitə Kanalları")
            color: "white"
            font.pixelSize: 26
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        QGCLabel {
            text: qsTr("Bu bölüm drone ilə %1 arasında bağlantı ayarlarını idarə etmək üçün istifadə olunur.").arg(QGroundControl.appName)
            color: "#E8E8E8"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "white"
            opacity: 0.25
        }
    }

    // ================== Main scroll (only vertical) ==================
    ScrollView {
        id: scrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        // ❗ sağa scroll olmasın
        contentWidth: width

        ColumnLayout {
            id: contentCol
            width: scrollView.width
            spacing: gap

            // ================== AutoConnect ==================
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                color: "#2a2a2a"
                radius: 12
                border.color: "white"
                border.width: 2

                implicitHeight: autoCardCol.implicitHeight + 24
                height: implicitHeight

                ColumnLayout {
                    id: autoCardCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: gap

                    QGCLabel {
                        text: qsTr("AutoConnect")
                        color: "white"
                        font.pixelSize: sectionPx
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        color: "#3D3B3B"
                        radius: 10
                        border.color: "white"
                        border.width: 2

                        implicitHeight: autoListCol.implicitHeight + 20
                        height: implicitHeight

                        ColumnLayout {
                            id: autoListCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            Repeater {
                                id: autoConnectRepeater
                                model: [
                                    _autoConnectSettings.autoConnectPixhawk,
                                    _autoConnectSettings.autoConnectSiKRadio,
                                    _autoConnectSettings.autoConnectLibrePilot,
                                    _autoConnectSettings.autoConnectUDP,
                                    _autoConnectSettings.autoConnectZeroConf,
                                    _autoConnectSettings.autoConnectRTKGPS
                                ]

                                property var names: [
                                    qsTr("Pixhawk"),
                                    qsTr("SiK Radio"),
                                    qsTr("LibrePilot"),
                                    qsTr("UDP"),
                                    qsTr("Zero-Conf"),
                                    qsTr("RTK")
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    radius: 8
                                    color: "#2A2A2A"
                                    implicitHeight: Math.max(rowMinH, rowGrid.implicitHeight + rowPadY * 2)
                                    height: implicitHeight

                                    GridLayout {
                                        id: rowGrid
                                        anchors.fill: parent
                                        anchors.leftMargin: rowPadX
                                        anchors.rightMargin: rowPadX
                                        anchors.topMargin: rowPadY
                                        anchors.bottomMargin: rowPadY
                                        columns: 2
                                        columnSpacing: gap
                                        rowSpacing: 6

                                        QGCLabel {
                                            text: autoConnectRepeater.names[index]
                                            color: "white"
                                            font.pixelSize: labelPx
                                            font.bold: true
                                            elide: Text.ElideRight
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                        }

                                        Rectangle {
                                            width: 44
                                            height: 22
                                            radius: 15
                                            color: modelData.value ? "#4CAF50" : "#666666"
                                            border.color: "#FFFFFF"
                                            border.width: 2
                                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                            Rectangle {
                                                x: modelData.value ? parent.width - width - 3 : 3
                                                y: 3
                                                width: 14
                                                height: 14
                                                radius: 12
                                                color: "white"
                                                Behavior on x { NumberAnimation { duration: 200 } }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    modelData.value = !modelData.value

                                                    // UDP aktiv edilirsə digər UDP bağlantılarını kəs
                                                    if (index === 3 && modelData.value) { // UDP index = 3
                                                        _closeOtherConnectionsForUDP()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ✅ UDP aktiv ediləndə mövcud UDP linklərini kəs
            function _closeOtherConnectionsForUDP() {
                if (!_linkManager || !_linkManager.linkConfigurations) return

                for (var i = 0; i < _linkManager.linkConfigurations.count; i++) {
                    var linkConfig = _linkManager.linkConfigurations.get(i)
                    if (!linkConfig || !linkConfig.name) continue

                    if (linkConfig.name.toLowerCase().includes("udp") && linkConfig.link) {
                        try { linkConfig.link.disconnect() } catch (e) { }
                    }
                }
            }

            // ================== NMEA + Links (responsive: narrow => stacked) ==================
            GridLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                columns: root.narrow ? 1 : 2
                columnSpacing: gap
                rowSpacing: gap

                // -------- NMEA GPS --------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: Math.max(8, gap * 0.75)

                    QGCLabel {
                        text: qsTr("NMEA GPS")
                        color: "white"
                        font.pixelSize: sectionPx
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        visible: QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.visible &&
                                 QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.visible
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        color: "#3D3B3B"
                        radius: 10
                        border.color: "white"
                        border.width: 2
                        visible: QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.visible &&
                                 QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.visible

                        implicitHeight: nmeaContentColumn.implicitHeight + 24
                        height: implicitHeight

                        ColumnLayout {
                            id: nmeaContentColumn
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            // DEVICE
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                radius: 8
                                color: "#2A2A2A"
                                implicitHeight: Math.max(rowMinH, devGrid.implicitHeight + rowPadY * 2)
                                height: implicitHeight

                                GridLayout {
                                    id: devGrid
                                    anchors.fill: parent
                                    anchors.leftMargin: rowPadX
                                    anchors.rightMargin: rowPadX
                                    anchors.topMargin: rowPadY
                                    anchors.bottomMargin: rowPadY
                                    columns: root.phone ? 1 : 2
                                    columnSpacing: gap
                                    rowSpacing: 6

                                    QGCLabel {
                                        text: qsTr("Device")
                                        color: "white"
                                        font.pixelSize: labelPx
                                        font.bold: true
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                    }

                                    QGCComboBox {
                                        sizeToContents: true
                                        id: nmeaPortCombo
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        Layout.preferredHeight: 35

                                        background: Rectangle {
                                            color: "#1A1A1A"
                                            border.color: "#FFFFFF"
                                            border.width: 1
                                            radius: 4
                                        }

                                        contentItem: Text {
                                            text: nmeaPortCombo.displayText
                                            color: "white"
                                            font.pixelSize: Math.max(11, root.labelPx)
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 8
                                            elide: Text.ElideRight
                                        }

                                        model: ListModel {}

                                        onActivated: (index) => {
                                            if (index !== -1) {
                                                var selectedValue = nmeaPortCombo.textAt(index)
                                                QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.value = selectedValue
                                                if (selectedValue === "UDP Port") {
                                                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = 0
                                                }
                                            }
                                        }

                                        Component.onCompleted: {
                                            var m = []
                                            m.push(qsTr("Disabled"))
                                            m.push(qsTr("UDP Port"))

                                            if (QGroundControl.linkManager.serialPorts.length === 0) {
                                                m.push(qsTr("Serial <none available>"))
                                            } else {
                                                for (var i in QGroundControl.linkManager.serialPorts) {
                                                    m.push(QGroundControl.linkManager.serialPorts[i])
                                                }
                                            }
                                            nmeaPortCombo.model = m

                                            var savedValue = QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.valueString
                                            var foundIndex = -1
                                            for (var j = 0; j < nmeaPortCombo.count; j++) {
                                                if (nmeaPortCombo.textAt(j) === savedValue) { foundIndex = j; break }
                                            }
                                            if (foundIndex === -1) {
                                                for (var k = 0; k < nmeaPortCombo.count; k++) {
                                                    if (nmeaPortCombo.textAt(k) === "Disabled") { foundIndex = k; break }
                                                }
                                            }
                                            nmeaPortCombo.currentIndex = foundIndex
                                        }
                                    }
                                }
                            }

                            // BAUD
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                radius: 8
                                color: "#2A2A2A"
                                visible: (nmeaPortCombo.currentText !== "UDP Port") && (nmeaPortCombo.currentText !== "Disabled")
                                implicitHeight: Math.max(rowMinH, baudGrid.implicitHeight + rowPadY * 2)
                                height: implicitHeight

                                GridLayout {
                                    id: baudGrid
                                    anchors.fill: parent
                                    anchors.leftMargin: rowPadX
                                    anchors.rightMargin: rowPadX
                                    anchors.topMargin: rowPadY
                                    anchors.bottomMargin: rowPadY
                                    columns: root.phone ? 1 : 2
                                    columnSpacing: gap
                                    rowSpacing: 6

                                    QGCLabel {
                                        text: qsTr("Baudrate")
                                        color: "white"
                                        font.pixelSize: labelPx
                                        font.bold: true
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                    }

                                    QGCComboBox {
                                        sizeToContents: true
                                        id: nmeaBaudCombo
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        Layout.preferredHeight: 35

                                        background: Rectangle {
                                            color: "#1A1A1A"
                                            border.color: "#FFFFFF"
                                            border.width: 1
                                            radius: 4
                                        }

                                        contentItem: Text {
                                            text: nmeaBaudCombo.displayText
                                            color: "white"
                                            font.pixelSize: Math.max(11, root.labelPx)
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 8
                                        }

                                        model: QGroundControl.linkManager.serialBaudRates

                                        onActivated: (index) => {
                                            if (index !== -1) {
                                                var selectedValue = parseInt(nmeaBaudCombo.textAt(index))
                                                QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = selectedValue
                                            }
                                        }

                                        Component.onCompleted: {
                                            var savedValue = QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.valueString
                                            var foundIndex = -1
                                            for (var j = 0; j < nmeaBaudCombo.count; j++) {
                                                if (nmeaBaudCombo.textAt(j) === savedValue) { foundIndex = j; break }
                                            }
                                            if (foundIndex === -1) {
                                                for (var k = 0; k < nmeaBaudCombo.count; k++) {
                                                    if (nmeaBaudCombo.textAt(k) === "57600") { foundIndex = k; break }
                                                }
                                            }
                                            nmeaBaudCombo.currentIndex = foundIndex
                                        }
                                    }
                                }
                            }

                            // UDP PORT
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                radius: 8
                                color: "#2A2A2A"
                                visible: nmeaPortCombo.currentText === "UDP Port"
                                implicitHeight: Math.max(rowMinH, udpGrid.implicitHeight + rowPadY * 2)
                                height: implicitHeight

                                GridLayout {
                                    id: udpGrid
                                    anchors.fill: parent
                                    anchors.leftMargin: rowPadX
                                    anchors.rightMargin: rowPadX
                                    anchors.topMargin: rowPadY
                                    anchors.bottomMargin: rowPadY
                                    columns: root.phone ? 1 : 2
                                    columnSpacing: gap
                                    rowSpacing: 6

                                    QGCLabel {
                                        text: qsTr("UDP Port")
                                        color: "white"
                                        font.pixelSize: labelPx
                                        font.bold: true
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                    }

                                    TextField {
                                        id: udpPortField
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        Layout.preferredHeight: 35

                                        background: Rectangle {
                                            color: "#1A1A1A"
                                            border.color: "#FFFFFF"
                                            border.width: 1
                                            radius: 4
                                        }

                                        color: "white"
                                        font.pixelSize: Math.max(11, root.labelPx)
                                        padding: 8
                                        validator: IntValidator { bottom: 1; top: 65535 }

                                        Component.onCompleted: {
                                            text = QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort.valueString
                                        }

                                        onTextChanged: {
                                            if (text && text !== "" && parseInt(text) > 0) {
                                                QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort.value = parseInt(text)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // -------- LINKS --------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: Math.max(8, gap * 0.75)

                    QGCLabel {
                        text: qsTr("Links")
                        color: "white"
                        font.pixelSize: sectionPx
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        color: "#3D3B3B"
                        radius: 10
                        border.color: "white"
                        border.width: 2

                        implicitHeight: linksContentColumn.implicitHeight + 24
                        height: implicitHeight

                        ColumnLayout {
                            id: linksContentColumn
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            // Repeater onsuz da _linkManager.linkConfigurations modelinin
                            // dəyişikliklərinə avtomatik reaksiya verir; LinkManager-də
                            // linkConfigurationsChanged signal-ı yoxdur, ona görə Connections silindi.

                            Repeater {
                                model: _linkManager.linkConfigurations

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    radius: 8
                                    color: "#2A2A2A"
                                    implicitHeight: Math.max(rowMinH, linkRowGrid.implicitHeight + rowPadY * 2)
                                    height: implicitHeight

                                    // UDP gizlət
                                    visible: !object.name.toLowerCase().includes("udp")

                                    GridLayout {
                                        id: linkRowGrid
                                        anchors.fill: parent
                                        anchors.leftMargin: rowPadX
                                        anchors.rightMargin: rowPadX
                                        anchors.topMargin: rowPadY
                                        anchors.bottomMargin: rowPadY
                                        columns: root.tiny ? 1 : 2
                                        columnSpacing: gap
                                        rowSpacing: 8

                                        // Name
                                        QGCLabel {
                                            text: object.name
                                            color: "white"
                                            font.pixelSize: labelPx
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                        }

                                        // Actions
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                            Layout.alignment: root.tiny ? Qt.AlignLeft : Qt.AlignRight
                                            spacing: 8

                                            // Edit
                                            Rectangle {
                                                width: 30; height: 30
                                                radius: 4
                                                color: "transparent"
                                                border.color: !object.link ? "#4CAF50" : "#666666"
                                                border.width: 1

                                                QGCColoredImage {
                                                    anchors.centerIn: parent
                                                    height: 16; width: 16
                                                    sourceSize.height: height
                                                    fillMode: Image.PreserveAspectFit
                                                    mipmap: true
                                                    smooth: true
                                                    color: !object.link ? "#4CAF50" : "#666666"
                                                    source: "/res/pencil.svg"
                                                }

                                                QGCMouseArea {
                                                    anchors.fill: parent
                                                    enabled: !object.link
                                                    onClicked: {
                                                        var editingConfig = _linkManager.startConfigurationEditing(object)
                                                        linkDialogComponent.createObject(
                                                            mainWindow,
                                                            { editingConfig: editingConfig, originalConfig: object }
                                                        ).open()
                                                    }
                                                }
                                            }

                                            // Delete
                                            Rectangle {
                                                width: 30; height: 30
                                                radius: 4
                                                color: "transparent"
                                                border.color: "#F44336"
                                                border.width: 1

                                                QGCColoredImage {
                                                    anchors.centerIn: parent
                                                    height: 16; width: 16
                                                    sourceSize.height: height
                                                    fillMode: Image.PreserveAspectFit
                                                    mipmap: true
                                                    smooth: true
                                                    color: "#F44336"
                                                    source: "/res/TrashDelete.svg"
                                                }

                                                QGCMouseArea {
                                                    anchors.fill: parent
                                                    onClicked: mainWindow.showMessageDialog(
                                                        qsTr("Linki silin"),
                                                        qsTr("'%1' silmək istədiyinizə əminsiniz?").arg(object.name),
                                                        Dialog.Ok | Dialog.Cancel,
                                                        function () { _linkManager.removeConfiguration(object) }
                                                    )
                                                }
                                            }

                                            // Connect/Disconnect
                                            Rectangle {
                                                width: 125
                                                height: 30
                                                radius: 4
                                                color: object.link ? "#F44336" : "#4CAF50"
                                                border.color: "#FFFFFF"
                                                border.width: 1

                                                QGCLabel {
                                                    anchors.centerIn: parent
                                                    text: object.link ? qsTr("Bağlantını kəsin") : qsTr("Əlaqəni qoşun")
                                                    color: "white"
                                                    font.pixelSize: Math.max(10, root.labelPx - 1)
                                                    font.bold: true
                                                }

                                                QGCMouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        if (object.link) {
                                                            if (_linkManager && typeof _linkManager.disconnectLink === "function") {
                                                                _linkManager.disconnectLink(object.link)
                                                            } else {
                                                                object.link.disconnect()
                                                            }
                                                        } else {
                                                            if (_linkManager && typeof _linkManager.createConnectedLink === "function") {
                                                                _linkManager.createConnectedLink(object)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Add new
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                radius: 8
                                color: "#2A2A2A"
                                implicitHeight: Math.max(rowMinH, addRow.implicitHeight + rowPadY * 2)
                                height: implicitHeight

                                RowLayout {
                                    id: addRow
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    QGCLabel {
                                        text: qsTr("Yeni Link əlavə edin")
                                        Layout.fillWidth: true
                                        color: "white"
                                        font.pixelSize: labelPx
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        width: 80
                                        height: 30
                                        radius: 4
                                        color: "#3D3B3B"
                                        border.color: "#FFFFFF"
                                        border.width: 1

                                        QGCLabel {
                                            anchors.centerIn: parent
                                            text: qsTr("Əlavə et")
                                            color: "white"
                                            font.pixelSize: labelPx
                                            font.bold: true
                                        }

                                        QGCMouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                var editingConfig = _linkManager.createConfiguration(
                                                    ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial
                                                                                 : LinkConfiguration.TypeUdp,
                                                    ""
                                                )
                                                linkDialogComponent.createObject(
                                                    mainWindow,
                                                    { editingConfig: editingConfig, originalConfig: null }
                                                ).open()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { height: sidePad }
        }
    }

    // ================== LINK DIALOG ==================
    Component {
        id: linkDialogComponent

        QGCPopupDialog {
            title:                  originalConfig ? qsTr("Linki Redaktə et") : qsTr("Yeni Link əlavə edin")
            buttons:                Dialog.Save | Dialog.Cancel
            acceptButtonEnabled:    nameField.text !== ""

            property var originalConfig
            property var editingConfig

            onAccepted: {
                linkSettingsLoader.item.saveSettings()
                editingConfig.name = nameField.text

                if (originalConfig) {
                    _linkManager.endConfigurationEditing(originalConfig, editingConfig)
                } else {
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)
                }
            }

            onRejected: {
                _linkManager.cancelConfigurationEditing(editingConfig)
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelWidth

                    QGCLabel { text: qsTr("Ad") }
                    QGCTextField {
                        id: nameField
                        Layout.fillWidth: true
                        text: editingConfig.name
                        placeholderText: qsTr("Ad daxil edin")
                    }
                }

                QGCCheckBoxSlider {
                    Layout.fillWidth: true
                    text: qsTr("Başlanğıcda avtomatik qoşulun")
                    checked: editingConfig.autoConnect
                    onCheckedChanged: editingConfig.autoConnect = checked
                }

                QGCCheckBoxSlider {
                    Layout.fillWidth: true
                    text: qsTr("Yüksək Gecikmə")
                    checked: editingConfig.highLatency
                    onCheckedChanged: editingConfig.highLatency = checked
                }

                LabelledComboBox {
                    label: qsTr("Növ")
                    enabled: originalConfig == null
                    model: _linkManager.linkTypeStrings
                    Component.onCompleted: comboBox.currentIndex = editingConfig.linkType

                    onActivated: (index) => {
                        if (index !== editingConfig.linkType) {
                            var name = nameField.text
                            editingConfig = _linkManager.createConfiguration(index, name)
                        }
                    }
                }

                Loader {
                    id: linkSettingsLoader
                    // settingsURL is a bare filename (e.g. "UdpSettings.qml"). The QML files live in
                    // the QGroundControl.AppSettings module, but Comm_links.qml is in QGroundControl/UI,
                    // so we must build the full qrc URL explicitly — otherwise the relative resolution
                    // looks in UI/ and the load fails silently (empty dialog).
                    source: subEditConfig && subEditConfig.settingsURL
                            ? "qrc:/qml/QGroundControl/AppSettings/" + subEditConfig.settingsURL
                            : ""
                    Layout.fillWidth: true

                    property var subEditConfig: editingConfig
                    property int _firstColumnWidth:  ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth: ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing:        ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing:        ScreenTools.defaultFontPixelWidth / 2
                }
            }
        }
    }
}

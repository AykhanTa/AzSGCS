import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    id: root

    // ---- Data ----
    property var  _settingsManager:          QGroundControl.settingsManager
    property var  _adsbSettings:             _settingsManager.adsbVehicleManagerSettings
    property Fact _adsbServerConnectEnabled: _adsbSettings.adsbServerConnectEnabled

    // ---- Responsive metrics ----
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100

    readonly property real gap:      Math.max(10, ScreenTools.defaultFontPixelHeight * (phone ? 0.6 : 0.8))
    readonly property real cardPad:  Math.max(14, ScreenTools.defaultFontPixelWidth  * 1.2)
    readonly property real rowPadX:  Math.max(12, ScreenTools.defaultFontPixelWidth  * 1.2)
    readonly property real rowPadY:  Math.max(8,  ScreenTools.defaultFontPixelHeight * 0.6)
    readonly property real rowMinH:  Math.max(48, ScreenTools.defaultFontPixelHeight * 2.6)

    readonly property real titlePx: Math.max(18, ScreenTools.defaultFontPixelHeight * (phone ? 1.15 : 1.35))
    readonly property real descPx:  Math.max(12, ScreenTools.defaultFontPixelHeight * (phone ? 0.95 : 1.05))
    readonly property real labelPx: Math.max(11, ScreenTools.defaultFontPixelHeight * (phone ? 0.90 : 0.95))

    // Sətirlərdəki kontrolların sabit eni — bütün textbox-lar eyni ölçüdə və
    // eyni xətt üzrə sağa hizalansın (digər tənzimləmə səhifələri ilə eyni).
    readonly property real ctrlW: Math.max(150, Math.min(260, width * 0.22))

    // ---- Header (sol-yuxarıdan, boşluqsuz) ----
    // Başlıq/alt-başlıq bir Column içində — aralarındakı boşluq digər tənzimləmə
    // səhifələri (Uzaqdan İD) ilə eyni sıxlıqda olsun deyə.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.6)

        Text {
            text: qsTr("ADSB Server")
            color: "white"
            font.pixelSize: 26
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Text {
            text: qsTr("Bu bölmə ADSB server bağlantı parametrlərini idarə etmək üçün istifadə olunur.")
            color: "#E8E8E8"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "white"
        opacity: 0.25
    }

    // ---- Main Card ----
    Rectangle {
        Layout.fillWidth: true
        color: "#3d3b3b"
        radius: 16
        border.color: "white"
        border.width: 2

        implicitHeight: cardLayout.implicitHeight + cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: cardPad
            spacing: gap

            // ========== Enable connect ==========
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: "#2A2A2A"
                visible: _adsbSettings && _adsbSettings.visible && _adsbServerConnectEnabled && _adsbServerConnectEnabled.visible
                implicitHeight: Math.max(rowMinH, enableGrid.implicitHeight + rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: enableGrid
                    anchors.fill: parent
                    anchors.leftMargin: rowPadX
                    anchors.rightMargin: rowPadX
                    anchors.topMargin: rowPadY
                    anchors.bottomMargin: rowPadY
                    columns: phone ? 1 : 2
                    columnSpacing: gap
                    rowSpacing: Math.max(6, gap * 0.4)

                    QGCLabel {
                        text: _adsbServerConnectEnabled ? _adsbServerConnectEnabled.shortDescription : ""
                        color: "white"
                        font.pixelSize: labelPx
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    FactCheckBoxSlider {
                        // label-i biz ayrıca verdik, ona görə boş saxlayırıq
                        text: ""
                        fact: _adsbServerConnectEnabled
                        Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                    }
                }
            }

            // ========== Host address ==========
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: "#2A2A2A"
                visible: _adsbSettings && _adsbSettings.adsbServerHostAddress.visible
                enabled: _adsbServerConnectEnabled ? _adsbServerConnectEnabled.rawValue : false
                implicitHeight: Math.max(rowMinH, hostGrid.implicitHeight + rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: hostGrid
                    anchors.fill: parent
                    anchors.leftMargin: rowPadX
                    anchors.rightMargin: rowPadX
                    anchors.topMargin: rowPadY
                    anchors.bottomMargin: rowPadY
                    columns: phone ? 1 : 2
                    columnSpacing: gap
                    rowSpacing: Math.max(6, gap * 0.4)

                    QGCLabel {
                        text: _adsbSettings.adsbServerHostAddress.shortDescription
                        color: "white"
                        font.pixelSize: labelPx
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    FactTextField {
                        fact: _adsbSettings.adsbServerHostAddress
                        Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                        Layout.fillWidth: root.phone
                        Layout.alignment: Qt.AlignRight
                        Layout.minimumWidth: 0
                    }
                }
            }

            // ========== Port ==========
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: "#2A2A2A"
                visible: _adsbSettings && _adsbSettings.adsbServerPort.visible
                enabled: _adsbServerConnectEnabled ? _adsbServerConnectEnabled.rawValue : false
                implicitHeight: Math.max(rowMinH, portGrid.implicitHeight + rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: portGrid
                    anchors.fill: parent
                    anchors.leftMargin: rowPadX
                    anchors.rightMargin: rowPadX
                    anchors.topMargin: rowPadY
                    anchors.bottomMargin: rowPadY
                    columns: phone ? 1 : 2
                    columnSpacing: gap
                    rowSpacing: Math.max(6, gap * 0.4)

                    QGCLabel {
                        text: _adsbSettings.adsbServerPort.shortDescription
                        color: "white"
                        font.pixelSize: labelPx
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    FactTextField {
                        fact: _adsbSettings.adsbServerPort
                        Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                        Layout.fillWidth: root.phone
                        Layout.alignment: Qt.AlignRight
                        Layout.minimumWidth: 0
                    }
                }
            }
        }
    }
}

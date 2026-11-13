import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

// ADSB server settings, in the new design: the page header of the setup pages, a status card
// with group box rows, and the new fields and switch.
SettingsPage {
    id: root

    // The fields, switch and labels take the new design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ---- Data ----
    property var  _settingsManager:          QGroundControl.settingsManager
    property var  _adsbSettings:             _settingsManager.adsbVehicleManagerSettings
    property Fact _adsbServerConnectEnabled: _adsbSettings.adsbServerConnectEnabled

    // ---- Responsive metrics ----
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100

    readonly property real gap:     AzTheme.px(phone ? 8 : 10)
    readonly property real cardPad: AzTheme.px(16)
    readonly property real rowPadX: AzTheme.px(AzTheme.groupPadding)
    readonly property real rowPadY: AzTheme.px(8)
    readonly property real rowMinH: AzTheme.px(AzTheme.groupRowHeight + 4)

    readonly property real titlePx: AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descPx:  AzTheme.fontPx(13)
    readonly property real labelPx: AzTheme.fontPx(AzTheme.popupTextSize)

    // Sətirlərdəki kontrolların sabit eni — bütün textbox-lar eyni ölçüdə və
    // eyni xətt üzrə sağa hizalansın (digər tənzimləmə səhifələri ilə eyni).
    readonly property real ctrlW: Math.max(150, Math.min(260, width * 0.22))

    // ---- Header ----
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: AzTheme.px(20)
        spacing: AzTheme.px(6)

        Text {
            text: qsTr("ADSB Server")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titlePx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Text {
            text: qsTr("Bu bölmə ADSB server bağlantı parametrlərini idarə etmək üçün istifadə olunur.")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descPx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }

    // ---- Main Card ----
    Rectangle {
        Layout.fillWidth: true
        radius: AzTheme.px(AzTheme.cardRadius)
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }

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
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
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
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
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
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
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

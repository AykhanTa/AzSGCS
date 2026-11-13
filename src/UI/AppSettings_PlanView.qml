
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

// Plan view settings, in the new design: the page header of the setup pages, a status card
// with group box rows, and the new fields and switches.
SettingsPage {
    id: root

    // The fields, switches and labels take the new design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ------------------ Data ------------------
    property var _settingsManager:  QGroundControl.settingsManager
    property var _planViewSettings: QGroundControl.settingsManager.planViewSettings

    // ------------------ Responsive metrics ------------------
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100
    readonly property bool tiny:   width < 560     // ✅ çox dar ekranlarda daha kiçik font

    readonly property real gap:      AzTheme.px(phone ? 8 : 10)
    readonly property real cardPad:  AzTheme.px(16)
    readonly property real rowPadX:  AzTheme.px(AzTheme.groupPadding)
    readonly property real rowPadY:  AzTheme.px(8)
    readonly property real rowMinH:  AzTheme.px(AzTheme.groupRowHeight + 4)

    readonly property real titlePx: AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descPx:  AzTheme.fontPx(13)
    readonly property real labelPx: AzTheme.fontPx(AzTheme.popupTextSize)

    // ================== Header ==================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: AzTheme.px(20)
        spacing: AzTheme.px(6)

        Text {
            text: qsTr("Missiya Parametrləri")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titlePx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Text {
            text: qsTr("Drone'un missiya planlama, uçuş rotası və görev parametrlərinin ayarları")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descPx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }

    // ================== Main Card ==================
    Rectangle {
        id: missionCard
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

            // ---------- Default Mission Altitude ----------
            Rectangle {
                Layout.fillWidth: true
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
                visible: _settingsManager.appSettings.defaultMissionItemAltitude.visible
                implicitHeight: Math.max(rowMinH, altGrid.implicitHeight + rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: altGrid
                    anchors.fill: parent
                    anchors.leftMargin: rowPadX
                    anchors.rightMargin: rowPadX
                    anchors.topMargin: rowPadY
                    anchors.bottomMargin: rowPadY
                    columns: phone ? 1 : 2
                    columnSpacing: gap
                    rowSpacing: Math.max(6, gap * 0.4)

                    QGCLabel {
                        text: qsTr("Defolt Missiya Hündürlüyü")
                        font.pixelSize: labelPx
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    LabelledFactTextField {
                        fact: _settingsManager.appSettings.defaultMissionItemAltitude
                        label: ""
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                    }
                }
            }

            // ---------- VTOL Transition Distance ----------
            Rectangle {
                Layout.fillWidth: true
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
                visible: _planViewSettings.vtolTransitionDistance.visible
                implicitHeight: Math.max(rowMinH, vtolGrid.implicitHeight + rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: vtolGrid
                    anchors.fill: parent
                    anchors.leftMargin: rowPadX
                    anchors.rightMargin: rowPadX
                    anchors.topMargin: rowPadY
                    anchors.bottomMargin: rowPadY
                    columns: phone ? 1 : 2
                    columnSpacing: gap
                    rowSpacing: Math.max(6, gap * 0.4)

                    QGCLabel {
                        text: qsTr("VTOL keçid məsafəsi")
                        font.pixelSize: labelPx
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    LabelledFactTextField {
                        fact: _planViewSettings.vtolTransitionDistance
                        label: ""
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                    }
                }
            }

            // ---------- Use Condition Gate ----------
            Rectangle {
                Layout.fillWidth: true
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
                visible: _planViewSettings.useConditionGate.visible
                implicitHeight: Math.max(rowMinH, gateGrid.implicitHeight + rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: gateGrid
                    anchors.fill: parent
                    anchors.leftMargin: rowPadX
                    anchors.rightMargin: rowPadX
                    anchors.topMargin: rowPadY
                    anchors.bottomMargin: rowPadY
                    columns: phone ? 1 : 2
                    columnSpacing: gap
                    rowSpacing: Math.max(6, gap * 0.4)

                    QGCLabel {
                        text: qsTr("Nümunə yaratmaq üçün MAV_CMD_CONDITION_GATE istifadə edin")
                        font.pixelSize: labelPx
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    FactCheckBoxSlider {
                        fact: _planViewSettings.useConditionGate
                        Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                    }
                }
            }

            // ---------- Takeoff Item Not Required ----------
            Rectangle {
                Layout.fillWidth: true
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
                visible: _planViewSettings.takeoffItemNotRequired.visible
                implicitHeight: Math.max(rowMinH, takeoffGrid.implicitHeight + rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: takeoffGrid
                    anchors.fill: parent
                    anchors.leftMargin: rowPadX
                    anchors.rightMargin: rowPadX
                    anchors.topMargin: rowPadY
                    anchors.bottomMargin: rowPadY
                    columns: phone ? 1 : 2
                    columnSpacing: gap
                    rowSpacing: Math.max(6, gap * 0.4)

                    QGCLabel {
                        text: qsTr("Missiyalar uçuş elementini tələb etmir")
                        font.pixelSize: labelPx
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    FactCheckBoxSlider {
                        fact: _planViewSettings.takeoffItemNotRequired
                        Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                    }
                }
            }

            // ---------- Allow Multiple Landing Patterns ----------
            Rectangle {
                Layout.fillWidth: true
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
                visible: _planViewSettings.allowMultipleLandingPatterns.visible
                implicitHeight: Math.max(rowMinH, landGrid.implicitHeight + rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: landGrid
                    anchors.fill: parent
                    anchors.leftMargin: rowPadX
                    anchors.rightMargin: rowPadX
                    anchors.topMargin: rowPadY
                    anchors.bottomMargin: rowPadY
                    columns: phone ? 1 : 2
                    columnSpacing: gap
                    rowSpacing: Math.max(6, gap * 0.4)

                    QGCLabel {
                        text: qsTr("Çoxlu eniş ardıcıllığını konfiqurasiya etməyə icazə verin")
                        font.pixelSize: labelPx
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    FactCheckBoxSlider {
                        fact: _planViewSettings.allowMultipleLandingPatterns
                        Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                    }
                }
            }
        }
    }
}

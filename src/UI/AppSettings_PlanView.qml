
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    id: root

    // ------------------ Data ------------------
    property var _settingsManager:  QGroundControl.settingsManager
    property var _planViewSettings: QGroundControl.settingsManager.planViewSettings

    // ------------------ Responsive metrics ------------------
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100
    readonly property bool tiny:   width < 560     // ✅ çox dar ekranlarda daha kiçik font

    readonly property real gap:      Math.max(10, ScreenTools.defaultFontPixelHeight * (phone ? 0.6 : 0.85))
    readonly property real cardPad:  Math.max(14, ScreenTools.defaultFontPixelWidth  * 1.2)
    readonly property real rowPadX:  Math.max(12, ScreenTools.defaultFontPixelWidth  * 1.2)
    readonly property real rowPadY:  Math.max(8,  ScreenTools.defaultFontPixelHeight * 0.6)
    readonly property real rowMinH:  Math.max(48, ScreenTools.defaultFontPixelHeight * 2.6)

    readonly property real titlePx: Math.max(18, ScreenTools.defaultFontPixelHeight * (phone ? 1.15 : 1.45))
    readonly property real descPx:  Math.max(12, ScreenTools.defaultFontPixelHeight * (phone ? 0.95 : 1.05))

    // ✅ Burada kiçildirik (label yazıları: “Defolt missiya hündürlüyü”, “VTOL keçid məsafəsi” və s.)
    readonly property real labelPx: Math.max(10,
        ScreenTools.defaultFontPixelHeight * (tiny ? 0.78 : phone ? 0.88 : 1.00)
    )

    // ================== Header ==================
    // Başlıq/alt-başlıq/ayırıcı bir Column içində — aralarındakı boşluq sıx və
    // digər tənzimləmə səhifələri (Uzaqdan İD) ilə eyni olsun deyə.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.6)

        Text {
            text: qsTr("Missiya Parametrləri")
            color: "white"
            font.pixelSize: 26
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Text {
            text: qsTr("Drone'un missiya planlama, uçuş rotası və görev parametrlərinin ayarları")
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

    // ================== Main Card ==================
    Rectangle {
        id: missionCard
        Layout.fillWidth: true
        color: "#3D3B3B"
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

            // ---------- Default Mission Altitude ----------
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: "#2A2A2A"
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
                        color: "white"
                        font.pixelSize: labelPx
                        font.bold: true
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
                radius: 10
                color: "#2A2A2A"
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
                        color: "white"
                        font.pixelSize: labelPx
                        font.bold: true
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
                radius: 10
                color: "#2A2A2A"
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
                        color: "white"
                        font.pixelSize: labelPx
                        font.bold: true
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
                radius: 10
                color: "#2A2A2A"
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
                        color: "white"
                        font.pixelSize: labelPx
                        font.bold: true
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
                radius: 10
                color: "#2A2A2A"
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
                        color: "white"
                        font.pixelSize: labelPx
                        font.bold: true
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

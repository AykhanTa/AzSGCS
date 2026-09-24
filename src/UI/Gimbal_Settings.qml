import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    id: root

    // ---- Data ----
    property var _settingsManager: QGroundControl.settingsManager
    property var _gimbal:          _settingsManager.skydroidGimbalSettings
    property var _ctl:             (typeof skydroidGimbal !== "undefined") ? skydroidGimbal : null

    // ---- Responsive metrics (digər tənzimləmə səhifələri ilə eyni) ----
    readonly property bool phone:  ScreenTools.isMobile || width < 720

    readonly property real gap:     Math.max(10, ScreenTools.defaultFontPixelHeight * (phone ? 0.6 : 0.8))
    readonly property real cardPad: Math.max(14, ScreenTools.defaultFontPixelWidth  * 1.2)
    readonly property real rowPadX: Math.max(12, ScreenTools.defaultFontPixelWidth  * 1.2)
    readonly property real rowPadY: Math.max(8,  ScreenTools.defaultFontPixelHeight * 0.6)
    readonly property real rowMinH: Math.max(48, ScreenTools.defaultFontPixelHeight * 2.6)

    readonly property real labelPx: Math.max(11, ScreenTools.defaultFontPixelHeight * (phone ? 0.90 : 0.95))
    readonly property real ctrlW:   Math.max(150, Math.min(260, width * 0.22))

    // Zavod yer stansiyası pod-u +/-30 ilə tərpədir, əl ilə yoxlama üçün də
    // eynisini istifadə edirik.
    readonly property int  _testSpeed: 30
    readonly property bool _rcOn: _gimbal.enabled.rawValue && _gimbal.rcControlEnabled.rawValue

    // Bu səhifədə 13 eyni quruluşlu sətir var, ona görə sətir qəlibini bir dəfə
    // yazıb təkrar istifadə edirik.
    component BoolRow: Rectangle {
        id: boolRow

        property var  fact:    null
        property bool rowEnabled: true

        Layout.fillWidth: true
        radius: 10
        color: "#2A2A2A"
        visible: fact && fact.visible
        enabled: rowEnabled
        opacity: enabled ? 1.0 : 0.5
        implicitHeight: Math.max(root.rowMinH, boolGrid.implicitHeight + root.rowPadY * 2)
        height: implicitHeight

        GridLayout {
            id: boolGrid
            anchors.fill: parent
            anchors.leftMargin: root.rowPadX
            anchors.rightMargin: root.rowPadX
            anchors.topMargin: root.rowPadY
            anchors.bottomMargin: root.rowPadY
            columns: root.phone ? 1 : 2
            columnSpacing: root.gap
            rowSpacing: Math.max(6, root.gap * 0.4)

            QGCLabel {
                text: boolRow.fact ? boolRow.fact.shortDescription : ""
                color: "white"
                font.pixelSize: root.labelPx
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            FactCheckBoxSlider {
                text: ""
                fact: boolRow.fact
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }
    }

    component FieldRow: Rectangle {
        id: fieldRow

        property var  fact:    null
        property bool rowEnabled: true

        Layout.fillWidth: true
        radius: 10
        color: "#2A2A2A"
        visible: fact && fact.visible
        enabled: rowEnabled
        opacity: enabled ? 1.0 : 0.5
        implicitHeight: Math.max(root.rowMinH, fieldGrid.implicitHeight + root.rowPadY * 2)
        height: implicitHeight

        GridLayout {
            id: fieldGrid
            anchors.fill: parent
            anchors.leftMargin: root.rowPadX
            anchors.rightMargin: root.rowPadX
            anchors.topMargin: root.rowPadY
            anchors.bottomMargin: root.rowPadY
            columns: root.phone ? 1 : 2
            columnSpacing: root.gap
            rowSpacing: Math.max(6, root.gap * 0.4)

            QGCLabel {
                text: fieldRow.fact ? fieldRow.fact.shortDescription : ""
                color: "white"
                font.pixelSize: root.labelPx
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            FactTextField {
                fact: fieldRow.fact
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }
    }

    // ---- Header ----
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.6)

        Text {
            text: qsTr("Gimbal (Skydroid)")
            color: "white"
            font.pixelSize: 26
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Text {
            text: qsTr("Skydroid C01-C14 kameralarını (C13 daxil) hava blokunun şəbəkəsi üzərindən idarə edir. ") +
                  qsTr("Bu, MAVLink gimbal protokolundan ayrı bir yoldur.")
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

    // ---- Bağlantı ----
    Rectangle {
        Layout.fillWidth: true
        color: "#3d3b3b"
        radius: 16
        border.color: "white"
        border.width: 2
        implicitHeight: linkLayout.implicitHeight + root.cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: linkLayout
            anchors.fill: parent
            anchors.margins: root.cardPad
            spacing: root.gap

            QGCLabel {
                text: qsTr("Bağlantı")
                color: "white"
                font.bold: true
                font.pixelSize: root.labelPx * 1.15
            }

            BoolRow  { fact: root._gimbal.enabled }
            FieldRow { fact: root._gimbal.address; rowEnabled: root._gimbal.enabled.rawValue }
            FieldRow { fact: root._gimbal.port;    rowEnabled: root._gimbal.enabled.rawValue }

            // Vəziyyət: istifadəçi uçuşa çıxmadan bağlantının işlədiyini görsün.
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: "#2A2A2A"
                implicitHeight: Math.max(root.rowMinH, statusGrid.implicitHeight + root.rowPadY * 2)
                height: implicitHeight

                GridLayout {
                    id: statusGrid
                    anchors.fill: parent
                    anchors.leftMargin: root.rowPadX
                    anchors.rightMargin: root.rowPadX
                    anchors.topMargin: root.rowPadY
                    anchors.bottomMargin: root.rowPadY
                    columns: root.phone ? 1 : 2
                    columnSpacing: root.gap
                    rowSpacing: Math.max(6, root.gap * 0.4)

                    QGCLabel {
                        text: qsTr("Vəziyyət")
                        color: "white"
                        font.pixelSize: root.labelPx
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    QGCLabel {
                        text: {
                            if (!root._ctl) {
                                return qsTr("mövcud deyil")
                            }
                            if (!root._gimbal.enabled.rawValue) {
                                return qsTr("sönülü")
                            }
                            return (root._ctl.active ? qsTr("cavab verir") : qsTr("cavab yoxdur")) +
                                   "  ·  " + qsTr("göndərilən: ") + root._ctl.sentCount +
                                   "  ·  pitch " + root._ctl.pitchSpeed +
                                   "  yaw " + root._ctl.yawSpeed
                        }
                        color: (root._ctl && root._ctl.active) ? "#00C853" : "#E8E8E8"
                        font.pixelSize: root.labelPx
                        wrapMode: Text.WordWrap
                        Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                        Layout.minimumWidth: 0
                    }
                }
            }
        }
    }

    // ---- RC kanalları ----
    Rectangle {
        Layout.fillWidth: true
        color: "#3d3b3b"
        radius: 16
        border.color: "white"
        border.width: 2
        implicitHeight: rcLayout.implicitHeight + root.cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: rcLayout
            anchors.fill: parent
            anchors.margins: root.cardPad
            spacing: root.gap

            QGCLabel {
                text: qsTr("RC kanalları")
                color: "white"
                font.bold: true
                font.pixelSize: root.labelPx * 1.15
            }

            QGCLabel {
                text: qsTr("Kanal nömrələri 1-dən başlayır; 0 həmin oxu söndürür. Dəyərlər uçuş kontrollerinin göndərdiyi RC_CHANNELS-dən oxunur.")
                color: "#CCCCCC"
                font.pixelSize: root.labelPx * 0.92
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            BoolRow  { fact: root._gimbal.rcControlEnabled; rowEnabled: root._gimbal.enabled.rawValue }
            FieldRow { fact: root._gimbal.pitchChannel;     rowEnabled: root._rcOn }
            FieldRow { fact: root._gimbal.yawChannel;       rowEnabled: root._rcOn }
            FieldRow { fact: root._gimbal.zoomChannel;      rowEnabled: root._rcOn }
            BoolRow  { fact: root._gimbal.pitchReversed;    rowEnabled: root._rcOn }
            BoolRow  { fact: root._gimbal.yawReversed;      rowEnabled: root._rcOn }
        }
    }

    // ---- Tənzimləmə ----
    Rectangle {
        Layout.fillWidth: true
        color: "#3d3b3b"
        radius: 16
        border.color: "white"
        border.width: 2
        implicitHeight: tuneLayout.implicitHeight + root.cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: tuneLayout
            anchors.fill: parent
            anchors.margins: root.cardPad
            spacing: root.gap

            QGCLabel {
                text: qsTr("Tənzimləmə")
                color: "white"
                font.bold: true
                font.pixelSize: root.labelPx * 1.15
            }

            FieldRow { fact: root._gimbal.maxSpeed;   rowEnabled: root._gimbal.enabled.rawValue }
            FieldRow { fact: root._gimbal.rcDeadband; rowEnabled: root._rcOn }
            FieldRow { fact: root._gimbal.rcMin;      rowEnabled: root._rcOn }
            FieldRow { fact: root._gimbal.rcMax;      rowEnabled: root._rcOn }
        }
    }

    // ---- Əl ilə yoxlama ----
    Rectangle {
        Layout.fillWidth: true
        color: "#3d3b3b"
        radius: 16
        border.color: "white"
        border.width: 2
        implicitHeight: testLayout.implicitHeight + root.cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: testLayout
            anchors.fill: parent
            anchors.margins: root.cardPad
            spacing: root.gap

            QGCLabel {
                text: qsTr("Əl ilə yoxlama")
                color: "white"
                font.bold: true
                font.pixelSize: root.labelPx * 1.15
            }

            QGCLabel {
                text: qsTr("Düymə basılı tutulduqca hərəkət davam edir. Buraxanda dayanır.")
                color: "#CCCCCC"
                font.pixelSize: root.labelPx * 0.92
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.phone ? 3 : 6
                columnSpacing: root.gap
                rowSpacing: root.gap
                enabled: root._ctl && root._gimbal.enabled.rawValue

                QGCButton {
                    text: qsTr("Yuxarı")
                    Layout.fillWidth: true
                    onPressed: root._ctl.setPitchSpeed(root._testSpeed)
                    onReleased: root._ctl.stopMotion()
                }
                QGCButton {
                    text: qsTr("Aşağı")
                    Layout.fillWidth: true
                    onPressed: root._ctl.setPitchSpeed(-root._testSpeed)
                    onReleased: root._ctl.stopMotion()
                }
                QGCButton {
                    text: qsTr("Sola")
                    Layout.fillWidth: true
                    onPressed: root._ctl.setYawSpeed(-root._testSpeed)
                    onReleased: root._ctl.stopMotion()
                }
                QGCButton {
                    text: qsTr("Sağa")
                    Layout.fillWidth: true
                    onPressed: root._ctl.setYawSpeed(root._testSpeed)
                    onReleased: root._ctl.stopMotion()
                }
                QGCButton {
                    text: qsTr("Zoom +")
                    Layout.fillWidth: true
                    onPressed: root._ctl.zoomIn()
                    onReleased: root._ctl.zoomStop()
                }
                QGCButton {
                    text: qsTr("Zoom -")
                    Layout.fillWidth: true
                    onPressed: root._ctl.zoomOut()
                    onReleased: root._ctl.zoomStop()
                }
            }
        }
    }
}

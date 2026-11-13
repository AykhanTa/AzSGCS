import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

// Skydroid gimbal settings, in the new design: the page header of the setup pages, status
// cards with group box rows, the design's status colours, and the new fields, switches and
// buttons.
SettingsPage {
    id: root

    // The fields, switches, labels and buttons take the new design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ---- Data ----
    property var _settingsManager: QGroundControl.settingsManager
    property var _gimbal:          _settingsManager.skydroidGimbalSettings
    property var _ctl:             (typeof skydroidGimbal !== "undefined") ? skydroidGimbal : null

    // ---- Responsive metrics (digər tənzimləmə səhifələri ilə eyni) ----
    readonly property bool phone:  ScreenTools.isMobile || width < 720

    readonly property real gap:     AzTheme.px(phone ? 8 : 10)
    readonly property real cardPad: AzTheme.px(16)
    readonly property real rowPadX: AzTheme.px(AzTheme.groupPadding)
    readonly property real rowPadY: AzTheme.px(8)
    readonly property real rowMinH: AzTheme.px(AzTheme.groupRowHeight + 4)

    readonly property real titlePx: AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descPx:  AzTheme.fontPx(13)
    readonly property real labelPx: AzTheme.fontPx(AzTheme.popupTextSize)
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
        radius: AzTheme.px(AzTheme.groupRadius)
        color: AzTheme.groupFill
        border.width: 1
        border.color: AzTheme.groupBorder
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
        radius: AzTheme.px(AzTheme.groupRadius)
        color: AzTheme.groupFill
        border.width: 1
        border.color: AzTheme.groupBorder
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
        Layout.topMargin: AzTheme.px(20)
        spacing: AzTheme.px(6)

        Text {
            text: qsTr("Gimbal (Skydroid)")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titlePx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Text {
            text: qsTr("Skydroid C01-C14 kameralarını (C13 daxil) hava blokunun şəbəkəsi üzərindən idarə edir. ") +
                  qsTr("Bu, MAVLink gimbal protokolundan ayrı bir yoldur.")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descPx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }

    // ---- Bağlantı ----
    Rectangle {
        Layout.fillWidth: true
        radius: AzTheme.px(AzTheme.cardRadius)
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }
        implicitHeight: linkLayout.implicitHeight + root.cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: linkLayout
            anchors.fill: parent
            anchors.margins: root.cardPad
            spacing: root.gap

            Text {
                text: qsTr("Bağlantı")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(16)
            }

            BoolRow  { fact: root._gimbal.enabled }
            FieldRow { fact: root._gimbal.address; rowEnabled: root._gimbal.enabled.rawValue }
            FieldRow { fact: root._gimbal.port;    rowEnabled: root._gimbal.enabled.rawValue }
            FieldRow { fact: root._gimbal.visibleRtspUrl; rowEnabled: root._gimbal.enabled.rawValue }
            FieldRow { fact: root._gimbal.thermalRtspUrl; rowEnabled: root._gimbal.enabled.rawValue }

            // Vəziyyət: istifadəçi uçuşa çıxmadan bağlantının işlədiyini görsün.
            Rectangle {
                Layout.fillWidth: true
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
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
                        color: (root._ctl && root._ctl.active) ? AzTheme.statusGreen : AzTheme.textCard
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
        radius: AzTheme.px(AzTheme.cardRadius)
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }
        implicitHeight: rcLayout.implicitHeight + root.cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: rcLayout
            anchors.fill: parent
            anchors.margins: root.cardPad
            spacing: root.gap

            Text {
                text: qsTr("RC kanalları")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(16)
            }

            QGCLabel {
                text: qsTr("Kanal nömrələri 1-dən başlayır; 0 həmin oxu söndürür. Dəyərlər uçuş kontrollerinin göndərdiyi RC_CHANNELS-dən oxunur.")
                color: AzTheme.textSecondary
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

            // Canlı RC dəyərləri. Əl ilə yoxlama düymələri işləyib RC işləmirsə,
            // problemin harada olduğunu yalnız bu göstərir: dəyərlər ümumiyyətlən
            // gəlmir, yoxsa gəlir amma ölü zonadan çıxmır.
            Rectangle {
                Layout.fillWidth: true
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder
                implicitHeight: rcLiveCol.implicitHeight + root.gap * 1.6

                ColumnLayout {
                    id: rcLiveCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: root.gap
                    anchors.rightMargin: root.gap
                    spacing: root.gap * 0.5

                    QGCLabel {
                        text: qsTr("Canlı RC")
                        font.weight: Font.Medium
                        font.pixelSize: root.labelPx
                    }

                    // Kanalların haradan gəldiyi: pultun özü (Skydroid SDK) və ya
                    // uçuş kontrollerinin RC_CHANNELS mesajı. Pult oxunursa o üstündür.
                    QGCLabel {
                        visible: !!root._ctl
                        text: {
                            if (!root._ctl) {
                                return ""
                            }
                            switch (root._ctl.rcSource) {
                            case 2:  return qsTr("Mənbə: pultun özü (Skydroid SDK)")
                            case 1:  return qsTr("Mənbə: uçuş kontrolleri (RC_CHANNELS)")
                            default: return qsTr("Mənbə: yoxdur")
                            }
                        }
                        color: (root._ctl && root._ctl.rcSource !== 0) ? AzTheme.statusGreen : AzTheme.statusRed
                        font.pixelSize: root.labelPx * 0.92
                        font.bold: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    QGCLabel {
                        visible: !!root._ctl && (root._ctl.rcInputState !== -1)
                        text: {
                            if (!root._ctl) {
                                return ""
                            }
                            switch (root._ctl.rcInputState) {
                            case 0:  return qsTr("Pult: oxunmur — gimbal və ya RC idarəsi söndürülüb.")
                            case 1:  return qsTr("Pult: qoşulur…")
                            case 2:  return qsTr("Pult: qoşuludur.")
                            case 3:  return qsTr("Pult: qoşulmaq alınmadı (%1). Skydroid köməkçi tətbiqi açıqdırsa, bağlayın — hər 5 saniyədən bir yenidən cəhd edilir.").arg(root._ctl.rcInputMessage)
                            default: return ""
                            }
                        }
                        color: (root._ctl && root._ctl.rcInputState === 2) ? AzTheme.textCard
                             : (root._ctl && root._ctl.rcInputState === 3) ? AzTheme.statusOrange : AzTheme.textSecondary
                        font.pixelSize: root.labelPx * 0.85
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    QGCLabel {
                        text: {
                            if (!root._ctl) {
                                return qsTr("idarəedici mövcud deyil")
                            }
                            if (!root._ctl.rcConnected) {
                                return qsTr("Kanal mənbəyi yoxdur: pult oxunmur və uçuş kontrolleri qoşulu deyil.")
                            }
                            if (root._ctl.rcUpdateCount === 0) {
                                return qsTr("Mənbə var, amma hələ bir dənə də kanal paketi gəlməyib.")
                            }
                            return qsTr("kanal sayı: ") + root._ctl.rcChannelCount +
                                   "  ·  pitch " + root._ctl.rcPitchPwm +
                                   "  ·  yaw " + root._ctl.rcYawPwm +
                                   "  ·  zoom " + root._ctl.rcZoomPwm +
                                   "\n" + qsTr("hesablanan sürət:") +
                                   "  pitch " + root._ctl.pitchSpeed +
                                   "  ·  yaw " + root._ctl.yawSpeed +
                                   "  ·  zoom " + root._ctl.zoomDirection +
                                   "  ·  " + qsTr("paket: ") + root._ctl.rcUpdateCount
                        }
                        color: {
                            if (!root._ctl || !root._ctl.rcConnected) return AzTheme.statusRed
                            return (root._ctl.rcSource !== 0) ? AzTheme.statusGreen : AzTheme.textCard
                        }
                        font.pixelSize: root.labelPx * 0.92
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    // Bütün kanallar: hansı düymənin hansı kanalı tərpətdiyini burada
                    // görüb yuxarıdakı kanal nömrələrini ona görə təyin etmək olur.
                    QGCLabel {
                        visible: !!root._ctl && (root._ctl.rcChannels.length > 0)
                        text: {
                            if (!root._ctl) {
                                return ""
                            }
                            var channels = root._ctl.rcChannels
                            var parts = []
                            for (var i = 0; i < channels.length; i++) {
                                parts.push("CH" + (i + 1) + " " + channels[i])
                            }
                            return qsTr("Bütün kanallar: ") + parts.join("  ·  ")
                        }
                        color: AzTheme.textCard
                        font.pixelSize: root.labelPx * 0.85
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    QGCLabel {
                        text: qsTr("-1 = həmin kanal gəlmir. Dəyərlər dəyişir, amma sürət 0 qalırsa, ölü zonanı azaldın və ya kanal aralığını yoxlayın.")
                        color: AzTheme.textSecondary
                        font.pixelSize: root.labelPx * 0.85
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }
                }
            }
        }
    }

    // ---- Tənzimləmə ----
    Rectangle {
        Layout.fillWidth: true
        radius: AzTheme.px(AzTheme.cardRadius)
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }
        implicitHeight: tuneLayout.implicitHeight + root.cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: tuneLayout
            anchors.fill: parent
            anchors.margins: root.cardPad
            spacing: root.gap

            Text {
                text: qsTr("Tənzimləmə")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(16)
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
        radius: AzTheme.px(AzTheme.cardRadius)
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }
        implicitHeight: testLayout.implicitHeight + root.cardPad * 2
        height: implicitHeight

        ColumnLayout {
            id: testLayout
            anchors.fill: parent
            anchors.margins: root.cardPad
            spacing: root.gap

            Text {
                text: qsTr("Əl ilə yoxlama")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(16)
            }

            QGCLabel {
                text: qsTr("Düymə basılı tutulduqca hərəkət davam edir. Buraxanda dayanır.")
                color: AzTheme.textSecondary
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

            QGCLabel {
                text: qsTr("Montaj rejimi")
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(14)
                Layout.topMargin: root.gap * 0.5
            }

            // Əvvəlki versiyada zoom əmri əslində bu rejimi dəyişən əmr idi, ona
            // görə gimbal səhv rejimdə qalmış ola bilər. Bərpa yolu buradır.
            QGCLabel {
                text: qsTr("Pod-un necə quraşdırıldığını bildirir. Əvvəlki versiyada zoom düymələri bu rejimi səhvən dəyişirdi: gimbal tərs dönürsə və ya qəribə hərəkət edirsə, burada düzgün rejimi seçin. Dronun altından asılan pod üçün \"Asılı\" seçilir.")
                color: AzTheme.textSecondary
                font.pixelSize: root.labelPx * 0.92
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.gap
                enabled: root._ctl && root._gimbal.enabled.rawValue

                QGCButton {
                    text: qsTr("Asılı (normal)")
                    Layout.fillWidth: true
                    onClicked: root._ctl.setMountHanging()
                }
                QGCButton {
                    text: qsTr("Tərs (üstdə)")
                    Layout.fillWidth: true
                    onClicked: root._ctl.setMountInverted()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

// Radio calibration, in the new design: the vehicle setup page header, status cards
// for the sticks, transmitter mode, channel monitor and extra setup, with group box
// rows inside them.
Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"
    clip: true

    // The labels, radio buttons, combo boxes and buttons take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ✅ Outer scroll-un əsas səbəbi sabit implicitHeight idi.
    // Loader/Flickable parent implicitHeight-ə görə contentHeight hesablayanda scroll çıxırdı.
    implicitWidth:  width
    implicitHeight: height

    // =========================================================
    // ✅ ANDROID FIX: Heç bir şəkil "file:///C:..." olmamalıdır
    // =========================================================
    readonly property string _azIconBase:   "qrc:/res/AZSHIELD_ICON/"
    readonly property string _calibBaseQrc: "qrc:/qml/QGroundControl/AutoPilotPlugins/Common/calibration/"

    // Fallback (qrc) — Android-də 100% işləyəcək
    readonly property string fallbackImagePath: _azIconBase + "joystick.svg"

    // Compact (kiçik pəncərə) rejimi: elementlər qarışmasın deyə stack + scroll
    readonly property bool compact: (ScreenTools.isMobile || width < 1200 || height < 760)

    // responsive ölçülər
    readonly property bool phone:  ScreenTools.isMobile || width < 700
    readonly property bool tablet: !phone && width < 1100

    readonly property real sidePadding: AzTheme.px(phone ? 12 : 20)
    readonly property real gap:         AzTheme.px(phone ? 10 : 16)
    readonly property real innerPad:    AzTheme.px(phone ? 12 : 16)
    readonly property real topPad:      AzTheme.px(20)

    readonly property real h1Px:    AzTheme.fontPx(compact ? 18 : 20)
    readonly property real subPx:   AzTheme.fontPx(13)
    readonly property real titlePx: AzTheme.fontPx(16)
    readonly property real textPx:  AzTheme.fontPx(AzTheme.popupTextSize)

    // ✅ Dropdown (ComboBox popup) çox böyük olmasın deyə ölçülər
    // - popup max height məhdud olur (scroll avtomatik işləyir)
    // - item hündürlüyü + font kiçilir
    readonly property real _comboPopupMaxH:   Math.min(260, Math.max(180, height * 0.35))
    readonly property int  _comboPopupFontPx: Math.max(11, Math.round(textPx - 2))
    readonly property real _comboPopupItemH:  Math.max(28, _comboPopupFontPx * 2.0)

    readonly property real rowMinH:     AzTheme.px(AzTheme.groupRowHeight)
    readonly property real channelRowH: AzTheme.px(28)
    readonly property real labelW:      phone ? 90 : 120

    // sağ sütun en limiti (Rejim seçimi çox enli olmasın)
    readonly property real rightColW: phone ? (width - 2*sidePadding) : Math.min(520, Math.max(460, (width - 2*sidePadding) * 0.34))

    // monitor ölçüləri
    readonly property real helpImageH: Math.max(120, Math.min(160, height * 0.16))
    readonly property real rcMonitorH: Math.max(220, Math.min(360, height * 0.30))

    // --- view references (controller signals üçün) ---
    property var _rollLoader
    property var _pitchLoader
    property var _yawLoader
    property var _throttleLoader

    property var _skipButton
    property var _cancelButton
    property var _nextButton
    property var _statusText

    // ===== RC input watchdog (siqnal yoxdursa placeholder göstər) =====
    property double _lastRcUpdateMs: 0
    property bool   rcSignalPresent: false

    function _markRcSignal() {
        _lastRcUpdateMs = Date.now()
    }

    Timer {
        id: rcWatchdog
        interval: 600
        repeat: true
        running: true
        onTriggered: {
            // 2 saniyədən çox siqnal gəlmirsə -> disconnected kimi qəbul et
            root.rcSignalPresent = (root._lastRcUpdateMs > 0) && ((Date.now() - root._lastRcUpdateMs) < 2000)
        }
    }

    // Placeholder şərti
    readonly property bool showNoRcHint: !QGroundControl.multiVehicleManager.activeVehicle || !rcSignalPresent

    function _wireView(v) {
        _rollLoader     = v ? v.rollLoader     : null
        _pitchLoader    = v ? v.pitchLoader    : null
        _yawLoader      = v ? v.yawLoader      : null
        _throttleLoader = v ? v.throttleLoader : null

        _skipButton   = v ? v.skipButton   : null
        _cancelButton = v ? v.cancelButton : null
        _nextButton   = v ? v.nextButton   : null
        _statusText   = v ? v.statusText   : null

        controller.skipButton   = _skipButton
        controller.cancelButton = _cancelButton
        controller.nextButton   = _nextButton
        controller.statusText   = _statusText

        Qt.callLater(setupPageCompleted)
    }

    function setupPageCompleted() {
        if (!QGroundControl.multiVehicleManager.activeVehicle) return
        controller.start()
    }

    // =========================================================
    // ✅ ANDROID FIX: Help image həmişə qrc-dən gəlsin
    // controller.imageHelp müxtəlif formatlarda gələ bilər:
    //  - artıq qrc:/... (OK)
    //  - "radioCenter.png" (sadə ad)
    //  - "mode1/radioCenter.png" və ya "mode2/..."
    //  - "...calibration/mode2/radioCenter.png" kimi uzun yol
    // Hepsini qrc base-ə map edirik.
    // =========================================================
    function resolveHelpImage() {
        var img = controller.imageHelp || ""
        if (img === "") return ""

        // artıq qrc-dirsə saxla
        if (img.indexOf("qrc:") === 0) return img

        // normalizasiya
        img = img.replace(/\\/g, "/")

        // bəzən "/qml/..." kimi gələ bilər
        if (img.indexOf("/qml/") === 0) {
            return "qrc:" + img
        }

        // "calibration/..." alt hissəsini tap
        var idx = img.indexOf("calibration/")
        if (idx >= 0) {
            // məsələn: "calibration/mode2/radioCenter.png" -> "mode2/radioCenter.png"
            var sub = img.substring(idx + "calibration/".length)
            return _calibBaseQrc + sub
        }

        // "mode1/..." və ya "mode2/..."
        if (img.indexOf("mode1/") === 0 || img.indexOf("mode2/") === 0) {
            return _calibBaseQrc + img
        }

        // təkcə fayl adı gəlibsə — transmitterMode-a görə seç
        var modeFolder = (controller.transmitterMode === 1) ? "mode1/" : "mode2/"
        return _calibBaseQrc + modeFolder + img
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    // ===================== Controller =====================
    RadioComponentController {
        id: controller

        onRollChannelRCValueChanged: {
            root._markRcSignal()
            if (root._rollLoader && root._rollLoader.item)
                root._rollLoader.item.rcValue = rcValue
        }
        onRollChannelMappedChanged:    if (root._rollLoader && root._rollLoader.item) root._rollLoader.item.mapped   = rollChannelMapped
        onRollChannelReversedChanged:  if (root._rollLoader && root._rollLoader.item) root._rollLoader.item.reversed = rollChannelReversed

        onPitchChannelRCValueChanged: {
            root._markRcSignal()
            if (root._pitchLoader && root._pitchLoader.item)
                root._pitchLoader.item.rcValue = rcValue
        }
        onPitchChannelMappedChanged:   if (root._pitchLoader && root._pitchLoader.item) root._pitchLoader.item.mapped   = pitchChannelMapped
        onPitchChannelReversedChanged: if (root._pitchLoader && root._pitchLoader.item) root._pitchLoader.item.reversed = pitchChannelReversed

        onYawChannelRCValueChanged: {
            root._markRcSignal()
            if (root._yawLoader && root._yawLoader.item)
                root._yawLoader.item.rcValue = rcValue
        }
        onYawChannelMappedChanged:     if (root._yawLoader && root._yawLoader.item) root._yawLoader.item.mapped   = yawChannelMapped
        onYawChannelReversedChanged:   if (root._yawLoader && root._yawLoader.item) root._yawLoader.item.reversed = yawChannelReversed

        onThrottleChannelRCValueChanged: {
            root._markRcSignal()
            if (root._throttleLoader && root._throttleLoader.item)
                root._throttleLoader.item.rcValue = rcValue
        }
        onThrottleChannelMappedChanged:   if (root._throttleLoader && root._throttleLoader.item) root._throttleLoader.item.mapped   = throttleChannelMapped
        onThrottleChannelReversedChanged: if (root._throttleLoader && root._throttleLoader.item) root._throttleLoader.item.reversed = throttleChannelReversed
    }

    // ===================== Spektrum bind dialog =====================
    Component {
        id: spektrumBindDialogComponent
        QGCPopupDialog {
            title: qsTr("Spektrum bağlaması")
            buttons: Dialog.Ok | Dialog.Cancel
            onAccepted: controller.spektrumBindMode(radioGroup.checkedButton.bindMode)

            ButtonGroup { id: radioGroup }
            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2
                QGCLabel { wrapMode: Text.WordWrap; text: qsTr("Spektrum qəbuledicinizi bağlama rejimində yerləşdirmək üçün Ok düyməsini klikləyin.") }
                QGCLabel { wrapMode: Text.WordWrap; text: qsTr("Aşağıda xüsusi qəbuledici növünü seçin:") }
                QGCRadioButton { text: qsTr("DSM2 rejimi"); ButtonGroup.group: radioGroup; property int bindMode: RadioComponentController.DSM2 }
                QGCRadioButton { text: qsTr("DSMX (7 kanal və ya daha az)"); ButtonGroup.group: radioGroup; property int bindMode: RadioComponentController.DSMX7 }
                QGCRadioButton { checked: true; text: qsTr("DSMX (8 kanal və ya daha çox)"); ButtonGroup.group: radioGroup; property int bindMode: RadioComponentController.DSMX8 }
            }
        }
    }

    // ===================== Channel mini bar component =====================
    Component {
        id: channelMonitorDisplayComponent
        Item {
            implicitHeight: root.channelRowH
            property int  rcValue: 1500
            property bool mapped: false
            property bool reversed: false

            property int __lastRcValue: 1500
            readonly property int __rcValueMaxJitter: 2
            property color __barColor: AzTheme.slotEmpty

            readonly property int _pwmMin: 800
            readonly property int _pwmMax: 2200
            readonly property int _pwmRange: _pwmMax - _pwmMin

            Rectangle {
                id: bar
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: AzTheme.px(8)
                radius: height / 2
                color: __barColor
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 2
                height: parent.height * 0.7
                anchors.verticalCenter: parent.verticalCenter
                color: AzTheme.cardHoverBorder
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: AzTheme.px(14)
                height: width
                radius: width/2
                color: mapped ? AzTheme.textPrimary : "transparent"
                border.color: mapped ? AzTheme.statusGreen : AzTheme.cardHoverBorder
                border.width: mapped ? 2 : 1
                x: {
                    if (!mapped) return parent.width/2 - width/2
                    var normalized = (reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange
                    return Math.max(0, Math.min(parent.width - width, normalized * (parent.width - width)))
                }
            }

            ColorAnimation {
                id: barAnim
                target: bar
                property: "color"
                from: AzTheme.statusYellow
                to: __barColor
                duration: 1500
            }

            onRcValueChanged: {
                if (Math.abs(rcValue - __lastRcValue) > __rcValueMaxJitter) {
                    __lastRcValue = rcValue
                    barAnim.start()
                }
            }
        }
    }

    // ===================== View switcher =====================
    Loader {
        id: viewLoader
        anchors.fill: parent
        sourceComponent: root.compact ? compactViewComponent : desktopViewComponent
        onLoaded: root._wireView(item)
    }

    onCompactChanged: viewLoader.sourceComponent = root.compact ? compactViewComponent : desktopViewComponent

    // ===================== DESKTOP VIEW (YUXARI BOŞLUQ YOX, OUTER SCROLL YOX) =====================
    Component {
        id: desktopViewComponent

        Item {
            id: desktop
            anchors.fill: parent

            implicitHeight: root.height
            implicitWidth:  root.width

            property alias rollLoader: rollLoader
            property alias pitchLoader: pitchLoader
            property alias yawLoader: yawLoader
            property alias throttleLoader: throttleLoader

            property alias skipButton: skipButton
            property alias cancelButton: cancelButton
            property alias nextButton: nextButton
            property alias statusText: statusText

            // Header
            Text {
                id: title
                x: root.sidePadding
                y: root.topPad
                text: qsTr("Radio Konfiqurasiyası")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: root.h1Px
            }

            Text {
                id: subtitle
                x: root.sidePadding
                y: title.y + title.implicitHeight + AzTheme.px(6)
                text: qsTr("RC ötürücü kanallarınızı və parametrlərinizi konfiqurasiya edin")
                color: AzTheme.textSecondary
                font.family: AzTheme.fontFamily
                font.pixelSize: root.subPx
            }

            readonly property real topY: subtitle.y + subtitle.implicitHeight + root.gap
            readonly property real m: root.sidePadding
            readonly property real g: root.gap
            readonly property real rightW: root.rightColW
            readonly property real leftW: Math.max(560, root.width - (m*2 + g + rightW))

            // LEFT: Attitude
            Rectangle {
                id: attitudePanel
                x: desktop.m
                y: desktop.topY
                width: desktop.leftW
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                implicitHeight: attCol.implicitHeight + root.innerPad * 2

                ColumnLayout {
                    id: attCol
                    anchors.fill: parent
                    anchors.margins: root.innerPad
                    spacing: Math.max(12, ScreenTools.defaultFontPixelHeight * 0.8)

                    Text {
                        text: qsTr("Münasibətə Nəzarətlər")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: root.titlePx
                    }

                    // Roll
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        implicitHeight: Math.max(root.rowMinH, root.channelRowH + 2*8)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                            anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                            spacing: root.gap
                            Text { text: qsTr("Roll"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.pixelSize: root.textPx; Layout.preferredWidth: root.labelW; Layout.minimumWidth: root.labelW }
                            Loader {
                                id: rollLoader
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.channelRowH
                                sourceComponent: channelMonitorDisplayComponent
                                onLoaded: { item.mapped = controller.rollChannelMapped; item.reversed = controller.rollChannelReversed }
                            }
                        }
                    }

                    // Pitch
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        implicitHeight: Math.max(root.rowMinH, root.channelRowH + 2*8)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                            anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                            spacing: root.gap
                            Text { text: qsTr("Pitch"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.pixelSize: root.textPx; Layout.preferredWidth: root.labelW; Layout.minimumWidth: root.labelW }
                            Loader {
                                id: pitchLoader
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.channelRowH
                                sourceComponent: channelMonitorDisplayComponent
                                onLoaded: { item.mapped = controller.pitchChannelMapped; item.reversed = controller.pitchChannelReversed }
                            }
                        }
                    }

                    // Yaw
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        implicitHeight: Math.max(root.rowMinH, root.channelRowH + 2*8)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                            anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                            spacing: root.gap
                            Text { text: qsTr("Yaw"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.pixelSize: root.textPx; Layout.preferredWidth: root.labelW; Layout.minimumWidth: root.labelW }
                            Loader {
                                id: yawLoader
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.channelRowH
                                sourceComponent: channelMonitorDisplayComponent
                                onLoaded: { item.mapped = controller.yawChannelMapped; item.reversed = controller.yawChannelReversed }
                            }
                        }
                    }

                    // Throttle
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        implicitHeight: Math.max(root.rowMinH, root.channelRowH + 2*8)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                            anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                            spacing: root.gap
                            Text { text: qsTr("Throttle"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.pixelSize: root.textPx; Layout.preferredWidth: root.labelW; Layout.minimumWidth: root.labelW }
                            Loader {
                                id: throttleLoader
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.channelRowH
                                sourceComponent: channelMonitorDisplayComponent
                                onLoaded: { item.mapped = controller.throttleChannelMapped; item.reversed = controller.throttleChannelReversed }
                            }
                        }
                    }
                }
            }

            // Buttons
            Row {
                id: buttonRow
                x: attitudePanel.x
                y: attitudePanel.y + attitudePanel.height + root.gap
                spacing: root.gap

                QGCButton { id: skipButton;   width: AzTheme.px(196); height: AzTheme.px(40); text: qsTr("Keç");     onClicked: controller.skipButtonClicked() }
                QGCButton { id: cancelButton; width: AzTheme.px(196); height: AzTheme.px(40); text: qsTr("Ləğv et"); onClicked: controller.cancelButtonClicked() }
                QGCButton { id: nextButton;   width: AzTheme.px(196); height: AzTheme.px(40); primary: true; text: controller.calibrateText; onClicked: controller.nextButtonClicked() }
            }

            // Status (boşdursa yer tutmasın)
            QGCLabel {
                id: statusText
                x: attitudePanel.x
                y: buttonRow.y + buttonRow.height + ((text && text.length > 0) ? 8 : 0)
                width: attitudePanel.width
                wrapMode: Text.WordWrap
                color: AzTheme.textCard
                font.pixelSize: root.textPx
                verticalAlignment: Text.AlignVCenter
                height: (text && text.length > 0) ? implicitHeight : 0
                visible: height > 0
            }

            // RIGHT: Mode
            Rectangle {
                id: modePanel
                x: attitudePanel.x + attitudePanel.width + root.gap
                y: attitudePanel.y
                width: desktop.rightW
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                implicitHeight: modeCol.implicitHeight + root.innerPad * 2

                ColumnLayout {
                    id: modeCol
                    anchors.fill: parent
                    anchors.margins: root.innerPad
                    spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                    Text { text: qsTr("Transmitter rejimi"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: root.titlePx }

                    ButtonGroup { id: modeGroup }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.gap
                        QGCRadioButton { text: qsTr("Rejim 1"); checked: controller.transmitterMode == 1; ButtonGroup.group: modeGroup; onClicked: controller.transmitterMode = 1; Layout.fillWidth: true }
                        QGCRadioButton { text: qsTr("Rejim 2"); checked: controller.transmitterMode == 2; ButtonGroup.group: modeGroup; onClicked: controller.transmitterMode = 2; Layout.fillWidth: true }
                    }
                }
            }

            // RIGHT: Monitor
            Rectangle {
                id: monitorPanel
                x: modePanel.x
                y: modePanel.y + modePanel.height + root.gap
                width: modePanel.width
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                implicitHeight: monCol.implicitHeight + root.innerPad * 2

                ColumnLayout {
                    id: monCol
                    anchors.fill: parent
                    anchors.margins: root.innerPad
                    spacing: root.gap

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.helpImageH
                        color: "transparent"

                        Image {
                            id: helpImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            cache: false
                            source: root.resolveHelpImage()
                            onStatusChanged: if (status === Image.Error) console.log("Calibration image not found:", source)
                        }

                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: root.fallbackImagePath
                            visible: (helpImage.source === "") || (helpImage.status === Image.Error)
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 100
                            height: 30
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            radius: AzTheme.px(AzTheme.groupRadius)
                            visible: helpImage.status === Image.Loading
                            Text { anchors.centerIn: parent; text: qsTr("Yüklənir..."); color: AzTheme.textSecondary; font.family: AzTheme.fontFamily; font.pixelSize: AzTheme.fontPx(12) }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.rcMonitorH
                        clip: true

                        // Monitor bütün kanallar üçün öz hündürlüyünü alır; kart sabit hündürlükdədir,
                        // ona görə sığmayan kanallar kəsilməsin deyə burada scroll olunur. Hamısı
                        // sığanda interactive söndürülür ki, sürüşdürmə səhifənin özünə getsin.
                        QGCFlickable {
                            anchors.fill:       parent
                            contentWidth:       width
                            contentHeight:      rcMonitorWide.height
                            flickableDirection: Flickable.VerticalFlick
                            interactive:        contentHeight > height

                            RCChannelMonitor {
                                id:         rcMonitorWide
                                width:      parent.width
                                twoColumn:  true
                            }
                        }

                        // Placeholder overlay
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            visible: root.showNoRcHint

                            Column {
                                anchors.centerIn: parent
                                width: parent.width * 0.86
                                spacing: 6

                                QGCLabel {
                                    width: parent.width
                                    text: qsTr("RC siqnalı aşkar edilmədi")
                                    color: AzTheme.textCard
                                    font.pixelSize: root.textPx
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }

                                QGCLabel {
                                    width: parent.width
                                    text: qsTr("Radio qəbuledicisini qoşun və çubuqları hərəkət etdirin. Siqnal gəldikdə kanallar burada görünəcək.")
                                    color: AzTheme.textSecondary
                                    font.pixelSize: root.textPx
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            // EXTRA PANEL (kontentə görə hündürlük + outer scroll yaratmasın)
            Rectangle {
                id: extraPanel
                x: attitudePanel.x
                y: statusText.y + statusText.height + root.gap
                width: attitudePanel.width

                readonly property real bottomLimit: (root.height - desktop.m)
                readonly property real maxPanelH: Math.max(220, Math.floor(bottomLimit - y) - 1)

                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                implicitHeight: extraCol.implicitHeight + root.innerPad * 2
                height: Math.min(implicitHeight, maxPanelH)

                ColumnLayout {
                    id: extraCol
                    anchors.fill: parent
                    anchors.margins: root.innerPad
                    spacing: root.gap

                    Text {
                        id: extraTitle
                        text: qsTr("Əlavə Radio quraşdırma:")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: root.titlePx
                    }

                    // kontent azdırsa panel kiçilir, çoxdursa içi scroll olur
                    QGCFlickable {
                        id: paramsFlick
                        Layout.fillWidth: true

                        readonly property real freeH: Math.max(120,
                            extraPanel.height
                            - extraTitle.implicitHeight
                            - actionsFlow.implicitHeight
                            - (root.gap * 3)
                        )

                        Layout.preferredHeight: Math.min(paramsGrid.implicitHeight, freeH)

                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        contentWidth: width
                        contentHeight: paramsGrid.implicitHeight
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        GridLayout {
                            id: paramsGrid
                            width: parent.width
                            columns: 1
                            rowSpacing: 12
                            columnSpacing: root.gap

                            Repeater {
                                model: QGroundControl.multiVehicleManager.activeVehicle && QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ?
                                           (QGroundControl.multiVehicleManager.activeVehicle.multiRotor ?
                                                [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"] :
                                                [ "RC_MAP_FLAPS", "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"]) :
                                           [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3" ]

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    radius: AzTheme.px(AzTheme.groupRadius)
                                    color: AzTheme.groupFill
                                    border.width: 1
                                    border.color: AzTheme.groupBorder
                                    implicitHeight: AzTheme.px(AzTheme.groupRowHeight)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: root.gap

                                        QGCLabel {
                                            text: controller.getParameterFact(-1, modelData).shortDescription
                                            color: AzTheme.textCard
                                            font.pixelSize: root.textPx
                                            Layout.fillWidth: true
                                        }

                                        FactComboBox {
                                            id: extraParamCombo
                                            fact: controller.getParameterFact(-1, modelData)
                                            indexModel: false
                                            Layout.minimumWidth: 220
                                            Layout.preferredWidth: 280

                                            // ✅ Popup ölçülərini kiçilt (hündürlük + item hündürlüyü)

                                            // ✅ Popup ağdırsa — yazı qara olsun (görünsün)

                                        }
                                    }
                                }
                            }
                        }
                    }

                    Flow {
                        id: actionsFlow
                        Layout.fillWidth: true
                        spacing: root.gap

                        QGCButton {
                            width: AzTheme.px(190); height: AzTheme.px(40)
                            primary: true
                            text: qsTr("Spektrum bağlama")
                            onClicked: spektrumBindDialogComponent.createObject(mainWindow).open()
                        }
                        QGCButton {
                            width: AzTheme.px(190); height: AzTheme.px(40)
                            primary: true
                            text: qsTr("CRSF Bağlaması")
                            onClicked: mainWindow.showMessageDialog(
                                           qsTr("CRSF Bağlaması"),
                                           qsTr("CRSF qəbuledicinizi bağlama rejimində yerləşdirmək üçün Ok düyməsini klikləyin."),
                                           Dialog.Ok | Dialog.Cancel,
                                           function(accepted) { if (accepted) controller.crsfBindMode() }
                                       )
                        }
                        QGCButton {
                            width: AzTheme.px(220); height: AzTheme.px(40)
                            primary: true
                            text: qsTr("Kəsmələri kopyalayın")
                            onClicked: mainWindow.showMessageDialog(
                                           qsTr("Kəsmələri kopyalayın"),
                                           qsTr("Çubuqlarınızı mərkəzləşdirin və tənzimləyicini tam aşağı hərəkət etdirin, sonra trimləri kopyalamaq üçün Ok düyməsini basın. Ok düyməsini basdıqdan sonra radionuzdakı trimləri sıfıra qaytarın."),
                                           Dialog.Ok | Dialog.Cancel,
                                           function(accepted) { if (accepted) controller.copyTrims() }
                                       )
                        }
                    }
                }
            }
        }
    }

    // ===================== COMPACT VIEW (stack + scroll, qarışmır) =====================
    Component {
        id: compactViewComponent

        Item {
            id: compactV
            anchors.fill: parent

            implicitHeight: root.height
            implicitWidth:  root.width

            property alias rollLoader: rollLoader
            property alias pitchLoader: pitchLoader
            property alias yawLoader: yawLoader
            property alias throttleLoader: throttleLoader

            property alias skipButton: skipButton
            property alias cancelButton: cancelButton
            property alias nextButton: nextButton
            property alias statusText: statusText

            QGCFlickable {
                anchors.fill: parent
                clip: true
                flickableDirection: Flickable.VerticalFlick
                contentWidth: width
                contentHeight: col.implicitHeight + root.sidePadding
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: col
                    width: parent.width
                    spacing: root.gap

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: root.sidePadding
                        Layout.rightMargin: root.sidePadding
                        Layout.topMargin: root.topPad
                        spacing: AzTheme.px(6)

                        Text { text: qsTr("Radio Konfiqurasiyası"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: root.h1Px }
                        Text { Layout.fillWidth: true; text: qsTr("RC ötürücü kanallarınızı və parametrlərinizi konfiqurasiya edin"); color: AzTheme.textSecondary; font.family: AzTheme.fontFamily; font.pixelSize: root.subPx; wrapMode: Text.WordWrap }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: root.sidePadding
                        Layout.rightMargin: root.sidePadding
                        radius: AzTheme.px(AzTheme.cardRadius)
                        border.width: 1
                        border.color: AzTheme.cardBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.cardGradientStart }
                            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                        }
                        implicitHeight: aCol.implicitHeight + root.innerPad*2

                        ColumnLayout {
                            id: aCol
                            anchors.fill: parent
                            anchors.margins: root.innerPad
                            spacing: 12

                            Text { text: qsTr("Münasibətə Nəzarətlər"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: root.titlePx }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: AzTheme.px(AzTheme.groupRadius)
                                color: AzTheme.groupFill
                                border.width: 1
                                border.color: AzTheme.groupBorder
                                implicitHeight: root.rowMinH
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                                    anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                                    spacing: root.gap
                                    Text { text: qsTr("Roll"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.pixelSize: root.textPx; Layout.preferredWidth: root.labelW }
                                    Loader { id: rollLoader; Layout.fillWidth: true; Layout.preferredHeight: root.channelRowH; sourceComponent: channelMonitorDisplayComponent }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: AzTheme.px(AzTheme.groupRadius)
                                color: AzTheme.groupFill
                                border.width: 1
                                border.color: AzTheme.groupBorder
                                implicitHeight: root.rowMinH
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                                    anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                                    spacing: root.gap
                                    Text { text: qsTr("Pitch"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.pixelSize: root.textPx; Layout.preferredWidth: root.labelW }
                                    Loader { id: pitchLoader; Layout.fillWidth: true; Layout.preferredHeight: root.channelRowH; sourceComponent: channelMonitorDisplayComponent }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: AzTheme.px(AzTheme.groupRadius)
                                color: AzTheme.groupFill
                                border.width: 1
                                border.color: AzTheme.groupBorder
                                implicitHeight: root.rowMinH
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                                    anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                                    spacing: root.gap
                                    Text { text: qsTr("Yaw"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.pixelSize: root.textPx; Layout.preferredWidth: root.labelW }
                                    Loader { id: yawLoader; Layout.fillWidth: true; Layout.preferredHeight: root.channelRowH; sourceComponent: channelMonitorDisplayComponent }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: AzTheme.px(AzTheme.groupRadius)
                                color: AzTheme.groupFill
                                border.width: 1
                                border.color: AzTheme.groupBorder
                                implicitHeight: root.rowMinH
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                                    anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                                    spacing: root.gap
                                    Text { text: qsTr("Throttle"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.pixelSize: root.textPx; Layout.preferredWidth: root.labelW }
                                    Loader { id: throttleLoader; Layout.fillWidth: true; Layout.preferredHeight: root.channelRowH; sourceComponent: channelMonitorDisplayComponent }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: root.sidePadding
                        Layout.rightMargin: root.sidePadding
                        radius: AzTheme.px(AzTheme.cardRadius)
                        border.width: 1
                        border.color: AzTheme.cardBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.cardGradientStart }
                            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                        }
                        implicitHeight: mCol.implicitHeight + root.innerPad*2

                        ColumnLayout {
                            id: mCol
                            anchors.fill: parent
                            anchors.margins: root.innerPad
                            spacing: 10

                            Text { text: qsTr("Transmitter rejimi"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: root.titlePx }
                            ButtonGroup { id: mGroup }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: root.gap
                                QGCRadioButton { text: qsTr("Rejim 1"); checked: controller.transmitterMode==1; ButtonGroup.group: mGroup; onClicked: controller.transmitterMode=1; Layout.fillWidth: true }
                                QGCRadioButton { text: qsTr("Rejim 2"); checked: controller.transmitterMode==2; ButtonGroup.group: mGroup; onClicked: controller.transmitterMode=2; Layout.fillWidth: true }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: root.sidePadding
                        Layout.rightMargin: root.sidePadding
                        radius: AzTheme.px(AzTheme.cardRadius)
                        border.width: 1
                        border.color: AzTheme.cardBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.cardGradientStart }
                            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                        }
                        implicitHeight: mmCol.implicitHeight + root.innerPad*2

                        ColumnLayout {
                            id: mmCol
                            anchors.fill: parent
                            anchors.margins: root.innerPad
                            spacing: root.gap

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.helpImageH
                                color: "transparent"

                                Image {
                                    id: cHelp
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    cache: false
                                    source: root.resolveHelpImage()
                                }

                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    source: root.fallbackImagePath
                                    visible: (cHelp.source === "") || (cHelp.status === Image.Error)
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.rcMonitorH
                                clip: true

                                // Monitor bütün kanallar üçün öz hündürlüyünü alır; kart sabit hündürlükdədir,
                                // ona görə sığmayan kanallar kəsilməsin deyə burada scroll olunur. Hamısı
                                // sığanda interactive söndürülür ki, sürüşdürmə səhifənin özünə getsin.
                                QGCFlickable {
                                    anchors.fill:       parent
                                    contentWidth:       width
                                    contentHeight:      rcMonitorCompact.height
                                    flickableDirection: Flickable.VerticalFlick
                                    interactive:        contentHeight > height

                                    RCChannelMonitor {
                                        id:         rcMonitorCompact
                                        width:      parent.width
                                        twoColumn:  false
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    visible: root.showNoRcHint

                                    Column {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.86
                                        spacing: 6

                                        QGCLabel {
                                            width: parent.width
                                            text: qsTr("RC siqnalı aşkar edilmədi")
                                            color: AzTheme.textCard
                                            font.pixelSize: root.textPx
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.WordWrap
                                        }

                                        QGCLabel {
                                            width: parent.width
                                            text: qsTr("Radio qoşulduqdan sonra kanallar burada görünəcək.")
                                            color: AzTheme.textSecondary
                                            font.pixelSize: root.textPx
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        Layout.leftMargin: root.sidePadding
                        Layout.rightMargin: root.sidePadding
                        spacing: root.gap

                        QGCButton { id: skipButton;   width: parent.width; height: AzTheme.px(40); text: qsTr("Keç");     onClicked: controller.skipButtonClicked() }
                        QGCButton { id: cancelButton; width: parent.width; height: AzTheme.px(40); text: qsTr("Ləğv et"); onClicked: controller.cancelButtonClicked() }
                        QGCButton { id: nextButton;   width: parent.width; height: AzTheme.px(40); primary: true; text: controller.calibrateText; onClicked: controller.nextButtonClicked() }
                    }

                    QGCLabel {
                        id: statusText
                        Layout.fillWidth: true
                        Layout.leftMargin: root.sidePadding
                        Layout.rightMargin: root.sidePadding
                        wrapMode: Text.WordWrap
                        color: AzTheme.textCard
                        font.pixelSize: root.textPx
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: root.sidePadding
                        Layout.rightMargin: root.sidePadding
                        radius: AzTheme.px(AzTheme.cardRadius)
                        border.width: 1
                        border.color: AzTheme.cardBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.cardGradientStart }
                            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                        }
                        implicitHeight: exCol.implicitHeight + root.innerPad*2

                        ColumnLayout {
                            id: exCol
                            anchors.fill: parent
                            anchors.margins: root.innerPad
                            spacing: root.gap

                            Text { text: qsTr("Əlavə Radio quraşdırma:"); color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: root.titlePx }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 1
                                rowSpacing: 10

                                Repeater {
                                    model: QGroundControl.multiVehicleManager.activeVehicle && QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ?
                                               (QGroundControl.multiVehicleManager.activeVehicle.multiRotor ?
                                                    [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"] :
                                                    [ "RC_MAP_FLAPS", "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"]) :
                                               [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3" ]

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        radius: AzTheme.px(AzTheme.groupRadius)
                                        color: AzTheme.groupFill
                                        border.width: 1
                                        border.color: AzTheme.groupBorder
                                        implicitHeight: AzTheme.px(AzTheme.groupRowHeight)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: root.gap

                                            QGCLabel { text: controller.getParameterFact(-1, modelData).shortDescription; color: AzTheme.textCard; Layout.fillWidth: true }

                                            FactComboBox {
                                                id: extraParamComboC
                                                fact: controller.getParameterFact(-1, modelData)
                                                indexModel: false
                                                Layout.minimumWidth: 180

                                                // ✅ Popup ölçülərini kiçilt (hündürlük + item hündürlüyü)

                                                // ✅ Popup ağdırsa — yazı qara olsun (görünsün)

                                            }
                                        }
                                    }
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: root.gap

                                QGCButton { width: parent.width; height: AzTheme.px(40); primary: true; text: qsTr("Spektrum bağlama"); onClicked: spektrumBindDialogComponent.createObject(mainWindow).open() }
                                QGCButton { width: parent.width; height: AzTheme.px(40); primary: true; text: qsTr("CRSF Bağlaması"); onClicked: mainWindow.showMessageDialog(qsTr("CRSF Bağlaması"), qsTr("CRSF qəbuledicinizi bağlama rejimində yerləşdirmək üçün Ok düyməsini klikləyin."), Dialog.Ok|Dialog.Cancel, function(a){ if(a) controller.crsfBindMode() }) }
                                QGCButton { width: parent.width; height: AzTheme.px(40); primary: true; text: qsTr("Kəsmələri kopyalayın"); onClicked: mainWindow.showMessageDialog(qsTr("Kəsmələri kopyalayın"), qsTr("Çubuqlarınızı mərkəzləşdirin və tənzimləyicini tam aşağı hərəkət etdirin, sonra trimləri kopyalamaq üçün Ok düyməsini basın. Ok düyməsini basdıqdan sonra radionuzdakı trimləri sıfıra qaytarın."), Dialog.Ok|Dialog.Cancel, function(a){ if(a) controller.copyTrims() }) }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; height: root.sidePadding }
                }
            }
        }
    }

    // Active vehicle sonradan gəlirsə
    Connections {
        target: QGroundControl.multiVehicleManager
        function onActiveVehicleChanged() {
            if (viewLoader.item) root._wireView(viewLoader.item)
        }
    }

    Component.onCompleted: Qt.callLater(function(){ if (viewLoader.item) root._wireView(viewLoader.item) })
}

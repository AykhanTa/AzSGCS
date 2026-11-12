import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

// General settings, in the new design: the page header of the setup pages, status cards
// with group box rows, and the new combo boxes, switches and buttons.
Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    // The combo boxes, switches, labels and buttons take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property var    _brandImageSettings:        _settingsManager.brandImageSettings
    property Fact   _appFontPointSize:          _appSettings.appFontPointSize
    property Fact   _userBrandImageIndoor:      _brandImageSettings.userBrandImageIndoor
    property Fact   _userBrandImageOutdoor:     _brandImageSettings.userBrandImageOutdoor
    property Fact   _appSavePath:               _appSettings.savePath

    // ---------- Responsive metrics ----------
    readonly property bool phone:  ScreenTools.isMobile || width < 700
    readonly property bool tablet: width < 1100

    readonly property real sidePadding: AzTheme.px(phone ? 12 : 20)
    readonly property real gap:         AzTheme.px(phone ? 10 : 16)

    // Yumşaq font scale: desktop=1.00, tablet ~0.95, phone ~0.90
    readonly property real fontScale: {
        var w = Math.max(1, width)
        var s = w / 1200.0
        s = Math.min(1.0, s)
        return Math.max(0.90, Math.min(1.0, s))
    }

    readonly property real titleFontPx: AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descFontPx:  AzTheme.fontPx(13)
    readonly property real labelFontPx: AzTheme.fontPx(AzTheme.popupTextSize)

    readonly property real smallPoint: ScreenTools.smallFontPointSize * fontScale

    // Panel grid hesabı
    readonly property real availableW: Math.max(0, width - 2 * sidePadding)
    readonly property real minPanelW:  phone ? 320 : tablet ? 520 : 720
    readonly property real maxPanelW:  820

    // Uçuş Görünüşü kimi maksimum 2 sütun
    readonly property int columns: phone ? 1
                                        : Math.min(2, Math.max(1, Math.floor((availableW + gap) / (minPanelW + gap))))

    readonly property real panelW: (columns === 1)
                                        ? availableW
                                        : Math.min(maxPanelW,
                                                   Math.floor((availableW - gap * (columns - 1)) / columns))

    // Row ölçüləri
    readonly property real rowPadX: AzTheme.px(AzTheme.groupPadding)
    readonly property real rowPadY: AzTheme.px(8)
    readonly property real rowMinH: AzTheme.px(AzTheme.groupRowHeight + 4)

    readonly property real ctrlW: Math.max(140, Math.min(260, panelW * (phone ? 0.55 : 0.42)))

    // -------------------- BLOCK BACKGROUND MAP INPUT --------------------
    // General Settings üstündə scroll/pinch edəndə arxadakı xəritəyə getməsin
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    WheelHandler {
        // bütün səhifə sahəsində wheel-i tut
        target: root
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: function(w) {
            // event arxaya keçməsin
            w.accepted = true

            // wheel-i bizim Flickable scroll-a çevir
            if (!flick) return

            var step = 0
            // touchpad: pixelDelta daha düzgündür
            if (w.pixelDelta && w.pixelDelta.y !== 0) {
                step = w.pixelDelta.y
            } else {
                // mouse wheel: angleDelta adətən 120 olur
                step = w.angleDelta.y / 3
            }

            var maxY = Math.max(0, flick.contentHeight - flick.height)
            flick.contentY = _clamp(flick.contentY - step, 0, maxY)
        }
    }

    PinchHandler {
        // Pinch jestini sadəcə “tut”, UI-ni böyütmə/kiçiltmə/daşıma ETMƏ
        target: null

        acceptedDevices: PointerDevice.TouchScreen

        // təhlükəsizlik üçün: scale/rotation kilidlə (target null olsa da problem çıxmaz)
        minimumScale: 1
        maximumScale: 1
        minimumRotation: 0
        maximumRotation: 0

        // (əgər versiyada varsa) jesti mütləq özünə götürsün
        grabPermissions: PointerHandler.CanTakeOverFromAnything
    }


    // ---------- Header ----------
    Column {
        id: headerArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: sidePadding
        anchors.rightMargin: sidePadding
        anchors.topMargin: AzTheme.px(20)
        spacing: AzTheme.px(6)

        Text {
            width: parent.width
            text: qsTr("Ümumi Tənzimləmələr")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titleFontPx
            wrapMode: Text.WordWrap
        }

        Text {
            text: qsTr("Proqramda ümumi parametrləri, ölçü vahidlərini və marka şəkillərini tənzimləmək üçün istifadə olunan tənzimləmələr")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descFontPx
            wrapMode: Text.WordWrap
            width: Math.min(parent.width, 1100)
        }
    }

    // ---------- Scroll content ----------
    QGCFlickable {
        id: flick
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: AzTheme.px(16)

        clip: true
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + sidePadding

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: contentColumn
            width: parent.width
            spacing: gap

            Flow {
                id: panelFlow
                x: sidePadding
                width: parent.width - 2 * sidePadding
                spacing: gap
                height: childrenRect.height

                property bool alignTopRow: root.columns > 1
                property real topRowH: alignTopRow ? Math.max(generalPanel.desiredH, unitsPanel.desiredH) : 0


                // ===================== Panel 1: Ümumi =====================
                Rectangle {
                    id: generalPanel
                    width: Math.min(root.panelW, panelFlow.width)
                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }


                    readonly property real pad: AzTheme.px(16)
                    readonly property real desiredH: generalLayout.implicitHeight + pad * 2

                    //height: generalLayout.implicitHeight + pad * 2
                    height: panelFlow.alignTopRow ? panelFlow.topRowH : desiredH


                    ColumnLayout {
                        id: generalLayout
                        x: generalPanel.pad
                        y: generalPanel.pad
                        width: generalPanel.width - 2 * generalPanel.pad
                        spacing: AzTheme.px(8)

                        Text {
                            text: qsTr("Ümumi")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(16)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        // Dil
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, langRow.implicitHeight + root.rowPadY * 2)

                            RowLayout {
                                id: langRow
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: root.gap

                                QGCLabel {
                                    text: qsTr("Dil")
                                    font.pixelSize: root.labelFontPx
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    Layout.fillWidth: true
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.ctrlW
                                    Layout.minimumWidth: 140
                                    fact: _appSettings.qLocaleLanguage
                                    indexModel: false
                                    visible: _appSettings.qLocaleLanguage.visible
                                }
                            }
                        }

                        // Rəng Sxemi
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, palRow.implicitHeight + root.rowPadY * 2)

                            RowLayout {
                                id: palRow
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: root.gap

                                QGCLabel {
                                    text: qsTr("Rəng Sxemi")
                                    font.pixelSize: root.labelFontPx
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    Layout.fillWidth: true
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.ctrlW
                                    Layout.minimumWidth: 140
                                    fact: _appSettings.indoorPalette
                                    indexModel: false
                                    visible: _appSettings.indoorPalette.visible
                                }
                            }
                        }

                        // Yayım GSC Mövqeyi
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, gcsRow.implicitHeight + root.rowPadY * 2)

                            RowLayout {
                                id: gcsRow
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: root.gap

                                QGCLabel {
                                    text: qsTr("Yayım GSC Mövqeyi")
                                    font.pixelSize: root.labelFontPx
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    Layout.fillWidth: true
                                }

                                FactComboBox {
                                    Layout.preferredWidth: root.ctrlW
                                    Layout.minimumWidth: 140
                                    fact: _appSettings.followTarget
                                    indexModel: false
                                    visible: _appSettings.followTarget.visible
                                }
                            }
                        }

                        // Audio muted
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, audioRow.implicitHeight + root.rowPadY * 2)

                            RowLayout {
                                id: audioRow
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: root.gap

                                QGCLabel {
                                    text: qsTr("Bütün audio çıxışı səssizləşdirin")
                                    font.pixelSize: root.labelFontPx
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    Layout.fillWidth: true
                                }

                                FactCheckBoxSlider {
                                    fact: _appSettings.audioMuted
                                    visible: _appSettings.audioMuted.visible
                                }
                            }
                        }

                        // Clear settings next boot
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, clearRow.implicitHeight + root.rowPadY * 2)

                            RowLayout {
                                id: clearRow
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: root.gap

                                QGCLabel {
                                    text: qsTr("Növbəti başlanğıcda bütün parametrləri silin")
                                    font.pixelSize: root.labelFontPx
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    Layout.fillWidth: true
                                }

                                QGCCheckBoxSlider {
                                    checked: false
                                    onClicked: {
                                        if (checked) {
                                            QGroundControl.deleteAllSettingsNextBoot()
                                        } else {
                                            QGroundControl.clearDeleteAllSettingsNextBoot()
                                        }
                                    }
                                }
                            }
                        }

                        // UI Scaling
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            visible: _appFontPointSize.visible
                            implicitHeight: Math.max(root.rowMinH, scaleRow.implicitHeight + root.rowPadY * 2)

                            RowLayout {
                                id: scaleRow
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: root.gap

                                QGCLabel {
                                    text: qsTr("UI Miqyaslanması")
                                    font.pixelSize: root.labelFontPx
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 10

                                    QGCButton {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        text: "-"
                                        onClicked: {
                                            if (_appFontPointSize.value > _appFontPointSize.min) {
                                                _appFontPointSize.value = _appFontPointSize.value - 1
                                            }
                                        }
                                    }

                                    QGCLabel {
                                        Layout.preferredWidth: 60
                                        text: (QGroundControl.settingsManager.appSettings.appFontPointSize.value / ScreenTools.platformFontPointSize * 100).toFixed(0) + "%"
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    QGCButton {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        text: "+"
                                        onClicked: {
                                            if (_appFontPointSize.value < _appFontPointSize.max) {
                                                _appFontPointSize.value = _appFontPointSize.value + 1
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Save Path (desktop only)
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            visible: _appSavePath.visible && !ScreenTools.isMobile
                            implicitHeight: Math.max(root.rowMinH, saveRow.implicitHeight + root.rowPadY * 2)

                            RowLayout {
                                id: saveRow
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: root.gap

                                QGCLabel {
                                    text: qsTr("Proqram Yüklə/Yolu saxla")
                                    font.pixelSize: root.labelFontPx
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    Layout.fillWidth: true
                                }

                                QGCLabel {
                                    Layout.fillWidth: true
                                    text: _appSavePath.rawValue === "" ? qsTr("<default location>") : _appSavePath.value
                                    elide: Text.ElideMiddle
                                    font.pointSize: root.smallPoint
                                }

                                QGCButton {
                                    text: qsTr("Gözdən Keçirin")
                                    Layout.preferredWidth: phone ? 140 : 160
                                    onClicked: savePathBrowseDialog.openForLoad()

                                    QGCFileDialog {
                                        id: savePathBrowseDialog
                                        title: qsTr("Choose the location to save/load files")
                                        folder: _appSavePath.rawValue
                                        selectFolder: true
                                        onAcceptedForLoad: function(file) { _appSavePath.rawValue = file }
                                    }
                                }
                            }
                        }
                    }
                }

                // ===================== Panel 2: Vahidlər =====================
                Rectangle {
                    id: unitsPanel
                    width: Math.min(root.panelW, panelFlow.width)
                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }
                    visible: QGroundControl.settingsManager.unitsSettings.visible

                    readonly property real pad: AzTheme.px(16)
                    readonly property real desiredH: unitsLayout.implicitHeight + pad * 2

                    // height: unitsLayout.implicitHeight + pad * 2
                    height: panelFlow.alignTopRow ? panelFlow.topRowH : desiredH


                    ColumnLayout {
                        id: unitsLayout
                        x: unitsPanel.pad
                        y: unitsPanel.pad
                        width: unitsPanel.width - 2 * unitsPanel.pad
                        spacing: AzTheme.px(8)

                        Text {
                            text: qsTr("Vahidlər")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(16)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Repeater {
                            model: [
                                QGroundControl.settingsManager.unitsSettings.horizontalDistanceUnits,
                                QGroundControl.settingsManager.unitsSettings.verticalDistanceUnits,
                                QGroundControl.settingsManager.unitsSettings.areaUnits,
                                QGroundControl.settingsManager.unitsSettings.speedUnits,
                                QGroundControl.settingsManager.unitsSettings.temperatureUnits
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                radius: AzTheme.px(AzTheme.groupRadius)
                                color: AzTheme.groupFill
                                border.width: 1
                                border.color: AzTheme.groupBorder
                                implicitHeight: Math.max(root.rowMinH, uRow.implicitHeight + root.rowPadY * 2)

                                RowLayout {
                                    id: uRow
                                    anchors.fill: parent
                                    anchors.leftMargin: root.rowPadX
                                    anchors.rightMargin: root.rowPadX
                                    anchors.topMargin: root.rowPadY
                                    anchors.bottomMargin: root.rowPadY
                                    spacing: root.gap

                                    QGCLabel {
                                        text: modelData.shortDescription
                                        font.pixelSize: root.labelFontPx
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        Layout.fillWidth: true
                                    }

                                    FactComboBox {
                                        Layout.preferredWidth: root.ctrlW
                                        Layout.minimumWidth: 140
                                        fact: modelData
                                        indexModel: false
                                    }
                                }
                            }
                        }
                    }
                }

            }

            Item { width: 1; height: sidePadding }
        }
    }
}

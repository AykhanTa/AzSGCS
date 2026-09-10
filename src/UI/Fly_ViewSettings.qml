import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

Rectangle {
    id: root
    anchors.fill: parent
    color: "#000000"

    property var    _settingsManager:                       QGroundControl.settingsManager
    property var    _flyViewSettings:                       _settingsManager.flyViewSettings
    property var    _mavlinkActionsSettings:                _settingsManager.mavlinkActionsSettings
    property Fact   _virtualJoystick:                       _settingsManager.appSettings.virtualJoystick
    property Fact   _virtualJoystickAutoCenterThrottle:     _settingsManager.appSettings.virtualJoystickAutoCenterThrottle
    property Fact   _virtualJoystickLeftHandedMode:         _settingsManager.appSettings.virtualJoystickLeftHandedMode
    property Fact   _enableMultiVehiclePanel:               _settingsManager.appSettings.enableMultiVehiclePanel
    property Fact   _showAdditionalIndicatorsCompass:       _flyViewSettings.showAdditionalIndicatorsCompass
    property Fact   _lockNoseUpCompass:                     _flyViewSettings.lockNoseUpCompass
    property Fact   _guidedMinimumAltitude:                 _flyViewSettings.guidedMinimumAltitude
    property Fact   _guidedMaximumAltitude:                 _flyViewSettings.guidedMaximumAltitude
    property Fact   _maxGoToLocationDistance:               _flyViewSettings.maxGoToLocationDistance
    property Fact   _forwardFlightGoToLocationLoiterRad:    _flyViewSettings.forwardFlightGoToLocationLoiterRad
    property Fact   _goToLocationRequiresConfirmInGuided:   _flyViewSettings.goToLocationRequiresConfirmInGuided
    property var    _viewer3DSettings:                      _settingsManager.viewer3DSettings
    property Fact   _viewer3DEnabled:                       _viewer3DSettings.enabled
    property Fact   _viewer3DOsmFilePath:                   _viewer3DSettings.osmFilePath
    property Fact   _viewer3DBuildingLevelHeight:           _viewer3DSettings.buildingLevelHeight
    property Fact   _viewer3DAltitudeBias:                  _viewer3DSettings.altitudeBias

    property Fact _useChecklist: _settingsManager.appSettings.useChecklist
    property Fact _enforceChecklist: _settingsManager.appSettings.enforceChecklist
    property Fact _keepMapCenteredOnVehicle: _flyViewSettings.keepMapCenteredOnVehicle
    property Fact _showLogReplayStatusBar: _flyViewSettings.showLogReplayStatusBar
    property Fact _showSimpleCameraControl: _flyViewSettings.showSimpleCameraControl
    property Fact _updateHomePosition: _flyViewSettings.updateHomePosition

    function mavlinkActionList() {
        var fileModel = QGCFileDialogController.getFiles(_settingsManager.appSettings.mavlinkActionsSavePath, "*.json")
        fileModel.unshift(qsTr("<Heç biri>"))
        return fileModel
    }

    // ---------- Responsive metrics (General_Settings kimi) ----------
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100

    readonly property real sidePadding: Math.max(10, ScreenTools.defaultFontPixelWidth  * (phone ? 0.9 : tablet ? 1.2 : 1.6))
    readonly property real gap:         Math.max(10, ScreenTools.defaultFontPixelWidth  * (phone ? 0.9 : tablet ? 1.2 : 1.6))

    readonly property real fontScale: {
        var w = Math.max(1, width)
        var s = w / 1200.0
        s = Math.min(1.0, s)
        return Math.max(0.90, Math.min(1.0, s))
    }

    readonly property real titleFontPx: Math.max(18, ScreenTools.defaultFontPixelHeight * (phone ? 1.15 : 1.25) * fontScale)
    readonly property real descFontPx:  Math.max(12, ScreenTools.defaultFontPixelHeight * (phone ? 0.92 : 0.98) * fontScale)
    readonly property real labelFontPx: Math.max(11, ScreenTools.defaultFontPixelHeight * (phone ? 0.90 : 0.88) * fontScale)
    readonly property real smallPoint:  ScreenTools.smallFontPointSize * fontScale

    readonly property real rowPadX: Math.max(12, ScreenTools.defaultFontPixelWidth * 1.2)
    readonly property real rowPadY: Math.max(8,  ScreenTools.defaultFontPixelHeight * 0.6)
    readonly property real rowMinH: Math.max(48, ScreenTools.defaultFontPixelHeight * 2.6)

    // Layout width hesabı (real görünən en üçün)
    readonly property real contentW: Math.max(0, flick.width - 2 * sidePadding)

    // 2 sütun üçün minimum panel eni (tablet/desktop fərqli)
    readonly property real minColW: (tablet ? 520 : 720)
    readonly property real maxColW: 820

    // ✅ Sərt qərar: iki panel üçün həqiqətən yer varsa 2 sütun, yoxsa 1 sütun
    readonly property int columns: (phone || contentW < (2 * minColW + gap)) ? 1 : 2

    // sütun eni
    readonly property real colW: (columns === 1)
                                 ? contentW
                                 : Math.min(maxColW, Math.floor((contentW - gap) / 2))

    readonly property real ctrlW: Math.max(140, Math.min(260, colW * (phone ? 0.60 : 0.42)))

    // ---------- Header ----------
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
            text: qsTr("Uçuş Görünüşü Tənzimləmələri")
            color: "white"
            font.pixelSize: 26
            font.bold: true
            wrapMode: Text.WordWrap
        }

        Text {
            text: qsTr("Uçuş görünüşü tənzimləməsini göstərən və dəyişdirməyə imkan verən tənzimləmə paneli")
            color: "#E8E8E8"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            width: Math.min(parent.width, 1100)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#FFFFFF"
            opacity: 0.25
        }
    }

    // ---------- Scroll content ----------
    QGCFlickable {
        id: flick
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.5)

        clip: true
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + sidePadding

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: contentColumn
            width: parent.width
            spacing: gap

            // Panel host (soldan-sağdan eyni padding)
            Item {
                id: panelHost
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: sidePadding
                anchors.rightMargin: sidePadding

                // Layout hündürlüyü (1 sütun: Column implicit, 2 sütun: max(sol, sağ))
                height: (root.columns === 1)
                        ? oneCol.implicitHeight
                        : Math.max(colLeft.implicitHeight, colRight.implicitHeight)

                // --------- 1 sütun (kiçik ekran) ----------
                Column {
                    id: oneCol
                    width: parent.width
                    spacing: gap
                    visible: root.columns === 1

                    Loader { active: root.columns === 1; sourceComponent: generalPanelComponent }
                    Loader { active: root.columns === 1; sourceComponent: guidedPanelComponent }
                    Loader { active: root.columns === 1; sourceComponent: mavPanelComponent }
                    Loader { active: root.columns === 1; sourceComponent: vjoyPanelComponent }
                    Loader { active: root.columns === 1; sourceComponent: view3DPanelComponent }
                    Loader { active: root.columns === 1; sourceComponent: instPanelComponent }
                }

                // --------- 2 sütun (masonry: boşluqsuz) ----------
                Row {
                    id: twoColRow
                    anchors.left: parent.left
                    anchors.top: parent.top
                    spacing: gap
                    visible: root.columns === 2

                    Column {
                        id: colLeft
                        width: root.colW
                        spacing: gap

                        Loader { active: root.columns === 2; sourceComponent: generalPanelComponent }
                        Loader { active: root.columns === 2; sourceComponent: mavPanelComponent }
                        Loader { active: root.columns === 2; sourceComponent: view3DPanelComponent }
                    }

                    Column {
                        id: colRight
                        width: root.colW
                        spacing: gap

                        Loader { active: root.columns === 2; sourceComponent: guidedPanelComponent }
                        Loader { active: root.columns === 2; sourceComponent: vjoyPanelComponent }
                        Loader { active: root.columns === 2; sourceComponent: instPanelComponent }
                    }
                }
            }

            Item { width: 1; height: sidePadding }
        }
    }

    // ===================== COMMON PANEL STYLE HELPERS =====================
    QtObject {
        id: panelStyle
        readonly property color panelBg: "#3D3B3B"
        readonly property color rowBg:   "#2A2A2A"
        readonly property color border:  "#9D9D9D"
        readonly property real  radius:  16
        readonly property real  rowRadius: 10
        readonly property real  pad: Math.max(14, ScreenTools.defaultFontPixelWidth * 1.2)
        readonly property real  titlePx: {
            var v = Math.max(15, ScreenTools.defaultFontPixelHeight * 1.02 * (root.fontScale || 1))
            return isFinite(v) ? v : 15
        }
    }

    // ===================== PANEL 1: ÜMUMİ =====================
    Component {
        id: generalPanelComponent

        Rectangle {
            width: root.colW
            color: panelStyle.panelBg
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border

            height: layout.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                Text {
                    text: qsTr("Ümumi")
                    color: "white"
                    font.pixelSize: panelStyle.titlePx
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                // Ön Uçuş Siyahısını İstifadə Edin
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _useChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length
                    implicitHeight: Math.max(root.rowMinH, useRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: useRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Ön Uçuş Siyahısını İstifadə Edin")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _useChecklist }
                    }
                }

                // Ön Uçuş Siyahısını Məcbur Edin
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _enforceChecklist.visible && _useChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length
                    implicitHeight: Math.max(root.rowMinH, enforceRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: enforceRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Ön Uçuş Siyahısını Məcbur Edin")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _enforceChecklist; enabled: _useChecklist.value }
                    }
                }

                // Çoxlu Vasitə Panelini Aktiv Edin
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _enableMultiVehiclePanel.visible
                    implicitHeight: Math.max(root.rowMinH, mvRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: mvRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Çoxlu Vasitə Panelini Aktiv Edin")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _enableMultiVehiclePanel }
                    }
                }

                // Xəritəni Vasitə Mərkəzində Saxlayın
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _keepMapCenteredOnVehicle.visible
                    implicitHeight: Math.max(root.rowMinH, kmRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: kmRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Xəritəni Vasitə Mərkəzində Saxlayın")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _keepMapCenteredOnVehicle }
                    }
                }

                // Telemetri Log Replay Status Barını Göstər
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _showLogReplayStatusBar.visible
                    implicitHeight: Math.max(root.rowMinH, logRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: logRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Telemetri Log Replay Status Barını Göstər")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _showLogReplayStatusBar }
                    }
                }

                // Sadə Kamera Nəzarətini Göstər
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _showSimpleCameraControl.visible
                    implicitHeight: Math.max(root.rowMinH, camRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: camRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Sadə Kamera Nəzarətini Göstər (DIGICAM_CONTROL)")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _showSimpleCameraControl }
                    }
                }

                // Ev Mövqeyini Yenilə
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _updateHomePosition.visible
                    implicitHeight: Math.max(root.rowMinH, homeRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: homeRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Ev Mövqeyini Cihazın Yerləşməsinə Görə Yenilə")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _updateHomePosition }
                    }
                }
            }
        }
    }

    // ===================== PANEL 2: GUIDE EDİLMİŞ ƏMRLƏR =====================
    Component {
        id: guidedPanelComponent

        Rectangle {
            width: root.colW
            color: panelStyle.panelBg
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border
            visible: _guidedMinimumAltitude.visible || _guidedMaximumAltitude.visible ||
                     _maxGoToLocationDistance.visible || _forwardFlightGoToLocationLoiterRad.visible ||
                     _goToLocationRequiresConfirmInGuided.visible

            height: layout.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                Text {
                    text: qsTr("Guide Edilmiş Əmrlər")
                    color: "white"
                    font.pixelSize: panelStyle.titlePx
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _guidedMinimumAltitude.visible
                    implicitHeight: Math.max(root.rowMinH, gminRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: gminRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Minimum Hündürlük")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }

                        FactTextField {
                            Layout.preferredWidth: root.ctrlW
                            Layout.minimumWidth: 120
                            Layout.alignment: Qt.AlignRight
                            fact: _guidedMinimumAltitude
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _guidedMaximumAltitude.visible
                    implicitHeight: Math.max(root.rowMinH, gmaxRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: gmaxRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Maksimum Hündürlük")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }

                        FactTextField {
                            Layout.preferredWidth: root.ctrlW
                            Layout.minimumWidth: 120
                            Layout.alignment: Qt.AlignRight
                            fact: _guidedMaximumAltitude
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _maxGoToLocationDistance.visible
                    implicitHeight: Math.max(root.rowMinH, distRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: distRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Go To Location Maksimum Məsafə")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }

                        FactTextField {
                            Layout.preferredWidth: root.ctrlW
                            Layout.minimumWidth: 120
                            Layout.alignment: Qt.AlignRight
                            fact: _maxGoToLocationDistance
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _forwardFlightGoToLocationLoiterRad.visible
                    implicitHeight: Math.max(root.rowMinH, loiterRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: loiterRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("İrəli Uçuş Rəhbəri Modunda Loiter Radiusu")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }

                        FactTextField {
                            Layout.preferredWidth: root.ctrlW
                            Layout.minimumWidth: 120
                            Layout.alignment: Qt.AlignRight
                            fact: _forwardFlightGoToLocationLoiterRad
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _goToLocationRequiresConfirmInGuided.visible
                    implicitHeight: Math.max(root.rowMinH, confirmRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: confirmRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Guide Edilmiş Modda Go To Location Üçün Təsdiq Tələb Edin")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }

                        FactCheckBoxSlider { fact: _goToLocationRequiresConfirmInGuided }
                    }
                }
            }
        }
    }

    // ===================== PANEL 3: MAVLINK AKSİYONLARI =====================
    Component {
        id: mavPanelComponent

        Rectangle {
            width: root.colW
            color: panelStyle.panelBg
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border

            height: layout.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                Text {
                    text: qsTr("MAVLink Aksiyonları")
                    color: "white"
                    font.pixelSize: panelStyle.titlePx
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Fəaliyyət JSON faylları '%1' qovluğunda yaradılmalıdır.").arg(QGroundControl.settingsManager.appSettings.mavlinkActionsSavePath)
                    color: "#CCCCCC"
                    font.pointSize: root.smallPoint
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    implicitHeight: Math.max(root.rowMinH, flyActRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: flyActRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Fly View Aksiyonları")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }

                        QGCComboBox {
                            sizeToContents: true
                            id: flyViewActionsComboBox
                            Layout.preferredWidth: Math.max(160, root.ctrlW)
                            Layout.minimumWidth: 140
                            model: root.mavlinkActionList()
                            enabled: model.length > 1

                            Component.onCompleted: {
                                var idx = find(_mavlinkActionsSettings.flyViewActionsFile.valueString)
                                currentIndex = (idx === -1) ? 0 : idx
                            }

                            onActivated: (idx) => {
                                if (idx === 0) {
                                    _mavlinkActionsSettings.flyViewActionsFile.rawValue = ""
                                } else {
                                    _mavlinkActionsSettings.flyViewActionsFile.rawValue = currentText
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    implicitHeight: Math.max(root.rowMinH, joyActRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: joyActRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Joystick Aksiyonları")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }

                        QGCComboBox {
                            sizeToContents: true
                            id: joystickActionsComboBox
                            Layout.preferredWidth: Math.max(160, root.ctrlW)
                            Layout.minimumWidth: 140
                            model: root.mavlinkActionList()
                            enabled: model.length > 1

                            Component.onCompleted: {
                                var idx = find(_mavlinkActionsSettings.joystickActionsFile.valueString)
                                currentIndex = (idx === -1) ? 0 : idx
                            }

                            onActivated: (idx) => {
                                if (idx === 0) {
                                    _mavlinkActionsSettings.joystickActionsFile.rawValue = ""
                                } else {
                                    _mavlinkActionsSettings.joystickActionsFile.rawValue = currentText
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ===================== PANEL 4: VIRTUAL JOYSTICK =====================
    Component {
        id: vjoyPanelComponent

        Rectangle {
            width: root.colW
            color: panelStyle.panelBg
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border
            visible: _virtualJoystick.visible || _virtualJoystickAutoCenterThrottle.visible || _virtualJoystickLeftHandedMode.visible

            height: layout.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                Text {
                    text: qsTr("Virtual Joystick")
                    color: "white"
                    font.pixelSize: panelStyle.titlePx
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _virtualJoystick.visible
                    implicitHeight: Math.max(root.rowMinH, vjRow1.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: vjRow1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Virtual Joystick Aktiv Edilmiş")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _virtualJoystick }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _virtualJoystickAutoCenterThrottle.visible
                    implicitHeight: Math.max(root.rowMinH, vjRow2.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: vjRow2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Auto-Center Throttle")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _virtualJoystickAutoCenterThrottle; enabled: _virtualJoystick.rawValue }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _virtualJoystickLeftHandedMode.visible
                    implicitHeight: Math.max(root.rowMinH, vjRow3.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: vjRow3
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Sol Əl Modu (stickləri dəyişdirin)")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _virtualJoystickLeftHandedMode; enabled: _virtualJoystick.rawValue }
                    }
                }
            }
        }
    }

    // ===================== PANEL 5: 3D GÖRÜNÜŞ =====================
    Component {
        id: view3DPanelComponent

        Rectangle {
            width: root.colW
            color: panelStyle.panelBg
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border
            visible: _viewer3DSettings.visible

            height: layout.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                Text {
                    text: qsTr("3D Görünüş")
                    color: "white"
                    font.pixelSize: panelStyle.titlePx
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _viewer3DEnabled.visible
                    implicitHeight: Math.max(root.rowMinH, v3dRow1.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: v3dRow1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("3D Görünüş Aktiv Edilmiş")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _viewer3DEnabled }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _viewer3DOsmFilePath.visible
                    implicitHeight: Math.max(root.rowMinH, osmCol.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    ColumnLayout {
                        id: osmCol
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: Math.max(8, root.gap * 0.6)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.gap

                            QGCLabel {
                                text: qsTr("3D Xəritə Faylı:")
                                color: "white"
                                font.pixelSize: root.labelFontPx
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                Layout.preferredWidth: root.phone ? 140 : 200
                            }

                            QGCTextField {
                                Layout.fillWidth: true
                                readOnly: true
                                text: _viewer3DOsmFilePath.rawValue
                                color: "white"
                                background: Rectangle { color: "#1A1A1A"; radius: 5 }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignRight
                            spacing: root.gap

                            QGCButton {
                                text: qsTr("Təmizlə")
                                Layout.preferredWidth: root.phone ? 120 : 100
                                onClicked: _viewer3DOsmFilePath.rawValue = ""
                            }

                            QGCButton {
                                text: qsTr("Fayl Seçin")
                                Layout.preferredWidth: root.phone ? 140 : 120
                                onClicked: fileDialog.openForLoad()

                                QGCFileDialog {
                                    id: fileDialog
                                    nameFilters: [qsTr("OpenStreetMap faylları (*.osm)")]
                                    title: qsTr("Xəritə faylını seçin")
                                    onAcceptedForLoad: (file) => { _viewer3DOsmFilePath.rawValue = file }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _viewer3DBuildingLevelHeight.visible
                    implicitHeight: Math.max(root.rowMinH, v3dRow2.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: v3dRow2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Orta Bina Səviyyəsi Hündürlüyü")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactTextField {
                            Layout.preferredWidth: root.ctrlW
                            Layout.minimumWidth: 120
                            fact: _viewer3DBuildingLevelHeight
                            enabled: _viewer3DEnabled.rawValue
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _viewer3DAltitudeBias.visible
                    implicitHeight: Math.max(root.rowMinH, v3dRow3.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: v3dRow3
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Vasitələr Hündürlük Biası")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactTextField {
                            Layout.preferredWidth: root.ctrlW
                            Layout.minimumWidth: 120
                            fact: _viewer3DAltitudeBias
                            enabled: _viewer3DEnabled.rawValue
                        }
                    }
                }
            }
        }
    }

    // ===================== PANEL 6: İNSTRUMENT PANELİ =====================
    Component {
        id: instPanelComponent

        Rectangle {
            width: root.colW
            color: panelStyle.panelBg
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border
            visible: _showAdditionalIndicatorsCompass.visible || _lockNoseUpCompass.visible

            height: layout.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)

                Text {
                    text: qsTr("İnstrument Paneli")
                    color: "white"
                    font.pixelSize: panelStyle.titlePx
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _showAdditionalIndicatorsCompass.visible
                    implicitHeight: Math.max(root.rowMinH, compRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: compRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Kompasda əlavə başlıq göstəricilərini göstərin")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _showAdditionalIndicatorsCompass }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: _lockNoseUpCompass.visible
                    implicitHeight: Math.max(root.rowMinH, lockRow.implicitHeight + root.rowPadY * 2)
                    height: implicitHeight

                    RowLayout {
                        id: lockRow
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX
                        anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY
                        anchors.bottomMargin: root.rowPadY
                        spacing: root.gap

                        QGCLabel {
                            text: qsTr("Kompası Burnu-Yuxarı Kilidləyin")
                            color: "white"
                            font.pixelSize: root.labelFontPx
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            Layout.fillWidth: true
                        }
                        FactCheckBoxSlider { fact: _lockNoseUpCompass }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

/// Batareya tənzimləmələri — göstərilən dəyər, rəngləmə hədləri və aşağı batareya failsafe.
/// Məzmun BatteryIndicator.qml / PX4BatteryIndicator.qml ilə eynidir, yalnız
/// TopStatusPanel-in öz panel dizaynına salınıb.
Rectangle {
    id: root

    anchors.fill: parent
    color: "#00000040"
    z: 100
    visible: true

    // TopStatusPanel-dən ötürülənlər
    property Item anchorItem: null
    property Item topPanelItem: null

    property var _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var _batterySettings: QGroundControl.settingsManager.batteryIndicatorSettings

    readonly property string _azIconBase: "qrc:/res/AZSHIELD_ICON/"

    readonly property bool _compact: (width < 900) || (height < 650)
    readonly property real _m:       Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.65 : 0.85))
    readonly property real _rowH:    Math.max(40, ScreenTools.defaultFontPixelHeight * 2.2)
    readonly property real _ctrlW:   Math.max(120, Math.min(210, panel.width * 0.40))

    FactPanelController { id: controller }

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    function reposition() {
        var gap    = Math.round(_m * 1.2)
        var margin = Math.round(_m * 1.2)

        var x = (root.width  - panel.width)  / 2
        var y = (root.height - panel.height) / 2

        if (anchorItem) {
            var p = anchorItem.mapToItem(root, 0, anchorItem.height)
            x = p.x + anchorItem.width / 2 - panel.width / 2
            y = p.y + gap
        } else if (topPanelItem) {
            y = topPanelItem.height + gap
        }

        panel.x = _clamp(x, margin, root.width  - panel.width  - margin)
        panel.y = _clamp(y, margin, root.height - panel.height - margin)
    }

    function close() {
        if (typeof settingsLoader !== "undefined" && settingsLoader) {
            settingsLoader.source = ""
        } else {
            root.visible = false
        }
    }

    Component.onCompleted: Qt.callLater(reposition)

    onWidthChanged:      Qt.callLater(reposition)
    onHeightChanged:     Qt.callLater(reposition)
    onAnchorItemChanged: Qt.callLater(reposition)

    Connections {
        target: panel
        function onHeightChanged() { Qt.callLater(root.reposition) }
    }

    // Panel açıq olduqda arxadakı xəritəyə heç bir mouse hadisəsi keçməməlidir
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        preventStealing: true
        onWheel: (wheel) => { wheel.accepted = true }
        onPressed: (mouse) => { mouse.accepted = true }
        onReleased: (mouse) => { mouse.accepted = true }
        onClicked: (mouse) => {
            mouse.accepted = true
            if (mouse.button === Qt.LeftButton) {
                root.close()
            }
        }
    }

    // ==========================================================
    // Təkrar istifadə olunan hissələr
    // ==========================================================

    /// Etiket solda, kontrol sağda
    component SettingRow: Rectangle {
        id: srow

        property alias label:  srowLabel.text
        property real  pad:    10
        property real  ctrlW:  150
        property real  rowH:   40
        default property alias content: srowContent.data

        implicitWidth:  parent ? parent.width : 0
        implicitHeight: rowH
        radius: 8
        color:  "#2A2A2A"

        QGCLabel {
            id: srowLabel
            anchors.left:           parent.left
            anchors.leftMargin:     srow.pad
            anchors.right:          srowContent.left
            anchors.rightMargin:    srow.pad * 0.6
            anchors.verticalCenter: parent.verticalCenter
            color:                  "#FFFFFF"
            elide:                  Text.ElideRight
        }

        Item {
            id: srowContent
            anchors.right:          parent.right
            anchors.rightMargin:    srow.pad
            anchors.verticalCenter: parent.verticalCenter
            width:                  srow.ctrlW
            height:                 Math.max(26, srow.rowH - 12)
        }
    }

    /// Bölmə başlığı
    component GroupTitle: RowLayout {
        property alias title: gtLabel.text

        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width:  3
            height: gtLabel.implicitHeight
            radius: 1.5
            color:  "#00C853"
        }

        QGCLabel {
            id:               gtLabel
            Layout.fillWidth: true
            color:            "#FFFFFF"
            font.bold:        true
        }
    }

    /// Rəngləmə pilləsi — ikon + (sabit etiket və ya redaktə olunan həd)
    component ColorStep: ColumnLayout {
        property string iconSource: ""
        property color  iconColor:  "#FFFFFF"
        property string caption:    ""
        property var    thresholdFact: null

        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.4)

        QGCColoredImage {
            Layout.alignment:       Qt.AlignHCenter
            Layout.preferredWidth:  Math.max(36, ScreenTools.defaultFontPixelHeight * 2.4)
            Layout.preferredHeight: Layout.preferredWidth
            source:                 iconSource
            color:                  iconColor
            fillMode:               Image.PreserveAspectFit
        }

        QGCLabel {
            Layout.alignment:       Qt.AlignHCenter
            Layout.preferredHeight: Math.max(28, ScreenTools.defaultFontPixelHeight * 1.7)
            text:                   caption
            color:                  "#E4E4E4"
            verticalAlignment:      Text.AlignVCenter
            visible:                thresholdFact === null
        }

        FactTextField {
            Layout.alignment:       Qt.AlignHCenter
            Layout.preferredWidth:  Math.max(56, ScreenTools.defaultFontPixelWidth * 6.5)
            Layout.preferredHeight: Math.max(28, ScreenTools.defaultFontPixelHeight * 1.7)
            fact:                   thresholdFact
            visible:                thresholdFact !== null
        }
    }

    // ==========================================================
    // Panel
    // ==========================================================
    Rectangle {
        id: panel

        width:  Math.min(_compact ? 480 : 560, root.width - Math.round(_m * 4))

        // Hündürlük məzmuna görədir — altda boş sahə qalmasın
        readonly property real _wantedH: titleBar.height + contentCol.implicitHeight + _m * 2
        height: Math.min(_wantedH, root.height - Math.round(_m * 4))

        color:  "#2A2A2A"
        radius: 12
        border.width: 1
        border.color: "#6E6E6E"
        clip:   true

        // Panelin özünə klik onu bağlamasın və arxaya da keçməsin
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            preventStealing: true
            onWheel: (wheel) => { wheel.accepted = true }
            onPressed: (mouse) => { mouse.accepted = true }
            onReleased: (mouse) => { mouse.accepted = true }
            onClicked: (mouse) => { mouse.accepted = true }
        }

        // ================= Başlıq =================
        Item {
            id: titleBar
            width: parent.width
            height: Math.max(44, ScreenTools.defaultFontPixelHeight * 2.4)
            anchors.top: parent.top

            QGCLabel {
                anchors.centerIn: parent
                text:             qsTr("Batareya Tənzimləmələri")
                color:            "#FFFFFF"
                font.bold:        true
            }

            Rectangle {
                width:  28; height: 28
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                anchors.right:          parent.right
                anchors.rightMargin:    10
                color: closeMouse.containsMouse ? "#4A4848" : "transparent"

                Behavior on color { ColorAnimation { duration: 110 } }

                Image {
                    source:  _azIconBase + "TopStatusPanel_Cixis.svg"
                    width:   18; height: 18
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.close()
                }
            }

            Rectangle {
                anchors.left:        parent.left
                anchors.right:       parent.right
                anchors.bottom:      parent.bottom
                anchors.leftMargin:  _m
                anchors.rightMargin: _m
                height: 1
                color:  "#4A4A4A"
            }
        }

        QGCFlickable {
            id: contentFlick
            anchors.top:        titleBar.bottom
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            anchors.margins:    _m
            clip:               true
            flickableDirection: Flickable.VerticalFlick
            contentWidth:       width
            contentHeight:      contentCol.implicitHeight

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id:      contentCol
                width:   contentFlick.width
                spacing: Math.max(8, _m * 0.8)

                // ---------------- Göstərilən dəyər ----------------
                GroupTitle { title: qsTr("Batareya Göstəricisi") }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: displayCol.implicitHeight + _m * 1.4
                    radius: 10
                    color:  "#1E1E1E"
                    border.width: 1
                    border.color: "#4A4A4A"

                    ColumnLayout {
                        id: displayCol
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: _m * 0.7
                        spacing:         Math.max(6, _m * 0.6)

                        SettingRow {
                            Layout.fillWidth:       true
                            Layout.preferredHeight: _rowH
                            label: qsTr("Göstərilən dəyər")
                            pad:   _m
                            ctrlW: _ctrlW
                            rowH:  _rowH

                            FactComboBox {
                                anchors.fill:   parent
                                fact:           _batterySettings.valueDisplay
                                indexModel:     false
                                sizeToContents: false
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            Layout.topMargin: 2
                            text:  qsTr("Rəngləmə")
                            color: "#B9B9B9"
                        }

                        // Rəng pillələri — 100% / həd1 / həd2 / aşağı / kritik
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Math.max(4, _m * 0.3)
                            spacing:          Math.max(10, _m)

                            ColorStep {
                                Layout.fillWidth: true
                                iconSource: "/qmlimages/BatteryGreen.svg"
                                iconColor:  qgcPal.colorGreen
                                caption:    qsTr("100%")
                            }

                            ColorStep {
                                Layout.fillWidth: true
                                iconSource:    "/qmlimages/BatteryYellowGreen.svg"
                                iconColor:     qgcPal.colorYellowGreen
                                thresholdFact: _batterySettings.threshold1
                            }

                            ColorStep {
                                Layout.fillWidth: true
                                iconSource:    "/qmlimages/BatteryYellow.svg"
                                iconColor:     qgcPal.colorYellow
                                thresholdFact: _batterySettings.threshold2
                            }

                            ColorStep {
                                Layout.fillWidth: true
                                iconSource: "/qmlimages/BatteryOrange.svg"
                                iconColor:  qgcPal.colorOrange
                                caption:    qsTr("Aşağı")
                            }

                            ColorStep {
                                Layout.fillWidth: true
                                iconSource: "/qmlimages/BatteryCritical.svg"
                                iconColor:  qgcPal.colorRed
                                caption:    qsTr("Kritik")
                            }
                        }
                    }
                }

                // ---------------- Aşağı batareya failsafe ----------------
                GroupTitle {
                    title:   qsTr("Aşağı Batareya Failsafe")
                    visible: _activeVehicle
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: failsafeCol.implicitHeight + _m * 1.4
                    radius: 10
                    color:  "#1E1E1E"
                    border.width: 1
                    border.color: "#4A4A4A"
                    visible: _activeVehicle

                    ColumnLayout {
                        id: failsafeCol
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: _m * 0.7
                        spacing:         Math.max(6, _m * 0.6)

                        SettingRow {
                            Layout.fillWidth:       true
                            Layout.preferredHeight: _rowH
                            label: qsTr("Təyyarə Hərəkəti")
                            pad:   _m
                            ctrlW: _ctrlW
                            rowH:  _rowH
                            visible: lowBatActCombo.fact !== null

                            FactComboBox {
                                id:             lowBatActCombo
                                anchors.fill:   parent
                                fact:           controller.getParameterFact(-1, "COM_LOW_BAT_ACT", false)
                                indexModel:     false
                                sizeToContents: false
                            }
                        }

                        FactSlider {
                            Layout.fillWidth:  true
                            label:             qsTr("Xəbərdarlıq Səviyyəsi")
                            fact:              controller.getParameterFact(-1, "BAT_LOW_THR", false)
                            visible:           fact !== null
                            majorTickStepSize: 5
                        }

                        FactSlider {
                            Layout.fillWidth:  true
                            label:             qsTr("Kritik Səviyyə")
                            fact:              controller.getParameterFact(-1, "BAT_CRIT_THR", false)
                            visible:           fact !== null
                            majorTickStepSize: 5
                        }

                        FactSlider {
                            Layout.fillWidth:  true
                            label:             qsTr("Fövqəladə Səviyyə")
                            fact:              controller.getParameterFact(-1, "BAT_EMERGEN_THR", false)
                            visible:           fact !== null
                            majorTickStepSize: 5
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            text:     qsTr("Failsafe parametrləri təyyarədən oxunmayıb.")
                            color:    "#B9B9B9"
                            wrapMode: Text.WordWrap
                            visible:  lowBatActCombo.fact === null
                        }
                    }
                }

                // ---------------- Enerji konfiqurasiyası ----------------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: _rowH
                    Layout.bottomMargin: _m
                    radius: 10
                    color:  "#1E1E1E"
                    border.width: 1
                    border.color: "#4A4A4A"
                    visible: _activeVehicle

                    RowLayout {
                        anchors.fill:        parent
                        anchors.leftMargin:  _m
                        anchors.rightMargin: _m
                        spacing:             _m * 0.6

                        QGCLabel {
                            Layout.fillWidth: true
                            text:  qsTr("Təyyarə Enerjisi")
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                        }

                        QGCButton {
                            text: qsTr("Konfiqurasiya et")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            onClicked: {
                                root.close()
                                // Aparat Qurğusu → Enerji (menyu idx 6)
                                mainWindow.showVehicleSetupPage(6)
                            }
                        }
                    }
                }
            }
        }
    }

    QGCPalette { id: qgcPal }
}

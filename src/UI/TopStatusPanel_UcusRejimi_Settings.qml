import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

/// Uçuş rejimi tənzimləmələri — RTL hündürlüyü, GeoFence və rejim siyahısının idarəsi.
/// Məzmun PX4FlightModeIndicator.qml / FlightModeIndicator.qml ilə eynidir,
/// yalnız TopStatusPanel-in öz panel dizaynına salınıb (Batareya paneli kimi).
Rectangle {
    id: root

    anchors.fill: parent
    color: "#00000040"
    z: 100
    visible: true

    // TopStatusPanel-dən ötürülənlər
    property Item anchorItem: null
    property Item topPanelItem: null

    property var _activeVehicle:      QGroundControl.multiVehicleManager.activeVehicle
    property var _flightModeSettings: QGroundControl.settingsManager.flightModeSettings
    property var _flyViewSettings:    QGroundControl.settingsManager.flyViewSettings

    property bool _px4:     _activeVehicle && _activeVehicle.px4Firmware
    property bool _apm:     _activeVehicle && _activeVehicle.apmFirmware

    readonly property string _azIconBase: "qrc:/res/AZSHIELD_ICON/"

    readonly property bool _compact: (width < 900) || (height < 650)
    readonly property real _m:       Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.65 : 0.85))
    readonly property real _rowH:    Math.max(40, ScreenTools.defaultFontPixelHeight * 2.2)
    readonly property real _ctrlW:   Math.max(120, Math.min(190, panel.width * 0.36))

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

    onWidthChanged:          Qt.callLater(reposition)
    onHeightChanged:         Qt.callLater(reposition)
    Connections {
        target: panel
        function onHeightChanged() { Qt.callLater(root.reposition) }
    }
    onAnchorItemChanged:     Qt.callLater(reposition)

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
    // Təkrar istifadə olunan sətir
    // ==========================================================
    component SettingRow: Rectangle {
        id: srow

        property alias label:  srowLabel.text
        property real  pad:    10
        property real  ctrlW:  150
        property real  rowH:   40
        default property alias content: srowContent.data

        // ColumnLayout daxilində ölçü Layout-dan gəlir, ona görə implicit ölçülər
        // verilir — əks halda sətir 0 hündürlükdə qalır və görünmür.
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

    // ==========================================================
    // Panel
    // ==========================================================
    Rectangle {
        id: panel

        width:  Math.min(_compact ? 460 : 520, root.width  - Math.round(_m * 4))

        // Hündürlük məzmuna görədir — altda boş sahə qalmasın; yalnız ekrana
        // sığmayanda maksimuma dayanır və daxildə scroll açılır.
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
                text:             qsTr("Uçuş Rejimi Tənzimləmələri")
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
            anchors.top:         titleBar.bottom
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.bottom:      parent.bottom
            anchors.margins:     _m
            clip:                true
            flickableDirection:  Flickable.VerticalFlick
            contentWidth:        width
            contentHeight:       contentCol.implicitHeight

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id:      contentCol
                width:   contentFlick.width
                spacing: Math.max(8, _m * 0.8)

                // ---------------- Təyyarə yoxdur ----------------
                QGCLabel {
                    Layout.fillWidth:    true
                    Layout.topMargin:    _m
                    text:                qsTr("Tənzimləmələr üçün təyyarə qoşulmalıdır.")
                    color:               "#B9B9B9"
                    wrapMode:            Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    visible:             !_activeVehicle
                }

                // ---------------- RTL hündürlüyü ----------------
                GroupTitle {
                    title:   qsTr("Evə Qayıtma")
                    visible: _activeVehicle && _px4
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: rtlCol.implicitHeight + _m * 1.4
                    radius:  10
                    color:   "#1E1E1E"
                    border.width: 1
                    border.color: "#4A4A4A"
                    visible: _activeVehicle && _px4

                    ColumnLayout {
                        id: rtlCol
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        anchors.top:        parent.top
                        anchors.margins:    _m * 0.7
                        spacing:            4

                        FactSlider {
                            Layout.fillWidth:  true
                            label:             qsTr("RTL Hündürlüyü")
                            fact:              controller.getParameterFact(-1, "RTL_RETURN_ALT", false)
                            visible:           fact !== null
                            to:                (fact && fact.maxIsDefaultForType)
                                               ? QGroundControl.unitsConversion.metersToAppSettingsVerticalDistanceUnits(121.92)
                                               : (fact ? fact.max : 100)
                            majorTickStepSize: 10
                        }
                    }
                }

                // ---------------- GeoFence ----------------
                GroupTitle {
                    title:   qsTr("GeoFence")
                    visible: _activeVehicle && _px4
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: fenceCol.implicitHeight + _m * 1.4
                    radius:  10
                    color:   "#1E1E1E"
                    border.width: 1
                    border.color: "#4A4A4A"
                    visible: _activeVehicle && _px4

                    ColumnLayout {
                        id: fenceCol
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: _m * 0.7
                        spacing:         Math.max(6, _m * 0.6)

                        SettingRow {
                            Layout.fillWidth:       true
                            Layout.preferredHeight: _rowH
                            label:  qsTr("Pozuntu Hərəkəti")
                            pad:    _m
                            ctrlW:  _ctrlW
                            rowH:   _rowH

                            FactComboBox {
                                anchors.fill:   parent
                                fact:           controller.getParameterFact(-1, "GF_ACTION", false)
                                indexModel:     false
                                sizeToContents: false
                                visible:        fact !== null
                            }
                        }

                        // Maksimum məsafə
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true

                                QGCLabel {
                                    Layout.fillWidth: true
                                    text:  qsTr("Maksimum Məsafə")
                                    color: "#FFFFFF"
                                }

                                QGCCheckBoxSlider {
                                    id:      maxDistanceEnable
                                    checked: maxDistanceSlider.fact && maxDistanceSlider.fact.value > 0

                                    property real prevValue: 0

                                    onClicked: {
                                        if (!maxDistanceSlider.fact) {
                                            return
                                        }
                                        if (checked) {
                                            maxDistanceSlider.setValue(prevValue !== 0 ? prevValue : maxDistanceSlider.to)
                                        } else {
                                            prevValue = maxDistanceSlider.value
                                            maxDistanceSlider.setValue(0)
                                        }
                                    }
                                }
                            }

                            FactSlider {
                                id:                maxDistanceSlider
                                Layout.fillWidth:  true
                                fact:              controller.getParameterFact(-1, "GF_MAX_HOR_DIST", false)
                                visible:           fact !== null
                                to:                _flyViewSettings.maxGoToLocationDistance.value
                                majorTickStepSize: 500
                                enabled:           fact && fact.value > 0
                            }
                        }

                        // Maksimum hündürlük
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true

                                QGCLabel {
                                    Layout.fillWidth: true
                                    text:  qsTr("Maksimum Hündürlük")
                                    color: "#FFFFFF"
                                }

                                QGCCheckBoxSlider {
                                    id:      maxAltitudeEnable
                                    checked: maxAltitudeSlider.fact && maxAltitudeSlider.fact.value > 0

                                    property real prevValue: 0

                                    onClicked: {
                                        if (!maxAltitudeSlider.fact) {
                                            return
                                        }
                                        if (checked) {
                                            maxAltitudeSlider.setValue(prevValue !== 0 ? prevValue : maxAltitudeSlider.to)
                                        } else {
                                            prevValue = maxAltitudeSlider.value
                                            maxAltitudeSlider.setValue(0)
                                        }
                                    }
                                }
                            }

                            FactSlider {
                                id:                maxAltitudeSlider
                                Layout.fillWidth:  true
                                fact:              controller.getParameterFact(-1, "GF_MAX_VER_DIST", false)
                                visible:           fact !== null
                                to:                _flyViewSettings.guidedMaximumAltitude.value
                                majorTickStepSize: 10
                                enabled:           fact && fact.value > 0
                            }
                        }
                    }
                }

                // ---------------- Ətraflı konfiqurasiya ----------------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: _rowH
                    Layout.bottomMargin: _m
                    radius:  10
                    color:   "#1E1E1E"
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
                            text:  qsTr("Uçuş Rejimləri")
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                        }

                        QGCButton {
                            text: qsTr("Konfiqurasiya et")
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            onClicked: {
                                root.close()
                                // Aparat Qurğusu → Uçuş Rejimləri (menyu idx 4)
                                mainWindow.showVehicleSetupPage(4)
                            }
                        }
                    }
                }
            }
        }
    }
}

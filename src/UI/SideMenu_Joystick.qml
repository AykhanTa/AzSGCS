import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "black"

    // Palette (qgcPal istifadə edirsən deyə təhlükəsiz olsun)
    QGCPalette {
        id: qgcPal
        colorGroupEnabled: true
    }

    // ======================
    // Responsive
    // ======================
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property bool _stacked: (width < 1000) || ScreenTools.isShortScreen

    readonly property real _m:    Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.70 : 1.0))
    readonly property real _side: Math.max(12, _m * 0.9)
    readonly property real _maxContentW: 1700

    readonly property int  _tabCols: _stacked ? ((width < 520) ? 1 : 2) : 4
    readonly property real _tabSpacing: Math.max(8, _m * 0.6)
    readonly property int  _tabH: Math.max(36, Math.round(ScreenTools.defaultFontPixelHeight * (_compact ? 2.0 : 2.4)))

    readonly property real axisMonitorWidth: ScreenTools.defaultFontPixelWidth * 32

    // ======================
    // Backend state
    // ======================
    property var  _activeJoystick: joystickManager.activeJoystick
    property bool _buttonsOnly: _activeJoystick ? (_activeJoystick.axisCount === 0) : false
    property bool _requiresCalibration: _activeJoystick ? (!_activeJoystick.calibrated && !_buttonsOnly) : false

    // ✅ TƏK controller (General + Calibration + Advanced üçün)
    JoystickConfigController {
        id: controller
    }

    // ======================
    // Tab state
    // ======================
    property int selectedButton: 0 // 0: General, 1: Button Assignment, 2: Calibration, 3: Advanced
    function selectButton(buttonIndex) {
        selectedButton = buttonIndex
        console.log("Selected button:", buttonIndex)
    }

    readonly property var _tabs: [
        { idx: 0, label: qsTr("Ümumi") },
        { idx: 1, label: qsTr("Düymə Təyinatı") },
        { idx: 2, label: qsTr("Kalibrasiya") },
        { idx: 3, label: qsTr("Qabaqcıl") }
    ]

    // ======================
    // Map/empty-area blocker
    // ======================
    MouseArea {
        anchors.fill: parent
        z: 1
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onWheel: (wheel) => { wheel.accepted = true }
    }

    // ======================
    // Outer scroll
    // ======================
    QGCFlickable {
        id: pageFlick
        z: 2
        anchors.fill: parent
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        contentWidth: width
        //contentHeight: contentCol.implicitHeight + root._side

        // Scroll yalnız həqiqətən lazım olanda işləsin (fit olanda yox)
        readonly property real _scrollTol: 2   // 1-2px overflow üçün tolerans
        contentHeight: (contentCol.implicitHeight <= height + _scrollTol) ? height : contentCol.implicitHeight
        interactive:  contentCol.implicitHeight > height + _scrollTol

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        ColumnLayout {
            id: contentCol
            width: Math.min(pageFlick.width - (root._side * 2), root._maxContentW)
            x: (pageFlick.width - width) / 2
            spacing: root._m

            // ======================
            // Header
            // ======================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: root._compact ? 2 : 6

                Text {
                    text: qsTr("Joystick Konfiqurasiyası")
                    color: "white"
                    font.bold: true
                    font.pixelSize: root._compact ? 22 : 26
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Optimal uçuş nəzarəti üçün nəzarətçi parametrlərinizi konfiqurasiya edin")
                    color: "#E8E8E8"
                    font.pixelSize: root._compact ? 13 : 16
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ======================
            // Tabs
            // ======================
            Rectangle {
                id: tabBar
                Layout.fillWidth: true
                color: "#2A2A2A"
                radius: 16

                readonly property real pad: Math.max(8, root._m * 0.8)
                implicitHeight: tabFlow.implicitHeight + pad * 2

                Flow {
                    id: tabFlow
                    width: tabBar.width - tabBar.pad * 2
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: tabBar.pad
                    spacing: root._tabSpacing

                    Repeater {
                        model: root._tabs

                        Rectangle {
                            id: tabBtn
                            height: root._tabH
                            radius: height / 2

                            readonly property int tabIndex: modelData.idx
                            readonly property bool isSelected: root.selectedButton === tabIndex

                            width: Math.max(
                                       ScreenTools.defaultFontPixelWidth * 14,
                                       Math.floor((tabFlow.width - tabFlow.spacing * (root._tabCols - 1)) / root._tabCols)
                                   )

                            color: isSelected ? "#232222" : "#2A2A2A"
                            border.width: isSelected ? 2 : 1
                            border.color: "white"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: "#E8E8E8"
                                font.pixelSize: root._compact ? 14 : 16
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: { if (!tabBtn.isSelected) tabBtn.color = "#232222" }
                                onExited:  { if (!tabBtn.isSelected) tabBtn.color = "#2A2A2A" }
                                onClicked: root.selectButton(tabBtn.tabIndex)
                            }
                        }
                    }
                }
            }

            // ======================
            // Panels
            // ======================
            Loader {
                id: panelLoader
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                Layout.minimumHeight:  Layout.preferredHeight

                sourceComponent: root.selectedButton === 0 ? generalPanelComp
                               : root.selectedButton === 1 ? buttonAssignComp
                               : root.selectedButton === 2 ? calibrationComp
                               : advancedComp
            }

            Item { Layout.preferredHeight: root._m; Layout.fillWidth: true }
        }
    }

    // ============================================================
    // GENERAL PANEL
    // ============================================================
    Component {
        id: generalPanelComp

        Item {
            width: panelLoader.width
            implicitHeight: generalCol.implicitHeight

            ColumnLayout {
                id: generalCol
                width: parent.width
                spacing: root._m

                GridLayout {
                    id: topCardsGrid
                    Layout.fillWidth: true
                    columns: (root._stacked || root._buttonsOnly) ? 1 : 2
                    columnSpacing: root._m
                    rowSpacing: root._m

                    property real rowH: (columns === 2)
                                        ? Math.max(controlCard.implicitHeight, axisCard.implicitHeight)
                                        : 0

                    // --------------------------
                    // Control Setup Card
                    // --------------------------
                    Rectangle {
                        id: controlCard
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        Layout.fillHeight: topCardsGrid.columns === 2
                        Layout.preferredHeight: (topCardsGrid.columns === 2) ? topCardsGrid.rowH : implicitHeight

                        color: "#3D3B3B"
                        radius: 16
                        border.width: 1
                        border.color: "#9D9D9D"

                        readonly property real pad: root._m
                        implicitHeight: controlCol.implicitHeight + pad * 2

                        ColumnLayout {
                            id: controlCol
                            anchors.fill: parent
                            anchors.margins: parent.pad
                            spacing: Math.max(10, root._m * 0.85)

                            Text {
                                text: qsTr("Nəzarət Quraşdırması")
                                color: "white"
                                font.pixelSize: root._compact ? 15 : 16
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            // Enable joystick
                            Rectangle {
                                Layout.fillWidth: true
                                color: "#3D3B3B"
                                radius: 14
                                border.width: 1
                                border.color: "#9D9D9D"
                                implicitHeight: Math.max(48, ScreenTools.defaultFontPixelHeight * (root._compact ? 2.6 : 3.0))

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: root._requiresCalibration
                                              ? qsTr("Aktivləşdirməyə icazə verilmir (Əvvəlcə Kalibrlə)")
                                              : qsTr("Joystik daxiletməsini aktiv edin")
                                        color: root._requiresCalibration ? "#FF6B6B" : "white"
                                        font.pixelSize: root._compact ? 13 : 16
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                    }

                                    // ON/OFF toggle
                                    Rectangle {
                                        id: toggleSwitch
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 25
                                        radius: 17
                                        color: enabledSwitch.checked ? "#4CAF50" : "#F44336"
                                        border.color: enabledSwitch.checked ? "#45a049" : "#d32f2f"
                                        border.width: 2
                                        enabled: !root._requiresCalibration
                                        opacity: enabled ? 1.0 : 0.5

                                        Rectangle {
                                            width: 13
                                            height: 13
                                            radius: 13
                                            color: "white"
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: enabledSwitch.checked ? parent.width - width - 4 : 4
                                            Behavior on x { NumberAnimation { duration: 200 } }
                                        }

                                        Text {
                                            text: "ON"
                                            color: "white"
                                            font.pixelSize: 12
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: 12
                                            visible: enabledSwitch.checked
                                        }

                                        Text {
                                            text: "OFF"
                                            color: "white"
                                            font.pixelSize: 12
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: parent.width - width - 12
                                            visible: !enabledSwitch.checked
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: parent.enabled
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!root._requiresCalibration) {
                                                    enabledSwitch.checked = !enabledSwitch.checked
                                                    globals.activeVehicle.joystickEnabled = enabledSwitch.checked
                                                    globals.activeVehicle.saveJoystickSettings()
                                                }
                                            }
                                        }
                                    }

                                    // hidden state holder
                                    QGCCheckBox {
                                        id: enabledSwitch
                                        visible: false

                                        Component.onCompleted: checked = globals.activeVehicle.joystickEnabled

                                        Connections {
                                            target: globals.activeVehicle
                                            onJoystickEnabledChanged: enabledSwitch.checked = globals.activeVehicle.joystickEnabled
                                        }

                                        Connections {
                                            target: joystickManager
                                            onActiveJoystickChanged: {
                                                if (root._activeJoystick) {
                                                    enabledSwitch.checked = root._activeJoystick.calibrated && globals.activeVehicle.joystickEnabled
                                                } else {
                                                    enabledSwitch.checked = globals.activeVehicle.joystickEnabled
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Active joystick selection
                            Rectangle {
                                Layout.fillWidth: true
                                color: "#2A2A2A"
                                radius: 14
                                implicitHeight: Math.max(50, ScreenTools.defaultFontPixelHeight * 3.0)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Text {
                                        text: qsTr("Aktiv joystik:")
                                        color: "white"
                                        font.pixelSize: root._compact ? 14 : 16
                                        font.bold: true
                                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 16
                                        elide: Text.ElideRight
                                    }

                                    QGCComboBox {
                                        id: joystickCombo
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        model: joystickManager.joystickNames

                                        onActivated: function(index) {
                                            joystickManager.activeJoystickName = textAt(index)
                                        }

                                        Component.onCompleted: {
                                            var idx = joystickCombo.find(joystickManager.activeJoystickName)
                                            if (idx >= 0) joystickCombo.currentIndex = idx
                                        }

                                        Connections {
                                            target: joystickManager
                                            onAvailableJoysticksChanged: {
                                                var idx = joystickCombo.find(joystickManager.activeJoystickName)
                                                if (idx >= 0) joystickCombo.currentIndex = idx
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: qsTr("RC rejimi seçimi:")
                                color: "white"
                                font.pixelSize: root._compact ? 16 : 18
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Flow {
                                Layout.fillWidth: true
                                width: parent.width
                                spacing: Math.max(10, ScreenTools.defaultFontPixelWidth)

                                QGCRadioButton {
                                    text: qsTr("Rejim 1")
                                    checked: controller.transmitterMode === 1
                                    enabled: !controller.calibrating
                                    onClicked: controller.transmitterMode = 1
                                }
                                QGCRadioButton {
                                    text: qsTr("Rejim 2")
                                    checked: controller.transmitterMode === 2
                                    enabled: !controller.calibrating
                                    onClicked: controller.transmitterMode = 2
                                }
                                QGCRadioButton {
                                    text: qsTr("Rejim 3")
                                    checked: controller.transmitterMode === 3
                                    enabled: !controller.calibrating
                                    onClicked: controller.transmitterMode = 3
                                }
                                QGCRadioButton {
                                    text: qsTr("Rejim 4")
                                    checked: controller.transmitterMode === 4
                                    enabled: !controller.calibrating
                                    onClicked: controller.transmitterMode = 4
                                }
                            }

                            Item { Layout.fillHeight: true; Layout.fillWidth: true }
                        }
                    }

                    // --------------------------
                    // Axis Configuration Card
                    // --------------------------
                    Rectangle {
                        id: axisCard
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        Layout.fillHeight: topCardsGrid.columns === 2
                        Layout.preferredHeight: (topCardsGrid.columns === 2) ? topCardsGrid.rowH : implicitHeight

                        visible: !root._buttonsOnly

                        color: "#3D3B3B"
                        radius: 16
                        border.width: 1
                        border.color: "#9D9D9D"

                        readonly property real pad: root._m
                        implicitHeight: axisCol.implicitHeight + pad * 2

                        ColumnLayout {
                            id: axisCol
                            anchors.fill: parent
                            anchors.margins: parent.pad
                            spacing: Math.max(10, root._m * 0.85)

                            Text {
                                text: qsTr("Ox Konfiqurasiyası")
                                color: "white"
                                font.pixelSize: root._compact ? 15 : 16
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            // ---- Roll ----
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text { text: qsTr("Roll"); color: "white"; font.pixelSize: 16 }

                                Slider {
                                    id: rollSlider
                                    Layout.fillWidth: true
                                    height: 18
                                    from: 0; to: 100
                                    value: Math.round((rollAxis.axisValue / 32768.0) * 50 + 50)
                                    enabled: false

                                    background: Rectangle {
                                        x: rollSlider.leftPadding
                                        y: rollSlider.height/2 - height/2
                                        width: rollSlider.availableWidth
                                        height: 12
                                        radius: height/2
                                        color: "#707070"
                                    }
                                    handle: Rectangle {
                                        width: 14; height: 14; radius: 7
                                        color: "white"; border.color: "#9D9D9D"; border.width: 1
                                        y: rollSlider.height/2 - height/2
                                        x: rollSlider.leftPadding + rollSlider.visualPosition * (rollSlider.availableWidth - width)
                                    }
                                }

                                Text {
                                    text: rollSlider.value
                                    color: "white"
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }
                            }

                            // ---- Pitch ----
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text { text: qsTr("Pitch"); color: "white"; font.pixelSize: 16 }

                                Slider {
                                    id: pitchSlider
                                    Layout.fillWidth: true
                                    height: 18
                                    from: 0; to: 100
                                    value: Math.round((pitchAxis.axisValue / 32768.0) * 50 + 50)
                                    enabled: false

                                    background: Rectangle {
                                        x: pitchSlider.leftPadding
                                        y: pitchSlider.height/2 - height/2
                                        width: pitchSlider.availableWidth
                                        height: 12
                                        radius: height/2
                                        color: "#707070"
                                    }
                                    handle: Rectangle {
                                        width: 14; height: 14; radius: 7
                                        color: "white"; border.color: "#9D9D9D"; border.width: 1
                                        y: pitchSlider.height/2 - height/2
                                        x: pitchSlider.leftPadding + pitchSlider.visualPosition * (pitchSlider.availableWidth - width)
                                    }
                                }

                                Text {
                                    text: pitchSlider.value
                                    color: "white"
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }
                            }

                            // ---- Yaw ----
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text { text: qsTr("Yaw"); color: "white"; font.pixelSize: 16 }

                                Slider {
                                    id: yawSlider
                                    Layout.fillWidth: true
                                    height: 18
                                    from: 0; to: 100
                                    value: Math.round((yawAxis.axisValue / 32768.0) * 50 + 50)
                                    enabled: false

                                    background: Rectangle {
                                        x: yawSlider.leftPadding
                                        y: yawSlider.height/2 - height/2
                                        width: yawSlider.availableWidth
                                        height: 12
                                        radius: height/2
                                        color: "#707070"
                                    }
                                    handle: Rectangle {
                                        width: 14; height: 14; radius: 7
                                        color: "white"; border.color: "#9D9D9D"; border.width: 1
                                        y: yawSlider.height/2 - height/2
                                        x: yawSlider.leftPadding + yawSlider.visualPosition * (yawSlider.availableWidth - width)
                                    }
                                }

                                Text {
                                    text: yawSlider.value
                                    color: "white"
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }
                            }

                            // ---- Throttle ----
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text { text: qsTr("Throttle"); color: "white"; font.pixelSize: 16 }

                                Slider {
                                    id: throttleSlider
                                    Layout.fillWidth: true
                                    height: 18
                                    from: 0; to: 100
                                    value: Math.round((throttleAxis.axisValue / 32768.0) * 50 + 50)
                                    enabled: false

                                    background: Rectangle {
                                        x: throttleSlider.leftPadding
                                        y: throttleSlider.height/2 - height/2
                                        width: throttleSlider.availableWidth
                                        height: 12
                                        radius: height/2
                                        color: "#707070"
                                    }
                                    handle: Rectangle {
                                        width: 14; height: 14; radius: 7
                                        color: "white"; border.color: "#9D9D9D"; border.width: 1
                                        y: throttleSlider.height/2 - height/2
                                        x: throttleSlider.leftPadding + throttleSlider.visualPosition * (throttleSlider.availableWidth - width)
                                    }
                                }

                                Text {
                                    text: throttleSlider.value
                                    color: "white"
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }
                            }

                            // Hidden monitors (səndə işləyən backend qalır)
                            AxisMonitor {
                                id: rollAxis
                                visible: false
                                mapped: root._activeJoystick ? root._activeJoystick.axisMapped[0] : false
                                reversed: root._activeJoystick ? root._activeJoystick.axisReversed[0] : false
                                axisValue: 0
                            }
                            AxisMonitor {
                                id: pitchAxis
                                visible: false
                                mapped: root._activeJoystick ? root._activeJoystick.axisMapped[1] : false
                                reversed: root._activeJoystick ? root._activeJoystick.axisReversed[1] : false
                                axisValue: 0
                            }
                            AxisMonitor {
                                id: yawAxis
                                visible: false
                                mapped: root._activeJoystick ? root._activeJoystick.axisMapped[2] : false
                                reversed: root._activeJoystick ? root._activeJoystick.axisReversed[2] : false
                                axisValue: 0
                            }
                            AxisMonitor {
                                id: throttleAxis
                                visible: false
                                mapped: root._activeJoystick ? root._activeJoystick.axisMapped[3] : false
                                reversed: root._activeJoystick ? root._activeJoystick.axisReversed[3] : false
                                axisValue: 0
                            }

                            // ✅ getAxis YOXDUR -> axisValues siqnalı ilə işlət (qoyduğun kimi qalır)
                            Connections {
                                target: root._activeJoystick
                                enabled: root._activeJoystick !== null
                                onAxisValues: function(roll, pitch, yaw, throttle) {
                                    rollAxis.axisValue  = roll  * 32768.0
                                    pitchAxis.axisValue = pitch * 32768.0
                                    yawAxis.axisValue   = yaw   * 32768.0

                                    throttleAxis.axisValue = (root._activeJoystick && root._activeJoystick.negativeThrust)
                                                             ? (throttle * -32768.0)
                                                             : ((-2 * throttle + 1) * 32768.0)
                                }
                            }

                            Item { Layout.fillHeight: true; Layout.fillWidth: true }
                        }
                    }

                }

                // --------------------------
                // Button Mapping Card
                // --------------------------
                Rectangle {
                    Layout.fillWidth: true
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"

                    readonly property real pad: root._m
                    implicitHeight: mapCol.implicitHeight + pad * 2

                    ColumnLayout {
                        id: mapCol
                        anchors.fill: parent
                        anchors.margins: parent.pad
                        spacing: root._m

                        Text {
                            text: qsTr("Düymə Xəritəçəkmə")
                            color: "white"
                            font.pixelSize: root._compact ? 15 : 16
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Item {
                            id: mapGridArea
                            Layout.fillWidth: true

                            readonly property real gridSpacing: root._stacked ? Math.max(8, root._m * 0.8) : Math.max(10, root._m)
                            readonly property real minCell: root._compact ? 56 : 72

                            readonly property int cols: {
                                var c = Math.floor((width + gridSpacing) / (minCell + gridSpacing))
                                c = Math.max(4, Math.min(10, c))
                                return c
                            }

                            readonly property real cellW: Math.floor((width - gridSpacing * (cols - 1)) / cols)
                            readonly property real cellH: root._compact ? 36 : 44

                            implicitHeight: buttonMappingGrid.implicitHeight

                            Grid {
                                id: buttonMappingGrid
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: mapGridArea.cols * mapGridArea.cellW + mapGridArea.gridSpacing * (mapGridArea.cols - 1)
                                columns: mapGridArea.cols
                                spacing: mapGridArea.gridSpacing

                                Repeater {
                                    id: buttonMonitorRepeater
                                    model: 24

                                    Rectangle {
                                        width: mapGridArea.cellW
                                        height: mapGridArea.cellH
                                        radius: 10

                                        property bool pressed: false

                                        border.width: 1
                                        border.color: pressed ? qgcPal.buttonHighlight : "#9D9D9D"
                                        color: pressed ? qgcPal.buttonHighlight : "#888585"

                                        QGCLabel {
                                            anchors.fill: parent
                                            color: pressed ? qgcPal.buttonHighlightText : "#FFFFFF"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: index
                                            font.pixelSize: root._compact ? 15 : 18
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }

                        Connections {
                            target: root._activeJoystick
                            enabled: root._activeJoystick !== null
                            onRawButtonPressedChanged: function(index, pressed) {
                                var it = buttonMonitorRepeater.itemAt(index)
                                if (it) it.pressed = pressed
                            }
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // BUTTON ASSIGNMENT PANEL (sənin son işlək variantındakı kimi saxlanılıb)
    // ============================================================
    Component {
        id: buttonAssignComp

        Item {
            width: panelLoader.width
            implicitHeight: assignCard.implicitHeight

            Rectangle {
                id: assignCard
                width: parent.width
                color: "#3D3B3B"
                radius: 16
                border.width: 1
                border.color: "#9D9D9D"

                readonly property real pad: root._m
                implicitHeight: assignCol.implicitHeight + pad * 2

                ColumnLayout {
                    id: assignCol
                    anchors.fill: parent
                    anchors.margins: assignCard.pad
                    spacing: root._m

                    Text {
                        text: qsTr("Fəaliyyəti çağırmaq üçün eyni hərəkətə malik bir neçə düymə eyni vaxtda basılmalıdır")
                        color: "#E8E8E8"
                        font.pixelSize: root._compact ? 13 : 16
                        font.bold: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        id: assignGrid
                        Layout.fillWidth: true
                        columns: root._stacked ? 1 : 2
                        columnSpacing: root._m
                        rowSpacing: Math.max(10, root._m * 0.8)

                        Repeater {
                            id: buttonRowRepeater
                            model: 24

                            Rectangle {
                                id: rowRect
                                Layout.fillWidth: true
                                radius: 8
                                border.width: 1
                                border.color: "#9D9D9D"

                                property int  buttonIndex: index
                                property bool pressed: false
                                color: pressed ? "#3D3B3B" : "#2A2A2A"

                                property bool _compactRow: root._stacked || (width < 560)

                                implicitHeight: _compactRow
                                                ? Math.max(78, ScreenTools.defaultFontPixelHeight * 4.2)
                                                : Math.max(46, ScreenTools.defaultFontPixelHeight * 2.8)

                                property bool repeatEnabled: false

                                function refreshAction() {
                                    var combo = rowLoader.item ? rowLoader.item.actionCombo : null
                                    if (!combo) return

                                    if (!root._activeJoystick || !root._activeJoystick.buttonActions) {
                                        combo.currentIndex = 0
                                        return
                                    }
                                    var currentAction = root._activeJoystick.buttonActions[buttonIndex]
                                    if (!currentAction) {
                                        combo.currentIndex = 0
                                        return
                                    }
                                    var idx = combo.find(currentAction)
                                    combo.currentIndex = (idx >= 0) ? idx : 0
                                }

                                function refreshRepeat() {
                                    if (root._activeJoystick && root._activeJoystick.calibrated) {
                                        repeatEnabled = root._activeJoystick.getButtonRepeat(buttonIndex)
                                    } else {
                                        repeatEnabled = false
                                    }
                                }

                                Component.onCompleted: {
                                    Qt.callLater(function() {
                                        refreshAction()
                                        refreshRepeat()
                                    })
                                }

                                Connections {
                                    target: joystickManager
                                    onActiveJoystickChanged: {
                                        rowRect.refreshAction()
                                        rowRect.refreshRepeat()
                                    }
                                }

                                Connections {
                                    target: root._activeJoystick
                                    enabled: root._activeJoystick !== null
                                    onButtonActionsChanged: rowRect.refreshAction()
                                }

                                Loader {
                                    id: rowLoader
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    sourceComponent: rowRect._compactRow ? rowCompactComp : rowWideComp
                                    onLoaded: {
                                        rowRect.refreshAction()
                                        rowRect.refreshRepeat()
                                    }
                                }

                                Component {
                                    id: rowWideComp

                                    Item {
                                        property alias actionCombo: actionCombo

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 12

                                            Text {
                                                text: qsTr("Düymə %1").arg(rowRect.buttonIndex)
                                                color: "white"
                                                font.pixelSize: 13
                                                font.bold: true
                                                Layout.preferredWidth: Math.max(ScreenTools.defaultFontPixelWidth * 10, implicitWidth)
                                                elide: Text.ElideRight
                                            }

                                            QGCComboBox {
                                                sizeToContents: true
                                                id: actionCombo
                                                Layout.fillWidth: true
                                                Layout.minimumWidth: 180
                                                Layout.preferredHeight: Math.max(30, ScreenTools.defaultFontPixelHeight * 2.0)

                                                model: root._activeJoystick && root._activeJoystick.assignableActionTitles
                                                       ? root._activeJoystick.assignableActionTitles
                                                       : [
                                                           "No Action", "Arm", "Disarm", "Toggle Arm",
                                                           "VTOL: Fixed Wing", "VTOL: Multi-Rotor",
                                                           "Continuous Zoom In", "Continuous Zoom Out",
                                                           "Step Zoom In", "Step Zoom Out",
                                                           "Next Video Stream", "Previous Video Stream",
                                                           "Next Camera", "Previous Camera", "Trigger Camera",
                                                           "Start Recording Video", "Stop Recording Video",
                                                           "Toggle Recording Video", "Gimbal Down", "Gimbal Up",
                                                           "Gimbal Left", "Gimbal Right", "Gimbal Center",
                                                           "Gimbal Yaw Lock", "Gimbal Yaw Follow", "Emergency Stop",
                                                           "Gripper Close", "Gripper Open", "Landing gear deploy",
                                                           "Landing gear retract", "Motor Interlock enable",
                                                           "Motor Interlock disable"
                                                       ]

                                                onActivated: {
                                                    if (root._activeJoystick) {
                                                        var selectedAction = textAt(currentIndex)
                                                        root._activeJoystick.setButtonAction(rowRect.buttonIndex, selectedAction)
                                                    }
                                                }

                                                background: Rectangle {
                                                    color: "#3D3B3B"
                                                    border.color: "#9D9D9D"
                                                    border.width: 1
                                                    radius: 4
                                                }

                                                contentItem: Text {
                                                    text: actionCombo.displayText
                                                    color: "white"
                                                    font.pixelSize: 12
                                                    verticalAlignment: Text.AlignVCenter
                                                    elide: Text.ElideRight
                                                    leftPadding: 10
                                                    rightPadding: 22
                                                }
                                            }

                                            RowLayout {
                                                spacing: 8
                                                Layout.preferredWidth: root._compact ? 110 : 130

                                                Text {
                                                    text: qsTr("Repeat")
                                                    color: "white"
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }

                                                Rectangle {
                                                    width: 40
                                                    height: 16
                                                    radius: 8
                                                    color: rowRect.repeatEnabled ? "#4CAF50" : "#F44336"

                                                    Rectangle {
                                                        width: 12
                                                        height: 12
                                                        radius: 6
                                                        color: "white"
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        x: rowRect.repeatEnabled ? parent.width - width - 2 : 2
                                                        Behavior on x { NumberAnimation { duration: 200 } }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (root._activeJoystick && root._activeJoystick.calibrated) {
                                                                var newState = !rowRect.repeatEnabled
                                                                root._activeJoystick.setButtonRepeat(rowRect.buttonIndex, newState)
                                                                rowRect.repeatEnabled = newState
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Component {
                                    id: rowCompactComp

                                    Item {
                                        property alias actionCombo: actionCombo

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 6

                                            Text {
                                                text: qsTr("Button %1").arg(rowRect.buttonIndex)
                                                color: "white"
                                                font.pixelSize: 13
                                                font.bold: true
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 10

                                                QGCComboBox {
                                                    sizeToContents: true
                                                    id: actionCombo
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 160
                                                    Layout.preferredHeight: Math.max(30, ScreenTools.defaultFontPixelHeight * 2.0)

                                                    model: root._activeJoystick && root._activeJoystick.assignableActionTitles
                                                           ? root._activeJoystick.assignableActionTitles
                                                           : [
                                                               "No Action", "Arm", "Disarm", "Toggle Arm",
                                                               "VTOL: Fixed Wing", "VTOL: Multi-Rotor",
                                                               "Continuous Zoom In", "Continuous Zoom Out",
                                                               "Step Zoom In", "Step Zoom Out",
                                                               "Next Video Stream", "Previous Video Stream",
                                                               "Next Camera", "Previous Camera", "Trigger Camera",
                                                               "Start Recording Video", "Stop Recording Video",
                                                               "Toggle Recording Video", "Gimbal Down", "Gimbal Up",
                                                               "Gimbal Left", "Gimbal Right", "Gimbal Center",
                                                               "Gimbal Yaw Lock", "Gimbal Yaw Follow", "Emergency Stop",
                                                               "Gripper Close", "Gripper Open", "Landing gear deploy",
                                                               "Landing gear retract", "Motor Interlock enable",
                                                               "Motor Interlock disable"
                                                           ]

                                                    onActivated: {
                                                        if (root._activeJoystick) {
                                                            var selectedAction = textAt(currentIndex)
                                                            root._activeJoystick.setButtonAction(rowRect.buttonIndex, selectedAction)
                                                        }
                                                    }

                                                    background: Rectangle {
                                                        color: "#3D3B3B"
                                                        border.color: "#9D9D9D"
                                                        border.width: 1
                                                        radius: 4
                                                    }

                                                    contentItem: Text {
                                                        text: actionCombo.displayText
                                                        color: "white"
                                                        font.pixelSize: 12
                                                        verticalAlignment: Text.AlignVCenter
                                                        elide: Text.ElideRight
                                                        leftPadding: 10
                                                        rightPadding: 22
                                                    }
                                                }

                                                RowLayout {
                                                    spacing: 8
                                                    Layout.preferredWidth: 120

                                                    Text {
                                                        text: qsTr("Təkrarla")
                                                        color: "white"
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }

                                                    Rectangle {
                                                        width: 40
                                                        height: 16
                                                        radius: 8
                                                        color: rowRect.repeatEnabled ? "#4CAF50" : "#F44336"

                                                        Rectangle {
                                                            width: 12
                                                            height: 12
                                                            radius: 6
                                                            color: "white"
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            x: rowRect.repeatEnabled ? parent.width - width - 2 : 2
                                                            Behavior on x { NumberAnimation { duration: 200 } }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (root._activeJoystick && root._activeJoystick.calibrated) {
                                                                    var newState = !rowRect.repeatEnabled
                                                                    root._activeJoystick.setButtonRepeat(rowRect.buttonIndex, newState)
                                                                    rowRect.repeatEnabled = newState
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Connections {
                        target: root._activeJoystick
                        enabled: root._activeJoystick !== null
                        onRawButtonPressedChanged: function(buttonIndex, pressed) {
                            var it = buttonRowRepeater.itemAt(buttonIndex)
                            if (it) it.pressed = pressed
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // CALIBRATION PANEL  (Joystick görünməmə problemi düzəldi)
    // ============================================================
    Component {
        id: calibrationComp

        Item {
            width: panelLoader.width
            implicitHeight: calCol.implicitHeight

            ColumnLayout {
                id: calCol
                width: parent.width
                spacing: root._m

                Rectangle {
                    Layout.fillWidth: true
                    color: "black"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"

                    readonly property real pad: root._m
                    implicitHeight: calMainGrid.implicitHeight + pad * 2

                    GridLayout {
                        id: calMainGrid
                        anchors.fill: parent
                        anchors.margins: parent.pad
                        columns: root._stacked ? 1 : 2
                        columnSpacing: root._m
                        rowSpacing: root._m

                        // Joystick visualization
                        Rectangle {
                            Layout.fillWidth: true
                            color: "#3D3B3B"     // ✅ karta kontrast verildi
                            radius: 12
                            border.width: 1
                            border.color: "#9D9D9D"

                            implicitHeight: joyVisCol.implicitHeight + root._m

                            ColumnLayout {
                                id: joyVisCol
                                anchors.fill: parent
                                anchors.margins: root._m
                                spacing: root._m

                                Text {
                                    text: qsTr("Joystick")
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: root._compact ? 14 : 16
                                    Layout.fillWidth: true
                                }

                                // ✅ Layout içində ölçü “0” olmamaq üçün HOLDER
                                Item {
                                    id: joyHolder
                                    Layout.fillWidth: true

                                    readonly property real shapeW: Math.min(width, Math.round(ScreenTools.defaultFontPixelWidth * (root._compact ? 70 : 75)))
                                    readonly property real shapeH: Math.round(shapeW * 0.5)

                                    implicitHeight: shapeH
                                    Layout.preferredHeight: shapeH
                                    Layout.minimumHeight: shapeH

                                    Rectangle {
                                        id: joyShape
                                        width:  joyHolder.shapeW
                                        height: joyHolder.shapeH
                                        anchors.centerIn: parent

                                        radius: ScreenTools.defaultFontPixelWidth * 2
                                        color: "#2A2A2A"
                                        border.color: "#9D9D9D"
                                        border.width: ScreenTools.defaultFontPixelWidth * 0.25
                                        antialiasing: true

                                        property bool hasStickPositions: (controller.stickPositions && controller.stickPositions.length === 4)

                                        // Left Stick base
                                        Rectangle {
                                            width: parent.width * 0.25
                                            height: width
                                            radius: width * 0.5
                                            color: "#2A2A2A"
                                            border.color: "#9D9D9D"
                                            border.width: ScreenTools.defaultFontPixelWidth * 0.125
                                            x: (parent.width * 0.25) - (width * 0.5)
                                            y: (parent.height * 0.5) - (height * 0.5)
                                        }

                                        // Left stick dot
                                        Rectangle {
                                            color: "#4CAF50"
                                            width: parent.width * 0.035
                                            height: width
                                            radius: width * 0.5
                                            visible: parent.hasStickPositions
                                            x: (parent.width * controller.stickPositions[0]) - (width * 0.5)
                                            y: (parent.height * controller.stickPositions[1]) - (height * 0.5)
                                        }

                                        // Right Stick base
                                        Rectangle {
                                            width: parent.width * 0.25
                                            height: width
                                            radius: width * 0.5
                                            color: "#2A2A2A"
                                            border.color: "#9D9D9D"
                                            border.width: ScreenTools.defaultFontPixelWidth * 0.125
                                            x: (parent.width * 0.75) - (width * 0.5)
                                            y: (parent.height * 0.5) - (height * 0.5)
                                        }

                                        // Right stick dot
                                        Rectangle {
                                            color: "#4CAF50"
                                            width: parent.width * 0.035
                                            height: width
                                            radius: width * 0.5
                                            visible: parent.hasStickPositions
                                            x: (parent.width * controller.stickPositions[2]) - (width * 0.5)
                                            y: (parent.height * controller.stickPositions[3]) - (height * 0.5)
                                        }
                                    }
                                }
                            }
                        }

                        // Axis monitor
                        Rectangle {
                            Layout.fillWidth: true
                            color: "#3D3B3B"
                            radius: 12
                            border.width: 1
                            border.color: "#9D9D9D"
                            implicitHeight: axisMonCol.implicitHeight + root._m

                            ColumnLayout {
                                id: axisMonCol
                                anchors.fill: parent
                                anchors.margins: root._m
                                spacing: root._m

                                Text {
                                    text: qsTr("Axis Monitor")
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: root._compact ? 14 : 16
                                    Layout.fillWidth: true
                                }

                                Connections {
                                    target: controller
                                    onAxisValueChanged: function(axis, value) {
                                        var it = calibrationAxisMonitorRepeater.itemAt(axis)
                                        if (it && it.axis) it.axis.axisValue = value
                                    }
                                    onAxisDeadbandChanged: function(axis, value) {
                                        var it = calibrationAxisMonitorRepeater.itemAt(axis)
                                        if (it && it.axis) it.axis.deadbandValue = value
                                    }
                                }

                                Repeater {
                                    id: calibrationAxisMonitorRepeater
                                    model: root._activeJoystick ? root._activeJoystick.axisCount : 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12
                                        property Item axis: theAxis

                                        Text {
                                            text: qsTr("Axis %1").arg(modelData)
                                            color: "white"
                                            font.pixelSize: 14
                                            Layout.preferredWidth: 70
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            id: theAxis
                                            Layout.fillWidth: true
                                            height: 25
                                            color: "#2A2A2A"
                                            border.color: "#9D9D9D"
                                            border.width: 1

                                            property real axisValue: 0
                                            property real deadbandValue: 0
                                            property color deadbandColor: "#8c161a"

                                            Rectangle {
                                                width: 8
                                                height: parent.height
                                                color: "#4CAF50"
                                                x: parent.width / 2 + (parent.axisValue / 32768.0) * (parent.width / 2) - width / 2
                                            }

                                            Rectangle {
                                                width: Math.max(6, (parent.deadbandValue / 32768.0) * parent.width)
                                                height: 6
                                                color: parent.deadbandColor
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: controller.deadbandToggle

                                                property real startX
                                                property real direction

                                                onPressed: function(mouse) {
                                                    startX = mouseX
                                                    direction = startX > width/2 ? 1 : -1
                                                    theAxis.deadbandColor = "#3C6315"
                                                }

                                                onPositionChanged: {
                                                    var mouseToDeadband = 32768/(width/2)
                                                    var newValue = theAxis.deadbandValue + direction*(mouseX - startX)*mouseToDeadband
                                                    if (newValue > 0 && newValue < 32768) {
                                                        theAxis.deadbandValue = newValue
                                                    }
                                                    startX = mouseX
                                                }

                                                onReleased: {
                                                    controller.setDeadbandValue(modelData, theAxis.deadbandValue)
                                                    theAxis.deadbandColor = "#8c161a"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Buttons
                Flow {
                    Layout.fillWidth: true
                    spacing: root._m

                    Rectangle {
                        width: 120; height: 40; radius: 8
                        color: (controller.calibrating && controller.skipEnabled) ? "#6C6C6C" : "#3D3D3D"
                        opacity: (controller.calibrating && controller.skipEnabled) ? 1.0 : 0.7

                        Text { text: qsTr("Keç"); color: "white"; anchors.centerIn: parent; font.pixelSize: 14 }
                        MouseArea {
                            anchors.fill: parent
                            enabled: controller.calibrating && controller.skipEnabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controller.skipButtonClicked()
                        }
                    }

                    Rectangle {
                        width: 120; height: 40; radius: 8
                        color: controller.calibrating ? "#6C6C6C" : "#3D3D3D"
                        opacity: controller.calibrating ? 1.0 : 0.7

                        Text { text: qsTr("Ləğv et"); color: "white"; anchors.centerIn: parent; font.pixelSize: 14 }
                        MouseArea {
                            anchors.fill: parent
                            enabled: controller.calibrating
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controller.cancelButtonClicked()
                        }
                    }

                    Rectangle {
                        width: 120; height: 40; radius: 8
                        color: "#4CAF50"
                        opacity: (controller.calibrating ? controller.nextEnabled : true) ? 1.0 : 0.6

                        Text {
                            text: controller.calibrating ? qsTr("Sonrakı") : qsTr("Başla")
                            color: "white"
                            anchors.centerIn: parent
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: controller.calibrating ? controller.nextEnabled : true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controller.nextButtonClicked()
                        }
                    }
                }

                Text {
                    text: controller.statusText
                    color: "white"
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }
            }
        }
    }

    // ============================================================
    // ADVANCED PANEL (JoystickConfigAdvanced.qml -> UI bloklar + backend)
    // ============================================================
    Component {
        id: advancedComp

        Item {
            width: panelLoader.width
            implicitHeight: advCol.implicitHeight

            ColumnLayout {
                id: advCol
                width: parent.width
                spacing: root._m

                // ===== Throttle Configuration =====
                Rectangle {
                    Layout.fillWidth: true
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"

                    readonly property real pad: root._m
                    implicitHeight: throttleCol.implicitHeight + pad * 2

                    ColumnLayout {
                        id: throttleCol
                        anchors.fill: parent
                        anchors.margins: parent.pad
                        spacing: root._m

                        Text {
                            text: qsTr("Throttle Configuration")
                            color: "white"
                            font.pixelSize: root._compact ? 16 : 18
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: root._stacked ? 1 : 2
                            columnSpacing: root._m
                            rowSpacing: root._m

                            // Full down is zero throttle (mode=1)
                            Rectangle {
                                Layout.fillWidth: true
                                height: Math.max(58, ScreenTools.defaultFontPixelHeight * 3.0)
                                radius: 10
                                color: "#2A2A2A"
                                border.width: 1
                                border.color: "#9D9D9D"

                                readonly property bool selected: root._activeJoystick ? (root._activeJoystick.throttleMode === 1) : false

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: "transparent"
                                        border.color: "#757575"
                                        border.width: 2
                                        Rectangle {
                                            width: 8; height: 8; radius: 4
                                            anchors.centerIn: parent
                                            color: parent.parent.parent.selected ? "#8F8F8F" : "transparent"
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Full down stick is zero throttle")
                                        color: "white"
                                        font.pixelSize: root._compact ? 14 : 16
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root._activeJoystick !== null
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root._activeJoystick) root._activeJoystick.throttleMode = 1
                                    }
                                }
                            }

                            // Center stick is zero throttle (mode=0)
                            Rectangle {
                                Layout.fillWidth: true
                                height: Math.max(58, ScreenTools.defaultFontPixelHeight * 3.0)
                                radius: 10
                                color: "#2A2A2A"
                                border.width: 1
                                border.color: "#9D9D9D"

                                readonly property bool selected: root._activeJoystick ? (root._activeJoystick.throttleMode === 0) : false

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: "transparent"
                                        border.color: "#757575"
                                        border.width: 2
                                        Rectangle {
                                            width: 8; height: 8; radius: 4
                                            anchors.centerIn: parent
                                            color: parent.parent.parent.selected ? "#8F8F8F" : "transparent"
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Center stick is zero throttle")
                                        color: "white"
                                        font.pixelSize: root._compact ? 14 : 16
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root._activeJoystick !== null
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root._activeJoystick) root._activeJoystick.throttleMode = 0
                                    }
                                }
                            }
                        }
                    }
                }

                // ===== Spring loaded throttle smoothing (only throttleMode==0) =====
                Rectangle {
                    Layout.fillWidth: true
                    visible: root._activeJoystick ? (root._activeJoystick.throttleMode === 0) : false
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"
                    height: Math.max(78, ScreenTools.defaultFontPixelHeight * 4.0)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root._m
                        spacing: root._m

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Spring loaded throttle smoothing")
                            color: "white"
                            font.pixelSize: root._compact ? 16 : 18
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        QGCCheckBox {
                            checked: root._activeJoystick ? root._activeJoystick.accumulator : false
                            enabled: root._activeJoystick !== null
                            onClicked: {
                                if (root._activeJoystick) root._activeJoystick.accumulator = checked
                            }
                        }
                    }
                }

                // ===== Allow negative thrust =====
                Rectangle {
                    Layout.fillWidth: true
                    visible: globals.activeVehicle && globals.activeVehicle.supportsNegativeThrust
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"
                    height: Math.max(78, ScreenTools.defaultFontPixelHeight * 4.0)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root._m
                        spacing: root._m

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Allow negative Thrust")
                            color: "white"
                            font.pixelSize: root._compact ? 16 : 18
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        QGCCheckBox {
                            visible: globals.activeVehicle && globals.activeVehicle.supportsNegativeThrust
                            enabled: globals.activeVehicle && globals.activeVehicle.supportsNegativeThrust && (root._activeJoystick !== null)
                            checked: root._activeJoystick ? root._activeJoystick.negativeThrust : false
                            onClicked: {
                                if (root._activeJoystick) root._activeJoystick.negativeThrust = checked
                            }
                        }
                    }
                }

                // ===== Exponential =====
                Rectangle {
                    Layout.fillWidth: true
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"

                    readonly property real pad: root._m
                    implicitHeight: expoCol.implicitHeight + pad * 2

                    ColumnLayout {
                        id: expoCol
                        anchors.fill: parent
                        anchors.margins: parent.pad
                        spacing: root._m

                        Text {
                            text: qsTr("Exponential:")
                            color: "white"
                            font.pixelSize: root._compact ? 16 : 18
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root._m

                            QGCSlider {
                                id: expoSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 0.75
                                enabled: root._activeJoystick !== null
                                value: 0

                                Component.onCompleted: {
                                    if (root._activeJoystick) {
                                        value = -root._activeJoystick.exponential
                                    }
                                }

                                onValueChanged: {
                                    if (root._activeJoystick) {
                                        root._activeJoystick.exponential = -value
                                    }
                                }

                                Connections {
                                    target: joystickManager
                                    onActiveJoystickChanged: {
                                        if (root._activeJoystick) {
                                            expoSlider.value = -root._activeJoystick.exponential
                                        } else {
                                            expoSlider.value = 0
                                        }
                                    }
                                }

                                Connections {
                                    target: root._activeJoystick
                                    enabled: root._activeJoystick !== null
                                    onExponentialChanged: expoSlider.value = -root._activeJoystick.exponential
                                }
                            }

                            Text {
                                text: expoSlider.value.toFixed(2)
                                color: "white"
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                                width: 60
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                // ===== Advanced settings toggle + content =====
                Rectangle {
                    id: advSettingsCard
                    Layout.fillWidth: true
                    color: "#3D3B3B"
                    radius: 16
                    border.width: 1
                    border.color: "#9D9D9D"

                    readonly property real pad: root._m

                    property bool advEnabled: globals.activeVehicle ? (globals.activeVehicle.joystickMode !== 0) : false

                    implicitHeight: advSettingsCol.implicitHeight + pad * 2

                    ColumnLayout {
                        id: advSettingsCol
                        anchors.fill: parent
                        anchors.margins: advSettingsCard.pad
                        spacing: root._m

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root._m

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Enable further advanced settings (careful!)")
                                color: "white"
                                font.pixelSize: root._compact ? 16 : 18
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }

                            QGCCheckBox {
                                id: advEnableCheck
                                checked: advSettingsCard.advEnabled
                                onClicked: {
                                    if (!globals.activeVehicle) return;

                                    if (!checked) {
                                        globals.activeVehicle.joystickMode = 0
                                    } else {
                                        if (globals.activeVehicle.joystickMode === 0) {
                                            globals.activeVehicle.joystickMode = 1
                                        }
                                    }
                                }
                            }
                        }

                        // Advanced content
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root._m
                            visible: advEnableCheck.checked

                            // Axis frequency
                            Rectangle {
                                Layout.fillWidth: true
                                color: "#2A2A2A"
                                radius: 10
                                border.width: 1
                                border.color: "#9D9D9D"
                                implicitHeight: row1.implicitHeight + 20

                                RowLayout {
                                    id: row1
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Axis frequency (Hz):")
                                        color: "white"
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    QGCTextField {
                                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
                                        enabled: advEnableCheck.checked && (root._activeJoystick !== null)
                                        text: root._activeJoystick ? root._activeJoystick.axisFrequencyHz : ""
                                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        validator: DoubleValidator {
                                            bottom: root._activeJoystick ? root._activeJoystick.minAxisFrequencyHz : 0
                                            top:    root._activeJoystick ? root._activeJoystick.maxAxisFrequencyHz : 1000
                                        }
                                        onEditingFinished: {
                                            if (root._activeJoystick) root._activeJoystick.axisFrequencyHz = parseFloat(text)
                                        }
                                    }
                                }
                            }

                            // Button repeat frequency
                            Rectangle {
                                Layout.fillWidth: true
                                color: "#2A2A2A"
                                radius: 10
                                border.width: 1
                                border.color: "#9D9D9D"
                                implicitHeight: row2.implicitHeight + 20

                                RowLayout {
                                    id: row2
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Button repeat frequency (Hz):")
                                        color: "white"
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    QGCTextField {
                                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
                                        enabled: advEnableCheck.checked && (root._activeJoystick !== null)
                                        text: root._activeJoystick ? root._activeJoystick.buttonFrequencyHz : ""
                                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        validator: DoubleValidator {
                                            bottom: root._activeJoystick ? root._activeJoystick.minButtonFrequencyHz : 0
                                            top:    root._activeJoystick ? root._activeJoystick.maxButtonFrequencyHz : 1000
                                        }
                                        onEditingFinished: {
                                            if (root._activeJoystick) root._activeJoystick.buttonFrequencyHz = parseFloat(text)
                                        }
                                    }
                                }
                            }

                            // Circle correction
                            Rectangle {
                                Layout.fillWidth: true
                                color: "#2A2A2A"
                                radius: 10
                                border.width: 1
                                border.color: "#9D9D9D"
                                implicitHeight: row3.implicitHeight + 20

                                RowLayout {
                                    id: row3
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Enable circle correction")
                                        color: "white"
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    QGCCheckBox {
                                        enabled: advEnableCheck.checked && (root._activeJoystick !== null)
                                        checked: root._activeJoystick ? root._activeJoystick.circleCorrection : false
                                        onClicked: {
                                            if (root._activeJoystick) root._activeJoystick.circleCorrection = checked
                                        }
                                    }
                                }
                            }

                            // Deadbands
                            Rectangle {
                                Layout.fillWidth: true
                                color: "#2A2A2A"
                                radius: 10
                                border.width: 1
                                border.color: "#9D9D9D"
                                implicitHeight: row4.implicitHeight + 20

                                RowLayout {
                                    id: row4
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Deadbands")
                                        color: "white"
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    QGCCheckBox {
                                        enabled: advEnableCheck.checked
                                        checked: controller.deadbandToggle
                                        onClicked: controller.deadbandToggle = checked
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                color: "#E8E8E8"
                                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
                                wrapMode: Text.WordWrap
                                text: qsTr("Deadband can be set during the first ") +
                                      qsTr("step of calibration by gently wiggling each axis. ") +
                                      qsTr("Deadband can also be adjusted by clicking and ") +
                                      qsTr("dragging vertically on the corresponding axis monitor.")
                            }
                        }
                    }
                }
            }
        }
    }
}

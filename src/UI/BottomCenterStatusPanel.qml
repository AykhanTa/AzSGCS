import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import QGroundControl.Controls

/// The ammunition panel ("Mərmi") at the bottom centre of the fly view.
///
/// Collapsed it is the design's AmmunitionPanel: an 80x40 pill with an arrow, the
/// panel gradient, radius 17 and a deep shadow. Open, it is the "Mərmi" mock-up: a
/// 603x217 card with the arrow on top, the title and count, the launcher's state and
/// its ARM button, the slots drawn as two thin rings around a dark disc (two rows of
/// 4, 5 or 6), and the actions on the right with a red "At".
Item {
    id: root

    /// The AmmoLauncherController ("ammoLauncher"). The launcher's heartbeat gives the
    /// slot count (8, 10 or 12); the slots, arming and firing all go through it.
    property var    launcher: null
    property bool   expanded: false
    property string panelTitle: "Status Panel"

    readonly property int  totalSlots:   launcher ? launcher.slotCount : 0
    readonly property var  statusStates: launcher ? launcher.slotStates : []
    readonly property bool connected:    !!launcher && launcher.connected
    readonly property bool armed:        !!launcher && launcher.armed
    readonly property bool busy:         !!launcher && launcher.busy
    readonly property int  columns:      Math.max(1, Math.ceil(totalSlots / 2))

    readonly property real pillWidth:   AzTheme.px(80)
    readonly property real pillHeight:  AzTheme.px(40)
    readonly property real panelHeight: AzTheme.px(217)
    readonly property real ringSize:    AzTheme.px(44)
    readonly property real innerSize:   AzTheme.px(35)

    readonly property int availableCount: _countOf(0) + _countOf(1)
    readonly property bool hasSelected:   _countOf(1) > 0
    readonly property bool hasReady:      _countOf(0) > 0

    width: 603
    height: expanded ? panelHeight : pillHeight
    implicitWidth: width
    implicitHeight: height

    function _countOf(stateValue) {
        var count = 0
        for (var i = 0; i < statusStates.length; i++) {
            if (statusStates[i] === stateValue) count++
        }
        return count
    }

    function _stateAt(index) {
        if (!statusStates || index < 0 || index >= statusStates.length) return 2
        return statusStates[index]
    }

    // 0 ready, 1 selected to fire, 2 empty (fired)
    function _ringColor(stateValue) {
        if (stateValue === 1) return AzTheme.statusRed
        if (stateValue === 2) return AzTheme.slotEmpty
        return AzTheme.slotReady
    }

    // Red armed, green ready to arm, orange on the ground (unless the bench test
    // setting allows arming there), grey without the launcher.
    function _statusColor() {
        if (!connected) return AzTheme.mutedText
        if (armed)      return AzTheme.statusRed
        if (!launcher.flying && !launcher.groundArmAllowed) return AzTheme.statusOrange
        return AzTheme.statusGreen
    }

    /// Panel gradient card with the AmmunitionPanel shadow and top highlight.
    component PanelFace: Item {
        id: face

        property real radius

        RectangularShadow {
            anchors.fill: faceBackground
            offset.y:     AzTheme.px(18)
            blur:         AzTheme.px(42)
            radius:       face.radius
            color:        Qt.rgba(0, 0, 0, 0.58)
        }

        AzGradientRect {
            id:            faceBackground
            anchors.fill:  parent
            angle:         AzTheme.panelGradientAngle
            startColor:    AzTheme.panelGradientStart
            startPosition: AzTheme.panelGradientStartPos
            endColor:      AzTheme.panelGradientEnd
            endPosition:   AzTheme.panelGradientEndPos
            radius:        face.radius
            borderColor:   AzTheme.panelBorder
            borderWidth:   1
        }

        // inset 0 0.84px 0 rgba(255, 255, 255, 0.035)
        Rectangle {
            x:      face.radius
            y:      1
            width:  face.width - 2 * face.radius
            height: 1
            color:  Qt.rgba(1, 1, 1, 0.035)
        }
    }

    /// The bold arrow of the pill and of the open panel; a click toggles the panel.
    component ArrowButton: Item {
        id: arrow

        signal clicked()

        QGCColoredImage {
            anchors.centerIn:  parent
            width:             AzTheme.px(18)
            height:            width
            sourceSize.height: height
            fillMode:          Image.PreserveAspectFit
            source:            "qrc:/res/AZSHIELD_ICON/v2/popup_chevron.svg"
            color:             AzTheme.textCard
            rotation:          180
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    arrow.clicked()
        }
    }

    // ─── Collapsed: the AmmunitionPanel pill ───
    Item {
        id: pill
        width: root.pillWidth
        height: root.pillHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        visible: !root.expanded

        PanelFace {
            anchors.fill: parent
            radius:       AzTheme.px(17)
        }

        Rectangle {
            anchors.fill:    parent
            anchors.margins: 1
            radius:          AzTheme.px(17) - 1
            color:           Qt.rgba(1, 1, 1, 0.05)
            visible:         pillHover.hovered
        }

        HoverHandler { id: pillHover }

        // The launcher is armed: visible even with the panel closed.
        Rectangle {
            anchors.right:          parent.right
            anchors.rightMargin:    AzTheme.px(12)
            anchors.verticalCenter: parent.verticalCenter
            width:                  Math.max(6, AzTheme.px(8))
            height:                 width
            radius:                 width / 2
            color:                  AzTheme.statusRed
            visible:                root.armed
        }

        ArrowButton {
            anchors.fill: parent
            onClicked:    root.expanded = true
        }
    }

    // ─── Open: the "Mərmi" panel ───
    Item {
        id: panel
        width: root.width
        height: root.panelHeight
        anchors.bottom: parent.bottom
        visible: root.expanded

        PanelFace {
            anchors.fill: parent
            radius:       AzTheme.px(16)
        }

        MouseArea {
            anchors.fill:    parent
            acceptedButtons: Qt.AllButtons
            onWheel:         (wheel) => { wheel.accepted = true }
        }

        ArrowButton {
            anchors.horizontalCenter: parent.horizontalCenter
            y:                        AzTheme.px(4)
            width:                    AzTheme.px(56)
            height:                   AzTheme.px(28)
            onClicked:                root.expanded = false
        }

        // ─── Title, count, launcher state and ARM ───
        Row {
            x:                            AzTheme.px(20)
            anchors.verticalCenter:       parent.top
            anchors.verticalCenterOffset: AzTheme.px(57)
            spacing:                      AzTheme.px(3)

            Text {
                id:             titleText
                rightPadding:   AzTheme.px(7)
                text:           root.panelTitle
                color:          AzTheme.textCard
                font.family:    AzTheme.fontFamily
                font.weight:    Font.Medium
                font.pixelSize: AzTheme.fontPx(16)
            }

            Text {
                anchors.baseline: titleText.baseline
                visible:          root.totalSlots > 0
                text:             root.availableCount.toString()
                color:            AzTheme.textCard
                font.family:      AzTheme.fontFamily
                font.weight:      Font.Medium
                font.pixelSize:   AzTheme.fontPx(16)
            }

            Text {
                anchors.baseline: titleText.baseline
                visible:          root.totalSlots > 0
                text:             "/" + root.totalSlots
                color:            AzTheme.textSecondary
                font.family:      AzTheme.fontFamily
                font.pixelSize:   AzTheme.fontPx(12)
            }
        }

        Row {
            anchors.right:                parent.right
            anchors.rightMargin:          AzTheme.px(24)
            anchors.verticalCenter:       parent.top
            anchors.verticalCenterOffset: AzTheme.px(57)
            spacing:                      AzTheme.px(12)

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing:                AzTheme.px(6)

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  Math.max(6, AzTheme.px(8))
                    height:                 width
                    radius:                 width / 2
                    color:                  root._statusColor()
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:                   root.launcher ? root.launcher.statusText : qsTr("Qoşulmayıb")
                    color:                  AzTheme.textSecondary
                    font.family:            AzTheme.fontFamily
                    font.pixelSize:         AzTheme.fontPx(13)
                }
            }

            // The launcher's own arming, not the vehicle's. ARM only in flight; DISARM
            // stays available whenever the launcher is armed.
            AzButton {
                anchors.verticalCenter: parent.verticalCenter
                width:     AzTheme.px(153)
                height:    AzTheme.px(32)
                text:      root.armed ? qsTr("DISARM") : qsTr("ARM")
                danger:    root.armed
                enabled:   root.armed || (!!root.launcher && root.launcher.canArm)
                onClicked: root.armed ? root.launcher.disarm() : root.launcher.arm()
            }
        }

        // ─── Slots and actions ───
        RowLayout {
            x:       AzTheme.px(20)
            y:       AzTheme.px(80)
            width:   parent.width - AzTheme.px(20) - AzTheme.px(24)
            spacing: AzTheme.px(16)

            Item {
                Layout.fillWidth:       true
                Layout.preferredHeight: AzTheme.px(128)

                Text {
                    anchors.centerIn:    parent
                    width:               parent.width
                    visible:             root.totalSlots === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode:            Text.WordWrap
                    text:                qsTr("Buraxıcı qoşulmayıb")
                    color:               AzTheme.mutedText
                    font.family:         AzTheme.fontFamily
                    font.pixelSize:      AzTheme.fontPx(14)
                }

                GridLayout {
                    anchors.fill:  parent
                    visible:       root.totalSlots > 0
                    opacity:       root.connected ? 1 : 0.45
                    columns:       root.columns
                    columnSpacing: 0
                    rowSpacing:    0

                    Repeater {
                        model: root.totalSlots

                        Item {
                            id: slot

                            required property int index
                            readonly property int   slotState: root._stateAt(index)
                            readonly property color ringColor: root._ringColor(slotState)
                            readonly property bool  clickable: root.connected && !root.busy && slotState !== 2

                            Layout.fillWidth:       true
                            Layout.preferredHeight: AzTheme.px(64)

                            Item {
                                id:               rings
                                anchors.centerIn: parent
                                width:            root.ringSize
                                height:           width

                                // Soft glow just outside the outer ring
                                Rectangle {
                                    anchors.centerIn: parent
                                    width:            parent.width + AzTheme.px(6)
                                    height:           width
                                    radius:           width / 2
                                    color:            Qt.rgba(slot.ringColor.r, slot.ringColor.g, slot.ringColor.b, 0.10)
                                    visible:          slot.slotState !== 2
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius:       width / 2
                                    color:        "transparent"
                                    border.width: Math.max(1, AzTheme.px(1.5))
                                    border.color: slot.ringColor
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width:            root.innerSize
                                    height:           width
                                    radius:           width / 2
                                    border.width:     Math.max(1, AzTheme.px(1.5))
                                    border.color:     slot.ringColor
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: "#23272B" }
                                        GradientStop { position: 1; color: "#16191C" }
                                    }
                                }

                                // Selected slots blink until they are unselected or fired.
                                SequentialAnimation on opacity {
                                    running:        slot.slotState === 1
                                    loops:          Animation.Infinite
                                    alwaysRunToEnd: false
                                    NumberAnimation { to: 0.35; duration: 500 }
                                    NumberAnimation { to: 1.00; duration: 500 }
                                }

                                Connections {
                                    target: slot
                                    function onSlotStateChanged() {
                                        if (slot.slotState !== 1) rings.opacity = 1
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: rings
                                text:             (slot.index + 1 < 10 ? "0" : "") + (slot.index + 1)
                                color:            slot.slotState === 2 ? AzTheme.mutedText : AzTheme.textCard
                                font.family:      AzTheme.fontFamily
                                font.weight:      Font.Medium
                                font.pixelSize:   AzTheme.fontPx(13)
                            }

                            MouseArea {
                                anchors.fill: rings
                                enabled:      slot.clickable
                                cursorShape:  slot.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked:    root.launcher.toggleSlot(slot.index)
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.alignment:      Qt.AlignTop
                Layout.topMargin:      AzTheme.px(5)
                Layout.preferredWidth: AzTheme.px(153)
                Layout.fillWidth:      false
                spacing:               AzTheme.px(8)

                AzButton {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: AzTheme.px(34)
                    text:      qsTr("Hamısını Seç")
                    enabled:   root.connected && !root.busy && root.hasReady
                    onClicked: root.launcher.selectAll()
                }

                // Atma: the selection goes back to ready
                AzButton {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: AzTheme.px(34)
                    text:      qsTr("Atma")
                    enabled:   !root.busy && root.hasSelected
                    onClicked: root.launcher.clearSelection()
                }

                // At: only while the launcher is armed
                AzButton {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: AzTheme.px(34)
                    text:       qsTr("At")
                    iconSource: "qrc:/res/AZSHIELD_ICON/v2/ammo_fire.svg"
                    danger:     true
                    enabled:    !!root.launcher && root.launcher.canFire
                    onClicked:  root.launcher.fire()
                }
            }
        }
    }
}

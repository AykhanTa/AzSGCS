import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import QGroundControl.Controls

/// The ammunition panel ("Mərmi") at the bottom centre of the fly view.
///
/// Collapsed it is the design's AmmunitionPanel: an 80x40 pill with an arrow, the
/// panel gradient, radius 17 and a deep shadow. Open, it is the "Mərmi" mock-up: a
/// 603x217 card with the arrow on top, the title and count, ten slots drawn as two
/// thin rings around a dark disc, and the actions on the right with a red "At".
Item {
    id: root

    property var statusStates: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property bool expanded: false
    property string panelTitle: "Status Panel"

    readonly property int totalSlots: 10

    readonly property real pillWidth:   AzTheme.px(80)
    readonly property real pillHeight:  AzTheme.px(40)
    readonly property real panelHeight: AzTheme.px(217)
    readonly property real ringSize:    AzTheme.px(44)
    readonly property real innerSize:   AzTheme.px(35)

    readonly property int availableCount: {
        if (!statusStates) return 0
        var count = 0
        for (var i = 0; i < totalSlots; i++) {
            if (i < statusStates.length && statusStates[i] !== 2) count++
        }
        return count
    }

    readonly property bool hasSelected: {
        if (!statusStates) return false
        for (var i = 0; i < totalSlots; i++) {
            if (i < statusStates.length && statusStates[i] === 1) return true
        }
        return false
    }

    width: 603
    height: expanded ? panelHeight : pillHeight
    implicitWidth: width
    implicitHeight: height

    function _stateAt(index) {
        if (!statusStates || index < 0 || index >= statusStates.length) return 2
        return statusStates[index]
    }

    // 0 ready, 1 selected to fire, 2 empty
    function _ringColor(stateValue) {
        if (stateValue === 1) return AzTheme.statusRed
        if (stateValue === 2) return AzTheme.slotEmpty
        return AzTheme.slotReady
    }

    // ← DƏYİŞDİRİLDİ: boş slot (2) klikləndikdə heç nə etmə
    function _cycleState(index) {
        var newStates = []
        for (var i = 0; i < statusStates.length; i++) newStates.push(statusStates[i])
        var current = newStates[index]
        if (current === 0)      newStates[index] = 1
        else if (current === 1) newStates[index] = 2
        // state === 2 isə — toxunma
        statusStates = newStates
    }

    // ← DƏYİŞDİRİLDİ: boş (2) slotları keçmə
    function selectAll() {
        var newStates = []
        for (var i = 0; i < statusStates.length; i++)
            newStates.push(statusStates[i] === 2 ? 2 : 1)
        statusStates = newStates
    }

    function unselectAll() {
        var newStates = []
        for (var i = 0; i < statusStates.length; i++)
            newStates.push(statusStates[i] === 1 ? 0 : statusStates[i])
        statusStates = newStates
    }

    function discardSelected() {
        var newStates = []
        for (var i = 0; i < statusStates.length; i++)
            newStates.push(statusStates[i] === 1 ? 2 : statusStates[i])
        statusStates = newStates
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

        // ─── Title and count ───
        Text {
            x:                      AzTheme.px(20)
            anchors.verticalCenter: parent.top
            anchors.verticalCenterOffset: AzTheme.px(57)
            text:                   root.panelTitle
            color:                  AzTheme.textCard
            font.family:            AzTheme.fontFamily
            font.weight:            Font.Medium
            font.pixelSize:         AzTheme.fontPx(16)
        }

        Row {
            anchors.right:                parent.right
            anchors.rightMargin:          AzTheme.px(24)
            anchors.verticalCenter:       parent.top
            anchors.verticalCenterOffset: AzTheme.px(57)
            spacing:                      AzTheme.px(3)

            Text {
                id:             countText
                text:           root.availableCount.toString()
                color:          AzTheme.textCard
                font.family:    AzTheme.fontFamily
                font.weight:    Font.Medium
                font.pixelSize: AzTheme.fontPx(16)
            }

            Text {
                anchors.baseline: countText.baseline
                text:             "/" + root.totalSlots
                color:            AzTheme.textSecondary
                font.family:      AzTheme.fontFamily
                font.pixelSize:   AzTheme.fontPx(12)
            }
        }

        // ─── Slots and actions ───
        RowLayout {
            x:       AzTheme.px(20)
            y:       AzTheme.px(74)
            width:   parent.width - AzTheme.px(20) - AzTheme.px(24)
            spacing: AzTheme.px(16)

            GridLayout {
                Layout.fillWidth: true
                columns:          5
                columnSpacing:    0
                rowSpacing:       0

                Repeater {
                    model: root.totalSlots

                    Item {
                        id: slot

                        required property int index
                        readonly property int  slotState: root._stateAt(index)
                        readonly property color ringColor: root._ringColor(slotState)

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

                            // Selected slots blink until they are kept or fired.
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

                        // ← DƏYİŞDİRİLDİ: boş slot kliklənsə heç nə etmə
                        MouseArea {
                            anchors.fill: rings
                            cursorShape:  slot.slotState === 2 ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked:    if (slot.slotState !== 2) root._cycleState(slot.index)
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
                    onClicked: root.selectAll()
                }

                // Atma (warning → ready)
                AzButton {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: AzTheme.px(34)
                    text:      qsTr("Atma")
                    enabled:   root.hasSelected
                    onClicked: root.unselectAll()
                }

                // At (warning → empty)
                AzButton {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: AzTheme.px(34)
                    text:       qsTr("At")
                    iconSource: "qrc:/res/AZSHIELD_ICON/v2/ammo_fire.svg"
                    danger:     true
                    enabled:    root.hasSelected
                    onClicked:  root.discardSelected()
                }
            }
        }
    }
}

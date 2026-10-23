import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import QGroundControl.Controls

/// The ammunition panel ("Mərmi") at the bottom centre of the fly view.
///
/// Collapsed it is the design's AmmunitionPanel: an 80x40 pill with an arrow, the
/// panel gradient, radius 17 and a deep shadow. The arrow opens the slots panel above
/// it and turns down.
Item {
    id: root

    property var statusStates: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property bool expanded: false
    property string panelTitle: "Status Panel"

    readonly property int totalSlots: 10

    readonly property color readyColor:   AzTheme.statusGreen
    readonly property color warningColor: AzTheme.statusRed
    readonly property color emptyColor:   "#3A3F44"

    readonly property real toggleWidth:  AzTheme.px(80)
    readonly property real toggleHeight: AzTheme.px(40)
    readonly property real dotSize:      AzTheme.px(32)
    readonly property real panelPadding: AzTheme.px(16)
    readonly property real panelGap:     AzTheme.px(8)

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

    width: 500
    height: expanded ? (bodyCard.height + panelGap + toggleRect.height) : toggleRect.height
    implicitWidth: width
    implicitHeight: height

    function _stateAt(index) {
        if (!statusStates || index < 0 || index >= statusStates.length) return 2
        return statusStates[index]
    }

    function _colorForState(stateValue) {
        if (stateValue === 1) return warningColor
        if (stateValue === 2) return emptyColor
        return readyColor
    }

    function _glowColorForState(stateValue) {
        if (stateValue === 1) return Qt.rgba(1.0, 0.2, 0.26, 0.35)
        if (stateValue === 0) return Qt.rgba(0.0, 0.71, 0.27, 0.25)
        return "transparent"
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

    // ─── Toggle (the design's AmmunitionPanel) ───
    Item {
        id: toggleRect
        z: 2
        width: root.toggleWidth
        height: root.toggleHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        PanelFace {
            anchors.fill: parent
            radius:       AzTheme.px(17)
        }

        Rectangle {
            anchors.fill:    parent
            anchors.margins: 1
            radius:          AzTheme.px(17) - 1
            color:           Qt.rgba(1, 1, 1, toggleMouse.pressed ? 0.08 : 0.04)
            visible:         toggleMouse.containsMouse || toggleMouse.pressed
        }

        QGCColoredImage {
            anchors.centerIn:  parent
            width:             AzTheme.px(16)
            height:            width
            sourceSize.height: height
            fillMode:          Image.PreserveAspectFit
            source:            "qrc:/res/AZSHIELD_ICON/v2/popup_chevron.svg"
            color:             AzTheme.textCard
            rotation:          root.expanded ? 0 : 180

            Behavior on rotation { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    // ─── Slots panel, above the toggle ───
    Item {
        id: bodyCard
        width: root.width
        height: bodyColumn.implicitHeight + 2 * root.panelPadding
        anchors.bottom: toggleRect.top
        anchors.bottomMargin: root.panelGap
        visible: root.expanded
        opacity: root.expanded ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 140 } }

        PanelFace {
            anchors.fill: parent
            radius:       AzTheme.px(14)
        }

        MouseArea {
            anchors.fill:    parent
            acceptedButtons: Qt.AllButtons
            onWheel:         (wheel) => { wheel.accepted = true }
        }

        ColumnLayout {
            id: bodyColumn
            x: root.panelPadding
            y: root.panelPadding
            width: parent.width - 2 * root.panelPadding
            spacing: AzTheme.px(12)

            // ─── Header ───
            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text:             root.panelTitle
                    color:            AzTheme.textCard
                    font.family:      AzTheme.fontFamily
                    font.weight:      Font.Medium
                    font.pixelSize:   AzTheme.fontPx(AzTheme.popupTitleSize)
                }

                Row {
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id:             activeCountText
                        text:           root.availableCount.toString()
                        color:          AzTheme.textCard
                        font.family:    AzTheme.fontFamily
                        font.weight:    Font.DemiBold
                        font.pixelSize: AzTheme.fontPx(20)
                    }

                    Text {
                        anchors.baseline: activeCountText.baseline
                        text:             "/" + root.totalSlots
                        color:            AzTheme.textSecondary
                        font.family:      AzTheme.fontFamily
                        font.pixelSize:   AzTheme.fontPx(14)
                    }
                }
            }

            // ─── LED-lər + Buttonlar ───
            RowLayout {
                Layout.fillWidth: true
                spacing: AzTheme.px(16)

                GridLayout {
                    id: ledGrid
                    Layout.fillWidth: true
                    columns: 5
                    columnSpacing: AzTheme.px(10)
                    rowSpacing: AzTheme.px(10)

                    Repeater {
                        model: root.totalSlots

                        Item {
                            id: ledCell

                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: root.dotSize * 1.5

                            Item {
                                id: ledItem
                                anchors.centerIn: parent
                                width: root.dotSize
                                height: root.dotSize

                                property int currentState: root._stateAt(ledCell.index)

                                // ── Glow effekti ──
                                Rectangle {
                                    id: glowRect
                                    anchors.centerIn: parent
                                    width: root.dotSize * 1.5
                                    height: width
                                    radius: width / 2
                                    color: root._glowColorForState(ledItem.currentState)
                                    visible: ledItem.currentState !== 2
                                    opacity: 1.0

                                    SequentialAnimation on opacity {
                                        running: ledItem.currentState === 1
                                        loops: Animation.Infinite
                                        alwaysRunToEnd: false
                                        NumberAnimation { to: 0.10; duration: 500 }
                                        NumberAnimation { to: 1.00; duration: 500 }
                                    }
                                }

                                // ── Əsas LED dairəsi ──
                                Rectangle {
                                    id: mainDot
                                    anchors.centerIn: parent
                                    width: root.dotSize
                                    height: root.dotSize
                                    radius: root.dotSize / 2
                                    color: root._colorForState(ledItem.currentState)
                                    border.color: ledItem.currentState === 2 ? AzTheme.groupBorder : Qt.rgba(0, 0, 0, 0.4)
                                    border.width: 1
                                    opacity: 1.0

                                    SequentialAnimation on opacity {
                                        running: ledItem.currentState === 1
                                        loops: Animation.Infinite
                                        alwaysRunToEnd: false
                                        NumberAnimation { to: 0.25; duration: 500 }
                                        NumberAnimation { to: 1.00; duration: 500 }
                                    }

                                    // ── Nömrə — dairənin içində ──
                                    Text {
                                        anchors.centerIn: parent
                                        text: (ledCell.index + 1 < 10 ? "0" : "") + (ledCell.index + 1)
                                        color: ledItem.currentState === 2 ? AzTheme.mutedText : "#0E1113"
                                        font.family: AzTheme.fontFamily
                                        font.weight: Font.DemiBold
                                        font.pixelSize: AzTheme.fontPx(11)
                                    }
                                }

                                // State dəyişdikdə opacity-ni sıfırla
                                onCurrentStateChanged: {
                                    if (currentState !== 1) {
                                        glowRect.opacity = 1.0
                                        mainDot.opacity  = 1.0
                                    }
                                }

                                // ← DƏYİŞDİRİLDİ: boş slot kliklənsə heç nə etmə
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: ledItem.currentState === 2
                                                     ? Qt.ArrowCursor
                                                     : Qt.PointingHandCursor
                                    onClicked: if (ledItem.currentState !== 2) root._cycleState(ledCell.index)
                                }
                            }
                        }
                    }
                }

                // ── Buttonlar ──
                ColumnLayout {
                    Layout.alignment:      Qt.AlignVCenter
                    Layout.preferredWidth: AzTheme.px(124)
                    Layout.fillWidth:      false
                    spacing: AzTheme.px(8)

                    AzButton {
                        Layout.fillWidth: true
                        text:      qsTr("Hamısını Seç")
                        onClicked: root.selectAll()
                    }

                    // Atma (warning → ready)
                    AzButton {
                        Layout.fillWidth: true
                        text:      qsTr("Atma")
                        enabled:   root.hasSelected
                        onClicked: root.unselectAll()
                    }

                    // At (warning → empty)
                    AzButton {
                        Layout.fillWidth: true
                        text:      qsTr("At")
                        danger:    true
                        enabled:   root.hasSelected
                        onClicked: root.discardSelected()
                    }
                }
            }
        }
    }
}

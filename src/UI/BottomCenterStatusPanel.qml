import QtQuick
import QtQuick.Controls

import QGroundControl.Controls
import QtQuick.Layouts

Item {
    id: root

    property var statusStates: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property bool expanded: false
    property string panelTitle: "Status Panel"

    readonly property int totalSlots: 10
    readonly property real expandedPanelHeight: 220
    readonly property real collapsedPanelHeight: 42
    readonly property real panelRadius: 10
    readonly property color panelColor: "#2f2f2f"
    readonly property color borderColor: "#3d3d3d"
    readonly property color textColor: "white"
    readonly property color subTextColor: "#A9A9A9"
    readonly property color readyColor: "#19d56b"
    readonly property color warningColor: "#FC0101"
    readonly property color emptyColor: "#777777"

    readonly property real headerHeight: 42
    readonly property real toggleWidth: 46
    readonly property real toggleHeight: 22
    readonly property real dotSize: 32
    readonly property real panelPadding: 14

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
    height: expanded ? (bodyRect.y + bodyRect.height) : toggleRect.height
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
        if (stateValue === 1) return Qt.rgba(1.0, 0.01, 0.01, 0.35)
        if (stateValue === 0) return Qt.rgba(0.1, 0.84, 0.42, 0.25)
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

    // ─── Toggle düyməsi ───
    Rectangle {
        id: toggleRect
        z: 2
        width: root.toggleWidth
        height: root.toggleHeight
        radius: height / 2
        color: root.panelColor
        border.color: root.borderColor
        border.width: 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        // An icon, not a glyph. This used to be U+2304/U+2303, the arrowheads from
        // Miscellaneous Technical, which Roboto does not carry -- so on Android the
        // only thing marking the control was an empty circle.
        QGCColoredImage {
            anchors.centerIn: parent
            width:  Math.round(parent.height * 0.42)
            height: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            source: root.expanded ? "/res/chevron-down.svg" : "/res/chevron-up.svg"
            color: root.textColor
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    // ─── Əsas panel gövdəsi ───
    Rectangle {
        id: bodyRect
        y: root.toggleHeight / 2
        width: root.width
        height: root.expanded ? root.expandedPanelHeight : 0
        radius: root.panelRadius
        color: root.panelColor
        border.color: root.borderColor
        border.width: 1
        clip: true
        visible: height > 0

        Behavior on height {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // ─── Header ───
        Item {
            id: headerRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 6
            height: root.headerHeight

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: root.panelTitle
                    color: root.textColor
                    font.pixelSize: 15
                    font.bold: true
                }

                Rectangle {
                    width: parent.children[0].contentWidth
                    height: 1
                    color: root.subTextColor
                    opacity: 0.5
                }
            }

            Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Row {
                    anchors.right: parent.right
                    spacing: 0

                    Text {
                        id: activeCountText
                        text: root.availableCount.toString()
                        color: root.textColor
                        font.pixelSize: 22
                        font.bold: true
                        anchors.baseline: totalCountText.baseline
                    }

                    Text {
                        id: totalCountText
                        text: "/" + root.totalSlots
                        color: root.subTextColor
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    width: activeCountText.contentWidth + totalCountText.contentWidth
                    height: 1
                    color: root.subTextColor
                    opacity: 0.5
                    anchors.right: parent.right
                }
            }
        }

        // ─── LED-lər + Buttonlar ───
        Item {
            id: contentArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: headerRow.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.panelPadding
            anchors.rightMargin: root.panelPadding
            anchors.bottomMargin: root.panelPadding
            clip: true
            visible: root.expanded
            opacity: root.expanded ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            // ── LED Grid ──
            GridLayout {
                id: ledGrid
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - buttonColumn.width - 16
                columns: 5
                columnSpacing: 14
                rowSpacing: 10

                Repeater {
                    model: root.totalSlots

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52

                        Item {
                            id: ledItem
                            anchors.centerIn: parent
                            width: root.dotSize
                            height: root.dotSize

                            property int currentState: root._stateAt(index)

                            // ── Glow effekti ──
                            Rectangle {
                                id: glowRect
                                anchors.centerIn: parent
                                width: root.dotSize * 1.6
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
                                border.color: "#111111"
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
                                    text: (index + 1 < 10 ? "0" : "") + (index + 1)
                                    color: ledItem.currentState === 2 ? "#444444" : "#1a1a1a"
                                    font.pixelSize: 10
                                    font.bold: true
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
                                onClicked: if (ledItem.currentState !== 2) root._cycleState(index)
                            }
                        }
                    }
                }
            }

            // ── Buttonlar ──
            Column {
                id: buttonColumn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 100
                spacing: 8

                // Hamısını Seç
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    color: buttonSelectAll.containsMouse ? "#5ab76b" : "#4CAF50"
                    border.color: "#3a8f42"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Hamısını Seç")
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: buttonSelectAll
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectAll()
                    }

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // Atma (warning → ready)
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    opacity: root.hasSelected ? 1.0 : 0.4
                    color: (root.hasSelected && buttonUnselect.containsMouse) ? "#6a89a0" : "#546E7A"
                    border.color: "#3d5260"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Atma"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: buttonUnselect
                        anchors.fill: parent
                        hoverEnabled: root.hasSelected
                        cursorShape: root.hasSelected ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (root.hasSelected) root.unselectAll()
                    }

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // At (warning → empty)
                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 6
                    opacity: root.hasSelected ? 1.0 : 0.4
                    color: (root.hasSelected && buttonDiscard.containsMouse) ? "#e64a3a" : "#D32F2F"
                    border.color: "#a12424"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "At"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: buttonDiscard
                        anchors.fill: parent
                        hoverEnabled: root.hasSelected
                        cursorShape: root.hasSelected ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (root.hasSelected) root.discardSelected()
                    }

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}

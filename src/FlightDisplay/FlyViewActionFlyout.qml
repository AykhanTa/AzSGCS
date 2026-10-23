import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

/// The flight commands that open from the side menu's "Uçuş Paneli" (design CSS: 146 px
/// wide, the panel gradient, radius 14, 48 px rows with a 24 px icon in a 34 px box and
/// Poppins 18). Altitude and speed open their panel beside the row that opened it.
Item {
    id: root

    signal displayPreFlightChecklist

    // Same insets the old tool strip reported, so the map keeps clear of it.
    property real leftEdgeTopInset:    visible ? (x + width) : 0
    property real leftEdgeCenterInset: leftEdgeTopInset
    property real topEdgeLeftInset:    visible ? (y + height) : 0

    readonly property real _rowH:      AzTheme.px(48)
    readonly property real _rowPadH:   AzTheme.px(10)
    readonly property real _iconBox:   AzTheme.px(34)
    readonly property real _iconSize:  AzTheme.px(24)
    readonly property real _labelGap:  AzTheme.px(10)
    readonly property real _radius:    AzTheme.px(14)

    // Widest label decides the width, never narrower than the design's 146 px.
    readonly property real _cardW: {
        var widest = 0
        for (var i = 0; i < rowRepeater.count; ++i) {
            var row = rowRepeater.itemAt(i)
            if (row && row.visible) {
                widest = Math.max(widest, row.labelWidth)
            }
        }
        return Math.max(AzTheme.px(146), Math.ceil(_rowPadH * 2 + _iconBox + _labelGap + widest + AzTheme.px(12)))
    }

    implicitWidth:  _cardW
    implicitHeight: rowColumn.height + 2

    // The panel that is open belongs to this row, so the row stays highlighted.
    property Item _panelRow: null

    FlyViewToolStripActionList {
        id: actionList
        onDisplayPreFlightChecklist: root.displayPreFlightChecklist()
    }

    function _trigger(action, row) {
        if (!action || (action.enabled !== undefined && !action.enabled)) {
            return
        }
        if (action === actionList.changeAltActionRef || action === actionList.changeSpeedActionRef) {
            _panelRow = row
        }
        if (typeof action.triggered === "function") {
            action.triggered(row)
        } else if (typeof action.trigger === "function") {
            action.trigger()
        }
    }

    // Panels close with the flight panel.
    onVisibleChanged: {
        if (!visible) {
            actionList.altPanelVisible   = false
            actionList.speedPanelVisible = false
        }
    }

    RectangularShadow {
        anchors.fill: cardBackground
        offset.y:     AzTheme.px(12)
        blur:         AzTheme.px(32)
        radius:       cardBackground.radius
        color:        AzTheme.popupShadow
    }

    AzGradientRect {
        id:            cardBackground
        width:         root._cardW
        height:        root.implicitHeight
        angle:         AzTheme.panelGradientAngle
        startColor:    AzTheme.panelGradientStart
        startPosition: AzTheme.panelGradientStartPos
        endColor:      AzTheme.panelGradientEnd
        endPosition:   AzTheme.panelGradientEndPos
        radius:        root._radius
        borderColor:   AzTheme.panelBorder
        borderWidth:   1
    }

    // Clicks on the card stay on the card.
    MouseArea {
        anchors.fill:    cardBackground
        acceptedButtons: Qt.AllButtons
        onWheel:         (wheel) => { wheel.accepted = true }
    }

    Column {
        id: rowColumn
        x:  1
        y:  1
        width: root._cardW - 2

        Repeater {
            id:    rowRepeater
            model: actionList.model

            delegate: Item {
                id: row

                required property var modelData
                readonly property var  action:   modelData
                readonly property bool _enabled: action && action.enabled !== undefined ? action.enabled : true
                readonly property bool _current: !!(action && action.current)
                readonly property bool _panelOpen: root._panelRow === row &&
                                                   (actionList.altPanelVisible || actionList.speedPanelVisible)
                readonly property real labelWidth: label.implicitWidth

                width:   rowColumn.width
                height:  root._rowH
                visible: action && action.visible !== undefined ? action.visible : true

                Rectangle {
                    anchors.fill:    parent
                    anchors.margins: AzTheme.px(2)
                    radius:          root._radius - AzTheme.px(3)
                    color:           Qt.rgba(1, 1, 1, rowMouse.pressed ? 0.09 : 0.05)
                    visible:         row._enabled && (rowMouse.containsMouse || rowMouse.pressed || row._panelOpen)
                }

                Item {
                    id:                     iconBox
                    x:                      root._rowPadH
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  root._iconBox
                    height:                 root._iconBox
                    opacity:                row._enabled ? 1 : 0.4

                    QGCColoredImage {
                        anchors.centerIn:  parent
                        width:             root._iconSize
                        height:            width
                        sourceSize.height: height
                        fillMode:          Image.PreserveAspectFit
                        source:            row.action ? row.action.iconSource : ""
                        color:             AzTheme.textCard
                        layer.enabled:     true
                        layer.effect: MultiEffect {
                            shadowEnabled:          true
                            shadowColor:            AzTheme.menuIconGlow
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset:   0
                            blurMax:                AzTheme.px(14)
                            shadowBlur:             1.0
                        }
                    }
                }

                Text {
                    id:                     label
                    anchors.left:           iconBox.right
                    anchors.leftMargin:     root._labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text:                   row.action ? row.action.text : ""
                    color:                  AzTheme.textCard
                    opacity:                row._enabled ? 1 : 0.4
                    font.family:            AzTheme.fontFamily
                    font.pixelSize:         AzTheme.fontPx(18)
                }

                // The command whose flight mode is active.
                Rectangle {
                    anchors.right:          parent.right
                    anchors.rightMargin:    AzTheme.px(10)
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  Math.max(5, AzTheme.px(7))
                    height:                 width
                    radius:                 width / 2
                    color:                  AzTheme.statusGreen
                    visible:                row._current
                }

                MouseArea {
                    id:           rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled:      row._enabled
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root._trigger(row.action, row)
                }
            }
        }
    }

    // ================== Altitude / speed panel ==================
    component ValuePanel: Item {
        id: panel

        property string title
        property string units
        property real   step:         1
        property real   currentValue: 0
        property real   lastApplied:  0
        property int    maxValue:     50000

        signal apply(real value)

        readonly property real _pad: AzTheme.px(18)

        width:  AzTheme.px(228)
        height: panelColumn.height + 2 * _pad

        // Inline components cannot see the file's ids, so this does not use actionList.
        function _value() {
            var v = parseFloat(("" + valueInput.text).trim().replace(",", "."))
            return isNaN(v) ? currentValue : v
        }

        function _step(delta) {
            valueInput.text = Math.max(0, Math.round(_value() + delta)).toString()
        }

        onVisibleChanged: {
            if (visible) {
                valueInput.text = Math.round(currentValue).toString()
                valueInput.forceActiveFocus()
            }
        }

        RectangularShadow {
            anchors.fill: panelBackground
            offset.y:     AzTheme.px(12)
            blur:         AzTheme.px(32)
            radius:       panelBackground.radius
            color:        AzTheme.popupShadow
        }

        AzGradientRect {
            id:            panelBackground
            anchors.fill:  parent
            angle:         AzTheme.panelGradientAngle
            startColor:    AzTheme.panelGradientStart
            startPosition: AzTheme.panelGradientStartPos
            endColor:      AzTheme.panelGradientEnd
            endPosition:   AzTheme.panelGradientEndPos
            radius:        AzTheme.px(14)
            borderColor:   AzTheme.panelBorder
            borderWidth:   1
        }

        MouseArea {
            anchors.fill:    parent
            acceptedButtons: Qt.AllButtons
            onWheel:         (wheel) => { wheel.accepted = true }
        }

        Column {
            id:      panelColumn
            x:       panel._pad
            y:       panel._pad
            width:   panel.width - 2 * panel._pad
            spacing: AzTheme.px(14)

            Text {
                text:           panel.title
                color:          AzTheme.textCard
                font.family:    AzTheme.fontFamily
                font.weight:    Font.Medium
                font.pixelSize: AzTheme.fontPx(18)
            }

            Item {
                width:  parent.width
                height: AzTheme.px(40)

                // Value with its unit, typed in place.
                Rectangle {
                    width:        AzTheme.px(80)
                    height:       parent.height
                    radius:       AzTheme.px(8)
                    border.width: 1
                    border.color: valueInput.activeFocus ? AzTheme.cardHoverBorder : AzTheme.groupBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.pillTop }
                        GradientStop { position: 1; color: AzTheme.pillBottom }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing:          AzTheme.px(4)

                        TextInput {
                            id:               valueInput
                            width:            Math.max(AzTheme.px(12), contentWidth)
                            color:            AzTheme.textCard
                            font.family:      AzTheme.fontFamily
                            font.pixelSize:   AzTheme.fontPx(14)
                            inputMethodHints: Qt.ImhPreferNumbers
                            selectByMouse:    true
                            validator:        IntValidator { bottom: 0; top: panel.maxValue }
                            onAccepted:       panel.apply(panel._value())
                        }

                        Text {
                            text:           panel.units
                            color:          AzTheme.textCard
                            font.family:    AzTheme.fontFamily
                            font.pixelSize: AzTheme.fontPx(14)
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    height:        parent.height
                    spacing:       AzTheme.px(8)

                    Repeater {
                        model: [ { text: "+", delta: 1 }, { text: "−", delta: -1 } ]

                        AzButton {
                            required property var modelData
                            minimumWidth: AzTheme.px(40)
                            width:        AzTheme.px(40)
                            height:       parent.height
                            text:         modelData.text
                            textSize:     22
                            onClicked:    panel._step(modelData.delta * panel.step)
                        }
                    }
                }
            }

            Text {
                width:          parent.width
                elide:          Text.ElideRight
                text:           qsTr("Son tətbiq olunan: %1 %2").arg(Math.round(panel.lastApplied)).arg(panel.units)
                color:          AzTheme.textSecondary
                font.family:    AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(14)
            }

            AzButton {
                width:     parent.width
                height:    AzTheme.px(40)
                text:      qsTr("Saxla")
                onClicked: panel.apply(panel._value())
            }
        }
    }

    readonly property real _panelX: _cardW + AzTheme.px(6)

    function _panelY(panelHeight) {
        var rowY = _panelRow ? _panelRow.mapToItem(root, 0, 0).y : 0
        var maxY = parent ? parent.height - root.y - panelHeight - AzTheme.px(12) : rowY
        return Math.max(0, Math.min(rowY, maxY))
    }

    ValuePanel {
        id:           altitudePanel
        x:            root._panelX
        y:            root._panelY(height)
        visible:      actionList.altPanelVisible && root.visible
        title:        qsTr("Hündürlük")
        units:        QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
        step:         actionList._altStepAppUnits
        currentValue: actionList.currentAltitude
        lastApplied:  actionList.lastAppliedAltitude
        maxValue:     50000
        onApply:      (value) => actionList.applyAltitudeTarget(value)
    }

    ValuePanel {
        id:           speedPanel
        x:            root._panelX
        y:            root._panelY(height)
        visible:      actionList.speedPanelVisible && root.visible
        title:        qsTr("Sürət")
        units:        QGroundControl.unitsConversion.appSettingsSpeedUnitsString
        step:         actionList._speedStepAppUnits
        currentValue: actionList.currentSpeed
        lastApplied:  actionList.lastAppliedSpeed
        maxValue:     2000
        onApply:      (value) => actionList.applySpeedTarget(value)
    }
}

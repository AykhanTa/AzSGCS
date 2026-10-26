import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// The panel a top bar card opens ("Status", "RC Siqnalı" mock-ups).
//
// It fills its host (a Loader over the whole window) and draws the card below the top
// bar, left-aligned with the card that opened it. The area below the bar is a
// transparent backdrop: a click there closes the panel, and no click or wheel reaches
// the map. The bar itself stays live, so another card can be clicked straight away.
//
// Children go into the scrolling body; `fixedContent` stays between the header and
// the body (the ARM row of the Status panel).
Item {
    id: root

    anchors.fill: parent
    visible:      panelVisible

    property bool   panelVisible:    true
    property Item   anchorItem:      null
    property Item   topPanelItem:    null
    property string title
    property bool   settingsVisible: false
    property real   cardWidth:       AzTheme.px(AzTheme.popupWidth)
    property real   maxCardHeight:   AzTheme.px(AzTheme.popupMaxHeight)

    default property alias content:      body.data
    property alias         fixedContent: fixedColumn.data
    readonly property real contentWidth: flick.width
    readonly property alias flickable:   flick

    signal closeRequested()
    signal settingsClicked()

    readonly property real _pad:  AzTheme.px(AzTheme.popupPadding)
    readonly property real _gap:  AzTheme.px(AzTheme.popupGap)
    readonly property real _edge: AzTheme.px(12)
    property real _barBottom: 0
    property real _leftBound: _edge
    // The card stays hidden until it has been placed under its button. A Loader (an
    // asynchronous one above all) shows the panel before it has a size, an anchor and
    // the top bar, and the card would flash at the left edge or over the bar.
    property bool _placed: false

    function reposition() {
        if (!visible || width <= 0 || ((!anchorItem || !topPanelItem) && !placeTimer.expired)) {
            return
        }

        _barBottom = topPanelItem ? topPanelItem.mapToItem(root, 0, topPanelItem.height).y : 0
        _leftBound = (topPanelItem ? Math.max(0, topPanelItem.mapToItem(root, 0, 0).x) : 0) + _edge

        var x = anchorItem ? anchorItem.mapToItem(root, 0, 0).x : _leftBound
        card.x = Math.round(Math.max(_leftBound, Math.min(x, width - card.width - _edge)))
        card.y = Math.round(_barBottom + AzTheme.px(AzTheme.popupDrop))
        _placed = true
    }

    Component.onCompleted:  { reposition(); placeTimer.arm() }
    onVisibleChanged: {
        if (visible) {
            reposition()
            Qt.callLater(reposition)
            placeTimer.arm()
        } else {
            _placed = false
        }
    }
    onWidthChanged:         reposition()
    onHeightChanged:        reposition()
    onAnchorItemChanged:    { reposition(); Qt.callLater(reposition) }
    onTopPanelItemChanged:  { reposition(); Qt.callLater(reposition) }

    // A panel opened without a button or top bar is placed anyway once this runs out.
    // It is long enough for a slow (Debug) asynchronous load to hand its anchor over.
    Timer {
        id:       placeTimer
        interval: 1000
        property bool expired: false
        onTriggered: { expired = true; root.reposition() }
        function arm() { expired = false; restart() }
    }

    // Two-finger gestures over the panel must not zoom the map underneath.
    PinchHandler {
        target:           null
        acceptedDevices:  PointerDevice.TouchScreen | PointerDevice.TouchPad
        grabPermissions:  PointerHandler.CanTakeOverFromAnything
    }

    MouseArea {
        id:              backdrop
        x:               0
        y:               root._barBottom
        width:           root.width
        height:          Math.max(0, root.height - y)
        acceptedButtons: Qt.AllButtons
        hoverEnabled:    true
        preventStealing: true
        onWheel:         (wheel) => { wheel.accepted = true }
        onClicked:       (mouse) => { if (mouse.button === Qt.LeftButton) root.closeRequested() }
    }

    Item {
        id:      card
        visible: root._placed
        width:   Math.min(root.cardWidth, root.width - root._leftBound - root._edge)
        height: Math.min(root.maxCardHeight,
                         root.height - y - root._edge,
                         flick.y + body.implicitHeight + root._pad)

        onWidthChanged: root.reposition()

        RectangularShadow {
            anchors.fill: cardBackground
            offset.y:     AzTheme.px(12)
            blur:         AzTheme.px(32)
            radius:       cardBackground.radius
            color:        AzTheme.popupShadow
        }

        AzGradientRect {
            id:            cardBackground
            anchors.fill:  parent
            angle:         AzTheme.panelGradientAngle
            startColor:    AzTheme.panelGradientStart
            startPosition: AzTheme.panelGradientStartPos
            endColor:      AzTheme.panelGradientEnd
            endPosition:   AzTheme.panelGradientEndPos
            radius:        AzTheme.px(AzTheme.popupRadius)
            borderColor:   AzTheme.panelBorder
            borderWidth:   1
        }

        // Clicks and the wheel on the card stay on the card.
        MouseArea {
            anchors.fill:    parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled:    true
            preventStealing: true
            onWheel:         (wheel) => { wheel.accepted = true }
        }

        Item {
            id:     header
            x:      root._pad
            y:      root._pad
            width:  card.width - 2 * root._pad
            height: AzTheme.px(32)

            Text {
                anchors.left:           parent.left
                anchors.right:          headerButtons.left
                anchors.rightMargin:    AzTheme.px(8)
                anchors.verticalCenter: parent.verticalCenter
                elide:                  Text.ElideRight
                text:                   root.title
                color:                  AzTheme.textCard
                font.family:            AzTheme.fontFamily
                font.weight:            Font.Medium
                font.pixelSize:         AzTheme.fontPx(AzTheme.popupTitleSize)
            }

            Row {
                id:                     headerButtons
                anchors.right:          parent.right
                anchors.rightMargin:    -AzTheme.px(6)
                anchors.verticalCenter: parent.verticalCenter
                spacing:                AzTheme.px(2)

                AzIconButton {
                    visible:    root.settingsVisible
                    iconSource: "qrc:/res/AZSHIELD_ICON/v2/popup_settings.svg"
                    onClicked:  root.settingsClicked()
                }

                AzIconButton {
                    iconSource: "qrc:/res/AZSHIELD_ICON/v2/popup_close.svg"
                    onClicked:  root.closeRequested()
                }
            }
        }

        Column {
            id:      fixedColumn
            x:       root._pad
            y:       header.y + header.height + (height > 0 ? root._gap : 0)
            width:   header.width
            spacing: root._gap
        }

        Flickable {
            id:                 flick
            x:                  root._pad
            y:                  fixedColumn.y + fixedColumn.height + root._gap
            width:              header.width
            height:             Math.max(0, card.height - y - root._pad)
            clip:               true
            contentWidth:       width
            contentHeight:      body.implicitHeight
            boundsBehavior:     Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive:        contentHeight > height + 1

            ScrollBar.vertical: ScrollBar {
                id:          scrollBar
                parent:      card
                x:           card.width - width - AzTheme.px(6)
                y:           flick.y
                height:      flick.height
                padding:     0
                policy:      flick.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                background:  null
                contentItem: Rectangle {
                    implicitWidth:  Math.max(3, AzTheme.px(4))
                    radius:         width / 2
                    color:          AzTheme.cardHoverBorder
                    opacity:        scrollBar.active ? 1 : 0.5
                }
            }

            Column {
                id:      body
                width:   flick.width
                spacing: root._gap
            }
        }
    }
}

import QtQuick
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls
import QGroundControl.UTMSP

/// Confirmation of a guided action (ARM, takeoff, RTL, set home...): the message,
/// "Xeyr" and a green "Bəli" (red for an emergency stop), and the keyboard hint, on
/// the panel card of the new design.
Item {
    id:         _root
    width:      Math.min(AzTheme.px(400), parent ? parent.width - 2 * AzTheme.px(16) : AzTheme.px(400))
    height:     card.height
    visible:    false

    anchors.top:              parent.top
    anchors.topMargin:        50
    anchors.horizontalCenter: parent.horizontalCenter

    property var    guidedController
    property var    guidedValueSlider
    property string title
    property alias  message:        messageText.text
    property int    action
    property var    actionData
    property bool   hideTrigger:    false
    property var    mapIndicator
    property string optionText
    property bool   optionChecked:  false

    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    // Properties of UTM adapter
    property bool   utmspSliderTrigger
    property bool   _utmspEnabled:                       QGroundControl.utmspSupported

    readonly property real _pad: AzTheme.px(24)
    readonly property real _gap: AzTheme.px(16)

    Component.onCompleted: guidedController.confirmDialog = this

    onVisibleChanged: {
        if (visible) {
            _root.forceActiveFocus()
        }
    }

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }

    function show(immediate) {
        if (immediate) {
            visible = true
        } else {
            visibleTimer.restart()
        }
    }

    function confirmCancelled() {
        guidedValueSlider.visible = false
        visible = false
        hideTrigger = false
        visibleTimer.stop()
        if (mapIndicator) {
            mapIndicator.actionCancelled()
            mapIndicator = undefined
        }
    }

    function executeConfirmedAction() {
        _root.visible = false
        var sliderOutputValue = 0
        if (guidedValueSlider.visible) {
            sliderOutputValue = guidedValueSlider.getOutputValue()
            guidedValueSlider.visible = false
        }
        hideTrigger = false
        guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
        if (mapIndicator) {
            mapIndicator.actionConfirmed()
            mapIndicator = undefined
        }

        UTMSPStateStorage.indicatorOnMissionStatus = true
        UTMSPStateStorage.currentNotificationIndex = 7
        UTMSPStateStorage.currentStateIndex = 3
    }

    // B / Y / E or Enter confirm, X / N / H or Esc cancel.
    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_B:
        case Qt.Key_E:
        case Qt.Key_Y:
        case Qt.Key_Return:
        case Qt.Key_Enter:
            executeConfirmedAction()
            event.accepted = true
            break
        case Qt.Key_X:
        case Qt.Key_H:
        case Qt.Key_N:
        case Qt.Key_Escape:
            confirmCancelled()
            event.accepted = true
            break
        }
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    visible = true
    }

    Item {
        id:     card
        width:  parent.width
        height: content.height + 2 * _root._pad

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
            radius:        AzTheme.px(16)
            borderColor:   AzTheme.panelBorder
            borderWidth:   1
        }

        // Clicks on the card do not reach the map.
        MouseArea {
            anchors.fill:    parent
            acceptedButtons: Qt.AllButtons
            onWheel:         (wheel) => { wheel.accepted = true }
        }

        Column {
            id:      content
            x:       _root._pad
            y:       _root._pad
            width:   card.width - 2 * _root._pad
            spacing: _root._gap

            Text {
                id:                  messageText
                width:               parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode:            Text.WordWrap
                color:               AzTheme.textCard
                font.family:         AzTheme.fontFamily
                font.pixelSize:      AzTheme.fontPx(17)
                lineHeight:          1.15
            }

            AzSettingRow {
                width:        parent.width
                visible:      _root.optionText !== ""
                label:        _root.optionText
                controlWidth: optionSwitch.implicitWidth

                AzSwitch {
                    id:        optionSwitch
                    anchors.verticalCenter: parent.verticalCenter
                    checked:   _root.optionChecked
                    onClicked: _root.optionChecked = !_root.optionChecked
                }
            }

            Row {
                width:   parent.width
                spacing: AzTheme.px(12)

                AzButton {
                    width:     (parent.width - parent.spacing) / 2
                    height:    AzTheme.px(44)
                    textSize:  17
                    text:      qsTr("Xeyr")
                    onClicked: confirmCancelled()
                }

                AzButton {
                    width:     (parent.width - parent.spacing) / 2
                    height:    AzTheme.px(44)
                    textSize:  17
                    text:      qsTr("Bəli")
                    positive:  !_root._emergencyAction
                    danger:    _root._emergencyAction
                    onClicked: executeConfirmedAction()
                }
            }

            Row {
                spacing: AzTheme.px(8)

                QGCColoredImage {
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  AzTheme.px(16)
                    height:                 width
                    sourceSize.height:      height
                    fillMode:               Image.PreserveAspectFit
                    source:                 "qrc:/res/AZSHIELD_ICON/v2/popup_info.svg"
                    color:                  AzTheme.mutedText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:                   qsTr("Klaviatura: [B] Bəli, [X] Xeyr, [Esc] Ləğv")
                    color:                  AzTheme.mutedText
                    font.family:            AzTheme.fontFamily
                    font.pixelSize:         AzTheme.fontPx(13)
                }
            }
        }
    }
}

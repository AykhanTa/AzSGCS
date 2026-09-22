


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl

import QGroundControl.Controls

import QGroundControl.UTMSP

Rectangle {
    id:         _root
    width:      ScreenTools.defaultFontPixelWidth * 35
    height:     mainLayout.height + (_margins * 2)
    radius:     ScreenTools.defaultFontPixelWidth / 2
    color:      qgcPal.window
    visible:    false

    // ✅ DIALOG'U 60PX AŞAĞI İNDİR - BURAYA EKLE
    anchors.top: parent.top
    anchors.topMargin: 50  // 150px AŞAĞI
    anchors.horizontalCenter: parent.horizontalCenter

    property var    guidedController
    property var    guidedValueSlider
    property string title
    property alias  message:            messageText.text
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         ScreenTools.defaultFontPixelWidth / 2
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    // Properties of UTM adapter
    property bool   utmspSliderTrigger
    property bool   _utmspEnabled:                       QGroundControl.utmspSupported



    Component.onCompleted: guidedController.confirmDialog = this

    onVisibleChanged: {
        if (visible) {
            yesButton.focus = true
        }
    }

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }
//**********************************************************************************************************************************************************
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

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    visible = true
    }

    QGCPalette { id: qgcPal }

    ColumnLayout {
        id:                 mainLayout
        anchors.centerIn:   parent
        width:              parent.width - (_margins * 2)
        spacing:            _margins

        QGCLabel {
            id:                     messageText
            Layout.fillWidth:       true
            horizontalAlignment:    Text.AlignHCenter
            wrapMode:               Text.WordWrap
            font.pointSize:         ScreenTools.defaultFontPointSize
            font.bold:              true
        }

        QGCCheckBox {
            id:                 optionCheckBox
            Layout.alignment:   Qt.AlignHCenter
            text:               ""
            visible:            text !== ""
        }

        // Evet/Hayır Butonları - SLIDER YERİNE BURASI DEĞİŞTİ
        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            Layout.topMargin:   _margins * 2

            // HAYIR Butonu - KIRMIZI
            Rectangle {
                id: noButton
                Layout.fillWidth:   true
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.2  // YÜKSEKLİK AZALTILDI
                radius: ScreenTools.defaultFontPixelWidth / 2
                color: noMouseArea.pressed ? Qt.darker("#e74c3c", 1.2) : "#e74c3c"  // KIRMIZI
                border.color: Qt.darker("#e74c3c", 1.5)
                border.width: 2

                QGCLabel {
                    anchors.centerIn: parent
                    text: qsTr("Xeyr")
                    font.pointSize: ScreenTools.defaultFontPointSize
                    font.bold: true
                    color: "white"
                }

                QGCMouseArea {
                    id: noMouseArea
                    fillItem: parent
                    onClicked: confirmCancelled()
                }

                Keys.onReturnPressed: confirmCancelled()
                Keys.onEnterPressed: confirmCancelled()
            }

            // EVET Butonu - YEŞİL
            Rectangle {
                id: yesButton
                Layout.fillWidth:   true
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.2  // YÜKSEKLİK AZALTILDI
                radius: ScreenTools.defaultFontPixelWidth / 2
                color: yesMouseArea.pressed ? Qt.darker("#63992C", 1.2) : "#63992C"  // YEŞİL
                border.color: Qt.darker("#63992C", 1.5)
                border.width: 2

                QGCLabel {
                    anchors.centerIn: parent
                    text: qsTr("Bəli")
                    font.pointSize: ScreenTools.defaultFontPointSize
                    font.bold: true
                    color: "white"
                }

                QGCMouseArea {
                    id: yesMouseArea
                    fillItem: parent
                    onClicked: executeConfirmedAction()
                }

                Keys.onReturnPressed: executeConfirmedAction()
                Keys.onEnterPressed: executeConfirmedAction()
            }
        }

        // Klavye Kısayolları Bilgisi
        QGCLabel {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Klavye: [B] Bəli, [X] Xeyr, [Esc] İptal")
            font.pointSize: ScreenTools.defaultFontPointSize * 0.8
            color: qgcPal.text
            opacity: 0.7
        }
    }

    // Klavye olaylarını yakala
    Keys.onPressed: {
        switch(event.key) {
            case Qt.Key_E:
            case Qt.Key_Y:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                executeConfirmedAction()
                event.accepted = true
                break
            case Qt.Key_H:
            case Qt.Key_N:
            case Qt.Key_Escape:
                confirmCancelled()
                event.accepted = true
                break
        }
    }
}

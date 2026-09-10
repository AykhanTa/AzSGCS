import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id: overlay
    anchors.fill: parent
    color: "#00000080"
    z: 100

    // Loader-dən gələnlər
    property bool panelVisible: true
    property Item anchorItem: null
    property Item topPanelItem: null

    visible: panelVisible

    readonly property string _azIconBase: "qrc:/res/AZSHIELD_ICON/"

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    // ---- responsive ----
    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : Math.max(12, Qt.application.font.pixelSize)
    readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : Math.max(8,  Qt.application.font.pixelSize * 0.60)
    readonly property bool _compact: (width < 900) || (height < 650) || (_hasScreenTools && ScreenTools.isShortScreen)

    readonly property real _edge: Math.round(Math.max(8, _fontH * (_compact ? 0.75 : 0.95)))
    readonly property real _gap:  Math.round(Math.max(6, _fontH * (_compact ? 0.55 : 0.75)))
    readonly property real _pad:  Math.round(Math.max(8, _fontH * (_compact ? 0.50 : 0.70)))

    readonly property real _yMin: topPanelItem ? (topPanelItem.height + _gap) : _edge
    readonly property real _maxCardH: Math.max(260, overlay.height - _yMin - _edge)

    // ---- QGC facts/settings (QGC source ilə eyni) ----
    property var rtkSettings: QGroundControl.settingsManager.rtkSettings
    property var autoConnectFact: QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS

    readonly property int _trimble:    1
    readonly property int _septentrio: 2
    readonly property int _femtomes:   4
    readonly property int _ublox:      8
    readonly property int _all:        15

    readonly property int manufacturer: (rtkSettings && rtkSettings.baseReceiverManufacturers)
                                        ? rtkSettings.baseReceiverManufacturers.rawValue : 0
    readonly property int useFixedPosition: (rtkSettings && rtkSettings.useFixedBasePosition)
                                           ? rtkSettings.useFixedBasePosition.rawValue
                                           : BaseModeDefinition.BaseSurveyIn

    property int settingsDisplayId: _all

    function updateSettingsDisplayId() {
        switch (manufacturer) {
        case 0: settingsDisplayId = (_trimble | _septentrio | _femtomes | _ublox); break // All
        case 1: settingsDisplayId = _trimble; break
        case 2: settingsDisplayId = _septentrio; break
        case 3: settingsDisplayId = _femtomes; break
        case 4: settingsDisplayId = _ublox; break
        default: settingsDisplayId = _all; break
        }
    }

    function reposition() {
        var x = (overlay.width - card.width) / 2
        var y = _yMin

        if (anchorItem) {
            var p = anchorItem.mapToItem(overlay, 0, anchorItem.height)
            x = p.x + (anchorItem.width / 2) - (card.width / 2)
            y = p.y + _gap
        } else if (topPanelItem) {
            y = topPanelItem.height + _gap
        }

        y = Math.max(y, _yMin)

        card.x = _clamp(x, _edge, overlay.width  - card.width  - _edge)
        card.y = _clamp(y, _yMin, overlay.height - card.height - _edge)
    }

    Component.onCompleted: {
        updateSettingsDisplayId()
        Qt.callLater(reposition)
    }

    onManufacturerChanged: updateSettingsDisplayId()
    onWidthChanged:        Qt.callLater(reposition)
    onHeightChanged:       Qt.callLater(reposition)
    onAnchorItemChanged:   Qt.callLater(reposition)

    // Arxa hissəyə scroll/klik keçməsin
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: (mouse) => { mouse.accepted = true }
        onWheel: (wheel) => { wheel.accepted = true }
    }

    WheelHandler {
        target: overlay
        onWheel: (wheel) => { wheel.accepted = true }
    }

    Rectangle {
        id: card
        width:  Math.min(_compact ? 520 : 640, overlay.width  - (_edge * 2))
        color: "#2A2A2A"
        radius: 8
        border.width: 1
        border.color: "#444444"
        clip: true

        readonly property real _desiredH: titleBar.height + (2 * _pad) + settingsLayout.implicitHeight
        height: Math.min(_desiredH, _maxCardH)

        onWidthChanged:  Qt.callLater(reposition)
        onHeightChanged: Qt.callLater(reposition)

        // Title bar
        Rectangle {
            id: titleBar
            width: parent.width
            height: 39
            color: "#3D3B3B"
            radius: 4
            anchors.top: parent.top

            Text {
                text: qsTr("RTK GPS Settings")
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            Image {
                source: _azIconBase + "TopStatusPanel_Cixis.svg"
                width: 20
                height: 20
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof settingsLoader !== "undefined" && settingsLoader) {
                            settingsLoader.source = ""
                        } else {
                            overlay.panelVisible = false
                        }
                    }
                }
            }
        }

        Flickable {
            id: contentFlick
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: _pad
            clip: true

            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            contentWidth: width
            contentHeight: settingsLayout.implicitHeight
            interactive: contentHeight > height + 2

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

            ColumnLayout {
                id: settingsLayout
                width: contentFlick.width
                spacing: 10

                // ---- AutoConnect ----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 4
                    color: "#3D3B3B"
                    visible: autoConnectFact && autoConnectFact.visible

                    Text {
                        text: qsTr("AutoConnect")
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 14
                    }

                    Rectangle {
                        width: 36
                        height: 20
                        radius: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        border.color: "#AAAAAA"
                        color: (autoConnectFact && autoConnectFact.rawValue) ? "#4CD964" : "#888888"

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: "#2A2A2A"
                            anchors.verticalCenter: parent.verticalCenter
                            x: (autoConnectFact && autoConnectFact.rawValue) ? parent.width - width - 2 : 2
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (autoConnectFact) autoConnectFact.rawValue = !autoConnectFact.rawValue
                            }
                        }
                    }
                }

                // ---- Settings displayed ----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    radius: 4
                    color: "#3D3B3B"
                    visible: rtkSettings && rtkSettings.baseReceiverManufacturers && rtkSettings.baseReceiverManufacturers.visible

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            text: qsTr("Settings displayed")
                            color: "white"
                            font.pixelSize: 14
                        }

                        Item { Layout.fillWidth: true }

                        // ✅ Ağ rəng + daha dar en (yalnız bu hissə dəyişdi)
                        Rectangle {
                            id: comboFrame
                            Layout.preferredHeight: 34
                            Layout.preferredWidth: _clamp(parent.width * 0.42, 170, 230)   // eni azaltdım
                            Layout.minimumWidth: 170
                            radius: 4
                            color: "white"
                            border.color: "#A0A0A0"
                            border.width: 1
                            clip: true

                            FactComboBox {
                                id: manufacturerCombo
                                anchors.fill: parent
                                fact: rtkSettings.baseReceiverManufacturers

                                // ağ fon üstündə qara yazı
                                background: Rectangle { color: "transparent" }

                                contentItem: Text {
                                    text: manufacturerCombo.displayText
                                    color: "#111111"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                indicator: Text {
                                    text: "\u25BE" // ▼
                                    color: "#111111"
                                    font.pixelSize: 16
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }

                // ---- Survey-In / Specify position ----
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    radius: 4
                    color: "#3D3B3B"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 14

                        QGCRadioButton {
                            text: qsTr("Survey-In")
                            checked: useFixedPosition == BaseModeDefinition.BaseSurveyIn
                            onClicked: rtkSettings.useFixedBasePosition.rawValue = BaseModeDefinition.BaseSurveyIn
                            visible: settingsDisplayId & _all
                        }

                        QGCRadioButton {
                            text: qsTr("Specify position")
                            checked: useFixedPosition == BaseModeDefinition.BaseFixed
                            onClicked: rtkSettings.useFixedBasePosition.rawValue = BaseModeDefinition.BaseFixed
                            visible: settingsDisplayId & _all
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                // ---- Survey-In Accuracy ----
                Rectangle {
                    Layout.fillWidth: true
                    radius: 4
                    color: "#3D3B3B"
                    visible: (
                        useFixedPosition == BaseModeDefinition.BaseSurveyIn
                        && rtkSettings && rtkSettings.surveyInAccuracyLimit && rtkSettings.surveyInAccuracyLimit.visible
                        && (settingsDisplayId & _ublox)
                    )

                    implicitHeight: accuracySlider.implicitHeight + 20

                    FactSlider {
                        id: accuracySlider
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        label: qsTr("Accuracy")
                        fact: rtkSettings.surveyInAccuracyLimit
                        majorTickStepSize: 0.1
                    }
                }

                // ---- Survey-In Min Duration ----
                Rectangle {
                    Layout.fillWidth: true
                    radius: 4
                    color: "#3D3B3B"
                    visible: (
                        useFixedPosition == BaseModeDefinition.BaseSurveyIn
                        && rtkSettings && rtkSettings.surveyInMinObservationDuration && rtkSettings.surveyInMinObservationDuration.visible
                        && (settingsDisplayId & (_ublox | _femtomes | _trimble))
                    )

                    implicitHeight: minDurationSlider.implicitHeight + 20

                    FactSlider {
                        id: minDurationSlider
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        label: qsTr("Min Duration")
                        fact: rtkSettings.surveyInMinObservationDuration
                        majorTickStepSize: 10
                    }
                }

                // ---- Fixed base position ----
                Rectangle {
                    Layout.fillWidth: true
                    radius: 4
                    color: "#3D3B3B"
                    visible: (useFixedPosition == BaseModeDefinition.BaseFixed)

                    implicitHeight: fixedCol.implicitHeight + 20

                    ColumnLayout {
                        id: fixedCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        LabelledFactTextField {
                            Layout.fillWidth: true
                            label: rtkSettings.fixedBasePositionLatitude.shortDescription
                            fact:  rtkSettings.fixedBasePositionLatitude
                            visible: (settingsDisplayId & _all)
                        }

                        LabelledFactTextField {
                            Layout.fillWidth: true
                            label: rtkSettings.fixedBasePositionLongitude.shortDescription
                            fact:  rtkSettings.fixedBasePositionLongitude
                            visible: (settingsDisplayId & _all)
                        }

                        LabelledFactTextField {
                            Layout.fillWidth: true
                            label: rtkSettings.fixedBasePositionAltitude.shortDescription
                            fact:  rtkSettings.fixedBasePositionAltitude
                            visible: (settingsDisplayId & _all)
                        }

                        LabelledFactTextField {
                            Layout.fillWidth: true
                            label: rtkSettings.fixedBasePositionAccuracy.shortDescription
                            fact:  rtkSettings.fixedBasePositionAccuracy
                            visible: (settingsDisplayId & _ublox)
                        }

                        LabelledButton {
                            Layout.fillWidth: true
                            label: qsTr("Current Base Position")
                            buttonText: enabled ? qsTr("Save") : qsTr("Not Yet Valid")
                            enabled: QGroundControl.gpsRtk.valid.value
                            visible: true

                            onClicked: {
                                rtkSettings.fixedBasePositionLatitude.rawValue  = QGroundControl.gpsRtk.currentLatitude.rawValue
                                rtkSettings.fixedBasePositionLongitude.rawValue = QGroundControl.gpsRtk.currentLongitude.rawValue
                                rtkSettings.fixedBasePositionAltitude.rawValue  = QGroundControl.gpsRtk.currentAltitude.rawValue
                                rtkSettings.fixedBasePositionAccuracy.rawValue  = QGroundControl.gpsRtk.currentAccuracy.rawValue
                            }
                        }
                    }
                }
            }
        }
    }
}

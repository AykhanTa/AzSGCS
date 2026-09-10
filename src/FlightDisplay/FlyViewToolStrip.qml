//------isleyenkod-----
// import QtQuick
// import QtQuick.Layouts
// import QtQuick.Controls
// import QtQml.Models

// import QGroundControl
// import QGroundControl.Controls
// import QGroundControl.FlightDisplay

// HorizontalToolStrip {
//     id: toolStrip

//     signal displayPreFlightChecklist

//     FlyViewToolStripActionList {
//         id: actionList
//         onDisplayPreFlightChecklist: toolStrip.displayPreFlightChecklist()
//     }

//     FlyViewAdditionalActionsPanel {
//         additionalActions:  _additionalActions
//         mavlinkActions:     _mavlinkActions.actions
//         customActions:      _customActions
//     }

//     model: actionList.model

//     // ---------------- ALTITUDE PANEL ----------------
//     Rectangle {
//         id: altitudePanel
//         visible: actionList.altPanelVisible
//         width: 260
//         height: 160
//         radius: 4
//         color: Qt.rgba(0, 0, 0, 0.8)
//         z: toolStrip.z + 1

//         anchors.top: toolStrip.bottom
//         anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
//         anchors.horizontalCenter: toolStrip.horizontalCenter

//         onVisibleChanged: {
//             if (visible) {
//                 altitudeTargetInput.text = Math.round(actionList.currentAltitude).toString()
//                 altitudeTargetInput.forceActiveFocus()
//             }
//         }

//         ColumnLayout {
//             anchors.fill: parent
//             anchors.margins: 8
//             spacing: 8

//             RowLayout {
//                 Layout.fillWidth: true
//                 spacing: 8

//                 Text {
//                     text: qsTr("Hündürlük:")
//                     color: "white"
//                     font.pixelSize: 15
//                     Layout.alignment: Qt.AlignVCenter
//                     Layout.preferredWidth: 70
//                 }

//                 TextField {
//                     id: altitudeTargetInput
//                     Layout.alignment: Qt.AlignVCenter
//                     Layout.minimumWidth: 60
//                     Layout.preferredWidth: Math.max(60, contentWidth + 20)
//                     text: ""
//                     color: "white"
//                     font.pixelSize: 15
//                     inputMethodHints: Qt.ImhPreferNumbers

//                     validator: IntValidator { bottom: 0; top: 50000 }

//                     background: Rectangle {
//                         color: "transparent"
//                         border.color: Qt.rgba(255, 255, 255, 0.5)
//                         border.width: 1
//                         radius: 2
//                     }

//                     Keys.onPressed: function(event) {
//                         if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
//                             okAltButton.clicked()
//                             event.accepted = true
//                         }
//                     }
//                 }

//                 Text {
//                     text: QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
//                     color: "white"
//                     font.pixelSize: 15
//                     Layout.alignment: Qt.AlignVCenter
//                     Layout.leftMargin: 6        // TextField böyüdükcə arada boşluq saxla
//                 }

//                 Item { Layout.fillWidth: true }
//             }

//             Text {
//                 text: qsTr("Son tətbiq olunan: ")
//                       + Math.round(actionList.lastAppliedAltitude) + " " + QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
//                 color: "white"
//                 font.pixelSize: 14
//                 Layout.fillWidth: true
//             }

//             RowLayout {
//                 Layout.fillWidth: true
//                 spacing: 8

//                 QGCButton {
//                     iconSource: "file:///C:/Users/user/qgroundcontrol/resources/AZSHIELD_ICON/arrow-up.svg"
//                     Layout.preferredWidth: 70
//                     Layout.fillWidth: true
//                     onClicked: {
//                         var v = actionList.parseUserFloat(
//                             altitudeTargetInput.text,
//                             actionList.currentAltitude
//                         )
//                         v += actionList._altStepAppUnits
//                         altitudeTargetInput.text = Math.round(v).toString()
//                     }
//                 }

//                 QGCButton {
//                     iconSource: "file:///C:/Users/user/qgroundcontrol/resources/AZSHIELD_ICON/arrow-down.svg"
//                     Layout.preferredWidth: 70
//                     Layout.fillWidth: true
//                     onClicked: {
//                         var v = actionList.parseUserFloat(
//                             altitudeTargetInput.text,
//                             actionList.currentAltitude
//                         )
//                         v -= actionList._altStepAppUnits
//                         altitudeTargetInput.text = Math.round(v).toString()
//                     }
//                 }

//                 QGCButton {
//                     id: okAltButton
//                     text: qsTr("OK")
//                     Layout.preferredWidth: 70
//                     Layout.fillWidth: true
//                     onClicked: {
//                         var v = parseInt(altitudeTargetInput.text)
//                         if (isNaN(v)) {
//                             //console.log("ApplyAlt: invalid altitude in input")
//                             return
//                         }
//                         actionList.applyAltitudeTarget(v)
//                     }
//                 }
//             }
//         }
//     }

//     // ---------------- SPEED PANEL ----------------
//     Rectangle {
//         id: speedPanel
//         visible: actionList.speedPanelVisible
//         width: 260
//         height: 160
//         radius: 4
//         color: Qt.rgba(0, 0, 0, 0.8)
//         z: toolStrip.z + 1

//         anchors.top: toolStrip.bottom
//         anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
//         anchors.horizontalCenter: toolStrip.horizontalCenter

//         onVisibleChanged: {
//             if (visible) {
//                 speedTargetInput.text = Math.round(actionList.currentSpeed).toString()
//                 speedTargetInput.forceActiveFocus()
//             }
//         }

//         ColumnLayout {
//             anchors.fill: parent
//             anchors.margins: 8
//             spacing: 8

//             RowLayout {
//                 Layout.fillWidth: true
//                 spacing: 8

//                 Text {
//                     text: qsTr("Sürət:")
//                     color: "white"
//                     font.pixelSize: 15
//                     Layout.alignment: Qt.AlignVCenter
//                     Layout.preferredWidth: 70
//                 }

//                 TextField {
//                     id: speedTargetInput
//                     Layout.alignment: Qt.AlignVCenter
//                     Layout.minimumWidth: 60
//                     Layout.preferredWidth: Math.max(60, contentWidth + 20)
//                     text: ""
//                     color: "white"
//                     font.pixelSize: 15
//                     inputMethodHints: Qt.ImhPreferNumbers

//                     validator: IntValidator { bottom: 0; top: 2000 }

//                     background: Rectangle {
//                         color: "transparent"
//                         border.color: Qt.rgba(255, 255, 255, 0.5)
//                         border.width: 1
//                         radius: 2
//                     }

//                     Keys.onPressed: function(event) {
//                         if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
//                             okSpeedButton.clicked()
//                             event.accepted = true
//                         }
//                     }
//                 }

//                 Text {
//                     text: QGroundControl.unitsConversion.appSettingsSpeedUnitsString
//                     color: "white"
//                     font.pixelSize: 15
//                     Layout.alignment: Qt.AlignVCenter
//                     Layout.leftMargin: 6         // TextField böyüdükcə boşluq saxla
//                 }

//                 Item { Layout.fillWidth: true }
//             }

//             Text {
//                 text: qsTr("Son tətbiq olunan: ")
//                       + Math.round(actionList.lastAppliedSpeed) + " "
//                       + QGroundControl.unitsConversion.appSettingsSpeedUnitsString
//                 color: "white"
//                 font.pixelSize: 14
//                 Layout.fillWidth: true
//             }

//             RowLayout {
//                 Layout.fillWidth: true
//                 spacing: 8

//                 QGCButton {
//                     iconSource: "file:///C:/Users/user/qgroundcontrol/resources/AZSHIELD_ICON/arrow-up.svg"
//                     Layout.preferredWidth: 70
//                     Layout.fillWidth: true
//                     onClicked: {
//                         var v = actionList.parseUserFloat(
//                             speedTargetInput.text,
//                             actionList.currentSpeed
//                         )
//                         v += actionList._speedStepAppUnits
//                         speedTargetInput.text = Math.round(v).toString()
//                     }
//                 }

//                 QGCButton {
//                     iconSource: "file:///C:/Users/user/qgroundcontrol/resources/AZSHIELD_ICON/arrow-down.svg"
//                     Layout.preferredWidth: 70
//                     Layout.fillWidth: true
//                     onClicked: {
//                         var v = actionList.parseUserFloat(
//                             speedTargetInput.text,
//                             actionList.currentSpeed
//                         )
//                         v -= actionList._speedStepAppUnits
//                         speedTargetInput.text = Math.round(v).toString()
//                     }
//                 }

//                 QGCButton {
//                     id: okSpeedButton
//                     text: qsTr("OK")
//                     Layout.preferredWidth: 70
//                     Layout.fillWidth: true
//                     onClicked: {
//                         var v = parseInt(speedTargetInput.text)
//                         if (isNaN(v)) {
//                             //console.log("ApplySpeed: invalid speed in input")
//                             return
//                         }
//                         actionList.applySpeedTarget(v)
//                     }
//                 }
//             }
//         }
//     }
// }










//----------androidkod--------
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

Item {
    id: root

    signal displayPreFlightChecklist
    property bool verticalMode: false

    // Insets (yalnız solda vertical olanda)
    property real leftEdgeTopInset:    (visible && verticalMode) ? (x + width)  : 0
    property real leftEdgeCenterInset: leftEdgeTopInset
    property real topEdgeLeftInset:    (visible && verticalMode) ? (y + height) : 0

    // ✅ paneli klik olunan button-un səviyyəsində açmaq üçün
    property real _popupTopMargin: 0

    // ✅ Kiçik ekranda ölçülər (daha balaca)
    readonly property real _pad:    Math.max(4, ScreenTools.defaultFontPixelHeight * 0.28)
    readonly property real _vW:     Math.max(86, Math.min(104, width > 0 ? width : ScreenTools.defaultFontPixelHeight * 5.2))
    readonly property real _vIcon:  Math.max(20, Math.min(28, ScreenTools.defaultFontPixelHeight * 1.55))
    readonly property real _vLabel: Math.max(9,  Math.min(11, ScreenTools.defaultFontPixelHeight * 0.80))
    readonly property real _vBtnH:  Math.max(46, _vIcon + _vLabel + _pad * 1.25)

    implicitWidth:  verticalMode ? _vW : hStrip.implicitWidth
    implicitHeight: verticalMode ? Math.min(vCol.implicitHeight + _pad * 2, ScreenTools.defaultFontPixelHeight * 22)
                                 : hStrip.implicitHeight

    FlyViewToolStripActionList {
        id: actionList
        onDisplayPreFlightChecklist: root.displayPreFlightChecklist()
    }

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    // ToolStripAction trigger
    function triggerAction(actionObj, senderObj) {
        if (!actionObj) return
        if (actionObj.enabled !== undefined && !actionObj.enabled) return

        // ✅ Altitude/Speed açılırsa paneli button səviyyəsinə gətir
        if (root.verticalMode && senderObj &&
            (actionObj === actionList.changeAltActionRef || actionObj === actionList.changeSpeedActionRef)) {

            var yInRoot = senderObj.mapToItem(root, 0, 0).y
            var maxY = Math.max(root._pad, root.height - altitudePanel.height - root._pad)
            root._popupTopMargin = _clamp(yInRoot, root._pad, maxY)
        }

        // QGC ToolStripAction triggered(sender) formasını gözləyir
        if (typeof actionObj.triggered === "function") {
            actionObj.triggered(senderObj ? senderObj : root)
            return
        }
        if (typeof actionObj.trigger === "function") {
            actionObj.trigger()
        }
    }

    // ================= LARGE (default QGC) =================
    // HorizontalToolStrip {
    //     id: hStrip
    //     anchors.fill: parent
    //     visible: !root.verticalMode
    //     model: actionList.model

    //     // FlyViewAdditionalActionsPanel {
    //     //     additionalActions:  hStrip._additionalActions
    //     //     mavlinkActions:     hStrip._mavlinkActions.actions
    //     //     customActions:      hStrip._customActions
    //     // }


    //     FlyViewAdditionalActionsPanel {
    //         additionalActions:  (hStrip && hStrip._additionalActions) ? hStrip._additionalActions : null
    //         mavlinkActions:     (hStrip && hStrip._mavlinkActions && hStrip._mavlinkActions.actions) ? hStrip._mavlinkActions.actions : null
    //         customActions:      (hStrip && hStrip._customActions) ? hStrip._customActions : null
    //     }

    // }

    // ================= LARGE (default QGC) =================
        HorizontalToolStrip {
            id: hStrip
            anchors.fill: parent
            visible: !root.verticalMode
            model: actionList.model

            // ✅ BURADA EN (width) və HÜNDÜRLÜK (height) DƏYƏRLƏRİNİ ARTIRIRIQ:
            // Bunlar əvvəlki dəyərlərini FlyViewBottomRightRowLayout-dan (məsələn, 350) götürürdü
            // İndi hündürlüyü də artırırıq ki, düymələr rahat yerləşsin

            // Bu hissə əvvəlki kimi qalır (FlyViewAdditionalActionsPanel)
            FlyViewAdditionalActionsPanel {
                additionalActions:  (hStrip && hStrip._additionalActions) ? hStrip._additionalActions : null
                mavlinkActions:     (hStrip && hStrip._mavlinkActions && hStrip._mavlinkActions.actions) ? hStrip._mavlinkActions.actions : null
                customActions:      (hStrip && hStrip._customActions) ? hStrip._customActions : null
            }
        }

    // ================= SMALL (vertical column + scroll) =================
    Rectangle {
        id: vBg
        anchors.fill: parent
        visible: root.verticalMode
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.50)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
    }

    Flickable {
        id: vFlick
        anchors.fill: parent
        visible: root.verticalMode
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: true

        contentWidth: width
        contentHeight: vCol.implicitHeight + root._pad * 2

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: vCol
            x: root._pad
            y: root._pad
            width: vFlick.width - root._pad * 2
            spacing: Math.max(4, root._pad * 0.55)

            Repeater {
                model: actionList.model

                delegate: Item {
                    id: btn
                    property var a: modelData
                    property bool _enabled: (a && a.enabled !== undefined) ? a.enabled : true
                    property bool _visible: (a && a.visible !== undefined) ? a.visible : true

                    width: vCol.width
                    height: root._vBtnH
                    visible: _visible

                    // ✅ Hover/active rənglərini dəyişmirik (mavi qalma problemi də burdan idi)
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Qt.rgba(0, 0, 0, 0.50)
                        border.color: Qt.rgba(1, 1, 1, 0.16)
                        border.width: 1
                        opacity: btn._enabled ? 1.0 : 0.35
                    }

                    QGCMouseArea {
                        anchors.fill: parent
                        enabled: btn._enabled
                        onClicked: root.triggerAction(btn.a, btn)
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.max(2, root._pad * 0.20)

                        QGCColoredImage {
                            source: btn.a ? btn.a.iconSource : ""
                            mipmap: true
                            width: root._vIcon
                            height: root._vIcon
                            sourceSize.width: width
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                            opacity: 0.95
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        QGCLabel {
                            text: btn.a ? btn.a.text : ""
                            color: "white"
                            font.pixelSize: root._vLabel
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            elide: Text.ElideRight
                            width: btn.width - root._pad
                        }
                    }
                }
            }
        }
    }

    // ========= Altitude/Speed apply =========
    function applyAltitudeFromInput() {
        var v = parseInt(altitudeTargetInput.text)
        if (isNaN(v)) return
        actionList.applyAltitudeTarget(v)
    }

    function applySpeedFromInput() {
        var v = parseInt(speedTargetInput.text)
        if (isNaN(v)) return
        actionList.applySpeedTarget(v)
    }

    // ================== ALTITUDE PANEL ==================
    Rectangle {
        id: altitudePanel
        visible: actionList.altPanelVisible
        width: 260
        height: 160
        radius: 4
        color: Qt.rgba(0, 0, 0, 0.80)
        z: 999

        // large mode default
        anchors.top: root.bottom
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
        anchors.horizontalCenter: root.horizontalCenter

        states: [
            State {
                name: "vertical"
                when: root.verticalMode
                AnchorChanges {
                    target: altitudePanel
                    anchors.top: root.top
                    anchors.left: root.right
                    anchors.horizontalCenter: undefined
                }
                PropertyChanges {
                    target: altitudePanel
                    anchors.topMargin: root._popupTopMargin
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.75
                }
            }
        ]

        onVisibleChanged: {
            if (visible) {
                altitudeTargetInput.text = Math.round(actionList.currentAltitude).toString()
                altitudeTargetInput.forceActiveFocus()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text { text: qsTr("Hündürlük:"); color: "white"; font.pixelSize: 15; Layout.preferredWidth: 70 }

                TextField {
                    id: altitudeTargetInput
                    Layout.minimumWidth: 60
                    Layout.preferredWidth: Math.max(60, contentWidth + 20)
                    color: "white"
                    font.pixelSize: 15
                    inputMethodHints: Qt.ImhPreferNumbers
                    validator: IntValidator { bottom: 0; top: 50000 }

                    background: Rectangle {
                        color: "transparent"
                        border.color: Qt.rgba(255,255,255,0.5)
                        border.width: 1
                        radius: 2
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.applyAltitudeFromInput()
                            event.accepted = true
                        }
                    }
                }

                Text {
                    text: QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
                    color: "white"
                    font.pixelSize: 15
                    Layout.leftMargin: 6
                }

                Item { Layout.fillWidth: true }
            }

            Text {
                text: qsTr("Son tətbiq olunan: ") + Math.round(actionList.lastAppliedAltitude) + " " +
                      QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString
                color: "white"
                font.pixelSize: 14
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QGCButton {
                    iconSource: "qrc:/res/AZSHIELD_ICON/arrow-up.svg"
                    Layout.preferredWidth: 70
                    Layout.fillWidth: true
                    onClicked: {
                        var v = actionList.parseUserFloat(altitudeTargetInput.text, actionList.currentAltitude)
                        v += actionList._altStepAppUnits
                        altitudeTargetInput.text = Math.round(v).toString()
                    }
                }

                QGCButton {
                    iconSource: "qrc:/res/AZSHIELD_ICON/arrow-down.svg"
                    Layout.preferredWidth: 70
                    Layout.fillWidth: true
                    onClicked: {
                        var v = actionList.parseUserFloat(altitudeTargetInput.text, actionList.currentAltitude)
                        v -= actionList._altStepAppUnits
                        altitudeTargetInput.text = Math.round(v).toString()
                    }
                }

                QGCButton {
                    text: qsTr("OK")
                    Layout.preferredWidth: 70
                    Layout.fillWidth: true
                    onClicked: root.applyAltitudeFromInput()
                }
            }
        }
    }

    // ================== SPEED PANEL ==================
    Rectangle {
        id: speedPanel
        visible: actionList.speedPanelVisible
        width: 260
        height: 160
        radius: 4
        color: Qt.rgba(0, 0, 0, 0.80)
        z: 999

        // large mode default
        anchors.top: root.bottom
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
        anchors.horizontalCenter: root.horizontalCenter

        states: [
            State {
                name: "vertical"
                when: root.verticalMode
                AnchorChanges {
                    target: speedPanel
                    anchors.top: root.top
                    anchors.left: root.right
                    anchors.horizontalCenter: undefined
                }
                PropertyChanges {
                    target: speedPanel
                    anchors.topMargin: root._popupTopMargin
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.75
                }
            }
        ]

        onVisibleChanged: {
            if (visible) {
                speedTargetInput.text = Math.round(actionList.currentSpeed).toString()
                speedTargetInput.forceActiveFocus()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text { text: qsTr("Sürət:"); color: "white"; font.pixelSize: 15; Layout.preferredWidth: 70 }

                TextField {
                    id: speedTargetInput
                    Layout.minimumWidth: 60
                    Layout.preferredWidth: Math.max(60, contentWidth + 20)
                    color: "white"
                    font.pixelSize: 15
                    inputMethodHints: Qt.ImhPreferNumbers
                    validator: IntValidator { bottom: 0; top: 2000 }

                    background: Rectangle {
                        color: "transparent"
                        border.color: Qt.rgba(255,255,255,0.5)
                        border.width: 1
                        radius: 2
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.applySpeedFromInput()
                            event.accepted = true
                        }
                    }
                }

                Text {
                    text: QGroundControl.unitsConversion.appSettingsSpeedUnitsString
                    color: "white"
                    font.pixelSize: 15
                    Layout.leftMargin: 6
                }

                Item { Layout.fillWidth: true }
            }

            Text {
                text: qsTr("Son tətbiq olunan: ") + Math.round(actionList.lastAppliedSpeed) + " " +
                      QGroundControl.unitsConversion.appSettingsSpeedUnitsString
                color: "white"
                font.pixelSize: 14
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QGCButton {
                    iconSource: "qrc:/res/AZSHIELD_ICON/arrow-up.svg"
                    Layout.preferredWidth: 70
                    Layout.fillWidth: true
                    onClicked: {
                        var v = actionList.parseUserFloat(speedTargetInput.text, actionList.currentSpeed)
                        v += actionList._speedStepAppUnits
                        speedTargetInput.text = Math.round(v).toString()
                    }
                }

                QGCButton {
                    iconSource: "qrc:/res/AZSHIELD_ICON/arrow-down.svg"
                    Layout.preferredWidth: 70
                    Layout.fillWidth: true
                    onClicked: {
                        var v = actionList.parseUserFloat(speedTargetInput.text, actionList.currentSpeed)
                        v -= actionList._speedStepAppUnits
                        speedTargetInput.text = Math.round(v).toString()
                    }
                }

                QGCButton {
                    text: qsTr("OK")
                    Layout.preferredWidth: 70
                    Layout.fillWidth: true
                    onClicked: root.applySpeedFromInput()
                }
            }
        }
    }
}

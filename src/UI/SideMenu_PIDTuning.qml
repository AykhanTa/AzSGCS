import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "black"

    readonly property real _m: Math.max(12, ScreenTools.defaultFontPixelHeight * 0.75)
    readonly property bool _compact: width < 1200 || height < 820
    readonly property real _side: Math.max(12, _m * 0.9)
    readonly property real _maxContentW: 1600

    property bool parametersReady: globals.activeVehicle
                                   && globals.activeVehicle.parameterManager
                                   && globals.activeVehicle.parameterManager.parametersReady

    QtObject {
        id: st
        property int tab: 0   // 0=Rate, 1=Attitude
    }

    // Arxa xəritəyə klik getməsin
    MouseArea {
        anchors.fill: parent
        z: 1
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
    }

    ColumnLayout {
        id: page
        z: 2
        anchors.fill: parent

        anchors.topMargin: 0
        anchors.leftMargin: root._side
        anchors.rightMargin: root._side
        anchors.bottomMargin: root._side

        // kompakt olanda aralıqlar azalsın
        spacing: root._compact ? (root._m * 0.65) : root._m

        // Header (başlıq + açıqlama bir-birinə yaxın)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: root._compact ? 3 : 6

            Text {
                text: qsTr("PID tənzimləmə")
                color: "white"
                font.pixelSize: root._compact ? 22 : 26
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("Uçuşun stabilliyini və reaksiya sürətini yaxşılaşdırmaq üçün Rate və Attitude nəzarətçilərinin PID parametrlərini tənzimləyin. Qrafikdə Response/Setpoint davranışını izləyin.")
                color: "#E8E8E8"
                font.pixelSize: 16
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // Avtopilot bağlantısı gözləyən kart
        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: "#3D3B3B"
            border.width: 1
            border.color: "#9D9D9D"
            visible: !root.parametersReady
            implicitHeight: 220

            Text {
                anchors.centerIn: parent
                width: parent.width - 2 * root._m
                text: qsTr("Parametrlər yüklənir...\nAvtopilot bağlantısını gözləyin")
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        // Body Loader — yalnız avtopilot qoşulduqda yüklənir.
        Loader {
            id: bodyLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.parametersReady
            active: root.parametersReady
            sourceComponent: bodyComponent
        }

        // Avtopilot qoşulu olmadıqda boş yeri aşağıda saxlayan filler
        // (Frame səhifəsindəki kimi)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: !root.parametersReady
            Layout.preferredHeight: root.parametersReady ? 0 : -1
            visible: !root.parametersReady
        }
    }

    // -------------------------
    // Body — tab düymələri + PIDTuning + axis məlumatları
    // -------------------------
    Component {
        id: bodyComponent

        ColumnLayout {
            id: bodyCol
            spacing: root._compact ? (root._m * 0.65) : root._m

            GridLayout {
                Layout.fillWidth: true
                columns: root._compact ? 1 : 2
                columnSpacing: root._m
                rowSpacing: root._m

                QGCButton {
                    text: qsTr("Rate Controller")
                    Layout.fillWidth: true
                    Layout.preferredHeight: root._compact
                                           ? ScreenTools.defaultFontPixelHeight * 1.9
                                           : ScreenTools.defaultFontPixelHeight * 2.7
                    primary: st.tab === 0
                    backgroundColor: st.tab === 0 ? "#4E4E4E" : "#2A2A2A"
                    onClicked: st.tab = 0

                    contentItem: Text {
                        text: parent.text
                        color: st.tab === 0 ? "#00FF00" : "white"
                        font.pixelSize: root._compact ? 13 : 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                QGCButton {
                    text: qsTr("Attitude Controller")
                    Layout.fillWidth: true
                    Layout.preferredHeight: root._compact
                                           ? ScreenTools.defaultFontPixelHeight * 1.9
                                           : ScreenTools.defaultFontPixelHeight * 2.7
                    primary: st.tab === 1
                    backgroundColor: st.tab === 1 ? "#4E4E4E" : "#2A2A2A"
                    onClicked: st.tab = 1

                    contentItem: Text {
                        text: parent.text
                        color: st.tab === 1 ? "#00FF00" : "white"
                        font.pixelSize: root._compact ? 13 : 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                id: pidHost
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                readonly property real contentW: Math.min(width, root._maxContentW)

                PIDTuning {
                    id: pidTuning
                    anchors.fill: parent
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: pidHost.contentW

                    availableWidth:  width
                    availableHeight: height

                    title: st.tab === 0 ? "Rate" : "Attitude"
                    tuningMode: Vehicle.ModeRateAndAttitude
                    unit:  st.tab === 0 ? "deg/s" : "deg"
                    chartDisplaySec: st.tab === 0 ? 3 : 8

                    axis: st.tab === 0
                          ? [ bodyCol.axisRateRoll, bodyCol.axisRatePitch, bodyCol.axisRateYaw ]
                          : [ bodyCol.axisAttRoll, bodyCol.axisAttPitch ]

                    showAutoModeChange: true
                    showAutoTuning:     true

                    Connections {
                        target: st
                        onTabChanged: {
                            if (pidTuning.axisIndexChanged) pidTuning.axisIndexChanged()
                            if (pidTuning.resetGraphs)      pidTuning.resetGraphs()
                        }
                    }
                }
            }

            // Axis data — bodyCol-un içində, ona görə yalnız Loader aktiv olduqda
            // (yəni avtopilot qoşulduqda) yaradılır.
            property var axisRateRoll: QtObject {
                property string name: qsTr("Roll")
                property var plot: [
                    { name: "Response", value: globals.activeVehicle.rollRate.value },
                    { name: "Setpoint", value: globals.activeVehicle.setpoint.rollRate.value }
                ]
                property var params: ListModel {
                    ListElement { title: qsTr("Porportional gain (FW_RR_P)"); description: qsTr("Porportional gain."); param: "FW_RR_P"; min: 0.0; max: 1; step: 0.005 }
                    ListElement { title: qsTr("Differential Gain (FW_RR_D)"); description: qsTr("Damping: increase to reduce overshoots and oscillations, but not higher than really needed."); param: "FW_RR_D"; min: 0.0; max: 1.0; step: 0.005 }
                    ListElement { title: qsTr("Integral Gain (FW_RR_I)"); description: qsTr("Generally does not need much adjustment, reduce this when seeing slow oscillations."); param: "FW_RR_I"; min: 0.0; max: 0.5; step: 0.005 }
                    ListElement { title: qsTr("Feedforward Gain (FW_RR_FF)"); description: qsTr("Feedforward gused to compensate for aerodynamic damping."); param: "FW_RR_FF"; min: 0.0; max: 10.0; step: 0.05 }
                }
            }

            property var axisRatePitch: QtObject {
                property string name: qsTr("Pitch")
                property var plot: [
                    { name: "Response", value: globals.activeVehicle.pitchRate.value },
                    { name: "Setpoint", value: globals.activeVehicle.setpoint.pitchRate.value }
                ]
                property var params: ListModel {
                    ListElement { title: qsTr("Porportional Gain (FW_PR_P)"); description: qsTr("Porportional Gain."); param: "FW_PR_P"; min: 0.0; max: 1; step: 0.005 }
                    ListElement { title: qsTr("Differential Gain (FW_PR_D)"); description: qsTr("Damping: increase to reduce overshoots and oscillations, but not higher than really needed."); param: "FW_PR_D"; min: 0.0; max: 1.00; step: 0.005 }
                    ListElement { title: qsTr("Integral Gain (FW_PR_I)"); description: qsTr("Generally does not need much adjustment, reduce this when seeing slow oscillations."); param: "FW_PR_I"; min: 0.0; max: 0.5; step: 0.005 }
                    ListElement { title: qsTr("Feedforward Gain (FW_PR_FF)"); description: qsTr("Feedforward gused to compensate for aerodynamic damping."); param: "FW_PR_FF"; min: 0.0; max: 10.0; step: 0.05 }
                }
            }

            property var axisRateYaw: QtObject {
                property string name: qsTr("Yaw")
                property var plot: [
                    { name: "Response", value: globals.activeVehicle.yawRate.value },
                    { name: "Setpoint", value: globals.activeVehicle.setpoint.yawRate.value }
                ]
                property var params: ListModel {
                    ListElement { title: qsTr("Porportional Gain (FW_YR_P)"); description: qsTr("Porportional Gain."); param: "FW_YR_P"; min: 0.0; max: 1; step: 0.005 }
                    ListElement { title: qsTr("Integral Gain (FW_YR_D)"); description: qsTr("Generally does not need much adjustment, reduce this when seeing slow oscillations."); param: "FW_YR_D"; min: 0.0; max: 1.0; step: 0.005 }
                    ListElement { title: qsTr("Integral Gain (FW_YR_I)"); description: qsTr("Generally does not need much adjustment, reduce this when seeing slow oscillations."); param: "FW_YR_I"; min: 0.0; max: 50.0; step: 0.5 }
                    ListElement { title: qsTr("Feedforward Gain (FW_YR_FF)"); description: qsTr("Feedforward gused to compensate for aerodynamic damping."); param: "FW_YR_FF"; min: 0.0; max: 10.0; step: 0.05 }
                    ListElement { title: qsTr("Roll control to yaw feedforward (FW_RLL_TO_YAW_FF)"); description: qsTr("Used to counteract the adverse yaw effect for fixed wings."); param: "FW_RLL_TO_YAW_FF"; min: 0.0; max: 1.0; step: 0.01 }
                }
            }

            property var axisAttRoll: QtObject {
                property string name: qsTr("Roll")
                property var plot: [
                    { name: "Response", value: globals.activeVehicle.roll.value },
                    { name: "Setpoint", value: globals.activeVehicle.setpoint.roll.value }
                ]
                property var params: ListModel {
                    ListElement { title: qsTr("Time constant (FW_R_TC)"); description: qsTr("The latency between a roll step input and the achieved setpoint (inverse to a P gain)"); param: "FW_R_TC"; min: 0.4; max: 1.0; step: 0.05 }
                }
            }

            property var axisAttPitch: QtObject {
                property string name: qsTr("Pitch")
                property var plot: [
                    { name: "Response", value: globals.activeVehicle.pitch.value },
                    { name: "Setpoint", value: globals.activeVehicle.setpoint.pitch.value }
                ]
                property var params: ListModel {
                    ListElement { title: qsTr("Time Constant (FW_P_TC)"); description: qsTr("The latency between a pitch step input and the achieved setpoint (inverse to a P gain)"); param: "FW_P_TC"; min: 0.2; max: 1.0; step: 0.05 }
                }
            }
        }
    }
}

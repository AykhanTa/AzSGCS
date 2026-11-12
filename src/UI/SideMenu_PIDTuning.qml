import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0

// PID tuning, in the new design: the vehicle setup page header, a pill tab bar for the
// Rate and Attitude controllers, and the tuning chart and cards in the design's colours
// (PIDTuning follows azInputStyle).
Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    // The chart, cards, sliders, fields and buttons take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    readonly property bool _compact: width < 1200 || height < 820
    readonly property real _m: AzTheme.px(_compact ? 12 : 16)
    readonly property real _side: AzTheme.px(_compact ? 12 : 20)
    readonly property real _maxContentW: 1600

    property bool parametersReady: globals.activeVehicle
                                   && globals.activeVehicle.parameterManager
                                   && globals.activeVehicle.parameterManager.parametersReady

    // Bu səhifədə scroll PIDTuning kontrolunun öz içindədir, ona görə başlığı
    // sadəcə onun məzmununa qoymaq mümkün deyil. Əvəzinə scroll aşağı gedəndə
    // başlıq yığılır (yer tutmur), yuxarı qayıdanda yenidən açılır.
    property bool _headerCollapsed: false
    property real _headerFactor:    (_headerCollapsed && parametersReady) ? 0 : 1

    Behavior on _headerFactor { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

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

        anchors.topMargin: AzTheme.px(20)
        anchors.leftMargin: root._side
        anchors.rightMargin: root._side
        anchors.bottomMargin: root._side

        // kompakt olanda aralıqlar azalsın
        spacing: root._m

        // Header (başlıq + açıqlama bir-birinə yaxın)
        // Hündürlüyü _headerFactor idarə edir; yığılanda ColumnLayout-un
        // aralığını da aparsın deyə tamam gizlənir.
        Item {
            id: headerArea
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(_fullH * root._headerFactor)
            visible: root._headerFactor > 0.01
            clip: true

            readonly property real _fullH: headerCol.implicitHeight

            ColumnLayout {
                id: headerCol
                width: headerArea.width
                // Yığılan hissə aşağı sıxılmasın, yuxarı sürüşsün.
                y: headerArea.height - headerArea._fullH
                spacing: AzTheme.px(6)

                Text {
                    text: qsTr("PID tənzimləmə")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(root._compact ? 18 : 20)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Uçuşun stabilliyini və reaksiya sürətini yaxşılaşdırmaq üçün Rate və Attitude nəzarətçilərinin PID parametrlərini tənzimləyin. Qrafikdə Response/Setpoint davranışını izləyin.")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(13)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // A status card with the vehicle state and what to expect
        Rectangle {
            Layout.fillWidth: true
            radius: AzTheme.px(AzTheme.cardRadius)
            border.width: 1
            border.color: AzTheme.cardBorder
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
            }
            visible: !root.parametersReady
            implicitHeight: AzTheme.px(200)

            Column {
                anchors.centerIn: parent
                width: parent.width - 2 * root._m
                spacing: AzTheme.px(10)

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: AzTheme.px(12); height: width; radius: width / 2
                    color: globals.activeVehicle ? AzTheme.statusOrange : AzTheme.mutedText
                }
                Text {
                    width: parent.width
                    text: globals.activeVehicle ? qsTr("Parametrlər yüklənir...") : qsTr("Aktiv aparat yoxdur")
                    color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(17)
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: globals.activeVehicle ? qsTr("Avtopilot bağlantısını gözləyin") : qsTr("Qoşulduqdan sonra PID parametrləri görünəcək.")
                    color: AzTheme.textSecondary; font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                }
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
            spacing: root._m

            QGCTabBar {
                id: controllerTabs
                Layout.fillWidth: true
                currentIndex: st.tab
                onCurrentIndexChanged: st.tab = currentIndex

                QGCTabButton { text: qsTr("Rate Controller") }
                QGCTabButton { text: qsTr("Attitude Controller") }
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

                    // Başlığın yığılması üçün histerezis: açmaq üçün lazım olan
                    // hədd bağlamaq həddindən xeyli aşağıdır, və başlıq yığılandan
                    // sonra da scroll qalmalıdır -- əks halda hündürlük dəyişikliyi
                    // scroll-u geri qısaldıb aç-bağla dövrəsi yaradardı.
                    onScrollYChanged: {
                        var openAt  = ScreenTools.defaultFontPixelHeight * 0.25
                        var closeAt = ScreenTools.defaultFontPixelHeight

                        if (root._headerCollapsed) {
                            if (scrollY < openAt) root._headerCollapsed = false
                        } else if (scrollY > closeAt && scrollMaxY > headerArea._fullH + closeAt) {
                            root._headerCollapsed = true
                        }
                    }

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

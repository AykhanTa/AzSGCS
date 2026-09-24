// SideMenu_Tehlukesizlik.qml
// Təhlükəsizlik konfiqurasiyası — kontent PX4 SafetyComponent-dən (real parametrlər),
// UI isə digər Aparat Qurğusu səhifələri (Enerji/Aktuatorlar) ilə eyni blok-kart dizaynında.
//
// Nizam: blok daxilində label/field alt-alta (2 sütun: label | field, field kartı doldurur).
// Bloklar iki müstəqil sütunda (masonry) — hündürlüyə görə balanslanıb.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id: root
    anchors.fill: parent
    color: "black"

    // -------- Responsive metrics --------
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property bool _stacked: (width < 900)  || ScreenTools.isShortScreen

    readonly property real _m:          Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.75 : 1.0))
    readonly property real _side:       Math.max(12, _m * 0.9)

    readonly property real _labelWidth: ScreenTools.defaultFontPixelWidth * 20
    readonly property real _fieldMin:   ScreenTools.defaultFontPixelWidth * 12
    readonly property real _fieldMax:   ScreenTools.defaultFontPixelWidth * 30
    readonly property real _iconW:      ScreenTools.defaultFontPixelHeight * 3.6
    readonly property real _iconH:      ScreenTools.defaultFontPixelHeight * 2.8

    // -------- Vehicle / parametr vəziyyəti --------
    readonly property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _parametersReady: _activeVehicle
                                             && _activeVehicle.parameterManager
                                             && _activeVehicle.parameterManager.parametersReady
    readonly property bool _hitlAvailable:   controller.parameterExists(-1, "SYS_HITL")

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    FactPanelController { id: controller }

    // -------- Parametr fact-ları --------
    property Fact _lowBattAction:       controller.getParameterFact(-1, "COM_LOW_BAT_ACT", false)
    property Fact _rcLossAction:        controller.getParameterFact(-1, "NAV_RCL_ACT", false)
    property Fact _dlLossAction:        controller.getParameterFact(-1, "NAV_DLL_ACT", false)
    property Fact _fenceAction:         controller.getParameterFact(-1, "GF_ACTION", false)
    property Fact _fenceRadius:         controller.getParameterFact(-1, "GF_MAX_HOR_DIST", false)
    property Fact _fenceAlt:            controller.getParameterFact(-1, "GF_MAX_VER_DIST", false)
    property Fact _rtlLandDelay:        controller.getParameterFact(-1, "RTL_LAND_DELAY", false)
    property Fact _disarmLandDelay:     controller.getParameterFact(-1, "COM_DISARM_LAND", false)
    property Fact _collisionPrevention: controller.getParameterFact(-1, "CP_DIST", false)
    property Fact _objectAvoidance:     controller.getParameterFact(-1, "COM_OBS_AVOID", false)
    property Fact _landSpeedMC:         controller.getParameterFact(-1, "MPC_LAND_SPEED", false)
    property Fact _enableLogging:       controller.getParameterFact(-1, "SDLOG_MODE", false)
    property Fact _hitlEnabled:         controller.getParameterFact(-1, "SYS_HITL", false)

    // -------- Təkrar komponentlər --------
    component SLabel: QGCLabel {
        color: "white"; elide: Text.ElideRight
        Layout.preferredWidth: _labelWidth
        Layout.alignment: Qt.AlignVCenter
    }

    component Section: ColumnLayout {
        id: sec
        property string title: ""
        property string iconSource: ""
        property bool   iconColored: false
        property bool   sectionVisible: root._parametersReady
        default property alias body: secGrid.data

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 6
        visible: sectionVisible

        RowLayout {
            Layout.fillWidth: true
            QGCLabel { text: sec.title; color: "white"; font.bold: true; font.pixelSize: 18 }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: secRow.implicitHeight + _m * 2
            radius: 16; color: "#3D3B3B"; border.width: 1; border.color: "#9D9D9D"
            RowLayout {
                id: secRow
                anchors.fill: parent; anchors.margins: _m; spacing: _m
                Item {
                    Layout.preferredWidth: _iconW; Layout.preferredHeight: _iconH
                    Layout.alignment: Qt.AlignTop; Layout.topMargin: _m * 0.4
                    visible: sec.iconSource !== "" && !_stacked
                    QGCColoredImage {
                        visible: sec.iconColored; anchors.centerIn: parent
                        source: sec.iconSource; color: qgcPal.text
                        height: _iconH; width: _iconH * 1.3; fillMode: Image.PreserveAspectFit
                    }
                    Image {
                        visible: !sec.iconColored; anchors.centerIn: parent
                        source: sec.iconSource; height: _iconH
                        fillMode: Image.PreserveAspectFit; mipmap: true
                    }
                }
                GridLayout {
                    id: secGrid
                    columns: 2; columnSpacing: _m; rowSpacing: Math.max(6, _m * 0.6)
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent; acceptedButtons: Qt.AllButtons; hoverEnabled: true
        onWheel: (wheel) => { wheel.accepted = true }
    }

    // ======================= Scroll kontent =======================
    QGCFlickable {
        id: pageFlick
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: _side; anchors.rightMargin: _side
        clip: true
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: outerCol.implicitHeight + _side
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: outerCol
            width: pageFlick.width
            spacing: _m

            // ---------- Başlıq ----------
            // Scroll məzmununun bir parçasıdır: aşağı sürüşdürəndə Çərçivə
            // səhifəsindəki kimi yuxarı çıxır və yer tutmur.
            ColumnLayout {
                Layout.fillWidth: true
                spacing: root._compact ? 3 : 6

                Text {
                    text: qsTr("Təhlükəsizlik Konfiqurasiyası")
                    color: "white"; font.pixelSize: root._compact ? 21 : 26; font.bold: true
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
                Text {
                    text: qsTr("Batareya, RC/data-link itkisi, geofence və enmə üçün failsafe davranışlarını konfiqurasiya edin.")
                    color: "#E8E8E8"; font.pixelSize: root._compact ? 13 : 16
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
            }

            // ---------- Yükləmə / aparat yoxdur ----------
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 220
                radius: 16; color: "#3D3B3B"; border.width: 1; border.color: "#9D9D9D"
                visible: !root._parametersReady
                Text {
                    anchors.centerIn: parent; width: parent.width - (_side * 2)
                    text: root._activeVehicle
                          ? qsTr("Parametrlər yüklənir...\nAvtopilot bağlantısını gözləyin")
                          : qsTr("Aktiv aparat yoxdur.\nQoşulduqdan sonra parametrlər görünəcək.")
                    color: "#FFFFFF"; font.pixelSize: 18; font.bold: true
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                }
            }

            // ---------- Bloklar: 2 sütun (masonry), hündürlüyə görə balanslı ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: _m
                visible: root._parametersReady

                // ===================== SOL SÜTUN =====================
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: _m

                    // ---- Aşağı Batareya Failsafe ----
                    Section {
                        title: qsTr("Aşağı Batareya Failsafe"); iconSource: "/qmlimages/LowBattery.svg"
                        SLabel { text: qsTr("Failsafe hərəkəti:") }
                        FactComboBox { sizeToContents: true; fact: root._lowBattAction; indexModel: false; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        SLabel { text: qsTr("Xəbərdarlıq səviyyəsi:") }
                        FactTextField { fact: controller.getParameterFact(-1, "BAT_LOW_THR", false); Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        SLabel { text: qsTr("Failsafe səviyyəsi:") }
                        FactTextField { fact: controller.getParameterFact(-1, "BAT_CRIT_THR", false); Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        SLabel { text: qsTr("Fövqəladə səviyyə:") }
                        FactTextField { fact: controller.getParameterFact(-1, "BAT_EMERGEN_THR", false); Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                    }

                    // ---- Evə Qayıtma (RTL) ----
                    Section {
                        title: qsTr("Evə Qayıtma (RTL) Ayarları")
                        iconSource: (controller.vehicle && controller.vehicle.fixedWing) ? "/qmlimages/ReturnToHomeAltitude.svg" : "/qmlimages/ReturnToHomeAltitudeCopter.svg"
                        iconColored: true
                        SLabel { text: qsTr("Qalxılacaq hündürlük:") }
                        FactTextField { fact: controller.getParameterFact(-1, "RTL_RETURN_ALT", false); Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        QGCLabel { text: qsTr("Evə qayıtdıqdan sonra:"); color: "white"; Layout.columnSpan: 2 }
                        QGCRadioButton {
                            id: rtlLandNow; text: qsTr("Dərhal en"); Layout.columnSpan: 2
                            checked: root._rtlLandDelay ? root._rtlLandDelay.value === 0 : false
                            onClicked: if (root._rtlLandDelay) root._rtlLandDelay.value = 0
                        }
                        QGCRadioButton {
                            id: rtlLoiterNoLand; text: qsTr("Loiter et, enmə"); Layout.columnSpan: 2
                            checked: root._rtlLandDelay ? root._rtlLandDelay.value < 0 : false
                            onClicked: if (root._rtlLandDelay) root._rtlLandDelay.value = -1
                        }
                        QGCRadioButton {
                            id: rtlLoiterLand; text: qsTr("Loiter et, müəyyən vaxtdan sonra en"); Layout.columnSpan: 2
                            checked: root._rtlLandDelay ? root._rtlLandDelay.value > 0 : false
                            onClicked: if (root._rtlLandDelay) root._rtlLandDelay.value = 60
                        }
                        SLabel { text: qsTr("Loiter vaxtı:") }
                        FactTextField { fact: root._rtlLandDelay; enabled: rtlLoiterLand.checked; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        SLabel { text: qsTr("Loiter hündürlüyü:") }
                        FactTextField { fact: controller.getParameterFact(-1, "RTL_DESCEND_ALT", false); enabled: rtlLoiterLand.checked || rtlLoiterNoLand.checked; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                    }

                    // ---- Telemetriya Loglaması ----
                    Section {
                        title: qsTr("Telemetriya Loglaması"); iconSource: "/qmlimages/no-logging.svg"
                        SLabel { text: qsTr("Aparat yaddaşına loglama:") }
                        QGCComboBox {
                            sizeToContents: true; model: [qsTr("Deaktiv"), qsTr("Aktiv")]; enabled: root._enableLogging; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax
                            currentIndex: root._enableLogging ? (root._enableLogging.value >= 0 ? 1 : 0) : 0
                            onActivated: (index) => { if (root._enableLogging) root._enableLogging.value = index > 0 ? 0 : -1 }
                        }
                    }

                    // ---- HITL (varsa) ----
                    Section {
                        title: qsTr("Hardware in the Loop (HITL)"); iconSource: "/qmlimages/HITL.svg"; iconColored: true
                        sectionVisible: root._parametersReady && root._hitlAvailable
                        SLabel { text: qsTr("HITL aktiv:") }
                        FactComboBox { sizeToContents: true; fact: root._hitlEnabled; indexModel: false; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                    }
                }

                // ===================== SAĞ SÜTUN =====================
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: _m
                    visible: !_stacked

                    // ---- Obyekt Aşkarlama ----
                    Section {
                        title: qsTr("Obyekt Aşkarlama"); iconSource: "/qmlimages/ObjectAvoidance.svg"; iconColored: true
                        SLabel { text: qsTr("Toqquşmanın qarşısı:") }
                        QGCComboBox {
                            sizeToContents: true; model: [qsTr("Deaktiv"), qsTr("Aktiv")]; enabled: root._collisionPrevention; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax
                            currentIndex: root._collisionPrevention ? (root._collisionPrevention.rawValue > 0 ? 1 : 0) : 0
                            onActivated: (index) => { if (root._collisionPrevention) root._collisionPrevention.value = index > 0 ? 5 : -1 }
                        }
                        SLabel { text: qsTr("Maneədən yayınma:") }
                        QGCComboBox {
                            sizeToContents: true; model: [qsTr("Deaktiv"), qsTr("Aktiv")]; enabled: root._objectAvoidance && root._collisionPrevention && root._collisionPrevention.rawValue > 0; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax
                            currentIndex: root._objectAvoidance ? (root._objectAvoidance.value === 0 ? 0 : 1) : 0
                            onActivated: (index) => { if (root._objectAvoidance) root._objectAvoidance.value = index > 0 ? 1 : 0 }
                        }
                        SLabel { text: qsTr("Minimum məsafə (m):") }
                        QGCSlider {
                            Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax; Layout.minimumHeight: ScreenTools.defaultFontPixelHeight * 2
                            enabled: root._collisionPrevention && root._collisionPrevention.rawValue > 0
                            from: 1; to: 15; stepSize: 1; displayValue: true; live: false
                            value: (root._collisionPrevention && root._collisionPrevention.rawValue > 0) ? root._collisionPrevention.rawValue : 1
                            onValueChanged: { if (root._collisionPrevention && root._collisionPrevention.rawValue >= 0) root._collisionPrevention.rawValue = value }
                        }
                        FactCheckBox {
                            text: qsTr("Maneə məsafəsi overlay-ini göstər")
                            fact: QGroundControl.settingsManager.flyViewSettings.showObstacleDistanceOverlay
                            Layout.columnSpan: 2
                        }
                    }

                    // ---- Geofence Failsafe ----
                    Section {
                        title: qsTr("Geofence Failsafe"); iconSource: "/qmlimages/GeoFence.svg"
                        SLabel { text: qsTr("Pozulma zamanı hərəkət:") }
                        FactComboBox { sizeToContents: true; fact: root._fenceAction; indexModel: false; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        QGCCheckBox {
                            id: fenceRadiusCheckBox; text: qsTr("Maks radius:")
                            checked: root._fenceRadius ? root._fenceRadius.value > 0 : false
                            onClicked: if (root._fenceRadius) root._fenceRadius.value = checked ? 100 : 0
                            Layout.preferredWidth: _labelWidth
                        }
                        FactTextField { fact: root._fenceRadius; enabled: fenceRadiusCheckBox.checked; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        QGCCheckBox {
                            id: fenceAltCheckBox; text: qsTr("Maks hündürlük:")
                            checked: root._fenceAlt ? root._fenceAlt.value > 0 : false
                            onClicked: if (root._fenceAlt) root._fenceAlt.value = checked ? 100 : 0
                            Layout.preferredWidth: _labelWidth
                        }
                        FactTextField { fact: root._fenceAlt; enabled: fenceAltCheckBox.checked; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                    }

                    // ---- RC İtkisi Failsafe ----
                    Section {
                        title: qsTr("RC İtkisi Failsafe"); iconSource: "/qmlimages/RCLoss.svg"
                        SLabel { text: qsTr("Failsafe hərəkəti:") }
                        FactComboBox { sizeToContents: true; fact: root._rcLossAction; indexModel: false; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        SLabel { text: qsTr("RC itkisi timeout:") }
                        FactTextField { fact: controller.getParameterFact(-1, "COM_RC_LOSS_T", false); Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                    }

                    // ---- Data Link İtkisi Failsafe ----
                    Section {
                        title: qsTr("Data Link İtkisi Failsafe"); iconSource: "/qmlimages/DatalinkLoss.svg"
                        SLabel { text: qsTr("Failsafe hərəkəti:") }
                        FactComboBox { sizeToContents: true; fact: root._dlLossAction; indexModel: false; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        SLabel { text: qsTr("Data link timeout:") }
                        FactTextField { fact: controller.getParameterFact(-1, "COM_DL_LOSS_T", false); Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                    }

                    // ---- Enmə Rejimi Ayarları ----
                    Section {
                        title: qsTr("Enmə Rejimi Ayarları")
                        iconSource: (controller.vehicle && controller.vehicle.fixedWing) ? "/qmlimages/LandMode.svg" : "/qmlimages/LandModeCopter.svg"
                        iconColored: true
                        SLabel { text: qsTr("Enmə enmə sürəti:"); visible: controller.vehicle && !controller.vehicle.fixedWing }
                        FactTextField { fact: root._landSpeedMC; visible: controller.vehicle && !controller.vehicle.fixedWing; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                        QGCCheckBox {
                            id: disarmDelayCheckBox; text: qsTr("Sonra disarm et:")
                            checked: root._disarmLandDelay ? root._disarmLandDelay.value > 0 : false
                            onClicked: if (root._disarmLandDelay) root._disarmLandDelay.value = checked ? 2 : 0
                            Layout.preferredWidth: _labelWidth
                        }
                        FactTextField { fact: root._disarmLandDelay; enabled: disarmDelayCheckBox.checked; Layout.fillWidth: true; Layout.minimumWidth: _fieldMin; Layout.maximumWidth: _fieldMax }
                    }
                }
            }
        }
    }
}

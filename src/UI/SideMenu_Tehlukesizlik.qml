// SideMenu_Tehlukesizlik.qml
// Təhlükəsizlik konfiqurasiyası — kontent PX4 SafetyComponent-dən (real parametrlər),
// UI isə digər Aparat Qurğusu səhifələri (Enerji/Aktuatorlar) ilə eyni blok-kart dizaynında.
//
// Nizam: blok daxilində label/field alt-alta (2 sütun: label | field, field kartı doldurur).
// Bloklar iki müstəqil sütunda (masonry) — hündürlüyə görə balanslanıb; dar ekranda bir
// sütunda alt-alta.
//
// New design: the vehicle setup page header, one status card per block with its icon in
// a group box, and the new fields, combo boxes, check boxes and radio buttons.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    // The fields, combo boxes, check boxes, radio buttons and labels take the new
    // design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // -------- Responsive metrics --------
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property bool _stacked: (width < 900)  || ScreenTools.isShortScreen

    readonly property real _m:          AzTheme.px(_compact ? 12 : 16)
    readonly property real _side:       AzTheme.px(_stacked ? 12 : 20)

    readonly property real _labelWidth: ScreenTools.defaultFontPixelWidth * 20
    readonly property real _fieldMin:   ScreenTools.defaultFontPixelWidth * 12
    readonly property real _fieldMax:   ScreenTools.defaultFontPixelWidth * 30
    readonly property real _iconW:      AzTheme.px(64)
    readonly property real _iconH:      AzTheme.px(40)

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
        elide: Text.ElideRight
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

        Text {
            Layout.fillWidth: true
            text: sec.title
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: AzTheme.fontPx(16)
            elide: Text.ElideRight
        }

        // The status card: linear-gradient(145deg, #25272A, #181B1E), 1 px #353A3F, radius 14
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: secRow.implicitHeight + _m * 2
            radius: AzTheme.px(AzTheme.cardRadius)
            border.width: 1
            border.color: AzTheme.cardBorder
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
            }

            RowLayout {
                id: secRow
                anchors.fill: parent; anchors.margins: _m; spacing: _m

                // The block's icon in a group box
                Rectangle {
                    Layout.preferredWidth: _iconW; Layout.preferredHeight: _iconW
                    Layout.alignment: Qt.AlignTop
                    visible: sec.iconSource !== "" && !_stacked
                    radius: AzTheme.px(AzTheme.groupRadius)
                    color: AzTheme.groupFill
                    border.width: 1
                    border.color: AzTheme.groupBorder

                    QGCColoredImage {
                        visible: sec.iconColored; anchors.centerIn: parent
                        source: sec.iconSource; color: AzTheme.textCard
                        height: _iconH; width: _iconH; sourceSize.height: _iconH
                        fillMode: Image.PreserveAspectFit
                    }
                    Image {
                        visible: !sec.iconColored; anchors.centerIn: parent
                        source: sec.iconSource; height: _iconH; width: _iconH
                        sourceSize.height: _iconH
                        fillMode: Image.PreserveAspectFit; mipmap: true
                    }
                }
                GridLayout {
                    id: secGrid
                    columns: 2; columnSpacing: _m; rowSpacing: AzTheme.px(10)
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
        contentHeight: outerCol.implicitHeight + AzTheme.px(20) + _side
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: outerCol
            y: AzTheme.px(20)
            width: pageFlick.width
            spacing: _m

            // ---------- Başlıq ----------
            // Scroll məzmununun bir parçasıdır: aşağı sürüşdürəndə Çərçivə
            // səhifəsindəki kimi yuxarı çıxır və yer tutmur.
            ColumnLayout {
                Layout.fillWidth: true
                spacing: AzTheme.px(6)

                Text {
                    text: qsTr("Təhlükəsizlik Konfiqurasiyası")
                    color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(root._compact ? 18 : 20)
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
                Text {
                    text: qsTr("Batareya, RC/data-link itkisi, geofence və enmə üçün failsafe davranışlarını konfiqurasiya edin.")
                    color: AzTheme.textSecondary; font.family: AzTheme.fontFamily; font.pixelSize: AzTheme.fontPx(13)
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
            }

            // ---------- Yükləmə / aparat yoxdur ----------
            // A status card with the vehicle state and what to expect
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: AzTheme.px(200)
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1; border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                visible: !root._parametersReady

                Column {
                    anchors.centerIn: parent
                    width: parent.width - (_side * 2)
                    spacing: AzTheme.px(10)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: AzTheme.px(12); height: width; radius: width / 2
                        color: root._activeVehicle ? AzTheme.statusOrange : AzTheme.mutedText
                    }
                    Text {
                        width: parent.width
                        text: root._activeVehicle ? qsTr("Parametrlər yüklənir...") : qsTr("Aktiv aparat yoxdur")
                        color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium
                        font.pixelSize: AzTheme.fontPx(17)
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    }
                    Text {
                        width: parent.width
                        text: root._activeVehicle ? qsTr("Avtopilot bağlantısını gözləyin")
                                                  : qsTr("Qoşulduqdan sonra parametrlər görünəcək.")
                        color: AzTheme.textSecondary; font.family: AzTheme.fontFamily
                        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    }
                }
            }

            // ---------- Bloklar: 2 sütun (masonry), hündürlüyə görə balanslı ----------
            // Dar ekranda sağ sütun solun altına keçir (əvvəl gizlənirdi və bloklarına
            // G20/G30-da çatmaq olmurdu).
            GridLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                columns: _stacked ? 1 : 2
                columnSpacing: _m
                rowSpacing: _m
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
                        QGCLabel { text: qsTr("Evə qayıtdıqdan sonra:"); color: AzTheme.textSecondary; Layout.columnSpan: 2 }
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

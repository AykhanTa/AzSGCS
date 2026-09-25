import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Controls 1.0
//import QGroundControl.ScreenTools 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "black"
    clip: true

    // -------------------- Responsive --------------------
    readonly property bool phone: ScreenTools.isMobile || width < 700

    readonly property real _m:        Math.max(12, ScreenTools.defaultFontPixelHeight * 0.75)
    readonly property real _side:     Math.max(12, _m * 0.9)
    readonly property real _itemH:    Math.max(56, ScreenTools.defaultFontPixelHeight * 2.8)

    // Row içi padding/gap
    readonly property real _rowPadH:  Math.max(12, ScreenTools.defaultFontPixelHeight * 0.90)
    readonly property real _rowPadV:  Math.max(10, ScreenTools.defaultFontPixelHeight * 0.55)
    readonly property real _rowGap:   Math.max(10, ScreenTools.defaultFontPixelHeight * 0.75)

    // Combo ölçüləri (Layout üçün!)
    readonly property real _comboH:   Math.max(36, ScreenTools.defaultFontPixelHeight * 1.9)

    // ✅ KİÇİK EKRANDA combo eni daha kiçik olsun ki, label tam görünsün
    readonly property real _comboW:   phone
                                     ? Math.max(110, Math.min(200, width * 0.42))
                                     : Math.max(130, Math.min(240, width * 0.20))

    readonly property real _labelPx:  Math.max(14, ScreenTools.defaultFontPixelHeight * 0.95)
    readonly property real _smallPx:  Math.max(12, ScreenTools.defaultFontPixelHeight * 0.85)

    // ✅ ComboBox popup ölçüləri (böyük olmasın)
    readonly property real _comboPopupMaxH:   Math.min(320, Math.max(180, height * 0.45))
    readonly property real _comboPopupItemH:  Math.max(28, Math.round(ScreenTools.defaultFontPixelHeight * 2.0))
    readonly property int  _comboPopupFontPx: Math.max(11, Math.round(_labelPx - 2))
    readonly property real _comboPopupMinH:   _comboPopupItemH * 3

    // Kartlar üçün breakpoint
    readonly property real _cardMinW: 560
    readonly property bool _twoCols:  width >= (2 * _cardMinW + _m)
    readonly property int  _columns:  _twoCols ? 2 : 1

    // -------------------- LOCAL Combo Style (yalnız bu QML) --------------------
    QtObject {
        id: comboStyle
        readonly property color text:    "white"
        readonly property color bg:      "#2B2B2B"
        readonly property color bgHi:    "#3A3A3A"
        readonly property color border:  "#585858"
        readonly property color popupBg: "#232323"
    }

    PX4SimpleFlightModesController {
        id: controller
    }

    // Switch list'ləri
    property var _switchNameList: [ "RC_MAP_ARM_SW", "RC_MAP_GEAR_SW", "RC_MAP_KILL_SW", "RC_MAP_LOITER_SW",
                                   "RC_MAP_OFFB_SW", "RC_MAP_RETURN_SW" ]
    property var _switchTHList:   [ "RC_ARMSWITCH_TH", "RC_GEAR_TH", "RC_KILLSWITCH_TH", "RC_LOITER_TH",
                                   "RC_OFFB_TH", "RC_RETURN_TH" ]

    // əvvəlki kodda istifadə olunub, amma yox idi -> səhv verirdi
    readonly property bool showNoRcHint: !controller.vehicle || !controller.rcChannelValues || controller.rcChannelValues.length === 0

    Component.onCompleted: {
        var names = _switchNameList.slice(0)
        var ths   = _switchTHList.slice(0)

        if (controller.vehicle && controller.vehicle.vtol) {
            names.push("RC_MAP_TRANS_SW")
            ths.push("RC_TRANS_TH")
        }
        if (controller.vehicle && controller.vehicle.fixedWing) {
            names.push("RC_MAP_FLAPS")
            ths.push("")
        }

        _switchNameList = names
        _switchTHList   = ths
    }

    // Click-through olmasın
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
    }

    // -------------------- Page scroll --------------------
    QGCFlickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentCol.implicitHeight + root._side
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentCol
            width: flick.width
            spacing: root._m

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            anchors.topMargin: 0
            anchors.leftMargin: root._side
            anchors.rightMargin: root._side
            anchors.bottomMargin: root._side

            // Başlıq
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("Uçuş rejimlərinin konfiqurasiyası")
                    color: "white"
                    font.pixelSize: Math.max(22, ScreenTools.defaultFontPixelHeight * 1.35)
                    font.bold: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Uçuş rejimlərini konfiqurasiya edin və RC ötürücü girişləri üçün seçimləri dəyişdirin")
                    color: "#E8E8E8"
                    font.pixelSize: 16
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            GridLayout {
                id: cardsGrid
                Layout.fillWidth: true
                columns: root._columns
                columnSpacing: root._m
                rowSpacing: root._m

                // ==================== Flight Mode Settings ====================
                Rectangle {
                    id: flightCard
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    radius: 16
                    color: "#3D3B3B"
                    border.width: 0.5
                    border.color: "#9D9D9D"
                    implicitHeight: flightContent.implicitHeight + (root._m * 2)

                    ColumnLayout {
                        id: flightContent
                        anchors.fill: parent
                        anchors.margins: root._m
                        spacing: root._m

                        Text {
                            text: qsTr("Uçuş Rejimi Parametrləri")
                            color: "white"
                            font.pixelSize: Math.max(16, ScreenTools.defaultFontPixelHeight * 1.05)
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: root._m

                            // --- Flight mode channel ---
                            Rectangle {
                                Layout.fillWidth: true
                                radius: 10
                                color: "#232323"
                                clip: true

                                // ✅ wrap ola bilsin deyə hündürlüyü implicitHeight ilə idarə edirik
                                implicitHeight: Math.max(root._itemH, channelRow.implicitHeight + (root._rowPadV * 2))

                                RowLayout {
                                    id: channelRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: root._rowPadH
                                    anchors.rightMargin: root._rowPadH
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: root._rowGap

                                    Text {
                                        text: qsTr("Uçuş rejimi kanalı")
                                        color: "#E8E8E8"
                                        font.pixelSize: root._labelPx

                                        // ✅ KİÇİK EKRANDA tam görünsün
                                        wrapMode: root.phone ? Text.WordWrap : Text.NoWrap
                                        maximumLineCount: root.phone ? 2 : 1
                                        elide: root.phone ? Text.ElideNone : Text.ElideRight

                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    FactComboBox {
                                        id: fltModeChannelCombo
                                        fact: controller.getParameterFact(-1, "RC_MAP_FLTMODE")
                                        indexModel: false

                                        Layout.preferredWidth: root._comboW
                                        Layout.minimumWidth: 110
                                        Layout.preferredHeight: root._comboH
                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                        // ✅ Popup max ölçü (çox böyük olmasın)

                                    }
                                }
                            }

                            // --- Flight modes 1..6 ---
                            Repeater {
                                model: 6

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    radius: 10
                                    color: (controller.activeFlightMode - 1) === index ? "#3A2E2E" : "#232323"
                                    clip: true

                                    // ✅ PWM yazısı silindi -> ComboBox ən sağda olur, label üçün yer artır
                                    implicitHeight: Math.max(root._itemH, modeRow.implicitHeight + (root._rowPadV * 2))

                                    RowLayout {
                                        id: modeRow
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: root._rowPadH
                                        anchors.rightMargin: root._rowPadH
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: root._rowGap

                                        Text {
                                            text: qsTr("Uçuş rejimi ") + (index + 1)
                                            color: (controller.activeFlightMode - 1) === index ? "yellow" : "#E8E8E8"
                                            font.pixelSize: root._labelPx

                                            // ✅ KİÇİK EKRANDA %1 yazıları tam görünsün
                                            wrapMode: root.phone ? Text.WordWrap : Text.NoWrap
                                            maximumLineCount: root.phone ? 2 : 1
                                            elide: root.phone ? Text.ElideNone : Text.ElideRight

                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        FactComboBox {
                                            id: modeCombo
                                            fact: controller.getParameterFact(-1, "COM_FLTMODE" + (index + 1))
                                            indexModel: false

                                            Layout.preferredWidth: root._comboW
                                            Layout.minimumWidth: 110
                                            Layout.preferredHeight: root._comboH
                                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                            // ✅ Popup max ölçü (çox böyük olmasın)

                                        }

                                        // ✅ PWM text SİLİNDİ (istəyə əsasən)
                                    }
                                }
                            }
                        }
                    }
                }

                // ==================== Switch Options ====================
                Rectangle {
                    id: switchCard
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    radius: 16
                    color: "#3D3B3B"
                    border.width: 0.5
                    border.color: "#9D9D9D"
                    implicitHeight: switchContent.implicitHeight + (root._m * 2)

                    ColumnLayout {
                        id: switchContent
                        anchors.fill: parent
                        anchors.margins: root._m
                        spacing: root._m

                        Text {
                            text: qsTr("Seçimləri dəyişdirin")
                            color: "white"
                            font.pixelSize: Math.max(16, ScreenTools.defaultFontPixelHeight * 1.05)
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Repeater {
                                model: _switchNameList

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    radius: 10
                                    color: swActive ? "#3A2E2E" : "#232323"
                                    clip: true

                                    implicitHeight: Math.max(root._itemH, swRow.implicitHeight + (root._rowPadV * 2))

                                    property string thFactName:     _switchTHList[index]
                                    property bool   thFactExists:   thFactName !== ""
                                    property Fact   swFact:         controller.getParameterFact(-1, modelData)
                                    property Fact   thFact:         thFactExists ? controller.getParameterFact(-1, thFactName) : null
                                    property real   thValue:        thFactExists && thFact ? thFact.rawValue : 0.5
                                    property real   thPWM:          1000 + (1000 * thValue)
                                    property int    swChannel:      swFact ? swFact.rawValue - 1 : -1
                                    property bool   swActive:       {
                                        if (swChannel < 0 || !controller.rcChannelValues || controller.rcChannelValues.length <= swChannel)
                                            return false
                                        var channelValue = controller.rcChannelValues[swChannel]
                                        if (channelValue === undefined)
                                            return false
                                        return (thValue >= 0) ? (channelValue > thPWM) : (channelValue <= thPWM)
                                    }

                                    RowLayout {
                                        id: swRow
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: root._rowPadH
                                        anchors.rightMargin: root._rowPadH
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: root._rowGap

                                        Text {
                                            text: getSwitchName(modelData)
                                            color: swActive ? "yellow" : "#E8E8E8"
                                            font.pixelSize: root._labelPx

                                            wrapMode: root.phone ? Text.WordWrap : Text.NoWrap
                                            maximumLineCount: root.phone ? 2 : 1
                                            elide: root.phone ? Text.ElideNone : Text.ElideRight

                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        FactComboBox {
                                            id: swCombo
                                            fact: swFact
                                            indexModel: false

                                            Layout.preferredWidth: root._comboW
                                            Layout.minimumWidth: 110
                                            Layout.preferredHeight: root._comboH
                                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                            // ✅ Popup max ölçü (çox böyük olmasın)

                                        }
                                    }
                                }
                            }

                            // RC Channel Monitor
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.max(240, Math.min(360, root.height * 0.35))
                                radius: 10
                                color: "#232323"
                                clip: true

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    spacing: 10

                                    Text {
                                        text: qsTr("RC Kanal Monitoru")
                                        color: "white"
                                        font.pixelSize: root._labelPx
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }

                                    // Monitor bütün kanallar üçün öz hündürlüyünü alır; kart sabit hündürlükdədir,
                                    // ona görə sığmayan kanallar kəsilməsin deyə burada scroll olunur. Hamısı
                                    // sığanda interactive söndürülür ki, sürüşdürmə səhifənin özünə getsin.
                                    QGCFlickable {
                                        Layout.fillWidth:   true
                                        Layout.fillHeight:  true
                                        contentWidth:       width
                                        contentHeight:      rcMonitor.height
                                        flickableDirection: Flickable.VerticalFlick
                                        interactive:        contentHeight > height

                                        RCChannelMonitor {
                                            id:         rcMonitor
                                            width:      parent.width
                                            twoColumn:  width >= 600
                                        }
                                    }
                                }

                                // RC yoxdursa göstərilən ipucu — ColumnLayout-un deyil,
                                // kart Rectangle-ın uşağıdır (layout item-də anchors olmasın deyə).
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    color: "transparent"
                                    visible: root.showNoRcHint

                                    Column {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.86
                                        spacing: 6

                                        QGCLabel {
                                            width: parent.width
                                            text: qsTr("RC siqnalı aşkar edilmədi")
                                            color: "#E8E8E8"
                                            font.pixelSize: root._labelPx
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.WordWrap
                                        }

                                        QGCLabel {
                                            width: parent.width
                                            text: qsTr("Radio qoşulduqdan sonra kanallar burada görünəcək.")
                                            color: "#9D9D9D"
                                            font.pixelSize: root._smallPx
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function getSwitchName(paramName) {
        var switchNames = {
            "RC_MAP_ARM_SW": "Arm Switch",
            "RC_MAP_GEAR_SW": "Gear Switch",
            "RC_MAP_KILL_SW": "Emergency Kill Switch",
            "RC_MAP_LOITER_SW": "Loiter Switch",
            "RC_MAP_OFFB_SW": "Offboard Switch",
            "RC_MAP_RETURN_SW": "Return Switch",
            "RC_MAP_TRANS_SW": "VTOL Transition Switch",
            "RC_MAP_FLAPS": "Flaps Switch"
        }
        return switchNames[paramName] || paramName
    }
}

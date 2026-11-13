// AppSettings_RemoteIdSettings.qml
// Uzaqdan İD (Remote ID) tənzimləmələri.
// Kontent: src/UI/AppSettings/RemoteIDSettings.qml (upstream, real Fact-lar)
// Dizayn : yeni dizaynın kartları və qrup qutuları, Fly_ViewSettings.qml ilə eyni (responsiv 1–2 sütun masonry)

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    // The fields, combo boxes, switches and labels take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ===================== Fact / vəziyyət =====================
    property var  _settingsManager:  QGroundControl.settingsManager
    property var  remoteIDSettings:  _settingsManager.remoteIDSettings

    property var  _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property var  _offlineVehicle:   QGroundControl.multiVehicleManager.offlineEditingVehicle
    property var  _remoteIDManager:  _activeVehicle ? _activeVehicle.remoteIDManager : null
    property var  _activeRID:        (_activeVehicle && _activeVehicle.remoteIDManager) ? _activeVehicle.remoteIDManager : null
    property bool commsGood:         (_activeVehicle && _activeVehicle.remoteIDManager) ? _activeVehicle.remoteIDManager.commsGood : false

    property Fact regionFact:         remoteIDSettings.region
    property Fact sendOperatorIdFact: remoteIDSettings.sendOperatorID
    property Fact locationTypeFact:   remoteIDSettings.locationType
    property Fact operatorIDFact:     remoteIDSettings.operatorID

    property int  _regionOperation:  remoteIDSettings.region.value
    property int  _locationType:     remoteIDSettings.locationType.value
    property bool isEURegion:        regionFact.rawValue === RemoteIDSettings.RegionOperation.EU
    property bool isFAARegion:       regionFact.rawValue === RemoteIDSettings.RegionOperation.FAA
    property bool _locationFixed:    locationTypeFact.rawValue === RemoteIDSettings.LocationType.FIXED

    property string gpsDisabled: "Disabled"
    property string gpsUdpPort:  "UDP Port"

    // Region dəyişəndə upstream məntiqi
    Connections {
        target: regionFact
        function onRawValueChanged(value) {
            if (value === RemoteIDSettings.RegionOperation.EU) {
                sendOperatorIdFact.rawValue = true
            } else if (value === RemoteIDSettings.RegionOperation.FAA) {
                locationTypeFact.value = RemoteIDSettings.LocationType.LIVE
            }
        }
    }

    // ===================== Responsive metrics (Fly_ViewSettings ilə eyni) =====================
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100

    readonly property real sidePadding: AzTheme.px(phone ? 12 : 20)
    readonly property real gap:         AzTheme.px(phone ? 10 : 16)

    readonly property real fontScale: {
        var w = Math.max(1, width)
        var s = w / 1200.0
        s = Math.min(1.0, s)
        return Math.max(0.90, Math.min(1.0, s))
    }

    readonly property real titleFontPx: AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descFontPx:  AzTheme.fontPx(13)
    readonly property real labelFontPx: AzTheme.fontPx(AzTheme.popupTextSize)

    readonly property real rowPadX: AzTheme.px(AzTheme.groupPadding)
    readonly property real rowPadY: AzTheme.px(8)
    readonly property real rowMinH: AzTheme.px(AzTheme.groupRowHeight + 4)

    readonly property real contentW: Math.max(0, flick.width - 2 * sidePadding)
    readonly property real minColW:  (tablet ? 520 : 700)
    readonly property real maxColW:  820
    readonly property int  columns:  (phone || contentW < (2 * minColW + gap)) ? 1 : 2
    readonly property real colW:     (columns === 1) ? contentW
                                                     : Math.min(maxColW, Math.floor((contentW - gap) / 2))
    readonly property real ctrlW:    Math.max(150, Math.min(280, colW * (phone ? 0.60 : 0.44)))

    // ===================== Panel stili =====================
    QtObject {
        id: panelStyle
        // The status card: linear-gradient(145deg, #25272A, #181B1E), 1 px #353A3F, radius 14
        readonly property Gradient cardGradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }
        // A group box row: #191D20, 1 px #353A3F, radius 8
        readonly property color rowBg:     AzTheme.groupFill
        readonly property color rowBorder: AzTheme.groupBorder
        readonly property color border:    AzTheme.cardBorder
        readonly property real  radius:    AzTheme.px(AzTheme.cardRadius)
        readonly property real  rowRadius: AzTheme.px(AzTheme.groupRadius)
        readonly property real  pad:       AzTheme.px(16)
        readonly property real  titlePx:   AzTheme.fontPx(16)
    }

    // A status flag: a group box with a coloured outline, dot and text; grey without a vehicle.
    component StatusFlag: Rectangle {
        id: flag

        property string text
        property bool   good:  false
        property bool   known: false

        readonly property color _tone: known ? (good ? AzTheme.statusGreen : AzTheme.statusRed) : AzTheme.mutedText

        width:        AzTheme.px(132)
        height:       AzTheme.px(40)
        radius:       AzTheme.px(AzTheme.groupRadius)
        color:        AzTheme.groupFill
        border.width: 1
        border.color: flag._tone

        Row {
            anchors.centerIn: parent
            spacing: AzTheme.px(8)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: AzTheme.px(8); height: width; radius: width / 2
                color: flag._tone
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: flag.text
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(12)
            }
        }
    }

    // ===================== Başlıq =====================
    Column {
        id: headerArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: sidePadding
        anchors.rightMargin: sidePadding
        anchors.topMargin: AzTheme.px(20)
        spacing: AzTheme.px(6)

        Text {
            text: qsTr("Remote ID Tənzimləmələri")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titleFontPx
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Text {
            text: qsTr("Remote ID yayımını konfiqurasiya edin: region, Basic ID, Operator ID, Self ID və yer stansiyasının mövqeyi.")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descFontPx
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    // ===================== Scroll kontent =====================
    QGCFlickable {
        id: flick
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: AzTheme.px(16)

        clip: true
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + sidePadding

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: contentColumn
            width: parent.width
            spacing: gap

            // ---------- STATUS bayraqları (tam en) ----------
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: sidePadding
                anchors.rightMargin: sidePadding
                height: visible ? statusPanel.height : 0
                visible: root._activeVehicle

                Rectangle {
                    id: statusPanel
                    width: parent.width
                    gradient: panelStyle.cardGradient
                    radius: panelStyle.radius
                    border.width: 1
                    border.color: panelStyle.border
                    height: statusCol.implicitHeight + panelStyle.pad * 2

                    ColumnLayout {
                        id: statusCol
                        anchors.fill: parent
                        anchors.margins: panelStyle.pad
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                        Text {
                            text: qsTr("Vəziyyət")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: panelStyle.titlePx
                            Layout.fillWidth: true
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: root.gap

                            StatusFlag {
                                visible: root.commsGood
                                text: qsTr("ARM STATUS")
                                known: !!root._activeRID
                                good: known && root._remoteIDManager.armStatusGood
                            }
                            StatusFlag {
                                text: (root._activeRID && root._remoteIDManager.commsGood) ? qsTr("RID COMMS") : qsTr("QOŞULMAYIB")
                                known: !!root._activeRID
                                good: known && root._remoteIDManager.commsGood
                            }
                            StatusFlag {
                                visible: root.commsGood
                                text: qsTr("GCS GPS")
                                known: !!root._activeRID
                                good: known && root._remoteIDManager.gcsGPSGood
                            }
                            StatusFlag {
                                visible: root.commsGood
                                text: qsTr("BASIC ID")
                                known: !!root._activeRID
                                good: known && root._remoteIDManager.basicIDGood
                            }
                            StatusFlag {
                                visible: (root.commsGood && root._activeRID)
                                         ? (root.remoteIDSettings.sendOperatorID.value || root._regionOperation === RemoteIDSettings.RegionOperation.EU)
                                         : false
                                text: qsTr("OPERATOR ID")
                                known: !!root._activeRID
                                good: known && root._remoteIDManager.operatorIDGood
                            }
                        }
                    }
                }
            }

            // ---------- Panel host: 1 və ya 2 sütun ----------
            Item {
                id: panelHost
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: sidePadding
                anchors.rightMargin: sidePadding

                // Hər sütun öz-özünə sıx yığılır (masonry) — bloklar öz təbii
                // hündürlüyündə qalır, altlarında boş sahə yaranmır.
                height: (root.columns === 1)
                        ? (colLeft.height + root.gap + colRight.height)
                        : Math.max(colLeft.height, colRight.height)

                Column {
                    id: colLeft
                    x: 0
                    y: 0
                    width: root.colW
                    spacing: root.gap

                    Loader {
                        width: parent.width
                        height: item ? item.desiredH : 0
                        sourceComponent: regionPanelComponent
                    }
                    Loader {
                        width: parent.width
                        height: item ? item.desiredH : 0
                        sourceComponent: selfIDPanelComponent
                    }
                    Loader {
                        width: parent.width
                        height: item ? item.desiredH : 0
                        sourceComponent: operatorIDPanelComponent
                    }
                }

                Column {
                    id: colRight
                    x: (root.columns === 2) ? (root.colW + root.gap) : 0
                    y: (root.columns === 2) ? 0 : (colLeft.height + root.gap)
                    width: root.colW
                    spacing: root.gap

                    Loader {
                        width: parent.width
                        height: item ? item.desiredH : 0
                        sourceComponent: basicIDPanelComponent
                    }
                    Loader {
                        width: parent.width
                        height: item ? item.desiredH : 0
                        sourceComponent: gcsLocationPanelComponent
                    }
                    Loader {
                        width: parent.width
                        height: visible ? (item ? item.desiredH : 0) : 0
                        visible: root.isEURegion
                        sourceComponent: euPanelComponent
                    }
                }
            }

            Item { width: 1; height: sidePadding }
        }
    }

    // ===================== PANEL: Region =====================
    Component {
        id: regionPanelComponent

        Rectangle {
            width: parent ? parent.width : root.colW
            gradient: panelStyle.cardGradient
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border

            readonly property real desiredH: lay.implicitHeight + panelStyle.pad * 2
            height: desiredH

            ColumnLayout {
                id: lay
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                Text {
                    text: qsTr("Region")
                    color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: panelStyle.titlePx
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    border.width: 1
                    border.color: panelStyle.rowBorder
                    visible: root.regionFact.visible
                    implicitHeight: Math.max(root.rowMinH, r1.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: r1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.regionFact.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.regionFact; indexModel: false; Layout.preferredWidth: root.ctrlW }
                    }
                }

                // Arm Status xətası
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    border.width: 1
                    border.color: root._activeRID ? (root._remoteIDManager.armStatusGood ? panelStyle.rowBorder : AzTheme.statusRed) : panelStyle.rowBorder
                    visible: armText.text !== ""
                    implicitHeight: Math.max(root.rowMinH, r2.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: r2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Arm Status xətası"); font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        QGCLabel {
                            id: armText
                            text: root._remoteIDManager ? root._remoteIDManager.armStatusError : qsTr("Aparat qoşulmayıb")
                            color: AzTheme.textCard; font.pixelSize: root.labelFontPx
                            wrapMode: Text.WordWrap
                            Layout.preferredWidth: root.ctrlW
                        }
                    }
                }
            }
        }
    }

    // ===================== PANEL: Basic ID =====================
    Component {
        id: basicIDPanelComponent

        Rectangle {
            width: root.colW
            gradient: panelStyle.cardGradient
            radius: panelStyle.radius
            border.width: 1
            border.color: root._activeRID ? (root._remoteIDManager.basicIDGood ? panelStyle.border : AzTheme.statusRed) : panelStyle.border
            height: lay.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: lay
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                Text {
                    text: qsTr("Basic ID")
                    color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: panelStyle.titlePx
                    Layout.fillWidth: true
                }
                Text {
                    text: qsTr("Basic ID artıq RID cihazında təyin olunubsa, bu Basic ID 2 kimi qeyd olunacaq.")
                    color: AzTheme.textSecondary; font.family: AzTheme.fontFamily; font.pixelSize: root.labelFontPx
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.sendBasicID.visible
                    implicitHeight: Math.max(root.rowMinH, rb.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: rb
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Yayımla"); font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactCheckBoxSlider { fact: root.remoteIDSettings.sendBasicID }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.basicIDType.visible
                    implicitHeight: Math.max(root.rowMinH, rt.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: rt
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.basicIDType.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.basicIDType; indexModel: false
                                       enabled: root.remoteIDSettings.sendBasicID.rawValue
                                       Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.basicIDUaType.visible
                    implicitHeight: Math.max(root.rowMinH, ru.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ru
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.basicIDUaType.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.basicIDUaType; indexModel: false
                                       enabled: root.remoteIDSettings.sendBasicID.rawValue
                                       Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.basicID.visible
                    implicitHeight: Math.max(root.rowMinH, ri.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ri
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.basicID.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.basicID; maximumLength: 20
                                        enabled: root.remoteIDSettings.sendBasicID.rawValue
                                        Layout.preferredWidth: root.ctrlW }
                    }
                }
            }
        }
    }

    // ===================== PANEL: Operator ID =====================
    Component {
        id: operatorIDPanelComponent

        Rectangle {
            width: parent ? parent.width : root.colW
            gradient: panelStyle.cardGradient
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border

            readonly property real desiredH: lay.implicitHeight + panelStyle.pad * 2
            height: desiredH

            ColumnLayout {
                id: lay
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                Text {
                    text: qsTr("Operator ID")
                    color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: panelStyle.titlePx
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.sendOperatorIdFact.visible
                    implicitHeight: Math.max(root.rowMinH, ob.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ob
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Yayımla%1").arg(root.isEURegion ? qsTr(" (EU tələb edir)") : "")
                                   font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactCheckBoxSlider { fact: root.sendOperatorIdFact; enabled: root.isFAARegion }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.operatorIDType.visible
                    implicitHeight: Math.max(root.rowMinH, ot.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ot
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.operatorIDType.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.operatorIDType; indexModel: false
                                       Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.operatorIDFact.visible
                    implicitHeight: Math.max(root.rowMinH, ov.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ov
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.operatorIDFact.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        QGCTextField {
                            id: operatorIDTextField
                            Layout.preferredWidth: root.ctrlW
                            text: root.operatorIDFact.valueString
                            maximumLength: 20

                            property bool operatorIDInvalid: ((root._regionOperation === RemoteIDSettings.RegionOperation.EU || root.remoteIDSettings.sendOperatorID.value)
                                                              && root._activeRID && !root._remoteIDManager.operatorIDGood)

                            onOperatorIDInvalidChanged: {
                                if (operatorIDInvalid) {
                                    operatorIDTextField.showValidationError(qsTr("Yanlış Operator ID"), root.operatorIDFact.valueString, false)
                                } else {
                                    operatorIDTextField.clearValidationError(false)
                                }
                            }
                            onTextChanged: {
                                root.operatorIDFact.value = text
                                if (root._activeVehicle) {
                                    root._remoteIDManager.checkOperatorID(text)
                                } else if (root._offlineVehicle) {
                                    root._offlineVehicle.remoteIDManager.checkOperatorID(text)
                                }
                            }
                            onEditingFinished: {
                                if (root._activeVehicle) {
                                    root._remoteIDManager.setOperatorID()
                                } else if (root._offlineVehicle) {
                                    root._offlineVehicle.remoteIDManager.setOperatorID()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ===================== PANEL: Self ID =====================
    Component {
        id: selfIDPanelComponent

        Rectangle {
            width: parent ? parent.width : root.colW
            gradient: panelStyle.cardGradient
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border

            readonly property real desiredH: lay.implicitHeight + panelStyle.pad * 2
            height: desiredH

            ColumnLayout {
                id: lay
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                Text {
                    text: qsTr("Self ID")
                    color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: panelStyle.titlePx
                    Layout.fillWidth: true
                }
                Text {
                    text: qsTr("Fövqəladə hal elan olunarsa, «Yayımla» sönülü olsa belə fövqəladə mətn yayımlanacaq.")
                    color: AzTheme.textSecondary; font.family: AzTheme.fontFamily; font.pixelSize: root.labelFontPx
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.sendSelfID.visible
                    implicitHeight: Math.max(root.rowMinH, sb.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: sb
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Yayımla"); font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactCheckBoxSlider { fact: root.remoteIDSettings.sendSelfID }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.selfIDType.visible
                    implicitHeight: Math.max(root.rowMinH, st.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: st
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Yayım mesajı"); font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.selfIDType; indexModel: false
                                       enabled: root.remoteIDSettings.sendSelfID.rawValue
                                       Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.selfIDFree.visible
                    implicitHeight: Math.max(root.rowMinH, sf.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: sf
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.selfIDFree.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.selfIDFree; maximumLength: 23
                                        enabled: root.remoteIDSettings.sendSelfID.rawValue
                                        Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.selfIDExtended.visible
                    implicitHeight: Math.max(root.rowMinH, se.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: se
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.selfIDExtended.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.selfIDExtended; maximumLength: 23
                                        enabled: root.remoteIDSettings.sendSelfID.rawValue
                                        Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.selfIDEmergency.visible
                    implicitHeight: Math.max(root.rowMinH, sm.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: sm
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.selfIDEmergency.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.selfIDEmergency; maximumLength: 23
                                        Layout.preferredWidth: root.ctrlW }
                    }
                }
            }
        }
    }

    // ===================== PANEL: Yer Stansiyasının Mövqeyi =====================
    Component {
        id: gcsLocationPanelComponent

        Rectangle {
            width: root.colW
            gradient: panelStyle.cardGradient
            radius: panelStyle.radius
            border.width: 1
            border.color: root._activeRID ? (root._remoteIDManager.gcsGPSGood ? panelStyle.border : AzTheme.statusRed) : panelStyle.border
            height: lay.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: lay
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                Text {
                    text: qsTr("Yer Stansiyasının Mövqeyi")
                    color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: panelStyle.titlePx
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    implicitHeight: Math.max(root.rowMinH, lt.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: lt
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.locationTypeFact.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.locationTypeFact; indexModel: false; Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    implicitHeight: Math.max(root.rowMinH, gl1.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: gl1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.latitudeFixed.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.latitudeFixed; maximumLength: 20
                                        enabled: root._locationFixed; Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    implicitHeight: Math.max(root.rowMinH, gl2.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: gl2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.longitudeFixed.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.longitudeFixed; maximumLength: 20
                                        enabled: root._locationFixed; Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    implicitHeight: Math.max(root.rowMinH, gl3.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: gl3
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.altitudeFixed.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.altitudeFixed; maximumLength: 20
                                        enabled: root._locationFixed; Layout.preferredWidth: root.ctrlW }
                    }
                }

                // ---- NMEA xarici GPS ----
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: !ScreenTools.isMobile
                             && QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.visible
                             && root._locationType !== RemoteIDSettings.LocationType.TAKEOFF
                    implicitHeight: Math.max(root.rowMinH, nm1.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: nm1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("NMEA xarici GPS cihazı"); font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        QGCComboBox {
                            id: nmeaPortCombo
                            Layout.preferredWidth: root.ctrlW
                            model: ListModel { }
                            onActivated: (index) => {
                                if (index !== -1) {
                                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.value = textAt(index)
                                }
                            }
                            Component.onCompleted: {
                                model.append({ text: root.gpsDisabled })
                                model.append({ text: root.gpsUdpPort })
                                for (var i in QGroundControl.linkManager.serialPorts) {
                                    nmeaPortCombo.model.append({ text: QGroundControl.linkManager.serialPorts[i] })
                                }
                                if (QGroundControl.linkManager.serialPorts.length === 0) {
                                    nmeaPortCombo.model.append({ text: qsTr("Serial <yoxdur>") })
                                }
                                nmeaPortCombo.currentIndex = nmeaPortCombo.find(
                                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.valueString)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: !ScreenTools.isMobile
                             && QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.visible
                             && root._locationType !== RemoteIDSettings.LocationType.TAKEOFF
                             && nmeaPortCombo.currentText !== root.gpsUdpPort
                             && nmeaPortCombo.currentText !== root.gpsDisabled
                    implicitHeight: Math.max(root.rowMinH, nm2.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: nm2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("NMEA GPS Baudrate"); font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        QGCComboBox {
                            id: nmeaBaudCombo
                            Layout.preferredWidth: root.ctrlW
                            model: [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600]
                            onActivated: (index) => {
                                if (index !== -1) {
                                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = textAt(index)
                                }
                            }
                            Component.onCompleted: {
                                nmeaBaudCombo.currentIndex = nmeaBaudCombo.find(
                                    QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.valueString)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: nmeaPortCombo.currentText === root.gpsUdpPort
                             && root._locationType !== RemoteIDSettings.LocationType.TAKEOFF
                    implicitHeight: Math.max(root.rowMinH, nm3.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: nm3
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("NMEA axını UDP portu"); font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort
                                        Layout.preferredWidth: root.ctrlW }
                    }
                }
            }
        }
    }

    // ===================== PANEL: EU Aparat Məlumatı =====================
    Component {
        id: euPanelComponent

        Rectangle {
            width: parent ? parent.width : root.colW
            gradient: panelStyle.cardGradient
            radius: panelStyle.radius
            border.width: 1
            border.color: panelStyle.border

            readonly property real desiredH: lay.implicitHeight + panelStyle.pad * 2
            height: desiredH

            ColumnLayout {
                id: lay
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                Text {
                    text: qsTr("EU Aparat Məlumatı")
                    color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium; font.pixelSize: panelStyle.titlePx
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.classificationType.visible
                    implicitHeight: Math.max(root.rowMinH, eu1.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: eu1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Məlumat təqdim et"); font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        QGCCheckBoxSlider {
                            id: euProvideInfoSlider
                            checked: root.remoteIDSettings.classificationType.rawValue === RemoteIDSettings.ClassificationType.EU
                            onClicked: root.remoteIDSettings.classificationType.rawValue = !root.remoteIDSettings.classificationType.rawValue
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.categoryEU.visible
                    implicitHeight: Math.max(root.rowMinH, eu2.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: eu2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.categoryEU.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.categoryEU; indexModel: false
                                       enabled: euProvideInfoSlider.checked; Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    border.width: 1; border.color: panelStyle.rowBorder
                    visible: root.remoteIDSettings.classEU.visible
                    implicitHeight: Math.max(root.rowMinH, eu3.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: eu3
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.classEU.shortDescription; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.classEU; indexModel: false
                                       enabled: euProvideInfoSlider.checked; Layout.preferredWidth: root.ctrlW }
                    }
                }
            }
        }
    }
}

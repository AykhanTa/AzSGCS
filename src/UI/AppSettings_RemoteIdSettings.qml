// AppSettings_RemoteIdSettings.qml
// Uzaqdan İD (Remote ID) tənzimləmələri.
// Kontent: src/UI/AppSettings/RemoteIDSettings.qml (upstream, real Fact-lar)
// Dizayn : Fly_ViewSettings.qml ilə eyni blok/panel sistemi (responsiv 1–2 sütun masonry)

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
    color: "#000000"

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

    QGCPalette { id: qgcPal }

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

    readonly property real sidePadding: Math.max(10, ScreenTools.defaultFontPixelWidth * (phone ? 0.9 : tablet ? 1.2 : 1.6))
    readonly property real gap:         Math.max(10, ScreenTools.defaultFontPixelWidth * (phone ? 0.9 : tablet ? 1.2 : 1.6))

    readonly property real fontScale: {
        var w = Math.max(1, width)
        var s = w / 1200.0
        s = Math.min(1.0, s)
        return Math.max(0.90, Math.min(1.0, s))
    }

    readonly property real labelFontPx: Math.max(11, ScreenTools.defaultFontPixelHeight * (phone ? 0.90 : 0.88) * fontScale)

    readonly property real rowPadX: Math.max(12, ScreenTools.defaultFontPixelWidth * 1.2)
    readonly property real rowPadY: Math.max(8,  ScreenTools.defaultFontPixelHeight * 0.6)
    readonly property real rowMinH: Math.max(48, ScreenTools.defaultFontPixelHeight * 2.6)

    readonly property real contentW: Math.max(0, flick.width - 2 * sidePadding)
    readonly property real minColW:  (tablet ? 520 : 700)
    readonly property real maxColW:  820
    readonly property int  columns:  (phone || contentW < (2 * minColW + gap)) ? 1 : 2
    readonly property real colW:     (columns === 1) ? contentW
                                                     : Math.min(maxColW, Math.floor((contentW - gap) / 2))
    readonly property real ctrlW:    Math.max(150, Math.min(280, colW * (phone ? 0.60 : 0.44)))

    readonly property real flagW: Math.max(120, ScreenTools.defaultFontPixelWidth * 14)
    readonly property real flagH: Math.max(44,  ScreenTools.defaultFontPixelHeight * 2.4)

    // ===================== Panel stili =====================
    QtObject {
        id: panelStyle
        readonly property color panelBg:   "#3D3B3B"
        readonly property color rowBg:     "#2A2A2A"
        readonly property color border:    "#9D9D9D"
        readonly property real  radius:    16
        readonly property real  rowRadius: 10
        readonly property real  pad:       Math.max(14, ScreenTools.defaultFontPixelWidth * 1.2)
        readonly property real  titlePx: {
            var v = Math.max(15, ScreenTools.defaultFontPixelHeight * 1.02 * (root.fontScale || 1))
            return isFinite(v) ? v : 15
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
        anchors.topMargin: 0
        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.6)

        Text {
            text: qsTr("Remote ID Tənzimləmələri")
            color: "white"
            font.pixelSize: 26
            font.bold: true
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Text {
            text: qsTr("Remote ID yayımını konfiqurasiya edin: region, Basic ID, Operator ID, Self ID və yer stansiyasının mövqeyi.")
            color: "#E8E8E8"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#FFFFFF"
            opacity: 0.25
        }
    }

    // ===================== Scroll kontent =====================
    QGCFlickable {
        id: flick
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.5)

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
                    color: panelStyle.panelBg
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
                            color: "white"
                            font.pixelSize: panelStyle.titlePx
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: root.gap

                            Rectangle {
                                width: root.flagW; height: root.flagH; radius: 8
                                visible: root.commsGood
                                color: root._activeRID ? (root._remoteIDManager.armStatusGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                                QGCLabel { anchors.fill: parent; text: qsTr("ARM STATUS"); wrapMode: Text.WordWrap; font.bold: true
                                           horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                            Rectangle {
                                width: root.flagW; height: root.flagH; radius: 8
                                color: root._activeRID ? (root._remoteIDManager.commsGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                                QGCLabel { anchors.fill: parent; font.bold: true; wrapMode: Text.WordWrap
                                           text: (root._activeRID && root._remoteIDManager.commsGood) ? qsTr("RID COMMS") : qsTr("QOŞULMAYIB")
                                           horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                            Rectangle {
                                width: root.flagW; height: root.flagH; radius: 8
                                visible: root.commsGood
                                color: root._activeRID ? (root._remoteIDManager.gcsGPSGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                                QGCLabel { anchors.fill: parent; text: qsTr("GCS GPS"); wrapMode: Text.WordWrap; font.bold: true
                                           horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                            Rectangle {
                                width: root.flagW; height: root.flagH; radius: 8
                                visible: root.commsGood
                                color: root._activeRID ? (root._remoteIDManager.basicIDGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                                QGCLabel { anchors.fill: parent; text: qsTr("BASIC ID"); wrapMode: Text.WordWrap; font.bold: true
                                           horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                            Rectangle {
                                width: root.flagW; height: root.flagH; radius: 8
                                visible: (root.commsGood && root._activeRID)
                                         ? (root.remoteIDSettings.sendOperatorID.value || root._regionOperation === RemoteIDSettings.RegionOperation.EU)
                                         : false
                                color: root._activeRID ? (root._remoteIDManager.operatorIDGood ? qgcPal.colorGreen : qgcPal.colorRed) : qgcPal.colorGrey
                                QGCLabel { anchors.fill: parent; text: qsTr("OPERATOR ID"); wrapMode: Text.WordWrap; font.bold: true
                                           horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
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
            color: panelStyle.panelBg
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
                    color: "white"; font.pixelSize: panelStyle.titlePx; font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius
                    color: panelStyle.rowBg
                    visible: root.regionFact.visible
                    implicitHeight: Math.max(root.rowMinH, r1.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: r1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.regionFact.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
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
                    border.color: root._activeRID ? (root._remoteIDManager.armStatusGood ? panelStyle.rowBg : qgcPal.colorRed) : panelStyle.rowBg
                    visible: armText.text !== ""
                    implicitHeight: Math.max(root.rowMinH, r2.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: r2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Arm Status xətası"); color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        QGCLabel {
                            id: armText
                            text: root._remoteIDManager ? root._remoteIDManager.armStatusError : qsTr("Aparat qoşulmayıb")
                            color: "#E8E8E8"; font.pixelSize: root.labelFontPx
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
            color: panelStyle.panelBg
            radius: panelStyle.radius
            border.width: 1
            border.color: root._activeRID ? (root._remoteIDManager.basicIDGood ? panelStyle.border : qgcPal.colorRed) : panelStyle.border
            height: lay.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: lay
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                Text {
                    text: qsTr("Basic ID")
                    color: "white"; font.pixelSize: panelStyle.titlePx; font.bold: true
                    Layout.fillWidth: true
                }
                Text {
                    text: qsTr("Basic ID artıq RID cihazında təyin olunubsa, bu Basic ID 2 kimi qeyd olunacaq.")
                    color: "#B8B8B8"; font.pixelSize: root.labelFontPx
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.sendBasicID.visible
                    implicitHeight: Math.max(root.rowMinH, rb.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: rb
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Yayımla"); color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactCheckBoxSlider { fact: root.remoteIDSettings.sendBasicID }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.basicIDType.visible
                    implicitHeight: Math.max(root.rowMinH, rt.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: rt
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.basicIDType.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.basicIDType; indexModel: false
                                       enabled: root.remoteIDSettings.sendBasicID.rawValue
                                       Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.basicIDUaType.visible
                    implicitHeight: Math.max(root.rowMinH, ru.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ru
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.basicIDUaType.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.basicIDUaType; indexModel: false
                                       enabled: root.remoteIDSettings.sendBasicID.rawValue
                                       Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.basicID.visible
                    implicitHeight: Math.max(root.rowMinH, ri.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ri
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.basicID.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
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
            color: panelStyle.panelBg
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
                    color: "white"; font.pixelSize: panelStyle.titlePx; font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.sendOperatorIdFact.visible
                    implicitHeight: Math.max(root.rowMinH, ob.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ob
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Yayımla%1").arg(root.isEURegion ? qsTr(" (EU tələb edir)") : "")
                                   color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactCheckBoxSlider { fact: root.sendOperatorIdFact; enabled: root.isFAARegion }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.operatorIDType.visible
                    implicitHeight: Math.max(root.rowMinH, ot.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ot
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.operatorIDType.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.operatorIDType; indexModel: false
                                       Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.operatorIDFact.visible
                    implicitHeight: Math.max(root.rowMinH, ov.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: ov
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.operatorIDFact.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
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
            color: panelStyle.panelBg
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
                    color: "white"; font.pixelSize: panelStyle.titlePx; font.bold: true
                    Layout.fillWidth: true
                }
                Text {
                    text: qsTr("Fövqəladə hal elan olunarsa, «Yayımla» sönülü olsa belə fövqəladə mətn yayımlanacaq.")
                    color: "#B8B8B8"; font.pixelSize: root.labelFontPx
                    wrapMode: Text.WordWrap; Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.sendSelfID.visible
                    implicitHeight: Math.max(root.rowMinH, sb.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: sb
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Yayımla"); color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactCheckBoxSlider { fact: root.remoteIDSettings.sendSelfID }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.selfIDType.visible
                    implicitHeight: Math.max(root.rowMinH, st.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: st
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Yayım mesajı"); color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.selfIDType; indexModel: false
                                       enabled: root.remoteIDSettings.sendSelfID.rawValue
                                       Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.selfIDFree.visible
                    implicitHeight: Math.max(root.rowMinH, sf.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: sf
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.selfIDFree.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.selfIDFree; maximumLength: 23
                                        enabled: root.remoteIDSettings.sendSelfID.rawValue
                                        Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.selfIDExtended.visible
                    implicitHeight: Math.max(root.rowMinH, se.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: se
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.selfIDExtended.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.selfIDExtended; maximumLength: 23
                                        enabled: root.remoteIDSettings.sendSelfID.rawValue
                                        Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.selfIDEmergency.visible
                    implicitHeight: Math.max(root.rowMinH, sm.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: sm
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.selfIDEmergency.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
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
            color: panelStyle.panelBg
            radius: panelStyle.radius
            border.width: 1
            border.color: root._activeRID ? (root._remoteIDManager.gcsGPSGood ? panelStyle.border : qgcPal.colorRed) : panelStyle.border
            height: lay.implicitHeight + panelStyle.pad * 2

            ColumnLayout {
                id: lay
                anchors.fill: parent
                anchors.margins: panelStyle.pad
                spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

                Text {
                    text: qsTr("Yer Stansiyasının Mövqeyi")
                    color: "white"; font.pixelSize: panelStyle.titlePx; font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    implicitHeight: Math.max(root.rowMinH, lt.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: lt
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.locationTypeFact.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.locationTypeFact; indexModel: false; Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    implicitHeight: Math.max(root.rowMinH, gl1.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: gl1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.latitudeFixed.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.latitudeFixed; maximumLength: 20
                                        enabled: root._locationFixed; Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    implicitHeight: Math.max(root.rowMinH, gl2.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: gl2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.longitudeFixed.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.longitudeFixed; maximumLength: 20
                                        enabled: root._locationFixed; Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    implicitHeight: Math.max(root.rowMinH, gl3.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: gl3
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.altitudeFixed.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactTextField { fact: root.remoteIDSettings.altitudeFixed; maximumLength: 20
                                        enabled: root._locationFixed; Layout.preferredWidth: root.ctrlW }
                    }
                }

                // ---- NMEA xarici GPS ----
                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
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
                        QGCLabel { text: qsTr("NMEA xarici GPS cihazı"); color: "white"; font.pixelSize: root.labelFontPx
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
                        QGCLabel { text: qsTr("NMEA GPS Baudrate"); color: "white"; font.pixelSize: root.labelFontPx
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
                    visible: nmeaPortCombo.currentText === root.gpsUdpPort
                             && root._locationType !== RemoteIDSettings.LocationType.TAKEOFF
                    implicitHeight: Math.max(root.rowMinH, nm3.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: nm3
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("NMEA axını UDP portu"); color: "white"; font.pixelSize: root.labelFontPx
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
            color: panelStyle.panelBg
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
                    color: "white"; font.pixelSize: panelStyle.titlePx; font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.classificationType.visible
                    implicitHeight: Math.max(root.rowMinH, eu1.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: eu1
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: qsTr("Məlumat təqdim et"); color: "white"; font.pixelSize: root.labelFontPx
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
                    visible: root.remoteIDSettings.categoryEU.visible
                    implicitHeight: Math.max(root.rowMinH, eu2.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: eu2
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.categoryEU.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.categoryEU; indexModel: false
                                       enabled: euProvideInfoSlider.checked; Layout.preferredWidth: root.ctrlW }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: panelStyle.rowRadius; color: panelStyle.rowBg
                    visible: root.remoteIDSettings.classEU.visible
                    implicitHeight: Math.max(root.rowMinH, eu3.implicitHeight + root.rowPadY * 2)
                    RowLayout {
                        id: eu3
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPadX; anchors.rightMargin: root.rowPadX
                        anchors.topMargin: root.rowPadY;  anchors.bottomMargin: root.rowPadY
                        spacing: root.gap
                        QGCLabel { text: root.remoteIDSettings.classEU.shortDescription; color: "white"; font.pixelSize: root.labelFontPx
                                   elide: Text.ElideRight; Layout.fillWidth: true }
                        FactComboBox { fact: root.remoteIDSettings.classEU; indexModel: false
                                       enabled: euProvideInfoSlider.checked; Layout.preferredWidth: root.ctrlW }
                    }
                }
            }
        }
    }
}

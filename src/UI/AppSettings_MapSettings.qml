import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.QGCMapEngineManager

// Map settings, in the new design: the page header of the setup pages, status cards with
// group box rows, and the new combo boxes, fields and buttons.
Item {
    id: root
    anchors.fill: parent

    // The combo boxes, fields, labels, buttons and dialogs take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ---------------- Settings refs ----------------
    property var    _settingsManager:               QGroundControl.settingsManager
    property var    _appSettings:                   _settingsManager.appSettings
    property var    _mapsSettings:                  _settingsManager.mapsSettings
    property var    _mapEngineManager:              QGroundControl.mapEngineManager
    property bool   _currentlyImportOrExporting:    _mapEngineManager.importAction === QGCMapEngineManager.ImportAction.ActionExporting ||
                                                    _mapEngineManager.importAction === QGCMapEngineManager.ImportAction.ActionImporting
    property real   _largeTextFieldWidth:           ScreenTools.defaultFontPixelWidth * 30

    property Fact   _mapProviderFact:               _settingsManager.flightMapSettings.mapProvider
    property Fact   _mapTypeFact:                   _settingsManager.flightMapSettings.mapType
    property Fact   _elevationProviderFact:         _settingsManager.flightMapSettings.elevationMapProvider
    property Fact   _mapboxFact:                    _settingsManager ? _settingsManager.appSettings.mapboxToken   : null
    property Fact   _mapboxAccountFact:             _settingsManager ? _settingsManager.appSettings.mapboxAccount : null
    property Fact   _mapboxStyleFact:               _settingsManager ? _settingsManager.appSettings.mapboxStyle   : null
    property Fact   _esriFact:                      _settingsManager ? _settingsManager.appSettings.esriToken    : null
    property Fact   _customURLFact:                 _settingsManager ? _settingsManager.appSettings.customURL     : null
    property Fact   _vworldFact:                    _settingsManager ? _settingsManager.appSettings.vworldToken   : null

    // ---------------- Responsive metrics ----------------
    readonly property bool phone:  ScreenTools.isMobile || width < 800
    readonly property bool tablet: width < 1200

    readonly property real sidePadding: AzTheme.px(phone ? 12 : 20)
    readonly property real gap:         AzTheme.px(phone ? 10 : 16)

    readonly property real fontScale: {
        var w = Math.max(1, width)
        var s = w / 1200.0
        s = Math.min(1.0, s)
        return Math.max(0.90, Math.min(1.0, s))
    }

    readonly property real titleFontPx:   AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descFontPx:    AzTheme.fontPx(13)
    readonly property real sectionFontPx: AzTheme.fontPx(16)
    readonly property real rowFontPx:     AzTheme.fontPx(AzTheme.popupTextSize)
    readonly property real smallPoint:    ScreenTools.smallFontPointSize * fontScale

    readonly property real contentW: Math.max(0, width - 2 * sidePadding)

    // ✅ Bloklar 2 sütunda — Telemetriya səhifəsindəki eyni formul
    // Blok ölçüləri Uçuş Görünüşü səhifəsi ilə eynidir (Fly_ViewSettings.qml)
    readonly property real minColW: (tablet ? 520 : 720)
    readonly property real maxColW: 820

    readonly property int columns: (phone || contentW < (2 * minColW + gap)) ? 1 : 2

    readonly property real colW: (columns === 1)
                                 ? contentW
                                 : Math.min(maxColW, Math.floor((contentW - gap) / 2))

    readonly property real panelW: colW

    // row sizes
    readonly property real rowPadX: AzTheme.px(AzTheme.groupPadding)
    readonly property real rowPadY: AzTheme.px(8)
    readonly property real rowMinH: AzTheme.px(AzTheme.groupRowHeight + 4)

    // general control widths (token textfields etc.)
    // Kontrol enləri də Uçuş Görünüşü ilə eyni formuladır
    readonly property real ctrlW:         Math.max(140, Math.min(260, colW * (phone ? 0.60 : 0.42)))
    readonly property real rightControlW: ctrlW
    readonly property real actionBtnW:    ctrlW

    // -------------------- BLOCK BACKGROUND MAP INPUT --------------------
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    WheelHandler {
        target: root
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(w) {
            w.accepted = true
            if (!flick) return

            var step = 0
            if (w.pixelDelta && w.pixelDelta.y !== 0) step = w.pixelDelta.y
            else step = w.angleDelta.y / 3

            var maxY = Math.max(0, flick.contentHeight - flick.height)
            flick.contentY = _clamp(flick.contentY - step, 0, maxY)
        }
    }

    PinchHandler {
        // Pinch jestini sadəcə “tut”, UI-ni böyütmə/kiçiltmə/daşıma ETMƏ
        target: null

        acceptedDevices: PointerDevice.TouchScreen

        // təhlükəsizlik üçün: scale/rotation kilidlə (target null olsa da problem çıxmaz)
        minimumScale: 1
        maximumScale: 1
        minimumRotation: 0
        maximumRotation: 0

        // (əgər versiyada varsa) jesti mütləq özünə götürsün
        grabPermissions: PointerHandler.CanTakeOverFromAnything
    }

    // ---------------- Header ----------------
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
            width: parent.width
            text: qsTr("Xəritə Parametrləri")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titleFontPx
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            text: qsTr("Xəritə və oflayn xəritə parametrləri")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descFontPx
            wrapMode: Text.WordWrap
        }
    }

    // ---------------- Scroll ----------------
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
            spacing: root.gap

        // Hər sütun öz-özünə sıx yığılır (masonry) — blok altında boşluq qalmır
        Item {
            id: panelFlow
            x: root.sidePadding
            width: Math.max(0, flick.width - 2 * root.sidePadding)
            height: (root.columns === 1)
                    ? (mapColLeft.height + root.gap + mapColRight.height)
                    : Math.max(mapColLeft.height, mapColRight.height)

        Column {
            id: mapColLeft
            x: 0
            y: 0
            width: root.colW
            spacing: root.gap

            // -------------------- 1) Xəritə Provayderi --------------------
            Rectangle {
                id: providerPanel
                width: parent.width
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                readonly property real pad: AzTheme.px(16)
                readonly property real desiredH: providerLayout.implicitHeight + pad * 2
                height: desiredH

                ColumnLayout {
                    id: providerLayout
                    x: providerPanel.pad
                    y: providerPanel.pad
                    width: providerPanel.width - 2 * providerPanel.pad
                    spacing: AzTheme.px(8)

                    Text {
                        text: qsTr("Xəritə Provayderi")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionFontPx
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    // ✅ Provayder (HƏMİŞƏ eyni row)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _mapProviderFact.visible
                        implicitHeight: Math.max(root.rowMinH, provRow.implicitHeight + root.rowPadY * 2)

                        RowLayout {
                            id: provRow
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            spacing: root.gap

                            QGCLabel {
                                text: qsTr("Provayder")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            QGCComboBox {
                                id: providerCombo
                                Layout.preferredWidth: root.rightControlW
                                Layout.minimumWidth: 0
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                sizeToContents: false
                                model: _mapEngineManager.mapProviderList

                                onActivated: function(index) {
                                    _mapProviderFact.rawValue = textAt(index)
                                    _mapTypeFact.rawValue = _mapEngineManager.mapTypeList(textAt(index))[0]
                                }

                                Component.onCompleted: {
                                    var index = find(_mapProviderFact.rawValue)
                                    if (index < 0) index = 0
                                    currentIndex = index
                                }
                            }
                        }
                    }

                    // ✅ Növ (HƏMİŞƏ eyni row)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _mapTypeFact.visible
                        implicitHeight: Math.max(root.rowMinH, typeRow.implicitHeight + root.rowPadY * 2)

                        RowLayout {
                            id: typeRow
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            spacing: root.gap

                            QGCLabel {
                                text: qsTr("Növ")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            QGCComboBox {
                                id: typeCombo
                                Layout.preferredWidth: root.rightControlW
                                Layout.minimumWidth: 0
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                sizeToContents: false
                                model: _mapEngineManager.mapTypeList(_mapProviderFact.rawValue)

                                onActivated: function(index) {
                                    _mapTypeFact.rawValue = textAt(index)
                                }

                                Component.onCompleted: {
                                    var index = find(_mapTypeFact.rawValue)
                                    if (index < 0) index = 0
                                    currentIndex = index
                                }
                            }
                        }
                    }

                    // ✅ Yüksəklik Təchizatçısı (HƏMİŞƏ eyni row)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _elevationProviderFact.visible
                        implicitHeight: Math.max(root.rowMinH, elevRow.implicitHeight + root.rowPadY * 2)

                        RowLayout {
                            id: elevRow
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            spacing: root.gap

                            QGCLabel {
                                text: qsTr("Yüksəklik Təchizatçısı")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            QGCComboBox {
                                id: elevCombo
                                Layout.preferredWidth: root.rightControlW
                                Layout.minimumWidth: 0
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                sizeToContents: false
                                model: _mapEngineManager.elevationProviderList

                                onActivated: function(index) {
                                    _elevationProviderFact.rawValue = textAt(index)
                                }

                                Component.onCompleted: {
                                    var index = find(_elevationProviderFact.rawValue)
                                    if (index < 0) index = 0
                                    currentIndex = index
                                }
                            }
                        }
                    }
                }
            }

            // -------------------- 2) Oflayn Xəritələr --------------------
            Rectangle {
                id: offlinePanel
                width: parent.width
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                readonly property real pad: AzTheme.px(16)
                readonly property real desiredH: offlineLayout.implicitHeight + pad * 2
                height: desiredH

                ColumnLayout {
                    id: offlineLayout
                    x: offlinePanel.pad
                    y: offlinePanel.pad
                    width: offlinePanel.width - 2 * offlinePanel.pad
                    spacing: AzTheme.px(8)

                    Text {
                        text: qsTr("Oflayn Xəritələr")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionFontPx
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: QGroundControl.mapEngineManager.tileSets

                        OfflineMapInfo {
                            tileSet: object
                            enabled: !object.deleting
                            Layout.fillWidth: true
                            onClicked: offlineMapEditorComponent.createObject(root, { tileSet: object }).showInfo()
                        }
                    }

                    // ✅ Yeni dəst (button HƏMİŞƏ eyni row)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        implicitHeight: Math.max(root.rowMinH, addRow.implicitHeight + root.rowPadY * 2)

                        RowLayout {
                            id: addRow
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            spacing: root.gap

                            QGCLabel {
                                text: qsTr("Yeni Dəst əlavə edin")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            QGCButton {
                                text: qsTr("Əlavə et")
                                Layout.preferredWidth: root.actionBtnW
                                Layout.minimumWidth: 120
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                enabled: !_currentlyImportOrExporting
                                onClicked: offlineMapEditorComponent.createObject(root).addNewSet()
                            }
                        }
                    }

                    // ✅ Import (button HƏMİŞƏ eyni row)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: QGroundControl.corePlugin.options.showOfflineMapImport
                        implicitHeight: Math.max(root.rowMinH, impRow.implicitHeight + root.rowPadY * 2)

                        RowLayout {
                            id: impRow
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            spacing: root.gap

                            QGCLabel {
                                text: qsTr("Map Tiles daxil edin")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            QGCButton {
                                text: qsTr("Daxil edin")
                                Layout.preferredWidth: root.actionBtnW
                                Layout.minimumWidth: 120
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                enabled: !_currentlyImportOrExporting
                                onClicked: {
                                    _mapEngineManager.importAction = QGCMapEngineManager.ImportAction.ActionNone
                                    importDialogComponent.createObject(mainWindow).open()
                                }
                            }
                        }
                    }

                    // ✅ Export (button HƏMİŞƏ eyni row)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: QGroundControl.corePlugin.options.showOfflineMapExport
                        implicitHeight: Math.max(root.rowMinH, expRow.implicitHeight + root.rowPadY * 2)

                        RowLayout {
                            id: expRow
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            spacing: root.gap

                            QGCLabel {
                                text: qsTr("Map Tiles xaric edin")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            QGCButton {
                                text: qsTr("Xaric edin")
                                Layout.preferredWidth: root.actionBtnW
                                Layout.minimumWidth: 120
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                enabled: !_currentlyImportOrExporting
                                onClicked: exportDialogComponent.createObject(mainWindow).open()
                            }
                        }
                    }

                    // Progress (istəsən bunu da always-row saxlayırıq)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _currentlyImportOrExporting
                        implicitHeight: Math.max(root.rowMinH, progRow.implicitHeight + root.rowPadY * 2)

                        RowLayout {
                            id: progRow
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            spacing: root.gap

                            QGCLabel {
                                text: _mapEngineManager.importAction === QGCMapEngineManager.ImportAction.ActionExporting ? qsTr("Xaric edilir") : qsTr("Daxil edilir")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            ProgressBar {
                                id: tileProgress
                                Layout.preferredWidth: root.rightControlW
                                Layout.minimumWidth: 150
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                from: 0
                                to: 100
                                value: _mapEngineManager.actionProgress

                                background: Rectangle {
                                    implicitHeight: AzTheme.px(8)
                                    radius:         height / 2
                                    color:          AzTheme.slotEmpty
                                }

                                contentItem: Item {
                                    implicitHeight: AzTheme.px(8)

                                    Rectangle {
                                        width:  tileProgress.visualPosition * parent.width
                                        height: parent.height
                                        radius: height / 2
                                        color:  AzTheme.statusGreen
                                    }
                                }
                            }
                        }
                    }
                }
            }

        } // mapColLeft

        Column {
            id: mapColRight
            x: (root.columns === 2) ? (root.colW + root.gap) : 0
            y: (root.columns === 2) ? 0 : (mapColLeft.height + root.gap)
            width: root.colW
            spacing: root.gap

            // -------------------- 3) Tokenlər --------------------
            Rectangle {
                id: tokensPanel
                width: parent.width
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                readonly property real pad: AzTheme.px(16)
                readonly property real desiredH: tokensLayout.implicitHeight + pad * 2
                height: desiredH

                ColumnLayout {
                    id: tokensLayout
                    x: tokensPanel.pad
                    y: tokensPanel.pad
                    width: tokensPanel.width - 2 * tokensPanel.pad
                    spacing: AzTheme.px(8)

                    Text {
                        text: qsTr("Tokenlər")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionFontPx
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    // Mapbox
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _appSettings.mapboxToken.visible
                        implicitHeight: Math.max(root.rowMinH, mapboxTokGrid.implicitHeight + root.rowPadY * 2)

                        GridLayout {
                            id: mapboxTokGrid
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            columns: root.phone ? 1 : 2
                            columnSpacing: root.gap
                            rowSpacing: Math.max(6, root.gap * 0.6)

                            QGCLabel {
                                text: qsTr("Mapbox")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                            }

                            FactTextField {
                                Layout.preferredWidth: root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.fillWidth: root.phone
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                                fact: _appSettings.mapboxToken
                            }
                        }
                    }

                    // Esri
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _appSettings.esriToken.visible
                        implicitHeight: Math.max(root.rowMinH, esriTokGrid.implicitHeight + root.rowPadY * 2)

                        GridLayout {
                            id: esriTokGrid
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            columns: root.phone ? 1 : 2
                            columnSpacing: root.gap
                            rowSpacing: Math.max(6, root.gap * 0.6)

                            QGCLabel {
                                text: qsTr("Esri")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                            }

                            FactTextField {
                                Layout.preferredWidth: root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.fillWidth: root.phone
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                                fact: _appSettings.esriToken
                            }
                        }
                    }

                    // VWorld
                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _appSettings.vworldToken.visible
                        implicitHeight: Math.max(root.rowMinH, vworldTokGrid.implicitHeight + root.rowPadY * 2)

                        GridLayout {
                            id: vworldTokGrid
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            columns: root.phone ? 1 : 2
                            columnSpacing: root.gap
                            rowSpacing: Math.max(6, root.gap * 0.6)

                            QGCLabel {
                                text: qsTr("VWorld")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                            }

                            FactTextField {
                                Layout.preferredWidth: root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.fillWidth: root.phone
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                                fact: _appSettings.vworldToken
                            }
                        }
                    }
                }
            }

            // -------------------- 4) Mapbox Giriş --------------------
            Rectangle {
                id: mapboxPanel
                width: parent.width
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                readonly property real pad: AzTheme.px(16)
                readonly property real desiredH: mapboxLayout.implicitHeight + pad * 2
                height: desiredH

                ColumnLayout {
                    id: mapboxLayout
                    x: mapboxPanel.pad
                    y: mapboxPanel.pad
                    width: mapboxPanel.width - 2 * mapboxPanel.pad
                    spacing: AzTheme.px(8)

                    Text {
                        text: qsTr("Mapbox Giriş")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionFontPx
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _appSettings.mapboxAccount.visible
                        implicitHeight: Math.max(root.rowMinH, mapAccGrid.implicitHeight + root.rowPadY * 2)

                        GridLayout {
                            id: mapAccGrid
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            columns: root.phone ? 1 : 2
                            columnSpacing: root.gap
                            rowSpacing: Math.max(6, root.gap * 0.6)

                            QGCLabel {
                                text: qsTr("Hesab")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                            }

                            FactTextField {
                                Layout.preferredWidth: root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.fillWidth: root.phone
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                                fact: _appSettings.mapboxAccount
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _appSettings.mapboxStyle.visible
                        implicitHeight: Math.max(root.rowMinH, mapStyleGrid.implicitHeight + root.rowPadY * 2)

                        GridLayout {
                            id: mapStyleGrid
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            columns: root.phone ? 1 : 2
                            columnSpacing: root.gap
                            rowSpacing: Math.max(6, root.gap * 0.6)

                            QGCLabel {
                                text: qsTr("Xəritə üslubu")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                            }

                            FactTextField {
                                Layout.preferredWidth: root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.fillWidth: root.phone
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                                fact: _appSettings.mapboxStyle
                            }
                        }
                    }
                }
            }

            // -------------------- 5) Fərdi Xəritə URL-i --------------------
            Rectangle {
                id: customUrlPanel
                width: parent.width
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                readonly property real pad: AzTheme.px(16)
                readonly property real desiredH: customUrlLayout.implicitHeight + pad * 2
                height: desiredH

                ColumnLayout {
                    id: customUrlLayout
                    x: customUrlPanel.pad
                    y: customUrlPanel.pad
                    width: customUrlPanel.width - 2 * customUrlPanel.pad
                    spacing: AzTheme.px(8)

                    Text {
                        text: qsTr("Fərdi Xəritə URL-i")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionFontPx
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _appSettings.customURL.visible
                        implicitHeight: Math.max(root.rowMinH, customGrid.implicitHeight + root.rowPadY * 2)

                        GridLayout {
                            id: customGrid
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            columns: root.phone ? 1 : 2
                            columnSpacing: root.gap
                            rowSpacing: Math.max(6, root.gap * 0.6)

                            QGCLabel {
                                text: qsTr("Server URL")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                            }

                            FactTextField {
                                Layout.preferredWidth: root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.fillWidth: root.phone
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                                fact: _appSettings.customURL
                            }
                        }
                    }
                }
            }

            // -------------------- 6) Tile Keş --------------------
            Rectangle {
                id: cachePanel
                width: parent.width
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                readonly property real pad: AzTheme.px(16)
                readonly property real desiredH: cacheLayout.implicitHeight + pad * 2
                height: desiredH

                ColumnLayout {
                    id: cacheLayout
                    x: cachePanel.pad
                    y: cachePanel.pad
                    width: cachePanel.width - 2 * cachePanel.pad
                    spacing: AzTheme.px(8)

                    Text {
                        text: qsTr("Tile Keş")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionFontPx
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _mapsSettings.maxCacheDiskSize.visible
                        implicitHeight: Math.max(root.rowMinH, diskGrid.implicitHeight + root.rowPadY * 2)

                        GridLayout {
                            id: diskGrid
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            columns: root.phone ? 1 : 2
                            columnSpacing: root.gap
                            rowSpacing: Math.max(6, root.gap * 0.6)

                            QGCLabel {
                                text: qsTr("Maksimum Keş Disk Ölçüsü")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            FactTextField {
                                Layout.preferredWidth: root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.fillWidth: root.phone
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                                fact: _mapsSettings.maxCacheDiskSize
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _mapsSettings.maxCacheMemorySize.visible
                        implicitHeight: Math.max(root.rowMinH, memGrid.implicitHeight + root.rowPadY * 2)

                        GridLayout {
                            id: memGrid
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPadX
                            anchors.rightMargin: root.rowPadX
                            anchors.topMargin: root.rowPadY
                            anchors.bottomMargin: root.rowPadY
                            columns: root.phone ? 1 : 2
                            columnSpacing: root.gap
                            rowSpacing: Math.max(6, root.gap * 0.6)

                            QGCLabel {
                                text: qsTr("Maksimum Keş Yaddaş Ölçüsü")
                                font.pixelSize: root.rowFontPx
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }

                            FactTextField {
                                Layout.preferredWidth: root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.fillWidth: root.phone
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                                fact: _mapsSettings.maxCacheMemorySize
                            }
                        }
                    }
                }
            }

        } // mapColRight
        } // panelFlow

            Item { width: 1; height: root.sidePadding }
        }
    }

    // ---------------- Backend ----------------
    Component.onCompleted: {
        QGroundControl.mapEngineManager.loadTileSets()
    }

    Connections {
        target: _mapEngineManager
        function onErrorMessageChanged() {
            errorDialogComponent.createObject(mainWindow).open()
        }
    }

    QGCFileDialog {
        id:             fileDialog
        folder:         _appSettings.missionSavePath
        nameFilters:    [ qsTr("Tile Sets (*.%1)").arg(defaultSuffix) ]
        defaultSuffix:  _appSettings.tilesetFileExtension

        onAcceptedForSave: function(file) {
            close()
            _mapEngineManager.exportSets(file)
        }

        onAcceptedForLoad: function(file) {
            close()
            _mapEngineManager.importSets(file)
        }
    }

    Component {
        id: exportDialogComponent

        QGCPopupDialog {
            title:      qsTr("Seçilmiş Tile dəstlərini xaric edin")
            buttons:    Dialog.Ok | Dialog.Cancel

            onAccepted: {
                close()
                fileDialog.title = qsTr("Tiles xaric et")
                fileDialog.openForSave()
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth / 2

                Repeater {
                    model: _mapEngineManager.tileSets

                    QGCCheckBox {
                        text:       object.name
                        checked:    object.selected
                        onClicked:  object.selected = checked
                    }
                }
            }
        }
    }

    Component {
        id: importDialogComponent

        QGCPopupDialog {
            title:      qsTr("Tile dəstlərini daxil edin")
            buttons:    Dialog.Ok | Dialog.Cancel

            onAccepted: {
                close()
                fileDialog.title = qsTr("Tiles daxil et")
                fileDialog.openForLoad()
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth / 2

                QGCRadioButton {
                    text:           qsTr("Mövcud dəstlərə əlavə edin")
                    checked:        !_mapEngineManager.importReplace
                    onClicked:      _mapEngineManager.importReplace = !checked
                }
                QGCRadioButton {
                    text:           qsTr("Mövcud dəstləri dəyişdirin")
                    checked:        _mapEngineManager.importReplace
                    onClicked:      _mapEngineManager.importReplace = checked
                }
            }
        }
    }

    Component {
        id: errorDialogComponent

        QGCSimpleMessageDialog {
            title:      qsTr("Xəta Mesajı")
            text:       _mapEngineManager.errorMessage
            buttons:    Dialog.Close
        }
    }

    Component {
        id: offlineMapEditorComponent

        OfflineMapEditor {
            id:             offlineMapEditor
            anchors.fill:   parent
        }
    }
}

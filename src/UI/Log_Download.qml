import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

// Log download, in the new design: the page header of the setup pages, the log table on a
// status card with a group box header row, and AzButton actions.
Item {
    id: root
    anchors.fill: parent

    // The check boxes, labels and dialogs take the new design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // QGC singleton controller (yaratmırıq!)
    readonly property var logController: LogDownloadController

    // -------- responsive helpers
    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : 14
    readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : 8
    readonly property bool _compact: (width < 1050) || (height < 650) || (_hasScreenTools && ScreenTools.isShortScreen)

    // spacing/padding
    readonly property real _outer: AzTheme.px(_compact ? 12 : 20)
    readonly property real _pad:   AzTheme.px(_compact ? 12 : 16)
    readonly property real _gap:   AzTheme.px(_compact ? 10 : 16)

    readonly property real _topGap: AzTheme.px(_compact ? 12 : 20)

    readonly property real _titlePx: AzTheme.fontPx(_compact ? 18 : 20)
    readonly property real _descPx:  AzTheme.fontPx(13)

    readonly property real _rowH:    AzTheme.px(_compact ? 34 : 38)
    readonly property real _cellPad: Math.round(Math.max(6,  _fontW * (_compact ? 0.90 : 1.20)))

    // Sütun enləri (min). Ekran daralarsa horizontal scroll açılacaq.
    readonly property real _checkW:    Math.round(Math.max(28,  _fontH * 1.25))
    readonly property real _idW:       Math.round(Math.max(56,  _fontW * 6.5))
    readonly property real _sizeW:     Math.round(Math.max(72,  _fontW * 8.5))
    readonly property real _statusW:   Math.round(Math.max(120, _fontW * 14))
    readonly property real _dateMinW:  Math.round(Math.max(200, _fontW * 20))
    readonly property real _tableMinW: _checkW + _idW + _dateMinW + _sizeW + _statusW + (_cellPad * 2)

    readonly property real _actionW: Math.round(Math.max(170, _fontW * 17))

    // -------------------- BLOCK BACKGROUND MAP INPUT (Wheel + Pinch) --------------------
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    // Mouse/touchpad wheel map-a getməsin + scroll-u ListView/Flickable-a çevir
    WheelHandler {
        target: root
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: function(w) {
            // mütləq accepted et: arxaya (xəritəyə) keçməsin
            w.accepted = true

            // delta oxu
            var dx = 0
            var dy = 0

            if (w.pixelDelta) {
                dx = w.pixelDelta.x
                dy = w.pixelDelta.y
            }
            if (dx === 0 && dy === 0) {
                // mouse wheel üçün
                dx = w.angleDelta.x / 3
                dy = w.angleDelta.y / 3
            }

            // Shift basılıbsa və ya horizontal daha güclüdürsə -> horizontal scroll
            var shiftHeld = (w.modifiers & Qt.ShiftModifier)
            var wantHorizontal = shiftHeld || (Math.abs(dx) > Math.abs(dy))

            // Horizontal mümkün deyilsə, vertikala düş
            if (wantHorizontal && typeof hFlick !== "undefined" && hFlick && hFlick.interactive) {
                // shift basılanda çox vaxt dy gəlir, onu da horizontal kimi istifadə edək
                var stepX = (Math.abs(dx) > 0) ? dx : dy
                var maxX = Math.max(0, hFlick.contentWidth - hFlick.width)
                hFlick.contentX = _clamp(hFlick.contentX - stepX, 0, maxX)
                return
            }

            // Default: vertikal scroll (logList)
            if (typeof logList !== "undefined" && logList) {
                var maxY = Math.max(0, logList.contentHeight - logList.height)
                logList.contentY = _clamp(logList.contentY - dy, 0, maxY)
            }
        }
    }

    // Android pinch (2 barmaq zoom) map-a keçməsin
    PinchHandler {
        // jesti sadəcə “tut”
        target: null
        acceptedDevices: PointerDevice.TouchScreen

        // UI-ni böyütmə/kiçiltmə etmə
        minimumScale: 1
        maximumScale: 1
        minimumRotation: 0
        maximumRotation: 0

        // jesti digər handlerlərdən/elementlərdən qoparıb götürə bilsin
        grabPermissions: PointerHandler.CanTakeOverFromAnything
    }

    function _dateText(o) {
        if (!o) return ""
        if (!o.received) return ""
        if (o.time && o.time.getUTCFullYear && o.time.getUTCFullYear() < 2010) return qsTr("Naməlum Tarix")
        return o.time ? o.time.toLocaleString(undefined) : ""
    }

    function _hasSelectedLogs() {
        if (!logController || !logController.model) return false
        for (var i = 0; i < logController.model.count; i++) {
            var obj = logController.model.get(i)
            if (obj && obj.selected) return true
        }
        return false
    }

    function _setAllSelected(sel) {
        if (!logController || !logController.model) return
        for (var i = 0; i < logController.model.count; i++) {
            var obj = logController.model.get(i)
            if (obj) obj.selected = sel
        }
    }

    function doRefresh() {
        var v = QGroundControl.multiVehicleManager.activeVehicle
        if (!v || v.isOfflineEditingVehicle) {
            if (typeof mainWindow !== "undefined" && mainWindow) {
                mainWindow.showMessageDialog(qsTr("Log Yenilə"),
                                             qsTr("Qeydləri endirmək üçün siz təyyarəyə qoşulmalısınız."))
            }
            return
        }
        logController.refresh()
    }

    function doDownload() {
        if (!_hasSelectedLogs()) {
            if (typeof mainWindow !== "undefined" && mainWindow) {
                mainWindow.showMessageDialog(qsTr("Log Yüklə"),
                                             qsTr("Yükləmək üçün ən azı bir günlük faylı seçməlisiniz."))
            }
            return
        }

        if (_hasScreenTools && ScreenTools.isMobile) {
            logController.download()
            return
        }

        saveFolderDialog.title = qsTr("Saxlama qovluğunu seçin")
        saveFolderDialog.folder = QGroundControl.settingsManager.appSettings.logSavePath
        saveFolderDialog.selectFolder = true
        saveFolderDialog.openForLoad()
    }

    function doEraseAll() {
        if (typeof mainWindow !== "undefined" && mainWindow) {
            mainWindow.showMessageDialog(
                qsTr("Bütün Günlük Faylları Sil"),
                qsTr("Bütün log faylları həmişəlik silinəcək. Həqiqətən istədiyiniz budurmu?"),
                Dialog.Yes | Dialog.No,
                function() { logController.eraseAll() }
            )
        } else {
            logController.eraseAll()
        }
    }

    function doCancel() { logController.cancel() }

    QGCFileDialog {
        id: saveFolderDialog
        onAcceptedForLoad: (file) => {
            logController.download(file)
            close()
        }
    }

    // --------------------
    // Margin/boş sahələrdə click/wheel map-a getməsin deyə arxa blocker
    // (card üstündə deyil -> UI elementlərini bloklamır)
    // --------------------
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        z: 0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onWheel: (wheel) => { wheel.accepted = true }
        }
    }

    Rectangle {
        id: card
        z: 1
        anchors.fill: parent
        anchors.topMargin: _topGap
        anchors.leftMargin: _outer
        anchors.rightMargin: _outer
        anchors.bottomMargin: _outer

        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing: _gap

            // ===== Header
            ColumnLayout {
                Layout.fillWidth: true
                spacing: AzTheme.px(6)

                Text {
                    text: qsTr("Log Yükləmə")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: _titlePx
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Log Yükləmə sizə təyyarənizdən ikili jurnal fayllarını endirməyə imkan verir. Mövcud qeydlərin siyahısını əldə etmək üçün Yenilə klikləyin.")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: _descPx
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ===== Body layout: table + actions
            GridLayout {
                id: bodyGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: _gap
                rowSpacing: _gap

                // ---- Actions holder (wide: sağda; compact: yuxarıda)
                Item {
                    id: actionsHolder
                    Layout.row: 0
                    Layout.column: _compact ? 0 : 1
                    Layout.columnSpan: _compact ? 2 : 1
                    Layout.preferredWidth: _compact ? -1 : _actionW
                    Layout.fillWidth: _compact
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignTop

                    implicitHeight: actionsLoader.item ? actionsLoader.item.implicitHeight : 0
                    Layout.preferredHeight: implicitHeight

                    Loader {
                        id: actionsLoader
                        anchors.fill: parent
                        sourceComponent: _compact ? compactActions : wideActions
                    }
                }

                // ---- Table holder
                Rectangle {
                    id: tableCard
                    Layout.row: _compact ? 1 : 0
                    Layout.column: 0
                    Layout.columnSpan: _compact ? 2 : 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }
                    clip: true

                    Flickable {
                        id: hFlick
                        anchors.fill: parent
                        anchors.margins: _cellPad
                        clip: true

                        flickableDirection: Flickable.HorizontalFlick
                        boundsBehavior: Flickable.StopAtBounds

                        contentWidth: Math.max(width, _tableMinW)
                        contentHeight: height
                        interactive: contentWidth > width + 2

                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                        Item {
                            id: tableContent
                            width: hFlick.contentWidth
                            height: hFlick.height

                            // ✅ Header row: label-lər mərkəzdə olsun (aşağı düşməsin)
                            Rectangle {
                                id: headerRow
                                x: 0
                                y: 0
                                width: parent.width
                                height: _rowH
                                radius: AzTheme.px(AzTheme.groupRadius)
                                color: AzTheme.groupFill
                                border.width: 1
                                border.color: AzTheme.groupBorder

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: _cellPad
                                    anchors.rightMargin: _cellPad
                                    spacing: 0

                                    Item {
                                        Layout.preferredWidth: _checkW
                                        Layout.alignment: Qt.AlignVCenter
                                        QGCCheckBox {
                                            id: selectAllBox
                                            anchors.verticalCenter: parent.verticalCenter
                                            enabled: logController && logController.model && logController.model.count > 0
                                            onClicked: _setAllSelected(checked)
                                        }
                                    }

                                    QGCLabel {
                                        text: qsTr("Id")
                                        font.weight: Font.Medium
                                        Layout.preferredWidth: _idW
                                        Layout.alignment: Qt.AlignVCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    QGCLabel {
                                        text: qsTr("Tarix")
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    QGCLabel {
                                        text: qsTr("Ölçü")
                                        font.weight: Font.Medium
                                        Layout.preferredWidth: _sizeW
                                        Layout.alignment: Qt.AlignVCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    QGCLabel {
                                        text: qsTr("Status")
                                        font.weight: Font.Medium
                                        Layout.preferredWidth: _statusW
                                        Layout.alignment: Qt.AlignVCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            ListView {
                                id: logList
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: headerRow.bottom
                                anchors.bottom: parent.bottom
                                clip: true

                                model: logController ? logController.model : null
                                boundsBehavior: Flickable.StopAtBounds

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    parent: hFlick
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                }

                                delegate: Rectangle {
                                    width: tableContent.width
                                    height: _rowH
                                    radius: AzTheme.px(6)
                                    color: (index % 2 === 0) ? "transparent" : AzTheme.pillTop

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: _cellPad
                                        anchors.rightMargin: _cellPad
                                        spacing: 0

                                        Item {
                                            Layout.preferredWidth: _checkW
                                            Layout.alignment: Qt.AlignVCenter
                                            QGCCheckBox {
                                                anchors.verticalCenter: parent.verticalCenter
                                                checked: !!object.selected
                                                onClicked: object.selected = checked
                                            }
                                        }

                                        QGCLabel {
                                            Layout.preferredWidth: _idW
                                            Layout.alignment: Qt.AlignVCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: (object && object.id !== undefined) ? String(object.id) : ""
                                            elide: Text.ElideRight
                                        }

                                        QGCLabel {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: _dateText(object)
                                            elide: Text.ElideRight
                                        }

                                        QGCLabel {
                                            Layout.preferredWidth: _sizeW
                                            Layout.alignment: Qt.AlignVCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: object ? object.sizeStr : ""
                                            elide: Text.ElideRight
                                        }

                                        QGCLabel {
                                            Layout.preferredWidth: _statusW
                                            Layout.alignment: Qt.AlignVCenter
                                            verticalAlignment: Text.AlignVCenter
                                            text: object ? object.status : ""
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            QGCLabel {
                                anchors.centerIn: parent
                                visible: logController && logController.model && logController.model.count === 0
                                text: qsTr("Siyahı boşdur. Logları görmək üçün “Yenilə” klikləyin.")
                                color: AzTheme.textSecondary
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // ===== Actions: wide
    Component {
        id: wideActions
        ColumnLayout {
            implicitHeight: childrenRect.height
            spacing: AzTheme.px(8)

            AzButton { Layout.fillWidth: true
                enabled: !logController.requestingList && !logController.downloadingLogs
                text: qsTr("Yenilə"); onClicked: doRefresh()
            }
            AzButton { Layout.fillWidth: true
                enabled: !logController.requestingList && !logController.downloadingLogs
                positive: true
                text: qsTr("Yüklə"); onClicked: doDownload()
            }
            AzButton { Layout.fillWidth: true
                enabled: !logController.requestingList && !logController.downloadingLogs && (logController.model.count > 0)
                danger: true
                text: qsTr("Hamısını Sil"); onClicked: doEraseAll()
            }
            AzButton { Layout.fillWidth: true
                enabled: logController.requestingList || logController.downloadingLogs
                text: qsTr("Ləğv et"); onClicked: doCancel()
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ===== Actions: compact (yuxarıda 2 sütun)
    Component {
        id: compactActions
        GridLayout {
            columns: 2
            implicitHeight: childrenRect.height
            columnSpacing: _gap
            rowSpacing: AzTheme.px(8)

            AzButton { Layout.fillWidth: true
                enabled: !logController.requestingList && !logController.downloadingLogs
                text: qsTr("Yenilə"); onClicked: doRefresh()
            }
            AzButton { Layout.fillWidth: true
                enabled: !logController.requestingList && !logController.downloadingLogs
                positive: true
                text: qsTr("Yüklə"); onClicked: doDownload()
            }
            AzButton { Layout.fillWidth: true
                enabled: !logController.requestingList && !logController.downloadingLogs && (logController.model.count > 0)
                danger: true
                text: qsTr("Hamısını Sil"); onClicked: doEraseAll()
            }
            AzButton { Layout.fillWidth: true
                enabled: logController.requestingList || logController.downloadingLogs
                text: qsTr("Ləğv et"); onClicked: doCancel()
            }
        }
    }
}

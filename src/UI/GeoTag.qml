import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

// GeoTag images, in the new design: the page header of the setup pages and a status card
// with the file pickers, a green progress bar and the start button.
Item {
    id: root
    anchors.fill: parent

    // The buttons, combo boxes, check boxes, labels and dialogs take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // =========================
    // Controller resolve (kritik fix)
    // =========================
    property var geo: null
    property string _geoResolveError: ""

    function _resolveGeoController() {
        if (geo) return

        // 1) Əvvəlki işlək səhifədəki kimi: context-də geoController varsa götür
        try {
            // geoController undefined olsa ReferenceError atacaq -> catch edirik
            if (geoController) {
                geo = geoController
                return
            }
        } catch (e) {
            // ignore
        }

        // 2) Yoxdursa, özümüz yaratmağa cəhd edirik (QGC-də olan controller)
        //    (Bu yol sayəsində səhifə hər yerdə işləyir)
        try {
            geo = Qt.createQmlObject(
                        'import QtQuick 2.15\n' +
                        'import QGroundControl\n' +
                        'GeoTagController { }',
                        root,
                        "internalGeoTagController"
                        )
            return
        } catch (e2) {
            // Bəzi build-lərdə controller başqa moduldadır, ikinci variantı sınayırıq
        }

        try {
            geo = Qt.createQmlObject(
                        'import QtQuick 2.15\n' +
                        'import QGroundControl.Controllers\n' +
                        'GeoTagController { }',
                        root,
                        "internalGeoTagController2"
                        )
            return
        } catch (e3) {
            _geoResolveError = String(e3)
        }
    }

    Timer {
        id: geoRetry
        interval: 200
        repeat: true
        running: false
        property int tries: 0
        onTriggered: {
            tries++
            root._resolveGeoController()
            if (root.geo || tries >= 15) {
                stop()
            }
        }
    }

    Component.onCompleted: {
        _resolveGeoController()
        if (!geo) geoRetry.start()
    }

    // =========================
    // Responsive helpers
    // =========================
    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : 14
    readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : 8
    readonly property bool _compact: (width < 1050) || (height < 650) || (_hasScreenTools && ScreenTools.isShortScreen)

    readonly property real _outer: AzTheme.px(_compact ? 12 : 20)
    readonly property real _pad:   AzTheme.px(_compact ? 12 : 16)
    readonly property real _gap:   AzTheme.px(_compact ? 10 : 16)

    readonly property real _topGap: AzTheme.px(_compact ? 12 : 20)

    readonly property real _titlePx: AzTheme.fontPx(_compact ? 18 : 20)
    readonly property real _descPx:  AzTheme.fontPx(13)

    // QGC GeoTagPage-dəki min/max eni məntiqi
    readonly property real _minBtnW: Math.round(Math.max(160, _fontW * 20))
    readonly property real _maxBtnW: Math.round(Math.max(_minBtnW, _fontW * 30))
    readonly property real _progressH: Math.round(Math.max(12, _fontH * 1.0))

    function _saveDirText() {
        if (!geo) return qsTr("Seçilməyib")
        if (geo.saveDirectory) {
            return geo.saveDirectory
        } else if (geo.imageDirectory) {
            return geo.imageDirectory + qsTr("/TAGGED")
        } else {
            return qsTr("Şəkil qovluğunuzda /TAGGED qovluğu")
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.topMargin: _topGap
        anchors.leftMargin: _outer
        anchors.rightMargin: _outer
        anchors.bottomMargin: _outer

        color: "transparent"

        // -------- Header (Title + Description)
        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: headerCol.implicitHeight + _pad

            ColumnLayout {
                id: headerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: AzTheme.px(6)

                Text {
                    text: qsTr("GeoTag Şəkillər")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: _titlePx
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("GPS koordinatları ilə sorğu missiyasından bir sıra şəkilləri etiketləmək üçün istifadə olunur. Siz uçuşdan ikili jurnalı, həmçinin etiketlənəcək şəkilləri ehtiva edən kataloqu təqdim etməlisiniz.")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: _descPx
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // -------- Body (scroll)
        QGCFlickable {
            id: bodyFlick
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: AzTheme.px(10)
            clip: true

            contentWidth: width
            contentHeight: bodyCol.implicitHeight
            interactive: contentHeight > height + 2

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

            Column {
                id: bodyCol
                width: bodyFlick.width
                spacing: _gap

                Rectangle {
                    width: parent.width
                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }
                    clip: true

                    implicitHeight: contentGrid.implicitHeight + _pad * 2

                    GridLayout {
                        id: contentGrid
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: _pad

                        columns: _compact ? 1 : 2
                        columnSpacing: _gap
                        rowSpacing: Math.max(8, _fontW * 1.8)

                        // Progress row (QGC kimi)
                        RowLayout {
                            Layout.columnSpan: contentGrid.columns
                            Layout.fillWidth: true
                            spacing: Math.max(10, _gap * 0.8)

                            BusyIndicator {
                                running: geo && (geo.progress > 0) && (geo.progress < 100) && !geo.errorMessage
                                width: _progressH
                                height: _progressH
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                            }

                            ProgressBar {
                                id: tagProgress
                                to: 100
                                value: geo ? geo.progress : 0
                                opacity: (geo && geo.progress > 0) ? 1 : 0.25
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                background: Rectangle {
                                    implicitHeight: AzTheme.px(8)
                                    radius:         height / 2
                                    color:          AzTheme.slotEmpty
                                }

                                contentItem: Item {
                                    implicitHeight: AzTheme.px(8)

                                    Rectangle {
                                        width:  tagProgress.visualPosition * parent.width
                                        height: parent.height
                                        radius: height / 2
                                        color:  AzTheme.statusGreen
                                    }
                                }
                            }
                        }

                        // Error message (QGC kimi)
                        QGCLabel {
                            Layout.columnSpan: contentGrid.columns
                            Layout.fillWidth: true
                            text: geo ? (geo.errorMessage || "") : ""
                            visible: geo && !!geo.errorMessage
                            color: AzTheme.statusRed
                            font.weight: Font.Medium
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // --- Select log file
                        QGCButton {
                            text: qsTr("Log faylı seçin")
                            Layout.fillWidth: true
                            Layout.minimumWidth: _compact ? 0 : _minBtnW
                            Layout.maximumWidth: _compact ? 999999 : _maxBtnW
                            enabled: !!geo && !geo.inProgress
                            onClicked: openLogFile.openForLoad()

                            QGCFileDialog {
                                id: openLogFile
                                title: qsTr("Log faylı seçin")
                                nameFilters: [qsTr("ULog file (*.ulg)"), qsTr("PX4 log faylı (*.px4log)"), qsTr("Bütün fayllar (*)")]
                                defaultSuffix: "ulg"
                                onAcceptedForLoad: (file) => {
                                    if (geo) geo.logFile = file
                                    close()
                                }
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            text: geo ? (geo.logFile || qsTr("Seçilməyib")) : qsTr("Seçilməyib")
                            elide: Text.ElideLeft
                            Layout.alignment: Qt.AlignVCenter
                            color: AzTheme.textSecondary
                        }

                        // --- Select image directory
                        QGCButton {
                            text: qsTr("Şəkil kataloqunu seçin")
                            Layout.fillWidth: true
                            Layout.minimumWidth: _compact ? 0 : _minBtnW
                            Layout.maximumWidth: _compact ? 999999 : _maxBtnW
                            enabled: !!geo && !geo.inProgress
                            onClicked: selectImageDir.openForLoad()

                            QGCFileDialog {
                                id: selectImageDir
                                title: qsTr("Şəkil kataloqunu seçin")
                                selectFolder: true
                                onAcceptedForLoad: (file) => {
                                    if (geo) geo.imageDirectory = file
                                    close()
                                }
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            text: geo ? (geo.imageDirectory || qsTr("Seçilməyib")) : qsTr("Seçilməyib")
                            elide: Text.ElideLeft
                            Layout.alignment: Qt.AlignVCenter
                            color: AzTheme.textSecondary
                        }

                        // --- Select save directory (optional)
                        QGCButton {
                            text: qsTr("(İstəyə görə) Saxlama qovluğunu seçin")
                            Layout.fillWidth: true
                            Layout.minimumWidth: _compact ? 0 : _minBtnW
                            Layout.maximumWidth: _compact ? 999999 : _maxBtnW
                            enabled: !!geo && !geo.inProgress
                            onClicked: selectDestDir.openForLoad()

                            QGCFileDialog {
                                id: selectDestDir
                                title: qsTr("Saxlama qovluğunu seçin")
                                selectFolder: true
                                onAcceptedForLoad: (file) => {
                                    if (geo) geo.saveDirectory = file
                                    close()
                                }
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            text: _saveDirText()
                            elide: Text.ElideLeft
                            Layout.alignment: Qt.AlignVCenter
                            color: AzTheme.textSecondary
                        }

                        Rectangle {
                            Layout.columnSpan: contentGrid.columns
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: AzTheme.groupBorder
                        }

                        // --- Start / Cancel
                        QGCButton {
                            Layout.columnSpan: contentGrid.columns
                            Layout.alignment: Qt.AlignHCenter

                            Layout.minimumWidth: _compact ? 0 : _minBtnW
                            Layout.maximumWidth: _compact ? 999999 : _maxBtnW
                            Layout.fillWidth: _compact

                            primary: !(geo && geo.inProgress)
                            text: (geo && geo.inProgress) ? qsTr("Etiketləməni ləğv et") : qsTr("Etiketləməni başlat")
                            enabled: geo && ((geo.imageDirectory && geo.logFile) || geo.inProgress)

                            onClicked: {
                                if (!geo) return
                                if (geo.inProgress) geo.cancelTagging()
                                else geo.startTagging()
                            }
                        }

                        // Debug mesaj (əgər heç cür controller tapılmadısa)
                        QGCLabel {
                            Layout.columnSpan: contentGrid.columns
                            Layout.fillWidth: true
                            visible: !geo && !!_geoResolveError
                            text: qsTr("GeoTagController yaradıla bilmədi: ") + _geoResolveError
                            color: AzTheme.statusYellow
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Item { width: 1; height: Math.max(6, _gap * 0.5) }
            }
        }
    }
}

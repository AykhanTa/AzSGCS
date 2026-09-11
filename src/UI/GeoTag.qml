import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

Item {
    id: root
    anchors.fill: parent

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

    readonly property real _outer: Math.max(8,  _fontH * (_compact ? 0.45 : 0.75))
    readonly property real _pad:   Math.max(8,  _fontH * (_compact ? 0.42 : 0.70))
    readonly property real _gap:   Math.max(8,  _fontH * (_compact ? 0.32 : 0.65))

    // Böyük ekranda üst xəttdən az aralı
    readonly property real _topGap: _compact ? 0 : Math.max(10, _fontH * 0.60)

    readonly property real _titlePx: Math.round(Math.max(_compact ? 15 : 18, _fontH * (_compact ? 1.05 : 1.30)))
    readonly property real _descPx:  Math.round(Math.max(_compact ? 10 : 12, _fontH * (_compact ? 0.78 : 0.95)))

    readonly property real _btnH:      Math.round(Math.max(_compact ? 30 : 36, _fontH * (_compact ? 1.85 : 2.20)))
    readonly property real _btnFontPx: Math.round(Math.max(10, _fontH * (_compact ? 0.82 : 0.95)))

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

        color: "#2b2b2b"
        radius: 14
        border.width: 2
        border.color: "#444"
        clip: true

        // -------- Header (Title + Description)
        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: headerCol.implicitHeight + _pad

            Column {
                id: headerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: _pad
                anchors.rightMargin: _pad
                anchors.topMargin: _pad * 0.7
                spacing: Math.max(4, _fontH * (_compact ? 0.18 : 0.30))

                QGCLabel {
                    text: qsTr("GeoTag Şəkillər")
                    color: "white"
                    font.bold: true
                    font.pixelSize: _titlePx
                    wrapMode: Text.WordWrap
                }

                QGCLabel {
                    text: qsTr("GPS koordinatları ilə sorğu missiyasından bir sıra şəkilləri etiketləmək üçün istifadə olunur. Siz uçuşdan ikili jurnalı, həmçinin etiketlənəcək şəkilləri ehtiva edən kataloqu təqdim etməlisiniz.")
                    color: "#E8E8E8"
                    font.pixelSize: _descPx
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#FFFFFF"
                    opacity: 0.12
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
            anchors.margins: _pad
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
                    radius: 10
                    color: "#242424"
                    border.width: 1
                    border.color: "#3a3a3a"
                    clip: true

                    implicitHeight: contentGrid.implicitHeight + Math.max(16, _pad * 0.9)

                    GridLayout {
                        id: contentGrid
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Math.max(10, _pad * 0.7)

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
                                to: 100
                                value: geo ? geo.progress : 0
                                opacity: (geo && geo.progress > 0) ? 1 : 0.25
                                Layout.fillWidth: true
                                Layout.preferredHeight: _progressH
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        // Error message (QGC kimi)
                        QGCLabel {
                            Layout.columnSpan: contentGrid.columns
                            Layout.fillWidth: true
                            text: geo ? (geo.errorMessage || "") : ""
                            visible: geo && !!geo.errorMessage
                            color: "red"
                            font.bold: true
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // --- Select log file
                        QGCButton {
                            text: qsTr("Log faylı seçin")
                            Layout.fillWidth: true
                            Layout.preferredHeight: _btnH
                            font.pixelSize: _btnFontPx
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
                            color: "#E8E8E8"
                        }

                        // --- Select image directory
                        QGCButton {
                            text: qsTr("Şəkil kataloqunu seçin")
                            Layout.fillWidth: true
                            Layout.preferredHeight: _btnH
                            font.pixelSize: _btnFontPx
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
                            color: "#E8E8E8"
                        }

                        // --- Select save directory (optional)
                        QGCButton {
                            text: qsTr("(İstəyə görə) Saxlama qovluğunu seçin")
                            Layout.fillWidth: true
                            Layout.preferredHeight: _btnH
                            font.pixelSize: _btnFontPx
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
                            color: "#E8E8E8"
                        }

                        Rectangle {
                            Layout.columnSpan: contentGrid.columns
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: "#FFFFFF"
                            opacity: 0.10
                        }

                        // --- Start / Cancel
                        QGCButton {
                            Layout.columnSpan: contentGrid.columns
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: _btnH
                            font.pixelSize: _btnFontPx

                            Layout.minimumWidth: _compact ? 0 : _minBtnW
                            Layout.maximumWidth: _compact ? 999999 : _maxBtnW
                            Layout.fillWidth: _compact

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
                            color: "#D0B000"
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

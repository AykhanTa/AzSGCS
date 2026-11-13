import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap
import QGroundControl.LogViewer

// Log analysis, in the new design: the page header of the setup pages (AnalyzePage._az),
// the chart on a status card, and the shared buttons, tabs, sliders and combo boxes.
AnalyzePage {
    id: logViewerPage
    pageComponent: pageComponent
    pageName: qsTr("Log Analizi")

    // The buttons, tabs, sliders, combo boxes, labels and log viewer panels take the new
    // design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true
    pageDescription: qsTr("DataFlash (.bin), PX4 ULog (.ulg) və telemetriya (.tlog) loglarını vahid iş axınında açır və təhlil edir.")
    allowPopout: true

    /// Log to open as soon as the page is up. Set by the host when this page is being
    /// recreated inside a popout window, so the log follows the window instead of being
    /// parsed twice or left behind in the panel.
    property string initialLogPath: ""

    /// Hands the loaded log over to a popout window: returns the path and clears this
    /// instance, so the two never hold the same log at once.
    ///
    /// Returns "" when there is nothing to hand over, and also for .tlog -- a telemetry
    /// replay owns a link in LinkManager and re-opening it elsewhere would start a second
    /// one, so a .tlog stays where it is and the new window simply opens empty.
    function takeLogForPopout() {
        if (!pageItem || !pageItem.canHandOverLog()) {
            return ""
        }
        return pageItem.takeLog()
    }

    Component {
        id: pageComponent

        ColumnLayout {
            width: availableWidth
            height: availableHeight
            spacing: AzTheme.px(12)

            property string pendingBinFile: ""

            readonly property bool _xAxisShowLocalTime: QGroundControl.settingsManager.logViewerSettings.xAxisShowLocalTime.rawValue

            readonly property bool isFirmwareLog: logViewerController.sourceType === LogViewerController.Bin
                                             || logViewerController.sourceType === LogViewerController.ULog

            // Cancel any in-flight async parse before QML starts tearing down the tree.
            // Without this, the background thread can emit signals (parseProgressChanged,
            // parseFileFinished) into partially-destroyed QML objects, causing a
            // QQmlData::disconnectNotifiers crash.
            Component.onDestruction: logParser.clear()

            Component.onCompleted: {
                if (logViewerPage.initialLogPath !== "") {
                    loadBinFile(logViewerPage.initialLogPath)
                }
            }

            /// See LogViewer_Page.takeLogForPopout().
            function canHandOverLog() {
                return logViewerController.hasLoadedLog && isFirmwareLog
            }

            function takeLog() {
                const path = logViewerController.currentLogPath
                clearLoadedLogState(true)
                return path
            }

            function clearLoadedLogState(clearControllerState) {
                replayController.isPlaying = false
                replayController.link = null
                logParser.clear()
                logViewerController.setPlottableFields([])
                logViewerController.clearSelection()
                _parametersTab.applyFilter()
                logViewerChart.clearMarker()
                logViewerChart.refreshBinChart()
                if (clearControllerState) {
                    logViewerController.clear()
                }
            }

            function loadBinFile(file) {
                if (logViewerController.hasLoadedLog) {
                    // Match explicit "Clear" behavior before loading replacement .bin file.
                    clearLoadedLogState(true)
                }
                pendingBinFile = file
                logParser.startParsingAsync(file)
            }

            LogViewerController {
                id: logViewerController
            }

            LogFileParser {
                id: logParser
            }

            Connections {
                target: logParser
                ignoreUnknownSignals: true

                function onParseFileFinished(filePath, ok, errorMessage) {
                    if (filePath !== pendingBinFile) {
                        return
                    }

                    if (!ok) {
                        mainWindow.showMessageDialog(qsTr("Log Analizi"), errorMessage)
                        pendingBinFile = ""
                        return
                    }

                    fieldsPanel.rebuildGroupedFields()
                    _parametersTab.applyFilter()
                    logViewerController.clearSelection()
                    logViewerChart.clearMarker()
                    logViewerChart.refreshBinChart()
                    Qt.callLater(logViewerChart.centerCursor)

                    const lowerPath = filePath.toLowerCase()
                    if (lowerPath.endsWith(".ulg")) {
                        logViewerController.openULogFile(filePath)
                    } else {
                        logViewerController.openBinLog(filePath)
                    }
                    pendingBinFile = ""
                }
            }

            LogReplayLinkController {
                id: replayController
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth

                QGCButton {
                    text: qsTr(".bin aç")
                    visible: QGroundControl.apmFirmwareSupported
                    onClicked: {
                        openDialog.nameFilters = ["DataFlash Logs (*.bin *.BIN *.log *.LOG)"]
                        openDialog.openForLoad()
                    }
                }

                QGCButton {
                    text: qsTr(".ulg aç")
                    onClicked: {
                        openDialog.nameFilters = ["PX4 ULog Files (*.ulg *.ULG)"]
                        openDialog.openForLoad()
                    }
                }

                QGCButton {
                    text: qsTr(".tlog aç")
                    onClicked: {
                        const activeVehicle = QGroundControl.multiVehicleManager.activeVehicle
                        if (activeVehicle && !activeVehicle.isOfflineEditingVehicle) {
                            mainWindow.showMessageDialog(qsTr("Log Analizi"), qsTr("Telemetriya təkrar oynatmasından əvvəl aktiv aparat bağlantılarını kəsin."))
                            return
                        }
                        openDialog.nameFilters = ["Telemetry Logs (*.tlog *.TLOG)"]
                        openDialog.openForLoad()
                    }
                }

                QGCButton {
                    text: qsTr("Təmizlə")
                    enabled: logViewerController.hasLoadedLog
                    onClicked: {
                        clearLoadedLogState(true)
                    }
                }

                QGCLabel {
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    text: logViewerController.hasLoadedLog ? logViewerController.currentLogPath.replace(/.*[/\\]/, "") : qsTr("Log seçilməyib")
                }

                QGCLabel {
                    visible: logViewerController.hasLoadedLog
                    text: qsTr("Başlama vaxtı:")
                }

                QGCLabel {
                    readonly property bool _hasStartTime: logParser.startTime
                                                          && !isNaN(logParser.startTime.getTime())
                                                          && logParser.startTime.getTime() > 0
                    visible: logViewerController.hasLoadedLog
                    text: _hasStartTime
                             ? Qt.formatDateTime(logParser.startTime, Qt.locale().dateTimeFormat(Locale.ShortFormat))
                             : qsTr("N/A")
                }

                QGCLabel {
                    visible: logViewerController.hasLoadedLog && logParser.detectedVehicleType.length > 0
                    text: qsTr("Aparat:")
                }

                QGCLabel {
                    visible: logViewerController.hasLoadedLog && logParser.detectedVehicleType.length > 0
                    text: logParser.detectedVehicleType
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: logParser.parsing
                spacing: ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    text: qsTr("Yüklənir...")
                }

                // A dark rounded track with a green fill
                ProgressBar {
                    id: parseProgressBar
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: logParser.parseProgress

                    background: Rectangle {
                        implicitHeight: AzTheme.px(8)
                        radius:         height / 2
                        color:          AzTheme.slotEmpty
                    }

                    contentItem: Item {
                        implicitHeight: AzTheme.px(8)

                        Rectangle {
                            width:  parseProgressBar.visualPosition * parent.width
                            height: parent.height
                            radius: height / 2
                            color:  AzTheme.statusGreen
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: logViewerController.sourceType === LogViewerController.TLog && replayController.link
                spacing: ScreenTools.defaultFontPixelWidth

                QGCButton {
                    text: replayController.isPlaying ? qsTr("Dayandır") : qsTr("Oynat")
                    onClicked: replayController.isPlaying = !replayController.isPlaying
                }

                QGCComboBox {
                    textRole: "text"
                    currentIndex: 3

                    model: ListModel {
                        ListElement { text: "0.1x";  value: 0.1  }
                        ListElement { text: "0.25x"; value: 0.25 }
                        ListElement { text: "0.5x";  value: 0.5  }
                        ListElement { text: "1x";    value: 1.0  }
                        ListElement { text: "2x";    value: 2.0  }
                        ListElement { text: "5x";    value: 5.0  }
                        ListElement { text: "10x";   value: 10.0 }
                    }

                    onActivated: (index) => replayController.playbackSpeed = model.get(index).value
                }

                QGCLabel { text: replayController.playheadTime }

                QGCSlider {
                    id: _replaySlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100

                    property bool _internalUpdate: false

                    Connections {
                        target: replayController
                        function onPercentCompleteChanged(percentComplete) {
                            _replaySlider._internalUpdate = true
                            _replaySlider.value = percentComplete
                            _replaySlider._internalUpdate = false
                        }
                    }

                    onValueChanged: {
                        if (!_internalUpdate) {
                            replayController.percentComplete = value
                        }
                    }
                }

                QGCLabel { text: replayController.totalTime }
            }

            QGCTabBar {
                id: mainTabBar
                Layout.fillWidth: true

                QGCTabButton { text: qsTr("Qrafik") }
                QGCTabButton { text: qsTr("Xəritə") }
                QGCTabButton { text: qsTr("Parametrlər") }
                QGCTabButton { text: qsTr("Mesajlar") }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: mainTabBar.currentIndex

                // ---- Tab 0: Charting ----
                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    // Left panel: stats + fields list
                    LogViewerFieldsPanel {
                        id: fieldsPanel
                        Layout.fillHeight: true
                        logParser: logParser
                        logViewerController: logViewerController
                        onClearSelectedRequested: logViewerChart.refreshBinChart()
                    }

                    // Right panel: chart + MAVLink inspector
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: AzTheme.px(AzTheme.cardRadius)
                        border.width: 1
                        border.color: AzTheme.cardBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.cardGradientStart }
                            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: AzTheme.px(12)
                            spacing: ScreenTools.defaultFontPixelHeight * 0.5

                            LogViewerChart {
                                id: logViewerChart
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: isFirmwareLog
                                logParser: logParser
                                logViewerController: logViewerController
                                xAxisShowLocalTime: _xAxisShowLocalTime

                                onCursorMoved: (t) => {
                                    _mapTab._markerVisible = true
                                    _mapTab._markerCoord   = logParser.gpsCoordAt(t)
                                    if (_altChart.visible) _altChart.setSharedCursor(t)
                                }
                                onZoomApplied: (minX, maxX) => {
                                    if (_altChart.visible) _altChart.setSharedZoom(minX, maxX)
                                }
                            }

                            Loader {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                active: logViewerController.sourceType === LogViewerController.TLog
                                source: "qrc:/qml/QGroundControl/AnalyzeView/MAVLinkInspector/MAVLinkInspectorPage.qml"
                            }
                        }
                    }
                }

                // ---- Tab 1: Map ----
                Item {
                    id: _mapTab
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // GPS path data
                    readonly property var _gpsPath: logParser.parseComplete ? logParser.gpsPath() : []
                    readonly property int _pathLen: (_gpsPath && _gpsPath.length) ? _gpsPath.length : 0
                    readonly property bool _hasPath: _pathLen >= 2
                    readonly property string _altFieldName: _hasPath ? logParser.gpsAltitudeFieldName() : ""
                    readonly property bool _hasAltField: _altFieldName.length > 0

                    // Shared cursor state (driven by altitude chart, displayed on map)
                    property bool _markerVisible: false
                    property var _markerCoord: ({})

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // ---- Map ----
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            FlightMap {
                                id: _flightMap
                                anchors.fill: parent
                                mapName: "LogViewerMap"
                                allowGCSLocationCenter: true

                                readonly property var _path: _mapTab._gpsPath

                                function _fitPath() {
                                    const p = _mapTab._gpsPath
                                    if (!_mapTab._hasPath) return
                                    var minLat = p[0].latitude, maxLat = minLat
                                    var minLon = p[0].longitude, maxLon = minLon
                                    for (var i = 1; i < p.length; i++) {
                                        var c = p[i]
                                        if (c.latitude  < minLat) minLat = c.latitude
                                        if (c.latitude  > maxLat) maxLat = c.latitude
                                        if (c.longitude < minLon) minLon = c.longitude
                                        if (c.longitude > maxLon) maxLon = c.longitude
                                    }
                                    setVisibleRegion(QtPositioning.rectangle(
                                        QtPositioning.coordinate(maxLat, minLon),
                                        QtPositioning.coordinate(minLat, maxLon)))
                                }

                                Connections {
                                    target: logParser
                                    function onParseCompleteChanged() {
                                        if (logParser.parseComplete) Qt.callLater(_flightMap._fitPath)
                                    }
                                }

                                MapPolyline {
                                    line.width: 3
                                    line.color: AzTheme.statusRed
                                    path: _flightMap._path
                                }

                                // Position dot driven by altitude chart cursor
                                MapQuickItem {
                                    readonly property var _coord: _mapTab._markerCoord
                                    visible: _mapTab._markerVisible && _mapTab._hasPath
                                                  && _coord && _coord.latitude !== undefined
                                    coordinate: (_coord && _coord.latitude !== undefined)
                                                  ? QtPositioning.coordinate(_coord.latitude, _coord.longitude)
                                                  : QtPositioning.coordinate(0, 0)
                                    anchorPoint: Qt.point(_posDot.width / 2, _posDot.height / 2)
                                    sourceItem: Rectangle {
                                        id: _posDot
                                        width: ScreenTools.defaultFontPixelHeight * 1.2
                                        height: width
                                        radius: width / 2
                                        color: AzTheme.statusYellow
                                        border.color: AzTheme.textPrimary
                                        border.width: 2
                                    }
                                }

                                MapScale {
                                    anchors.margins: ScreenTools.defaultFontPixelWidth
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    mapControl: _flightMap
                                }
                            }

                            QGCLabel {
                                anchors.centerIn: parent
                                visible: logParser.parseComplete && !_mapTab._hasPath
                                text: qsTr("Bu logda GPS məlumatı tapılmadı")
                                font.italic: true
                            }

                            QGCLabel {
                                anchors.centerIn: parent
                                visible: !logParser.parseComplete
                                text: qsTr("Uçuş marşrutunu görmək üçün log faylı yükləyin")
                                font.italic: true
                            }
                        }

                        // ---- Altitude chart ----
                        LogViewerAltChart {
                            id: _altChart
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 14
                            visible: _mapTab._hasAltField && _mapTab._hasPath
                            logParser: logParser
                            altFieldName: _mapTab._altFieldName
                            xAxisShowLocalTime: _xAxisShowLocalTime

                            onMarkerChanged: (t) => {
                                _mapTab._markerVisible = true
                                _mapTab._markerCoord   = logParser.gpsCoordAt(t)
                                logViewerChart.setSharedCursor(t)
                            }
                            onMarkerCleared: {
                                _mapTab._markerVisible = false
                            }
                            onZoomApplied: (minX, maxX) => {
                                logViewerChart.setSharedZoom(minX, maxX)
                            }
                        }
                    }
                }

                // ---- Tab 2: Parameters ----
                LogViewerParametersTab {
                    id: _parametersTab
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    logParser: logParser
                }

                // ---- Tab 3: Messages ----
                LogViewerMessagesTab {
                    id: _messagesTab
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    logParser: logParser
                }
            }

            QGCFileDialog {
                id: openDialog
                title: qsTr("Log faylını seçin")
                folder: QGroundControl.settingsManager.appSettings.logSavePath
                selectFolder: false

                onAcceptedForLoad: (file) => {
                    const fileLower = file.toLowerCase()
                    if (fileLower.endsWith(".tlog")) {
                        if (logViewerController.hasLoadedLog) {
                            clearLoadedLogState(true)
                        }
                        const replayLink = QGroundControl.linkManager.startLogReplay(file)
                        if (!replayLink) {
                            mainWindow.showMessageDialog(
                                qsTr("Log Analizi"),
                                qsTr("Seçilmiş .tlog faylı üçün telemetriya təkrar oynatması başladıla bilmədi.")
                            )
                            close()
                            return
                        }
                        replayController.link = replayLink
                        logViewerController.openTLog(file)
                    } else {
                        loadBinFile(file)
                    }
                    close()
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0

Item {
    id: root

    // External API
    property real   availableHeight: height
    property real   availableWidth:  width
    property var    axis
    property string unit
    property string title
    property var    tuningMode
    property double chartDisplaySec:    8
    property bool   showAutoModeChange: false
    property bool   showAutoTuning:     false

    // auto/manual state
    property bool   useAutoTuning:      true

    // Screens in the new design declare azInputStyle: the chart and the cards take its
    // colours, the labels and controls theirs (see QGCLabel._az).
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    // Internals
    property real   _margins:           _az ? AzTheme.px(12) : ScreenTools.defaultFontPixelHeight / 2
    property int    _currentAxis:       0
    property var    _xAxis:             xAxis
    property var    _yAxis:             yAxis
    property int    _msecs:             0
    property double _last_t:            0
    property var    _savedTuningParamValues: [ ]

    readonly property int  _tickSeparation:  5
    readonly property int  _maxTickSections: 10

    // stacked: kiçik en/short ekran -> alt-alta
    readonly property bool _stacked: (availableWidth < 1050) || ScreenTools.isShortScreen

    // right panel width (2 sütunda)
    readonly property real _rightW: Math.min(
                                        Math.max(ScreenTools.defaultFontPixelWidth * 44, availableWidth * 0.34),
                                        ScreenTools.defaultFontPixelWidth * 60
                                    )

    // chart height limit
    readonly property real _minChartH: ScreenTools.defaultFontPixelHeight * (_stacked ? 12 : 18)
    readonly property real _maxChartH: ScreenTools.defaultFontPixelHeight * (_stacked ? 18 : 32)

    // Scroll vəziyyəti — bunu yerləşdirən səhifə (məs. SideMenu_PIDTuning) öz
    // başlığını buna bağlayır ki, aşağı sürüşdürəndə başlıq yuxarı çıxsın.
    readonly property real scrollY:    outerFlick.contentY
    readonly property real scrollMaxY: Math.max(0, outerFlick.contentHeight - outerFlick.height)

    // controller local
    FactPanelController { id: controller }

    function adjustYAxisMin(yAxis, newValue) {
        var newMin = Math.min(yAxis.min, newValue)
        if (newMin % 5 != 0) {
            newMin -= 5
            newMin = Math.floor(newMin / _tickSeparation) * _tickSeparation
        }
        yAxis.min = newMin
    }

    function adjustYAxisMax(yAxis, newValue) {
        var newMax = Math.max(yAxis.max, newValue)
        if (newMax % 5 != 0) {
            newMax += 5
            newMax = Math.floor(newMax / _tickSeparation) * _tickSeparation
        }
        yAxis.max = newMax
    }

    function resetGraphs() {
        for (var i = 0; i < chart.count; ++i) {
            chart.series(i).removePoints(0, chart.series(i).count)
        }
        _xAxis.min = 0
        _xAxis.max = 0
        _yAxis.min = 0
        _yAxis.max = 0
        _msecs = 0
        _last_t = 0
    }

    function saveTuningParamValues() {
        var vals = [ ]
        for (var i=0; i<axis[_currentAxis].params.count; i++) {
            var currentTuneParam = controller.getParameterFact(-1, axis[_currentAxis].params.get(i).param)
            vals.push(currentTuneParam.valueString)
        }
        _savedTuningParamValues = vals
    }

    function resetToSavedTuningParamValues() {
        for (var i=0; i<axis[_currentAxis].params.count; i++) {
            var currentTuneParam = controller.getParameterFact(-1, axis[_currentAxis].params.get(i).param)
            currentTuneParam.value = _savedTuningParamValues[i]
        }
    }

    function axisIndexChanged() {
        chart.removeAllSeries()
        axis[_currentAxis].plot.forEach(function(e) {
            chart.createSeries(ChartView.SeriesTypeLine, e.name, xAxis, yAxis);
        })
        var chartTitle = axis[_currentAxis].plotTitle
        if (chartTitle == null)
            chartTitle = axis[_currentAxis].name
        chart.title = chartTitle + " " + title
        saveTuningParamValues()
        resetGraphs()
    }

    Component.onCompleted: {
        axisIndexChanged()
        globals.activeVehicle.setPIDTuningTelemetryMode(tuningMode)
        saveTuningParamValues()
    }

    Component.onDestruction: globals.activeVehicle.setPIDTuningTelemetryMode(Vehicle.ModeDisabled)

    // property _currentAxis -> handler səndəki kimi
    on_CurrentAxisChanged: axisIndexChanged()

    ValueAxis {
        id:                     xAxis
        min:                    0
        max:                    0
        labelFormat:            "%.1f"
        titleText:              ScreenTools.isShortScreen ? "" : qsTr("sec")
        tickCount:              Math.min(Math.max(Math.floor(chart.width / (ScreenTools.defaultFontPixelWidth * 7)), 4), 11)
        labelsFont.pointSize:   ScreenTools.defaultFontPointSize
        labelsFont.family:      root._az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
        titleFont.pointSize:    ScreenTools.defaultFontPointSize
        titleFont.family:       root._az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
        color:                  root._az ? AzTheme.panelBorder : "#9D9D9D"
        labelsColor:            root._az ? AzTheme.textSecondary : "#CCCCCC"
        gridLineColor:          Qt.rgba(1, 1, 1, 0.12)
        minorGridLineColor:     Qt.rgba(1, 1, 1, 0.06)
    }

    ValueAxis {
        id:                     yAxis
        min:                    0
        max:                    10
        titleText:              unit
        tickCount:              Math.min(((max - min) / _tickSeparation), _maxTickSections) + 1
        labelsFont.pointSize:   ScreenTools.defaultFontPointSize
        labelsFont.family:      root._az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
        titleFont.pointSize:    ScreenTools.defaultFontPointSize
        titleFont.family:       root._az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
        color:                  root._az ? AzTheme.panelBorder : "#9D9D9D"
        labelsColor:            root._az ? AzTheme.textSecondary : "#CCCCCC"
        gridLineColor:          Qt.rgba(1, 1, 1, 0.12)
        minorGridLineColor:     Qt.rgba(1, 1, 1, 0.06)
    }

    Timer {
        id:         dataTimer
        interval:   10
        running:    true
        repeat:     true

        onTriggered: {
            _xAxis.max = _msecs / 1000
            _xAxis.min = _msecs / 1000 - chartDisplaySec

            var firstPoint = _msecs == 0

            var len = axis[_currentAxis].plot.length
            for (var i = 0; i < len; ++i) {
                var value = axis[_currentAxis].plot[i].value
                if (!isNaN(value)) {
                    chart.series(i).append(_msecs/1000, value)
                    if (firstPoint) {
                        _yAxis.min = value
                        _yAxis.max = value
                    } else {
                        adjustYAxisMin(_yAxis, value)
                        adjustYAxisMax(_yAxis, value)
                    }
                    var minSec = _msecs/1000 - 3*60
                    while (chart.series(i).count > 0 && chart.series(i).at(0).x < minSec) {
                        chart.series(i).remove(0)
                    }
                }
            }

            var t = new Date().getTime()
            if (_last_t > 0)
                _msecs += t-_last_t
            _last_t = t
        }
    }

    // stacked olanda bütün kontent scroll olsun (yalnız aşağı-yuxarı)
    QGCFlickable {
        id: outerFlick
        anchors.fill: parent
        clip: true

        flickableDirection: Flickable.VerticalFlick
        interactive: root._stacked

        ScrollBar.vertical: ScrollBar { policy: root._stacked ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        contentWidth:  width
        contentHeight: root._stacked ? Math.max(contentGrid.implicitHeight, height) : height

        // stacked olanda wheel -> scroll
        WheelHandler {
            enabled: root._stacked
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: function(e) {
                e.accepted = true
                var dy = 0
                if (e.pixelDelta && e.pixelDelta.y !== 0) dy = e.pixelDelta.y
                else if (e.angleDelta && e.angleDelta.y !== 0) dy = (e.angleDelta.y / 120) * (ScreenTools.defaultFontPixelHeight * 3)

                var maxY = Math.max(0, outerFlick.contentHeight - outerFlick.height)
                outerFlick.contentY = Math.max(0, Math.min(outerFlick.contentY - dy, maxY))
            }
        }

        GridLayout {
            id: contentGrid
            width: outerFlick.width
            // Two-column mode stretches to the viewport so Layout.fillHeight below has
            // something to fill -- without this the grid collapses to its implicit
            // height and the chart shrinks to its minimum, leaving the column empty.
            height: root._stacked ? implicitHeight : outerFlick.height
            columns: root._stacked ? 1 : 2
            columnSpacing: root._margins
            rowSpacing: root._margins

            // ---------- LEFT PANEL ----------
            ColumnLayout {
                id: leftPanel
                Layout.fillWidth: true
                Layout.fillHeight: !root._stacked
                spacing: ScreenTools.defaultFontPixelHeight / 4

                // stacked-də chart hündürlüyü width-ə görə (çox balaca düşməsin)
                readonly property real chartH: {
                    if (root._stacked) {
                        var h = root.availableWidth * 0.55
                        return Math.max(root._minChartH, Math.min(root._maxChartH, h))
                    } else {
                        var hh = root.availableHeight * 0.70
                        return Math.max(root._minChartH, Math.min(root._maxChartH, hh))
                    }
                }

                ChartView {
                    id:                     chart
                    Layout.fillWidth:       true
                    // In two-column mode take whatever height is left after the bottom
                    // controls: the old _maxChartH cap left most of the column empty.
                    // Stacked mode still uses the width-derived height so the chart does
                    // not push the tuning cards off-screen.
                    Layout.fillHeight:      !root._stacked
                    Layout.preferredHeight: root._stacked ? leftPanel.chartH : -1
                    Layout.minimumHeight:   root._minChartH
                    antialiasing:           true
                    clip:                   true

                    // Match the dark cards the rest of this screen is built from; the
                    // QtCharts default theme is light and stood out badly against them.
                    theme:                  ChartView.ChartThemeDark
                    backgroundColor:        root._az ? AzTheme.cardGradientEnd : "#2A2A2A"
                    plotAreaColor:          root._az ? AzTheme.groupFill : "#232323"
                    backgroundRoundness:    root._az ? AzTheme.px(AzTheme.cardRadius) : ScreenTools.defaultFontPixelHeight / 2
                    titleColor:             root._az ? AzTheme.textCard : "#FFFFFF"

                    legend.alignment:       Qt.AlignBottom
                    legend.backgroundVisible: false
                    legend.labelColor:      root._az ? AzTheme.textSecondary : "#CCCCCC"
                    legend.font.pointSize:  ScreenTools.defaultFontPointSize
                    legend.font.family:     root._az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
                    titleFont.pointSize:    ScreenTools.defaultFontPointSize
                    titleFont.family:       root._az ? AzTheme.fontFamily : ScreenTools.normalFontFamily

                    // wheel/drag yalnız 2 sütunda işləsin (stacked-də wheel scroll üçün boş qalır)
                    MouseArea {
                        enabled: !root._stacked
                        property var _startPoint: undefined
                        property double _scaling: 0
                        anchors.fill: parent

                        onPressed: (mouse) => {
                            _startPoint = Qt.point(mouse.x, mouse.y)
                            var start = chart.mapToValue(_startPoint)
                            var next = chart.mapToValue(Qt.point(mouse.x+1, mouse.y+1))
                            _scaling = next.x - start.x
                        }

                        onWheel: (wheel) => {
                            wheel.accepted = true
                            if (wheel.angleDelta.y > 0) chartDisplaySec /= 1.2
                            else chartDisplaySec *= 1.2
                            _xAxis.min = _xAxis.max - chartDisplaySec
                        }

                        onPositionChanged: (mouse) => {
                            if (_startPoint != undefined) {
                                dataTimer.running = false
                                var cp = Qt.point(mouse.x, mouse.y)
                                var dx = (cp.x - _startPoint.x) * _scaling
                                _startPoint = cp
                                _xAxis.max -= dx
                                _xAxis.min -= dx
                            }
                        }

                        onReleased: _startPoint = undefined
                    }
                }

                // Bottom controls
                ColumnLayout {
                    id: leftBottom
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelHeight / 4

                    GridLayout {
                        Layout.fillWidth: true
                        columns: (leftPanel.width < 520) ? 1 : 2
                        columnSpacing: root._margins
                        rowSpacing: root._margins

                        QGCButton {
                            text: qsTr("Təmizlə")
                            Layout.fillWidth: true
                            onClicked: resetGraphs()
                        }

                        QGCButton {
                            text: dataTimer.running ? qsTr("Dayan") : qsTr("Başla")
                            Layout.fillWidth: true
                            onClicked: {
                                dataTimer.running = !dataTimer.running
                                _last_t = 0
                                if (showAutoModeChange && autoModeChange.checked) {
                                    globals.activeVehicle.flightMode = dataTimer.running
                                            ? globals.activeVehicle.stabilizedFlightMode
                                            : globals.activeVehicle.pauseFlightMode
                                }
                            }
                        }
                    }

                    QGCCheckBox {
                        visible: showAutoModeChange
                        id:     autoModeChange
                        text:   qsTr("Avtomatik Uçuş Rejiminin dəyişdirilməsi")
                        onClicked: if (checked) dataTimer.running = false
                    }

                    ColumnLayout {
                        visible: autoModeChange.checked
                        QGCLabel {
                            text: qsTr("Başlat düyməsini kliklədiyiniz zaman 'Stabilize' vəziyyətinə keçir.")
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                        QGCLabel {
                            text: qsTr("Dayandır düyməsini kliklədikdə '%1'ə keçir.").arg(globals.activeVehicle.pauseFlightMode)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                    }
                }
            }

            // ---------- RIGHT PANEL ----------
            Item {
                id: rightHost
                Layout.fillWidth: true
                Layout.fillHeight: !root._stacked
                Layout.preferredWidth: root._stacked ? contentGrid.width : root._rightW

                // ✅ KRİTİK: stacked-də Item implicitHeight=0 olur -> sağ panel yox olur
                implicitHeight: root._stacked ? rightModeLoader.height : 0

                Loader {
                    id: rightModeLoader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    // stacked: kontentin qədər; non-stacked: bütün hündürlük
                    height: root._stacked ? (item ? item.implicitHeight : 0) : parent.height

                    sourceComponent: root._stacked ? rightContentComponent : rightScrollableComponent
                }

                // === Right panel content (NO scroll) ===
                Component {
                    id: rightContentComponent

                    ColumnLayout {
                        id: rp
                        width: parent.width
                        spacing: root._margins

                        // Without this the auto/manual radios sit flush against the tab
                        // bar and read as clipped, while the chart column starts lower.
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root._margins
                        }

                        Flow {
                            visible: showAutoTuning
                            width: rp.width
                            spacing: root._margins

                            QGCRadioButton {
                                text: qsTr("Use auto-tuning")
                                checked: root.useAutoTuning
                                onClicked: root.useAutoTuning = true
                            }
                            QGCRadioButton {
                                text: qsTr("Use manual tuning")
                                checked: !root.useAutoTuning
                                onClicked: root.useAutoTuning = false
                            }
                        }

                        AutotuneUI {
                            visible: showAutoTuning && root.useAutoTuning
                        }

                        ColumnLayout {
                            visible: !showAutoTuning || !root.useAutoTuning
                            Layout.fillWidth: true
                            spacing: root._margins

                            // Select axis (kiçik ekranda Roll/Pitch/Yaw eyni sətirdə qalsın)
                            ColumnLayout {
                                visible: axis && axis.length > 1
                                Layout.fillWidth: true
                                spacing: 4

                                QGCLabel {
                                    text: qsTr("Select Tuning:")
                                    color: root._az ? AzTheme.textCard : "white"
                                    font.pointSize: root._stacked ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    id: axisRow
                                    Layout.fillWidth: true
                                    spacing: root._margins * (root._stacked ? 0.6 : 1.0)

                                    Repeater {
                                        model: axis
                                        QGCRadioButton {
                                            text: modelData.name
                                            checked: index === root._currentAxis
                                            onClicked: root._currentAxis = index

                                            Layout.fillWidth: root._stacked
                                            Layout.preferredWidth: root._stacked
                                                                  ? (axisRow.width - axisRow.spacing * (axis.length - 1)) / axis.length
                                                                  : implicitWidth

                                            font.pointSize: root._stacked ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                                            spacing: root._stacked ? (ScreenTools.defaultFontPixelWidth * 0.6) : ScreenTools.defaultFontPixelWidth

                                            contentItem: Text {
                                                text: parent.text
                                                font.family: root._az ? AzTheme.fontFamily : parent.font.family
                                                font.pointSize: parent.font.pointSize
                                                color: root._az ? AzTheme.textCard : "white"
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: parent.indicator.width + parent.spacing
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }

                            // Sliders
                            Repeater {
                                model: axis
                                delegate: ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: root._currentAxis === index
                                    spacing: root._margins

                                    Repeater {
                                        model: modelData.params

                                        Rectangle {
                                            Layout.fillWidth: true
                                            color: root._az ? AzTheme.groupFill : "#3C3838"
                                            radius: root._az ? AzTheme.px(AzTheme.groupRadius) : 8
                                            border.color: root._az ? AzTheme.groupBorder : "#9D9D9D"
                                            border.width: 1
                                            Layout.topMargin: root._margins * 0.4

                                            implicitHeight: contentCol.implicitHeight + ScreenTools.defaultFontPixelHeight

                                            ColumnLayout {
                                                id: contentCol
                                                anchors.fill: parent
                                                anchors.margins: ScreenTools.defaultFontPixelHeight / 2
                                                spacing: ScreenTools.defaultFontPixelHeight / 4

                                                QGCLabel {
                                                    text: title
                                                    font.bold: !root._az
                                                    font.weight: root._az ? Font.Medium : Font.Bold
                                                    color: root._az ? AzTheme.textCard : "white"
                                                    Layout.fillWidth: true
                                                }

                                                QGCLabel {
                                                    text: description
                                                    wrapMode: Text.WordWrap
                                                    color: root._az ? AzTheme.textSecondary : "#CCCCCC"
                                                    Layout.fillWidth: true
                                                    font.pointSize: ScreenTools.smallFontPointSize
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: ScreenTools.defaultFontPixelWidth

                                                    QGCSlider {
                                                        id: sliderControl
                                                        Layout.fillWidth: true
                                                        from: min
                                                        to: max
                                                        stepSize: step
                                                        value: controller.getParameterFact(-1, param).value

                                                        onValueChanged: {
                                                            if (pressed) {
                                                                controller.getParameterFact(-1, param).value = value
                                                            }
                                                        }
                                                    }

                                                    QGCTextField {
                                                        Layout.preferredWidth: Math.min(ScreenTools.defaultFontPixelWidth * 12, rp.width * 0.28)
                                                        text: sliderControl.value.toFixed(4)
                                                        validator: DoubleValidator { bottom: min; top: max }
                                                        onEditingFinished: {
                                                            var standardizedText = text.replace(',', '.')
                                                            var newValue = parseFloat(standardizedText)
                                                            if (!isNaN(newValue) && newValue >= min && newValue <= max) {
                                                                controller.getParameterFact(-1, param).value = newValue
                                                                text = newValue.toFixed(4)
                                                            } else {
                                                                text = sliderControl.value.toFixed(4)
                                                            }
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    QGCLabel { text: min.toFixed(3); color: root._az ? AzTheme.mutedText : "#AAAAAA"; font.pointSize: ScreenTools.smallFontPointSize }
                                                    Item { Layout.fillWidth: true }
                                                    QGCLabel { text: max.toFixed(3); color: root._az ? AzTheme.mutedText : "#AAAAAA"; font.pointSize: ScreenTools.smallFontPointSize }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Clipboard
                            Rectangle {
                                Layout.fillWidth: true
                                color: root._az ? AzTheme.groupFill : "#2A2A2A"
                                border.color: root._az ? AzTheme.groupBorder : "#9D9D9D"
                                border.width: 1
                                radius: root._az ? AzTheme.px(AzTheme.groupRadius) : 4
                                clip: true

                                implicitHeight: Math.min(Math.max(clipboardCol.implicitHeight + root._margins * 2, 140), 360)

                                ColumnLayout {
                                    id: clipboardCol
                                    anchors.fill: parent
                                    anchors.margins: root._margins
                                    spacing: 6

                                    QGCLabel {
                                        text: qsTr("Clipboard Values:")
                                        color: root._az ? AzTheme.textCard : "white"
                                        Layout.fillWidth: true
                                    }

                                    Repeater {
                                        model: (axis && axis.length > 0) ? axis[root._currentAxis].params : 0

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: root._margins

                                            QGCLabel {
                                                text: param
                                                color: root._az ? AzTheme.textCard : "white"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                color: root._az ? AzTheme.pillBottom : "#1E1E1E"
                                                radius: root._az ? AzTheme.px(6) : 3
                                                Layout.preferredWidth: Math.min(ScreenTools.defaultFontPixelWidth * 14, rightHost.width * 0.35)
                                                implicitHeight: valueLbl.implicitHeight + 6

                                                QGCLabel {
                                                    id: valueLbl
                                                    anchors.centerIn: parent
                                                    text: (root._savedTuningParamValues && root._savedTuningParamValues.length > index)
                                                          ? root._savedTuningParamValues[index]
                                                          : ""
                                                    color: root._az ? AzTheme.textCard : "white"
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Save/Restore
                            GridLayout {
                                Layout.fillWidth: true
                                columns: (rp.width < 520) ? 1 : 2
                                columnSpacing: root._margins
                                rowSpacing: root._margins

                                QGCButton {
                                    text: qsTr("Save To Clipboard")
                                    Layout.fillWidth: true
                                    onClicked: saveTuningParamValues()
                                }

                                QGCButton {
                                    text: qsTr("Restore From Clipboard")
                                    Layout.fillWidth: true
                                    onClicked: resetToSavedTuningParamValues()
                                }
                            }
                        }
                    }
                }

                // === Right panel content (scrollable) — yalnız 2 sütunda ===
                Component {
                    id: rightScrollableComponent

                    QGCFlickable {
                        id: rightFlick
                        anchors.fill: parent
                        clip: true

                        flickableDirection: Flickable.VerticalFlick
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                        contentWidth:  width
                        contentHeight: rightLoader.item ? rightLoader.item.implicitHeight : 0

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: function(e) {
                                e.accepted = true
                                var dy = 0
                                if (e.pixelDelta && e.pixelDelta.y !== 0) dy = e.pixelDelta.y
                                else if (e.angleDelta && e.angleDelta.y !== 0) dy = (e.angleDelta.y / 120) * (ScreenTools.defaultFontPixelHeight * 3)

                                var maxY = Math.max(0, rightFlick.contentHeight - rightFlick.height)
                                rightFlick.contentY = Math.max(0, Math.min(rightFlick.contentY - dy, maxY))
                            }
                        }

                        Loader {
                            id: rightLoader
                            width: rightFlick.width
                            sourceComponent: rightContentComponent
                        }
                    }
                }
            }
        }
    }
}

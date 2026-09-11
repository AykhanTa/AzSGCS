// // import QtQuick
// // import QtQuick.Controls
// // import QtCharts
// // import QtQuick.Layouts

// // import QGroundControl
// // import QGroundControl.Controls

// // import QGroundControl.FactControls

// // RowLayout {
// //     spacing: _margins

// //     property real   availableHeight
// //     property real   availableWidth
// //     property var    axis
// //     property string unit
// //     property string title
// //     property var    tuningMode
// //     property double chartDisplaySec:    8 // number of seconds to display
// //     property bool   showAutoModeChange: false
// //     property bool   showAutoTuning:     false

// //     property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
// //     property int    _currentAxis:       0
// //     property var    _xAxis:             xAxis
// //     property var    _yAxis:             yAxis
// //     property int    _msecs:             0
// //     property double _last_t:            0
// //     property var    _savedTuningParamValues:    [ ]

// //     readonly property int _tickSeparation:      5
// //     readonly property int _maxTickSections:     10

// //     function adjustYAxisMin(yAxis, newValue) {
// //         var newMin = Math.min(yAxis.min, newValue)
// //         if (newMin % 5 != 0) {
// //             newMin -= 5
// //             newMin = Math.floor(newMin / _tickSeparation) * _tickSeparation
// //         }
// //         yAxis.min = newMin
// //     }

// //     function adjustYAxisMax(yAxis, newValue) {
// //         var newMax = Math.max(yAxis.max, newValue)
// //         if (newMax % 5 != 0) {
// //             newMax += 5
// //             newMax = Math.floor(newMax / _tickSeparation) * _tickSeparation
// //         }
// //         yAxis.max = newMax
// //     }

// //     function resetGraphs() {
// //         for (var i = 0; i < chart.count; ++i) {
// //             chart.series(i).removePoints(0, chart.series(i).count)
// //         }
// //         _xAxis.min = 0
// //         _xAxis.max = 0
// //         _yAxis.min = 0
// //         _yAxis.max = 0
// //         _msecs = 0
// //         _last_t = 0
// //     }

// //     // Save the current set of tuning values so we can reset to them
// //     function saveTuningParamValues() {
// //         _savedTuningParamValues = [ ]
// //         for (var i=0; i<axis[_currentAxis].params.count; i++) {
// //             var currentTuneParam = controller.getParameterFact(-1, axis[_currentAxis].params.get(i).param)
// //             _savedTuningParamValues.push(currentTuneParam.valueString)
// //         }
// //         savedRepeater.model = _savedTuningParamValues
// //     }

// //     function resetToSavedTuningParamValues() {
// //         for (var i=0; i<axis[_currentAxis].params.count; i++) {
// //             var currentTuneParam = controller.getParameterFact(-1,
// //                                                                axis[_currentAxis].params.get(i).param)
// //             currentTuneParam.value = _savedTuningParamValues[i]
// //         }
// //     }

// //     function axisIndexChanged() {
// //         chart.removeAllSeries()
// //         axis[_currentAxis].plot.forEach(function(e) {
// //             chart.createSeries(ChartView.SeriesTypeLine, e.name, xAxis, yAxis);
// //         })
// //         var chartTitle = axis[_currentAxis].plotTitle
// //         if (chartTitle == null)
// //             chartTitle = axis[_currentAxis].name
// //         chart.title = chartTitle + " " + title
// //         saveTuningParamValues()
// //         resetGraphs()
// //     }

// //     Component.onCompleted: {
// //         axisIndexChanged()
// //         globals.activeVehicle.setPIDTuningTelemetryMode(tuningMode)
// //         saveTuningParamValues()
// //     }

// //     Component.onDestruction: globals.activeVehicle.setPIDTuningTelemetryMode(Vehicle.ModeDisabled)
// //     on_CurrentAxisChanged: axisIndexChanged()

// //     ValueAxis {
// //         id:                     xAxis
// //         min:                    0
// //         max:                    0
// //         labelFormat:            "%.1f"
// //         titleText:              ScreenTools.isShortScreen ? "" : qsTr("sec") // Save space on small screens
// //         tickCount:              Math.min(Math.max(Math.floor(chart.width / (ScreenTools.defaultFontPixelWidth * 7)), 4), 11)
// //         labelsFont.pointSize:   ScreenTools.defaultFontPointSize
// //         labelsFont.family:      ScreenTools.normalFontFamily
// //         titleFont.pointSize:    ScreenTools.defaultFontPointSize
// //         titleFont.family:       ScreenTools.normalFontFamily
// //     }

// //     ValueAxis {
// //         id:                     yAxis
// //         min:                    0
// //         max:                    10
// //         titleText:              unit
// //         tickCount:              Math.min(((max - min) / _tickSeparation), _maxTickSections) + 1
// //         labelsFont.pointSize:   ScreenTools.defaultFontPointSize
// //         labelsFont.family:      ScreenTools.normalFontFamily
// //         titleFont.pointSize:    ScreenTools.defaultFontPointSize
// //         titleFont.family:       ScreenTools.normalFontFamily
// //     }

// //     Timer {
// //         id:         dataTimer
// //         interval:   10
// //         running:    true
// //         repeat:     true

// //         onTriggered: {
// //             _xAxis.max = _msecs / 1000
// //             _xAxis.min = _msecs / 1000 - chartDisplaySec

// //             var firstPoint = _msecs == 0

// //             var len = axis[_currentAxis].plot.length
// //             for (var i = 0; i < len; ++i) {
// //                 var value = axis[_currentAxis].plot[i].value
// //                 if (!isNaN(value)) {
// //                     chart.series(i).append(_msecs/1000, value)
// //                     if (firstPoint) {
// //                         _yAxis.min = value
// //                         _yAxis.max = value
// //                     } else {
// //                         adjustYAxisMin(_yAxis, value)
// //                         adjustYAxisMax(_yAxis, value)
// //                     }
// //                     // limit history
// //                     var minSec = _msecs/1000 - 3*60
// //                     while (chart.series(i).count > 0 && chart.series(i).at(0).x < minSec) {
// //                         chart.series(i).remove(0)
// //                     }
// //                 }
// //             }

// //             var t = new Date().getTime() // in ms
// //             if (_last_t > 0)
// //                 _msecs += t-_last_t
// //             _last_t = t
// //         }

// //         property int _maxPointCount:    10000 / interval
// //     }

// //     Column {
// //         id:                 leftPanel
// //         Layout.alignment:   Qt.AlignTop
// //         // Layout.topMargin:   -150  // BURAYA EKLE - 100px YUKARI KALDIR
// //         spacing:            ScreenTools.defaultFontPixelHeight / 4
// //         clip:               true // chart has redraw problems

// //         ChartView {
// //             id:                     chart
// //             // width:                   1000  // SABİT GENİŞLİK
// //             // height:                  700  // SABİT YÜKSEKLİK
// //             width:                  Math.max(_minChartWidth, availableWidth - rightPanel.width - parent.spacing - _margins)
// //                         height:                 Math.max(_minChartHeight, availableHeight - leftPanelBottomColumn.height - parent.spacing - _margins)
// //             antialiasing:           true
// //             legend.alignment:       Qt.AlignBottom
// //             legend.font.pointSize:  ScreenTools.defaultFontPointSize
// //             legend.font.family:     ScreenTools.normalFontFamily
// //             titleFont.pointSize:    ScreenTools.defaultFontPointSize
// //             titleFont.family:       ScreenTools.normalFontFamily


// //             property real _chartMargin: 0
// //             property real _minChartWidth:   ScreenTools.defaultFontPixelWidth * 40
// //             property real _minChartHeight:  ScreenTools.defaultFontPixelHeight * 15

// //             // enable mouse dragging
// //             MouseArea {
// //                 property var _startPoint: undefined
// //                 property double _scaling: 0
// //                 anchors.fill: parent
// //                 onPressed: (mouse) => {
// //                                _startPoint = Qt.point(mouse.x, mouse.y)
// //                                var start = chart.mapToValue(_startPoint)
// //                                var next = chart.mapToValue(Qt.point(mouse.x+1, mouse.y+1))
// //                                _scaling = next.x - start.x
// //                            }
// //                 onWheel: (wheel) => {
// //                              if (wheel.angleDelta.y > 0)
// //                              chartDisplaySec /= 1.2
// //                              else
// //                              chartDisplaySec *= 1.2
// //                              _xAxis.min = _xAxis.max - chartDisplaySec
// //                          }
// //                 onPositionChanged: (mouse) => {
// //                                        if(_startPoint != undefined) {
// //                                            dataTimer.running = false
// //                                            var cp = Qt.point(mouse.x, mouse.y)
// //                                            var dx = (cp.x - _startPoint.x) * _scaling
// //                                            _startPoint = cp
// //                                            _xAxis.max -= dx
// //                                            _xAxis.min -= dx
// //                                        }
// //                                    }

// //                 onReleased: {
// //                     _startPoint = undefined
// //                 }
// //             }
// //         }

// //         Column {
// //             id:         leftPanelBottomColumn
// //             spacing:    ScreenTools.defaultFontPixelHeight / 4

// //             RowLayout {
// //                 spacing: _margins

// //                 // Boş bir item ekleyerek butonları sağa itiyoruz
// //                 Item {
// //                     Layout.fillWidth: true
// //                 }

// //                 // Clear Butonu
// //                 Rectangle {
// //                     width: ScreenTools.defaultFontPixelWidth * 20
// //                     height: ScreenTools.defaultFontPixelHeight * 2.5
// //                     color: "#2A2A2A"
// //                     border.color: "#9D9D9D"
// //                     border.width: 1
// //                     radius: 4

// //                     QGCButton {
// //                         anchors.fill: parent
// //                         anchors.margins: 1
// //                         text: qsTr("Təmizlə")
// //                         primary: false
// //                         backgroundColor: "transparent"

// //                         contentItem: Text {
// //                             text: parent.text
// //                             color: "white"
// //                             font.pointSize: 14
// //                             horizontalAlignment: Text.AlignHCenter
// //                             verticalAlignment: Text.AlignVCenter
// //                         }

// //                         onClicked: resetGraphs()
// //                     }
// //                 }

// //                 // Start/Stop Butonu
// //                 Rectangle {
// //                     width: ScreenTools.defaultFontPixelWidth * 20
// //                     height: ScreenTools.defaultFontPixelHeight * 2.5
// //                     color: "#2A2A2A"
// //                     border.color: "#9D9D9D"
// //                     border.width: 1
// //                     radius: 4

// //                     QGCButton {
// //                         anchors.fill: parent
// //                         anchors.margins: 1
// //                         text: dataTimer.running ? qsTr("Dayan") : qsTr("Başla")
// //                         primary: false
// //                         backgroundColor: "transparent"

// //                         contentItem: Text {
// //                             text: parent.text
// //                             color: "white"
// //                             font.pointSize: 14
// //                             horizontalAlignment: Text.AlignHCenter
// //                             verticalAlignment: Text.AlignVCenter
// //                         }

// //                         onClicked: {
// //                             dataTimer.running = !dataTimer.running
// //                             _last_t = 0
// //                             if (showAutoModeChange && autoModeChange.checked) {
// //                                 globals.activeVehicle.flightMode = dataTimer.running ? globals.activeVehicle.stabilizedFlightMode : globals.activeVehicle.pauseFlightMode
// //                             }
// //                         }
// //                     }
// //                 }
// //             }

// //             QGCCheckBox {
// //                 visible: showAutoModeChange
// //                 id:     autoModeChange
// //                 text:   qsTr("Avtomatik Uçuş Rejiminin dəyişdirilməsi")
// //                 onClicked: {
// //                     if (checked)
// //                         dataTimer.running = false
// //                 }
// //             }

// //             Column {
// //                 visible: autoModeChange.checked
// //                 QGCLabel {
// //                     text:            qsTr("Başlat düyməsini kliklədiyiniz zaman 'Stabilize' vəziyyətinə keçir.")
// //                     font.pointSize:     ScreenTools.smallFontPointSize
// //                 }

// //                 QGCLabel {
// //                     text:            qsTr("Dayandır düyməsini kliklədikdə '%1'ə keçir.").arg(globals.activeVehicle.pauseFlightMode)
// //                     font.pointSize:     ScreenTools.smallFontPointSize
// //                 }
// //             }
// //         }
// //     }

// //     ColumnLayout {
// //         id:                 rightPanel
// //         Layout.alignment:   Qt.AlignTop



// //         RowLayout {
// //             visible: showAutoTuning

// //             QGCRadioButton {
// //                 id:         useAutoTuningRadio
// //                 text:       qsTr("Use auto-tuning")
// //                 checked:    useAutoTuning
// //                 onClicked:  useAutoTuning = true
// //             }
// //             QGCRadioButton {
// //                 id:         useManualTuningRadio
// //                 text:       qsTr("Use manual tuning")
// //                 checked:    !useAutoTuning
// //                 onClicked:  useAutoTuning = false
// //             }
// //         }

// //         AutotuneUI {
// //             visible: showAutoTuning && useAutoTuningRadio.checked
// //         }

// //         ColumnLayout {
// //             visible: !showAutoTuning || useManualTuningRadio.checked




// //             Column {
// //                 RowLayout {
// //                     spacing: _margins
// //                     visible: axis.length > 1

// //                     QGCLabel {
// //                         text: qsTr("Select Tuning:")
// //                         color: "white"
// //                     }

// //                     Repeater {
// //                         model: axis
// //                         QGCRadioButton {
// //                             text: modelData.name
// //                             checked: index == _currentAxis
// //                             onClicked: _currentAxis = index

// //                             // Radio button text rengi beyaz
// //                             contentItem: Text {
// //                                 text: parent.text
// //                                 font: parent.font
// //                                 color: "white"
// //                                 verticalAlignment: Text.AlignVCenter
// //                                 leftPadding: parent.indicator.width + parent.spacing
// //                             }
// //                         }
// //                     }
// //                 }
// //             }

// //             // Instantiate all sliders (instead of switching the model), so that
// //             // values are not changed unexpectedly if they do not match with a tick value.
// //             Repeater {
// //                 model: axis
// //                 delegate: Column {
// //                     property int axisIndex: index

// //                     Repeater {
// //                         model: modelData.params

// //                         // ANA ITEM - Layout properties burada çalışacak
// //                         Item {
// //                             width: ScreenTools.defaultFontPixelWidth * 45
// //                             height: ScreenTools.defaultFontPixelHeight * 7.5
// //                             Layout.preferredWidth: width
// //                             Layout.preferredHeight: height
// //                             Layout.topMargin: ScreenTools.defaultFontPixelHeight * 0.5  // SLIDER'LAR ARASI BOŞLUK
// //                             Layout.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.5  // SLIDER'LAR ARASI BOŞLUK
// //                             visible: _currentAxis === axisIndex

// //                             // SLIDER CONTAINER - Arka plan rengi ve boyutları ayarlandı
// //                             Rectangle {
// //                                 id: sliderContainer
// //                                 width: parent.width
// //                                 height: ScreenTools.defaultFontPixelHeight * 6.5
// //                                 color: "#3C3838"
// //                                 radius: 8
// //                                 border.color: "#9D9D9D"
// //                                 border.width: 1
// //                                 anchors.centerIn: parent

// //                                 ColumnLayout {
// //                                     anchors.fill: parent
// //                                     anchors.margins: ScreenTools.defaultFontPixelHeight / 2
// //                                     spacing: ScreenTools.defaultFontPixelHeight / 4

// //                                     // BAŞLIK - BEYAZ RENK
// //                                     QGCLabel {
// //                                         text: title
// //                                         font.bold: true
// //                                         Layout.fillWidth: true
// //                                         color: "white"
// //                                         font.pointSize: ScreenTools.defaultFontPointSize
// //                                     }

// //                                     // AÇIKLAMA - AÇIK GRI RENK
// //                                     QGCLabel {
// //                                         text: description
// //                                         wrapMode: Text.WordWrap
// //                                         Layout.fillWidth: true
// //                                         font.pointSize: ScreenTools.smallFontPointSize
// //                                         color: "#CCCCCC"
// //                                         Layout.maximumHeight: ScreenTools.defaultFontPixelHeight * 2.5
// //                                     }

// //                                     // SLIDER ve INPUT ALANI
// //                                     RowLayout {
// //                                         spacing: ScreenTools.defaultFontPixelWidth
// //                                         Layout.fillWidth: true
// //                                         Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.8

// //                                         // QGC SLIDER - Özelleştirilmiş boyutlar
// //                                         QGCSlider {
// //                                             id: sliderControl
// //                                             Layout.fillWidth: true
// //                                             Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.2
// //                                             from: min
// //                                             to: max
// //                                             stepSize: step
// //                                             value: controller.getParameterFact(-1, param).value

// //                                             onValueChanged: {
// //                                                 if (sliderControl.pressed) {
// //                                                     controller.getParameterFact(-1, param).value = value
// //                                                 }
// //                                             }

// //                                             // Slider'ın yanında değer göstergesi
// //                                             ToolTip.visible: pressed
// //                                             ToolTip.text: value.toFixed(4)

// //                                             // Slider stil özelleştirmeleri
// //                                             background: Rectangle {
// //                                                 x: sliderControl.leftPadding
// //                                                 y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
// //                                                 implicitWidth: 200
// //                                                 implicitHeight: 4
// //                                                 width: sliderControl.availableWidth
// //                                                 height: implicitHeight
// //                                                 radius: 2
// //                                                 color: "#707070"

// //                                                 Rectangle {
// //                                                     width: sliderControl.visualPosition * parent.width
// //                                                     height: parent.height
// //                                                     color: "#E2EEF9"
// //                                                     radius: 2
// //                                                 }
// //                                             }

// //                                             handle: Rectangle {
// //                                                 x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width)
// //                                                 y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
// //                                                 implicitWidth: 18
// //                                                 implicitHeight: 18
// //                                                 radius: 9
// //                                                 color: sliderControl.pressed ? "#FFFFFF" : "#F0F0F0"
// //                                                 border.color: "#E2EEF9"
// //                                                 border.width: 2
// //                                             }
// //                                         }

// //                                         // INPUT ALANI
// //                                         QGCTextField {
// //                                             text: sliderControl.value.toFixed(4)
// //                                             Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 12
// //                                             Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
// //                                             validator: DoubleValidator {
// //                                                 bottom: min
// //                                                 top: max
// //                                             }
// //                                             onEditingFinished: {
// //                                                 // Ondalık ayırıcıyı standartlaştır
// //                                                 var standardizedText = text.replace(',', '.')
// //                                                 var newValue = parseFloat(standardizedText)

// //                                                 console.log("Original text:", text, "Standardized:", standardizedText, "Parsed value:", newValue)

// //                                                 if (!isNaN(newValue) && newValue >= min && newValue <= max) {
// //                                                     controller.getParameterFact(-1, param).value = newValue
// //                                                     // Değeri güncelledikten sonra text alanını da güncelle
// //                                                     text = newValue.toFixed(4)
// //                                                 } else {
// //                                                     // Geçersiz değer durumunda eski değere geri dön
// //                                                     text = sliderControl.value.toFixed(4)
// //                                                 }
// //                                             }

// //                                             // Input alanı stil özelleştirmeleri
// //                                             color: "white"
// //                                             background: Rectangle {
// //                                                 color: "#2A2A2A"
// //                                                 border.color: "#9D9D9D"
// //                                                 border.width: 1
// //                                                 radius: 4
// //                                             }
// //                                         }
// //                                     }

// //                                     // MIN/MAX DEĞERLERİ - GRI RENK
// //                                     RowLayout {
// //                                         Layout.fillWidth: true
// //                                         Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 0.8

// //                                         QGCLabel {
// //                                             text: min.toFixed(3)
// //                                             font.pointSize: ScreenTools.smallFontPointSize
// //                                             color: "#AAAAAA"
// //                                         }
// //                                         Item { Layout.fillWidth: true }
// //                                         QGCLabel {
// //                                             text: max.toFixed(3)
// //                                             font.pointSize: ScreenTools.smallFontPointSize
// //                                             color: "#AAAAAA"
// //                                         }
// //                                     }
// //                                 }
// //                             }
// //                         }
// //                     }
// //                 }
// //             }


// //             Rectangle {
// //                 color: "#2A2A2A"
// //                 border.color: "#9D9D9D"
// //                 border.width: 1
// //                 radius: 4

// //                 width: Math.max(childrenRect.width + _margins * 2, 360)
// //                 height: Math.min(Math.max(childrenRect.height + _margins * 2, 100), 400)
// //                 clip: true

// //                 Column {
// //                     anchors.fill: parent
// //                     anchors.margins: _margins
// //                     spacing: 0

// //                     QGCLabel {
// //                         id: titleLabel
// //                         text: qsTr("Clipboard Values:")
// //                         color: "white"
// //                         anchors.horizontalCenter: parent.horizontalCenter
// //                         width: parent.width
// //                         elide: Text.ElideRight
// //                         font.pointSize: 8  // DAHA KÜÇÜK FONT
// //                         height: implicitHeight * 0.8  // DAHA KÜÇÜK YÜKSEKLİK
// //                         topPadding: 0
// //                         bottomPadding: 0
// //                     }

// //                     GridLayout {
// //                         rows: savedRepeater.model.length
// //                         flow: GridLayout.TopToBottom
// //                         rowSpacing: 0  // SATIR ARASI BOŞLUK SIFIR
// //                         columnSpacing: _margins
// //                         width: parent.width
// //                         height: Math.min(implicitHeight, parent.height - titleLabel.height)

// //                         // Parametre isimleri (sol sütun)
// //                         Repeater {
// //                             model: axis[_currentAxis].params

// //                             QGCLabel {
// //                                 text: param
// //                                 color: "white"
// //                                 width: parent.width * 0.6
// //                                 elide: Text.ElideRight
// //                                 font.pointSize: 8  // DAHA KÜÇÜK FONT
// //                                 topPadding: 0
// //                                 bottomPadding: 0
// //                                 leftPadding: 2
// //                                 rightPadding: 2
// //                                 height: implicitHeight * 0.8  // DAHA KÜÇÜK YÜKSEKLİK
// //                             }
// //                         }

// //                         // Değerler (sağ sütun) - yeşil backgroundlu
// //                         Repeater {
// //                             id: savedRepeater

// //                             Rectangle {
// //                                 color: "#1E1E1E"
// //                                 radius: 3
// //                                 Layout.preferredWidth: Math.min(dataLabel.implicitWidth + 6, parent.width * 0.4)
// //                                 Layout.preferredHeight: Math.min(dataLabel.implicitHeight * 0.8 + 2, 20)  // DAHA KÜÇÜK
// //                                 Layout.topMargin: 0
// //                                 Layout.bottomMargin: 0

// //                                 QGCLabel {
// //                                     id: dataLabel
// //                                     anchors.centerIn: parent
// //                                     text: modelData
// //                                     color: "#FFFFFF"
// //                                     width: parent.width - 4
// //                                     elide: Text.ElideRight
// //                                     horizontalAlignment: Text.AlignHCenter
// //                                     font.pointSize: 8  // DAHA KÜÇÜK FONT
// //                                     topPadding: 0
// //                                     bottomPadding: 0
// //                                 }
// //                             }
// //                         }
// //                     }
// //                 }
// //             }

// //             RowLayout {
// //                 spacing: _margins

// //                 // Save To Clipboard Butonu
// //                 Rectangle {
// //                     width: ScreenTools.defaultFontPixelWidth * 30
// //                     height: ScreenTools.defaultFontPixelHeight * 2.2
// //                     color: "#2A2A2A"
// //                     border.color: "#9D9D9D"
// //                     border.width: 1
// //                     radius: 4

// //                     QGCButton {
// //                         anchors.fill: parent
// //                         anchors.margins: 1
// //                         text: qsTr("Save To Clipboard")
// //                         primary: false
// //                         backgroundColor: "transparent"

// //                         contentItem: Text {
// //                             text: parent.text
// //                             color: "white"
// //                             font.pointSize: 13
// //                             horizontalAlignment: Text.AlignHCenter
// //                             verticalAlignment: Text.AlignVCenter
// //                         }

// //                         onClicked: saveTuningParamValues()
// //                     }
// //                 }

// //                 // Restore From Clipboard Butonu
// //                 Rectangle {
// //                     width: ScreenTools.defaultFontPixelWidth * 30
// //                     height: ScreenTools.defaultFontPixelHeight * 2.2
// //                     color: "#2A2A2A"
// //                     border.color: "#9D9D9D"
// //                     border.width: 1
// //                     radius: 4

// //                     QGCButton {
// //                         anchors.fill: parent
// //                         anchors.margins: 1
// //                         text: qsTr("Restore From Clipboard")
// //                         primary: false
// //                         backgroundColor: "transparent"

// //                         contentItem: Text {
// //                             text: parent.text
// //                             color: "white"
// //                             font.pointSize: 13
// //                             horizontalAlignment: Text.AlignHCenter
// //                             verticalAlignment: Text.AlignVCenter
// //                         }

// //                         onClicked: resetToSavedTuningParamValues()
// //                     }
// //                 }
// //             }
// //         }
// //     }

// // } // RowLayout

// import QtQuick 2.15
// import QtQuick.Controls 2.15
// import QtQuick.Layouts 1.15
// import QtCharts 2.15

// import QGroundControl 1.0
// import QGroundControl.Controls 1.0
// import QGroundControl.FactControls 1.0

// Item {
//     id: root

//     // External API (səndəki kimi saxlanıldı)
//     property real   availableHeight: height
//     property real   availableWidth:  width
//     property var    axis
//     property string unit
//     property string title
//     property var    tuningMode
//     property double chartDisplaySec:    8
//     property bool   showAutoModeChange: false
//     property bool   showAutoTuning:     false

//     // ✅ əlavə: auto/manual state
//     property bool   useAutoTuning:      true

//     // Internals
//     property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
//     property int    _currentAxis:       0
//     property var    _xAxis:             xAxis
//     property var    _yAxis:             yAxis
//     property int    _msecs:             0
//     property double _last_t:            0
//     property var    _savedTuningParamValues: [ ]

//     readonly property int  _tickSeparation:  5
//     readonly property int  _maxTickSections: 10

//     // ✅ breakpoint: kiçik en -> stacked (alt‑alta)
//     readonly property bool _stacked: (availableWidth < 1050) || ScreenTools.isShortScreen

//     // ✅ sağ panel eni (2 sütunda)
//     readonly property real _rightW: Math.min(
//                                         Math.max(ScreenTools.defaultFontPixelWidth * 44, availableWidth * 0.34),
//                                         ScreenTools.defaultFontPixelWidth * 60
//                                     )

//     // ✅ chart height limitləri (böyük ekranda “şişməsin”)
//     readonly property real _minChartH: ScreenTools.defaultFontPixelHeight * (_stacked ? 12 : 18)
//     readonly property real _maxChartH: ScreenTools.defaultFontPixelHeight * (_stacked ? 18 : 32)

//     // controller bu faylın içində olsun (başqa fayldakı id-ə güvənməsin)
//     FactPanelController { id: controller }

//     function adjustYAxisMin(yAxis, newValue) {
//         var newMin = Math.min(yAxis.min, newValue)
//         if (newMin % 5 != 0) {
//             newMin -= 5
//             newMin = Math.floor(newMin / _tickSeparation) * _tickSeparation
//         }
//         yAxis.min = newMin
//     }

//     function adjustYAxisMax(yAxis, newValue) {
//         var newMax = Math.max(yAxis.max, newValue)
//         if (newMax % 5 != 0) {
//             newMax += 5
//             newMax = Math.floor(newMax / _tickSeparation) * _tickSeparation
//         }
//         yAxis.max = newMax
//     }

//     function resetGraphs() {
//         for (var i = 0; i < chart.count; ++i) {
//             chart.series(i).removePoints(0, chart.series(i).count)
//         }
//         _xAxis.min = 0
//         _xAxis.max = 0
//         _yAxis.min = 0
//         _yAxis.max = 0
//         _msecs = 0
//         _last_t = 0
//     }

//     // function saveTuningParamValues() {
//     //     _savedTuningParamValues = [ ]
//     //     for (var i=0; i<axis[_currentAxis].params.count; i++) {
//     //         var currentTuneParam = controller.getParameterFact(-1, axis[_currentAxis].params.get(i).param)
//     //         _savedTuningParamValues.push(currentTuneParam.valueString)
//     //     }
//     //     savedRepeater.model = _savedTuningParamValues
//     // }

//     function saveTuningParamValues() {
//         var vals = [ ]
//         for (var i=0; i<axis[_currentAxis].params.count; i++) {
//             var currentTuneParam = controller.getParameterFact(-1, axis[_currentAxis].params.get(i).param)
//             vals.push(currentTuneParam.valueString)
//         }
//         _savedTuningParamValues = vals
//     }



//     function resetToSavedTuningParamValues() {
//         for (var i=0; i<axis[_currentAxis].params.count; i++) {
//             var currentTuneParam = controller.getParameterFact(-1, axis[_currentAxis].params.get(i).param)
//             currentTuneParam.value = _savedTuningParamValues[i]
//         }
//     }

//     function axisIndexChanged() {
//         chart.removeAllSeries()
//         axis[_currentAxis].plot.forEach(function(e) {
//             chart.createSeries(ChartView.SeriesTypeLine, e.name, xAxis, yAxis);
//         })
//         var chartTitle = axis[_currentAxis].plotTitle
//         if (chartTitle == null)
//             chartTitle = axis[_currentAxis].name
//         chart.title = chartTitle + " " + title
//         saveTuningParamValues()
//         resetGraphs()
//     }

//     Component.onCompleted: {
//         axisIndexChanged()
//         globals.activeVehicle.setPIDTuningTelemetryMode(tuningMode)
//         saveTuningParamValues()
//     }

//     Component.onDestruction: globals.activeVehicle.setPIDTuningTelemetryMode(Vehicle.ModeDisabled)

//     // ✅ səndə səhv idi: on_CurrentAxisChanged yox, on_currentAxisChanged olmalıdır
//     //on_currentAxisChanged: axisIndexChanged()
//     on_CurrentAxisChanged: axisIndexChanged()

//     ValueAxis {
//         id:                     xAxis
//         min:                    0
//         max:                    0
//         labelFormat:            "%.1f"
//         titleText:              ScreenTools.isShortScreen ? "" : qsTr("sec")
//         tickCount:              Math.min(Math.max(Math.floor(chart.width / (ScreenTools.defaultFontPixelWidth * 7)), 4), 11)
//         labelsFont.pointSize:   ScreenTools.defaultFontPointSize
//         labelsFont.family:      ScreenTools.normalFontFamily
//         titleFont.pointSize:    ScreenTools.defaultFontPointSize
//         titleFont.family:       ScreenTools.normalFontFamily
//     }

//     ValueAxis {
//         id:                     yAxis
//         min:                    0
//         max:                    10
//         titleText:              unit
//         tickCount:              Math.min(((max - min) / _tickSeparation), _maxTickSections) + 1
//         labelsFont.pointSize:   ScreenTools.defaultFontPointSize
//         labelsFont.family:      ScreenTools.normalFontFamily
//         titleFont.pointSize:    ScreenTools.defaultFontPointSize
//         titleFont.family:       ScreenTools.normalFontFamily
//     }

//     Timer {
//         id:         dataTimer
//         interval:   10
//         running:    true
//         repeat:     true

//         onTriggered: {
//             _xAxis.max = _msecs / 1000
//             _xAxis.min = _msecs / 1000 - chartDisplaySec

//             var firstPoint = _msecs == 0

//             var len = axis[_currentAxis].plot.length
//             for (var i = 0; i < len; ++i) {
//                 var value = axis[_currentAxis].plot[i].value
//                 if (!isNaN(value)) {
//                     chart.series(i).append(_msecs/1000, value)
//                     if (firstPoint) {
//                         _yAxis.min = value
//                         _yAxis.max = value
//                     } else {
//                         adjustYAxisMin(_yAxis, value)
//                         adjustYAxisMax(_yAxis, value)
//                     }
//                     var minSec = _msecs/1000 - 3*60
//                     while (chart.series(i).count > 0 && chart.series(i).at(0).x < minSec) {
//                         chart.series(i).remove(0)
//                     }
//                 }
//             }

//             var t = new Date().getTime()
//             if (_last_t > 0)
//                 _msecs += t-_last_t
//             _last_t = t
//         }
//     }

//     // =========================
//     //  Layout + Scroll davranışı
//     // =========================

//     // ✅ stacked olanda bütün kontent scroll olsun
//     QGCFlickable {
//         id: outerFlick
//         anchors.fill: parent
//         clip: true

//         flickableDirection: Flickable.VerticalFlick
//         interactive: root._stacked

//         ScrollBar.vertical: ScrollBar { policy: root._stacked ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
//         ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

//         contentWidth:  width
//         contentHeight: root._stacked ? contentGrid.implicitHeight : height

//         // stacked olanda mouse wheel -> scroll (xəritəyə getməsin)
//         WheelHandler {
//             enabled: root._stacked
//             onWheel: function(e) {
//                 e.accepted = true
//                 var dy = 0
//                 if (e.pixelDelta && e.pixelDelta.y !== 0) dy = e.pixelDelta.y
//                 else if (e.angleDelta && e.angleDelta.y !== 0) dy = (e.angleDelta.y / 120) * (ScreenTools.defaultFontPixelHeight * 3)

//                 var maxY = Math.max(0, outerFlick.contentHeight - outerFlick.height)
//                 outerFlick.contentY = Math.max(0, Math.min(outerFlick.contentY - dy, maxY))
//             }
//         }

//         GridLayout {
//             id: contentGrid
//             width: outerFlick.width
//             columns: root._stacked ? 1 : 2
//             columnSpacing: root._margins
//             rowSpacing: root._margins

//             // ---------- LEFT PANEL ----------
//             ColumnLayout {
//                 id: leftPanel
//                 Layout.fillWidth: true
//                 Layout.fillHeight: !root._stacked
//                 spacing: ScreenTools.defaultFontPixelHeight / 4

//                 // ✅ chart hündürlüyü: stacked-də kiçik, 2 sütunda max limiti ilə
//                 readonly property real chartH: {
//                     if (root._stacked) {
//                         return Math.max(root._minChartH, Math.min(root._maxChartH, root.availableHeight * 0.33))
//                     } else {
//                         // 2 sütun: chart çox böyüməsin
//                         var h = root.availableHeight * 0.70
//                         return Math.max(root._minChartH, Math.min(root._maxChartH, h))
//                     }
//                 }

//                 ChartView {
//                     id:                     chart
//                     Layout.fillWidth:       true
//                     Layout.preferredHeight: leftPanel.chartH
//                     Layout.minimumHeight:   root._minChartH
//                     antialiasing:           true
//                     legend.alignment:       Qt.AlignBottom
//                     legend.font.pointSize:  ScreenTools.defaultFontPointSize
//                     legend.font.family:     ScreenTools.normalFontFamily
//                     titleFont.pointSize:    ScreenTools.defaultFontPointSize
//                     titleFont.family:       ScreenTools.normalFontFamily
//                     clip:                   true

//                     // ✅ chart wheel/drag yalnız 2 sütunda işləsin (kiçikdə wheel scroll olsun)
//                     MouseArea {
//                         enabled: !root._stacked
//                         property var _startPoint: undefined
//                         property double _scaling: 0
//                         anchors.fill: parent

//                         onPressed: (mouse) => {
//                             _startPoint = Qt.point(mouse.x, mouse.y)
//                             var start = chart.mapToValue(_startPoint)
//                             var next = chart.mapToValue(Qt.point(mouse.x+1, mouse.y+1))
//                             _scaling = next.x - start.x
//                         }

//                         onWheel: (wheel) => {
//                             wheel.accepted = true
//                             if (wheel.angleDelta.y > 0) chartDisplaySec /= 1.2
//                             else chartDisplaySec *= 1.2
//                             _xAxis.min = _xAxis.max - chartDisplaySec
//                         }

//                         onPositionChanged: (mouse) => {
//                             if (_startPoint != undefined) {
//                                 dataTimer.running = false
//                                 var cp = Qt.point(mouse.x, mouse.y)
//                                 var dx = (cp.x - _startPoint.x) * _scaling
//                                 _startPoint = cp
//                                 _xAxis.max -= dx
//                                 _xAxis.min -= dx
//                             }
//                         }

//                         onReleased: _startPoint = undefined
//                     }
//                 }

//                 // Bottom controls
//                 ColumnLayout {
//                     id: leftBottom
//                     Layout.fillWidth: true
//                     spacing: ScreenTools.defaultFontPixelHeight / 4

//                     GridLayout {
//                         Layout.fillWidth: true
//                         columns: (leftPanel.width < 520) ? 1 : 2
//                         columnSpacing: root._margins
//                         rowSpacing: root._margins

//                         QGCButton {
//                             text: qsTr("Təmizlə")
//                             Layout.fillWidth: true
//                             onClicked: resetGraphs()
//                         }

//                         QGCButton {
//                             text: dataTimer.running ? qsTr("Dayan") : qsTr("Başla")
//                             Layout.fillWidth: true
//                             onClicked: {
//                                 dataTimer.running = !dataTimer.running
//                                 _last_t = 0
//                                 if (showAutoModeChange && autoModeChange.checked) {
//                                     globals.activeVehicle.flightMode = dataTimer.running
//                                             ? globals.activeVehicle.stabilizedFlightMode
//                                             : globals.activeVehicle.pauseFlightMode
//                                 }
//                             }
//                         }
//                     }

//                     QGCCheckBox {
//                         visible: showAutoModeChange
//                         id:     autoModeChange
//                         text:   qsTr("Avtomatik Uçuş Rejiminin dəyişdirilməsi")
//                         onClicked: if (checked) dataTimer.running = false
//                     }

//                     ColumnLayout {
//                         visible: autoModeChange.checked
//                         QGCLabel {
//                             text: qsTr("Başlat düyməsini kliklədiyiniz zaman 'Stabilize' vəziyyətinə keçir.")
//                             font.pointSize: ScreenTools.smallFontPointSize
//                         }
//                         QGCLabel {
//                             text: qsTr("Dayandır düyməsini kliklədikdə '%1'ə keçir.").arg(globals.activeVehicle.pauseFlightMode)
//                             font.pointSize: ScreenTools.smallFontPointSize
//                         }
//                     }
//                 }
//             }

//             // ---------- RIGHT PANEL ----------
//             Item {
//                 id: rightHost
//                 Layout.fillWidth: true
//                 Layout.fillHeight: !root._stacked
//                 Layout.preferredWidth: root._stacked ? contentGrid.width : root._rightW

//                 Loader {
//                     anchors.fill: parent
//                     sourceComponent: root._stacked ? rightContentComponent : rightScrollableComponent
//                 }

//                 // === Right panel content (NO scroll) ===
//                 Component {
//                     id: rightContentComponent

//                     ColumnLayout {
//                         id: rp
//                         width: parent.width
//                         spacing: root._margins

//                         // Auto/manual selector (wrap)
//                         Flow {
//                             visible: showAutoTuning
//                             width: rp.width
//                             spacing: root._margins

//                             QGCRadioButton {
//                                 text: qsTr("Use auto-tuning")
//                                 checked: root.useAutoTuning
//                                 onClicked: root.useAutoTuning = true
//                             }
//                             QGCRadioButton {
//                                 text: qsTr("Use manual tuning")
//                                 checked: !root.useAutoTuning
//                                 onClicked: root.useAutoTuning = false
//                             }
//                         }

//                         AutotuneUI {
//                             visible: showAutoTuning && root.useAutoTuning
//                         }

//                         ColumnLayout {
//                             visible: !showAutoTuning || !root.useAutoTuning
//                             Layout.fillWidth: true
//                             spacing: root._margins

//                             // Select axis (wrap)
//                             // Flow {
//                             //     width: rp.width
//                             //     spacing: root._margins
//                             //     visible: axis && axis.length > 1

//                             //     QGCLabel { text: qsTr("Select Tuning:"); color: "white" }

//                             //     Repeater {
//                             //         model: axis
//                             //         QGCRadioButton {
//                             //             text: modelData.name
//                             //             checked: index === root._currentAxis
//                             //             onClicked: root._currentAxis = index

//                             //             contentItem: Text {
//                             //                 text: parent.text
//                             //                 font: parent.font
//                             //                 color: "white"
//                             //                 verticalAlignment: Text.AlignVCenter
//                             //                 leftPadding: parent.indicator.width + parent.spacing
//                             //             }
//                             //         }
//                             //     }
//                             // }
//                             // Select axis (kiçik ekranda Yaw aşağı düşməsin)
//                             ColumnLayout {
//                                 visible: axis && axis.length > 1
//                                 Layout.fillWidth: true
//                                 spacing: 4

//                                 QGCLabel {
//                                     text: qsTr("Select Tuning:")
//                                     color: "white"
//                                     font.pointSize: root._stacked ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
//                                     Layout.fillWidth: true
//                                 }

//                                 RowLayout {
//                                     id: axisRow
//                                     Layout.fillWidth: true
//                                     spacing: root._margins * (root._stacked ? 0.6 : 1.0)

//                                     Repeater {
//                                         model: axis
//                                         QGCRadioButton {
//                                             text: modelData.name
//                                             checked: index === root._currentAxis
//                                             onClicked: root._currentAxis = index

//                                             // kiçik ekranda hamısı 1 sətirə sığsın
//                                             Layout.fillWidth: root._stacked
//                                             Layout.preferredWidth: root._stacked
//                                                                   ? (axisRow.width - axisRow.spacing * (axis.length - 1)) / axis.length
//                                                                   : implicitWidth

//                                             font.pointSize: root._stacked ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
//                                             spacing: root._stacked ? (ScreenTools.defaultFontPixelWidth * 0.6) : ScreenTools.defaultFontPixelWidth

//                                             contentItem: Text {
//                                                 text: parent.text
//                                                 font: parent.font
//                                                 color: "white"
//                                                 verticalAlignment: Text.AlignVCenter
//                                                 leftPadding: parent.indicator.width + parent.spacing
//                                                 elide: Text.ElideRight
//                                             }
//                                         }
//                                     }
//                                 }
//                             }


//                             // Sliders for current axis (all instantiated, only one visible)
//                             Repeater {
//                                 model: axis
//                                 delegate: ColumnLayout {
//                                     Layout.fillWidth: true
//                                     visible: root._currentAxis === index
//                                     spacing: root._margins

//                                     Repeater {
//                                         model: modelData.params

//                                         Rectangle {
//                                             Layout.fillWidth: true
//                                             color: "#3C3838"
//                                             radius: 8
//                                             border.color: "#9D9D9D"
//                                             border.width: 1
//                                             Layout.topMargin: root._margins * 0.4

//                                             implicitHeight: contentCol.implicitHeight + ScreenTools.defaultFontPixelHeight

//                                             ColumnLayout {
//                                                 id: contentCol
//                                                 anchors.fill: parent
//                                                 anchors.margins: ScreenTools.defaultFontPixelHeight / 2
//                                                 spacing: ScreenTools.defaultFontPixelHeight / 4

//                                                 QGCLabel {
//                                                     text: title
//                                                     font.bold: true
//                                                     color: "white"
//                                                     Layout.fillWidth: true
//                                                 }

//                                                 QGCLabel {
//                                                     text: description
//                                                     wrapMode: Text.WordWrap
//                                                     color: "#CCCCCC"
//                                                     Layout.fillWidth: true
//                                                     font.pointSize: ScreenTools.smallFontPointSize
//                                                 }

//                                                 RowLayout {
//                                                     Layout.fillWidth: true
//                                                     spacing: ScreenTools.defaultFontPixelWidth

//                                                     QGCSlider {
//                                                         id: sliderControl
//                                                         Layout.fillWidth: true
//                                                         from: min
//                                                         to: max
//                                                         stepSize: step
//                                                         value: controller.getParameterFact(-1, param).value

//                                                         onValueChanged: {
//                                                             if (pressed) {
//                                                                 controller.getParameterFact(-1, param).value = value
//                                                             }
//                                                         }
//                                                     }

//                                                     QGCTextField {
//                                                         Layout.preferredWidth: Math.min(ScreenTools.defaultFontPixelWidth * 12, rp.width * 0.28)
//                                                         text: sliderControl.value.toFixed(4)
//                                                         validator: DoubleValidator { bottom: min; top: max }
//                                                         onEditingFinished: {
//                                                             var standardizedText = text.replace(',', '.')
//                                                             var newValue = parseFloat(standardizedText)
//                                                             if (!isNaN(newValue) && newValue >= min && newValue <= max) {
//                                                                 controller.getParameterFact(-1, param).value = newValue
//                                                                 text = newValue.toFixed(4)
//                                                             } else {
//                                                                 text = sliderControl.value.toFixed(4)
//                                                             }
//                                                         }
//                                                     }
//                                                 }

//                                                 RowLayout {
//                                                     Layout.fillWidth: true
//                                                     QGCLabel { text: min.toFixed(3); color: "#AAAAAA"; font.pointSize: ScreenTools.smallFontPointSize }
//                                                     Item { Layout.fillWidth: true }
//                                                     QGCLabel { text: max.toFixed(3); color: "#AAAAAA"; font.pointSize: ScreenTools.smallFontPointSize }
//                                                 }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }

//                             // Clipboard
//                             // Rectangle {
//                             //     Layout.fillWidth: true
//                             //     color: "#2A2A2A"
//                             //     border.color: "#9D9D9D"
//                             //     border.width: 1
//                             //     radius: 4
//                             //     clip: true

//                             //     implicitHeight: Math.min(Math.max(clipboardCol.implicitHeight + root._margins * 2, 130), 360)

//                             //     ColumnLayout {
//                             //         id: clipboardCol
//                             //         anchors.fill: parent
//                             //         anchors.margins: root._margins
//                             //         spacing: 6

//                             //         QGCLabel {
//                             //             text: qsTr("Clipboard Values:")
//                             //             color: "white"
//                             //             Layout.fillWidth: true
//                             //         }

//                             //         GridLayout {
//                             //             Layout.fillWidth: true
//                             //             columns: 2
//                             //             columnSpacing: root._margins
//                             //             rowSpacing: 2

//                             //             Repeater {
//                             //                 model: axis[root._currentAxis].params
//                             //                 QGCLabel {
//                             //                     text: param
//                             //                     color: "white"
//                             //                     elide: Text.ElideRight
//                             //                     Layout.fillWidth: true
//                             //                 }
//                             //             }

//                             //         //     Repeater {
//                             //         //         id: savedRepeater
//                             //         //         Rectangle {
//                             //         //             color: "#1E1E1E"
//                             //         //             radius: 3
//                             //         //             Layout.fillWidth: true
//                             //         //             implicitHeight: dataLabel.implicitHeight + 6

//                             //         //             QGCLabel {
//                             //         //                 id: dataLabel
//                             //         //                 anchors.centerIn: parent
//                             //         //                 text: modelData
//                             //         //                 color: "white"
//                             //         //                 elide: Text.ElideRight
//                             //         //             }
//                             //         //         }
//                             //         //     }

//                             //             Repeater {
//                             //                 model: root._savedTuningParamValues
//                             //                 Rectangle {
//                             //                     color: "#1E1E1E"
//                             //                     radius: 3
//                             //                     Layout.fillWidth: true
//                             //                     implicitHeight: dataLabel.implicitHeight + 6

//                             //                     QGCLabel {
//                             //                         id: dataLabel
//                             //                         anchors.centerIn: parent
//                             //                         text: modelData
//                             //                         color: "white"
//                             //                         elide: Text.ElideRight
//                             //                     }
//                             //                 }
//                             //             }

//                             //         }
//                             //     }
//                             // }

//                             // Clipboard
//                             Rectangle {
//                                 Layout.fillWidth: true
//                                 color: "#2A2A2A"
//                                 border.color: "#9D9D9D"
//                                 border.width: 1
//                                 radius: 4
//                                 clip: true

//                                 // çox böyüməsin, amma dəyərlər görünəcək qədər yer versin
//                                 implicitHeight: Math.min(Math.max(clipboardCol.implicitHeight + root._margins * 2, 140), 360)

//                                 ColumnLayout {
//                                     id: clipboardCol
//                                     anchors.fill: parent
//                                     anchors.margins: root._margins
//                                     spacing: 6

//                                     QGCLabel {
//                                         text: qsTr("Clipboard Values:")
//                                         color: "white"
//                                         Layout.fillWidth: true
//                                     }

//                                     // Param + Value eyni sətirdə
//                                     Repeater {
//                                         model: (axis && axis.length > 0) ? axis[root._currentAxis].params : 0

//                                         RowLayout {
//                                             Layout.fillWidth: true
//                                             spacing: root._margins

//                                             QGCLabel {
//                                                 text: param
//                                                 color: "white"
//                                                 elide: Text.ElideRight
//                                                 Layout.fillWidth: true
//                                             }

//                                             Rectangle {
//                                                 color: "#1E1E1E"
//                                                 radius: 3
//                                                 Layout.preferredWidth: Math.min(ScreenTools.defaultFontPixelWidth * 14, rightHost.width * 0.35)
//                                                 implicitHeight: valueLbl.implicitHeight + 6

//                                                 QGCLabel {
//                                                     id: valueLbl
//                                                     anchors.centerIn: parent
//                                                     text: (root._savedTuningParamValues && root._savedTuningParamValues.length > index)
//                                                           ? root._savedTuningParamValues[index]
//                                                           : ""
//                                                     color: "white"
//                                                     elide: Text.ElideRight
//                                                 }
//                                             }
//                                         }
//                                     }
//                                 }
//                             }

//                             // Save/Restore (wrap)
//                             GridLayout {
//                                 Layout.fillWidth: true
//                                 columns: (rp.width < 520) ? 1 : 2
//                                 columnSpacing: root._margins
//                                 rowSpacing: root._margins

//                                 QGCButton {
//                                     text: qsTr("Save To Clipboard")
//                                     Layout.fillWidth: true
//                                     onClicked: saveTuningParamValues()
//                                 }

//                                 QGCButton {
//                                     text: qsTr("Restore From Clipboard")
//                                     Layout.fillWidth: true
//                                     onClicked: resetToSavedTuningParamValues()
//                                 }
//                             }
//                         }
//                     }
//                 }

//                 // === Right panel content (scrollable) — yalnız 2 sütunda ===
//                 Component {
//                     id: rightScrollableComponent

//                     QGCFlickable {
//                         id: rightFlick
//                         anchors.fill: parent
//                         clip: true

//                         flickableDirection: Flickable.VerticalFlick
//                         ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
//                         ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

//                         contentWidth:  width
//                         contentHeight: rightLoader.item ? rightLoader.item.implicitHeight : 0

//                         // wheel -> sağ panel scroll (xəritəyə getməsin)
//                         WheelHandler {
//                             onWheel: function(e) {
//                                 e.accepted = true
//                                 var dy = 0
//                                 if (e.pixelDelta && e.pixelDelta.y !== 0) dy = e.pixelDelta.y
//                                 else if (e.angleDelta && e.angleDelta.y !== 0) dy = (e.angleDelta.y / 120) * (ScreenTools.defaultFontPixelHeight * 3)

//                                 var maxY = Math.max(0, rightFlick.contentHeight - rightFlick.height)
//                                 rightFlick.contentY = Math.max(0, Math.min(rightFlick.contentY - dy, maxY))
//                             }
//                         }

//                         Loader {
//                             id: rightLoader
//                             width: rightFlick.width
//                             sourceComponent: rightContentComponent
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }


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

    // Internals
    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
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
        labelsFont.family:      ScreenTools.normalFontFamily
        titleFont.pointSize:    ScreenTools.defaultFontPointSize
        titleFont.family:       ScreenTools.normalFontFamily
    }

    ValueAxis {
        id:                     yAxis
        min:                    0
        max:                    10
        titleText:              unit
        tickCount:              Math.min(((max - min) / _tickSeparation), _maxTickSections) + 1
        labelsFont.pointSize:   ScreenTools.defaultFontPointSize
        labelsFont.family:      ScreenTools.normalFontFamily
        titleFont.pointSize:    ScreenTools.defaultFontPointSize
        titleFont.family:       ScreenTools.normalFontFamily
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
                    Layout.preferredHeight: leftPanel.chartH
                    Layout.minimumHeight:   root._minChartH
                    antialiasing:           true
                    legend.alignment:       Qt.AlignBottom
                    legend.font.pointSize:  ScreenTools.defaultFontPointSize
                    legend.font.family:     ScreenTools.normalFontFamily
                    titleFont.pointSize:    ScreenTools.defaultFontPointSize
                    titleFont.family:       ScreenTools.normalFontFamily
                    clip:                   true

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
                                    color: "white"
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
                                                font: parent.font
                                                color: "white"
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
                                            color: "#3C3838"
                                            radius: 8
                                            border.color: "#9D9D9D"
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
                                                    font.bold: true
                                                    color: "white"
                                                    Layout.fillWidth: true
                                                }

                                                QGCLabel {
                                                    text: description
                                                    wrapMode: Text.WordWrap
                                                    color: "#CCCCCC"
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
                                                    QGCLabel { text: min.toFixed(3); color: "#AAAAAA"; font.pointSize: ScreenTools.smallFontPointSize }
                                                    Item { Layout.fillWidth: true }
                                                    QGCLabel { text: max.toFixed(3); color: "#AAAAAA"; font.pointSize: ScreenTools.smallFontPointSize }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Clipboard
                            Rectangle {
                                Layout.fillWidth: true
                                color: "#2A2A2A"
                                border.color: "#9D9D9D"
                                border.width: 1
                                radius: 4
                                clip: true

                                implicitHeight: Math.min(Math.max(clipboardCol.implicitHeight + root._margins * 2, 140), 360)

                                ColumnLayout {
                                    id: clipboardCol
                                    anchors.fill: parent
                                    anchors.margins: root._margins
                                    spacing: 6

                                    QGCLabel {
                                        text: qsTr("Clipboard Values:")
                                        color: "white"
                                        Layout.fillWidth: true
                                    }

                                    Repeater {
                                        model: (axis && axis.length > 0) ? axis[root._currentAxis].params : 0

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: root._margins

                                            QGCLabel {
                                                text: param
                                                color: "white"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                color: "#1E1E1E"
                                                radius: 3
                                                Layout.preferredWidth: Math.min(ScreenTools.defaultFontPixelWidth * 14, rightHost.width * 0.35)
                                                implicitHeight: valueLbl.implicitHeight + 6

                                                QGCLabel {
                                                    id: valueLbl
                                                    anchors.centerIn: parent
                                                    text: (root._savedTuningParamValues && root._savedTuningParamValues.length > index)
                                                          ? root._savedTuningParamValues[index]
                                                          : ""
                                                    color: "white"
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

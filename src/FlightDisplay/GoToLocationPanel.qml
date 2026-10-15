import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.Controls

/// Go To paneli: xəritədə seçilmiş nöqtəyə hansı hündürlükdə (evdən) və hansı sürətlə
/// uçulacağını təyin edir. Əmr yalnız "Təsdiq et" basılanda göndərilir.
///
/// Dəyərlər metrlə saxlanılır, tətbiqin ölçü vahidində göstərilir. Limitlər burada yalnız
/// istifadəçiyə göstərmək üçündür: Vehicle::guidedModeGotoLocation() onları yenidən yoxlayır.
Rectangle {
    id:         root
    width:      Math.min(ScreenTools.defaultFontPixelWidth * 46, parent ? parent.width * 0.9 : ScreenTools.defaultFontPixelWidth * 46)
    height:     mainLayout.implicitHeight + (_margins * 2)
    radius:     ScreenTools.defaultFontPixelWidth / 2
    color:      qgcPal.window
    border.color: qgcPal.groupBorder
    border.width: 1
    visible:    false

    property var guidedController

    /// Hədəf nöqtə və xəritədəki "Go here" nişanı (təsdiq/ləğvdə ona xəbər verilir).
    property var coordinate:    QtPositioning.coordinate()
    property var mapIndicator

    property real altitudeM:    0       ///< Evdən hündürlük, metr
    property bool speedEnabled: false   ///< Söndürülü olanda aparat öz sürəti ilə uçur
    property real speedMS:      0       ///< m/s: hover-də yer sürəti, irəli uçuşda hava sürəti

    readonly property var   _vehicle:           QGroundControl.multiVehicleManager.activeVehicle
    readonly property var   _flyViewSettings:   QGroundControl.settingsManager.flyViewSettings
    readonly property var   _units:             QGroundControl.unitsConversion
    readonly property real  _margins:           ScreenTools.defaultFontPixelWidth
    readonly property bool  _fwdFlight:         _vehicle ? _vehicle.inFwdFlight : false

    /// Hədəf hündürlük yalnız ev nöqtəsinin hündürlüyü məlum olanda göndərilə bilər.
    readonly property bool  _altitudeAvailable: !!_vehicle && _vehicle.homePosition.isValid && !isNaN(_vehicle.homePosition.altitude)
    readonly property real  _altitudeMinM:      _flyViewSettings.guidedMinimumAltitude.rawValue
    readonly property real  _altitudeMaxM:      _flyViewSettings.guidedMaximumAltitude.rawValue
    readonly property real  _currentAltitudeM:  _vehicle ? _vehicle.altitudeRelative.rawValue : NaN

    // Sürət limitləri panel açılanda aparatın parametrlərindən oxunur.
    property real _speedMinMS:  0
    property real _speedMaxMS:  NaN

    readonly property bool  _altitudeValid: !_altitudeAvailable || ((altitudeM >= _altitudeMinM) && (altitudeM <= _altitudeMaxM))
    readonly property bool  _speedValid:    !speedEnabled || ((speedMS > 0) && (speedMS >= _speedMinMS) && (isNaN(_speedMaxMS) || (speedMS <= _speedMaxMS)))
    readonly property bool  _canConfirm:    !!_vehicle && _altitudeValid && _speedValid

    readonly property real  _distanceM:     (_vehicle && _vehicle.coordinate.isValid && coordinate.isValid) ? _vehicle.coordinate.distanceTo(coordinate) : NaN

    /// Çatma vaxtı üçün sürət: təyin edilibsə o, yoxsa aparatın indiki yer sürəti.
    readonly property real  _etaSpeedMS: {
        if (speedEnabled) {
            return speedMS
        }
        var current = _vehicle ? _vehicle.groundSpeed.rawValue : NaN
        return (current > 0.5) ? current : NaN
    }

    // Aparat Go To edə bilmir hala düşəndə (endi, bağlantı itdi) panel özü bağlanır.
    readonly property bool _gotoAllowed: guidedController ? guidedController.showGotoLocation : false
    on_GotoAllowedChanged: {
        if (!_gotoAllowed && visible) {
            cancel()
        }
    }

    Component.onCompleted: guidedController.gotoPanel = root

    function open(coord, indicator) {
        coordinate = coord
        mapIndicator = indicator

        var current = isNaN(_currentAltitudeM) ? _altitudeMinM : Math.round(_currentAltitudeM)
        altitudeM = Math.min(Math.max(current, _altitudeMinM), _altitudeMaxM)

        if (_fwdFlight) {
            var haveFw = _vehicle && _vehicle.haveFWSpeedLimits
            _speedMinMS = haveFw ? _vehicle.minimumEquivalentAirspeed() : 1
            _speedMaxMS = haveFw ? _vehicle.maximumEquivalentAirspeed() : NaN
        } else {
            _speedMinMS = 0.5
            _speedMaxMS = (_vehicle && _vehicle.haveMRSpeedLimits) ? _vehicle.maximumHorizontalSpeedMultirotor() : NaN
        }

        // Sürət sahəsi açılanda başlanğıc dəyər: indiki sürət, o yoxdursa aralığın ortası.
        var startSpeed = _vehicle ? _vehicle.groundSpeed.rawValue : NaN
        if (!(startSpeed > 0.5)) {
            startSpeed = isNaN(_speedMaxMS) ? 5 : (_speedMinMS + _speedMaxMS) / 2
        }
        speedMS = _clampSpeed(Math.round(startSpeed * 2) / 2)
        speedCheck.checked = false

        visible = true
        root.forceActiveFocus()
    }

    function cancel() {
        visible = false
        if (mapIndicator) {
            mapIndicator.actionCancelled()
            mapIndicator = undefined
        }
    }

    function confirm() {
        if (!_canConfirm) {
            return
        }
        visible = false
        guidedController.executeGoto(coordinate,
                                     _altitudeAvailable ? altitudeM : NaN,
                                     speedEnabled ? speedMS : NaN)
        if (mapIndicator) {
            mapIndicator.actionConfirmed()
            mapIndicator = undefined
        }
    }

    function _clampSpeed(value) {
        var v = Math.max(value, _speedMinMS)
        return isNaN(_speedMaxMS) ? v : Math.min(v, _speedMaxMS)
    }

    function _altitudeText(meters) {
        return _units.metersToAppSettingsVerticalDistanceUnits(meters).toFixed(1) + " " + _units.appSettingsVerticalDistanceUnitsString
    }

    function _speedText(metersSecond) {
        return _units.metersSecondToAppSettingsSpeedUnits(metersSecond).toFixed(1) + " " + _units.appSettingsSpeedUnitsString
    }

    function _etaText() {
        if (isNaN(_distanceM) || isNaN(_etaSpeedMS) || (_etaSpeedMS <= 0)) {
            return "—"
        }
        var seconds = Math.round(_distanceM / _etaSpeedMS)
        var minutes = Math.floor(seconds / 60)
        seconds = seconds % 60
        return minutes > 0 ? qsTr("%1 dəq %2 san").arg(minutes).arg(seconds) : qsTr("%1 san").arg(seconds)
    }

    Keys.onEscapePressed: cancel()

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    // − / sahə / + sətri. Dəyər metrlə gəlir; sahədə tətbiqin vahidində göstərilir.
    component StepRow: RowLayout {
        id: stepRow

        property real   valueM
        property real   stepM:          1
        property string unitText
        property bool   valid:          true
        // Metr ↔ göstərilən vahid çevirmələri (hündürlük və sürət üçün fərqlidir).
        property var    toDisplay
        property var    fromDisplay

        signal changed(real newValueM)

        spacing: ScreenTools.defaultFontPixelWidth / 2

        // Sahə metr dəyərindən yazılır. İstifadəçi yazanda binding qırılır, ona görə bağlama
        // əvəzinə dəyər dəyişəndə açıq yazılır.
        function _refresh() { field.text = stepRow.toDisplay(stepRow.valueM).toFixed(1) }
        onValueMChanged:        _refresh()
        Component.onCompleted:  _refresh()

        // Inline komponent xarici id-ləri görmür.
        QGCPalette { id: rowPal; colorGroupEnabled: stepRow.enabled }

        QGCButton {
            text:               "−"
            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.2
            onClicked:          stepRow.changed(stepRow.valueM - stepRow.stepM)
        }

        QGCTextField {
            id:                 field
            Layout.fillWidth:   true
            horizontalAlignment: Text.AlignHCenter
            inputMethodHints:   Qt.ImhFormattedNumbersOnly
            textColor:          stepRow.valid ? rowPal.textFieldText : rowPal.colorRed

            onEditingFinished: {
                var entered = parseFloat(text.replace(",", "."))
                if (!isNaN(entered)) {
                    stepRow.changed(stepRow.fromDisplay(entered))
                }
                // Limitə sıxılan və ya dəyişməyən dəyər də sahədə düzgün görünsün.
                stepRow._refresh()
            }
        }

        QGCLabel {
            text:               stepRow.unitText
            Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 4
        }

        QGCButton {
            text:               "+"
            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.2
            onClicked:          stepRow.changed(stepRow.valueM + stepRow.stepM)
        }
    }

    ColumnLayout {
        id:                 mainLayout
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.margins:    root._margins
        spacing:            root._margins

        QGCLabel {
            Layout.fillWidth:       true
            horizontalAlignment:    Text.AlignHCenter
            text:                   qsTr("Mövqeyə uç")
            font.pointSize:         ScreenTools.mediumFontPointSize
            font.bold:              true
        }

        GridLayout {
            Layout.fillWidth:   true
            columns:            2
            columnSpacing:      root._margins
            rowSpacing:         root._margins / 4

            QGCLabel { text: qsTr("Məsafə") }
            QGCLabel {
                Layout.fillWidth:   true
                horizontalAlignment: Text.AlignRight
                text: isNaN(root._distanceM) ? "—"
                                        : root._units.metersToAppSettingsHorizontalDistanceUnits(root._distanceM).toFixed(0) + " " + root._units.appSettingsHorizontalDistanceUnitsString
            }

            QGCLabel {
                text:       qsTr("Hündürlük dəyişimi")
                visible:    root._altitudeAvailable && !isNaN(root._currentAltitudeM)
            }
            QGCLabel {
                Layout.fillWidth:   true
                horizontalAlignment: Text.AlignRight
                visible:            root._altitudeAvailable && !isNaN(root._currentAltitudeM)
                text: {
                    var delta = root.altitudeM - root._currentAltitudeM
                    return (delta >= 0 ? "+" : "−") + root._altitudeText(Math.abs(delta))
                }
            }

            QGCLabel { text: qsTr("Təxmini vaxt") }
            QGCLabel {
                Layout.fillWidth:   true
                horizontalAlignment: Text.AlignRight
                text:               root._etaText()
            }
        }

        // ---------------------------------------------------------------- Hündürlük
        QGCLabel {
            text:       qsTr("Hündürlük (evdən)")
            font.bold:  true
        }

        StepRow {
            Layout.fillWidth:   true
            visible:            root._altitudeAvailable
            valueM:             root.altitudeM
            stepM:              5
            unitText:           root._units.appSettingsVerticalDistanceUnitsString
            valid:              root._altitudeValid
            toDisplay:          function(m) { return root._units.metersToAppSettingsVerticalDistanceUnits(m) }
            fromDisplay:        function(v) { return root._units.appSettingsVerticalDistanceUnitsToMeters(v) }
            onChanged:          (newValueM) => { root.altitudeM = Math.min(Math.max(newValueM, root._altitudeMinM), root._altitudeMaxM) }
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            text: root._altitudeAvailable
                  ? qsTr("Aralıq: %1 – %2").arg(root._altitudeText(root._altitudeMinM)).arg(root._altitudeText(root._altitudeMaxM))
                  : qsTr("Ev nöqtəsinin hündürlüyü bilinmir: aparat indiki hündürlüyündə uçacaq.")
        }

        // ------------------------------------------------------------------- Sürət
        QGCCheckBox {
            id:         speedCheck
            text:       root._fwdFlight ? qsTr("Hava sürətini təyin et") : qsTr("Yer sürətini təyin et")
            checked:    false
            onCheckedChanged: root.speedEnabled = checked
        }

        StepRow {
            Layout.fillWidth:   true
            enabled:            root.speedEnabled
            opacity:            root.speedEnabled ? 1 : 0.5
            valueM:             root.speedMS
            stepM:              0.5
            unitText:           root._units.appSettingsSpeedUnitsString
            valid:              root._speedValid
            toDisplay:          function(m) { return root._units.metersSecondToAppSettingsSpeedUnits(m) }
            fromDisplay:        function(v) { return root._units.appSettingsSpeedUnitsToMetersSecond(v) }
            onChanged:          (newValueM) => { root.speedMS = root._clampSpeed(newValueM) }
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            text: {
                if (!root.speedEnabled) {
                    return qsTr("Söndürülü: aparat öz sürəti ilə uçur.")
                }
                return isNaN(root._speedMaxMS)
                        ? qsTr("Minimum: %1").arg(root._speedText(root._speedMinMS))
                        : qsTr("Aralıq: %1 – %2").arg(root._speedText(root._speedMinMS)).arg(root._speedText(root._speedMaxMS))
            }
        }

        // ---------------------------------------------------------------- Düymələr
        RowLayout {
            Layout.fillWidth:   true
            Layout.topMargin:   root._margins / 2
            spacing:            ScreenTools.defaultFontPixelWidth * 2

            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.2
                radius:                 ScreenTools.defaultFontPixelWidth / 2
                color:                  cancelArea.pressed ? Qt.darker("#e74c3c", 1.2) : "#e74c3c"
                border.color:           Qt.darker("#e74c3c", 1.5)
                border.width:           2

                QGCLabel {
                    anchors.centerIn:   parent
                    text:               qsTr("Ləğv et")
                    font.bold:          true
                    color:              "white"
                }

                QGCMouseArea {
                    id:         cancelArea
                    fillItem:   parent
                    onClicked:  root.cancel()
                }
            }

            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.2
                radius:                 ScreenTools.defaultFontPixelWidth / 2
                opacity:                root._canConfirm ? 1 : 0.4
                color:                  confirmArea.pressed ? Qt.darker("#63992C", 1.2) : "#63992C"
                border.color:           Qt.darker("#63992C", 1.5)
                border.width:           2

                QGCLabel {
                    anchors.centerIn:   parent
                    text:               qsTr("Təsdiq et")
                    font.bold:          true
                    color:              "white"
                }

                QGCMouseArea {
                    id:         confirmArea
                    fillItem:   parent
                    enabled:    root._canConfirm
                    onClicked:  root.confirm()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls

/// Go To paneli: xəritədə seçilmiş nöqtəyə hansı hündürlükdə (evdən) və hansı sürətlə
/// uçulacağını təyin edir. Əmr yalnız "Təsdiq et" basılanda göndərilir.
///
/// Dəyərlər metrlə saxlanılır, tətbiqin ölçü vahidində göstərilir. Limitlər burada yalnız
/// istifadəçiyə göstərmək üçündür: Vehicle::guidedModeGotoLocation() onları yenidən yoxlayır.
///
/// Görünüş Yüksəklik/Sürət panelləri ilədir (dizayn kartı, Poppins, AzButton).
Item {
    id:         root
    width:      Math.min(AzTheme.px(400), parent ? parent.width * 0.9 : AzTheme.px(400))
    height:     mainLayout.implicitHeight + (_margins * 2)
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
    readonly property real  _margins:           AzTheme.px(20)
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

    RectangularShadow {
        anchors.fill: cardBackground
        offset.y:     AzTheme.px(12)
        blur:         AzTheme.px(32)
        radius:       cardBackground.radius
        color:        AzTheme.popupShadow
    }

    AzGradientRect {
        id:            cardBackground
        anchors.fill:  parent
        angle:         AzTheme.panelGradientAngle
        startColor:    AzTheme.panelGradientStart
        startPosition: AzTheme.panelGradientStartPos
        endColor:      AzTheme.panelGradientEnd
        endPosition:   AzTheme.panelGradientEndPos
        radius:        AzTheme.px(AzTheme.popupRadius)
        borderColor:   AzTheme.panelBorder
        borderWidth:   1
    }

    // Clicks and the wheel on the panel do not reach the map.
    MouseArea {
        anchors.fill:    parent
        acceptedButtons: Qt.AllButtons
        onWheel:         (wheel) => { wheel.accepted = true }
    }

    /// Plain panel text.
    component PanelText: Text {
        color:          AzTheme.textCard
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
    }

    /// Small grey note under a setting.
    component NoteText: Text {
        wrapMode:       Text.WordWrap
        color:          AzTheme.textSecondary
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(12)
    }

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

        spacing: AzTheme.px(8)

        // Sahə metr dəyərindən yazılır. İstifadəçi yazanda binding qırılır, ona görə bağlama
        // əvəzinə dəyər dəyişəndə açıq yazılır.
        function _refresh() { field.text = stepRow.toDisplay(stepRow.valueM).toFixed(1) }
        onValueMChanged:        _refresh()
        Component.onCompleted:  _refresh()

        AzButton {
            text:                   "−"
            textSize:               22
            minimumWidth:           AzTheme.px(40)
            Layout.preferredWidth:  AzTheme.px(40)
            Layout.preferredHeight: AzTheme.px(40)
            onClicked:              stepRow.changed(stepRow.valueM - stepRow.stepM)
        }

        // Value and unit in a pill; red while out of range.
        Rectangle {
            Layout.fillWidth:       true
            Layout.preferredHeight: AzTheme.px(40)
            radius:                 AzTheme.px(8)
            border.width:           1
            border.color:           !stepRow.valid ? AzTheme.statusRed
                                                   : (field.activeFocus ? AzTheme.cardHoverBorder : AzTheme.groupBorder)
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.pillTop }
                GradientStop { position: 1; color: AzTheme.pillBottom }
            }

            Row {
                anchors.centerIn: parent
                spacing:          AzTheme.px(4)

                TextInput {
                    id:                  field
                    width:               Math.max(AzTheme.px(24), contentWidth)
                    horizontalAlignment: Text.AlignHCenter
                    inputMethodHints:    Qt.ImhFormattedNumbersOnly
                    selectByMouse:       true
                    color:               stepRow.valid ? AzTheme.textCard : AzTheme.statusRed
                    font.family:         AzTheme.fontFamily
                    font.pixelSize:      AzTheme.fontPx(AzTheme.popupTextSize)

                    onEditingFinished: {
                        var entered = parseFloat(text.replace(",", "."))
                        if (!isNaN(entered)) {
                            stepRow.changed(stepRow.fromDisplay(entered))
                        }
                        // Limitə sıxılan və ya dəyişməyən dəyər də sahədə düzgün görünsün.
                        stepRow._refresh()
                    }
                }

                Text {
                    text:           stepRow.unitText
                    color:          AzTheme.textCard
                    font.family:    AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                }
            }
        }

        AzButton {
            text:                   "+"
            textSize:               22
            minimumWidth:           AzTheme.px(40)
            Layout.preferredWidth:  AzTheme.px(40)
            Layout.preferredHeight: AzTheme.px(40)
            onClicked:              stepRow.changed(stepRow.valueM + stepRow.stepM)
        }
    }

    ColumnLayout {
        id:                 mainLayout
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.margins:    root._margins
        spacing:            AzTheme.px(12)

        PanelText {
            Layout.fillWidth:   true
            text:               qsTr("Mövqeyə uç")
            font.weight:        Font.Medium
            font.pixelSize:     AzTheme.fontPx(18)
        }

        GridLayout {
            Layout.fillWidth:   true
            columns:            2
            columnSpacing:      root._margins
            rowSpacing:         AzTheme.px(6)

            PanelText { text: qsTr("Məsafə"); color: AzTheme.textSecondary }
            PanelText {
                Layout.fillWidth:   true
                horizontalAlignment: Text.AlignRight
                text: isNaN(root._distanceM) ? "—"
                                        : root._units.metersToAppSettingsHorizontalDistanceUnits(root._distanceM).toFixed(0) + " " + root._units.appSettingsHorizontalDistanceUnitsString
            }

            PanelText {
                text:       qsTr("Hündürlük dəyişimi")
                color:      AzTheme.textSecondary
                visible:    root._altitudeAvailable && !isNaN(root._currentAltitudeM)
            }
            PanelText {
                Layout.fillWidth:   true
                horizontalAlignment: Text.AlignRight
                visible:            root._altitudeAvailable && !isNaN(root._currentAltitudeM)
                text: {
                    var delta = root.altitudeM - root._currentAltitudeM
                    return (delta >= 0 ? "+" : "−") + root._altitudeText(Math.abs(delta))
                }
            }

            PanelText { text: qsTr("Təxmini vaxt"); color: AzTheme.textSecondary }
            PanelText {
                Layout.fillWidth:   true
                horizontalAlignment: Text.AlignRight
                text:               root._etaText()
            }
        }

        // ---------------------------------------------------------------- Hündürlük
        PanelText {
            Layout.topMargin:   AzTheme.px(4)
            text:               qsTr("Hündürlük (evdən)")
            font.weight:        Font.Medium
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

        NoteText {
            Layout.fillWidth:   true
            text: root._altitudeAvailable
                  ? qsTr("Aralıq: %1 – %2").arg(root._altitudeText(root._altitudeMinM)).arg(root._altitudeText(root._altitudeMaxM))
                  : qsTr("Ev nöqtəsinin hündürlüyü bilinmir: aparat indiki hündürlüyündə uçacaq.")
        }

        // ------------------------------------------------------------------- Sürət
        RowLayout {
            Layout.fillWidth:   true
            Layout.topMargin:   AzTheme.px(4)

            PanelText {
                Layout.fillWidth:   true
                text:               root._fwdFlight ? qsTr("Hava sürətini təyin et") : qsTr("Yer sürətini təyin et")
                font.weight:        Font.Medium
            }

            AzSwitch {
                id:                 speedCheck
                checked:            false
                onClicked:          checked = !checked
                onCheckedChanged:   root.speedEnabled = checked
            }
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

        NoteText {
            Layout.fillWidth:   true
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
            Layout.topMargin:   AzTheme.px(4)
            spacing:            AzTheme.px(12)

            AzButton {
                Layout.fillWidth:   true
                text:               qsTr("Ləğv et")
                onClicked:          root.cancel()
            }

            AzButton {
                Layout.fillWidth:   true
                text:               qsTr("Təsdiq et")
                enabled:            root._canConfirm
                onClicked:          root.confirm()
            }
        }
    }
}

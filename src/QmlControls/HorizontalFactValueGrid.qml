










//---------androidkod----------------
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml

import QGroundControl.Controls
import QGroundControl.FlightMap
import QGroundControl

HorizontalFactValueGridTemplate {
    id: _root
    clip: true

    // TelemetryValuesBar-dan ötürülür
    property real availableWidth:  0
    property real availableHeight: 0

    // İstəsən 6 yox 8 elə
    property int _maxUserColumns: 3


    property bool settingsUnlocked: false

    readonly property real _fallbackMaxWidth: ScreenTools.defaultFontPixelHeight * 17.1
    readonly property real _windowH: (_root.window && _root.window.height > 0) ? _root.window.height : Screen.height

    // Panelin iç eni (real limit)
    readonly property real _maxContentW: {
        if (availableWidth > 0) {
            return Math.max(180, availableWidth)
        }
        if (_root.parent && _root.parent.width > 0) {
            return Math.max(180, _root.parent.width)
        }
        return Math.max(180, _fallbackMaxWidth)
    }

    readonly property bool _compact: ScreenTools.isMobile || _maxContentW < 340

    // Between columns, between a name and its reading, and between values in a column.
    readonly property real _groupSpacing: AzTheme.px(16)
    readonly property real _innerGap:     AzTheme.px(12)
    readonly property real _rowGap:       AzTheme.px(16)

    // columns count (length və ya count ola bilər)
    function _modelCount(m) {
        if (!m) return 0
        if (m.length !== undefined) return m.length
        if (m.count !== undefined)  return m.count
        return 0
    }

    // Hazırda neçə sütun qrupu var
    readonly property int _colCount: {
        var c = _modelCount(_root.columns)
        return c > 0 ? c : 1
    }

    // ✅ Sağdakı column +/- düymələrinin eni (yalnız unlock olanda yer tutur)
    readonly property real _colButtonsW: settingsUnlocked ? Math.max(28, Math.round(ScreenTools.minTouchPixels * 0.85)) : 0

    // ✅ Grid üçün real istifadə olunan en (panel eni - column button eni - aralıq)
    readonly property real _gridMaxW: Math.max(
        180,
        _maxContentW - (_colButtonsW > 0 ? (_colButtonsW + _groupSpacing) : 0)
    )

    // The design fits three columns into a 282 px card.
    readonly property real _minColW: AzTheme.px(72)

    // Hər sütun qrupuna düşən en (grid eninə görə)
    readonly property real _perColW: Math.max(
        _minColW,
        Math.floor((_gridMaxW - ((_colCount - 1) * _groupSpacing)) / _colCount)
    )

    // Auto-fit üçün row limiti
    property int _rowMax: _compact ? 6 : 4

    width: _maxContentW
    implicitWidth: width
    implicitHeight: topLayout.implicitHeight

    Layout.preferredWidth: width
    Layout.maximumWidth:   width
    Layout.alignment:      Qt.AlignRight

    // -------- AUTO-FIT: eni aşırsa rowCount artır --------
    property int _autoFitPass: 0

    Timer {
        id: autoFitTimer
        interval: 40
        repeat: false
        onTriggered: {
            var again = _root._autoFitNow()
            if (again && _root._autoFitPass < 10) {
                _root._autoFitPass++
                autoFitTimer.restart()
            }
        }
    }

    function _requestAutoFit() {
        _autoFitPass = 0
        autoFitTimer.restart()
    }

    function _autoFitNow() {
        if (settingsUnlocked) return false
        if (!_root.columns || _modelCount(_root.columns) === 0) return false

        var maxW = _gridMaxW
        var guard = 0
        var changed = false

        while (labelValueRow.implicitWidth > maxW && _root.rowCount < _rowMax && guard < 10) {
            appendRow()
            guard++
            changed = true
        }

        if (!_compact) {
            while (_root.rowCount > 1 && labelValueRow.implicitWidth < (maxW * 0.72) && guard < 20) {
                deleteLastRow()
                guard++
                changed = true
            }
        }
        return changed
    }

    onAvailableWidthChanged: _requestAutoFit()
    onColumnsChanged:        _requestAutoFit()
    onWidthChanged:          _requestAutoFit()
    Component.onCompleted:   _requestAutoFit()

    // ✅ Klik edilən elementin içindən instrumentValueData tap
    function _findInstrumentItem(item) {
        var it = item
        while (it && it !== _root) {
            if (it.instrumentValueData !== undefined) {
                return it
            }
            it = it.parent
        }
        return null
    }

    // ✅ minimum column eni ilə panelə sığan maksimum column sayı (overflow olmasın)
    readonly property int _maxAllowedColumns: {
        var minCol = _minColW
        var w = _gridMaxW
        var sp = _groupSpacing
        // colCount*minCol + (colCount-1)*sp <= w
        // colCount <= (w + sp) / (minCol + sp)
        return Math.max(1, Math.floor((w + sp) / (minCol + sp)))
    }

    // ---------------- UI ----------------
    ColumnLayout {
        id: topLayout
        anchors.fill: parent
        spacing: ScreenTools.defaultFontPixelWidth * (_compact ? 0.55 : 0.85)

        // ✅ yuxarı hissə: grid + sağda column (+/-)
        RowLayout {
            id: headRow
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: _groupSpacing

            // GRID AREA (yalnız buranı kliklə edit edirik)
            Item {
                id: gridArea
                Layout.fillWidth: true
                implicitHeight: labelValueRow.implicitHeight
                clip: true

                RowLayout {
                    id: labelValueRow
                    anchors.fill: parent
                    Layout.alignment: Qt.AlignRight
                    spacing: _groupSpacing

                    Repeater {
                        model: _root.columns

                        // One column of the card: each value is its name over its reading.
                        ColumnLayout {
                            Layout.preferredWidth: _perColW
                            Layout.maximumWidth:   _perColW
                            Layout.alignment:      Qt.AlignTop
                            spacing:               _rowGap

                            Repeater {
                                model: object

                                ColumnLayout {
                                    // Lets the edit hit test find the value under the click.
                                    property var instrumentValueData: object

                                    Layout.fillWidth: true
                                    spacing:          _innerGap
                                    clip:             true

                                    InstrumentValueLabel {
                                        Layout.fillWidth:    true
                                        instrumentValueData: object
                                    }

                                    InstrumentValueValue {
                                        instrumentValueData: object
                                    }
                                }
                            }
                        }
                    }
                }

                // ✅ Unlock olanda klik -> edit dialog
                QGCMouseArea {
                    anchors.fill: parent
                    visible: settingsUnlocked
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true
                    z: 999

                    onClicked: (mouse) => {
                        var p = mapToItem(labelValueRow, mouse.x, mouse.y)

                        var grid = labelValueRow.childAt(p.x, p.y)
                        if (!grid) return

                        var p2 = labelValueRow.mapToItem(grid, p.x, p.y)
                        var hit = grid.childAt(p2.x, p2.y)
                        hit = _root._findInstrumentItem(hit)

                        if (hit && hit.instrumentValueData) {
                            valueEditDialog.createObject(mainWindow, { instrumentValueData: hit.instrumentValueData }).open()
                            mouse.accepted = true
                        }
                    }
                }
            }


            // ✅ Sağda Column (+/-)
            ColumnLayout {
                id: colButtons
                visible: settingsUnlocked
                spacing: 1

                Layout.preferredWidth: _colButtonsW
                Layout.minimumWidth:   _colButtonsW
                Layout.maximumWidth:   _colButtonsW
                Layout.fillHeight: true

                // Soft max: istədiyin qədər artır/azalt (overflow olsa belə user geri sala bilir)
                // 6 G20 üçün yaxşıdır. İstəsən 8 et.
                // (Template daha az icazə verirsə, appendColumn onsuz da təsir etməyəcək.)
                property int _maxUserColumns: 6

                QGCButton {
                    Layout.preferredWidth:  _colButtonsW
                    Layout.fillHeight:      true
                    topPadding:             0
                    bottomPadding:          0
                    leftPadding:            0
                    rightPadding:           0
                    text:                   qsTr("+")
                    enabled:                _colCount < colButtons._maxUserColumns
                    onClicked: {
                        appendColumn()
                        _requestAutoFit()
                    }
                }

                QGCButton {
                    Layout.preferredWidth:  _colButtonsW
                    Layout.fillHeight:      true
                    topPadding:             0
                    bottomPadding:          0
                    leftPadding:            0
                    rightPadding:           0
                    text:                   qsTr("-")
                    enabled:                _colCount > 1
                    onClicked: {
                        deleteLastColumn()
                        _requestAutoFit()
                    }
                }
            }

        }

        // ✅ Row +/- düymələri (unlock olanda)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 25
            visible: settingsUnlocked

            Row {
                anchors.centerIn: parent
                spacing: 10

                QGCButton {
                    width: 100
                    height: 25
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    text: qsTr("+")
                    font.pixelSize: 12
                    enabled: (_root.implicitHeight + 80) < (_windowH - ScreenTools.toolbarHeight)
                    onClicked: appendRow()
                }

                QGCButton {
                    width: 100
                    height: 25
                    topPadding: 0
                    bottomPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    text: qsTr("-")
                    font.pixelSize: 12
                    enabled: _root.rowCount > 1
                    onClicked: deleteLastRow()
                }
            }
        }
    }

    Component {
        id: valueEditDialog
        InstrumentValueEditDialog { }
    }
}

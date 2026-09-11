import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

AnalyzePage {
    id:              vibrationPage
    anchors.fill:    parent
    anchors.margins: 0

    headerComponent: headerComponent
    pageComponent:   pageComponent
    pageDescription: ""
    allowPopout:     true

    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
                                  ? QGroundControl.multiVehicleManager.activeVehicle
                                  : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property bool _available:     !isNaN(_activeVehicle.vibration.xAxis.rawValue)

    property real _xValue: _activeVehicle.vibration.xAxis.rawValue
    property real _yValue: _activeVehicle.vibration.yAxis.rawValue
    property real _zValue: _activeVehicle.vibration.zAxis.rawValue

    readonly property real _barMinimum:  0.0
    readonly property real _barMaximum:  90.0
    readonly property real _barBadValue: 60.0
    readonly property real _barMidValue: 30.0

    // ------------------ Responsive ------------------
    readonly property real _fontH: ScreenTools.defaultFontPixelHeight
    readonly property real _fontW: ScreenTools.defaultFontPixelWidth

    readonly property bool _compact: ScreenTools.isMobile || availableWidth < 900 || availableHeight < 700

    readonly property real _sidePad: Math.max(10, _fontW * (_compact ? 1.0 : 1.6))
    readonly property real _gap:     Math.max(8,  _fontH * (_compact ? 0.55 : 0.85))

    readonly property real _titlePt: _compact ? 16 : 20
    readonly property real _descPt:  _compact ? 10 : 12

    readonly property real _barWidth:  Math.max(46, _fontW * (_compact ? 6 : 8))
    readonly property real _barHeight: Math.max(150, _fontH * (_compact ? 9 : 13))

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    // ---- Popout (MAVLink Konsol / Inspector ilə eyni yanaşma)
    property var _popoutWindow: null

    onPopout: {
        if (!_popoutWindow) {
            _popoutWindow = popoutWindowComponent.createObject(null)
        }
        _popoutWindow.visible = true
        _popoutWindow.raise()
        _popoutWindow.requestActivate()
    }

    Component {
        id: popoutWindowComponent

        Window {
            id: popoutWindow
            width:   900
            height:  620
            visible: false
            title:   qsTr("Vibrasiya")
            color:   "#000000"

            Loader {
                anchors.fill: parent
                sourceComponent: pageComponent
            }

            onClosing: function(close) {
                vibrationPage._popoutWindow = null
                close.accepted = true
                Qt.callLater(function() { popoutWindow.destroy() })
            }
        }
    }

    // ================== HEADER ==================
    Component {
        id: headerComponent

        Item {
            anchors.left:   parent.left
            anchors.right:  parent.right
            implicitHeight: headerCol.implicitHeight

            ColumnLayout {
                id: headerCol
                anchors.left:         parent.left
                anchors.right:        parent.right
                anchors.leftMargin:   vibrationPage._sidePad
                anchors.rightMargin:  vibrationPage._sidePad
                anchors.topMargin:    0
                anchors.bottomMargin: Math.max(6, vibrationPage._gap * 0.5)
                spacing:              Math.max(4, vibrationPage._fontH * 0.22)

                QGCLabel {
                    text:                qsTr("Vibrasiya")
                    color:               "white"
                    font.bold:           true
                    font.pointSize:      vibrationPage._titlePt
                    wrapMode:            Text.WordWrap
                    Layout.fillWidth:    true
                    Layout.minimumWidth: 0
                }

                QGCLabel {
                    text:                qsTr("Təyyarənizin akselerometr vibrasiya səviyyələrini və klip sayğaclarını izləyin.")
                    color:               "#CCCCCC"
                    font.pointSize:      vibrationPage._descPt
                    wrapMode:            Text.WordWrap
                    Layout.fillWidth:    true
                    Layout.minimumWidth: 0
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:  1
                    color:   "white"
                    opacity: 0.18
                }
            }
        }
    }

    // ==========================================================
    // Bir ox üçün vibrasiya sütunu
    // ==========================================================
    component VibrationBar: ColumnLayout {
        id: vbar

        property string axisName: ""
        property real   value:    0
        property real   barW:     50
        property real   barH:     160

        spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.35)

        // Səviyyəyə görə rəng: 30-a qədər normal, 60-a qədər xəbərdarlıq, sonra kritik
        readonly property color barColor: value >= vibrationPage._barBadValue ? "#E53935"
                                          : (value >= vibrationPage._barMidValue ? "#FFB300" : "#00C853")

        Rectangle {
            Layout.alignment:       Qt.AlignHCenter
            Layout.preferredWidth:  vbar.barW
            Layout.preferredHeight: vbar.barH
            radius:       6
            color:        "#2A2A2A"
            border.width: 1
            border.color: "#4A4A4A"
            clip:         true

            // Dolum
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.margins: 2
                radius: 4
                height: (parent.height - 4) *
                        (Math.min(vibrationPage._barMaximum, Math.max(0, vbar.value)) /
                         (vibrationPage._barMaximum - vibrationPage._barMinimum))
                color:  vbar.barColor

                Behavior on height { NumberAnimation { duration: 120 } }
                Behavior on color  { ColorAnimation  { duration: 160 } }
            }

            // Kritik həd xətti (60)
            Rectangle {
                anchors.left:      parent.left
                anchors.right:     parent.right
                anchors.top:       parent.top
                anchors.topMargin: parent.height *
                                   (1.0 - ((vibrationPage._barBadValue - vibrationPage._barMinimum) /
                                           (vibrationPage._barMaximum - vibrationPage._barMinimum)))
                height:  1
                color:   "#E53935"
                opacity: 0.85
            }

            // Xəbərdarlıq həddi xətti (30)
            Rectangle {
                anchors.left:      parent.left
                anchors.right:     parent.right
                anchors.top:       parent.top
                anchors.topMargin: parent.height *
                                   (1.0 - ((vibrationPage._barMidValue - vibrationPage._barMinimum) /
                                           (vibrationPage._barMaximum - vibrationPage._barMinimum)))
                height:  1
                color:   "#FFB300"
                opacity: 0.75
            }
        }

        QGCLabel {
            Layout.alignment: Qt.AlignHCenter
            text:             vbar.axisName
            color:            "#B9B9B9"
        }

        QGCLabel {
            Layout.alignment: Qt.AlignHCenter
            text:             vbar.value.toFixed(0)
            color:            vbar.barColor
            font.bold:        true
        }
    }

    // ==========================================================
    // Səhifə məzmunu
    // ==========================================================
    Component {
        id: pageComponent

        Item {
            id: pageRoot
            anchors.fill: parent

            implicitWidth:  700
            implicitHeight: 460

            GridLayout {
                id: blockGrid
                anchors.left:        parent.left
                anchors.right:       parent.right
                anchors.top:         parent.top
                anchors.leftMargin:  vibrationPage._sidePad
                anchors.rightMargin: vibrationPage._sidePad
                columns:             vibrationPage._compact ? 1 : 2
                columnSpacing:       vibrationPage._gap
                rowSpacing:          vibrationPage._gap

                // ---------------- Vibrasiya səviyyələri ----------------
                Rectangle {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: levelCol.implicitHeight + vibrationPage._gap * 2
                    radius:       12
                    color:        "#3D3B3B"
                    border.width: 1
                    border.color: "#9D9D9D"

                    ColumnLayout {
                        id: levelCol
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: vibrationPage._gap
                        spacing:         vibrationPage._gap * 0.8

                        QGCLabel {
                            Layout.fillWidth: true
                            text:             qsTr("Vibrasiya Səviyyələri")
                            color:            "white"
                            font.bold:        true
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing:          Math.max(14, vibrationPage._fontW * 3)

                            VibrationBar {
                                axisName: qsTr("X")
                                value:    vibrationPage._xValue
                                barW:     vibrationPage._barWidth
                                barH:     vibrationPage._barHeight
                            }

                            VibrationBar {
                                axisName: qsTr("Y")
                                value:    vibrationPage._yValue
                                barW:     vibrationPage._barWidth
                                barH:     vibrationPage._barHeight
                            }

                            VibrationBar {
                                axisName: qsTr("Z")
                                value:    vibrationPage._zValue
                                barW:     vibrationPage._barWidth
                                barH:     vibrationPage._barHeight
                            }
                        }

                        // Şkala izahı
                        RowLayout {
                            Layout.fillWidth:  true
                            Layout.topMargin:  4
                            spacing:           Math.max(10, vibrationPage._fontW * 1.4)

                            Repeater {
                                model: [
                                    { c: "#00C853", t: qsTr("Normal (< 30)")      },
                                    { c: "#FFB300", t: qsTr("Xəbərdarlıq (30-60)") },
                                    { c: "#E53935", t: qsTr("Kritik (> 60)")      }
                                ]

                                RowLayout {
                                    spacing: 6

                                    Rectangle {
                                        width:  10
                                        height: 10
                                        radius: 2
                                        color:  modelData.c
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    QGCLabel {
                                        text:             modelData.t
                                        color:            "#B9B9B9"
                                        font.pointSize:   vibrationPage._descPt
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------------- Klip sayğacları ----------------
                Rectangle {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: clipCol.implicitHeight + vibrationPage._gap * 2
                    Layout.alignment:       Qt.AlignTop
                    radius:       12
                    color:        "#3D3B3B"
                    border.width: 1
                    border.color: "#9D9D9D"

                    ColumnLayout {
                        id: clipCol
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: vibrationPage._gap
                        spacing:         vibrationPage._gap * 0.6

                        QGCLabel {
                            Layout.fillWidth: true
                            text:             qsTr("Klip Sayğacları")
                            color:            "white"
                            font.bold:        true
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            text:      qsTr("Klip hadisələri akselerometrin ölçmə həddini aşdığını göstərir. Sıfırdan böyük dəyərlər mexaniki izolyasiyanın yaxşılaşdırılmasını tələb edir.")
                            color:     "#B9B9B9"
                            wrapMode:  Text.WordWrap
                            font.pointSize: vibrationPage._descPt
                        }

                        Repeater {
                            model: [
                                { n: qsTr("Akselerometr 1"), v: _activeVehicle.vibration.clipCount1.rawValue },
                                { n: qsTr("Akselerometr 2"), v: _activeVehicle.vibration.clipCount2.rawValue },
                                { n: qsTr("Akselerometr 3"), v: _activeVehicle.vibration.clipCount3.rawValue }
                            ]

                            Rectangle {
                                Layout.fillWidth:       true
                                Layout.preferredHeight: Math.max(40, vibrationPage._fontH * 2.2)
                                radius: 8
                                color:  "#2A2A2A"

                                QGCLabel {
                                    anchors.left:           parent.left
                                    anchors.leftMargin:     vibrationPage._gap
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:                   modelData.n
                                    color:                  "#FFFFFF"
                                }

                                QGCLabel {
                                    anchors.right:          parent.right
                                    anchors.rightMargin:    vibrationPage._gap
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:                   modelData.v
                                    color:                  modelData.v > 0 ? "#FFB300" : "#00C853"
                                    font.bold:              true
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- Məlumat yoxdur ----------------
            Rectangle {
                anchors.fill: parent
                color:        "#000000"
                opacity:      0.72
                visible:      !vibrationPage._available

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.AllButtons
                    onWheel: (wheel) => { wheel.accepted = true }
                }

                QGCLabel {
                    anchors.centerIn:    parent
                    width:               parent.width * 0.7
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode:            Text.WordWrap
                    color:               "#E4E4E4"
                    font.bold:           true
                    text:                qsTr("Vibrasiya məlumatı mövcud deyil")
                }
            }
        }
    }
}

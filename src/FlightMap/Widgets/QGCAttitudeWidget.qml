


// //                 QGCLabel {
// //                     anchors.centerIn: parent
// //                     text: vehicle ? _pitchAngle.toFixed(1) + "°" : "---"
// //                     color: "white"
// //                     font.pixelSize: 11
// //                     font.bold: true
// //                     font.family: "Monospace"
// //                 }
// //             }
// //         }
// //     }
// // }




















import QtQuick
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    property bool showPitch:    true
    property var  vehicle:      null
    property real size:         200
    property bool showHeading:  false

    // ✅ Target indicator (GoTo / WP)
    property bool  targetIndicatorEnabled: false
    property real  targetAngleDeg: NaN
    property bool  targetOnCourse: false
    property color targetColor: "#00BFFF"



    // ============================================================
    // Units conversion
    // ============================================================
    property var _unitsConversion: QGroundControl.unitsConversion

    property real _rollAngle:      vehicle ? vehicle.roll.rawValue            : 0
    property real _pitchAngle:     vehicle ? vehicle.pitch.rawValue           : 0
    property real _groundSpeedRaw: vehicle && vehicle.groundSpeed
                                   ? vehicle.groundSpeed.rawValue            : 0 // m/s
    property real _altRelRaw:      vehicle && vehicle.altitudeRelative
                                   ? vehicle.altitudeRelative.rawValue       : 0 // m

    property real _groundSpeedDisplay: _unitsConversion
                                       ? _unitsConversion.metersSecondToAppSettingsSpeedUnits(_groundSpeedRaw)
                                       : _groundSpeedRaw
    property real _altRelDisplay:      _unitsConversion
                                       ? _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altRelRaw)
                                       : _altRelRaw

    property string _speedUnits: _unitsConversion ? _unitsConversion.appSettingsSpeedUnitsString : "m/s"
    property string _altUnits:   _unitsConversion ? _unitsConversion.appSettingsVerticalDistanceUnitsString : "m"

    width:  size
    height: size

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    // UI ölçüləri (sənin “evvelki kimi” görünüşə yaxın)
    readonly property real _titlePx: Math.max(12, size * 0.055)
    readonly property real _valuePx: Math.max(10, size * 0.045)

    readonly property real _scaleW:  Math.max(80, size * 0.30)
    readonly property real _scaleH:  Math.max(40, size * 0.16)

    readonly property real _boxH:    Math.max(18, size * 0.070)
    readonly property real _boxWAlt: Math.max(50, size * 0.18)
    readonly property real _boxWSpd: Math.max(60, size * 0.21)

    // köhnə layout-a bənzər ofsetlər
    readonly property real _topOfs:  -Math.max(27, size * 0.10)
    readonly property real _sideOfs: -Math.max(60, size * 0.23)

    // ROLL/PITCH ölçüləri
    readonly property real _rpLabelPx: Math.max(10, size * 0.048)
    readonly property real _rpSpacing: size * 0.020
    readonly property real _rpLabelW:  size * 0.19
    readonly property real _rpBoxW:    size * 0.18
    readonly property real _rpBoxH:    size * 0.070

    Item {
        id: instrument
        anchors.fill: parent
        visible: false

        // Artificial Horizon
        QGCArtificialHorizon {
            rollAngle:  _rollAngle
            pitchAngle: _pitchAngle
            anchors.fill: parent
        }

        // Dial (roll ilə fırlanır)
        Image {
            id: instrumentDial
            source: "/qmlimages/attitudeDial.svg"
            mipmap: true
            fillMode: Image.PreserveAspectFit
            anchors.fill: parent
            sourceSize.height: parent.height
            transform: Rotation {
                origin.x: root.width  / 2
                origin.y: root.height / 2
                angle:    -_rollAngle
            }
        }

        // Pitch indicator
        QGCPitchIndicator {
            visible: root.showPitch
            size: root.size * 0.5
            anchors.verticalCenter: parent.verticalCenter
            pitchAngle: _pitchAngle
            rollAngle:  _rollAngle
            color: Qt.rgba(0,0,0,0)
        }

        // CrossHair
        Image {
            id: crossHair
            anchors.centerIn: parent
            source: "/qmlimages/crossHair.svg"
            mipmap: true
            width: root.size * 0.60
            sourceSize.width: width
            fillMode: Image.PreserveAspectFit
        }

        // ✅ TARGET TRIANGLE (GoTo/WP) — dairənin içində, ring-ə yaxın
        Item {
            id: targetIndicatorLayer
            anchors.fill: parent
            z: 2

            readonly property bool _haveTarget: root.targetIndicatorEnabled && !isNaN(root.targetAngleDeg)
            readonly property color _c: _haveTarget
                                      ? (root.targetOnCourse ? "#00FF00" : root.targetColor)
                                      : "#EE3424"   // target yoxdursa əvvəlki kimi qırmızı yuxarıda qalsın

            // Bu layer fırlanır, triangle yuxarıdadır -> nəticədə triangle dairə boyunca gedir
            transform: Rotation {
                origin.x: targetIndicatorLayer.width  / 2
                origin.y: targetIndicatorLayer.height / 2
                angle: targetIndicatorLayer._haveTarget ? root.targetAngleDeg : 0
            }

            Canvas {
                id: targetTriangle
                width:  root.size * 0.085
                height: root.size * 0.065
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.size * 0.025    // ring-ə yaxın (istəsən 0.02..0.05 arası oynat)

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0,0,width,height)

                    ctx.fillStyle = targetIndicatorLayer._c
                    ctx.strokeStyle = "#000000"
                    ctx.lineWidth = 2

                    ctx.beginPath()
                    ctx.moveTo(width/2, 0)
                    ctx.lineTo(0, height)
                    ctx.lineTo(width, height)
                    ctx.closePath()
                    ctx.fill()
                    ctx.stroke()
                }

                onWidthChanged:  requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()
            }
        }

        // ============================================================
        // ✅ SPD (sağ) — köhnə yerləşim kimi
        // ============================================================
        Item {
            id: speedScale
            width:  root._scaleW
            height: root._scaleH
            anchors.top: crossHair.bottom
            anchors.topMargin: root._topOfs
            anchors.right: crossHair.right
            anchors.rightMargin: root._sideOfs
            z: 20

            QGCLabel {
                id: spdTitle
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SPD"
                color: "white"
                font.pixelSize: root._titlePx
                font.bold: true
            }

            Rectangle {
                width:  root._boxWSpd
                height: root._boxH
                anchors.top: spdTitle.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#000000"
                radius: 3
                opacity: 1

                QGCLabel {
                    anchors.centerIn: parent
                    text: vehicle ? (root._groundSpeedDisplay.toFixed(1) + " " + root._speedUnits)
                                 : ("-- " + root._speedUnits)
                    color: "#FFFFFF"
                    font.pixelSize: root._valuePx
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ============================================================
        // ✅ ALT (sol) — köhnə yerləşim kimi
        // ============================================================
        Item {
            id: altitudeScale
            width:  root._scaleW
            height: root._scaleH
            anchors.top: crossHair.bottom
            anchors.topMargin: root._topOfs
            anchors.left: crossHair.left
            anchors.leftMargin: root._sideOfs
            z: 20

            QGCLabel {
                id: altTitle
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ALT"
                color: "white"
                font.pixelSize: root._titlePx
                font.bold: true
            }

            Rectangle {
                width:  root._boxWAlt
                height: root._boxH
                anchors.top: altTitle.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#000000"
                radius: 3
                opacity: 1

                QGCLabel {
                    anchors.centerIn: parent
                    text: vehicle ? (root._altRelDisplay.toFixed(1) + " " + root._altUnits)
                                 : ("-- " + root._altUnits)
                    color: "#FFFFFF"
                    font.pixelSize: root._valuePx
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ============================================================
        // ✅ ROLL / PITCH (aşağıda)
        // ============================================================
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.size * 0.070
            spacing: root.size * 0.020
            z: 25

            Row {
                width: root._rpLabelW + root._rpSpacing + root._rpBoxW
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root._rpSpacing

                Item {
                    width: root._rpLabelW
                    height: root._rpBoxH
                    QGCLabel {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ROLL:"
                        color: "#FFFFFF"
                        font.pixelSize: root._rpLabelPx
                        font.bold: true
                        font.family: "Monospace"
                    }
                }

                Rectangle {
                    width:  root._rpBoxW
                    height: root._rpBoxH
                    color: "#000000"
                    radius: 3
                    border.color: "#00FF00"
                    border.width: 1

                    QGCLabel {
                        anchors.centerIn: parent
                        text: vehicle ? (root._rollAngle.toFixed(1) + "°") : "---"
                        color: "white"
                        font.pixelSize: root._rpLabelPx
                        font.bold: true
                        font.family: "Monospace"
                    }
                }
            }

            Row {
                width: root._rpLabelW + root._rpSpacing + root._rpBoxW
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root._rpSpacing

                Item {
                    width: root._rpLabelW
                    height: root._rpBoxH
                    QGCLabel {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PITCH:"
                        color: "#FFFFFF"
                        font.pixelSize: root._rpLabelPx
                        font.bold: true
                        font.family: "Monospace"
                    }
                }

                Rectangle {
                    width:  root._rpBoxW
                    height: root._rpBoxH
                    color: "#000000"
                    radius: 3
                    border.color: "#00FF00"
                    border.width: 1

                    QGCLabel {
                        anchors.centerIn: parent
                        text: vehicle ? (root._pitchAngle.toFixed(1) + "°") : "---"
                        color: "white"
                        font.pixelSize: root._rpLabelPx
                        font.bold: true
                        font.family: "Monospace"
                    }
                }
            }
        }
    }

    // Mask
    MultiEffect {
        source: instrument
        anchors.fill: instrument
        maskEnabled: true
        maskSource: mask
    }

    Item {
        id: mask
        width: instrument.width
        height: instrument.height
        layer.enabled: true
        visible: false

        Rectangle {
            width: parent.width
            height: parent.height
            radius: width/2
            color: "black"
        }
    }

    // Border
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(0,0,0,0)
        border.color: qgcPal.text
        border.width: 1
    }

    // Optional heading text
    QGCLabel {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(ScreenTools.defaultFontPixelHeight * .75)
        anchors.horizontalCenter: parent.horizontalCenter
        visible: showHeading
        color: "white"
        text: {
            var h = vehicle ? Math.round(vehicle.heading.rawValue) : NaN
            return isNaN(h) ? "OFF" : (h + "°")
        }
    }
}

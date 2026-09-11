// //-------isleyenkod----

// /**
//  * @file
//  *   @brief QGC Attitude Instrument
//  *   @author Gus Grubba <gus@auterion.com>
//  */

// // import QtQuick
// // import QtQuick.Effects

// // import QGroundControl
// // import QGroundControl.Controls

// // Item {
// //     id: root

// //     property bool showPitch:    true
// //     property var  vehicle:      null
// //     property real size
// //     property bool showHeading:  false

// //     // QGC global unit conversion
// //     property var  _unitsConversion: QGroundControl.unitsConversion

// //     // Temel değerler (ham)
// //     property real _rollAngle:       vehicle ? vehicle.roll.rawValue        : 0
// //     property real _pitchAngle:      vehicle ? vehicle.pitch.rawValue       : 0
// //     property real _airSpeedRaw:     vehicle && vehicle.airSpeed        ? vehicle.airSpeed.rawValue        : 0   // m/s
// //     property real _groundSpeedRaw:  vehicle && vehicle.groundSpeed     ? vehicle.groundSpeed.rawValue     : 0   // m/s
// //     property real _altitudeRelRaw:  vehicle && vehicle.altitudeRelative ? vehicle.altitudeRelative.rawValue : 0 // m (relative)

// //     // Ekranda gösterilecek hız (QGC speed units)
// //     property real  _groundSpeedDisplay: _unitsConversion
// //                                         ? _unitsConversion.metersSecondToAppSettingsSpeedUnits(_groundSpeedRaw)
// //                                         : _groundSpeedRaw
// //     // Ekranda gösterilecek irtifa (QGC vertical distance units)
// //     property real  _altitudeRelDisplay: _unitsConversion
// //                                         ? _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altitudeRelRaw)
// //                                         : _altitudeRelRaw

// //     property string _speedUnits:    _unitsConversion
// //                                     ? _unitsConversion.appSettingsSpeedUnitsString
// //                                     : "m/s"
// //     property string _altUnits:      _unitsConversion
// //                                     ? _unitsConversion.appSettingsVerticalDistanceUnitsString
// //                                     : "m"

// //     width:  size
// //     height: size

// //     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

// //     Item {
// //         id:             instrument
// //         anchors.fill:   parent
// //         visible:        false

// //         //----------------------------------------------------
// //         //-- Artificial Horizon
// //         QGCArtificialHorizon {
// //             rollAngle:          _rollAngle
// //             pitchAngle:         _pitchAngle
// //             anchors.fill:       parent
// //         }

// //         //----------------------------------------------------
// //         //-- Pointer
// //         Image {
// //             id:                 pointer
// //             source:             "/qmlimages/attitudePointer.svg"
// //             mipmap:             true
// //             fillMode:           Image.PreserveAspectFit
// //             anchors.centerIn:   parent
// //             width:              parent.width * 0.9
// //             height:             parent.height * 0.7
// //             sourceSize.height:  parent.height
// //             rotation:           180
// //             transform: Translate {
// //                 y: -185
// //             }
// //         }

// //         //----------------------------------------------------
// //         //-- Instrument Dial
// //         Image {
// //             id:                 instrumentDial
// //             source:             "/qmlimages/attitudeDial.svg"
// //             mipmap:             true
// //             fillMode:           Image.PreserveAspectFit
// //             anchors.fill:       parent
// //             sourceSize.height:  parent.height
// //             transform: Rotation {
// //                 origin.x:       root.width  / 2
// //                 origin.y:       root.height / 2
// //                 angle:          -_rollAngle
// //             }
// //         }

// //         //----------------------------------------------------
// //         //-- Pitch
// //         QGCPitchIndicator {
// //             id:                     pitchWidget
// //             visible:                root.showPitch
// //             size:                   root.size * 0.5
// //             anchors.verticalCenter: parent.verticalCenter
// //             pitchAngle:             _pitchAngle
// //             rollAngle:              _rollAngle
// //             color:                  Qt.rgba(0,0,0,0)
// //         }

// //         //----------------------------------------------------
// //         //-- Cross Hair
// //         Image {
// //             id:                 crossHair
// //             anchors.centerIn:   parent
// //             source:             "/qmlimages/crossHair.svg"
// //             mipmap:             true
// //             width:              size * 0.60
// //             sourceSize.width:   width
// //             fillMode:           Image.PreserveAspectFit
// //         }

// //         //----------------------------------------------------
// //         //-- Ground Speed Göstergesi (sağ altta) - TEXT SABİT, DEĞER KUTU İÇİNDE
// //         Item {
// //             id: speedScale
// //             width: 80
// //             height: 40

// //             anchors.top:         crossHair.bottom
// //             anchors.topMargin:   -27
// //             anchors.right:       crossHair.right
// //             anchors.rightMargin: -60

// //             // Başlık (yerini koruyoruz)
// //             QGCLabel {
// //                 id: speedTitle
// //                 anchors.top: parent.top
// //                 anchors.topMargin: 2
// //                 anchors.horizontalCenter: parent.horizontalCenter
// //                 text: "SPD"
// //                 color: "white"
// //                 font.pixelSize: 13
// //                 font.bold: true
// //             }

// //             // Değer için textbox
// //             Rectangle {
// //                 id: speedBox
// //                 width:  50
// //                 height: 18
// //                 anchors.top: speedTitle.bottom
// //                 anchors.topMargin: 4
// //                 anchors.horizontalCenter: parent.horizontalCenter
// //                 color: "#000000"
// //                 radius: 3
// //                 opacity: 1

// //                 QGCLabel {
// //                     id: speedValue
// //                     anchors.centerIn: parent
// //                     text: vehicle
// //                           ? _groundSpeedDisplay.toFixed(1) + " " + _speedUnits
// //                           : "-- " + _speedUnits
// //                     color: "#FFFFFF"
// //                     font.pixelSize: 11
// //                     font.bold: true
// //                     horizontalAlignment: Text.AlignHCenter
// //                 }
// //             }
// //         }

// //         //----------------------------------------------------
// //         //-- Altitude (Relative) Göstergesi (sol altta) - TEXT SABİT, DEĞER KUTU İÇİNDE
// //         Item {
// //             id: altitudeScale
// //             width: 80
// //             height: 40

// //             anchors.top:       crossHair.bottom
// //             anchors.topMargin: -27
// //             anchors.left:      crossHair.left
// //             anchors.leftMargin: -60

// //             // Başlık (yerini koruyoruz)
// //             QGCLabel {
// //                 id: altitudeTitle
// //                 anchors.top: parent.top
// //                 anchors.topMargin: 2
// //                 anchors.horizontalCenter: parent.horizontalCenter
// //                 text: "ALT"
// //                 color: "white"
// //                 font.pixelSize: 13
// //                 font.bold: true
// //             }

// //             // Değer için textbox
// //             Rectangle {
// //                 id: altitudeBox
// //                 width:  50
// //                 height: 18
// //                 anchors.top: altitudeTitle.bottom
// //                 anchors.topMargin: 4
// //                 anchors.horizontalCenter: parent.horizontalCenter
// //                 color: "#000000"
// //                 radius: 3
// //                 opacity: 1

// //                 QGCLabel {
// //                     id: altitudeValue
// //                     anchors.centerIn: parent
// //                     text: vehicle
// //                           ? _altitudeRelDisplay.toFixed(1) + " " + _altUnits
// //                           : "-- " + _altUnits
// //                     color: "#FFFFFF"
// //                     font.pixelSize: 11
// //                     font.bold: true
// //                     horizontalAlignment: Text.AlignHCenter
// //                 }
// //             }
// //         }
// //     }

// //     MultiEffect {
// //         source: instrument
// //         anchors.fill: instrument
// //         maskEnabled: true
// //         maskSource: mask
// //     }

// //     Item {
// //         id: mask
// //         width: instrument.width
// //         height: instrument.height
// //         layer.enabled: true
// //         visible: false

// //         Rectangle {
// //             width: parent.width
// //             height: parent.height
// //             radius: width/2
// //             color: "black"
// //         }
// //     }

// //     Rectangle {
// //         id:             borderRect
// //         anchors.fill:   parent
// //         radius:         width / 2
// //         color:          Qt.rgba(0,0,0,0)
// //         border.color:   qgcPal.text
// //         border.width:   1
// //     }

// //     QGCLabel {
// //         anchors.bottomMargin:       Math.round(ScreenTools.defaultFontPixelHeight * .75)
// //         anchors.bottom:             parent.bottom
// //         anchors.horizontalCenter:   parent.horizontalCenter
// //         text:                       _headingString3
// //         color:                      "white"
// //         visible:                    showHeading

// //         property string _headingString:  vehicle ? vehicle.heading.rawValue.toFixed(0) : "OFF"
// //         property string _headingString2: _headingString.length === 1 ? "0" + _headingString : _headingString
// //         property string _headingString3: _headingString2.length === 2 ? "0" + _headingString2 : _headingString2
// //     }

// //     //----------------------------------------------------
// //     // -- Roll / Pitch Göstergeleri: ALT ALTA + VALUE TEXTBOX
// //     //-- Roll Değeri Göstergesi
// //     Rectangle {
// //         id: rollDisplay
// //         height: 28
// //         color: "#000000"
// //         opacity: 1
// //         radius: 3
// //         border.color: "#00FF00"
// //         border.width: 1

// //         anchors.top: parent.top
// //         anchors.topMargin: 188
// //         anchors.left: parent.left
// //         anchors.leftMargin: 132

// //         Row {
// //             anchors.centerIn: parent
// //             spacing: 5

// //             // ROLL: yazısı
// //             QGCLabel {
// //                 text: "ROLL: "
// //                 color: "#FFFFFF"
// //                 font.pixelSize: 11
// //                 font.bold: true
// //                 font.family: "Monospace"
// //                 verticalAlignment: Text.AlignVCenter
// //             }

// //             // Roll değeri textbox içinde
// //             Rectangle {
// //                 id: rollValueBox
// //                 width: 45
// //                 height: 15
// //                 color: "black"
// //                 radius: 3


// //                 QGCLabel {
// //                     anchors.centerIn: parent
// //                     text: vehicle ? _rollAngle.toFixed(1) + "°" : "---"
// //                     color: "white"
// //                     font.pixelSize: 11
// //                     font.bold: true
// //                     font.family: "Monospace"
// //                 }
// //             }
// //         }
// //     }

// //     //----------------------------------------------------
// //     //-- Pitch Değeri Göstergesi
// //     //-- Pitch Değeri Göstergesi
// //     Rectangle {
// //         id: pitchDisplay
// //         height: 28
// //         color: "#000000"
// //         opacity: 1
// //         radius: 3
// //         border.color: "#00FF00"
// //         border.width: 1

// //         anchors.top: rollDisplay.bottom
// //         anchors.topMargin: -5
// //         anchors.left: parent.left
// //         anchors.leftMargin: 130

// //         Row {
// //             anchors.centerIn: parent
// //             spacing: 5

// //             // PITCH: yazısı
// //             QGCLabel {
// //                 text: "PITCH:"
// //                 color: "#FFFFFF"
// //                 font.pixelSize: 11
// //                 font.bold: true
// //                 font.family: "Monospace"
// //                 verticalAlignment: Text.AlignVCenter
// //             }

// //             // Pitch değeri textbox içinde
// //             Rectangle {
// //                 id: pitchValueBox
// //                 width: 45
// //                 height: 15
// //                 color: "black"
// //                 radius: 3


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










// //---------------------androidkod-------------
// // import QtQuick
// // import QtQuick.Effects

// // import QGroundControl
// // import QGroundControl.Controls

// // Item {
// //     id: root

// //     property bool showPitch:    true
// //     property var  vehicle:      null
// //     property real size
// //     property bool showHeading:  false

// //     property var  _unitsConversion: QGroundControl.unitsConversion

// //     property real _rollAngle:       vehicle ? vehicle.roll.rawValue : 0
// //     property real _pitchAngle:      vehicle ? vehicle.pitch.rawValue : 0
// //     property real _groundSpeedRaw:  vehicle && vehicle.groundSpeed ? vehicle.groundSpeed.rawValue : 0
// //     property real _altitudeRelRaw:  vehicle && vehicle.altitudeRelative ? vehicle.altitudeRelative.rawValue : 0

// //     property real _groundSpeedDisplay: _unitsConversion
// //                                        ? _unitsConversion.metersSecondToAppSettingsSpeedUnits(_groundSpeedRaw)
// //                                        : _groundSpeedRaw
// //     property real _altitudeRelDisplay: _unitsConversion
// //                                        ? _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altitudeRelRaw)
// //                                        : _altitudeRelRaw

// //     property string _speedUnits: _unitsConversion ? _unitsConversion.appSettingsSpeedUnitsString : "m/s"
// //     property string _altUnits:   _unitsConversion ? _unitsConversion.appSettingsVerticalDistanceUnitsString : "m"

// //     width:  size
// //     height: size

// //     // responsiv şriftlər
// //     readonly property real _t:     Math.max(10, size * 0.055)   // ALT/SPD title
// //     readonly property real _v:     Math.max(9,  size * 0.050)   // value
// //     readonly property real _label: Math.max(10, size * 0.048)   // ROLL/PITCH label

// //     // ALT/SPD yerləşim parametrləri
// //     readonly property real _lrXOffset:       root.size * 0.325   // mərkəzdən uzaq (kənara)
// //     readonly property real _pairShiftRight:  root.size * 0.040   // cütlük birlikdə sağa
// //     readonly property real _altExtraLeft:    root.size * 0.030   // ✅ yalnız ALT bir az sola

// //     readonly property real _titleY: -root.size * 0.085          // title göy hissədə
// //     readonly property real _valueY:  root.size * 0.055          // value yaşıl hissədə

// //     // ROLL/PITCH simmetriya ölçüləri
// //     readonly property real _rpSpacing:  root.size * 0.02
// //     readonly property real _rpLabelW:   root.size * 0.19
// //     readonly property real _rpBoxW:     root.size * 0.18
// //     readonly property real _rpBoxH:     root.size * 0.070

// //     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

// //     Item {
// //         id:             instrument
// //         anchors.fill:   parent
// //         visible:        false

// //         QGCArtificialHorizon {
// //             rollAngle:          _rollAngle
// //             pitchAngle:         _pitchAngle
// //             anchors.fill:       parent
// //         }

// //         // ❌ Yaşıl hissədə görünən qırmızı üçbucaq burdan gəlirdi — söndürülüb
// //         Image {
// //             id:                 pointer
// //             visible:            false
// //             source:             "/qmlimages/attitudePointer.svg"
// //             mipmap:             true
// //             fillMode:           Image.PreserveAspectFit
// //             anchors.centerIn:   parent
// //             width:              parent.width * 0.9
// //             height:             parent.height * 0.7
// //             sourceSize.height:  parent.height
// //             rotation:           180
// //             transform: Translate { y: -root.size * 0.18 }
// //         }

// //         Image {
// //             id:                 instrumentDial
// //             source:             "/qmlimages/attitudeDial.svg"
// //             mipmap:             true
// //             fillMode:           Image.PreserveAspectFit
// //             anchors.fill:       parent
// //             sourceSize.height:  parent.height
// //             transform: Rotation {
// //                 origin.x:       root.width  / 2
// //                 origin.y:       root.height / 2
// //                 angle:          -_rollAngle
// //             }
// //         }

// //         QGCPitchIndicator {
// //             id:                     pitchWidget
// //             visible:                root.showPitch
// //             size:                   root.size * 0.5
// //             anchors.verticalCenter: parent.verticalCenter
// //             pitchAngle:             _pitchAngle
// //             rollAngle:              _rollAngle
// //             color:                  Qt.rgba(0,0,0,0)
// //         }

// //         Image {
// //             id:                 crossHair
// //             anchors.centerIn:   parent
// //             source:             "/qmlimages/crossHair.svg"
// //             mipmap:             true
// //             width:              size * 0.60
// //             sourceSize.width:   width
// //             fillMode:           Image.PreserveAspectFit
// //         }

// //         // ✅ SABİT İÇ ÜÇBUCAQ — bir az yuxarı çəkildi (ucu N-ə baxır)
// //         Canvas {
// //             id: fixedNoseTriangle
// //             width:  root.size * 0.085
// //             height: root.size * 0.065
// //             anchors.horizontalCenter: parent.horizontalCenter
// //             anchors.top: parent.top
// //             anchors.topMargin: root.size * 0.075   // ✅ əvvəl 0.10 idi (yuxarı qalxdı)

// //             onPaint: {
// //                 var ctx = getContext("2d")
// //                 ctx.clearRect(0,0,width,height)
// //                 ctx.fillStyle = "#EE3424"
// //                 ctx.beginPath()
// //                 ctx.moveTo(width/2, 0)
// //                 ctx.lineTo(0, height)
// //                 ctx.lineTo(width, height)
// //                 ctx.closePath()
// //                 ctx.fill()
// //             }
// //         }

// //         // ===== ALT (sol) =====
// //         Item {
// //             id: altGroup
// //             anchors.centerIn: parent
// //             readonly property real _baseX: (-root._lrXOffset + root._pairShiftRight - root._altExtraLeft)

// //             QGCLabel {
// //                 text: "ALT"
// //                 color: "white"
// //                 font.pixelSize: root._t
// //                 font.bold: true
// //                 x: altGroup._baseX - (contentWidth / 2)
// //                 y: root._titleY
// //             }

// //             Rectangle {
// //                 width:  root.size * 0.22
// //                 height: root.size * 0.075
// //                 color: "#000000"
// //                 radius: 3
// //                 opacity: 1

// //                 x: altGroup._baseX - (width / 2)
// //                 y: root._valueY

// //                 QGCLabel {
// //                     anchors.centerIn: parent
// //                     text: vehicle ? _altitudeRelDisplay.toFixed(1) + " " + _altUnits : "-- " + _altUnits
// //                     color: "#FFFFFF"
// //                     font.pixelSize: root._v
// //                     font.bold: true
// //                     horizontalAlignment: Text.AlignHCenter
// //                 }
// //             }
// //         }

// //         // ===== SPD (sağ) =====
// //         Item {
// //             id: spdGroup
// //             anchors.centerIn: parent
// //             readonly property real _baseX: (root._lrXOffset + root._pairShiftRight)   // ✅ dəyişməz

// //             QGCLabel {
// //                 text: "SPD"
// //                 color: "white"
// //                 font.pixelSize: root._t
// //                 font.bold: true
// //                 x: spdGroup._baseX - (contentWidth / 2)
// //                 y: root._titleY
// //             }

// //             Rectangle {
// //                 width:  root.size * 0.26
// //                 height: root.size * 0.075
// //                 color: "#000000"
// //                 radius: 3
// //                 opacity: 1

// //                 x: spdGroup._baseX - (width / 2)
// //                 y: root._valueY

// //                 QGCLabel {
// //                     anchors.centerIn: parent
// //                     text: vehicle ? _groundSpeedDisplay.toFixed(1) + " " + _speedUnits : "-- " + _speedUnits
// //                     color: "#FFFFFF"
// //                     font.pixelSize: root._v
// //                     font.bold: true
// //                     horizontalAlignment: Text.AlignHCenter
// //                 }
// //             }
// //         }

// //         // ✅ ROLL/PITCH — alt-alta simmetrik (ölçülər eyni)
// //         Column {
// //             id: rollPitchGroup
// //             anchors.horizontalCenter: parent.horizontalCenter
// //             anchors.bottom: parent.bottom
// //             anchors.bottomMargin: root.size * 0.070
// //             spacing: root.size * 0.020

// //             Row {
// //                 width: root._rpLabelW + root._rpSpacing + root._rpBoxW
// //                 anchors.horizontalCenter: parent.horizontalCenter
// //                 spacing: root._rpSpacing

// //                 Item {
// //                     width: root._rpLabelW
// //                     height: root._rpBoxH
// //                     QGCLabel {
// //                         anchors.right: parent.right
// //                         anchors.verticalCenter: parent.verticalCenter
// //                         text: "ROLL:"
// //                         color: "#FFFFFF"
// //                         font.pixelSize: root._label
// //                         font.bold: true
// //                         font.family: "Monospace"
// //                     }
// //                 }

// //                 Rectangle {
// //                     width:  root._rpBoxW
// //                     height: root._rpBoxH
// //                     color: "#000000"
// //                     radius: 3
// //                     border.color: "#00FF00"
// //                     border.width: 1

// //                     QGCLabel {
// //                         anchors.centerIn: parent
// //                         text: vehicle ? _rollAngle.toFixed(1) + "°" : "---"
// //                         color: "white"
// //                         font.pixelSize: root._label
// //                         font.bold: true
// //                         font.family: "Monospace"
// //                     }
// //                 }
// //             }

// //             Row {
// //                 width: root._rpLabelW + root._rpSpacing + root._rpBoxW
// //                 anchors.horizontalCenter: parent.horizontalCenter
// //                 spacing: root._rpSpacing

// //                 Item {
// //                     width: root._rpLabelW
// //                     height: root._rpBoxH
// //                     QGCLabel {
// //                         anchors.right: parent.right
// //                         anchors.verticalCenter: parent.verticalCenter
// //                         text: "PITCH:"
// //                         color: "#FFFFFF"
// //                         font.pixelSize: root._label
// //                         font.bold: true
// //                         font.family: "Monospace"
// //                     }
// //                 }

// //                 Rectangle {
// //                     width:  root._rpBoxW
// //                     height: root._rpBoxH
// //                     color: "#000000"
// //                     radius: 3
// //                     border.color: "#00FF00"
// //                     border.width: 1

// //                     QGCLabel {
// //                         anchors.centerIn: parent
// //                         text: vehicle ? _pitchAngle.toFixed(1) + "°" : "---"
// //                         color: "white"
// //                         font.pixelSize: root._label
// //                         font.bold: true
// //                         font.family: "Monospace"
// //                     }
// //                 }
// //             }
// //         }
// //     }

// //     MultiEffect {
// //         source: instrument
// //         anchors.fill: instrument
// //         maskEnabled: true
// //         maskSource: mask
// //     }

// //     Item {
// //         id: mask
// //         width: instrument.width
// //         height: instrument.height
// //         layer.enabled: true
// //         visible: false

// //         Rectangle {
// //             width: parent.width
// //             height: parent.height
// //             radius: width/2
// //             color: "black"
// //         }
// //     }

// //     Rectangle {
// //         anchors.fill: parent
// //         radius: width / 2
// //         color: Qt.rgba(0,0,0,0)
// //         border.color: qgcPal.text
// //         border.width: 1
// //     }
// // }









// import QtQuick
// import QtQuick.Effects

// import QGroundControl
// import QGroundControl.Controls

// Item {
//     id: root

//     property bool showPitch:    true
//     property var  vehicle:      null
//     property real size
//     property bool showHeading:  false

//     // QGC global unit conversion
//     property var  _unitsConversion: QGroundControl.unitsConversion

//     // Temel değerler (ham)
//     property real _rollAngle:       vehicle ? vehicle.roll.rawValue : 0
//     property real _pitchAngle:      vehicle ? vehicle.pitch.rawValue : 0
//     property real _groundSpeedRaw:  vehicle && vehicle.groundSpeed ? vehicle.groundSpeed.rawValue : 0   // m/s
//     property real _altitudeRelRaw:  vehicle && vehicle.altitudeRelative ? vehicle.altitudeRelative.rawValue : 0 // m

//     // Ekranda gösterilecek hız/irtifa (QGC unit)
//     property real  _groundSpeedDisplay: _unitsConversion
//                                         ? _unitsConversion.metersSecondToAppSettingsSpeedUnits(_groundSpeedRaw)
//                                         : _groundSpeedRaw

//     property real  _altitudeRelDisplay: _unitsConversion
//                                         ? _unitsConversion.metersToAppSettingsVerticalDistanceUnits(_altitudeRelRaw)
//                                         : _altitudeRelRaw

//     property string _speedUnits: _unitsConversion ? _unitsConversion.appSettingsSpeedUnitsString : "m/s"
//     property string _altUnits:   _unitsConversion ? _unitsConversion.appSettingsVerticalDistanceUnitsString : "m"

//     width:  size
//     height: size

//     // responsiv şriftlər (səndəki kimi saxlanıldı)
//     readonly property real _t:     Math.max(10, size * 0.055)   // ALT/SPD title
//     readonly property real _v:     Math.max(9,  size * 0.050)   // value
//     readonly property real _label: Math.max(10, size * 0.048)   // ROLL/PITCH label

//     // ✅ ALT/SPD köhnə yerləşim parametrləri (crossHair.bottom-a bağlanır)
//     readonly property real _spdAltShiftX:  Math.min(Math.max(size * 0.27, 40), 80)     // ~60px
//     readonly property real _spdAltTopLift: Math.min(Math.max(size * 0.12, 18), 32)     // ~27px

//     readonly property real _spdAltGroupW:  Math.min(Math.max(size * 0.36, 80), 150)    // ~80
//     readonly property real _spdAltGroupH:  Math.min(Math.max(size * 0.18, 40), 90)     // ~40

//     readonly property real _spdAltBoxH:    Math.max(18, size * 0.075)                  // ~18
//     readonly property real _altBoxW:       Math.max(50, size * 0.22)                   // ~50
//     readonly property real _spdBoxW:       Math.max(50, size * 0.26)

//     readonly property real _titleGap:      Math.max(4,  size * 0.015)                  // ~4

//     // ✅ Sabit üçbucaq ölçüləri + kənara yapışdırma
//     readonly property real _noseTriW:      size * 0.085
//     readonly property real _noseTriH:      size * 0.065
//     readonly property real _noseTriTop:    0        // ✅ əvvəl size*0.075 idi (içəri salırdı)

//     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

//     Item {
//         id:             instrument
//         anchors.fill:   parent
//         visible:        false

//         //----------------------------------------------------
//         //-- Artificial Horizon
//         QGCArtificialHorizon {
//             rollAngle:          _rollAngle
//             pitchAngle:         _pitchAngle
//             anchors.fill:       parent
//         }

//         //----------------------------------------------------
//         //-- Pointer (səndəki kimi söndürülü)
//         Image {
//             id:                 pointer
//             visible:            false
//             source:             "/qmlimages/attitudePointer.svg"
//             mipmap:             true
//             fillMode:           Image.PreserveAspectFit
//             anchors.centerIn:   parent
//             width:              parent.width * 0.9
//             height:             parent.height * 0.7
//             sourceSize.height:  parent.height
//             rotation:           180
//             transform: Translate { y: -root.size * 0.18 }
//         }

//         //----------------------------------------------------
//         //-- Instrument Dial
//         Image {
//             id:                 instrumentDial
//             source:             "/qmlimages/attitudeDial.svg"
//             mipmap:             true
//             fillMode:           Image.PreserveAspectFit
//             anchors.fill:       parent
//             sourceSize.height:  parent.height
//             transform: Rotation {
//                 origin.x:       root.width  / 2
//                 origin.y:       root.height / 2
//                 angle:          -_rollAngle
//             }
//         }

//         //----------------------------------------------------
//         //-- Pitch
//         QGCPitchIndicator {
//             id:                     pitchWidget
//             visible:                root.showPitch
//             size:                   root.size * 0.5
//             anchors.verticalCenter: parent.verticalCenter
//             pitchAngle:             _pitchAngle
//             rollAngle:              _rollAngle
//             color:                  Qt.rgba(0,0,0,0)
//         }

//         //----------------------------------------------------
//         //-- Cross Hair
//         Image {
//             id:                 crossHair
//             anchors.centerIn:   parent
//             source:             "/qmlimages/crossHair.svg"
//             mipmap:             true
//             width:              root.size * 0.60
//             sourceSize.width:   width
//             fillMode:           Image.PreserveAspectFit
//         }

//         //----------------------------------------------------
//         //-- ✅ SABİT ÜÇBUCAQ (kənara bitişik)
//         Canvas {
//             id: fixedNoseTriangle
//             width:  root._noseTriW
//             height: root._noseTriH
//             anchors.horizontalCenter: parent.horizontalCenter
//             anchors.top: parent.top
//             anchors.topMargin: root._noseTriTop
//             z: 100

//             onPaint: {
//                 var ctx = getContext("2d")
//                 ctx.clearRect(0,0,width,height)
//                 ctx.fillStyle = "#EE3424"
//                 ctx.beginPath()
//                 ctx.moveTo(width/2, 0)
//                 ctx.lineTo(0, height)
//                 ctx.lineTo(width, height)
//                 ctx.closePath()
//                 ctx.fill()
//             }
//         }

//         //----------------------------------------------------
//         //-- ✅ ALT (sol) — köhnə kod kimi
//         Item {
//             id: altitudeScale
//             width:  root._spdAltGroupW
//             height: root._spdAltGroupH

//             anchors.top:       crossHair.bottom
//             anchors.topMargin: -root._spdAltTopLift
//             anchors.left:      crossHair.left
//             anchors.leftMargin: -root._spdAltShiftX

//             QGCLabel {
//                 id: altitudeTitle
//                 anchors.top: parent.top
//                 anchors.topMargin: Math.max(2, root.size * 0.01)
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 text: "ALT"
//                 color: "white"
//                 font.pixelSize: root._t
//                 font.bold: true
//             }

//             Rectangle {
//                 id: altitudeBox
//                 width:  root._altBoxW
//                 height: root._spdAltBoxH
//                 anchors.top: altitudeTitle.bottom
//                 anchors.topMargin: root._titleGap
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 color: "#000000"
//                 radius: 3
//                 opacity: 1

//                 QGCLabel {
//                     anchors.centerIn: parent
//                     text: vehicle
//                           ? _altitudeRelDisplay.toFixed(1) + " " + _altUnits
//                           : "-- " + _altUnits
//                     color: "#FFFFFF"
//                     font.pixelSize: root._v
//                     font.bold: true
//                     horizontalAlignment: Text.AlignHCenter
//                 }
//             }
//         }

//         //----------------------------------------------------
//         //-- ✅ SPD (sağ) — köhnə kod kimi
//         Item {
//             id: speedScale
//             width:  root._spdAltGroupW
//             height: root._spdAltGroupH

//             anchors.top:       crossHair.bottom
//             anchors.topMargin: -root._spdAltTopLift
//             anchors.right:     crossHair.right
//             anchors.rightMargin: -root._spdAltShiftX

//             QGCLabel {
//                 id: speedTitle
//                 anchors.top: parent.top
//                 anchors.topMargin: Math.max(2, root.size * 0.01)
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 text: "SPD"
//                 color: "white"
//                 font.pixelSize: root._t
//                 font.bold: true
//             }

//             Rectangle {
//                 id: speedBox
//                 width:  root._spdBoxW
//                 height: root._spdAltBoxH
//                 anchors.top: speedTitle.bottom
//                 anchors.topMargin: root._titleGap
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 color: "#000000"
//                 radius: 3
//                 opacity: 1

//                 QGCLabel {
//                     anchors.centerIn: parent
//                     text: vehicle
//                           ? _groundSpeedDisplay.toFixed(1) + " " + _speedUnits
//                           : "-- " + _speedUnits
//                     color: "#FFFFFF"
//                     font.pixelSize: root._v
//                     font.bold: true
//                     horizontalAlignment: Text.AlignHCenter
//                 }
//             }
//         }

//         //----------------------------------------------------
//         //-- ✅ ROLL/PITCH — səndəki kimi saxlanıldı
//         Column {
//             id: rollPitchGroup
//             anchors.horizontalCenter: parent.horizontalCenter
//             anchors.bottom: parent.bottom
//             anchors.bottomMargin: root.size * 0.070
//             spacing: root.size * 0.020

//             readonly property real _rpSpacing:  root.size * 0.02
//             readonly property real _rpLabelW:   root.size * 0.19
//             readonly property real _rpBoxW:     root.size * 0.18
//             readonly property real _rpBoxH:     root.size * 0.070

//             Row {
//                 width: rollPitchGroup._rpLabelW + rollPitchGroup._rpSpacing + rollPitchGroup._rpBoxW
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 spacing: rollPitchGroup._rpSpacing

//                 Item {
//                     width: rollPitchGroup._rpLabelW
//                     height: rollPitchGroup._rpBoxH
//                     QGCLabel {
//                         anchors.right: parent.right
//                         anchors.verticalCenter: parent.verticalCenter
//                         text: "ROLL:"
//                         color: "#FFFFFF"
//                         font.pixelSize: root._label
//                         font.bold: true
//                         font.family: "Monospace"
//                     }
//                 }

//                 Rectangle {
//                     width:  rollPitchGroup._rpBoxW
//                     height: rollPitchGroup._rpBoxH
//                     color: "#000000"
//                     radius: 3
//                     border.color: "#00FF00"
//                     border.width: 1

//                     QGCLabel {
//                         anchors.centerIn: parent
//                         text: vehicle ? _rollAngle.toFixed(1) + "°" : "---"
//                         color: "white"
//                         font.pixelSize: root._label
//                         font.bold: true
//                         font.family: "Monospace"
//                     }
//                 }
//             }

//             Row {
//                 width: rollPitchGroup._rpLabelW + rollPitchGroup._rpSpacing + rollPitchGroup._rpBoxW
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 spacing: rollPitchGroup._rpSpacing

//                 Item {
//                     width: rollPitchGroup._rpLabelW
//                     height: rollPitchGroup._rpBoxH
//                     QGCLabel {
//                         anchors.right: parent.right
//                         anchors.verticalCenter: parent.verticalCenter
//                         text: "PITCH:"
//                         color: "#FFFFFF"
//                         font.pixelSize: root._label
//                         font.bold: true
//                         font.family: "Monospace"
//                     }
//                 }

//                 Rectangle {
//                     width:  rollPitchGroup._rpBoxW
//                     height: rollPitchGroup._rpBoxH
//                     color: "#000000"
//                     radius: 3
//                     border.color: "#00FF00"
//                     border.width: 1

//                     QGCLabel {
//                         anchors.centerIn: parent
//                         text: vehicle ? _pitchAngle.toFixed(1) + "°" : "---"
//                         color: "white"
//                         font.pixelSize: root._label
//                         font.bold: true
//                         font.family: "Monospace"
//                     }
//                 }
//             }
//         }
//     }

//     MultiEffect {
//         source: instrument
//         anchors.fill: instrument
//         maskEnabled: true
//         maskSource: mask
//     }

//     Item {
//         id: mask
//         width: instrument.width
//         height: instrument.height
//         layer.enabled: true
//         visible: false

//         Rectangle {
//             width: parent.width
//             height: parent.height
//             radius: width/2
//             color: "black"
//         }
//     }

//     Rectangle {
//         anchors.fill: parent
//         radius: width / 2
//         color: Qt.rgba(0,0,0,0)
//         border.color: qgcPal.text
//         border.width: 1
//     }
// }



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

// // import QtQuick
// // import QtQuick.Controls
// // import QtQuick.Layouts

// // import QGroundControl

// // import QGroundControl.Controls
// // import QGroundControl.FactControls


// // // Camera section for mission item editors
// // Column {
// //     anchors.left:   parent.left
// //     anchors.right:  parent.right
// //     spacing:        _margin

// //     property alias buttonGroup:  cameraSectionHeader.buttonGroup
// //     property alias showSpacer:      cameraSectionHeader.showSpacer
// //     property alias checked:         cameraSectionHeader.checked

// //     property var    _camera:        missionItem.cameraSection
// //     property real   _fieldWidth:    ScreenTools.defaultFontPixelWidth * 16
// //     property real   _margin:        ScreenTools.defaultFontPixelWidth / 2

// //     SectionHeader {
// //         id:             cameraSectionHeader
// //         anchors.left:   parent.left
// //         anchors.right:  parent.right
// //         text:           qsTr("Camera")
// //         checked:        false
// //     }

// //     Column {
// //         anchors.left:   parent.left
// //         anchors.right:  parent.right
// //         spacing:        _margin
// //         visible:        cameraSectionHeader.checked

// //         FactComboBox {
// //             id:             cameraActionCombo
// //             anchors.left:   parent.left
// //             anchors.right:  parent.right
// //             fact:           _camera.cameraAction
// //             indexModel:     false
// //         }

// //         RowLayout {
// //             anchors.left:   parent.left
// //             anchors.right:  parent.right
// //             spacing:        ScreenTools.defaultFontPixelWidth
// //             visible:        _camera.cameraAction.rawValue === 1

// //             QGCLabel {
// //                 text:               qsTr("Time")
// //                 Layout.fillWidth:   true
// //             }
// //             FactTextField {
// //                 fact:                   _camera.cameraPhotoIntervalTime
// //                 Layout.preferredWidth:  _fieldWidth
// //             }
// //         }

// //         RowLayout {
// //             anchors.left:   parent.left
// //             anchors.right:  parent.right
// //             spacing:        ScreenTools.defaultFontPixelWidth
// //             visible:        _camera.cameraAction.rawValue === 2

// //             QGCLabel {
// //                 text:               qsTr("Distance")
// //                 Layout.fillWidth:   true
// //             }
// //             FactTextField {
// //                 fact:                   _camera.cameraPhotoIntervalDistance
// //                 Layout.preferredWidth:  _fieldWidth
// //             }
// //         }

// //         RowLayout {
// //             anchors.left:   parent.left
// //             anchors.right:  parent.right
// //             spacing:        ScreenTools.defaultFontPixelWidth
// //             visible:        _camera.cameraModeSupported

// //             QGCCheckBox {
// //                 id:                 modeCheckBox
// //                 text:               qsTr("Mode")
// //                 checked:            _camera.specifyCameraMode
// //                 onClicked:          _camera.specifyCameraMode = checked
// //             }
// //             FactComboBox {
// //                 fact:               _camera.cameraMode
// //                 indexModel:         false
// //                 enabled:            modeCheckBox.checked
// //                 Layout.fillWidth:   true
// //             }
// //         }

// //         GridLayout {
// //             anchors.left:   parent.left
// //             anchors.right:  parent.right
// //             columnSpacing:  ScreenTools.defaultFontPixelWidth / 2
// //             rowSpacing:     0
// //             columns:        3

// //             QGCLabel { text: qsTr("Gimbal") }
// //             QGCLabel { text: qsTr("Pitch") }
// //             QGCLabel { text: qsTr("Yaw") }

// //             QGCCheckBox {
// //                 id:                 gimbalCheckBox
// //                 checked:            _camera.specifyGimbal
// //                 onClicked:          _camera.specifyGimbal = checked
// //                 Layout.fillWidth:   true
// //             }
// //             FactTextField {
// //                 fact:           _camera.gimbalPitch
// //                 implicitWidth:  ScreenTools.defaultFontPixelWidth * 9
// //                 enabled:        gimbalCheckBox.checked
// //             }

// //             FactTextField {
// //                 fact:           _camera.gimbalYaw
// //                 implicitWidth:  ScreenTools.defaultFontPixelWidth * 9
// //                 enabled:        gimbalCheckBox.checked
// //             }
// //         }
// //     }
// // }



// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts

// import QGroundControl

// import QGroundControl.Controls
// import QGroundControl.FactControls


// // Camera section for mission item editors
// Column {
//     anchors.left:   parent.left
//     anchors.right:  parent.right
//     spacing:        _margin

//     property alias buttonGroup:  cameraSectionHeader.buttonGroup
//     property alias showSpacer:      cameraSectionHeader.showSpacer
//     property alias checked:         cameraSectionHeader.checked

//     property var    _camera:        missionItem.cameraSection
//     property real   _fieldWidth:    ScreenTools.defaultFontPixelWidth * 16
//     property real   _margin:        ScreenTools.defaultFontPixelWidth / 2

//     SectionHeader {

//         id:             cameraSectionHeader
//        anchors.left:   parent.left
//         anchors.right:  parent.right
//         text:           qsTr("Camera")
//         checked:        false
//     }

//     Column {
//         anchors.left:   parent.left
//         anchors.right:  parent.right
//         spacing:        _margin
//         visible:        cameraSectionHeader.checked
//         Rectangle{
//             width: 300
//             height: 42
//             x:2
//             radius: 3
//             color: "#2A2A2A"
//         FactComboBox {
//             id:             cameraActionCombo
//             width: 280
//             x:10
//             //anchors.left:   parent.left
//             //anchors.right:  parent.right
//             fact:           _camera.cameraAction
//             indexModel:     false
//             y:5
//             // FactComboBox özel property'leri
//               background: Rectangle {
//                   color: "#3D3B3B"
//                   radius: 3
//                   border.color: "#5D5B5B"
//                   border.width: 1
//               }
//         }

// }
//         RowLayout {
//             anchors.left:   parent.left
//             anchors.right:  parent.right
//             spacing:        ScreenTools.defaultFontPixelWidth
//             visible:        _camera.cameraAction.rawValue === 1

//             QGCLabel {
//                 text:               qsTr("Time")
//                 Layout.fillWidth:   true
//             }
//             FactTextField {
//                 fact:                   _camera.cameraPhotoIntervalTime
//                 Layout.preferredWidth:  _fieldWidth
//             }
//         }

//         RowLayout {
//             anchors.left:   parent.left
//             anchors.right:  parent.right
//             spacing:        ScreenTools.defaultFontPixelWidth
//             visible:        _camera.cameraAction.rawValue === 2

//             QGCLabel {
//                 text:               qsTr("Distance")
//                 Layout.fillWidth:   true
//             }
//             FactTextField {
//                 fact:                   _camera.cameraPhotoIntervalDistance
//                 Layout.preferredWidth:  _fieldWidth
//             }
//         }
// Rectangle{
//     width: 300
//     height: 42
//     x:2
//     radius: 3
//     color: "#2A2A2A"

//         RowLayout {
//             y:4
//             x:13
//             //anchors.left:   parent.left
//             //anchors.right:  parent.right
//             spacing:        144//ScreenTools.defaultFontPixelWidth
//             visible:        _camera.cameraModeSupported

//             QGCCheckBox {
//                 id:                 modeCheckBox
//                 text:               qsTr("Mode")
//                 checked:            _camera.specifyCameraMode
//                 onClicked:          _camera.specifyCameraMode = checked
//                 indicator: Rectangle {
//                         y:8
//                         implicitWidth: 20
//                         implicitHeight: 20
//                         radius: 3
//                         border.color: modeCheckBox.checked ? "#00FF00" : "#888888"
//                         border.width: 2
//                         color: "transparent"

//                         // Yeşil check işareti (✓)
//                         Text {
//                             anchors.centerIn: parent
//                             text: "✓"
//                             color: "#00FF00"
//                             font.pixelSize: 14
//                             font.bold: true
//                             visible: modeCheckBox.checked
//                         }
//                     }
//             }
//             FactComboBox {
//                 fact:               _camera.cameraMode
//                 indexModel:         false
//                 enabled:            modeCheckBox.checked
//                // Layout.fillWidth:   true
//                // width: 300
//                 // FactComboBox özel property'leri
//                   background: Rectangle {
//                       color: "#3D3B3B"
//                       radius: 3
//                       border.color: "#5D5B5B"
//                       border.width: 1
//                   }

//             }
//         }}
// Rectangle{
//     width: 300
//     height: 42
//     x:2
//     radius: 3
//     color: "#2A2A2A"
//         GridLayout {
//             x:14
//             y:8
//            // anchors.left:   parent.left
//             //anchors.right:  parent.right
//             columnSpacing:  18//ScreenTools.defaultFontPixelWidth / 2
//             rowSpacing:     0
//             columns:        3

//             // QGCLabel { text: qsTr("Gimbal") }
//             // QGCLabel { text: qsTr("Pitch") }
//             // QGCLabel { text: qsTr("Yaw") }

//             QGCCheckBox {
//                 y:8
//                 id:                 gimbalCheckBox
//                  text:               qsTr("Gimbal")
//                 checked:            _camera.specifyGimbal
//                 onClicked:          _camera.specifyGimbal = checked
//                 Layout.fillWidth:   true
//                 indicator: Rectangle {
//                         implicitWidth: 20
//                         implicitHeight: 20
//                         radius: 3
//                         border.color: gimbalCheckBox.checked ? "#00FF00" : "#888888"
//                         border.width: 2
//                         color: "transparent"

//                         // Yeşil check işareti (✓)
//                         Text {
//                             anchors.centerIn: parent
//                             text: "✓"
//                             color: "#00FF00" // Yeşil
//                             font.pixelSize: 14
//                             font.bold: true
//                             visible: gimbalCheckBox.checked
//                         }
//                     }

//             }
//             FactTextField {
//                 fact:           _camera.gimbalPitch
//                 implicitWidth:  ScreenTools.defaultFontPixelWidth * 10
//                 enabled:        gimbalCheckBox.checked
//             }

//             FactTextField {
//                 fact:           _camera.gimbalYaw
//                 implicitWidth:  ScreenTools.defaultFontPixelWidth * 10
//                 enabled:        gimbalCheckBox.checked
//             }
//         }
//     }
//     }
// }


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

// Camera section for mission item editors
Column {
    id: root
    anchors.left:   parent.left
    anchors.right:  parent.right
    spacing:        _margin

    property alias buttonGroup: cameraSectionHeader.buttonGroup
    property alias showSpacer:  cameraSectionHeader.showSpacer
    property alias checked:     cameraSectionHeader.checked

    property var  _camera:      missionItem.cameraSection
    property real _fieldWidth:  ScreenTools.defaultFontPixelWidth * 16
    property real _margin:      ScreenTools.defaultFontPixelWidth / 2

    // -------------------- Responsive sizes --------------------
    readonly property real _rowH:     Math.max(40, ScreenTools.defaultFontPixelHeight * 2.15)
    readonly property real _padH:     Math.max(10, ScreenTools.defaultFontPixelWidth)
    readonly property real _gap:      Math.max(10, ScreenTools.defaultFontPixelWidth * 0.8)

    // Combo/TextField ölçüləri (kiçik olsun, kənara çıxmasın)
    readonly property real _comboH:   Math.max(28, ScreenTools.defaultFontPixelHeight * 1.6)
    readonly property real _valueW:   Math.min(_fieldWidth, Math.max(110, width * 0.36))
    readonly property real _gimbalW:  Math.max(60, Math.min(ScreenTools.defaultFontPixelWidth * 10, width * 0.22))

    readonly property real _disabledOpacity: 0.45

    // -------------------- Local style (bu QML üçün) --------------------
    QtObject {
        id: _style
        // Combo/popup renglari artiq QGCComboBox-un umumi qaranliq stilinden gelir
        readonly property color labelText:      "#FFFFFF"
    }

    SectionHeader {
        id:             cameraSectionHeader
        anchors.left:   parent.left
        anchors.right:  parent.right
        text:           qsTr("Camera")
        checked:        false
    }

    Column {
        id: content
        anchors.left:   parent.left
        anchors.right:  parent.right
        spacing:        _margin
        visible:        cameraSectionHeader.checked

        // ===================== Camera action =====================
        Rectangle {
            width:  parent.width
            height: root._rowH
            radius: 6
            color:  "#2A2A2A"
            clip:   true

            FactComboBox {
                id:         cameraActionCombo
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin:     root._padH
                anchors.rightMargin:    root._padH
                height:                 root._comboH

                fact:           _camera.cameraAction
                indexModel:     false
                sizeToContents: false
            }
        }

        // ===================== Time =====================
        Rectangle {
            width:  parent.width
            height: root._rowH
            radius: 6
            color:  "#2A2A2A"
            clip:   true
            visible: _camera.cameraAction.rawValue === 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin:  root._padH
                anchors.rightMargin: root._padH
                spacing: root._gap

                QGCLabel {
                    text:               qsTr("Time")
                    color:              _style.labelText
                    Layout.fillWidth:   true
                    elide:              Text.ElideRight
                    Layout.alignment:   Qt.AlignVCenter
                }

                FactTextField {
                    fact:                   _camera.cameraPhotoIntervalTime
                    Layout.preferredWidth:  root._valueW
                    Layout.minimumWidth:    100
                    Layout.alignment:       Qt.AlignVCenter
                }
            }
        }

        // ===================== Distance =====================
        Rectangle {
            width:  parent.width
            height: root._rowH
            radius: 6
            color:  "#2A2A2A"
            clip:   true
            visible: _camera.cameraAction.rawValue === 2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin:  root._padH
                anchors.rightMargin: root._padH
                spacing: root._gap

                QGCLabel {
                    text:               qsTr("Distance")
                    color:              _style.labelText
                    Layout.fillWidth:   true
                    elide:              Text.ElideRight
                    Layout.alignment:   Qt.AlignVCenter
                }

                FactTextField {
                    fact:                   _camera.cameraPhotoIntervalDistance
                    Layout.preferredWidth:  root._valueW
                    Layout.minimumWidth:    100
                    Layout.alignment:       Qt.AlignVCenter
                }
            }
        }

        // ===================== Mode (checkbox + combobox eyni ROW) =====================
        Rectangle {
            width:  parent.width
            height: root._rowH
            radius: 6
            color:  "#2A2A2A"
            clip:   true
            visible: _camera.cameraModeSupported

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin:  root._padH
                anchors.rightMargin: root._padH
                spacing: root._gap

                QGCCheckBox {
                    id:         modeCheckBox
                    text:       qsTr("Mode")
                    checked:    _camera.specifyCameraMode
                    onClicked:  _camera.specifyCameraMode = checked

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                FactComboBox {
                    id:         cameraModeCombo
                    fact:       _camera.cameraMode
                    indexModel: false

                    // ✅ Mode checkbox aktiv deyilse: deaktiv + solğun
                    enabled:    modeCheckBox.checked
                    opacity:    enabled ? 1.0 : root._disabledOpacity

                    Layout.preferredWidth:  root._valueW
                    Layout.minimumWidth:    110
                    Layout.alignment:       Qt.AlignVCenter
                    height:                 root._comboH
                    sizeToContents:         false
                }
            }
        }

        // ===================== Gimbal (checkbox + 2 field eyni ROW) =====================
        Rectangle {
            width:  parent.width
            height: root._rowH
            radius: 6
            color:  "#2A2A2A"
            clip:   true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin:  root._padH
                anchors.rightMargin: root._padH
                spacing: root._gap

                QGCCheckBox {
                    id:                 gimbalCheckBox
                    text:               qsTr("Gimbal")
                    checked:            _camera.specifyGimbal
                    onClicked:          _camera.specifyGimbal = checked

                    Layout.fillWidth:   true
                    Layout.alignment:   Qt.AlignVCenter
                }

                FactTextField {
                    fact:                   _camera.gimbalPitch
                    enabled:                gimbalCheckBox.checked
                    opacity:                enabled ? 1.0 : root._disabledOpacity
                    Layout.preferredWidth:  root._gimbalW
                    Layout.minimumWidth:    60
                    Layout.alignment:       Qt.AlignVCenter
                }

                FactTextField {
                    fact:                   _camera.gimbalYaw
                    enabled:                gimbalCheckBox.checked
                    opacity:                enabled ? 1.0 : root._disabledOpacity
                    Layout.preferredWidth:  root._gimbalW
                    Layout.minimumWidth:    60
                    Layout.alignment:       Qt.AlignVCenter
                }
            }
        }
    }
}

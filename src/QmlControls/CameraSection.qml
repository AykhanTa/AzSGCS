// // import QtQuick
// // import QtQuick.Controls
// // import QtQuick.Layouts

// // import QGroundControl

// // import QGroundControl.Controls
// // import QGroundControl.FactControls




// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts

// import QGroundControl

// import QGroundControl.Controls
// import QGroundControl.FactControls



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
            color:  AzTheme.groupFill
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
            color:  AzTheme.groupFill
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
            color:  AzTheme.groupFill
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
            color:  AzTheme.groupFill
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
            color:  AzTheme.groupFill
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

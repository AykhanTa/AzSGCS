import QtQuick

import QGroundControl
import QGroundControl.Controls

/// Shortcut buttons for a Skydroid pod (C13 and the rest of the range) down the edge of
/// the fly view, laid out like Skydroid's own ground station: one-key centre and look
/// down, record, photo, zoom, and the thermal camera.
Column {
    id: root

    /// Height the column has to fit in; the buttons shrink to fit rather than run off.
    property real availableHeight: height

    readonly property var  _ctl:         (typeof skydroidGimbal !== "undefined") ? skydroidGimbal : null
    readonly property int  _buttonCount: (_ctl && _ctl.thermalAvailable) ? 7 : 6
    readonly property real _spacing:     Math.round(ScreenTools.defaultFontPixelHeight * 0.4)
    /// The least height the buttons can shrink to.
    readonly property real minimumHeight: (ScreenTools.defaultFontPixelHeight * 1.8 * _buttonCount) + (_spacing * (_buttonCount - 1))

    readonly property real _buttonSize:  Math.round(Math.max(ScreenTools.defaultFontPixelHeight * 1.8,
                                                             Math.min(ScreenTools.defaultFontPixelHeight * 2.6,
                                                                      (availableHeight - _spacing * (_buttonCount - 1)) / _buttonCount)))

    spacing: _spacing

    // A zoom button stepping while it is held must not keep stepping if this goes away
    // underneath the finger.
    Component.onDestruction: {
        if (_ctl && (zoomInButton.held || zoomOutButton.held)) {
            _ctl.zoomStop()
        }
    }

    component ShortcutButton: Rectangle {
        id: button

        // Inline components cannot see the enclosing file's ids, so the size is handed in.
        property real   size
        property string iconSource
        property bool   checked:        false
        property color  checkedColor:   "#E53935"
        readonly property bool held:    mouseArea.pressed

        signal clicked()
        signal pressed()
        signal released()

        width:          size
        height:         width
        radius:         width / 2
        color:          mouseArea.pressed ? "#B3FFFFFF" : (checked ? checkedColor : "#99000000")
        border.color:   "white"
        border.width:   Math.max(1, Math.round(width * 0.035))

        QGCColoredImage {
            anchors.centerIn:   parent
            width:              Math.round(parent.width * 0.52)
            height:             width
            sourceSize.height:  height
            source:             button.iconSource
            color:              "white"
            fillMode:           Image.PreserveAspectFit
        }

        MouseArea {
            id:                 mouseArea
            anchors.fill:       parent
            onClicked:          button.clicked()
            onPressed:          button.pressed()
            onReleased:         button.released()
            onCanceled:         button.released()
        }
    }

    ShortcutButton {
        size:       root._buttonSize
        iconSource: "/InstrumentValueIcons/target.svg"
        onClicked:  root._ctl.centerGimbal()
    }

    ShortcutButton {
        size:       root._buttonSize
        iconSource: "/InstrumentValueIcons/arrow-thick-down.svg"
        onClicked:  root._ctl.lookDown()
    }

    ShortcutButton {
        size:       root._buttonSize
        iconSource: "/InstrumentValueIcons/video-camera.svg"
        checked:    root._ctl ? root._ctl.recording : false
        onClicked:  root._ctl.toggleRecording()
    }

    ShortcutButton {
        size:       root._buttonSize
        iconSource: "/InstrumentValueIcons/camera.svg"
        onClicked:  root._ctl.takePhoto()
    }

    ShortcutButton {
        id:         zoomInButton
        size:       root._buttonSize
        iconSource: "/InstrumentValueIcons/zoom-in.svg"
        onPressed:  root._ctl.zoomIn()
        onReleased: root._ctl.zoomStop()
    }

    ShortcutButton {
        id:         zoomOutButton
        size:       root._buttonSize
        iconSource: "/InstrumentValueIcons/zoom-out.svg"
        onPressed:  root._ctl.zoomOut()
        onReleased: root._ctl.zoomStop()
    }

    ShortcutButton {
        size:           root._buttonSize
        visible:        root._ctl ? root._ctl.thermalAvailable : false
        iconSource:     "/InstrumentValueIcons/thermometer.svg"
        checked:        root._ctl ? root._ctl.thermalView : false
        checkedColor:   "#FF6D00"
        onClicked:      root._ctl.toggleThermal()
    }
}

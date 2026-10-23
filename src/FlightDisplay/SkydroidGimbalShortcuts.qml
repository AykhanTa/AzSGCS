import QtQuick
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls

/// Shortcut buttons for a Skydroid pod (C13 and the rest of the range) down the edge of
/// the fly view, laid out like Skydroid's own ground station: one-key centre and look
/// down, record, photo, the thermal camera and zoom.
///
/// Drawn from the "MapTools" frame of the design: 48 px buttons, radius 14, the card
/// gradient with a 1 px #34393E border, 8 px apart, and a 52x100 block holding + and −.
Column {
    id: root

    /// Height the column has to fit in; the buttons shrink to fit rather than run off.
    property real availableHeight: height

    readonly property var  _ctl:        (typeof skydroidGimbal !== "undefined") ? skydroidGimbal : null
    readonly property real _spacing:    AzTheme.px(8)
    // Five buttons and the zoom block, which is 100/48 of a button tall.
    readonly property real _zoomRatio:  100 / 48
    readonly property real _units:      5 + _zoomRatio
    // On the G30/G20 the scaled size would drop below a comfortable touch target.
    readonly property real _minButton:  40
    /// The least height the buttons can shrink to.
    readonly property real minimumHeight: (_minButton * _units) + (_spacing * 5)

    readonly property real _buttonSize: Math.round(Math.max(_minButton,
                                                             Math.min(AzTheme.px(48),
                                                                      (availableHeight - _spacing * 5) / _units)))

    readonly property color _border:       "#34393E"
    readonly property color _recordColor:  AzTheme.statusRed
    readonly property color _thermalColor: AzTheme.statusOrange

    spacing: _spacing

    // A zoom button stepping while it is held must not keep stepping if this goes away
    // underneath the finger.
    Component.onDestruction: {
        if (_ctl && (zoomBlock.zoomInHeld || zoomBlock.zoomOutHeld)) {
            _ctl.zoomStop()
        }
    }

    /// The card background shared by the buttons and the zoom block.
    component ButtonFace: Item {
        id: face

        property real  radius
        property color borderColor
        property real  shadowOffset
        property real  shadowBlur
        property color shadowColor

        RectangularShadow {
            anchors.fill: faceBackground
            offset.y:     face.shadowOffset
            blur:         face.shadowBlur
            radius:       face.radius
            color:        face.shadowColor
        }

        AzGradientRect {
            id:            faceBackground
            anchors.fill:  parent
            angle:         AzTheme.cardGradientAngle
            startColor:    AzTheme.cardGradientStart
            startPosition: AzTheme.cardGradientStartPos
            endColor:      AzTheme.cardGradientEnd
            endPosition:   AzTheme.cardGradientEndPos
            radius:        face.radius
            borderColor:   face.borderColor
            borderWidth:   1
        }
    }

    component ShortcutButton: Item {
        id: button

        // Inline components cannot see the enclosing file's ids, so these are handed in.
        property real   size
        property color  borderColor
        property string iconSource
        property real   iconRatio:      20 / 48
        /// false for an icon that carries its own colours (thermal).
        property bool   tintIcon:       true
        property bool   checked:        false
        property color  checkedColor
        readonly property bool held:    mouseArea.pressed
        readonly property real _radius: Math.round(size * 14 / 48)

        signal clicked()

        width:                    size
        height:                   size
        anchors.horizontalCenter: parent.horizontalCenter
        opacity:                  enabled ? 1 : 0.4

        function flash() {
            flashAnimation.restart()
        }

        ButtonFace {
            anchors.fill: parent
            radius:       button._radius
            borderColor:  button.checked ? button.checkedColor
                                         : ((mouseArea.containsMouse && button.enabled) ? AzTheme.cardHoverBorder : button.borderColor)
            shadowOffset: Math.round(button.size * 7 / 48)
            shadowBlur:   Math.round(button.size * 16 / 48)
            shadowColor:  Qt.rgba(0, 0, 0, 0.35)
        }

        // Active tint and press feedback.
        Rectangle {
            anchors.fill:    parent
            anchors.margins: 1
            radius:          button._radius - 1
            color:           button.checked ? Qt.rgba(button.checkedColor.r, button.checkedColor.g, button.checkedColor.b, 0.14)
                                            : Qt.rgba(1, 1, 1, mouseArea.pressed ? 0.08 : 0)
        }

        // Photo flash.
        Rectangle {
            anchors.fill:    parent
            anchors.margins: 1
            radius:          button._radius - 1
            color:           "white"
            opacity:         0

            NumberAnimation on opacity {
                id:       flashAnimation
                running:  false
                from:     0.35
                to:       0
                duration: 350
            }
        }

        QGCColoredImage {
            anchors.centerIn:   parent
            width:              Math.round(button.size * button.iconRatio)
            height:             width
            sourceSize.height:  height
            source:             button.iconSource
            color:              button.checked ? button.checkedColor : AzTheme.textCard
            fillMode:           Image.PreserveAspectFit
            visible:            button.tintIcon
        }

        Image {
            anchors.centerIn:   parent
            width:              Math.round(button.size * button.iconRatio)
            height:             width
            sourceSize.height:  height
            source:             button.iconSource
            fillMode:           Image.PreserveAspectFit
            visible:            !button.tintIcon
        }

        MouseArea {
            id:           mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked:    button.clicked()
        }
    }

    ShortcutButton {
        size:        root._buttonSize
        borderColor: root._border
        iconSource:  "qrc:/res/AZSHIELD_ICON/v2/cam_target.svg"
        onClicked:   root._ctl.centerGimbal()
    }

    ShortcutButton {
        size:        root._buttonSize
        borderColor: root._border
        iconSource:  "qrc:/res/AZSHIELD_ICON/v2/cam_lookdown.svg"
        onClicked:   root._ctl.lookDown()
    }

    ShortcutButton {
        id:           recordButton
        size:         root._buttonSize
        borderColor:  root._border
        iconSource:   "qrc:/res/AZSHIELD_ICON/v2/cam_video.svg"
        iconRatio:    21 / 48
        checked:      root._ctl ? root._ctl.recording : false
        checkedColor: root._recordColor
        onClicked:    root._ctl.toggleRecording()

        // Blinking dot in the corner while recording.
        Rectangle {
            x:       parent.width - width - Math.round(parent.width * 0.16)
            y:       Math.round(parent.height * 0.16)
            width:   Math.max(5, Math.round(parent.width * 0.14))
            height:  width
            radius:  width / 2
            color:   root._recordColor
            visible: recordButton.checked

            SequentialAnimation on opacity {
                running: recordButton.checked
                loops:   Animation.Infinite
                NumberAnimation { to: 0.2; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }
    }

    ShortcutButton {
        id:          photoButton
        size:        root._buttonSize
        borderColor: root._border
        iconSource:  "qrc:/res/AZSHIELD_ICON/v2/cam_photo.svg"
        iconRatio:   21 / 48
        onClicked: {
            root._ctl.takePhoto()
            photoButton.flash()
        }
    }

    // Always shown; it only works once the pod reports a thermal camera.
    ShortcutButton {
        size:         root._buttonSize
        borderColor:  root._border
        enabled:      root._ctl ? root._ctl.thermalAvailable : false
        iconSource:   "qrc:/res/AZSHIELD_ICON/v2/cam_thermal.svg"
        tintIcon:     false
        checked:      root._ctl ? root._ctl.thermalView : false
        checkedColor: root._thermalColor
        onClicked:    root._ctl.toggleThermal()
    }

    // + and − in one block; each zooms while held.
    Item {
        id: zoomBlock

        readonly property bool zoomInHeld:  zoomInMouse.pressed
        readonly property bool zoomOutHeld: zoomOutMouse.pressed
        readonly property real _radius:     Math.round(root._buttonSize * 14 / 48)

        width:                    Math.round(root._buttonSize * 52 / 48)
        height:                   Math.round(root._buttonSize * root._zoomRatio)
        anchors.horizontalCenter: parent.horizontalCenter

        ButtonFace {
            anchors.fill: parent
            radius:       zoomBlock._radius
            borderColor:  (zoomInMouse.containsMouse || zoomOutMouse.containsMouse) ? AzTheme.cardHoverBorder : root._border
            shadowOffset: Math.round(root._buttonSize * 8 / 48)
            shadowBlur:   Math.round(root._buttonSize * 18 / 48)
            shadowColor:  Qt.rgba(0, 0, 0, 0.4)
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x:                      Math.round(parent.width * 0.2)
            width:                  parent.width - 2 * x
            height:                 1
            color:                  root._border
        }

        Repeater {
            model: [
                { text: "+", top: true },
                { text: "−", top: false }
            ]

            Item {
                id: zoomHalf

                required property var modelData

                y:      zoomHalf.modelData.top ? 0 : zoomBlock.height / 2
                width:  zoomBlock.width
                height: zoomBlock.height / 2

                readonly property bool _pressed: zoomHalf.modelData.top ? zoomInMouse.pressed : zoomOutMouse.pressed
                readonly property real _inset:   Math.max(3, Math.round(root._buttonSize * 4 / 48))

                Rectangle {
                    anchors.fill:    parent
                    anchors.margins: zoomHalf._inset
                    radius:          zoomBlock._radius - zoomHalf._inset
                    color:           Qt.rgba(1, 1, 1, 0.08)
                    visible:         zoomHalf._pressed
                }

                Text {
                    anchors.centerIn: parent
                    text:             zoomHalf.modelData.text
                    color:            AzTheme.textCard
                    font.family:      AzTheme.fontFamily
                    font.weight:      Font.Light
                    font.pixelSize:   Math.round(root._buttonSize * 28 / 48)
                }
            }
        }

        MouseArea {
            id:           zoomInMouse
            width:        parent.width
            height:       parent.height / 2
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onPressed:    root._ctl.zoomIn()
            onReleased:   root._ctl.zoomStop()
            onCanceled:   root._ctl.zoomStop()
        }

        MouseArea {
            id:           zoomOutMouse
            y:            parent.height / 2
            width:        parent.width
            height:       parent.height / 2
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onPressed:    root._ctl.zoomOut()
            onReleased:   root._ctl.zoomStop()
            onCanceled:   root._ctl.zoomStop()
        }
    }
}

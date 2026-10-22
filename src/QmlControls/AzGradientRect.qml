import QtQuick
import QtQuick.Shapes

// Rounded rectangle filled the way CSS linear-gradient(angle, start pos, end pos) fills
// it. QML's Gradient only runs horizontally or vertically; the Figma exports use angles
// such as 145deg and 155deg. The border is drawn inside the bounds, as with
// box-sizing: border-box.
Shape {
    id: root

    // CSS degrees: 0 points to the top, 90 to the right, 180 to the bottom.
    property real   angle:         180
    property color  startColor:    "black"
    property real   startPosition: 0
    property color  endColor:      "black"
    property real   endPosition:   1
    property real   radius:        0
    property color  borderColor:   "transparent"
    property real   borderWidth:   0

    // CSS sizes the gradient line so that its ends touch the far corners.
    readonly property real _radians:    angle * Math.PI / 180
    readonly property real _dirX:       Math.sin(_radians)
    readonly property real _dirY:       -Math.cos(_radians)
    readonly property real _halfLength: (Math.abs(width * _dirX) + Math.abs(height * _dirY)) / 2
    readonly property real _inset:      borderWidth / 2

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
        strokeWidth: root.borderWidth

        fillGradient: LinearGradient {
            x1: root.width / 2 - root._dirX * root._halfLength
            y1: root.height / 2 - root._dirY * root._halfLength
            x2: root.width / 2 + root._dirX * root._halfLength
            y2: root.height / 2 + root._dirY * root._halfLength

            GradientStop { position: root.startPosition; color: root.startColor }
            GradientStop { position: root.endPosition;   color: root.endColor }
        }

        PathRectangle {
            x:      root._inset
            y:      root._inset
            width:  Math.max(0, root.width - root.borderWidth)
            height: Math.max(0, root.height - root.borderWidth)
            radius: Math.max(0, root.radius - root._inset)
        }
    }
}

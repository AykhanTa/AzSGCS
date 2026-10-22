import QtQuick
import QtQuick.Shapes

// CSS radial-gradient(<rx>% <ry>% at <cx>% <cy>%, color 0%, transparent <end>%) inside a
// rounded rectangle. RadialGradient only draws circles, so the circle is stretched into
// the CSS ellipse with fillTransform. The defaults are the status card's glow.
Shape {
    id: root

    property color color:        "transparent"
    property real  centerXRatio: 0.20
    property real  centerYRatio: 0.30
    property real  radiusXRatio: 0.8238
    property real  radiusYRatio: 2.9314
    property real  endPosition:  0.42
    property real  radius:       0

    readonly property real _cx: width * centerXRatio
    readonly property real _cy: height * centerYRatio
    readonly property real _rx: Math.max(1, width * radiusXRatio)
    readonly property real _ry: Math.max(1, height * radiusYRatio)

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: "transparent"

        fillGradient: RadialGradient {
            centerX:      root._cx
            centerY:      root._cy
            centerRadius: root._rx
            focalX:       root._cx
            focalY:       root._cy

            GradientStop { position: 0;                color: root.color }
            GradientStop { position: root.endPosition; color: Qt.rgba(root.color.r, root.color.g, root.color.b, 0) }
        }
        fillTransform: PlanarTransform.fromScale(1, root._ry / root._rx, root._cx, root._cy)

        PathRectangle {
            x:      0
            y:      0
            width:  root.width
            height: root.height
            radius: root.radius
        }
    }
}

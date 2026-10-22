pragma Singleton

import QtQuick

// Design tokens for the AzShield UI.
//
// The Figma frames are drawn at 1920x1080. px() maps a Figma length onto the current
// window, so a value can be copied straight from the design's CSS. Below minScale the
// UI stops shrinking (touch targets and text would get too small on the G30/G20) and
// the screens switch to their compact layouts instead, signalled by `compact`.
QtObject {
    // Bound by MainWindow to its own size.
    property real windowWidth:  designWidth
    property real windowHeight: designHeight

    readonly property real designWidth:  1920
    readonly property real designHeight: 1080
    readonly property real minScale:     0.62

    readonly property real uiScale: Math.max(minScale, Math.min(1, windowWidth / designWidth, windowHeight / designHeight))
    readonly property bool compact: windowWidth < 1280 || windowHeight < 720

    function px(value) {
        return Math.round(value * uiScale)
    }

    // Text has its own floor: 18 px menu labels scaled by minScale are still legible,
    // 12 px captions are not.
    function fontPx(value) {
        return Math.max(11, Math.round(value * uiScale))
    }

    // ---- Typography ----
    readonly property string fontFamily: "Poppins"

    // ---- Text ----
    readonly property color textPrimary:   "#FFFFFF"
    readonly property color textCard:      "#F2F3F4"
    readonly property color textSecondary: "#9B9FA4"

    // ---- Side menu and top bar panels (linear-gradient(155deg, ...)) ----
    readonly property real  panelGradientAngle: 155
    readonly property color panelGradientStart: Qt.rgba(25 / 255, 29 / 255, 32 / 255, 0.97)
    readonly property real  panelGradientStartPos: 0.0849
    readonly property color panelGradientEnd:   Qt.rgba(14 / 255, 17 / 255, 19 / 255, 0.98)
    readonly property real  panelGradientEndPos: 0.9151
    readonly property color panelBorder:        "#353A3F"
    readonly property color panelShadow:        Qt.rgba(0, 0, 0, 0.2)

    // ---- Side menu items ----
    readonly property color menuSelectedTop:    "#30353A"
    readonly property color menuSelectedBottom: "#202428"
    readonly property color menuSelectedBorder: "#5D646B"
    readonly property real  menuSelectedRadius: 8
    readonly property color menuIconGlow:       Qt.rgba(214 / 255, 230 / 255, 242 / 255, 0.18)

    // ---- Cards: top bar status cards, map buttons (linear-gradient(145deg, ...)) ----
    readonly property real  cardGradientAngle:    145
    readonly property color cardGradientStart:    "#25272A"
    readonly property real  cardGradientStartPos: 0.0617
    readonly property color cardGradientEnd:      "#181B1E"
    readonly property real  cardGradientEndPos:   0.9383
    readonly property color cardBorder:           "#353A3F"
    readonly property real  cardRadius:           14

    // ---- Status colours ----
    readonly property color statusRed: "#FF3443"
}

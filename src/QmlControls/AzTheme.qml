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
    readonly property color cardHoverBorder:      "#5D646B"
    readonly property real  cardRadius:           14
    // box-shadow: 0 8px 20px rgba(0, 0, 0, 0.2), inset 0 1px 0 rgba(255, 255, 255, 0.024)
    readonly property color cardShadow:           Qt.rgba(0, 0, 0, 0.2)
    readonly property color cardTopHighlight:     Qt.rgba(1, 1, 1, 0.024)

    // ---- Top bar ----
    readonly property color topBarShadow:       Qt.rgba(0, 0, 0, 0.28)
    readonly property color topBarMenuTop:      "#0F1215"
    readonly property color topBarMenuBottom:   "#0B0D0F"
    readonly property color topBarMenuIcon:     "#C8CACD"
    // The kebab button's hover in the CSS.
    readonly property color activeTintStart:    Qt.rgba(29 / 255, 78 / 255, 216 / 255, 0.04)
    readonly property color activeTintEnd:      Qt.rgba(37 / 255, 99 / 255, 235 / 255, 0.09)
    readonly property color activeBorder:       Qt.rgba(37 / 255, 99 / 255, 235 / 255, 0.6)

    // ---- Status colours ----
    // Red and its glow are in the CSS, green is sampled from the "Bağlantı" mock-up.
    // Blue has no mock-up yet; it is the same family as activeTint.
    readonly property color statusRed:       "#FF3443"
    readonly property color statusRedGlow:   Qt.rgba(188 / 255, 38 / 255, 43 / 255, 0.24)
    readonly property color statusGreen:     "#00B546"
    readonly property color statusGreenGlow: Qt.rgba(0, 181 / 255, 70 / 255, 0.24)
    readonly property color statusBlue:      "#3B82F6"
    readonly property color statusBlueGlow:  Qt.rgba(59 / 255, 130 / 255, 246 / 255, 0.24)
    readonly property color statusOrange:    "#FF9F1A"
    readonly property color statusYellow:    "#FFD43B"
    readonly property color modeChangeGlow:  Qt.rgba(238 / 255, 204 / 255, 68 / 255, 0.30)

    // ---- Top bar panels (the "Status" and "RC Siqnalı" mock-ups) ----
    // No CSS for these yet: colours are sampled from the mock-ups, lengths measured on
    // them and then tightened a little on request (padding, rows, pills, buttons). The
    // card uses the panel gradient; groups are flat #191D20 boxes split by 1 px lines.
    readonly property real  popupWidth:      400     // the info panels (RC, GPS, Batareya)
    readonly property real  popupWideWidth:  480     // Status, Yoxlama and the settings panels
    readonly property real  popupMaxHeight:  640
    readonly property real  popupRadius:     12
    readonly property real  popupPadding:    16
    readonly property real  popupGap:        12      // between the header, sections and groups
    readonly property real  popupDrop:       8       // below the top bar
    readonly property color popupShadow:     Qt.rgba(0, 0, 0, 0.35)
    readonly property real  popupTitleSize:  17
    readonly property real  popupTextSize:   14
    readonly property color groupFill:       "#191D20"
    readonly property color groupBorder:     "#353A3F"
    readonly property real  groupRadius:     8
    readonly property real  groupRowHeight:  48
    readonly property real  groupLineHeight: 32      // message, problem and sensor lines
    readonly property real  groupPadding:    16
    readonly property color pillTop:         "#171A1D"
    readonly property color pillBottom:      "#0F1214"
    readonly property real  pillWidth:       104
    readonly property real  pillHeight:      32
    readonly property color buttonTop:       "#2A2D31"
    readonly property color buttonBottom:    "#1F2225"
    readonly property color buttonBorder:    "#3E4347"
    readonly property real  buttonHeight:    36
    // The ammunition panel's red "At" button.
    readonly property color dangerTop:         "#CD2B35"
    readonly property color dangerBottom:      "#AD151F"
    readonly property color dangerBorder:      "#E04650"
    readonly property color dangerHoverBorder: "#F27A81"
    // The confirmation dialog's green "Bəli" button.
    readonly property color positiveTop:         "#12A34C"
    readonly property color positiveBottom:      "#0B7B37"
    readonly property color positiveBorder:      "#3DBE6E"
    readonly property color positiveHoverBorder: "#6FD896"
    // Ammunition slot rings
    readonly property color slotReady:         "#0E9F7A"
    readonly property color slotEmpty:         "#3A3F44"
    // Problems and messages: errors are statusRed, warnings this yellow, and the
    // parameter link in a problem's description the pale one.
    readonly property color warningText:     "#E3D21A"
    readonly property color linkText:        "#FFFABF"
    readonly property color mutedText:       "#6F757B"
}

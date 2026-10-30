import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls


/// Standard push button control:
///     If there is both an icon and text the icon will be to the left of the text
///     If icon only, icon will be centered
Button {
    id:             control
    hoverEnabled:   !ScreenTools.isMobile
    topPadding:     _verticalPadding
    bottomPadding:  _verticalPadding
    leftPadding:    _horizontalPadding
    rightPadding:   _horizontalPadding
    focusPolicy:    Qt.ClickFocus
    font.family:    _az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
    text:           ""

    property bool   primary:        false                               ///< primary button for a group of buttons
    property bool   showBorder:     qgcPal.globalTheme === QGCPalette.Light
    property real   backRadius:     ScreenTools.buttonBorderRadius
    property real   heightFactor:   0.5
    property string iconSource:     ""
    property real   fontWeight:     Font.Normal // default for qml Text
    property real   pointSize:      ScreenTools.defaultFontPointSize

    property bool  forceTextColor: false
    property color forcedTextColor: "white"


    property alias wrapMode:            text.wrapMode
    property alias horizontalAlignment: text.horizontalAlignment
    property alias backgroundColor:     backRect.color
    property alias textColor:           text.color

    property bool   _showHighlight:     enabled && (pressed | checked)

    // The new design's look (AzButton's) for screens that ask for it by declaring
    // `readonly property bool azInputStyle: true` on their root (the Plan view so far);
    // a primary button is the green one there.
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    property int _horizontalPadding:    ScreenTools.defaultFontPixelWidth * 2
    property int _verticalPadding:      Math.round(ScreenTools.defaultFontPixelHeight * heightFactor)

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
    background: Rectangle {
        id:             backRect
        radius:         control._az ? AzTheme.px(8) : backRadius
        implicitWidth:  ScreenTools.implicitButtonWidth
        implicitHeight: ScreenTools.implicitButtonHeight
        border.width:   (control._az || showBorder) ? 1 : 0
        border.color:   control._az ? (primary ? (control.hovered ? AzTheme.positiveHoverBorder : AzTheme.positiveBorder)
                                               : (control.hovered && control.enabled ? AzTheme.cardHoverBorder : AzTheme.buttonBorder))
                                    : qgcPal.buttonBorder
        color:          control._az ? (primary ? AzTheme.positiveBottom : AzTheme.buttonBottom)
                                    : (primary ? qgcPal.primaryButton : qgcPal.button)
        opacity:        (control._az && !control.enabled) ? 0.45 : 1

        Rectangle {
            anchors.fill:   parent
            color:          control._az ? Qt.rgba(1, 1, 1, 0.3) : qgcPal.buttonHighlight
            opacity:        _showHighlight ? 1 : control.enabled && control.hovered ? .2 : 0
            radius:         parent.radius
        }
    }

    contentItem: RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            QGCColoredImage {
                id:                     icon
                Layout.alignment:       Qt.AlignHCenter
                source:                 control.iconSource
                height:                 text.height
                width:                  height
                color:                  text.color
                fillMode:               Image.PreserveAspectFit
                sourceSize.height:      height
                visible:                control.iconSource !== ""
            }

            QGCLabel {
                id:                     text
                Layout.alignment:       Qt.AlignHCenter
                text:                   control.text
                font.pointSize:         control.pointSize
                font.family:            control.font.family
                font.weight:            fontWeight
              //  color:                  _showHighlight ? qgcPal.buttonHighlightText : (primary ? qgcPal.primaryButtonText : qgcPal.buttonText)
                color: control._az
                       ? (control.forceTextColor ? control.forcedTextColor : (primary ? AzTheme.textPrimary : AzTheme.textCard))
                       : (_showHighlight
                          ? qgcPal.buttonHighlightText
                          : (control.forceTextColor
                               ? control.forcedTextColor
                               : (primary ? qgcPal.primaryButtonText : qgcPal.buttonText)))


                visible:                control.text !== ""
            }
    }
}

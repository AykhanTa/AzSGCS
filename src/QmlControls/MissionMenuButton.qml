import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

/// Plan görünüşündəki açılan menyular (hamburger) üçün sətir düyməsi.
/// Standart QGCButton-dan fərqli olaraq mətn sola dayaqlıdır və menyu
/// sətri kimi görünür — hover-də yaşıl sol kənar yaranır.
Button {
    id: control

    focusPolicy: Qt.ClickFocus
    padding:     0

    property color accentColor: "#00C853"

    implicitHeight: Math.max(34, ScreenTools.defaultFontPixelHeight * 1.9)
    // Mətnin tam sığması üçün — menyu bəndləri kəsilməsin
    implicitWidth:  Math.max(260, contentItem.implicitWidth + _pad * 2)

    readonly property real _pad: Math.max(8, ScreenTools.defaultFontPixelWidth * 0.9)

    HoverHandler { id: hoverHandler; enabled: control.enabled }

    background: Rectangle {
        radius: 8
        color: control.down ? "#454545"
                            : (control.enabled && hoverHandler.hovered ? "#3A3A3A" : "#333333")
        opacity: control.enabled ? 1.0 : 0.45

        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            anchors.left:           parent.left
            anchors.leftMargin:     1
            anchors.verticalCenter: parent.verticalCenter
            width:                  3
            height:                 parent.height * 0.55
            radius:                 1.5
            color:                  control.accentColor
            visible:                control.enabled && (hoverHandler.hovered || control.down)
        }
    }

    contentItem: QGCLabel {
        text:                control.text
        color:               "#FFFFFF"
        font.pointSize:      ScreenTools.defaultFontPointSize
        verticalAlignment:   Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        leftPadding:         control._pad
        rightPadding:        control._pad
        opacity:             control.enabled ? 1.0 : 0.6
    }
}

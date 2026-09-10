import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

/// Plan görünüşündəki qat seçicisi (Mission / Fence / Rally) üçün seqment düyməsi.
/// Aktiv olan doldurulmuş, digərləri sadəcə konturludur — beləliklə hansının
/// seçili olduğu bir baxışda görünür.
TabButton {
    id: control

    focusPolicy: Qt.ClickFocus

    property color accentColor:  "#00C853"
    property color inactiveText: "#DDDDDD"
    property color panelColor:   "#2A2A2A"

    readonly property bool _active: checked

    topPadding:    _verticalPadding
    bottomPadding: _verticalPadding
    leftPadding:   _horizontalPadding
    rightPadding:  _horizontalPadding

    property int _horizontalPadding: Math.round(ScreenTools.defaultFontPixelWidth * 1.0)
    property int _verticalPadding:   Math.round(ScreenTools.defaultFontPixelHeight * 0.5)

    implicitHeight: Math.max(34, ScreenTools.defaultFontPixelHeight * 2.1)

    HoverHandler { id: hoverHandler; enabled: control.enabled }

    background: Rectangle {
        radius: height / 2
        color: control._active
               ? control.accentColor
               : (control.enabled && hoverHandler.hovered ? "#3A3A3A" : control.panelColor)
        border.width: control._active ? 0 : 1
        border.color: control.enabled ? "#6E6E6E" : "#4A4A4A"
        opacity: control.enabled ? 1.0 : 0.45

        Behavior on color { ColorAnimation { duration: 130 } }
    }

    contentItem: Text {
        text: control.text
        color: control._active ? "#0E0E0E" : control.inactiveText
        font.family: ScreenTools.normalFontFamily
        font.pointSize: ScreenTools.defaultFontPointSize
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: control.enabled ? 1.0 : 0.6

        Behavior on color { ColorAnimation { duration: 130 } }
    }
}


import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

ColumnLayout {
    property var    instrumentValueData:            null
    property bool   settingsUnlocked:               false
    property real   contentWidth:                   100  // SABİT genişlik
    property real   _uniformFontSize:               (_root && _root.uniformFontSize !== undefined) ? _root.uniformFontSize : 11

    property var    _rgFontSizes:                   [ ScreenTools.defaultFontPointSize, ScreenTools.smallFontPointSize, ScreenTools.mediumFontPointSize, ScreenTools.largeFontPointSize ]
    property var    _rgFontSizeRatios:              [ 1, ScreenTools.smallFontPointRatio, ScreenTools.mediumFontPointRatio, ScreenTools.largeFontPointRatio ]
    property real   _doubleDescent:                 ScreenTools.defaultFontDescent * 2
    property real   _tightDefaultFontHeight:        ScreenTools.defaultFontPixelHeight - _doubleDescent
    property var    _rgFontSizeTightHeights:        [ _tightDefaultFontHeight * _rgFontSizeRatios[0] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[1] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[2] + 2, _tightDefaultFontHeight * _rgFontSizeRatios[3] + 2 ]
    property real   _tightHeight:                   _rgFontSizeTightHeights[instrumentValueData.factValueGrid.fontSize]
    property real   _fontSize:                      _rgFontSizes[instrumentValueData.factValueGrid.fontSize]
    property real   _horizontalLabelSpacing:        ScreenTools.defaultFontPixelWidth

    // Value için dikdörtgen container
    Rectangle {
        id: valueContainer
        Layout.fillWidth: true
        Layout.preferredHeight: _tightHeight + 5
        Layout.topMargin: 1.5
        Layout.bottomMargin: 1.5
        Layout.leftMargin: 1
        color: "transparent"
        border.color: instrumentValueData.isValidColor(instrumentValueData.currentColor) ? instrumentValueData.currentColor : qgcPal.text
        border.width: 1
        radius: 3
        opacity: instrumentValueData.currentOpacity * 1

        // Value label'ı - dikdörtgen içinde
        Text {
            id: label
            anchors.fill: parent
            anchors.margins: 2
            color: "#FFFFFF"
            text: valueText()
            font.pixelSize: 14
            font.family: ScreenTools.normalFontFamily
            antialiasing: true
            elide: Text.ElideRight  // Uzun text'leri ... ile kısalt

            function valueText() {
                if (instrumentValueData.fact) {
                    return instrumentValueData.fact.enumOrValueString + (instrumentValueData.showUnits ? " " + instrumentValueData.fact.units : "")
                } else {
                    return qsTr("--.--")
                }
            }
        }

        // Value altı çizgisi - dikdörtgenin içinde
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: instrumentValueData.isValidColor(instrumentValueData.currentColor) ? instrumentValueData.currentColor : qgcPal.text
            opacity: instrumentValueData.currentOpacity * 0.5
        }
    }
}











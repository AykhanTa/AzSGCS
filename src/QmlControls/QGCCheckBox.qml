import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls


CheckBox {
    id:             control
    spacing:        _noText ? 0 : ScreenTools.defaultFontPixelWidth
    focusPolicy:    Qt.ClickFocus

    property color  textColor:          _qgcPal.text
    property bool   textBold:           false
    property real   textFontPointSize:  ScreenTools.defaultFontPointSize

    property var    _qgcPal: QGCPalette { colorGroupEnabled: enabled }
    property bool   _noText: text === ""

    property ButtonGroup buttonGroup: null
    onButtonGroupChanged: {
        if (buttonGroup) {
            buttonGroup.addButton(control)
        }
    }

    contentItem: Text {
        //implicitWidth:  _noText ? 0 : text.implicitWidth + ScreenTools.defaultFontPixelWidth * 0.25
        //implicitHeight: _noText ? 0 : Math.max(text.implicitHeight, ScreenTools.checkBoxIndicatorSize)
        leftPadding:        control.indicator.width + control.spacing
        verticalAlignment:  Text.AlignVCenter
        text:               control.text
        font.pointSize:     textFontPointSize
        font.bold:          control.textBold
        font.family:        ScreenTools.normalFontFamily
        color:              control.textColor
    }

    property color accentColor: "#00C853"

    HoverHandler { id: checkHover; enabled: control.enabled }

    indicator:  Rectangle {
        implicitWidth:  ScreenTools.implicitCheckBoxHeight
        implicitHeight: implicitWidth
        x:              control.leftPadding
        y:              parent.height / 2 - height / 2
        radius:         4
        opacity:        control.checkedState === Qt.PartiallyChecked ? 0.5 : 1

        // İşarələnmiş qutu yaşıl dolur, boş qutu şəffaf qalır — beləliklə
        // vəziyyət ağ kvadratın içindəki kiçik nişandan deyil, rəngdən oxunur.
        color: control.checked
               ? (control.enabled ? control.accentColor : "#5A5A5A")
               : "transparent"
        border.width: 2
        border.color: control.checked
                      ? (control.enabled ? control.accentColor : "#5A5A5A")
                      : (control.enabled && checkHover.hovered ? control.accentColor : "#8A8A8A")

        Behavior on color        { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        QGCColoredImage {
            source:             "/qmlimages/checkbox-check.svg"
            color:              "#101010"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            width:              parent.implicitWidth * 0.7
            height:             width
            sourceSize.height:  height
            visible:            control.checked
            anchors.centerIn:   parent
        }

        // Qismən işarələnmiş vəziyyət
        Rectangle {
            anchors.centerIn:   parent
            width:              parent.implicitWidth * 0.5
            height:             2
            radius:             1
            color:              "#101010"
            visible:            control.checkedState === Qt.PartiallyChecked
        }
    }
}

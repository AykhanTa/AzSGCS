import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls


CheckBox {
    id:             control
    spacing:        _noText ? 0 : ScreenTools.defaultFontPixelWidth
    focusPolicy:    Qt.ClickFocus

    property color  textColor:          _az ? AzTheme.textCard : _qgcPal.text
    property bool   textBold:           false
    property real   textFontPointSize:  ScreenTools.defaultFontPointSize
    /// Opt in where the row is tall enough for two lines; the default keeps every
    /// existing checkbox exactly one line high.
    property int    textWrapMode:       Text.NoWrap

    property var    _qgcPal: QGCPalette { colorGroupEnabled: enabled }
    property bool   _noText: text === ""
    // The new design's look for screens that ask for it by declaring
    // `readonly property bool azInputStyle: true` on their root (the Plan view so far);
    // everywhere else the control keeps its old look.
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

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
        font.family:        control._az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
        color:              control.textColor
        // Where the control is narrower than its label -- an anchored checkbox in a
        // form row, say -- the text used to keep painting straight over whatever sat
        // beside it. It gives way now instead.
        wrapMode:           control.textWrapMode
        elide:              Text.ElideRight
    }

    property color accentColor: _az ? AzTheme.statusGreen : "#00C853"

    HoverHandler { id: checkHover; enabled: control.enabled }

    indicator:  Rectangle {
        implicitWidth:  ScreenTools.implicitCheckBoxHeight
        implicitHeight: implicitWidth
        x:              control.leftPadding
        y:              parent.height / 2 - height / 2
        radius:         control._az ? AzTheme.px(5) : 4
        opacity:        control.checkedState === Qt.PartiallyChecked ? 0.5 : 1

        // İşarələnmiş qutu yaşıl dolur, boş qutu şəffaf qalır — beləliklə
        // vəziyyət ağ kvadratın içindəki kiçik nişandan deyil, rəngdən oxunur.
        color: control.checked
               ? (control.enabled ? control.accentColor : "#5A5A5A")
               : "transparent"
        border.width: control._az ? 1.5 : 2
        border.color: control.checked
                      ? (control.enabled ? control.accentColor : "#5A5A5A")
                      : (control.enabled && checkHover.hovered ? control.accentColor
                                                               : (control._az ? AzTheme.cardHoverBorder : "#8A8A8A"))

        Behavior on color        { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        QGCColoredImage {
            source:             "/qmlimages/checkbox-check.svg"
            color:              control._az ? AzTheme.textPrimary : "#101010"
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

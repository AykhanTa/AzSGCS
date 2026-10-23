
import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

/// Name of a telemetry value in the card style of the design ("A: ↑", "ALT (Rel)"):
/// the label in grey Poppins, followed by the value's icon when it has one.
RowLayout {
    property var    instrumentValueData:        null

    readonly property bool  _iconVisible: instrumentValueData.rangeType === InstrumentValueData.IconSelectRange || instrumentValueData.icon
    readonly property bool  _hasColor:    instrumentValueData.isValidColor(instrumentValueData.currentColor)
    readonly property real  _fontPx:      AzTheme.fontPx(14)

    spacing: AzTheme.px(10)
    opacity: instrumentValueData.currentOpacity

    Text {
        id:                 labelText
        Layout.alignment:   Qt.AlignVCenter
        Layout.fillWidth:   !valueIcon.visible
        visible:            instrumentValueData.text !== ""
        elide:              Text.ElideRight
        text:               instrumentValueData.text + (valueIcon.visible ? ":" : "")
        color:              _hasColor ? instrumentValueData.currentColor : AzTheme.textSecondary
        font.family:        AzTheme.fontFamily
        font.pixelSize:     _fontPx
    }

    QGCColoredImage {
        id:                         valueIcon
        Layout.alignment:           Qt.AlignVCenter
        Layout.preferredHeight:     Math.round(_fontPx * 1.3)
        Layout.preferredWidth:      Layout.preferredHeight
        sourceSize.height:          height
        fillMode:                   Image.PreserveAspectFit
        mipmap:                     true
        smooth:                     true
        visible:                    _iconVisible && source != ""
        color:                      _hasColor ? instrumentValueData.currentColor : AzTheme.textCard

        readonly property string iconPrefix: "/InstrumentValueIcons/"

        function updateIcon() {
            if (instrumentValueData.rangeType === InstrumentValueData.IconSelectRange) {
                valueIcon.source = instrumentValueData.currentIcon != "" ? iconPrefix + instrumentValueData.currentIcon : "";
            } else if (instrumentValueData.icon) {
                valueIcon.source = instrumentValueData.icon != "" ? iconPrefix + instrumentValueData.icon : "";
            } else {
                valueIcon.source = ""
            }
        }

        Connections {
            target:                 instrumentValueData
            function onRangeTypeChanged() { valueIcon.updateIcon() }
            function onCurrentIconChanged() { valueIcon.updateIcon() }
            function onIconChanged() { valueIcon.updateIcon() }
        }

        Component.onCompleted:      updateIcon();
    }

    Item {
        Layout.fillWidth: valueIcon.visible
    }
}

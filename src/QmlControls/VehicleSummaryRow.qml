import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

RowLayout {
    property string labelText: "Label"
    property string valueText: "value"

    // The new design's look (see QGCLabel._az): the label grey, the value white.
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    width: parent.width

    QGCPalette { id: rowPal; colorGroupEnabled: label.enabled }

    QGCLabel {
        id:     label
        text:   labelText
        color:  _az ? AzTheme.textSecondary : rowPal.text
    }
    QGCLabel {
        text:                   valueText
        elide:                  Text.ElideRight
        horizontalAlignment:    Text.AlignRight
        Layout.fillWidth:       true
    }
}

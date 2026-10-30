import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls


Text {
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    _az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
    color:          _az ? AzTheme.textCard : qgcPal.text
    antialiasing:   true

    // The new design's look for screens that ask for it by declaring
    // `readonly property bool azInputStyle: true` on their root (the Plan view so far);
    // everywhere else the control keeps its old look.
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
}

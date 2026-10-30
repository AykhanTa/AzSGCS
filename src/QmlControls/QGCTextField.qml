import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls


TextField {
    id:                 control
    color:              _az ? AzTheme.textCard : qgcPal.textFieldText
    selectionColor:     _az ? AzTheme.statusBlue : qgcPal.textFieldText
    selectedTextColor:  _az ? AzTheme.textPrimary : qgcPal.textField
    activeFocusOnPress: true
    antialiasing:       true
    font.pointSize:     ScreenTools.defaultFontPointSize
    font.family:        _az ? AzTheme.fontFamily : ScreenTools.normalFontFamily
    inputMethodHints:   numericValuesOnly && !ScreenTools.isiOS ?
                            Qt.ImhFormattedNumbersOnly:  // Forces use of virtual numeric keyboard instead of full keyboard
                            Qt.ImhNone                   // iOS numeric keyboard has no done button, we can't use it.
    leftPadding:        _marginPadding
    rightPadding:       _marginPadding + unitsHelpLayout.width
    topPadding:         _marginPadding
    bottomPadding:      _marginPadding
    EnterKey.type:      Qt.EnterKeyDone

    property bool   showUnits:          false
    property bool   showHelp:           false
    property string unitsLabel:         ""
    property string extraUnitsLabel:    ""
    property bool   numericValuesOnly:  false   // true: Used as hint for mobile devices to show numeric only keyboard
    property alias  textColor:          control.color
    property bool   validationError:    false

    // The new design's look for screens that ask for it by declaring
    // `readonly property bool azInputStyle: true` on their root (the Plan view so far);
    // everywhere else the control keeps its old look.
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    property real _helpLayoutWidth: 0
    property real _marginPadding:   ScreenTools.defaultFontPixelHeight / 3

    signal helpClicked

    Component.onCompleted: checkActiveFocus()
    onActiveFocusChanged: checkActiveFocus()

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    onEditingFinished: {
        if (ScreenTools.isMobile) {
            // Toss focus on mobile after Done on virtual keyboard. Prevent strange interactions.
            focus = false
        }
    }

    function checkActiveFocus() {
        if (activeFocus) {
            selectAll()
            if (validationError) {
                validationToolTip.visible = true
            }
        } else {
            validationToolTip.visible = false
        }
    }

    function showValidationError(errorString, originalValidValue = undefined, preventViewSiwtch = true) {
        validationToolTip.text = errorString
        validationToolTip.originalValidValue = originalValidValue
        validationToolTip.visible = true
        if (!validationError) {
            validationError = true
            if (preventViewSiwtch) {
                globals.validationErrorCount++
            }
        }
    }

    function clearValidationError(preventViewSiwtch = true) {
        validationToolTip.visible = false
        validationToolTip.originalValidValue = undefined
        if (validationError) {
            validationError = false
            if (preventViewSiwtch) {
                globals.validationErrorCount--
            }
        }
    }

    background: Rectangle {
        // Az: the dark pill of the top bar panels, blue while editing
        border.width:   control.validationError ? 2 : ((control._az || qgcPal.globalTheme === QGCPalette.Light) ? 1 : 0)
        border.color:   control.validationError ? (control._az ? AzTheme.statusRed : qgcPal.colorRed)
                                                : (control._az ? (control.activeFocus ? AzTheme.activeBorder : AzTheme.panelBorder)
                                                               : qgcPal.buttonBorder)
        radius:         control._az ? AzTheme.px(8) : ScreenTools.buttonBorderRadius
        color:          control._az ? AzTheme.pillBottom : qgcPal.textField
        implicitWidth:  ScreenTools.implicitTextFieldWidth
        implicitHeight: ScreenTools.implicitTextFieldHeight

        RowLayout {
            id:                     unitsHelpLayout
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.right:          parent.right
            anchors.rightMargin:    control.activeFocus ? 2 : control._marginPadding
            spacing:                ScreenTools.defaultFontPixelWidth / 4
            layoutDirection:        Qt.RightToLeft

            Component.onCompleted:  control._helpLayoutWidth = unitsHelpLayout.width
            onWidthChanged:         control._helpLayoutWidth = unitsHelpLayout.width

            // Help button
            Rectangle {
                id:                     helpButton
                Layout.margins:         2
                Layout.leftMargin:      0
                Layout.rightMargin:     1
                Layout.fillHeight:      true
                Layout.preferredWidth:  helpLabel.contentWidth * 3
                Layout.alignment:       Qt.AlignVCenter
                color:                  control.color
                visible:                control.showHelp && control.activeFocus

                QGCLabel {
                    id:                 helpLabel
                    anchors.centerIn:   parent
                    color:              qgcPal.textField
                    text:               qsTr("?")
                }

            }

            // Extra units
            Text {
                Layout.alignment:   Qt.AlignVCenter
                text:               control.extraUnitsLabel
                font.pointSize:     ScreenTools.smallFontPointSize
                font.family:        control.font.family
                antialiasing:       true
                color:              control._az ? AzTheme.textSecondary : control.color
                visible:            control.showUnits && text !== ""
            }

            // Units
            Text {
                Layout.alignment:   Qt.AlignVCenter
                text:               control.unitsLabel
                font.pointSize:     control.activeFocus ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                font.family:        control.font.family
                antialiasing:       true
                color:              control._az ? AzTheme.textSecondary : control.color
                visible:            control.showUnits && text !== ""
            }
        }
    }

    ToolTip {
        id: validationToolTip

        property var originalValidValue: undefined

        QGCMouseArea {
            anchors.fill: parent
            onClicked: {
                if (validationToolTip.originalValidValue !== undefined) {
                    control.text = validationToolTip.originalValidValue
                    control.clearValidationError()
                }
            }
        }
    }

    MouseArea {
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        width:          control._helpLayoutWidth
        enabled:        helpButton.visible
        onClicked:      control.helpClicked()
    }
}

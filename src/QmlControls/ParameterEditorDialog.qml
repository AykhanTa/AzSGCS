/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls



import QGroundControl.FactControls


QGCPopupDialog {
    id:         root
    title:      fact.componentId > 0 ? fact.name : qsTr("Value Editor")

    buttons:    Dialog.Save | (validate ? 0 : Dialog.Cancel)

    property Fact   fact
    property bool   showRCToParam:  false
    property bool   validate:       false
    property string validateValue
    property bool   setFocus:       true    ///< true: focus is set to text field on display, false: focus not set (works around strange virtual keyboard bug with FactValueSlider

    property real   _editFieldWidth:            ScreenTools.defaultFontPixelWidth * 20
    property bool   _longDescriptionAvailable:  fact.longDescription != ""
    property bool   _editingParameter:          fact.componentId != 0
    property bool   _allowForceSave:            QGroundControl.corePlugin.showAdvancedUI && _editingParameter
    property bool   _allowDefaultReset:         fact.defaultValueAvailable
    property bool   _showCombo:                 fact.enumStrings.length !== 0 && fact.bitmaskStrings.length === 0 && !validate

    ParameterEditorController { id: controller; }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    onAccepted: {
        if (bitmaskColumn.visible && !manualEntry.checked) {
            fact.value = bitmaskValue();
            fact.valueChanged(fact.value)
        } else if (factCombo.visible && !manualEntry.checked) {
            fact.enumIndex = factCombo.currentIndex
        } else {
            var errorString = fact.validate(valueField.text, forceSave.checked)
            if (errorString === "") {
                fact.value = valueField.text
                fact.valueChanged(fact.value)
            } else {
                validationError.text = errorString
                if (_allowForceSave) {
                    forceSave.visible = true
                }
                preventClose = true
            }
        }
    }

    function bitmaskValue() {
        var value = 0;
        for (var i = 0; i < fact.bitmaskValues.length; ++i) {
            var checkbox = bitmaskRepeater.itemAt(i)
            if (checkbox.checked) {
                value |= fact.bitmaskValues[i];
            }
        }
        return value
    }

    Component.onCompleted: {
        if (validate) {
            valueField.text = validateValue
            validationError.text = fact.validate(validateValue, false /* convertOnly */)
            if (_allowForceSave) {
                forceSave.visible = true
            }
        } else {
            valueField.text = fact.valueString
        }
    }

    ColumnLayout {
        width:      Math.min(mainWindow.width * .75, Math.max(AzTheme.px(560), editRow.width))
        spacing:    AzTheme.px(14)

        // A red-tinted box with the validation error
        Rectangle {
            Layout.fillWidth:   true
            implicitHeight:     validationError.implicitHeight + AzTheme.px(20)
            visible:            validationError.text !== ""
            radius:             AzTheme.px(AzTheme.groupRadius)
            color:              Qt.rgba(1, 52 / 255, 67 / 255, 0.10)
            border.width:       1
            border.color:       Qt.rgba(1, 52 / 255, 67 / 255, 0.55)

            QGCLabel {
                id:                 validationError
                anchors.fill:       parent
                anchors.margins:    AzTheme.px(10)
                wrapMode:           Text.WordWrap
                verticalAlignment:  Text.AlignVCenter
                color:              AzTheme.statusRed
            }
        }

        RowLayout {
            id:         editRow
            spacing:    AzTheme.px(10)

            QGCTextField {
                id:                 valueField
                width:              _editFieldWidth
                unitsLabel:         fact.units
                showUnits:          fact.units != ""
                focus:              setFocus && visible
                inputMethodHints:   (fact.typeIsString || ScreenTools.isiOS) ? // iOS numeric keyboard has no done button, we can't use it
                                        Qt.ImhNone :
                                        Qt.ImhFormattedNumbersOnly  // Forces use of virtual numeric keyboard
                visible:            !_showCombo || validate || manualEntry.checked
            }

            QGCComboBox {
                id:             factCombo
                width:          _editFieldWidth
                model:          fact.enumStrings
                sizeToContents: true
                visible:        _showCombo
                focus:          setFocus && visible

                Component.onCompleted: {
                    // We can't bind directly to fact.enumIndex since that would add an unknown value
                    // if there are no enum strings.
                    if (_showCombo) {
                        currentIndex = fact.enumIndex
                    }
                }

                onCurrentIndexChanged: {
                    if (currentIndex >=0 && currentIndex < model.length) {
                        valueField.text = fact.enumValues[currentIndex]
                    }
                }
            }

            QGCButton {
                visible:    _allowDefaultReset
                text:       qsTr("Defoltlara sıfırlayın")

                onClicked: {
                    fact.value = fact.defaultValue
                    fact.valueChanged(fact.value)
                    close()
                }
            }
        }

        Column {
            id:         bitmaskColumn
            spacing:    AzTheme.px(8)
            visible:    fact.bitmaskStrings.length > 0

            Repeater {
                id:     bitmaskRepeater
                model:  fact.bitmaskStrings

                delegate : QGCCheckBox {
                    text : modelData
                    checked : fact.value & fact.bitmaskValues[index]

                    onClicked: {
                        valueField.text = bitmaskValue()
                    }
                }
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:           Text.WordWrap
            visible:            !longDescriptionLabel.visible
            color:              AzTheme.textSecondary
            text:               fact.shortDescription
        }

        QGCLabel {
            id:                 longDescriptionLabel
            Layout.fillWidth:   true
            color:              AzTheme.textSecondary
            wrapMode:           Text.WordWrap
            visible:            fact.longDescription != ""
            text:               fact.longDescription
        }

        // The limits as small pills: the name in grey, the value in white
        Flow {
            Layout.fillWidth:   true
            spacing:            AzTheme.px(8)
            visible:            !fact.minIsDefaultForType || !fact.maxIsDefaultForType || _allowDefaultReset

            component LimitPill: Rectangle {
                property string name
                property string value

                width:          pillRow.implicitWidth + AzTheme.px(20)
                height:         AzTheme.px(AzTheme.pillHeight)
                radius:         height / 2
                border.width:   1
                border.color:   AzTheme.groupBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.pillTop }
                    GradientStop { position: 1; color: AzTheme.pillBottom }
                }

                Row {
                    id:                 pillRow
                    anchors.centerIn:   parent
                    spacing:            AzTheme.px(6)

                    QGCLabel { text: name;  color: AzTheme.textSecondary }
                    QGCLabel { text: value; font.weight: Font.Medium }
                }
            }

            LimitPill {
                id:         minPill
                name:       qsTr("Min")
                value:      fact.minString
                visible:    !fact.minIsDefaultForType
            }

            LimitPill {
                id:         maxPill
                name:       qsTr("Max")
                value:      fact.maxString
                visible:    !fact.maxIsDefaultForType
            }

            LimitPill {
                id:         defaultPill
                name:       qsTr("Defolt")
                value:      fact.defaultValueString
                visible:    _allowDefaultReset
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:   Text.WordWrap
            color:      AzTheme.statusOrange
            visible:    fact.vehicleRebootRequired
            text:       qsTr("Dəyişiklikdən sonra təyyarənin yenidən işə salınması tələb olunur")
        }

        QGCLabel {
            Layout.fillWidth:   true
            wrapMode:   Text.WordWrap
            color:      AzTheme.statusOrange
            visible:    fact.qgcRebootRequired
            text:       qsTr("Dəyişiklikdən sonra tətbiqin yenidən başlaması tələb olunur")
        }

        // An orange-tinted box with the in-flight warning
        Rectangle {
            Layout.fillWidth:   true
            implicitHeight:     warningRow.implicitHeight + AzTheme.px(20)
            visible:            fact.componentId != -1
            radius:             AzTheme.px(AzTheme.groupRadius)
            color:              Qt.rgba(1, 159 / 255, 26 / 255, 0.10)
            border.width:       1
            border.color:       Qt.rgba(1, 159 / 255, 26 / 255, 0.55)

            RowLayout {
                id:                 warningRow
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.top:        parent.top
                anchors.margins:    AzTheme.px(10)
                spacing:            AzTheme.px(10)

                QGCColoredImage {
                    Layout.alignment:       Qt.AlignTop
                    Layout.preferredWidth:  AzTheme.px(20)
                    Layout.preferredHeight: AzTheme.px(20)
                    source:                 "qrc:/res/AZSHIELD_ICON/bx_error.svg"
                    sourceSize.height:      AzTheme.px(20)
                    fillMode:               Image.PreserveAspectFit
                    color:                  AzTheme.statusOrange
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    wrapMode:   Text.WordWrap
                    text:       qsTr("Xəbərdarlıq: Təyyarənin uçuşda olduğu zaman dəyərlərin dəyişdirilməsi təyyarənin qeyri-sabitliyinə və mümkün təyyarə itkisinə səbəb ola bilər. ") +
                                qsTr("Nə etdiyinizi bildiyinizə əmin olun və Saxlamadan əvvəl dəyərlərinizi iki dəfə yoxlayın!")
                }
            }
        }

        QGCCheckBox {
            id:         forceSave
            visible:    false
            text:       qsTr("Məcburi saxlama (Təhlükəli!)")
        }

        QGCCheckBox {
            id:         _advanced
            text:       qsTr("Qabaqcıl parametrlər")
            visible:    showRCToParam || factCombo.visible || bitmaskColumn.visible
        }

        // Checkbox to allow manual entry of enumerated or bitmask parameters
        QGCCheckBox {
            id:         manualEntry
            visible:    _advanced.checked && (factCombo.visible || bitmaskColumn.visible)
            text:       qsTr("Manual Giriş")

            onClicked: {
                valueField.text = fact.valueString
            }
        }

        QGCButton {
            text:       qsTr("Set RC to Param")
            visible:    _advanced.checked && !validate && showRCToParam
            onClicked:  rcToParamDialog.createObject(mainWindow).open()
        }
    } // Column

    Component {
        id: rcToParamDialog

        RCToParamDialog {
            tuningFact: fact
        }
    }
}

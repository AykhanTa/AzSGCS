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



// Provides the standard dialog mechanism for QGC. Works 99% like Qml Dialog.
//
// Example usage:
//      Component {
//          id: dialogComponent
//
//          QGCPopupDialog {
//              ...
//          }
//      }
//
//      onFoo: dialogComponent.createObject(mainWindow).open()
//
// Notes:
//  * QGCPopupDialog should be created from a component to limit the memory usage of the dialog
//      to only when it is displayed.
//  * Parent for createObject should always be mainWindow.
// Differences from standard Qml Dialog:
//  * The QGCPopupDialog object will automatically be destroyed when it closed. You can override this
//      behaviour by setting destroyOnClose to false if it was not created dynamically.
//  * Dialog will automatically close after accepted/rejected signal processing. You can prevent this by setting
//      preventClose = true prior to returning from your signal handlers.
Popup {
    id:                 root
    width:  mainWindow.width
    height: mainWindow.height
    parent:             Overlay.overlay
    modal:              true
    focus:              true
    margins:            0

    property string title
    property var    buttons:                Dialog.Ok
    property alias  acceptButtonEnabled:    acceptButton.enabled
    property alias  rejectButtonEnabled:    rejectButton.enabled
    property var    dialogProperties
    property bool   destroyOnClose:         true
    property bool   preventClose:           false
    
    readonly property real headerMinWidth: titleLable.implicitWidth + rejectButton.width + acceptButton.width + titleRowLayout.spacing * 2

    signal accepted
    signal rejected

    property var    _qgcPal:            QGroundControl.globalPalette

    // Kiçik ekranlarda (G30/G20) başlıq sətri çox vaxt məzmundan geniş çıxır:
    // dialoq lazımsız böyüyür və məzmunun sağında boş zolaq qalır.
    readonly property bool _compact:    ScreenTools.isShortScreen

    property real   _frameSize:         ScreenTools.defaultFontPixelWidth
    property real   _contentMargin:     ScreenTools.defaultFontPixelHeight * (_compact ? 0.35 : 0.5)
    property bool   _acceptAllowed:     acceptButton.visible
    property bool   _rejectAllowed:     rejectButton.visible
    property int    _previousValidationErrorCount: 0

    // Dialoq dizaynı
    property color dialogColor:     "#2A2A2A"
    property color dialogBorder:    "#6E6E6E"
    property color dialogContentBg: "#1E1E1E"

    background: Item {
        width:  mainWindow.width
        height: mainWindow.height

        // Arxa fonu qaraldan qat — dialoq xəritənin üstündə itməsin
        Rectangle {
            anchors.fill:   parent
            color:          "#000000"
            opacity:        0.45
        }

        QGCMouseArea {
            anchors.fill: parent

            onClicked: {
                if (closePolicy & Popup.CloseOnPressOutside) {
                    _reject()
                }
            }
        }
    }

    Component.onCompleted: {
        // The last child item will be the true dialog content.
        // Re-Parent it to the right place in the ui hierarchy.
        contentChildren[contentChildren.length - 1].parent = dialogContentParent
    }

    onAboutToShow: {
        _previousValidationErrorCount = globals.validationErrorCount
        setupDialogButtons(buttons)
    }

    onClosed: {
        globals.validationErrorCount = _previousValidationErrorCount
        Qt.inputMethod.hide()
        if (destroyOnClose) {
            root.destroy()
        }
    }

    function _accept() {
        if (_acceptAllowed && mainWindow.allowViewSwitch(_previousValidationErrorCount)) {
            accepted()
            if (preventClose) {
                preventClose = false
            } else {
                close()
            }
        }
    }

    function _reject() {
        // Dialogs with cancel button are allowed to close with validation errors
        if (_rejectAllowed && ((buttons & Dialog.Cancel) || mainWindow.allowViewSwitch(_previousValidationErrorCount))) {
            rejected()
            if (preventClose) {
                preventClose = false
            } else {
                close()
            }
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: parent.enabled }

    function setupDialogButtons(buttons) {
        acceptButton.visible = false
        rejectButton.visible = false
        // Accept role buttons
        if (buttons & Dialog.Ok) {
            acceptButton.text = qsTr("Bəli")
            acceptButton.visible = true
        } else if (buttons & Dialog.Open) {
            acceptButton.text = qsTr("Aç")
            acceptButton.visible = true
        } else if (buttons & Dialog.Save) {
            acceptButton.text = qsTr("Yadda saxla")
            acceptButton.visible = true
        } else if (buttons & Dialog.Apply) {
            acceptButton.text = qsTr("Tətbiq et")
            acceptButton.visible = true
        } else if (buttons & Dialog.Open) {
            acceptButton.text = qsTr("Aç")
            acceptButton.visible = true
        } else if (buttons & Dialog.SaveAll) {
            acceptButton.text = qsTr("Hamısını Saxla")
            acceptButton.visible = true
        } else if (buttons & Dialog.Yes) {
            acceptButton.text = qsTr("Bəli")
            acceptButton.visible = true
        } else if (buttons & Dialog.YesToAll) {
            acceptButton.text = qsTr("Hamıya Bəli")
            acceptButton.visible = true
        } else if (buttons & Dialog.Retry) {
            acceptButton.text = qsTr("Təkrarla")
            acceptButton.visible = true
        } else if (buttons & Dialog.Reset) {
            acceptButton.text = qsTr("Sıfırla")
            acceptButton.visible = true
        } else if (buttons & Dialog.RestoreToDefaults) {
            acceptButton.text = qsTr("Defoltlara bərpa et")
            acceptButton.visible = true
        } else if (buttons & Dialog.Ignore) {
            acceptButton.text = qsTr("Nəzərə alma")
            acceptButton.visible = true
        }

        // Reject role buttons
        if (buttons & Dialog.Cancel) {
            rejectButton.text = qsTr("Ləğv et")
            rejectButton.visible = true
        } else if (buttons & Dialog.Close) {
            rejectButton.text = qsTr("Bağla")
            rejectButton.visible = true
        } else if (buttons & Dialog.No) {
            rejectButton.text = qsTr("Xeyr")
            rejectButton.visible = true
        } else if (buttons & Dialog.NoToAll) {
            rejectButton.text = qsTr("Hamıya yox")
            rejectButton.visible = true
        } else if (buttons & Dialog.Abort) {
            rejectButton.text = qsTr("İptal et")
            rejectButton.visible = true
        }

        closePolicy = Popup.NoAutoClose
        if (buttons & Dialog.Cancel) {
            closePolicy |= Popup.CloseOnEscape
        }
    }

    function disableAcceptButton() {
        acceptButton.enabled = false
    }

    Rectangle {
        x:              mainLayout.x - _contentMargin * 1.5
        y:              mainLayout.y - _contentMargin * 1.5
        width:          mainLayout.width + _contentMargin * 3
        height:         mainLayout.height + _contentMargin * 3
        color:          root.dialogColor
        radius:         14
        border.width:   1
        border.color:   root.dialogBorder
    }

    ColumnLayout {
        id:                 mainLayout
        anchors.centerIn:   parent
        x:          _contentMargin
        y:          _contentMargin
        spacing:    _contentMargin

        RowLayout {
            id:                     titleRowLayout
            Layout.fillWidth:       true
            spacing:                _contentMargin

            QGCLabel {
                id: titleLable
                Layout.fillWidth:   true
                text:               root.title
                font.pointSize:     root._compact ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                font.bold:          true
                color:              "#FFFFFF"
                verticalAlignment:	Text.AlignVCenter
                elide:              Text.ElideRight
            }

            QGCButton {
                id:                     rejectButton
                onClicked:              _reject()
                Layout.minimumWidth:    height * 1.8
            }

            QGCButton {
                id:                     acceptButton
                primary:                true
                onClicked:              _accept()
                Layout.minimumWidth:    height * 1.8
            }
        }

        // Başlığı məzmundan ayıran xətt
        Rectangle {
            Layout.fillWidth:       true
            Layout.preferredHeight: 1
            color:                  "#4A4A4A"
        }

        Rectangle {
            Layout.fillWidth:       true
            Layout.preferredWidth:  Math.min(maxAvailableWidth, totalContentWidth)
            Layout.preferredHeight: Math.min(maxAvailableHeight, totalContentHeight)
            color:                  root.dialogContentBg
            radius:                 10

            property real maxAvailableWidth:    mainWindow.width - _contentMargin * 4
            property real maxAvailableHeight:   mainWindow.height - titleRowLayout.height - _contentMargin * 6
            property real totalContentWidth:    dialogContentParent.childrenRect.width + _contentMargin * 2
            property real totalContentHeight:   dialogContentParent.childrenRect.height + _contentMargin * 2

            QGCFlickable {
                anchors.margins:    _contentMargin
                anchors.fill:       parent
                contentWidth:       dialogContentParent.childrenRect.width
                contentHeight:      dialogContentParent.childrenRect.height

                Item {
                    id:     dialogContentParent
                    focus:  true
                    // childrenRect is in this item's own coordinates, so it does
                    // not move with x -- no binding loop.
                    x:      Math.max(0, (parent.width - childrenRect.width) / 2)

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape && _rejectAllowed) {
                            _reject()
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }
}

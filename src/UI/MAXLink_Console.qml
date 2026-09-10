import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

import QGroundControl
import QGroundControl.Controls

AnalyzePage {
    id: analyzePage
    anchors.fill: parent

    // ✅ Üstdən/yanlardan AnalyzePage-in default boşluğunu minimuma endir
    anchors.margins: 0

    allowPopout: true

    // Default AnalyzePage title/description göstərməyək (öz kart headerimizi çəkirik)
    pageDescription: ""

    // ✅ Default headingColumn boşluğunu kəs
    headerComponent: Component { Item { width: 0; height: 0 } }

    // ---- Popout handling (SideMenu-də popout siqnalını heç kim tutmur deyə burda edirik)
    property var _popoutWindow: null

    onPopout: {
        if (!_popoutWindow) {
            _popoutWindow = popoutWindowComponent.createObject(null)
        }
        _popoutWindow.visible = true
        _popoutWindow.raise()
        _popoutWindow.requestActivate()
    }

    Component {
        id: popoutWindowComponent
        Window {
            id: w
            width: 1100
            height: 750
            visible: false
            title: qsTr("MAVLink Konsol")
            color: "#000000"

            Loader {
                anchors.fill: parent
                sourceComponent: consoleContent
            }

            onClosing: function(close) {
                analyzePage._popoutWindow = null
                close.accepted = true
                Qt.callLater(function() { w.destroy() })
            }
        }
    }

    pageComponent: consoleContent

    Component {
        id: consoleContent

        Item {
            id: root
            anchors.fill: parent

            // fallback size
            implicitWidth:  900
            implicitHeight: 600

            QGCPalette { id: qgcPal }

            // ---- responsive helpers
            readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
            readonly property real _fontH: _hasScreenTools ? ScreenTools.defaultFontPixelHeight : 14
            readonly property real _fontW: _hasScreenTools ? ScreenTools.defaultFontPixelWidth  : 8
            readonly property bool _compact: (width < 1050) || (height < 650) || (_hasScreenTools && ScreenTools.isShortScreen)

            // ✅ Üst boşluq minimum (0 yox, nazik xəttə yapışmasın deyə çox az)
            readonly property real _topGap: _compact ? 0 : Math.max(4, _fontH * 0.25)

            // ✅ Kartın ümumi margin-ləri bir az “sıx”
            readonly property real _outer: Math.max(8, _fontH * (_compact ? 0.45 : 0.60))
            readonly property real _pad:   Math.max(8, _fontH * (_compact ? 0.45 : 0.65))
            readonly property real _gap:   Math.max(8, _fontH * (_compact ? 0.40 : 0.60))

            // ✅ Sağdan eni azaltmaq üçün: ikon üçün yer saxla (yalnız böyük ekranda)
            readonly property real _rightReserve: (_compact || !analyzePage.allowPopout) ? 0 : Math.max(28, _fontH * 2.2)

            // Mobile üçün ayrıca command input (QGC kimi)
            readonly property bool _separateCommandInput: (_hasScreenTools ? ScreenTools.isMobile : false)

            MAVLinkConsoleController { id: conController }

            property bool isLoaded: false
            property int  _consoleOutputLen: 0

            function scrollToBottom() {
                if (consoleFlick.contentHeight > consoleFlick.height) {
                    consoleFlick.contentY = consoleFlick.contentHeight - consoleFlick.height
                }
            }

            function getCommand() {
                return textConsole.getText(_consoleOutputLen, textConsole.length)
            }

            function getCommandAndClear() {
                var command = getCommand()
                textConsole.remove(_consoleOutputLen, textConsole.length)
                return command
            }

            function pasteFromClipboard() {
                const cursor = textConsole.cursorPosition - _consoleOutputLen
                var command = getCommandAndClear()
                var command_pre = ""
                var command_post = command
                if (cursor > 0) {
                    command_pre = command.substr(0, cursor)
                    command_post = command.substr(cursor)
                }
                var command_leftover = conController.handleClipboard(command_pre) + command_post
                textConsole.insert(textConsole.length, command_leftover)
                textConsole.cursorPosition = textConsole.length - command_post.length
            }

            Connections {
                target: conController
                function onDataChanged(topLeft, bottomRight, roles) {
                    if (root.isLoaded) {
                        updateTimer.start()
                    }
                }
            }

            Timer {
                id: updateTimer
                interval: 30
                running: false
                repeat: false
                onTriggered: {
                    if (consoleFlick.atYEnd) {
                        var command = root.getCommand()
                        var cursor = textConsole.cursorPosition - root._consoleOutputLen

                        textConsole.text = conController.text
                        root._consoleOutputLen = textConsole.length

                        textConsole.insert(textConsole.length, command)
                        textConsole.cursorPosition = textConsole.length
                        root.scrollToBottom()

                        if (cursor >= 0) {
                            textConsole.cursorPosition = root._consoleOutputLen + cursor
                        }
                    } else {
                        updateTimer.start()
                    }
                }
            }

            Rectangle {
                id: card
                anchors.fill: parent

                // ✅ Üstdən minimal boşluq
                anchors.topMargin: root._topGap

                // ✅ Sağdan eni azaldırıq (reserve əlavə edirik)
                anchors.leftMargin:   root._outer
                anchors.rightMargin:  root._outer + root._rightReserve
                anchors.bottomMargin: root._outer

                color: "#2b2b2b"
                radius: 14
                border.width: 2
                border.color: "#444"
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root._pad
                    spacing: root._gap

                    // ===== Title + Description
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Math.max(4, root._fontH * 0.25)

                        QGCLabel {
                            text: qsTr("MAVLink Konsol")
                            font.bold: true
                            font.pixelSize: Math.round(Math.max(root._compact ? 15 : 20,
                                                                root._fontH * (root._compact ? 1.05 : 1.30)))
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        QGCLabel {
                            text: qsTr("Təyyarənin sistem qabığı ilə əlaqəni təmin edir.")
                            color: "#E8E8E8"
                            font.pixelSize: Math.round(Math.max(10, root._fontH * (root._compact ? 0.82 : 0.95)))
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: "#FFFFFF"
                            opacity: 0.12
                        }
                    }

                    // ===== Console frame
                    Rectangle {
                        id: consoleFrame
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#242424"
                        radius: 10
                        border.width: 1
                        border.color: "#3a3a3a"
                        clip: true

                        QGCFlickable {
                            id: consoleFlick
                            anchors.fill: parent
                            anchors.margins: Math.max(6, root._fontH * 0.40)

                            contentWidth: textConsole.width
                            contentHeight: textConsole.height

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                            TextArea.flickable: TextArea {
                                id: textConsole
                                width: consoleFlick.width

                                wrapMode: Text.WordWrap
                                readOnly: root._separateCommandInput
                                textFormat: TextEdit.RichText
                                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhMultiLine

                                text: "> "
                                focus: true

                                color: qgcPal.text
                                selectedTextColor: qgcPal.windowShade
                                selectionColor: qgcPal.text

                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.family: ScreenTools.fixedFontFamily

                                background: Rectangle { color: qgcPal.windowShade }

                                Component.onCompleted: {
                                    root.isLoaded = true
                                    root._consoleOutputLen = textConsole.length
                                    textConsole.cursorPosition = root._consoleOutputLen
                                    if (!root._separateCommandInput) {
                                        textConsole.forceActiveFocus()
                                    }
                                }

                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Tab) {
                                        event.accepted = true
                                    }
                                    if (event.matches(StandardKey.Cut)) {
                                        event.accepted = true
                                    }

                                    if (!event.matches(StandardKey.Copy) &&
                                        event.key !== Qt.Key_Escape &&
                                        event.key !== Qt.Key_Insert &&
                                        event.key !== Qt.Key_Pause &&
                                        event.key !== Qt.Key_Print &&
                                        event.key !== Qt.Key_SysReq &&
                                        event.key !== Qt.Key_Clear &&
                                        event.key !== Qt.Key_Home &&
                                        event.key !== Qt.Key_End &&
                                        event.key !== Qt.Key_Left &&
                                        event.key !== Qt.Key_Up &&
                                        event.key !== Qt.Key_Right &&
                                        event.key !== Qt.Key_Down &&
                                        event.key !== Qt.Key_PageUp &&
                                        event.key !== Qt.Key_PageDown &&
                                        event.key !== Qt.Key_Shift &&
                                        event.key !== Qt.Key_Control &&
                                        event.key !== Qt.Key_Meta &&
                                        event.key !== Qt.Key_Alt &&
                                        event.key !== Qt.Key_AltGr &&
                                        event.key !== Qt.Key_CapsLock &&
                                        event.key !== Qt.Key_NumLock &&
                                        event.key !== Qt.Key_ScrollLock &&
                                        event.key !== Qt.Key_Super_L &&
                                        event.key !== Qt.Key_Super_R &&
                                        event.key !== Qt.Key_Menu &&
                                        event.key !== Qt.Key_Hyper_L &&
                                        event.key !== Qt.Key_Hyper_R &&
                                        event.key !== Qt.Key_Direction_L &&
                                        event.key !== Qt.Key_Direction_R) {

                                        root.scrollToBottom()

                                        if (textConsole.selectionStart < root._consoleOutputLen) {
                                            textConsole.select(root._consoleOutputLen, textConsole.selectionEnd)
                                        }
                                        if (textConsole.cursorPosition < root._consoleOutputLen) {
                                            textConsole.cursorPosition = textConsole.length
                                        }
                                    }

                                    switch (event.key) {
                                    case Qt.Key_Left:
                                        if (textConsole.cursorPosition === root._consoleOutputLen) {
                                            event.accepted = true
                                        }
                                        break
                                    case Qt.Key_Backspace:
                                        if (textConsole.cursorPosition <= root._consoleOutputLen) {
                                            event.accepted = true
                                        }
                                        break
                                    case Qt.Key_Enter:
                                    case Qt.Key_Return:
                                        conController.sendCommand(root.getCommandAndClear())
                                        event.accepted = true
                                        break
                                    default:
                                        break
                                    }

                                    if (event.matches(StandardKey.Paste)) {
                                        root.pasteFromClipboard()
                                        event.accepted = true
                                    }

                                    if (event.key === Qt.Key_Up) {
                                        var cmdUp = conController.historyUp(root.getCommandAndClear())
                                        textConsole.insert(textConsole.length, cmdUp)
                                        textConsole.cursorPosition = textConsole.length
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Down) {
                                        var cmdDown = conController.historyDown(root.getCommandAndClear())
                                        textConsole.insert(textConsole.length, cmdDown)
                                        textConsole.cursorPosition = textConsole.length
                                        event.accepted = true
                                    }
                                }
                            }
                        }
                    }

                    // ===== Mobile command input (QGC kimi)
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root._separateCommandInput
                        spacing: Math.max(8, root._fontW * 1.2)

                        QGCTextField {
                            id: commandInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("Əmrləri bura daxil edin...")
                            inputMethodHints: Qt.ImhNoAutoUppercase
                            onAccepted: sendCommand()

                            function sendCommand() {
                                conController.sendCommand(text)
                                text = ""
                                root.scrollToBottom()
                            }
                        }

                        QGCButton {
                            text: qsTr("Göndər")
                            Layout.preferredWidth: Math.round(Math.max(90, root._fontW * 10))
                            onClicked: commandInput.sendCommand()
                        }
                    }
                }
            }
        }
    }
}

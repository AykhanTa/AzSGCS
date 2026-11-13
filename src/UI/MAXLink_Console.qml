import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

import QGroundControl
import QGroundControl.Controls

// MAVLink console, in the new design: the page header of the setup pages and the console on
// a group box inside a status card.
AnalyzePage {
    id: analyzePage
    anchors.fill: parent

    // The buttons, combo boxes, check boxes, labels and dialogs take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

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
            color: AzTheme.panelGradientEnd

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
            readonly property real _topGap: AzTheme.px(_compact ? 12 : 20)

            readonly property real _outer: AzTheme.px(_compact ? 12 : 20)
            readonly property real _pad:   AzTheme.px(_compact ? 12 : 16)
            readonly property real _gap:   AzTheme.px(_compact ? 10 : 16)

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

                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: root._gap

                    // ===== Header
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: AzTheme.px(6)

                        Text {
                            text: qsTr("MAVLink Konsol")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(root._compact ? 18 : 20)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: qsTr("Təyyarənin sistem qabığı ilə əlaqəni təmin edir.")
                            color: AzTheme.textSecondary
                            font.family: AzTheme.fontFamily
                            font.pixelSize: AzTheme.fontPx(13)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    // ===== Console frame
                    Rectangle {
                        id: consoleFrame
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: AzTheme.px(AzTheme.cardRadius)
                        border.width: 1
                        border.color: AzTheme.cardBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.cardGradientStart }
                            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                        }
                        clip: true

                        QGCFlickable {
                            id: consoleFlick
                            anchors.fill: parent
                            anchors.margins: root._pad

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

                                color: AzTheme.textCard
                                selectedTextColor: AzTheme.textPrimary
                                selectionColor: AzTheme.statusBlue

                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.family: ScreenTools.fixedFontFamily

                                padding: AzTheme.px(AzTheme.groupPadding)
                                background: Rectangle {
                                    radius: AzTheme.px(AzTheme.groupRadius)
                                    color: AzTheme.groupFill
                                    border.width: 1
                                    border.color: AzTheme.groupBorder
                                }

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
                            primary: true
                            Layout.preferredWidth: Math.round(Math.max(90, root._fontW * 10))
                            onClicked: commandInput.sendCommand()
                        }
                    }
                }
            }
        }
    }
}

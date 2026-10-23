import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

// The panel of the Status card: arming, the vehicle's messages, the health and arming
// problems and the sensor states. The title and the ARM row stay put; the rest scrolls.
AzPopupFrame {
    id: overlay

    panelVisible: false
    topPanelItem: statusPanelItem
    title:        qsTr("Status")

    onCloseRequested: close()

    // TopStatusPanel Loader ötürür (panelin yerini hesablayırıq)
    property var statusPanelItem: null

    // Vehicle refs
    readonly property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _checksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false
    function canArmNow() { return _activeVehicle ? (_checksSupported ? _activeVehicle.healthAndArmingCheckReport.canArm : true) : false }

    readonly property real _linePx:   AzTheme.px(AzTheme.groupLineHeight)
    readonly property real _groupPad: AzTheme.px(AzTheme.groupPadding)
    readonly property real _textPx:   AzTheme.fontPx(AzTheme.popupTextSize)

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    // ===================== Vehicle Messages (manual refresh, signal-based) =====================
    property string _vehicleMessagesHtml: ""
    property bool   _hasMessages:         false

    function _getFormattedMessagesRaw() {
        if (!_activeVehicle) return ""
        var raw = ""
        try {
            raw = _activeVehicle.formattedMessages
            if (typeof raw === "function") raw = raw.call(_activeVehicle)
        } catch (e) {
            raw = ""
        }
        if (raw === undefined || raw === null) raw = ""
        if (Array.isArray(raw)) raw = raw.join("<br>")
        return "" + raw
    }

    function _isMessageAtBottom() {
        var maxY = Math.max(0, messageFlick.contentHeight - messageFlick.height)
        return messageFlick.contentY >= (maxY - 8)
    }

    function _scrollMessageToBottom() {
        messageFlick.contentY = Math.max(0, messageFlick.contentHeight - messageFlick.height)
    }

    function _refreshVehicleMessages(forceBottom) {
        var stickToBottom = forceBottom || _isMessageAtBottom()
        var raw = _activeVehicle ? _getFormattedMessagesRaw() : ""

        overlay._hasMessages = raw.length > 0
        overlay._vehicleMessagesHtml = overlay._hasMessages ? formatMessage(raw) : ""

        Qt.callLater(function() {
            if (overlay.visible && stickToBottom) _scrollMessageToBottom()
        })
    }

    function open()  {
        overlay.panelVisible = true
        _refreshVehicleMessages(true)
    }
    function close() {
        overlay.panelVisible = false
    }

    // ================= PARAM LINK / PARAMETER DIALOG =================
    FactPanelController { id: factController }

    Component {
        id: paramEditorDialogComponent
        ParameterEditorDialog {
            title: qsTr("Parametri redaktə edin")
            destroyOnClose: true
        }
    }

    function handleLinkActivated(link) {
        if (!link || link === "") return

        if (link.indexOf("param://") === 0) {
            var paramName = link.substring("param://".length)
            var fact = factController.getParameterFact(-1, paramName, true)
            if (fact) {
                var parentObj = (typeof mainWindow !== "undefined" && mainWindow) ? mainWindow : (overlay.window ? overlay.window : overlay)
                var dlg = paramEditorDialogComponent.createObject(parentObj, { fact: fact })
                if (dlg) dlg.open()
            }
        } else {
            Qt.openUrlExternally(link)
        }
    }

    // Each message arrives as <font style="<#E|#I|#N>">[time comp] Severity: text</font><br/>.
    // Errors and worse are red, warnings and notices yellow, the rest white; every
    // message becomes a paragraph so the lines get the mock-up's spacing.
    function formatMessage(message) {
        if (!message) return ""
        var font = "font-family: '" + AzTheme.fontFamily + "'; font-size: " + overlay._textPx + "px;"
        var gap = Math.max(0, Math.round(overlay._linePx - overlay._textPx * 1.5))

        message = message.replace(new RegExp("<#E>", "g"), "color: " + AzTheme.statusRed + "; " + font)
        message = message.replace(new RegExp("<#I>", "g"), "color: " + AzTheme.warningText + "; " + font)
        message = message.replace(new RegExp("<#N>", "g"), "color: " + AzTheme.textCard + "; " + font)
        message = message.replace(new RegExp(" \\]", "g"), "]")
        message = message.replace(new RegExp("<font style=", "g"), "<p style=\"margin-top: 0; margin-bottom: " + gap + "px;\"><font style=")
        message = message.replace(new RegExp("</font><br/>", "g"), "</font></p>")
        return message
    }

    // RichText ignores Text.linkColor, so links get their colour from a style block.
    readonly property string _linkStyle: "<style>a { color: " + AzTheme.linkText + "; text-decoration: none; }</style>"

    function _sensorStatusText(status) {
        if (status === "Normal")   return qsTr("Normal")
        if (status === "Error")    return qsTr("Xəta")
        if (status === "Disabled") return qsTr("Söndürülüb")
        return status ? status : qsTr("Naməlum")
    }

    function _sensorStatusColor(status) {
        if (status === "Normal") return AzTheme.statusGreen
        if (status === "Error")  return AzTheme.statusRed
        return AzTheme.textSecondary
    }

    // ---------------- Arming (fixed) ----------------
    fixedContent: Item {
        width:  overlay.contentWidth
        height: armButton.height

        Text {
            anchors.left:           parent.left
            anchors.leftMargin:     AzTheme.px(10)
            anchors.right:          armButton.left
            anchors.rightMargin:    AzTheme.px(12)
            anchors.verticalCenter: parent.verticalCenter
            wrapMode:               Text.Wrap
            maximumLineCount:       2
            elide:                  Text.ElideRight
            text: {
                if (!_activeVehicle)       return qsTr("Aparat qoşulmayıb.")
                if (_activeVehicle.armed)  return qsTr("Motorlar aktivdir.")
                return qsTr("Uçuş üçün motorları aktivləşdirin.")
            }
            color:          AzTheme.textPrimary
            opacity:        _activeVehicle ? 1 : 0.6
            font.family:    AzTheme.fontFamily
            font.pixelSize: overlay._textPx
        }

        AzButton {
            id:                  armButton
            anchors.right:       parent.right
            anchors.rightMargin: AzTheme.px(20)
            text:                _activeVehicle && _activeVehicle.armed ? qsTr("DISARM") : qsTr("ARM")
            danger:              !!(_activeVehicle && _activeVehicle.armed)
            enabled:             !!(_activeVehicle && (_activeVehicle.armed || canArmNow()))
            onClicked: {
                if (!_activeVehicle) return
                if (_activeVehicle.armed) mainWindow.disarmVehicleRequest()
                else if (canArmNow()) mainWindow.armVehicleRequest()
            }
        }
    }

    // ---------------- Vehicle Message Panel ----------------
    AzSectionTitle {
        text: qsTr("Aparat mesajları")
    }

    Item {
        width:  overlay.contentWidth
        height: messageGroup.height

        AzGroup {
            id:              messageGroup
            width:           parent.width
            height:          overlay._hasMessages
                             ? Math.round(overlay._clamp(messageText.contentHeight + 2 * verticalPadding, overlay._linePx * 2, AzTheme.px(182)))
                             : overlay._linePx + 2 * verticalPadding
            verticalPadding: AzTheme.px(12)
            dividers:        false
            clip:            true

            Flickable {
                id:                 messageFlick
                x:                  overlay._groupPad
                width:              messageGroup.width - overlay._groupPad - trashButton.width - AzTheme.px(32)
                height:             messageGroup.height - 2 * messageGroup.verticalPadding
                clip:               true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior:     Flickable.StopAtBounds
                contentWidth:       width
                contentHeight:      messageText.contentHeight
                interactive:        contentHeight > height + 2

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                TextEdit {
                    id:             messageText
                    width:          messageFlick.width
                    height:         contentHeight
                    visible:        overlay._hasMessages
                    readOnly:       true
                    selectByMouse:  true
                    textFormat:     TextEdit.RichText
                    wrapMode:       TextEdit.Wrap
                    color:          AzTheme.textCard
                    font.family:    AzTheme.fontFamily
                    font.pixelSize: overlay._textPx
                    text:           overlay._vehicleMessagesHtml
                    onLinkActivated: function(link) { handleLinkActivated(link) }
                }

                Text {
                    height:            messageFlick.height
                    verticalAlignment: Text.AlignVCenter
                    visible:           !overlay._hasMessages
                    text:              _activeVehicle ? qsTr("Mesaj yoxdur") : qsTr("Heç bir aparat qoşulmayıb")
                    color:             AzTheme.textSecondary
                    font.family:       AzTheme.fontFamily
                    font.pixelSize:    overlay._textPx
                }
            }
        }

        AzIconButton {
            id:                  trashButton
            anchors.right:       parent.right
            anchors.rightMargin: AzTheme.px(26)
            y:                   messageGroup.verticalPadding + (overlay._linePx - height) / 2 + AzTheme.px(12)
            visible:             overlay._hasMessages
            iconSource:          "qrc:/res/AZSHIELD_ICON/v2/popup_trash.svg"
            iconSize:            AzTheme.px(20)
            onClicked: {
                if (_activeVehicle) _activeVehicle.clearMessages()
                Qt.callLater(function() { overlay._refreshVehicleMessages(true) })
            }
        }
    }

    // ---------------- Overall Status ----------------
    AzSectionTitle {
        visible: overallGroup.visible
        text:    qsTr("Ümumi Vəziyyət")
    }

    AzGroup {
        id:              overallGroup
        width:           overlay.contentWidth
        visible:         !!(_activeVehicle && _checksSupported &&
                            _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode.count > 0)
        verticalPadding: AzTheme.px(6)
        dividerInset:    AzTheme.px(8)

        Repeater {
            model: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode : null

            delegate: Item {
                width:  overallGroup.width
                height: problemText.y * 2 + problemText.height + (object.expanded ? descriptionText.height + AzTheme.px(4) : 0)

                readonly property bool _hasDescription: object.description !== ""

                Text {
                    id:            problemText
                    x:             overlay._groupPad
                    y:             Math.max(AzTheme.px(6), (overlay._linePx - implicitHeight) / 2)
                    width:         parent.width - x - (chevron.visible ? chevron.width + AzTheme.px(16) : overlay._groupPad)
                    wrapMode:      Text.Wrap
                    textFormat:    Text.RichText
                    text:          overlay._linkStyle + object.message
                    color: {
                        if (object.severity === "error")   return AzTheme.statusRed
                        if (object.severity === "warning") return AzTheme.warningText
                        return AzTheme.textCard
                    }
                    font.family:    AzTheme.fontFamily
                    font.pixelSize: overlay._textPx
                    onLinkActivated: function(link) { handleLinkActivated(link) }
                }

                AzIconButton {
                    id:                     chevron
                    anchors.right:          parent.right
                    anchors.rightMargin:    AzTheme.px(16)
                    anchors.verticalCenter: problemText.verticalCenter
                    visible:                parent._hasDescription
                    iconSource:             "qrc:/res/AZSHIELD_ICON/v2/popup_chevron.svg"
                    iconSize:               AzTheme.px(20)
                    rotation:               object.expanded ? 180 : 0
                    onClicked:              object.expanded = !object.expanded
                }

                MouseArea {
                    anchors.fill: problemText
                    enabled:      parent._hasDescription
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        var link = problemText.linkAt(mouseX, mouseY)
                        if (link) handleLinkActivated(link)
                        else object.expanded = !object.expanded
                    }
                }

                Text {
                    id:             descriptionText
                    x:              overlay._groupPad
                    y:              problemText.y + problemText.height + AzTheme.px(4)
                    width:          parent.width - x - overlay._groupPad
                    visible:        object.expanded
                    wrapMode:       Text.Wrap
                    textFormat:     Text.RichText
                    text:           overlay._linkStyle + object.description
                    color:          AzTheme.textCard
                    font.family:    AzTheme.fontFamily
                    font.pixelSize: overlay._textPx
                    onLinkActivated: function(link) { handleLinkActivated(link) }

                    HoverHandler { cursorShape: descriptionText.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor }
                }
            }
        }
    }

    // ---------------- Sensor Status ----------------
    AzSectionTitle {
        visible: sensorGroup.visible
        text:    qsTr("Sensor Vəziyyəti")
    }

    AzGroup {
        id:              sensorGroup
        width:           overlay.contentWidth
        visible:         !!(_activeVehicle && _activeVehicle.sysStatusSensorInfo && _activeVehicle.sysStatusSensorInfo.sensorNames &&
                            _activeVehicle.sysStatusSensorInfo.sensorNames.length > 0)
        verticalPadding: AzTheme.px(6)
        dividerInset:    AzTheme.px(8)

        Repeater {
            model: sensorGroup.visible ? _activeVehicle.sysStatusSensorInfo.sensorNames.length : 0

            delegate: Item {
                id:     sensorRow
                width:  sensorGroup.width
                height: overlay._linePx

                readonly property string _status: _activeVehicle && _activeVehicle.sysStatusSensorInfo.sensorStatus
                                                  ? _activeVehicle.sysStatusSensorInfo.sensorStatus[index] : ""
                readonly property color  _color:  overlay._sensorStatusColor(_status)

                Text {
                    x:                      overlay._groupPad
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  statusColumn.x - x - AzTheme.px(12)
                    elide:                  Text.ElideRight
                    text:                   _activeVehicle ? _activeVehicle.sysStatusSensorInfo.sensorNames[index] : ""
                    color:                  AzTheme.textCard
                    font.family:            AzTheme.fontFamily
                    font.pixelSize:         overlay._textPx
                }

                // Dot and state in a fixed column, so the states line up.
                Item {
                    id:                     statusColumn
                    anchors.right:          parent.right
                    anchors.rightMargin:    overlay._groupPad
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  statusDot.width + AzTheme.px(10) + widestStatus.advanceWidth
                    height:                 statusText.implicitHeight

                    TextMetrics {
                        id:             widestStatus
                        font:           statusText.font
                        text:           qsTr("Söndürülüb")
                    }

                    Rectangle {
                        id:                     statusDot
                        anchors.verticalCenter: parent.verticalCenter
                        width:                  Math.max(5, AzTheme.px(6))
                        height:                 width
                        radius:                 width / 2
                        color:                  sensorRow._color
                    }

                    Text {
                        id:                     statusText
                        anchors.left:           statusDot.right
                        anchors.leftMargin:     AzTheme.px(10)
                        anchors.right:          parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        elide:                  Text.ElideRight
                        text:                   overlay._sensorStatusText(sensorRow._status)
                        color:                  sensorRow._color
                        font.family:            AzTheme.fontFamily
                        font.pixelSize:         overlay._textPx
                    }
                }
            }
        }
    }

    // ✅ Mesajlar canlı yenilənsin
    Connections {
        target: _activeVehicle
        ignoreUnknownSignals: true

        function onNewFormattedMessage(message) {
            overlay._refreshVehicleMessages(false)
        }

        function onFormattedMessagesChanged() {
            overlay._refreshVehicleMessages(false)
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        ignoreUnknownSignals: true
        function onActiveVehicleChanged(activeVehicle) {
            Qt.callLater(function() { overlay._refreshVehicleMessages(true) })
        }
    }
}

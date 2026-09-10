import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id: overlay
    anchors.fill: parent
    color: "transparent"
    visible: false
    z: 1

    // TopStatusPanel Loader ötürür (panelin yerini hesablayırıq)
    property var statusPanelItem: null

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    function _wheelDeltaY(wheel) {
        if (wheel.pixelDelta && wheel.pixelDelta.y !== 0) return wheel.pixelDelta.y
        if (wheel.angleDelta && wheel.angleDelta.y !== 0) return wheel.angleDelta.y / 2
        return 0
    }

    readonly property bool _hasScreenTools: (typeof ScreenTools !== "undefined")
    readonly property real _fontPx: _hasScreenTools && ScreenTools.defaultFontPixelHeight !== undefined
                                 ? ScreenTools.defaultFontPixelHeight
                                 : Math.max(14, (Qt.application.font.pixelSize > 0 ? Qt.application.font.pixelSize : 14))
    readonly property real _fontPt: _hasScreenTools && ScreenTools.defaultFontPointSize !== undefined
                                 ? ScreenTools.defaultFontPointSize
                                 : Math.max(10, (Qt.application.font.pointSize > 0 ? Qt.application.font.pointSize : 10))

    readonly property real _margin:    Math.round(Math.max(10, _fontPx * 0.80))
    readonly property real _pad:       Math.round(Math.max(10, _fontPx * 0.80))
    readonly property real _closeSize: Math.round(_clamp(_fontPx * 1.25, 18, 22))

    // ✅ TopStatusPanel hündürlüyü qədər aşağıdan başlasın
    readonly property real _topInset: statusPanelItem ? statusPanelItem.height : 0

    // ✅ SideMenu bitdiyi yerdən başlasın (açıq/collapsed/kiçik ekran fərqi yoxdur)
    // Prioritet: mainWindow._leftInset (səndə var), fallback: statusPanelItem.x
    readonly property real _sideMenuInset: {
        if (typeof mainWindow !== "undefined" && mainWindow && mainWindow._leftInset !== undefined) {
            var v = mainWindow._leftInset
            return (v === undefined || v === null) ? 0 : v
        }
        if (statusPanelItem && statusPanelItem.x !== undefined) {
            return Math.max(0, statusPanelItem.x)
        }
        return 0
    }

    // SideMenu ilə panel arasında “biraz məsafə”
    readonly property real _sideMenuGap: Math.round(Math.max(8, _fontPx * 0.55))

    // Panelin soldan real başlanğıcı:
    // - SideMenu varsa: sideMenuEnd + gap
    // - Yoxdursa: standart margin
    readonly property real _panelLeftX: (_sideMenuInset > 0) ? (_sideMenuInset + _sideMenuGap) : _margin

    // Qalan boşluğa görə panel eni (kiçik ekranda da sığsın)
    readonly property real _availW: Math.max(120, overlay.width - _panelLeftX - _margin)
    readonly property real _availH: Math.max(140, overlay.height - _topInset - (_margin * 2))

    readonly property real _panelW: Math.round(Math.min(Math.min(520, Math.max(300, _availW)), _availW))
    readonly property real _panelH: Math.round(Math.min(Math.min(overlay.height * 0.82, Math.max(320, _availH)), _availH))

    readonly property real _panelHMax: _panelH
    readonly property real _panelHMin: 220

    // Vehicle refs
    readonly property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _checksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false
    function canArmNow() { return _activeVehicle ? (_checksSupported ? _activeVehicle.healthAndArmingCheckReport.canArm : true) : false }

    // ===================== Vehicle Messages (manual refresh, signal-based) =====================
    property string _vehicleMessagesHtml: ""

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
        if (!messageFlick) return true
        var maxY = Math.max(0, messageFlick.contentHeight - messageFlick.height)
        return messageFlick.contentY >= (maxY - 8)
    }

    function _scrollMessageToBottom() {
        if (!messageFlick) return
        var maxY = Math.max(0, messageFlick.contentHeight - messageFlick.height)
        messageFlick.contentY = maxY
    }

    function _refreshVehicleMessages(forceBottom) {
        var stickToBottom = forceBottom || _isMessageAtBottom()

        var html = ""
        if (!_activeVehicle) {
            html = qsTr("Heç bir təyyarə qoşulmayıb")
        } else {
            var raw = _getFormattedMessagesRaw()
            html = (raw && raw.length > 0) ? formatMessage(raw) : qsTr("Mesaj yoxdur")
        }

        overlay._vehicleMessagesHtml = html

        Qt.callLater(function() {
            if (overlay.visible && stickToBottom) _scrollMessageToBottom()
        })
    }

    function open()  {
        overlay.visible = true
        _refreshVehicleMessages(true)
    }
    function close() {
        overlay.visible = false
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

    function formatMessage(message) {
        if (!message) return ""
        var pt = Math.max(8, overlay._fontPt - 1).toFixed(0)

        message = message.replace(new RegExp("<#E>", "g"),
                                  "color: " + qgcPal.warningText + "; font: " + pt + "pt monospace;")
        message = message.replace(new RegExp("<#I>", "g"),
                                  "color: " + qgcPal.warningText + "; font: " + pt + "pt monospace;")
        message = message.replace(new RegExp("<#N>", "g"),
                                  "color: " + qgcPal.text + "; font: " + pt + "pt monospace;")
        return message
    }

    // ----------------------------
    // BACKDROP (klik + wheel ud)
    // ----------------------------
    MouseArea {
        id: backdrop
        anchors.fill: parent
        enabled: overlay.visible
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: false

        function clickedOutsidePanel(mx, my) {
            return !(mx >= panel.x && mx <= (panel.x + panel.width) &&
                     my >= panel.y && my <= (panel.y + panel.height))
        }

        onWheel: (wheel) => { wheel.accepted = true }
        onPressed:  (m)=> { m.accepted = true }
        onReleased: (m)=> { m.accepted = true }

        onClicked: (m)=> {
            m.accepted = true
            if (clickedOutsidePanel(m.x, m.y)) overlay.close()
        }
    }

    // ✅ Pinch udulsun (iki barmaq gesture pəncərəni dəyişməsin)
    PinchHandler {
        enabled: overlay.visible
        target: null
        acceptedDevices: PointerDevice.TouchScreen | PointerDevice.TouchPad
        grabPermissions: PointerHandler.CanTakeOverFromAnything
    }

    // ----------------------------
    // PANEL
    // ----------------------------
    Rectangle {
        id: panel
        width: overlay._panelW
        height: Math.round(_clamp(contentCol.implicitHeight + overlay._pad * 2, overlay._panelHMin, overlay._panelHMax))

        radius: 12
        color: "#2A2A2A"
        border.width: 1
        border.color: "#6E6E6E"
        clip: true

        // ✅ SideMenu bitən yerdən + gap
        x: Math.round(overlay._clamp(overlay._panelLeftX,
                                     overlay._margin,
                                     overlay.width - width - overlay._margin))

        y: Math.round(overlay._clamp(overlay._topInset + overlay._margin,
                                     overlay._margin,
                                     overlay.height - height - overlay._margin))

        Rectangle {
            id: closeIcon
            width:  overlay._closeSize + 10
            height: width
            radius: width / 2
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 6
            anchors.rightMargin: 6
            color: closeMouse.containsMouse ? "#4A4848" : "transparent"
            z: 10

            Behavior on color { ColorAnimation { duration: 110 } }

            Image {
                source: "qrc:/res/AZSHIELD_ICON/TopStatusPanel_Cixis.svg"
                width:  overlay._closeSize
                height: overlay._closeSize
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: overlay.close()
            }
        }

        // ----------------------------
        // OUTER SCROLL
        // ----------------------------
        QGCFlickable {
            id: contentFlick
            anchors.fill: parent
            anchors.margins: overlay._pad
            clip: true

            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            contentWidth: width
            contentHeight: contentCol.implicitHeight
            interactive: contentHeight > height + 2

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            WheelHandler {
                target: contentFlick
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (wheel) => {
                    var maxY = Math.max(0, contentFlick.contentHeight - contentFlick.height)
                    wheel.accepted = true
                    if (maxY <= 0) return
                    var dy = overlay._wheelDeltaY(wheel)
                    contentFlick.contentY = overlay._clamp(contentFlick.contentY - dy, 0, maxY)
                }
            }

            ColumnLayout {
                id: contentCol
                width: contentFlick.width
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        width:  20
                        height: 18
                        radius: 4
                        color:  (_activeVehicle && _activeVehicle.armed) ? "#00C853" : "#4A4A4A"

                        Behavior on color { ColorAnimation { duration: 130 } }
                    }

                    QGCLabel {
                        Layout.fillWidth: true
                        text: _activeVehicle ? qsTr("Arm") : qsTr("Disconnected")
                        font.bold: true
                        color: "white"
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: Math.max(52, overlay._fontPx * 3.0)
                    radius: 10
                    color: "#333333"
                    border.width: 1
                    border.color: "#4A4A4A"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        QGCLabel {
                            Layout.fillWidth: true
                            text: _activeVehicle ? qsTr("Uçuş üçün Motorları aktivləşdirin") : qsTr("Təyyarə Yoxdur")
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                            opacity: _activeVehicle ? 1 : 0.6
                            wrapMode: Text.Wrap
                        }

                        QGCButton {
                            text: _activeVehicle && _activeVehicle.armed ? qsTr("Disarm") : qsTr("Arm")
                            enabled: _activeVehicle && (_activeVehicle.armed || canArmNow())
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            onClicked: {
                                if (!_activeVehicle) return
                                if (_activeVehicle.armed) mainWindow.disarmVehicleRequest()
                                else if (canArmNow()) mainWindow.armVehicleRequest()
                            }
                        }
                    }
                }

                // ---------------- Vehicle Message Panel ----------------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: true

                    QGCLabel {
                        Layout.fillWidth: true
                        text: qsTr("Təyyarə Mesajı")
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 8
                        color: "#1E1E1E"
                        border.color: "#4A4A4A"
                        clip: true

                        Layout.preferredHeight: Math.min(
                                                    Math.max(160, overlay._fontPx * 10),
                                                    Math.max(190, panel.height * 0.38)
                                                )

                        QGCFlickable {
                            id: messageFlick
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true

                            flickableDirection: Flickable.VerticalFlick
                            boundsBehavior: Flickable.StopAtBounds

                            contentWidth: width
                            contentHeight: messageText.contentHeight + 2
                            interactive: contentHeight > height + 2

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            WheelHandler {
                                target: messageFlick
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: (wheel) => {
                                    var maxY = Math.max(0, messageFlick.contentHeight - messageFlick.height)
                                    wheel.accepted = true
                                    if (maxY <= 0) return
                                    var dy = overlay._wheelDeltaY(wheel)
                                    messageFlick.contentY = overlay._clamp(messageFlick.contentY - dy, 0, maxY)
                                }
                            }

                            TextEdit {
                                id: messageText
                                width: messageFlick.width
                                height: contentHeight
                                readOnly: true
                                selectByMouse: true
                                textFormat: TextEdit.RichText
                                wrapMode: TextEdit.Wrap
                                color: "white"

                                text: overlay._vehicleMessagesHtml
                                onLinkActivated: function(link) { handleLinkActivated(link) }
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            width: Math.round(overlay._clamp(overlay._fontPx * 1.25, 18, 26))
                            height: width
                            radius: width / 2
                            color: "#333333"
                            border.color: "#4A4A4A"

                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: parent.width * 0.60
                                height: width
                                source: "/res/TrashDelete.svg"
                                fillMode: Image.PreserveAspectFit
                                color: "white"
                            }

                            QGCMouseArea {
                                fillItem: parent
                                onClicked: {
                                    if (_activeVehicle) _activeVehicle.clearMessages()
                                    Qt.callLater(function() { overlay._refreshVehicleMessages(true) })
                                }
                            }
                        }
                    }
                }

                // ---------------- Overall Status ----------------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: _activeVehicle && _checksSupported &&
                             _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode.count > 0

                    QGCLabel {
                        Layout.fillWidth: true
                        text: qsTr("Ümumi Vəziyyət")
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 8
                        color: "#1E1E1E"
                        border.color: "#4A4A4A"
                        Layout.preferredHeight: overallStatusCol.implicitHeight + 20

                        ColumnLayout {
                            id: overallStatusCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Repeater {
                                model: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode : null

                                delegate: ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        QGCLabel {
                                            Layout.fillWidth: true
                                            text: object.message
                                            textFormat: TextEdit.RichText
                                            color: {
                                                if (object.severity === "error")   return "#FF6B6B"
                                                if (object.severity === "warning") return "#FFA500"
                                                return "white"
                                            }
                                            wrapMode: Text.Wrap
                                            onLinkActivated: function(link) { handleLinkActivated(link) }
                                        }

                                        QGCColoredImage {
                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16
                                            source: "/qmlimages/arrow-down.png"
                                            color: "white"
                                            visible: object.description !== ""

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: object.expanded = !object.expanded
                                            }
                                        }
                                    }

                                    QGCLabel {
                                        Layout.fillWidth: true
                                        text: object.description
                                        textFormat: TextEdit.RichText
                                        color: "#CCCCCC"
                                        wrapMode: Text.Wrap
                                        visible: object.expanded
                                        onLinkActivated: function(link) { handleLinkActivated(link) }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: "#3A3A3A"
                                        visible: index < (_activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode.count - 1)
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------------- Sensor Status ----------------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: _activeVehicle && _activeVehicle.sysStatusSensorInfo && _activeVehicle.sysStatusSensorInfo.sensorNames

                    QGCLabel {
                        Layout.fillWidth: true
                        text: qsTr("Sensor Vəziyyəti")
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 8
                        color: "#1E1E1E"
                        border.color: "#4A4A4A"
                        clip: true

                        Layout.preferredHeight: Math.min(sensorList.contentHeight + 6,
                                                         Math.max(160, panel.height * 0.35))

                        ListView {
                            id: sensorList
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 3
                            clip: true

                            model: (_activeVehicle && _activeVehicle.sysStatusSensorInfo && _activeVehicle.sysStatusSensorInfo.sensorNames)
                                   ? _activeVehicle.sysStatusSensorInfo.sensorNames.length : 0

                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            WheelHandler {
                                target: sensorList
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: (wheel) => {
                                    var maxY = Math.max(0, sensorList.contentHeight - sensorList.height)
                                    wheel.accepted = true
                                    if (maxY <= 0) return
                                    var dy = overlay._wheelDeltaY(wheel)
                                    sensorList.contentY = overlay._clamp(sensorList.contentY - dy, 0, maxY)
                                }
                            }

                            delegate: Rectangle {
                                width: sensorList.width
                                height: 26
                                radius: 4
                                color: "#3D3D3D"
                                border.color: "#5E5E5E"

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 6

                                    QGCLabel {
                                        text: _activeVehicle.sysStatusSensorInfo.sensorNames[index]
                                        color: "white"
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                        width: sensorList.width - pillRect.width - 26
                                    }

                                    Rectangle {
                                        id: pillRect
                                        radius: 3
                                        height: 18
                                        width: Math.max(78, statusText.implicitWidth + 16)
                                        color: {
                                            if (!_activeVehicle.sysStatusSensorInfo.sensorStatus) return "#444444"
                                            const val = _activeVehicle.sysStatusSensorInfo.sensorStatus[index]
                                            if (val === "Normal")   return "#415247"
                                            if (val === "Error")     return "#5A2F2F"
                                            if (val === "Disabled") return "#444444"
                                            return "#444444"
                                        }
                                        border.color: "#9d9d9d"
                                        border.width: 0.5

                                        QGCLabel {
                                            id: statusText
                                            anchors.centerIn: parent
                                            color: "white"
                                            text: _activeVehicle.sysStatusSensorInfo.sensorStatus
                                                  ? _activeVehicle.sysStatusSensorInfo.sensorStatus[index] : "Unknown"
                                            font.pointSize: Math.max(8, overlay._fontPt - 2)
                                        }
                                    }
                                }
                            }
                        }
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

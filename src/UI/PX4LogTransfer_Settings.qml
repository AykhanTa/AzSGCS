import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
//import QtQuick.Dialogs 1.3

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

// PX4 log transfer and MAVLink logging, in the new design: the page header of the setup
// pages, status cards with group box rows, and the new fields, combo boxes, switches and
// buttons.
Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    // The fields, combo boxes, switches, labels and buttons take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ------------------ Data ------------------
    property var  _activeVehicle:               QGroundControl.multiVehicleManager.activeVehicle
    property bool _isPX4: _activeVehicle ? _activeVehicle.px4Firmware : false
    property bool _showMavlinkLog:              QGroundControl.corePlugin.options.showPX4LogTransferOptions
    property var  _mavlinkLogManager:           _activeVehicle ? _activeVehicle.mavlinkLogManager : null
    property int  _selectedCount:               0
    property bool _uploadedSelected:            false
    property var  _disableDataPersistenceFact:  QGroundControl.settingsManager.appSettings.disableAllPersistence
    property bool _disableDataPersistence:      _disableDataPersistenceFact ? _disableDataPersistenceFact.rawValue : false

    // ------------------ Responsive metrics ------------------
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100

    readonly property real sidePadding: AzTheme.px(phone ? 12 : 20)
    readonly property real gap:         AzTheme.px(phone ? 10 : 16)

    readonly property real fontScale: {
        var w = Math.max(1, width)
        var s = w / 1400.0
        s = Math.min(1.0, s)
        return Math.max(0.90, Math.min(1.0, s))
    }

    readonly property real titleFontPx: AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descFontPx:  AzTheme.fontPx(13)
    readonly property real labelFontPx: AzTheme.fontPx(AzTheme.popupTextSize)

    readonly property real availableW: Math.max(0, width - 2 * sidePadding)
    readonly property real minPanelW:  phone ? 320 : tablet ? 520 : 720
    readonly property real maxPanelW:  820

    readonly property int columns: phone ? 1
                                        : Math.min(2, Math.max(1, Math.floor((availableW + gap) / (minPanelW + gap))))

    readonly property real panelW: (columns === 1)
                                        ? availableW
                                        : Math.min(maxPanelW, Math.floor((availableW - gap * (columns - 1)) / columns))

    readonly property real rowPadX: AzTheme.px(AzTheme.groupPadding)
    readonly property real rowPadY: AzTheme.px(8)
    readonly property real rowMinH: AzTheme.px(AzTheme.groupRowHeight + 4)

    readonly property real wheelStepPx: Math.max(60, ScreenTools.defaultFontPixelHeight * 3.2)
    readonly property real listH: Math.max(200, Math.min(420, height * (phone ? 0.34 : 0.38)))

    // ================== EQUAL-HEIGHT rows (fix Flow boşluq) ==================
    // Qeyd: desiredH-lər panellərin içində hesablanır, burada sadəcə max götürürük.
    readonly property real row1H: {
        if (columns < 2) return 0
        var a = (loggingPanel && loggingPanel.visible) ? loggingPanel.desiredH : 0
        var b = (uploadsPanel && uploadsPanel.visible) ? uploadsPanel.desiredH : 0
        return Math.max(a, b)
    }
    readonly property real row2H: {
        if (columns < 2) return 0
        var a = (additionalPanel && additionalPanel.visible) ? additionalPanel.desiredH : 0
        var b = (logsPanel && logsPanel.visible) ? logsPanel.desiredH : 0
        return Math.max(a, b)
    }
    readonly property bool _logsReady: (_activeVehicle && _isPX4 && _mavlinkLogManager)

    readonly property string _logsStatusText: !_activeVehicle
        ? qsTr("Heç bir təyyarə qoşulmayıb")
        : (!_isPX4
            ? qsTr("PX4 Log Transfer yalnız PX4 təyyarələri üçün mövcuddur")
            : qsTr("MAVLink Logging mövcud deyil"))

    // ✅ Map arxaya keçməsin: boş sahələrdə click/drag da tutulur
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        // Bu MouseArea aşağıda qalacaq (sonrakı elementlər üstündə olacaq)
        // ona görə düymələri/textfildi bloklamır, amma boş sahədə map-ə keçidi kəsir.
        onPressed:  (m) => { m.accepted = true }
        onReleased: (m) => { m.accepted = true }
        onClicked:  (m) => { m.accepted = true }
        onPositionChanged: (m) => { m.accepted = true }
    }

    // ✅ Wheel həmişə burada tutulur -> map zoom etməyəcək
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        onWheel: (event) => {
            event.accepted = true

            var delta = (event.pixelDelta.y !== 0)
                      ? event.pixelDelta.y
                      : (event.angleDelta.y / 120.0) * root.wheelStepPx

            // 1) Əgər wheel log listin üstündədirsə -> listi scroll et
            if (logsPanel && logsPanel.visible && logListView && logListView.visible) {
                var p = logListView.mapFromItem(root, event.x, event.y)
                var overList = (p.x >= 0 && p.y >= 0 && p.x < logListView.width && p.y < logListView.height)
                if (overList) {
                    var maxY = Math.max(0, logListView.contentHeight - logListView.height)
                    logListView.contentY = Math.max(0, Math.min(maxY, logListView.contentY - delta))
                    return
                }
            }

            // 2) Default: səhifəni (flick) scroll et
            var maxF = Math.max(0, flick.contentHeight - flick.height)
            flick.contentY = Math.max(0, Math.min(maxF, flick.contentY - delta))
        }
    }


    // ------------------ Selected count tracking ------------------
    Connections {
        target: _mavlinkLogManager
        onSelectedCountChanged: {
            _uploadedSelected = false
            var selected = 0
            for (var i = 0; i < _mavlinkLogManager.logFiles.count; i++) {
                var logFile = _mavlinkLogManager.logFiles.get(i)
                if (logFile.selected) {
                    selected++
                    if (logFile.uploaded) {
                        _uploadedSelected = true
                    }
                }
            }
            _selectedCount = selected
        }
    }

    function saveItems() {
        if (_mavlinkLogManager) {
            _mavlinkLogManager.videoURL     = videoUrlField.text
            _mavlinkLogManager.feedback     = feedbackTextArea.text
            _mavlinkLogManager.emailAddress = emailField.text
            _mavlinkLogManager.description  = descField.text
            _mavlinkLogManager.uploadURL    = urlField.text

            if (autoUploadCheck.checked && _mavlinkLogManager.emailAddress === "") {
                autoUploadCheck.checked = false
            } else {
                _mavlinkLogManager.enableAutoUpload = autoUploadCheck.checked
            }
        }
    }

    MessageDialog {
        id: emptyEmailDialog
        visible: false
        buttons: MessageDialog.Close
        title: qsTr("MAVLink Logging")
        text: qsTr("MAVLink log fayllarını yükləməzdən əvvəl e-poçt ünvanı daxil edin.")
    }

    // ------------------ Header ------------------
    Column {
        id: headerArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: sidePadding
        anchors.rightMargin: sidePadding
        anchors.topMargin: AzTheme.px(20)
        spacing: AzTheme.px(6)

        Text {
            text: qsTr("PX4 Log Transfer & MAVLink Logging")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titleFontPx
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Text {
            text: qsTr("PX4 jurnal fayllarını idarə edin, MAVLink qeyd parametrlərini konfiqurasiya edin və log yükləmə əməliyyatlarına nəzarət edin.")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descFontPx
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    // ------------------ Main scroll area (prevents wheel to map) ------------------
    QGCFlickable {
        id: flick
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: AzTheme.px(16)

        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + sidePadding

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        // WheelHandler {
        //     acceptedDevices: PointerDevice.Mouse
        //     onWheel: (event) => {
        //         event.accepted = true
        //         var delta = (event.pixelDelta.y !== 0) ? event.pixelDelta.y : (event.angleDelta.y / 120.0) * root.wheelStepPx
        //         var maxY = Math.max(0, flick.contentHeight - flick.height)
        //         flick.contentY = Math.max(0, Math.min(maxY, flick.contentY - delta))
        //     }
        // }

        Column {
            id: contentColumn
            width: flick.width
            spacing: gap

            Flow {
                id: panelFlow
                x: sidePadding
                width: Math.max(0, flick.width - 2 * sidePadding)
                spacing: gap
                height: childrenRect.height

                // ================== MAVLink Logging ==================
                Rectangle {
                    id: loggingPanel
                    width: panelFlow.width
                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }
                    visible: _showMavlinkLog && _isPX4

                    readonly property real pad: AzTheme.px(16)
                    readonly property real desiredH: loggingLayout.implicitHeight + pad * 2

                    height: (root.columns > 1 && uploadsPanel && uploadsPanel.visible) ? root.row1H : desiredH

                    ColumnLayout {
                        id: loggingLayout
                        anchors.fill: parent
                        anchors.margins: loggingPanel.pad
                        spacing: AzTheme.px(8)

                        Text {
                            text: qsTr("MAVLink 2.0 Logging (PX4 Pro Only)")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(16)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, manualGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: manualGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Manual Start/Stop:")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    QGCButton {
                                        text: qsTr("Başla Logging")
                                        width: root.phone ? parent.width : 160
                                        enabled: _mavlinkLogManager && !_mavlinkLogManager.logRunning && _mavlinkLogManager.canStartLog && !_disableDataPersistence
                                        onClicked: _mavlinkLogManager.startLogging()
                                    }

                                    QGCButton {
                                        text: qsTr("Bitir Logging")
                                        width: root.phone ? parent.width : 160
                                        enabled: _mavlinkLogManager && _mavlinkLogManager.logRunning && !_disableDataPersistence
                                        onClicked: _mavlinkLogManager.stopLogging()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, autoGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: autoGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Avtomatik qeydi aktivləşdirin")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    checked: _mavlinkLogManager ? _mavlinkLogManager.enableAutoStart : false
                                    enabled: !_disableDataPersistence
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                    onCheckedChanged: {
                                        if (_mavlinkLogManager) {
                                            _mavlinkLogManager.enableAutoStart = checked
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true } // panel hündürlüyü böyüyəndə içəridə balanslı boşluq
                    }
                }

                // ================== Log Uploads ==================
                Rectangle {
                    id: uploadsPanel
                    width: panelFlow.width
                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }
                    visible: _showMavlinkLog && _isPX4

                    readonly property real pad: AzTheme.px(16)
                    readonly property real desiredH: uploadsLayout.implicitHeight + pad * 2

                    height: (root.columns > 1 && loggingPanel && loggingPanel.visible) ? root.row1H : desiredH

                    ColumnLayout {
                        id: uploadsLayout
                        anchors.fill: parent
                        anchors.margins: uploadsPanel.pad
                        spacing: AzTheme.px(8)

                        Text {
                            text: qsTr("MAVLink 2.0 Log Uploads (PX4 Pro Only)")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(16)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, emailGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: emailGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Log Upload üçün e-poçt ünvanı:")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    Layout.preferredWidth: root.phone ? -1 : 260
                                }

                                QGCTextField {
                                    id: emailField
                                    text: _mavlinkLogManager ? _mavlinkLogManager.emailAddress : ""
                                    Layout.fillWidth: true
                                    enabled: !_disableDataPersistence
                                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhEmailCharactersOnly
                                    onEditingFinished: { saveItems() }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, descGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: descGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Defolt Təsvir:")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: root.phone ? -1 : 260
                                }

                                QGCTextField {
                                    id: descField
                                    text: _mavlinkLogManager ? _mavlinkLogManager.description : ""
                                    Layout.fillWidth: true
                                    enabled: !_disableDataPersistence
                                    onEditingFinished: { saveItems() }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, urlGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: urlGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Defolt Yükləmə URL:")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: root.phone ? -1 : 260
                                }

                                QGCTextField {
                                    id: urlField
                                    text: _mavlinkLogManager ? _mavlinkLogManager.uploadURL : ""
                                    Layout.fillWidth: true
                                    enabled: !_disableDataPersistence
                                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
                                    onEditingFinished: { saveItems() }
                                }
                            }
                        }
                    }
                }

                // ================== Additional Settings ==================
                Rectangle {
                    id: additionalPanel
                    width: panelFlow.width
                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }
                    visible: _showMavlinkLog && _isPX4

                    readonly property real pad: AzTheme.px(16)
                    readonly property real desiredH: additionalLayout.implicitHeight + pad * 2

                    height: (root.columns > 1 && logsPanel && logsPanel.visible) ? root.row2H : desiredH

                    ColumnLayout {
                        id: additionalLayout
                        anchors.fill: parent
                        anchors.margins: additionalPanel.pad
                        spacing: AzTheme.px(8)

                        Text {
                            text: qsTr("Əlavə Parametrlər")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(16)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, vurlGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: vurlGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Video URL:")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: root.phone ? -1 : 220
                                }

                                QGCTextField {
                                    id: videoUrlField
                                    text: _mavlinkLogManager ? _mavlinkLogManager.videoURL : ""
                                    Layout.fillWidth: true
                                    enabled: !_disableDataPersistence
                                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhUrlCharactersOnly
                                    onEditingFinished: { saveItems() }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, windGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: windGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Küləyin sürəti:")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: root.phone ? -1 : 220
                                }

                                QGCComboBox {
                                    id: windCombo
                                    Layout.fillWidth: true
                                    enabled: !_disableDataPersistence
                                    textRole: "text"
                                    model: ListModel {
                                        id: windItems
                                        ListElement { text: qsTr("Zəhmət olmasa seçin"); value: -1 }
                                        ListElement { text: qsTr("Sakit"); value: 0 }
                                        ListElement { text: qsTr("Meh"); value: 5 }
                                        ListElement { text: qsTr("Fırtına"); value: 8 }
                                        ListElement { text: qsTr("Tufan"); value: 10 }
                                    }
                                    onActivated: (index) => {
                                        if (_mavlinkLogManager) {
                                            _mavlinkLogManager.windSpeed = windItems.get(index).value
                                        }
                                        saveItems()
                                    }
                                    Component.onCompleted: {
                                        if (_mavlinkLogManager) {
                                            for (var i = 0; i < windItems.count; i++) {
                                                if (windItems.get(i).value === _mavlinkLogManager.windSpeed) {
                                                    currentIndex = i
                                                    break
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, rateGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: rateGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Uçuş Reytinqi:")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: root.phone ? -1 : 220
                                }

                                QGCComboBox {
                                    id: ratingCombo
                                    Layout.fillWidth: true
                                    enabled: !_disableDataPersistence
                                    textRole: "text"
                                    model: ListModel {
                                        id: ratingItems
                                        ListElement { text: qsTr("Zəhmət olmasa seçin"); value: "notset"}
                                        ListElement { text: qsTr("Qəzaya uğradı (Pilot xətası)"); value: "crash_pilot" }
                                        ListElement { text: qsTr("Qəzaya uğradı (Proqram və ya hardware problemi)"); value: "crash_sw_hw" }
                                        ListElement { text: qsTr("Qeyri-qənaətbəxş"); value: "unsatisfactory" }
                                        ListElement { text: qsTr("Yaxşı"); value: "good" }
                                        ListElement { text: qsTr("Əla"); value: "great" }
                                    }
                                    onActivated: (index) => {
                                        if (_mavlinkLogManager) {
                                            _mavlinkLogManager.rating = ratingItems.get(index).value
                                        }
                                        saveItems()
                                    }
                                    Component.onCompleted: {
                                        if (_mavlinkLogManager) {
                                            for (var i = 0; i < ratingItems.count; i++) {
                                                if (ratingItems.get(i).value === _mavlinkLogManager.rating) {
                                                    currentIndex = i
                                                    break
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(140, fbCol.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            ColumnLayout {
                                id: fbCol
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                spacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Əlavə geridönüş:")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                }

                                TextArea {
                                    id: feedbackTextArea
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: _mavlinkLogManager ? _mavlinkLogManager.feedback : ""
                                    enabled: !_disableDataPersistence
                                    color: AzTheme.textCard
                                    font.family: AzTheme.fontFamily
                                    font.pixelSize: root.labelFontPx
                                    background: Rectangle {
                                        color:        AzTheme.pillBottom
                                        radius:       AzTheme.px(8)
                                        border.width: 1
                                        border.color: feedbackTextArea.activeFocus ? AzTheme.activeBorder : AzTheme.panelBorder
                                    }
                                    onTextChanged: {
                                        if (_mavlinkLogManager) {
                                            _mavlinkLogManager.feedback = text
                                        }
                                    }
                                }
                            }
                        }

                        // Public log
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, pubGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: pubGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Bu jurnalı hamı üçün əlçatan edin")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    checked: _mavlinkLogManager ? _mavlinkLogManager.publicLog : false
                                    enabled: !_disableDataPersistence
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                    onCheckedChanged: {
                                        if (_mavlinkLogManager) {
                                            _mavlinkLogManager.publicLog = checked
                                        }
                                    }
                                }
                            }
                        }

                        // Auto upload
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, auGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: auGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Avtomatik log yükləmələrini aktivləşdirin")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    id: autoUploadCheck
                                    checked: _mavlinkLogManager ? _mavlinkLogManager.enableAutoUpload : false
                                    enabled: !_disableDataPersistence
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                    onCheckedChanged: {
                                        saveItems()
                                        if (checked && _mavlinkLogManager && _mavlinkLogManager.emailAddress === "") {
                                            emptyEmailDialog.open()
                                            checked = false
                                        }
                                    }
                                }
                            }
                        }

                        // Delete after upload
                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            implicitHeight: Math.max(root.rowMinH, delGrid.implicitHeight + root.rowPadY * 2)
                            height: implicitHeight

                            GridLayout {
                                id: delGrid
                                anchors.fill: parent
                                anchors.leftMargin: root.rowPadX
                                anchors.rightMargin: root.rowPadX
                                anchors.topMargin: root.rowPadY
                                anchors.bottomMargin: root.rowPadY
                                columns: root.phone ? 1 : 2
                                columnSpacing: root.gap
                                rowSpacing: Math.max(6, root.gap * 0.4)

                                QGCLabel {
                                    text: qsTr("Yüklədikdən sonra log faylını silin")
                                    font.pixelSize: root.labelFontPx
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                FactCheckBoxSlider {
                                    checked: _mavlinkLogManager ? _mavlinkLogManager.deleteAfterUpload : false
                                    enabled: autoUploadCheck.checked && !_disableDataPersistence
                                    Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
                                    onCheckedChanged: {
                                        if (_mavlinkLogManager) {
                                            _mavlinkLogManager.deleteAfterUpload = checked
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ================== Log Files ==================
                Rectangle {
                    id: logsPanel
                    width: panelFlow.width
                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }
                    visible: _showMavlinkLog

                    readonly property real pad: AzTheme.px(16)
                    readonly property real desiredH: logsLayout.implicitHeight + pad * 2

                    height: (root.columns > 1 && additionalPanel && additionalPanel.visible) ? root.row2H : desiredH

                    ColumnLayout {
                        id: logsLayout
                        anchors.fill: parent
                        anchors.margins: logsPanel.pad
                        spacing: AzTheme.px(8)

                        Text {
                            text: qsTr("Saxlanmış Log Faylları")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(16)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            id: logsListContainer
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            height: root.listH
                            clip: true

                            // ✅ List yalnız PX4 + vehicle + manager olanda görünür
                            ListView {
                                id: logListView
                                anchors.fill: parent
                                anchors.margins: 10
                                clip: true
                                spacing: 6
                                model: root._logsReady ? _mavlinkLogManager.logFiles : null
                                visible: root._logsReady
                                boundsBehavior: Flickable.StopAtBounds

                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                delegate: Rectangle {
                                    width: logListView.width
                                    height: AzTheme.px(42)
                                    radius: AzTheme.px(6)
                                    color: index % 2 === 0 ? "transparent" : AzTheme.pillTop

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        QGCCheckBox {
                                            checked: object.selected
                                            enabled: !object.writing && !object.uploading
                                            onCheckedChanged: object.selected = checked
                                        }

                                        QGCLabel {
                                            text: object.name
                                            color: object.writing ? AzTheme.statusOrange : (object.uploading ? AzTheme.statusYellow : AzTheme.textCard)
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                        }

                                        QGCLabel {
                                            text: object.uploaded ? qsTr("Yükləndi") :
                                                  (object.uploading ? "" : Number(object.size).toLocaleString(Qt.locale(), 'f', 0))
                                            color: object.uploaded ? AzTheme.statusGreen : AzTheme.textSecondary
                                            Layout.preferredWidth: 110
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        ProgressBar {
                                            id: uploadProgress
                                            visible: object.uploading && !object.uploaded
                                            Layout.preferredWidth: 120
                                            from: 0
                                            to: 100
                                            value: object.progress * 100.0

                                            background: Rectangle {
                                                implicitHeight: AzTheme.px(8)
                                                radius:         height / 2
                                                color:          AzTheme.slotEmpty
                                            }

                                            contentItem: Item {
                                                implicitHeight: AzTheme.px(8)

                                                Rectangle {
                                                    width:  uploadProgress.visualPosition * parent.width
                                                    height: parent.height
                                                    radius: height / 2
                                                    color:  AzTheme.statusGreen
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ✅ PX4 yoxdursa / vehicle yoxdursa mesaj burada ortada görünür
                            QGCLabel {
                                anchors.fill: parent
                                anchors.margins: 20
                                visible: !root._logsReady
                                text: root._logsStatusText
                                color: AzTheme.textSecondary
                                font.pixelSize: root.labelFontPx
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: 10
                            visible: root._logsReady

                            QGCButton {
                                text: qsTr("Hamısını seç")
                                width: root.phone ? parent.width : implicitWidth
                                enabled: _mavlinkLogManager && !_mavlinkLogManager.uploading && !_mavlinkLogManager.logRunning
                                onClicked: {
                                    for (var i = 0; i < _mavlinkLogManager.logFiles.count; i++) {
                                        _mavlinkLogManager.logFiles.get(i).selected = true
                                    }
                                }
                            }

                            QGCButton {
                                text: qsTr("Heçbirini seçmə")
                                width: root.phone ? parent.width : implicitWidth
                                enabled: _mavlinkLogManager && !_mavlinkLogManager.uploading && !_mavlinkLogManager.logRunning
                                onClicked: {
                                    for (var i = 0; i < _mavlinkLogManager.logFiles.count; i++) {
                                        _mavlinkLogManager.logFiles.get(i).selected = false
                                    }
                                }
                            }

                            QGCButton {
                                text: qsTr("Seçilmişi Sil")
                                width: root.phone ? parent.width : implicitWidth
                                enabled: _selectedCount > 0 && _mavlinkLogManager && !_mavlinkLogManager.uploading && !_mavlinkLogManager.logRunning
                                onClicked: deleteDialog.open()

                                MessageDialog {
                                    id: deleteDialog
                                    visible: false
                                    buttons: MessageDialog.Yes | MessageDialog.No
                                    title: qsTr("Seçilmiş Log Fayllarını silin")
                                    text: qsTr("Seçilmiş log fayllarının silinməsi təsdiq edilsin?")
                                    onButtonClicked: function (button, role) {
                                        if (button === MessageDialog.Yes && _mavlinkLogManager) {
                                            _mavlinkLogManager.deleteLog()
                                        }
                                    }
                                }
                            }

                            QGCButton {
                                text: qsTr("Seçilənləri Yüklə")
                                width: root.phone ? parent.width : implicitWidth
                                enabled: _selectedCount > 0 && _mavlinkLogManager && !_mavlinkLogManager.uploading && !_mavlinkLogManager.logRunning && !_uploadedSelected
                                visible: !_mavlinkLogManager || !_mavlinkLogManager.uploading
                                onClicked: {
                                    saveItems()
                                    if (_mavlinkLogManager && _mavlinkLogManager.emailAddress === "") {
                                        emptyEmailDialog.open()
                                    } else {
                                        uploadDialog.open()
                                    }
                                }

                                MessageDialog {
                                    id: uploadDialog
                                    visible: false
                                    buttons: MessageDialog.Yes | MessageDialog.No
                                    title: qsTr("Seçilmiş Log Fayllarını Yükləyin")
                                    text: qsTr("Seçilmiş log fayllarının yüklənməsini təsdiqləyin?")
                                    onButtonClicked: function (button, role) {
                                        if (button === MessageDialog.Yes && _mavlinkLogManager) {
                                            _mavlinkLogManager.uploadLog()
                                        }
                                    }
                                }
                            }

                            QGCButton {
                                text: qsTr("Yükləməni ləğv edin")
                                width: root.phone ? parent.width : implicitWidth
                                enabled: _mavlinkLogManager && _mavlinkLogManager.uploading && !_mavlinkLogManager.logRunning
                                visible: _mavlinkLogManager && _mavlinkLogManager.uploading
                                onClicked: cancelDialog.open()

                                MessageDialog {
                                    id: cancelDialog
                                    visible: false
                                    buttons: MessageDialog.Yes | MessageDialog.No
                                    title: qsTr("Yükləməni ləğv edin")
                                    text: qsTr("Yükləmə prosesinin ləğvini təsdiqləyin?")
                                    onButtonClicked: function (button, role) {
                                        if (button === MessageDialog.Yes && _mavlinkLogManager) {
                                            _mavlinkLogManager.cancelUpload()
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: AzTheme.groupFill
                            border.width: 1
                            border.color: AzTheme.groupBorder
                            height: 40
                            visible: root._logsReady && _selectedCount > 0


                            QGCLabel {
                                anchors.centerIn: parent
                                text: qsTr("%1 log fayl(lar)ı seçildi").arg(_selectedCount)
                                color: AzTheme.textCard
                                font.weight: Font.Medium
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }


            }

            Item { width: 1; height: sidePadding }
        }
    }
}

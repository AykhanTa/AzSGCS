import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

// Console, in the new design: the page header of the setup pages, a status card holding the
// log list on a group box and the action bar with the shared buttons and combo box.
Item {
    id: _root
    anchors.fill: parent

    // The buttons, combo box, labels and the filter dialog take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    property bool listViewLoadCompleted: false

    // ------------------ Responsive ------------------
    readonly property bool phone: ScreenTools.isMobile || width < 720
    readonly property bool tiny:  width < 560

    readonly property real sidePad: AzTheme.px(phone ? 12 : 20)
    readonly property real gap:     AzTheme.px(phone ? 10 : 16)

    readonly property real rowPx:   AzTheme.fontPx(12)
    readonly property real labelPx: AzTheme.fontPx(13)

    // ================== Arxaya click/drag keçməsin ==================
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed:  (m) => { m.accepted = true }
        onReleased: (m) => { m.accepted = true }
        onClicked:  (m) => { m.accepted = true }
        onPositionChanged: (m) => { m.accepted = true }
        onWheel: (w) => { w.accepted = true }
    }

    // ================== Wheel arxaya keçməsin, list scroll olsun ==================
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        onWheel: (event) => {
            event.accepted = true

            var delta = (event.pixelDelta.y !== 0)
                      ? event.pixelDelta.y
                      : (event.angleDelta.y / 120.0) * Math.max(50, ScreenTools.defaultFontPixelHeight * 2.5)

            var maxY = Math.max(0, listView.contentHeight - listView.height)
            listView.contentY = Math.max(0, Math.min(maxY, listView.contentY - delta))
        }
    }

    // ================== Layout ==================
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: _root.sidePad
        anchors.rightMargin: _root.sidePad
        anchors.topMargin: AzTheme.px(20)
        anchors.bottomMargin: _root.sidePad
        spacing: _root.gap

        // -------- Header --------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: AzTheme.px(6)

            Text {
                text: qsTr("Konsol Pəncərəsi")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(_root.phone ? 18 : 20)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            Text {
                text: qsTr("Tətbiq jurnallarını (logları) göstərmək, filtrləmək və saxlamaq üçün tənzimləmələr")
                color: AzTheme.textSecondary
                font.family: AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(13)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }

        // -------- Main panel: the status card --------
        Rectangle {
            id: logwindow
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            radius: AzTheme.px(AzTheme.cardRadius)
            border.width: 1
            border.color: AzTheme.cardBorder
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
            }

            readonly property real pad:    AzTheme.px(_root.phone ? 12 : 16)
            readonly property real barGap: AzTheme.px(_root.phone ? 8 : 12)

            // -------- Delegate --------
            Component {
                id: delegateItem
                Rectangle {
                    width: listView.width
                    color: index % 2 === 0 ? "transparent" : AzTheme.pillTop
                    radius: AzTheme.px(6)
                    implicitHeight: Math.max(AzTheme.px(28), field.implicitHeight + AzTheme.px(10))

                    QGCLabel {
                        id: field
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: AzTheme.px(8)
                        // Model sətri silinərkən `display` qısa müddət undefined olur.
                        // Bunu birbaşa mənimsətmək QML xəbərdarlığı doğurur, xəbərdarlıq isə
                        // yenidən bu modelə düşüb sonsuz dövrə çevrilir — ona görə süzülür.
                        text: (display === undefined || display === null) ? "" : display
                        wrapMode: Text.Wrap
                        font.pixelSize: _root.rowPx
                    }
                }
            }

            // -------- Log list on a group box --------
            Rectangle {
                id: listFrame
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: actionBar.top
                anchors.leftMargin: logwindow.pad
                anchors.rightMargin: logwindow.pad
                anchors.topMargin: logwindow.pad
                anchors.bottomMargin: logwindow.barGap
                color: AzTheme.groupFill
                radius: AzTheme.px(AzTheme.groupRadius)
                border.color: AzTheme.groupBorder
                border.width: 1
                clip: true

                QGCListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: AzTheme.px(6)
                    clip: true
                    model: debugMessageModel
                    delegate: delegateItem
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                    function scrollToEnd() {
                        if (listViewLoadCompleted && followTail.checked) {
                            listView.positionViewAtEnd()
                        }
                    }

                    Component.onCompleted: {
                        listViewLoadCompleted = true
                        scrollToEnd()
                    }

                    Connections {
                        target: debugMessageModel
                        function onDataChanged(topLeft, bottomRight, roles) { listView.scrollToEnd() }
                    }
                }
            }

            // -------- Action bar --------
            Item {
                id: actionBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: logwindow.pad
                anchors.rightMargin: logwindow.pad
                anchors.bottomMargin: logwindow.pad
                implicitHeight: actionsGrid.implicitHeight

                GridLayout {
                    id: actionsGrid
                    width: parent.width

                    // Kiçik ekranda 2 sütun -> hündürlük azalsın, mesaj hissəsi böyüsün
                    columns: _root.tiny ? 1 : (_root.phone ? 2 : 4)

                    columnSpacing: AzTheme.px(_root.phone ? 8 : 10)
                    rowSpacing:    AzTheme.px(_root.phone ? 8 : 10)

                    // --- Save Button ---
                    QGCButton {
                        id: writeButton
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignBottom
                        text: qsTr("Tətbiq log yadda saxlayın")
                        onClicked: writeDialog.openForSave()
                    }

                    // --- GST (1 item kimi) ---
                    ColumnLayout {
                        id: gstBlock
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignBottom
                        Layout.columnSpan: _root.phone ? (_root.tiny ? 1 : 2) : 1
                        visible: QGroundControl.settingsManager.appSettings.gstDebugLevel.visible
                        spacing: AzTheme.px(4)

                        QGCLabel {
                            text: qsTr("GStreamer Debug Level")
                            color: AzTheme.textSecondary
                            font.pixelSize: _root.labelPx
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }

                        FactComboBox {
                            id: gstCombo
                            fact: QGroundControl.settingsManager.appSettings.gstDebugLevel
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }
                    }

                    // --- Follow Tail: green while on ---
                    QGCButton {
                        id: followTail
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignBottom
                        text: qsTr("Ən son göstər")
                        checkable: true
                        checked: true
                        primary: checked

                        onCheckedChanged: {
                            if (checked && listViewLoadCompleted) {
                                listView.positionViewAtEnd()
                            }
                        }
                    }

                    // --- Filter Button ---
                    QGCButton {
                        id: filterButton
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignBottom
                        text: qsTr("Loglama təyin edin")
                        onClicked: filtersDialogComponent.createObject(mainWindow).open()
                    }
                }
            }
        }
    }

    // ================== Save dialog ==================
    QGCFileDialog {
        id: writeDialog
        folder: QGroundControl.settingsManager.appSettings.logSavePath
        nameFilters: [qsTr("Log faylları (*.txt)"), qsTr("Bütün Fayllar (*)")]
        title: qsTr("Yadda saxlamaq üçün log faylı seçin")
        onAcceptedForSave: (file) => {
            debugMessageModel.writeMessages(file)
            visible = false
        }
    }

    Connections {
        target: debugMessageModel
        function onWriteStarted()  { writeButton.enabled = false }
        function onWriteFinished(success) { writeButton.enabled = true }
    }

    // ================== Filters dialog (original logic) ==================
    Component {
        id: filtersDialogComponent

        QGCPopupDialog {
            title: qsTr("Loglama kateqoriyaları")
            buttons: Dialog.Close

            property int enabledCategoryCount: 0

            function clearAllLogging() {
                var logCategories = QGroundControl.loggingCategories()
                for (var category of logCategories) {
                    QGroundControl.setCategoryLoggingOn(category, false)
                }
                QGroundControl.updateLoggingFilterRules()
                categoryRepeater.model = undefined
                categoryRepeater.model = QGroundControl.loggingCategories()
                enabledCategoryCount = 0
                enabledCategoryRepeater.model = undefined
                enabledCategoryRepeater.model = QGroundControl.loggingCategories()
            }

            function updateLoggingCategory(logCategory, checked, rebuildCategoryList) {
                QGroundControl.setCategoryLoggingOn(logCategory, checked)
                QGroundControl.updateLoggingFilterRules()
                enabledCategoryCount = 0
                enabledCategoryRepeater.model = undefined
                enabledCategoryRepeater.model = QGroundControl.loggingCategories()
                if (rebuildCategoryList) {
                    categoryRepeater.model = undefined
                    categoryRepeater.model = QGroundControl.loggingCategories()
                }
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2
                    Layout.fillWidth: true

                    QGCLabel { text: qsTr("Axtar:") }

                    QGCTextField {
                        id: searchText
                        text: ""
                        Layout.fillWidth: true
                        enabled: true
                    }

                    QGCButton {
                        text: qsTr("Təmizlə")
                        onClicked: searchText.text = ""
                    }
                }

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    Repeater {
                        id: enabledCategoryRepeater
                        model: QGroundControl.loggingCategories()

                        QGCCheckBox {
                            text: modelData
                            visible: QGroundControl.categoryLoggingOn(modelData)
                            checked: QGroundControl.categoryLoggingOn(modelData)
                            onClicked: updateLoggingCategory(modelData, checked, true)
                            Component.onCompleted: enabledCategoryCount += checked ? 1 : 0
                        }
                    }

                    QGCButton {
                        text: qsTr("Hamısını Sil")
                        visible: enabledCategoryCount > 0
                        onClicked: clearAllLogging()
                    }
                }

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    Repeater {
                        id: categoryRepeater
                        model: QGroundControl.loggingCategories()

                        QGCCheckBox {
                            text: modelData
                            visible: searchText.text ? text.match(`(${searchText.text})`, "i") : true
                            checked: QGroundControl.categoryLoggingOn(modelData)
                            onClicked: updateLoggingCategory(modelData, checked, false)
                        }
                    }
                }
            }
        }
    }
}

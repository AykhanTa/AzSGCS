import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Item {
    id: _root
    anchors.fill: parent

    property bool listViewLoadCompleted: false

    // ------------------ Responsive ------------------
    readonly property bool phone: ScreenTools.isMobile || width < 720
    readonly property bool tiny:  width < 560

    readonly property real sidePad: Math.max(10, ScreenTools.defaultFontPixelWidth * (phone ? 0.9 : 1.6))
    readonly property real gap:     Math.max(8,  ScreenTools.defaultFontPixelHeight * (phone ? 0.60 : 0.95))

    readonly property real titlePt: phone ? 16 : 20
    readonly property real descPt:  phone ? 10 : 12
    readonly property real rowPt:   phone ? 10 : 11

    // Button style
    readonly property color btnNormal:  "#3D3B3B"
    readonly property color btnHover:   "#504E4E"
    readonly property color btnPressed: "#9D9D9D"
    readonly property real  btnH:       tiny ? 30 : phone ? 34 : 38
    readonly property real  btnPt:      tiny ? 9  : phone ? 10 : 11

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }

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
        anchors.topMargin: 0
        anchors.bottomMargin: _root.sidePad
        spacing: _root.gap

        // -------- Header --------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * 0.6)

            QGCLabel {
                text: qsTr("Konsol Pəncərəsi")
                color: "white"
                font.bold: true
                font.pixelSize: 26
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            QGCLabel {
                text: qsTr("Tətbiq jurnallarını (logları) göstərmək, filtrləmək və saxlamaq üçün tənzimləmələr")
                color: "#E8E8E8"
                font.pixelSize: 16
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "white"
                opacity: 0.25
            }
        }

        // -------- Main panel --------
        Rectangle {
            id: logwindow
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            color: "#3b3b3b"
            radius: 12
            border.color: "white"
            border.width: 2

            readonly property real pad: Math.max(10, ScreenTools.defaultFontPixelWidth * (phone ? 0.9 : 1.2))
            readonly property real barGap: phone ? 6 : Math.max(8, ScreenTools.defaultFontPixelHeight * 0.5)

            // -------- Delegate --------
            Component {
                id: delegateItem
                Rectangle {
                    width: listView.width
                    color: "#2A2A2A"
                    radius: 6
                    implicitHeight: Math.max(30, field.implicitHeight + 10)

                    QGCLabel {
                        id: field
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 8
                        // Model sətri silinərkən `display` qısa müddət undefined olur.
                        // Bunu birbaşa mənimsətmək QML xəbərdarlığı doğurur, xəbərdarlıq isə
                        // yenidən bu modelə düşüb sonsuz dövrə çevrilir — ona görə süzülür.
                        text: (display === undefined || display === null) ? "" : display
                        wrapMode: Text.Wrap
                        font.pointSize: _root.rowPt
                        color: "white"
                    }
                }
            }

            // -------- Log list --------
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
                color: "#2A2A2A"
                radius: 10
                border.color: "white"
                border.width: 1
                clip: true

                QGCListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: 6
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
                anchors.bottomMargin: phone ? 8 : logwindow.pad
                implicitHeight: actionsGrid.implicitHeight

                GridLayout {
                    id: actionsGrid
                    width: parent.width

                    // Kiçik ekranda 2 sütun -> hündürlük azalsın, mesaj hissəsi böyüsün
                    columns: _root.tiny ? 1 : (_root.phone ? 2 : 4)

                    columnSpacing: _root.phone ? 8 : 10
                    rowSpacing:    _root.phone ? 8 : 10

                    // --- Save Button ---
                    QGCButton {
                        id: writeButton
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignBottom
                        Layout.preferredHeight: _root.btnH
                        text: qsTr("Tətbiq log yadda saxlayın")
                        font.pointSize: _root.btnPt
                        onClicked: writeDialog.openForSave()

                        HoverHandler { id: writeHover }

                        background: Rectangle {
                            radius: 6
                            border.color: "white"
                            border.width: 1
                            color: writeButton.down ? _root.btnPressed : (writeHover.hovered ? _root.btnHover : _root.btnNormal)
                            opacity: writeButton.enabled ? 1 : 0.5
                        }
                    }

                    // --- GST (1 item kimi) ---
                    ColumnLayout {
                        id: gstBlock
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignBottom
                        Layout.columnSpan: _root.phone ? (_root.tiny ? 1 : 2) : 1
                        visible: QGroundControl.settingsManager.appSettings.gstDebugLevel.visible
                        spacing: 4

                        QGCLabel {
                            text: qsTr("GStreamer Debug Level")
                            color: "white"
                            font.pointSize: _root.btnPt
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }

                        FactComboBox {
                            id: gstCombo
                            fact: QGroundControl.settingsManager.appSettings.gstDebugLevel
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredHeight: _root.btnH

                            HoverHandler { id: gstHover }

                            // Standart fon qara panel üzərində seçilmir — düymələrlə eyni stil verilir
                            background: Rectangle {
                                radius: 6
                                border.color: "white"
                                border.width: 1
                                color: gstCombo.down ? _root.btnPressed
                                                     : (gstHover.hovered ? _root.btnHover : _root.btnNormal)
                            }
                        }
                    }

                    // --- Follow Tail ---
                    QGCButton {
                        id: followTail
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignBottom
                        Layout.preferredHeight: _root.btnH
                        text: qsTr("Ən son göstər")
                        font.pointSize: _root.btnPt
                        checkable: true
                        checked: true

                        HoverHandler { id: followHover }

                        background: Rectangle {
                            radius: 6
                            border.color: "white"
                            border.width: 1
                            color: followTail.down ? _root.btnPressed : (followHover.hovered ? _root.btnHover : _root.btnNormal)
                            opacity: followTail.enabled ? 1 : 0.5
                        }

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
                        Layout.preferredHeight: _root.btnH
                        text: qsTr("Loglama təyin edin")
                        font.pointSize: _root.btnPt
                        onClicked: filtersDialogComponent.createObject(mainWindow).open()

                        HoverHandler { id: filterHover }

                        background: Rectangle {
                            radius: 6
                            border.color: "white"
                            border.width: 1
                            color: filterButton.down ? _root.btnPressed : (filterHover.hovered ? _root.btnHover : _root.btnNormal)
                            opacity: filterButton.enabled ? 1 : 0.5
                        }
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




// import QtQuick 2.15
// import QtQuick.Controls 2.15
// //import QtQuick.Dialogs 1.3
// import QtQuick.Layouts 1.15

// import QGroundControl
// import QGroundControl.Controls
// import QGroundControl.FactControls

// Item {
//     id: _root
//     anchors.fill: parent

//     property bool listViewLoadCompleted: false

//     // ------------------ Responsive ------------------
//     readonly property bool phone: ScreenTools.isMobile || width < 720
//     readonly property bool tiny:  width < 560

//     readonly property real sidePad: Math.max(10, ScreenTools.defaultFontPixelWidth * (phone ? 0.9 : 1.6))
//     readonly property real gap:     Math.max(8,  ScreenTools.defaultFontPixelHeight * (phone ? 0.60 : 0.95))

//     readonly property int basePx:   Math.max(12, ScreenTools.defaultFontPixelHeight)
//     readonly property int titlePx:  phone ? Math.round(basePx * 1.25) : Math.round(basePx * 1.55)
//     readonly property int descPx:   phone ? Math.round(basePx * 0.80) : Math.round(basePx * 0.90)
//     readonly property int rowPx:    phone ? Math.round(basePx * 0.75) : Math.round(basePx * 0.82)

//     // Buttons
//     readonly property color btnNormal:  "#3D3B3B"
//     readonly property color btnHover:   "#504E4E"
//     readonly property color btnPressed: "#9D9D9D"

//     readonly property int btnH:   tiny ? 30 : phone ? 34 : 38
//     readonly property int btnPx:  tiny ? Math.round(basePx * 0.70) : phone ? Math.round(basePx * 0.78) : Math.round(basePx * 0.85)

//     // Action columns
//     readonly property int actionsCols: tiny ? 1 : (phone ? 2 : 4)

//     Rectangle {
//         anchors.fill: parent
//         color: "#000000"
//     }

//     // ================== Arxaya click/drag keçməsin ==================
//     MouseArea {
//         anchors.fill: parent
//         acceptedButtons: Qt.AllButtons
//         hoverEnabled: true
//         onPressed: function(m) { m.accepted = true }
//         onReleased: function(m) { m.accepted = true }
//         onClicked: function(m) { m.accepted = true }
//         onPositionChanged: function(m) { m.accepted = true }
//         onWheel: function(w) { w.accepted = true }
//     }

//     // ================== Wheel arxaya keçməsin, list scroll olsun ==================
//     WheelHandler {
//         acceptedDevices: PointerDevice.Mouse
//         onWheel: function(event) {
//             event.accepted = true

//             var delta = 0
//             if (event.pixelDelta && event.pixelDelta.y !== 0) {
//                 delta = event.pixelDelta.y
//             } else if (event.angleDelta) {
//                 delta = (event.angleDelta.y / 120.0) * Math.max(50, ScreenTools.defaultFontPixelHeight * 2.5)
//             }

//             var maxY = Math.max(0, listView.contentHeight - listView.height)
//             listView.contentY = Math.max(0, Math.min(maxY, listView.contentY - delta))
//         }
//     }

//     // ================== Page Layout ==================
//     ColumnLayout {
//         anchors.fill: parent
//         anchors.margins: _root.sidePad
//         spacing: _root.gap

//         // -------- Header --------
//         ColumnLayout {
//             Layout.fillWidth: true
//             spacing: Math.max(4, ScreenTools.defaultFontPixelHeight * (phone ? 0.25 : 0.4))

//             QGCLabel {
//                 text: qsTr("Konsol Pəncərəsi")
//                 color: "white"
//                 font.bold: true
//                 font.pixelSize: _root.titlePx
//                 wrapMode: Text.WordWrap
//                 Layout.fillWidth: true
//                 Layout.minimumWidth: 0
//             }

//             QGCLabel {
//                 text: qsTr("Tətbiq jurnallarını (logları) göstərmək, filtrləmək və saxlamaq üçün tənzimləmələr")
//                 color: "#CCCCCC"
//                 font.pixelSize: _root.descPx
//                 wrapMode: Text.WordWrap
//                 Layout.fillWidth: true
//                 Layout.minimumWidth: 0
//             }

//             Rectangle {
//                 Layout.fillWidth: true
//                 height: 1
//                 color: "white"
//                 opacity: 0.25
//             }
//         }

//         // -------- Main panel --------
//         Rectangle {
//             id: logwindow
//             Layout.fillWidth: true
//             Layout.fillHeight: true
//             Layout.minimumWidth: 0
//             color: "#3b3b3b"
//             radius: 12
//             border.color: "white"
//             border.width: 2

//             readonly property real pad: Math.max(10, ScreenTools.defaultFontPixelWidth * (phone ? 0.9 : 1.2))
//             readonly property real barGap: phone ? 6 : Math.max(8, ScreenTools.defaultFontPixelHeight * 0.5)

//             // === Inside layout (fix overlap completely) ===
//             ColumnLayout {
//                 anchors.fill: parent
//                 anchors.margins: logwindow.pad
//                 spacing: logwindow.barGap

//                 // -------- Log list --------
//                 Rectangle {
//                     id: listFrame
//                     Layout.fillWidth: true
//                     Layout.fillHeight: true
//                     Layout.minimumHeight: ScreenTools.defaultFontPixelHeight * (phone ? 12 : 16)

//                     color: "#2A2A2A"
//                     radius: 10
//                     border.color: "white"
//                     border.width: 1
//                     clip: true

//                     Component {
//                         id: delegateItem
//                         Rectangle {
//                             width: listView.width
//                             color: "#2A2A2A"
//                             radius: 6
//                             implicitHeight: Math.max(30, field.implicitHeight + 10)

//                             QGCLabel {
//                                 id: field
//                                 anchors.left: parent.left
//                                 anchors.right: parent.right
//                                 anchors.verticalCenter: parent.verticalCenter
//                                 anchors.margins: 8

//                                 // SAFE: display bəzən undefined ola bilər (warning flood olmasın)
//                                 text: (typeof display === "string") ? display : (display !== undefined && display !== null ? ("" + display) : "")
//                                 wrapMode: Text.Wrap
//                                 font.pixelSize: _root.rowPx
//                                 color: "white"
//                             }
//                         }
//                     }

//                     QGCListView {
//                         id: listView
//                         anchors.fill: parent
//                         anchors.margins: 6
//                         clip: true
//                         model: debugMessageModel
//                         delegate: delegateItem
//                         boundsBehavior: Flickable.StopAtBounds

//                         ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
//                         ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

//                         function scrollToEnd() {
//                             if (_root.listViewLoadCompleted && followTail.checked) {
//                                 positionViewAtEnd()
//                             }
//                         }

//                         Component.onCompleted: {
//                             _root.listViewLoadCompleted = true
//                             scrollToEnd()
//                         }

//                         Connections {
//                             target: debugMessageModel
//                             function onDataChanged(topLeft, bottomRight, roles) { listView.scrollToEnd() }
//                         }
//                     }
//                 }

//                 // -------- Actions --------
//                 GridLayout {
//                     id: actionsGrid
//                     Layout.fillWidth: true
//                     columns: _root.actionsCols
//                     columnSpacing: _root.phone ? 8 : 10
//                     rowSpacing:    _root.phone ? 8 : 10

//                     // ---------- Save ----------
//                     QGCButton {
//                         id: writeButton
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: _root.btnH
//                         text: qsTr("Tətbiq log yadda saxlayın")
//                         font.pixelSize: _root.btnPx
//                         onClicked: writeDialog.openForSave()

//                         HoverHandler { id: writeHover }

//                         background: Rectangle {
//                             radius: 6
//                             border.color: "white"
//                             border.width: 1
//                             color: writeButton.down ? _root.btnPressed : (writeHover.hovered ? _root.btnHover : _root.btnNormal)
//                             opacity: writeButton.enabled ? 1 : 0.5
//                         }
//                     }

//                     // ---------- GStreamer (fix: no overlap + enough width) ----------
//                     Item {
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: gstLoader.implicitHeight
//                         Layout.columnSpan: (_root.actionsCols === 2) ? 2 : 1
//                         visible: QGroundControl.settingsManager.appSettings.gstDebugLevel.visible

//                         Loader {
//                             id: gstLoader
//                             anchors.fill: parent
//                             sourceComponent: _root.phone ? gstColumnComp : gstRowComp
//                         }

//                         Component {
//                             id: gstRowComp
//                             RowLayout {
//                                 anchors.fill: parent
//                                 spacing: 8

//                                 QGCLabel {
//                                     text: qsTr("GStreamer Debug Level")
//                                     color: "white"
//                                     font.pixelSize: _root.btnPx
//                                     elide: Text.ElideRight
//                                     wrapMode: Text.NoWrap
//                                     Layout.fillWidth: true
//                                     Layout.minimumWidth: 0
//                                 }

//                                 FactComboBox {
//                                     id: gstComboRow
//                                     fact: QGroundControl.settingsManager.appSettings.gstDebugLevel
//                                     Layout.preferredWidth: 170
//                                     Layout.preferredHeight: _root.btnH
//                                     sizeToContents: false
//                                 }
//                             }
//                         }

//                         Component {
//                             id: gstColumnComp
//                             ColumnLayout {
//                                 anchors.fill: parent
//                                 spacing: 6

//                                 QGCLabel {
//                                     text: qsTr("GStreamer Debug Level")
//                                     color: "white"
//                                     font.pixelSize: _root.btnPx
//                                     wrapMode: Text.WordWrap
//                                     Layout.fillWidth: true
//                                     Layout.minimumWidth: 0
//                                 }

//                                 FactComboBox {
//                                     id: gstComboCol
//                                     fact: QGroundControl.settingsManager.appSettings.gstDebugLevel
//                                     Layout.fillWidth: true
//                                     Layout.preferredHeight: _root.btnH
//                                     sizeToContents: false
//                                 }
//                             }
//                         }
//                     }

//                     // ---------- Follow ----------
//                     QGCButton {
//                         id: followTail
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: _root.btnH
//                         text: qsTr("Ən son göstər")
//                         font.pixelSize: _root.btnPx
//                         checkable: true
//                         checked: true

//                         HoverHandler { id: followHover }

//                         background: Rectangle {
//                             radius: 6
//                             border.color: "white"
//                             border.width: 1
//                             color: followTail.down ? _root.btnPressed : (followHover.hovered ? _root.btnHover : _root.btnNormal)
//                             opacity: followTail.enabled ? 1 : 0.5
//                         }

//                         onCheckedChanged: {
//                             if (checked && _root.listViewLoadCompleted) {
//                                 listView.positionViewAtEnd()
//                             }
//                         }
//                     }

//                     // ---------- Filter ----------
//                     QGCButton {
//                         id: filterButton
//                         Layout.fillWidth: true
//                         Layout.preferredHeight: _root.btnH
//                         text: qsTr("Loglama təyin edin")
//                         font.pixelSize: _root.btnPx
//                         onClicked: filtersDialogComponent.createObject(mainWindow).open()

//                         HoverHandler { id: filterHover }

//                         background: Rectangle {
//                             radius: 6
//                             border.color: "white"
//                             border.width: 1
//                             color: filterButton.down ? _root.btnPressed : (filterHover.hovered ? _root.btnHover : _root.btnNormal)
//                             opacity: filterButton.enabled ? 1 : 0.5
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     // ================== Save dialog ==================
//     QGCFileDialog {
//         id: writeDialog
//         folder: QGroundControl.settingsManager.appSettings.logSavePath
//         nameFilters: [qsTr("Log faylları (*.txt)"), qsTr("Bütün Fayllar (*)")]
//         title: qsTr("Yadda saxlamaq üçün log faylı seçin")
//         onAcceptedForSave: function(file) {
//             debugMessageModel.writeMessages(file)
//             visible = false
//         }
//     }

//     Connections {
//         target: debugMessageModel
//         function onWriteStarted()  { writeButton.enabled = false }
//         function onWriteFinished(success) { writeButton.enabled = true }
//     }

//     // ================== Filters dialog (FIX: no undefined modelData, no regex crash) ==================
//     Component {
//         id: filtersDialogComponent

//         QGCPopupDialog {
//             title: qsTr("Loglama kateqoriyaları")
//             buttons: Dialog.Close

//             property var _categories: QGroundControl.loggingCategories()
//             property int enabledCategoryCount: 0

//             function _recountEnabled() {
//                 var c = 0
//                 for (var i = 0; i < _categories.length; i++) {
//                     var cat = _categories[i]
//                     if (cat && QGroundControl.categoryLoggingOn(cat)) {
//                         c++
//                     }
//                 }
//                 enabledCategoryCount = c
//             }

//             function refreshCategories() {
//                 _categories = QGroundControl.loggingCategories()
//                 _recountEnabled()
//             }

//             Component.onCompleted: refreshCategories()

//             function clearAllLogging() {
//                 var logCategories = QGroundControl.loggingCategories()
//                 for (var i = 0; i < logCategories.length; i++) {
//                     QGroundControl.setCategoryLoggingOn(logCategories[i], false)
//                 }
//                 QGroundControl.updateLoggingFilterRules()
//                 refreshCategories()
//             }

//             function updateLoggingCategory(logCategory, checked) {
//                 if (!logCategory) return
//                 QGroundControl.setCategoryLoggingOn(logCategory, checked)
//                 QGroundControl.updateLoggingFilterRules()
//                 refreshCategories()
//             }

//             ColumnLayout {
//                 spacing: ScreenTools.defaultFontPixelHeight / 2

//                 RowLayout {
//                     spacing: ScreenTools.defaultFontPixelHeight / 2
//                     Layout.fillWidth: true

//                     QGCLabel { text: qsTr("Axtar:") }

//                     QGCTextField {
//                         id: searchText
//                         text: ""
//                         Layout.fillWidth: true
//                         enabled: true
//                     }

//                     QGCButton {
//                         text: qsTr("Təmizlə")
//                         onClicked: searchText.text = ""
//                     }
//                 }

//                 // Enabled list
//                 ColumnLayout {
//                     spacing: ScreenTools.defaultFontPixelHeight / 2

//                     Repeater {
//                         model: _categories

//                         QGCCheckBox {
//                             // SAFE: modelData undefined olsa belə flood etməsin
//                             text: modelData ? modelData : ""
//                             visible: modelData && QGroundControl.categoryLoggingOn(modelData)
//                             checked: modelData && QGroundControl.categoryLoggingOn(modelData)
//                             onClicked: updateLoggingCategory(modelData, checked)
//                         }
//                     }

//                     QGCButton {
//                         text: qsTr("Hamısını Sil")
//                         visible: enabledCategoryCount > 0
//                         onClicked: clearAllLogging()
//                     }
//                 }

//                 // All categories with simple substring search (no regex)
//                 ColumnLayout {
//                     spacing: ScreenTools.defaultFontPixelHeight / 2

//                     Repeater {
//                         model: _categories

//                         QGCCheckBox {
//                             text: modelData ? modelData : ""
//                             checked: modelData && QGroundControl.categoryLoggingOn(modelData)

//                             visible: {
//                                 if (!modelData) return false
//                                 if (!searchText.text) return true
//                                 var a = ("" + modelData).toLowerCase()
//                                 var b = ("" + searchText.text).toLowerCase()
//                                 return a.indexOf(b) !== -1
//                             }

//                             onClicked: updateLoggingCategory(modelData, checked)
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }

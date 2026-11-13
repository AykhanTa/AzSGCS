import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtCharts

import QGroundControl
import QGroundControl.Controls

// MAVLink inspector, in the new design: the page header of the setup pages, the message
// list and the message details on status cards, and a waiting card without a vehicle.
AnalyzePage {
    id: root
    anchors.fill: parent
    anchors.margins: 0
    anchors.topMargin: AzTheme.px(20)

    // The buttons, combo boxes, check boxes, labels and dialogs take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    headerComponent:    headerComponent
    pageComponent:      pageComponent
    allowPopout:        true

    property var    curSystem:      controller ? controller.activeSystem : null
    property var    curMessage:     curSystem && curSystem.messages.count ? curSystem.messages.get(curSystem.selected) : null
    property int    curCompID:      0
    property real   maxButtonWidth: 0

    // ------------------ Responsive ------------------
    readonly property real _fontH: ScreenTools.defaultFontPixelHeight
    readonly property real _fontW: ScreenTools.defaultFontPixelWidth

    readonly property bool _compact: ScreenTools.isMobile || availableWidth < 900 || availableHeight < 760
    readonly property bool _tiny:    availableWidth < 560

    readonly property real _sidePad: AzTheme.px(_compact ? 12 : 20)
    readonly property real _gap:     AzTheme.px(_compact ? 10 : 16)

    readonly property real _titlePt: _compact ? 16 : 20
    readonly property real _descPt:  _compact ? 10 : 12
    readonly property real _rowPt:   _tiny ? 9 : (_compact ? 10 : 11)

    readonly property real _minButtonW:  Math.max(_fontW * 26, 220)
    readonly property real _buttonPaneW: _compact ? -1 : Math.max(_minButtonW, maxButtonWidth)

    readonly property real _nameColW: _fontW * 18
    readonly property real _valColW:  _fontW * 18
    readonly property real _typeColW: _fontW * 10
    readonly property real _plotColW: _fontW * 8
    readonly property real _msgInfoMinW: _nameColW + _valColW + _typeColW + (_plotColW * 2) + (_fontW * 6)

    readonly property real _chartH: Math.max(_compact ? 180 : 220, _fontH * (_compact ? 10 : 18))
    readonly property real _wheelStepPx: Math.max(60, _fontH * 3.0)

    MAVLinkInspectorController { id: controller }

    // ---- Popout: AnalyzePage yalnız siqnal göndərir, pəncərəni burada açırıq
    //      (MAVLink Konsoldakı ilə eyni yanaşma)
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
            id: popoutWindow
            width:   1200
            height:  800
            visible: false
            title:   qsTr("MAVLink Inspector")
            color:   AzTheme.panelGradientEnd

            Loader {
                anchors.fill: parent
                sourceComponent: pageComponent
            }

            onClosing: function(close) {
                root._popoutWindow = null
                close.accepted = true
                Qt.callLater(function() { popoutWindow.destroy() })
            }
        }
    }

    function updateEnabledStatus(repeater, message, chart) {
        if (!message || !repeater) return
        for (let i = 0; i < repeater.count; i++) {
            let checkBox = repeater.itemAt(i)
            if (!checkBox) continue
            const obj = message.fields.get(i)
            checkBox.enabled = isCheckboxEnabled(checkBox, obj, chart)
        }
    }

    function isCheckboxEnabled(checkBox, obj, chart) {
        if (!checkBox || !obj || !chart) return false
        if (checkBox.checkState === Qt.Checked) return true
        if (!obj.selectable) return false
        if (obj.series !== null && obj.series !== undefined) return false
        if (chart.chartController !== null) {
            if (chart.chartController.chartFields.length >= chart.seriesColors.length) return false
        }
        return true
    }

    // ================== HEADER ==================
    Component {
        id: headerComponent

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: headerCol.implicitHeight

            ColumnLayout {
                id: headerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: root._sidePad
                anchors.rightMargin: root._sidePad
                anchors.topMargin: 0
                anchors.bottomMargin: Math.max(6, root._gap * 0.5)
                spacing: Math.max(6, root._fontH * 0.35)

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: AzTheme.px(6)

                    Text {
                        text: qsTr("MAVLink Inspector")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: AzTheme.fontPx(root._compact ? 18 : 20)
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: qsTr("Real vaxt MAVLink mesajlarını yoxlayın.")
                        color: AzTheme.textSecondary
                        font.family: AzTheme.fontFamily
                        font.pixelSize: AzTheme.fontPx(13)
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: root._compact ? 1 : 2
                    columnSpacing: root._gap
                    rowSpacing: Math.max(6, root._gap * 0.6)
                    visible: curSystem ? (controller.systemNames.length > 1 || curSystem.compIDsStr.length > 2) : false

                    QGCComboBox {
                        id: systemCombo
                        model: controller.systemNames
                        sizeToContents: !root._compact
                        Layout.fillWidth: root._compact
                        Layout.alignment: root._compact ? Qt.AlignLeft : Qt.AlignRight
                        visible: controller.systemNames.length > 1
                        onActivated: (index) => controller.setActiveSystem(controller.systems.get(index).id)

                        Connections {
                            target: controller
                            function onActiveSystemChanged() {
                                for (var i = 0; i < controller.systems.count; i++) {
                                    if (controller.systems.get(i) === curSystem) {
                                        systemCombo.currentIndex = i
                                        curCompID = 0
                                        cidCombo.currentIndex = 0
                                        break
                                    }
                                }
                            }
                        }
                    }

                    QGCComboBox {
                        id: cidCombo
                        model: curSystem ? curSystem.compIDsStr : []
                        sizeToContents: !root._compact
                        Layout.fillWidth: root._compact
                        Layout.alignment: root._compact ? Qt.AlignLeft : Qt.AlignRight
                        visible: curSystem ? curSystem.compIDsStr.length > 2 : false

                        onActivated: (index) => {
                            if (curSystem && curSystem.compIDsStr.length > 1) {
                                curCompID = (index < 1) ? 0 : curSystem.compIDs[index - 1]
                            }
                        }
                    }
                }
            }
        }
    }

    // ================== PAGE ROOT (MÜTLƏQ ÖLÇÜ VER!) ==================
    Component {
        id: pageComponent

        Item {
            id: pageRoot
            width:  availableWidth
            height: availableHeight

            readonly property bool _hasVehicle: !!QGroundControl.multiVehicleManager.activeVehicle

            Loader {
                anchors.fill: parent
                active: pageRoot._hasVehicle
                sourceComponent: root._compact ? compactPage : widePage
            }

            // Aparat qoşulmayıbsa digər səhifələr kimi boz panel.
            Rectangle {
                visible: !pageRoot._hasVehicle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: root._sidePad
                anchors.rightMargin: root._sidePad
                height: AzTheme.px(200)
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - (root._sidePad * 2)
                    spacing: AzTheme.px(10)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: AzTheme.px(12); height: width; radius: width / 2
                        color: AzTheme.mutedText
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Aktiv aparat yoxdur")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: AzTheme.fontPx(17)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Qoşulduqdan sonra MAVLink mesajları görünəcək.")
                        color: AzTheme.textSecondary
                        font.family: AzTheme.fontFamily
                        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // ================== WIDE ==================
    Component {
        id: widePage

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: root._sidePad
                anchors.rightMargin: root._sidePad
                anchors.topMargin: 0
                anchors.bottomMargin: root._sidePad
                spacing: root._gap

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    columnSpacing: root._gap
                    rowSpacing: root._gap

                    Rectangle {
                        Layout.preferredWidth: root._buttonPaneW
                        Layout.minimumWidth:  root._minButtonW
                        Layout.fillHeight: true
                        radius: AzTheme.px(AzTheme.cardRadius)
                        border.width: 1
                        border.color: AzTheme.cardBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.cardGradientStart }
                            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                        }

                        QGCFlickable {
                            id: buttonGrid
                            anchors.fill: parent
                            anchors.margins: AzTheme.px(10)
                            flickableDirection: Flickable.VerticalFlick
                            clip: true

                            contentWidth:  width
                            contentHeight: buttonCol.implicitHeight
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            ColumnLayout {
                                id: buttonCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: root._fontH * 0.25

                                Repeater {
                                    model: curSystem ? curSystem.messages : []
                                    delegate: MAVLinkMessageButton {
                                        Layout.fillWidth: true
                                        text:      (object && object.name !== undefined) ? (String(object.name) + (object.fieldSelected ? " *" : "")) : ""
                                        compID:    object ? object.compId : 0
                                        checked:   curSystem ? (curSystem.selected === index) : false
                                        messageHz: object ? object.actualRateHz : 0
                                        visible:   (curCompID === 0) || (curCompID === compID)

                                        Component.onCompleted: root.maxButtonWidth = Math.max(root.maxButtonWidth, implicitWidth)
                                        onImplicitWidthChanged: root.maxButtonWidth = Math.max(root.maxButtonWidth, implicitWidth)

                                        onClicked: { if (curSystem) curSystem.selected = index }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
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

                        QGCFlickable {
                            id: messageGrid
                            anchors.fill: parent
                            anchors.margins: AzTheme.px(14)
                            flickableDirection: Flickable.VerticalFlick
                            clip: true

                            contentWidth:  width
                            contentHeight: messageCol.implicitHeight
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            QGCLabel {
                                anchors.centerIn: parent
                                visible: !(curMessage && (curCompID === 0 || curCompID === curMessage.compId))
                                text: qsTr("Zəhmət olmasa soldan bir mesaj seçin.")
                                color: AzTheme.textSecondary
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width * 0.9
                            }

                            Column {
                                id: messageCol
                                width: parent.width
                                spacing: root._fontH * 0.25
                                visible: (curMessage !== null) && (curCompID === 0 || curCompID === curMessage.compId)

                                Loader {
                                    width: parent.width
                                    sourceComponent: messageDetailsContent
                                    onLoaded: if (item) item.width = width
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ================== COMPACT (TƏK ÜMUMİ SCROLL) ==================
    Component {
        id: compactPage

        Item {
            anchors.fill: parent

            QGCFlickable {
                id: vFlick
                anchors.fill: parent
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                contentWidth:  width
                contentHeight: contentItem.implicitHeight + root._sidePad
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse
                    onWheel: (event) => {
                        event.accepted = true
                        var delta = (event.pixelDelta.y !== 0)
                                  ? event.pixelDelta.y
                                  : (event.angleDelta.y / 120.0) * root._wheelStepPx

                        var maxY = Math.max(0, vFlick.contentHeight - vFlick.height)
                        vFlick.contentY = Math.max(0, Math.min(maxY, vFlick.contentY - delta))
                    }
                }

                Item {
                    id: contentItem
                    width: vFlick.width
                    implicitHeight: col.implicitHeight
                    Column {
                        id: col
                        x: root._sidePad
                        width: Math.max(0, vFlick.width - 2 * root._sidePad)
                        spacing: root._gap

                        Rectangle {
                            width: parent.width
                            radius: AzTheme.px(AzTheme.cardRadius)
                            border.width: 1
                            border.color: AzTheme.cardBorder
                            gradient: Gradient {
                                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                            }
                            clip: true

                            Column {
                                x: Math.max(10, root._fontW * 1.2)
                                width: parent.width - 2 * x
                                y: Math.max(10, root._fontW * 1.2)
                                spacing: Math.max(8, root._gap * 0.8)

                                QGCLabel {
                                    text: qsTr("Mesajlar")
                                    font.weight: Font.Medium
                                    font.pixelSize: AzTheme.fontPx(16)
                                    color: AzTheme.textCard
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }

                                Column {
                                    width: parent.width
                                    spacing: root._fontH * 0.25

                                    Repeater {
                                        model: curSystem ? curSystem.messages : []
                                        delegate: MAVLinkMessageButton {
                                            width: parent.width
                                            text:      (object && object.name !== undefined) ? (String(object.name) + (object.fieldSelected ? " *" : "")) : ""
                                            compID:    object ? object.compId : 0
                                            checked:   curSystem ? (curSystem.selected === index) : false
                                            messageHz: object ? object.actualRateHz : 0
                                            visible:   (curCompID === 0) || (curCompID === compID)
                                            onClicked: { if (curSystem) curSystem.selected = index }
                                        }
                                    }
                                }

                                Item { height: Math.max(10, root._fontH * 0.5) }
                            }

                            implicitHeight: (childrenRect.height + Math.max(10, root._fontW * 1.2))
                        }

                        Rectangle {
                            width: parent.width
                            radius: AzTheme.px(AzTheme.cardRadius)
                            border.width: 1
                            border.color: AzTheme.cardBorder
                            gradient: Gradient {
                                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                            }
                            clip: true

                            Column {
                                x: Math.max(10, root._fontW * 1.2)
                                width: parent.width - 2 * x
                                y: Math.max(10, root._fontW * 1.2)
                                spacing: Math.max(8, root._gap * 0.9)

                                QGCLabel {
                                    visible: !(curMessage && (curCompID === 0 || curCompID === curMessage.compId))
                                    text: qsTr("Zəhmət olmasa yuxarıdan bir mesaj seçin.")
                                    color: AzTheme.textSecondary
                                    wrapMode: Text.WordWrap
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.width
                                }

                                Loader {
                                    visible: (curMessage !== null) && (curCompID === 0 || curCompID === curMessage.compId)
                                    width: parent.width
                                    sourceComponent: messageDetailsContent
                                    onLoaded: if (item) item.width = width
                                }

                                Item { height: Math.max(10, root._fontH * 0.5) }
                            }

                            implicitHeight: (childrenRect.height + Math.max(10, root._fontW * 1.2))
                        }

                        Item { height: root._sidePad }
                    }
                }
            }
        }
    }

    // ================== COMMON DETAILS ==================
    Component {
        id: messageDetailsContent

        Column {
            width: parent ? parent.width : 0
            spacing: root._fontH * 0.25

            GridLayout {
                columns: 2
                columnSpacing: root._fontW
                rowSpacing: root._fontH * 0.25
                width: parent.width

                QGCLabel { text: qsTr("Mesaj:"); font.pointSize: root._rowPt; Layout.minimumWidth: root._fontW * 18 }
                QGCLabel {
                    color: AzTheme.statusBlue
                    font.pointSize: root._rowPt
                    text: curMessage ? (String(curMessage.name) + " (" + String(curMessage.id) + ")") : ""
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                QGCLabel { text: qsTr("Komponent:"); font.pointSize: root._rowPt }
                QGCLabel { text: curMessage ? String(curMessage.compId) : ""; font.pointSize: root._rowPt }

                QGCLabel { text: qsTr("Count:"); font.pointSize: root._rowPt }
                QGCLabel { text: curMessage ? String(curMessage.count) : ""; font.pointSize: root._rowPt }

                QGCLabel { text: qsTr("Actual Rate:"); font.pointSize: root._rowPt }
                QGCLabel { font.pointSize: root._rowPt; text: curMessage ? (Number(curMessage.actualRateHz).toFixed(1) + qsTr("Hz")) : "" }

                QGCLabel { text: qsTr("Set Rate:"); font.pointSize: root._rowPt }
                QGCComboBox {
                    id: msgRateCombo
                    textRole: "text"
                    valueRole: "value"
                    font.pointSize: root._rowPt
                    model: [
                        { value: -1,  text: qsTr("Disabled") },
                        { value: 0,   text: qsTr("Default") },
                        { value: 1,   text: qsTr("1Hz") },
                        { value: 2,   text: qsTr("2Hz") },
                        { value: 3,   text: qsTr("3Hz") },
                        { value: 4,   text: qsTr("4Hz") },
                        { value: 5,   text: qsTr("5Hz") },
                        { value: 6,   text: qsTr("6Hz") },
                        { value: 7,   text: qsTr("7Hz") },
                        { value: 8,   text: qsTr("8Hz") },
                        { value: 9,   text: qsTr("9Hz") },
                        { value: 10,  text: qsTr("10Hz") },
                        { value: 25,  text: qsTr("25Hz") },
                        { value: 50,  text: qsTr("50Hz") },
                        { value: 100, text: qsTr("100Hz") }
                    ]
                    Layout.alignment: Qt.AlignLeft
                    sizeToContents: true
                    Component.onCompleted: reset()
                    onActivated: (index) => controller.setMessageInterval(currentValue)
                    function reset() { currentIndex = indexOfValue(0) }

                    Connections { target: root; function onCurMessageChanged() { msgRateCombo.reset() } }
                    Connections {
                        target: curMessage
                        function onTargetRateHzChanged() {
                            const i = indexOfValue(curMessage.targetRateHz)
                            if (i !== -1) currentIndex = i
                        }
                    }
                }
            }

            Item { height: root._fontH * 0.6; width: 1 }

            Flickable {
                id: msgInfoFlick
                width: parent.width
                height: msgInfoContainer.implicitHeight
                clip: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                contentWidth: Math.max(width, root._msgInfoMinW)
                contentHeight: height
                interactive: contentWidth > width + 2
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                Item {
                    id: msgInfoContainer
                    width: msgInfoFlick.contentWidth
                    implicitHeight: msgInfoGrid.implicitHeight

                    GridLayout {
                        id: msgInfoGrid
                        width: parent.width
                        columns: 5
                        columnSpacing: root._fontW * 0.25
                        rowSpacing: root._fontH * 0.25

                        QGCLabel { text: qsTr("Ad");    font.pointSize: root._rowPt; Layout.minimumWidth: root._nameColW }
                        QGCLabel { text: qsTr("Dəyər"); font.pointSize: root._rowPt; Layout.minimumWidth: root._valColW }
                        QGCLabel { text: qsTr("Növ");   font.pointSize: root._rowPt; Layout.minimumWidth: root._typeColW }
                        QGCLabel { text: qsTr("Plot 1");font.pointSize: root._rowPt; Layout.minimumWidth: root._plotColW; Layout.alignment: Qt.AlignHCenter }
                        QGCLabel { text: qsTr("Plot 2");font.pointSize: root._rowPt; Layout.minimumWidth: root._plotColW; Layout.alignment: Qt.AlignHCenter }

                        Rectangle {
                            Layout.columnSpan: 5
                            Layout.fillWidth: true
                            height: 1
                            color: AzTheme.groupBorder
                        }

                        Repeater {
                            model: curMessage ? curMessage.fields : []
                            delegate: QGCLabel {
                                Layout.row: index + 2
                                Layout.column: 0
                                Layout.minimumWidth: root._nameColW
                                font.pointSize: root._rowPt
                                text: (object && object.name !== undefined) ? String(object.name) : ""
                                elide: Text.ElideRight
                            }
                        }
                        Repeater {
                            model: curMessage ? curMessage.fields : []
                            delegate: QGCLabel {
                                Layout.row: index + 2
                                Layout.column: 1
                                Layout.minimumWidth: root._valColW
                                font.pointSize: root._rowPt
                                text: (object && object.value !== undefined) ? String(object.value) : ""
                                elide: Text.ElideRight
                            }
                        }
                        Repeater {
                            model: curMessage ? curMessage.fields : []
                            delegate: QGCLabel {
                                Layout.row: index + 2
                                Layout.column: 2
                                Layout.minimumWidth: root._typeColW
                                font.pointSize: root._rowPt
                                text: (object && object.type !== undefined) ? String(object.type) : ""
                                elide: Text.ElideRight
                            }
                        }

                        Repeater {
                            id: chart1Repeater
                            model: curMessage ? curMessage.fields : []
                            delegate: QGCCheckBox {
                                Layout.row: index + 2
                                Layout.column: 3
                                Layout.alignment: Qt.AlignHCenter
                                checked: (object && object.series !== null && object.series !== undefined && object.chartIndex === 0)
                                onClicked: {
                                    if (checked) chart1.addDimension(object)
                                    else chart1.delDimension(object)
                                    updateEnabledStatus(chart1Repeater, curMessage, chart1)
                                    updateEnabledStatus(chart2Repeater, curMessage, chart2)
                                }
                                Component.onCompleted: updateEnabledStatus(chart1Repeater, curMessage, chart1)
                            }
                        }

                        Repeater {
                            id: chart2Repeater
                            model: curMessage ? curMessage.fields : []
                            delegate: QGCCheckBox {
                                Layout.row: index + 2
                                Layout.column: 4
                                Layout.alignment: Qt.AlignHCenter
                                checked: (object && object.series !== null && object.series !== undefined && object.chartIndex === 1)
                                onClicked: {
                                    if (checked) chart2.addDimension(object)
                                    else chart2.delDimension(object)
                                    updateEnabledStatus(chart2Repeater, curMessage, chart2)
                                    updateEnabledStatus(chart1Repeater, curMessage, chart1)
                                }
                                Component.onCompleted: updateEnabledStatus(chart2Repeater, curMessage, chart2)
                            }
                        }
                    }
                }
            }

            Item { height: root._fontH * 0.35; width: 1 }

            MAVLinkChart { id: chart1; height: root._chartH; width: parent.width }
            MAVLinkChart { id: chart2; height: root._chartH; width: parent.width }

            Item { height: root._fontH * 0.6; width: 1 }
        }
    }
}

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "black"

    // ===== Responsive =====
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property real _m:       Math.max(6, ScreenTools.defaultFontPixelHeight * (_compact ? 0.45 : 0.55))
    readonly property real _side:    _compact ? Math.max(6, _m * 0.9) : _m * 2

    // ✅ Kiçik ekranda Search/Clear/Tools hündürlüyü ARTIRILDI (text cut olmasın)
    readonly property int  _ctrlH:     Math.round(ScreenTools.defaultFontPixelHeight * (_compact ? 1.55 : 2.0))
    readonly property int  _catH:      Math.round(ScreenTools.defaultFontPixelHeight * (_compact ? 1.35 : 2.0))
    readonly property real _ctrlFont:  ScreenTools.defaultFontPixelHeight * (_compact ? 0.82 : 1.0)
    readonly property real _catFont:   ScreenTools.defaultFontPixelHeight * (_compact ? 0.90 : 1.0)

    // Kiçik ekranda bloklar çox kiçilməsin
    readonly property real _compactGroupH: Math.max(ScreenTools.defaultFontPixelHeight * 10, Math.floor(root.height * 0.30))
    readonly property real _compactParamH: Math.max(ScreenTools.defaultFontPixelHeight * 16, Math.floor(root.height * 0.55))

    readonly property color _textOnBlack: "white"
    readonly property color _modifiedOnBlack: "#FF3B30"   // qırmızı (istəsən "#FF0000")


    // ===== State =====
    property Fact _editorDialogFact: Fact { }
    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool _showRCToParam: _activeVehicle ? _activeVehicle.px4Firmware : false
    property var  _appSettings:   QGroundControl.settingsManager.appSettings

    readonly property bool _searchFilter: (searchText.text.trim() !== "") || controller.showModifiedOnly

    ParameterEditorController { id: controller }

    // ✅ Tools menyusunu dəqiq Tools düyməsinin altına yerləşdir
    function positionToolsMenu() {
        if (!toolsButton) return

        // toolsButton-un ALT SOL nöqtəsi (root koordinatında)
        var p = toolsButton.mapToItem(root, 0, toolsButton.height)

        // menyunu düymənin altına və sağdan hizalı aç (ekrandan çıxmasın)
        var desiredX = p.x + toolsButton.width - customToolsMenu.width
        desiredX = Math.max(0, Math.min(desiredX, root.width - customToolsMenu.width))

        customToolsMenu.x = desiredX
        customToolsMenu.y = p.y + Math.round(ScreenTools.defaultFontPixelHeight * 0.25)
    }

    // İlk açılışda boş qalmasın: 1-ci category + 1-ci group seç
    Timer {
        id: initSelectTimer
        interval: 80
        running: true
        repeat: true
        onTriggered: {
            if (!controller || !controller.categories) return
            var cnt = controller.categories.count
            if (cnt === undefined || cnt <= 0) return

            if (!controller.currentCategory) {
                controller.currentCategory = controller.categories.get(0)
            }
            if (controller.currentCategory && !controller.currentGroup) {
                var g = controller.currentCategory.groups
                if (g && g.count !== undefined && g.count > 0) {
                    controller.currentGroup = g.get(0)
                }
            }
            if (controller.currentCategory) running = false
        }
    }

    Timer {
        id: clearTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            searchText.text = ""
            controller.searchText = ""
        }
    }

    QGCFileDialog {
        id:          fileDialog
        folder:      _appSettings.parameterSavePath
        nameFilters: [ qsTr("Parameter Files (*.%1)").arg(_appSettings.parameterFileExtension),
                       qsTr("All Files (*)") ]

        onAcceptedForSave: function(file) {
            controller.saveToFile(file)
            close()
        }

        onAcceptedForLoad: function(file) {
            close()
            if (controller.buildDiffFromFile(file)) {
                parameterDiffDialog.createObject(mainWindow).open()
            }
        }
    }

    Component {
        id: editorDialogComponent
        ParameterEditorDialog {
            fact:          _editorDialogFact
            showRCToParam: _showRCToParam
        }
    }

    Component {
        id: parameterDiffDialog
        ParameterDiffDialog {
            paramController: controller
        }
    }

    // Menyu bəndlərinin ən uzun mətnini ölçmək üçün.
    // ❗ Ölçünü BİR DƏFƏ hesablayıb sabit property-də saxlayırıq. Əvvəl width
    //    bindingi içindən toolsMetrics.text dəyişdirilirdi; toolsMetrics.width də
    //    həmin bindingin asılılığı olduğu üçün sonsuz binding loop yaranırdı.
    TextMetrics {
        id: toolsMetrics
        font.family:    ScreenTools.normalFontFamily
        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
    }

    property real _toolsMenuWidth: 300

    function _recalcToolsMenuWidth() {
        var labels = [
            qsTr("Yeniləyin"),
            qsTr("Hamısını proqram təminatının defoltlarına sıfırla"),
            qsTr("Təyyarənin konfiqurasiya defoltlarına sıfırla"),
            qsTr("Nəzərdən keçirilməsi üçün fayldan yükləyin..."),
            qsTr("Faylda saxla..."),
            qsTr("Param üçün bütün RC-ni silin"),
            qsTr("Təyyarəni yenidən başladın")
        ]
        var w = 0
        for (var i = 0; i < labels.length; ++i) {
            toolsMetrics.text = labels[i]
            w = Math.max(w, toolsMetrics.width)
        }
        // mətn + sol/sağ doldurma (14+14) + nəfəslik
        _toolsMenuWidth = w + 28 + ScreenTools.defaultFontPixelWidth * 1.5
    }

    Component.onCompleted: _recalcToolsMenuWidth()

    // ===== Tools menu (istədiyin stil) =====
    Menu {
        id: customToolsMenu
        // Əvvəlcədən ölçülmüş ölçüyə görə enlənir, amma ekran enini keçmir.
        width: Math.min(root.width - 20, Math.max(300, root._toolsMenuWidth))

        background: Rectangle {
            color: "#3D3B3B"
            border.color: "#9D9D9D"
            border.width: 1
            radius: 6
        }

        // ✅ Açılmamışdan əvvəl koordinatı yenilə
        onAboutToShow: root.positionToolsMenu()

        MenuItem {
            text: qsTr("Yeniləyin")
            onTriggered: controller.refresh()
            background: Rectangle { color: parent.highlighted ? "#504E4E" : "transparent"; radius: 4 }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.family: ScreenTools.normalFontFamily
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: 14
                rightPadding: 14
            }
        }

        MenuItem {
            text: qsTr("Hamısını proqram təminatının defoltlarına sıfırla")
            onTriggered: mainWindow.showMessageDialog(
                             qsTr("Hamısını Sıfırla"),
                             qsTr("Bütün parametrləri defoltlarına sıfırlamaq üçün Sıfırla seçin.\n\nNəzərə alın ki, bu, həmçinin UAVCAN qovşaqları, bütün təyyarə parametrləri, quraşdırma və kalibrləmə daxil olmaqla hər şeyi tamamilə sıfırlayacaq."),
                             Dialog.Cancel | Dialog.Reset,
                             function() { controller.resetAllToDefaults() }
                         )
            background: Rectangle { color: parent.highlighted ? "#504E4E" : "transparent"; radius: 4 }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.family: ScreenTools.normalFontFamily
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: 14
                rightPadding: 14
            }
        }

        MenuItem {
            text: qsTr("Təyyarənin konfiqurasiya defoltlarına sıfırla")
            visible: _activeVehicle && !_activeVehicle.apmFirmware
            onTriggered: mainWindow.showMessageDialog(
                             qsTr("Hamısını Sıfırla"),
                             qsTr("Bütün parametrləri təyyarənin konfiqurasiya defoltlarına sıfırlamaq üçün Sıfırla seçin."),
                             Dialog.Cancel | Dialog.Reset,
                             function() { controller.resetAllToVehicleConfiguration() }
                         )
            background: Rectangle { color: parent.highlighted ? "#504E4E" : "transparent"; radius: 4 }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.family: ScreenTools.normalFontFamily
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: 14
                rightPadding: 14
            }
        }

        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: "#6F6F6F" } }

        MenuItem {
            text: qsTr("Nəzərdən keçirilməsi üçün fayldan yükləyin...")
            onTriggered: {
                fileDialog.title = qsTr("Parametrləri yüklə")
                fileDialog.openForLoad()
            }
            background: Rectangle { color: parent.highlighted ? "#504E4E" : "transparent"; radius: 4 }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.family: ScreenTools.normalFontFamily
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: 14
                rightPadding: 14
            }
        }

        MenuItem {
            text: qsTr("Faylda saxla...")
            onTriggered: {
                fileDialog.title = qsTr("Parametrləri saxla")
                fileDialog.openForSave()
            }
            background: Rectangle { color: parent.highlighted ? "#504E4E" : "transparent"; radius: 4 }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.family: ScreenTools.normalFontFamily
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: 14
                rightPadding: 14
            }
        }

        MenuSeparator { visible: _showRCToParam; contentItem: Rectangle { implicitHeight: 1; color: "#6F6F6F" } }

        MenuItem {
            text: qsTr("Param üçün bütün RC-ni silin")
            visible: _showRCToParam && _activeVehicle
            onTriggered: _activeVehicle.clearAllParamMapRC()
            background: Rectangle { color: parent.highlighted ? "#504E4E" : "transparent"; radius: 4 }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.family: ScreenTools.normalFontFamily
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: 14
                rightPadding: 14
            }
        }

        MenuSeparator { contentItem: Rectangle { implicitHeight: 1; color: "#6F6F6F" } }

        MenuItem {
            text: qsTr("Təyyarəni yenidən başladın")
            visible: _activeVehicle
            onTriggered: mainWindow.showMessageDialog(
                             qsTr("Təyyarəni yenidən başladın"),
                             qsTr("Təyyarəni yenidən işə salmaq üçün Ok seçin."),
                             Dialog.Cancel | Dialog.Ok,
                             function() { _activeVehicle.rebootVehicle() }
                         )
            background: Rectangle { color: parent.highlighted ? "#504E4E" : "transparent"; radius: 4 }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.family: ScreenTools.normalFontFamily
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.9
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                leftPadding: 14
                rightPadding: 14
            }
        }

        onClosed: toolsButton.checked = false
    }

    // ======================
    // OUTER SCROLL (yalnız kiçik ekranda)
    // ======================
    QGCFlickable {
        id: pageFlick
        anchors.fill: parent
        clip: true

        flickableDirection: Flickable.VerticalFlick
        interactive: root._compact
        boundsBehavior: Flickable.StopAtBounds

        contentWidth: width
        contentHeight: root._compact ? (contentCol.implicitHeight + root._side) : height

        ScrollBar.vertical: ScrollBar { policy: root._compact ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        ColumnLayout {
            id: contentCol
            x: root._side
            y: 0
            width: pageFlick.width - (root._side * 2)

            // BÖYÜK EKRAN FIX
            height: root._compact ? implicitHeight : pageFlick.height

            spacing: root._compact ? (root._m * 0.55) : root._m

            // ===== Title + description =====
            ColumnLayout {
                Layout.fillWidth: true
                spacing: root._compact ? 2 : 4

                Text {
                    text: qsTr("Parametrlər")
                    color: "white"
                    font.bold: true
                    font.pixelSize: root._compact ? 22 : 28
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: qsTr("Parametrləri axtarın, kateqoriya və qruplara görə seçin.")
                    color: "#E8E8E8"
                    font.pixelSize: root._compact ? 12 : 14
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: qsTr("Dəyəri klikləyərək redaktə edin. Dəyişiklikləri ehtiyatla edin.")
                    color: "#CFCFCF"
                    font.pixelSize: root._compact ? 11 : 13
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            // ===== Navbar =====
            Rectangle {
                id: navBg
                Layout.fillWidth: true
                color: "#3D3B3B"
                radius: 8
                border.color: "#9D9D9D"
                border.width: 1

                readonly property real pad: root._compact ? Math.max(6, root._m * 0.70) : root._m
                implicitHeight: navGrid.implicitHeight + pad * 2

                GridLayout {
                    id: navGrid
                    x: navBg.pad
                    y: navBg.pad
                    width: navBg.width - navBg.pad * 2

                    columns: root._compact ? 2 : 5
                    columnSpacing: root._compact ? Math.max(6, root._m * 0.65) : root._m
                    rowSpacing:    root._compact ? Math.max(4, root._m * 0.50) : 0

                    QGCTextField {
                        id: searchText
                        placeholderText: qsTr("Axtar")
                        onDisplayTextChanged: controller.searchText = displayText

                        Layout.row: 0
                        Layout.column: 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: root._ctrlH
                        Layout.minimumHeight: root._ctrlH

                        font.pixelSize: root._ctrlFont

                        background: Rectangle {
                            color: "#2A2A2A"
                            radius: 5
                            border.color: "#FFFFFF"
                            border.width: 1
                        }
                        color: "#FFFFFF"
                        placeholderTextColor: "#FFFFFF"
                    }

                    QGCButton {
                        text: qsTr("Təmizlə")
                        Layout.row: 0
                        Layout.column: 1
                        Layout.preferredHeight: root._ctrlH
                        Layout.minimumHeight: root._ctrlH

                        background: Rectangle {
                            color: "#2A2A2A"
                            radius: 5
                            border.color: parent.pressed ? "#00FF00" : "#FFFFFF"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.family: ScreenTools.normalFontFamily
                            font.pixelSize: root._ctrlFont
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        onClicked: {
                            if (ScreenTools.isMobile) Qt.inputMethod.hide()
                            clearTimer.start()
                        }
                    }

                    QGCCheckBox {
                        id: showModifiedCheckbox
                        visible: _activeVehicle && _activeVehicle.px4Firmware
                        text: qsTr("Yalnız dəyişdirilmişləri göstərin")
                        checked: controller.showModifiedOnly
                        onClicked: controller.showModifiedOnly = checked

                        Layout.row: root._compact ? 1 : 0
                        Layout.column: root._compact ? 0 : 2
                        Layout.fillWidth: root._compact
                        Layout.preferredHeight: root._ctrlH
                        Layout.minimumHeight: root._ctrlH

                        background: Rectangle { color: "#2A2A2A"; radius: 5 }

                        indicator: Rectangle {
                            width:  root._compact ? 18 : 24
                            height: root._compact ? 18 : 24
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.leftPadding
                            radius: 4
                            border.color: parent.checked ? "#00FF00" : "#FFFFFF"
                            border.width: 2
                            color: parent.checked ? "#00FF00" : "transparent"

                            Text {
                                text: "✓"
                                color: "#2A2A2A"
                                font.pixelSize: height * 0.82
                                font.bold: true
                                anchors.centerIn: parent
                                visible: parent.parent.checked
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.family: ScreenTools.normalFontFamily
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * (root._compact ? 0.78 : 1.0)
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + parent.spacing + 5
                            elide: Text.ElideRight
                        }
                    }

                    QGCButton {
                        id: toolsButton
                        text: qsTr("Alətlər")
                        checkable: true

                        Layout.row: root._compact ? 1 : 0
                        Layout.column: root._compact ? 1 : 4
                        Layout.preferredHeight: root._ctrlH
                        Layout.minimumHeight: root._ctrlH

                        background: Rectangle {
                            color: "#2A2A2A"
                            radius: 5
                            border.color: parent.checked ? "#00FF00" : "#FFFFFF"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.family: ScreenTools.normalFontFamily
                            font.pixelSize: root._ctrlFont
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        onClicked: {
                            checked = true
                            root.positionToolsMenu()
                            customToolsMenu.open()
                        }
                    }

                    Flow {
                        id: categoryFlow
                        spacing: Math.max(6, root._m * 0.60)

                        Layout.row: root._compact ? 2 : 0
                        Layout.column: root._compact ? 0 : 3
                        Layout.columnSpan: root._compact ? 2 : 1
                        Layout.fillWidth: true

                        readonly property int cols: root._compact
                                                    ? Math.max(1, Math.min(3, controller.categories.count))
                                                    : 0

                        Repeater {
                            model: controller.categories

                            QGCButton {
                                text: object.name
                                checked: object == controller.currentCategory
                                autoExclusive: true

                                Layout.preferredHeight: root._catH
                                Layout.minimumHeight: root._catH

                                width: root._compact
                                       ? Math.max(90,
                                                  Math.floor((categoryFlow.width - categoryFlow.spacing * (categoryFlow.cols - 1)) / categoryFlow.cols))
                                       : implicitWidth

                                background: Rectangle {
                                    color: "#2A2A2A"
                                    radius: 5
                                    border.color: parent.checked ? "#00FF00" : "#FFFFFF"
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.family: ScreenTools.normalFontFamily
                                    font.pixelSize: root._catFont
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }

                                onClicked: {
                                    if (!checked) checked = true
                                    controller.currentCategory = object
                                    if (object && object.groups && object.groups.count !== undefined && object.groups.count > 0) {
                                        controller.currentGroup = object.groups.get(0)
                                    }
                                    toolsButton.checked = false
                                }
                            }
                        }
                    }
                }
            }

            // ===== Body =====
            GridLayout {
                id: bodyGrid
                Layout.fillWidth: true
                Layout.fillHeight: !root._compact

                columns: (root._compact || root._searchFilter) ? 1 : 2
                columnSpacing: root._m
                rowSpacing: root._searchFilter ? 0 : root._m

                Layout.preferredHeight: root._compact
                                        ? (root._searchFilter ? root._compactParamH : (root._compactGroupH + root._compactParamH + root._m))
                                        : -1

                Rectangle {
                    id: groupPanel
                    readonly property bool _hide: root._searchFilter
                    visible: !_hide
                    opacity: _hide ? 0 : 1

                    color: "transparent"
                    border.color: "#FFFFFF"
                    border.width: 2
                    radius: 8
                    clip: true

                    Layout.fillWidth: (!_hide && bodyGrid.columns === 1)

                    Layout.preferredWidth: _hide ? 0
                                          : (bodyGrid.columns === 2
                                             ? Math.max(ScreenTools.defaultFontPixelHeight * 14, bodyGrid.width * 0.28)
                                             : bodyGrid.width)
                    Layout.maximumWidth: _hide ? 0 : -1

                    Layout.fillHeight: (!_hide && !root._compact && bodyGrid.columns === 2)

                    Layout.preferredHeight: _hide ? 0 : (root._compact ? root._compactGroupH : bodyGrid.height)
                    Layout.maximumHeight: _hide ? 0 : -1

                    QGCFlickable {
                        id: groupScroll
                        anchors.fill: parent
                        anchors.margins: 6
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        contentHeight: groupedColumn.height

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                        Rectangle { anchors.fill: parent; color: "#3D3B3B"; radius: 5 }

                        ColumnLayout {
                            id: groupedColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: Math.ceil(ScreenTools.defaultFontPixelHeight * 0.25)

                            Repeater {
                                model: controller.categories

                                Column {
                                    Layout.fillWidth: true
                                    spacing: Math.ceil(ScreenTools.defaultFontPixelHeight * 0.25)

                                    SectionHeader {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        text: object.name
                                        checked: object == controller.currentCategory
                                        visible: true
                                        onCheckedChanged: {
                                            if (checked) {
                                                controller.currentCategory = object
                                                if (object && object.groups && object.groups.count !== undefined && object.groups.count > 0) {
                                                    controller.currentGroup = object.groups.get(0)
                                                }
                                            }
                                        }
                                    }

                                    Repeater {
                                        model: (object == controller.currentCategory) ? object.groups : 0

                                        QGCButton {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            text: object.name
                                            height: ScreenTools.defaultFontPixelHeight * 1.5
                                            checked: object == controller.currentGroup
                                            autoExclusive: true
                                            hoverEnabled: true

                                            background: Rectangle {
                                                color: parent.checked ? "#557D55" : (parent.hovered ? "#504E4E" : "#2A2A2A")
                                                radius: 5
                                                border.color: parent.checked ? "#00FF00" : "#9D9D9D"
                                                border.width: parent.hovered ? 2 : 1
                                            }

                                            contentItem: Text {
                                                text: parent.text
                                                color: parent.checked ? "#00FF00" : "#FFFFFF"
                                                font.family: ScreenTools.normalFontFamily
                                                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.85
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                            }

                                            onClicked: {
                                                checked = true
                                                controller.currentGroup = object
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: parameterPanel
                    color: "transparent"
                    border.color: "#FFFFFF"
                    border.width: 2
                    radius: 8
                    clip: true

                    Layout.fillWidth: true
                    Layout.fillHeight: !root._compact
                    Layout.preferredHeight: root._compact ? root._compactParamH : -1

                    TableView {
                        id: tableView
                        anchors.fill: parent
                        anchors.margins: 10
                        columnSpacing: ScreenTools.defaultFontPixelWidth
                        rowSpacing: ScreenTools.defaultFontPixelHeight / 4
                        model: controller.parameters
                        clip: true
                        contentWidth: width

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                        Timer {
                            id: forceLayoutTimer
                            interval: 350
                            repeat: false
                            onTriggered: tableView.forceLayout()
                        }

                        onContentYChanged: forceLayoutTimer.start()
                        onWidthChanged:    forceLayoutTimer.start()

                        onModelChanged: {
                            positionViewAtRow(0, TableView.AlignLeft | TableView.AlignTop)
                            forceLayoutTimer.start()
                        }

                        delegate: Item {
                            implicitWidth:  label.contentWidth
                            implicitHeight: label.contentHeight
                            clip: true


                            QGCLabel {
                                id: label
                                width: column == 1 ? ScreenTools.defaultFontPixelWidth * 15 : contentWidth
                                text: column == 1 ? col1String() : display

                                // ✅ column 0 (ad) həmişə ağ, column 1 (dəyər) default/ağ, dəyişibsə qırmızı
                                color: column == 1 ? col1Color() : root._textOnBlack

                                maximumLineCount: 1
                                elide: column == 1 ? Text.ElideRight : Text.ElideNone
                                font.family: "Arial"
                                font.pixelSize: 15

                                function col1Color() {
                                    // fact yoxdursa fallback
                                    if (!fact) return root._textOnBlack

                                    // ✅ dəyişdirilmiş parametr = defaultValueAvailable && !valueEqualsDefault
                                    if (fact.defaultValueAvailable && !fact.valueEqualsDefault) {
                                        return root._modifiedOnBlack
                                    }
                                    return root._textOnBlack
                                }

                                function col1String() {
                                    if (fact.enumStrings.length === 0) return fact.valueString + " " + fact.units
                                    if (fact.bitmaskStrings.length !== 0) return fact.selectedBitmaskStrings.join(',')
                                    return fact.enumStringValue
                                }
                            }

                            QGCMouseArea {
                                anchors.fill: parent
                                onClicked: function(mouse) {
                                    _editorDialogFact = fact
                                    editorDialogComponent.createObject(mainWindow).open()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

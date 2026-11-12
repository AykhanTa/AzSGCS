import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0

// Parameter editor, in the new design: the vehicle setup page header, a status card with
// the search, filter and tools, the categories as side-menu style chips, the groups as
// side menu items on a card, and the parameter table on a card.
Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    // The search field, check box, buttons and section headers take the new design's
    // look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ===== Responsive =====
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property real _m:       AzTheme.px(_compact ? 10 : 14)
    readonly property real _side:    AzTheme.px(_compact ? 12 : 20)
    readonly property real _top:     AzTheme.px(_compact ? 12 : 20)

    readonly property int  _ctrlH:   AzTheme.px(_compact ? 34 : 38)
    readonly property int  _catH:    AzTheme.px(_compact ? 32 : 36)
    readonly property real _cardPad: AzTheme.px(_compact ? 10 : 14)

    // Kiçik ekranda bloklar çox kiçilməsin
    readonly property real _compactGroupH: Math.max(ScreenTools.defaultFontPixelHeight * 10, Math.floor(root.height * 0.30))
    readonly property real _compactParamH: Math.max(ScreenTools.defaultFontPixelHeight * 16, Math.floor(root.height * 0.55))

    readonly property color _valueColor:    AzTheme.textCard
    readonly property color _modifiedColor: AzTheme.statusRed

    // ===== State =====
    property Fact _editorDialogFact: Fact { }
    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool _showRCToParam: _activeVehicle ? _activeVehicle.px4Firmware : false
    property var  _appSettings:   QGroundControl.settingsManager.appSettings

    readonly property bool _searchFilter: (searchText.text.trim() !== "") || controller.showModifiedOnly

    ParameterEditorController { id: controller }

    // The status card: linear-gradient(145deg, #25272A, #181B1E), 1 px #353A3F, radius 14
    component CardBackground: Rectangle {
        radius: AzTheme.px(AzTheme.cardRadius)
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }
    }

    // A row of the tools menu: the dark popup's row with a faint highlight
    component ToolsMenuItem: MenuItem {
        id: toolsItem
        implicitHeight: visible ? AzTheme.px(40) : 0
        height: implicitHeight

        background: Rectangle {
            color: toolsItem.highlighted ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
            radius: AzTheme.px(6)
        }
        contentItem: Text {
            text: toolsItem.text
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            leftPadding: AzTheme.px(12)
            rightPadding: AzTheme.px(12)
        }
    }

    component ToolsMenuSeparator: MenuSeparator {
        topPadding: AzTheme.px(4)
        bottomPadding: AzTheme.px(4)
        contentItem: Rectangle { implicitHeight: 1; color: AzTheme.panelBorder }
    }

    // ✅ Tools menyusunu dəqiq Tools düyməsinin altına yerləşdir
    function positionToolsMenu() {
        if (!toolsButton) return

        // toolsButton-un ALT SOL nöqtəsi (root koordinatında)
        var p = toolsButton.mapToItem(root, 0, toolsButton.height)

        // menyunu düymənin altına və sağdan hizalı aç (ekrandan çıxmasın)
        var desiredX = p.x + toolsButton.width - customToolsMenu.width
        desiredX = Math.max(0, Math.min(desiredX, root.width - customToolsMenu.width))

        customToolsMenu.x = desiredX
        customToolsMenu.y = p.y + AzTheme.px(6)
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
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
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
        // mətn + sol/sağ doldurma + menyunun öz kənarları + nəfəslik
        _toolsMenuWidth = w + AzTheme.px(24) + AzTheme.px(16) + ScreenTools.defaultFontPixelWidth * 1.5
    }

    Component.onCompleted: _recalcToolsMenuWidth()

    // ===== Tools menu: the dark popup of the new combo boxes =====
    Menu {
        id: customToolsMenu
        // Əvvəlcədən ölçülmüş ölçüyə görə enlənir, amma ekran enini keçmir.
        width: Math.min(root.width - 20, Math.max(300, root._toolsMenuWidth))
        padding: AzTheme.px(8)

        background: Rectangle {
            color: AzTheme.menuSelectedBottom
            border.color: AzTheme.panelBorder
            border.width: 1
            radius: AzTheme.px(AzTheme.popupRadius)
        }

        // ✅ Açılmamışdan əvvəl koordinatı yenilə
        onAboutToShow: root.positionToolsMenu()

        ToolsMenuItem {
            text: qsTr("Yeniləyin")
            onTriggered: controller.refresh()
        }

        ToolsMenuItem {
            text: qsTr("Hamısını proqram təminatının defoltlarına sıfırla")
            onTriggered: mainWindow.showMessageDialog(
                             qsTr("Hamısını Sıfırla"),
                             qsTr("Bütün parametrləri defoltlarına sıfırlamaq üçün Sıfırla seçin.\n\nNəzərə alın ki, bu, həmçinin UAVCAN qovşaqları, bütün təyyarə parametrləri, quraşdırma və kalibrləmə daxil olmaqla hər şeyi tamamilə sıfırlayacaq."),
                             Dialog.Cancel | Dialog.Reset,
                             function() { controller.resetAllToDefaults() }
                         )
        }

        ToolsMenuItem {
            text: qsTr("Təyyarənin konfiqurasiya defoltlarına sıfırla")
            visible: _activeVehicle && !_activeVehicle.apmFirmware
            onTriggered: mainWindow.showMessageDialog(
                             qsTr("Hamısını Sıfırla"),
                             qsTr("Bütün parametrləri təyyarənin konfiqurasiya defoltlarına sıfırlamaq üçün Sıfırla seçin."),
                             Dialog.Cancel | Dialog.Reset,
                             function() { controller.resetAllToVehicleConfiguration() }
                         )
        }

        ToolsMenuSeparator { }

        ToolsMenuItem {
            text: qsTr("Nəzərdən keçirilməsi üçün fayldan yükləyin...")
            onTriggered: {
                fileDialog.title = qsTr("Parametrləri yüklə")
                fileDialog.openForLoad()
            }
        }

        ToolsMenuItem {
            text: qsTr("Faylda saxla...")
            onTriggered: {
                fileDialog.title = qsTr("Parametrləri saxla")
                fileDialog.openForSave()
            }
        }

        ToolsMenuSeparator { visible: _showRCToParam }

        ToolsMenuItem {
            text: qsTr("Param üçün bütün RC-ni silin")
            visible: _showRCToParam && _activeVehicle
            onTriggered: if (_activeVehicle) _activeVehicle.clearAllParamMapRC()
        }

        ToolsMenuSeparator { }

        ToolsMenuItem {
            text: qsTr("Təyyarəni yenidən başladın")
            visible: _activeVehicle
            onTriggered: mainWindow.showMessageDialog(
                             qsTr("Təyyarəni yenidən başladın"),
                             qsTr("Təyyarəni yenidən işə salmaq üçün Ok seçin."),
                             Dialog.Cancel | Dialog.Ok,
                             function() { if (_activeVehicle) _activeVehicle.rebootVehicle() }
                         )
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
        contentHeight: root._compact ? (contentCol.implicitHeight + root._top + root._side) : height

        ScrollBar.vertical: ScrollBar { policy: root._compact ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        ColumnLayout {
            id: contentCol
            x: root._side
            y: root._top
            width: pageFlick.width - (root._side * 2)

            // BÖYÜK EKRAN FIX
            height: root._compact ? implicitHeight : (pageFlick.height - root._top - root._side)

            spacing: root._m

            // ===== Title + description =====
            ColumnLayout {
                Layout.fillWidth: true
                spacing: AzTheme.px(6)

                Text {
                    text: qsTr("Parametrlər")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(root._compact ? 18 : 20)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: qsTr("Parametrləri axtarın, kateqoriya və qruplara görə seçin.") + " " +
                          qsTr("Dəyəri klikləyərək redaktə edin. Dəyişiklikləri ehtiyatla edin.")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(13)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            // ===== Navbar: search, filter, categories and tools on a card =====
            CardBackground {
                id: navBg
                Layout.fillWidth: true
                implicitHeight: navGrid.implicitHeight + root._cardPad * 2

                GridLayout {
                    id: navGrid
                    x: root._cardPad
                    y: root._cardPad
                    width: navBg.width - root._cardPad * 2

                    columns: root._compact ? 2 : 5
                    columnSpacing: root._m
                    rowSpacing: root._compact ? AzTheme.px(8) : 0

                    QGCTextField {
                        id: searchText
                        placeholderText: qsTr("Axtar")
                        onDisplayTextChanged: controller.searchText = displayText

                        Layout.row: 0
                        Layout.column: 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: root._ctrlH
                        Layout.minimumHeight: root._ctrlH
                        Layout.minimumWidth: AzTheme.px(160)
                    }

                    QGCButton {
                        text: qsTr("Təmizlə")
                        Layout.row: 0
                        Layout.column: 1
                        Layout.preferredHeight: root._ctrlH
                        Layout.minimumHeight: root._ctrlH

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
                    }

                    QGCButton {
                        id: toolsButton
                        text: qsTr("Alətlər")
                        checkable: true
                        iconSource: "qrc:/res/AZSHIELD_ICON/v2/popup_settings.svg"

                        Layout.row: root._compact ? 1 : 0
                        Layout.column: root._compact ? 1 : 4
                        Layout.preferredHeight: root._ctrlH
                        Layout.minimumHeight: root._ctrlH

                        onClicked: {
                            checked = true
                            root.positionToolsMenu()
                            customToolsMenu.open()
                        }
                    }

                    Flow {
                        id: categoryFlow
                        spacing: AzTheme.px(6)

                        Layout.row: root._compact ? 2 : 0
                        Layout.column: root._compact ? 0 : 3
                        Layout.columnSpan: root._compact ? 2 : 1
                        Layout.fillWidth: true

                        readonly property int cols: root._compact
                                                    ? Math.max(1, Math.min(3, controller.categories.count))
                                                    : 0

                        Repeater {
                            model: controller.categories

                            // A chip with the side menu's selected box
                            QGCButton {
                                id: categoryChip
                                text: object.name
                                checked: object == controller.currentCategory
                                autoExclusive: true
                                hoverEnabled: true

                                height: root._catH
                                width: root._compact
                                       ? Math.max(90,
                                                  Math.floor((categoryFlow.width - categoryFlow.spacing * (categoryFlow.cols - 1)) / categoryFlow.cols))
                                       : implicitWidth

                                background: Rectangle {
                                    radius: AzTheme.px(AzTheme.menuSelectedRadius)
                                    color: (categoryChip.hovered && !categoryChip.checked) ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                                    gradient: categoryChip.checked ? chipGradient : null
                                    border.width: 1
                                    border.color: categoryChip.checked ? AzTheme.menuSelectedBorder
                                                                       : (categoryChip.hovered ? AzTheme.cardHoverBorder : AzTheme.groupBorder)

                                    Gradient {
                                        id: chipGradient
                                        GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                                        GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
                                    }
                                }
                                contentItem: Text {
                                    text: categoryChip.text
                                    color: categoryChip.checked ? AzTheme.textPrimary : AzTheme.textSecondary
                                    font.family: AzTheme.fontFamily
                                    font.weight: categoryChip.checked ? Font.Medium : Font.Normal
                                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
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

                // ---- Groups: side menu items on a card ----
                CardBackground {
                    id: groupPanel
                    readonly property bool _hide: root._searchFilter
                    visible: !_hide
                    opacity: _hide ? 0 : 1
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
                        anchors.margins: root._cardPad
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        contentHeight: groupedColumn.height

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                        ColumnLayout {
                            id: groupedColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: AzTheme.px(6)

                            Repeater {
                                model: controller.categories

                                Column {
                                    Layout.fillWidth: true
                                    spacing: AzTheme.px(4)

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

                                        // The side menu's item: the selected box, a faint outline on hover
                                        QGCButton {
                                            id: groupItem
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            text: object.name
                                            height: AzTheme.px(36)
                                            checked: object == controller.currentGroup
                                            autoExclusive: true
                                            hoverEnabled: true

                                            background: Rectangle {
                                                radius: AzTheme.px(AzTheme.menuSelectedRadius)
                                                color: (groupItem.hovered && !groupItem.checked) ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                                                gradient: groupItem.checked ? groupGradient : null
                                                border.width: (groupItem.checked || groupItem.hovered) ? 1 : 0
                                                border.color: groupItem.checked ? AzTheme.menuSelectedBorder : AzTheme.panelBorder

                                                Gradient {
                                                    id: groupGradient
                                                    GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                                                    GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
                                                }
                                            }

                                            contentItem: Text {
                                                text: groupItem.text
                                                color: groupItem.checked ? AzTheme.textPrimary : AzTheme.textCard
                                                font.family: AzTheme.fontFamily
                                                font.weight: groupItem.checked ? Font.Medium : Font.Normal
                                                font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: Text.AlignLeft
                                                leftPadding: AzTheme.px(12)
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

                // ---- Parameters: the table on a card ----
                CardBackground {
                    id: parameterPanel
                    clip: true

                    Layout.fillWidth: true
                    Layout.fillHeight: !root._compact
                    Layout.preferredHeight: root._compact ? root._compactParamH : -1

                    TableView {
                        id: tableView
                        anchors.fill: parent
                        anchors.margins: root._cardPad
                        columnSpacing: AzTheme.px(16)
                        rowSpacing: AzTheme.px(10)
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

                                // Ad ağ, təsvir boz; dəyər ağ, dəyişibsə qırmızı.
                                color: column == 1 ? col1Color() : (column == 0 ? AzTheme.textCard : AzTheme.textSecondary)

                                maximumLineCount: 1
                                elide: column == 1 ? Text.ElideRight : Text.ElideNone
                                font.family: AzTheme.fontFamily
                                font.weight: column == 1 ? Font.Medium : Font.Normal
                                font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)

                                function col1Color() {
                                    // fact yoxdursa fallback
                                    if (!fact) return root._valueColor

                                    // ✅ dəyişdirilmiş parametr = defaultValueAvailable && !valueEqualsDefault
                                    if (fact.defaultValueAvailable && !fact.valueEqualsDefault) {
                                        return root._modifiedColor
                                    }
                                    return root._valueColor
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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

// Analyze tools, in the new design (the same frame as the application settings): the
// 80 px header on the top bar's panel gradient with a back card, the tool list on the side
// menu's panel (its selected box and hover outline), and the tool on the dark app background.
Rectangle {
    id: qeydRoot
    anchors.fill: parent
    color: AzTheme.panelGradientEnd

    // Wheel and clicks on empty areas must not reach the fly view behind.
    MouseArea {
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        propagateComposedEvents: false

        onWheel: (wheel) => { wheel.accepted = true }
        onPressed: (mouse) => { mouse.accepted = true }
    }

    // QRC base (TopStatusPanel kimi)
    readonly property string _uiQrcBase: "qrc:/qml/QGroundControl/UI/"

    property int selectedIndex: 0

    // -------- responsive metrics --------
    readonly property real _m:     AzTheme.px(12)
    readonly property real topH:   AzTheme.px(80)
    readonly property real _itemH: AzTheme.px(52)

    readonly property real _minMenuW:  Math.max(170, ScreenTools.defaultFontPixelWidth * 18)
    readonly property real _maxMenuW:  Math.max(_minMenuW, Math.min(ScreenTools.defaultFontPixelWidth * 34, width * 0.34))
    readonly property real _autoMenuW: (menuColumn ? menuColumn.maxItemW : _minMenuW) + (_m * 2)
    readonly property real menuW:      Math.min(_maxMenuW, Math.max(_minMenuW, _autoMenuW))

    function closeThis() {
        if (typeof sideMenuLoader !== "undefined") {
            sideMenuLoader.source = ""
        }
    }

    /// Menu label of the page currently on the right, used to title its popout window.
    function currentPageTitle() {
        for (var i = 0; i < menuModel.count; i++) {
            var it = menuModel.get(i)
            if (it.idx === qeydRoot.selectedIndex) {
                return it.textLabel
            }
        }
        return ""
    }

    function openMenuByIdx(menuIdx) {
        qeydRoot.selectedIndex = menuIdx

        for (var i = 0; i < menuModel.count; i++) {
            var it = menuModel.get(i)
            if (it.idx === menuIdx) {
                if (it.page && it.page !== "") {
                    rightPanelLoader.source = _uiQrcBase + it.page     // ✅ qrc ilə aç
                } else {
                    rightPanelLoader.source = ""
                }

                var row = i
                Qt.callLater(function() {
                    var y = row * (qeydRoot._itemH + menuColumn.spacing)
                    menuFlick.contentY = Math.max(0, Math.min(y, menuFlick.contentHeight - menuFlick.height))
                })
                return
            }
        }
    }

    // ------------------ Top header ------------------
    Item {
        id: topHeader
        z: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: topH

        // linear-gradient(155deg), box-shadow 0 8px 16px rgba(0, 0, 0, 0.28)
        RectangularShadow {
            anchors.fill: headerBackground
            offset.y:     AzTheme.px(8)
            blur:         AzTheme.px(16)
            color:        AzTheme.topBarShadow
        }

        AzGradientRect {
            id:            headerBackground
            anchors.fill:  parent
            angle:         AzTheme.panelGradientAngle
            startColor:    AzTheme.panelGradientStart
            startPosition: AzTheme.panelGradientStartPos
            endColor:      AzTheme.panelGradientEnd
            endPosition:   AzTheme.panelGradientEndPos
        }

        Rectangle {
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            height:         1
            color:          AzTheme.panelBorder
        }

        // Back, on the status card style
        Item {
            id: backButton
            width: AzTheme.px(44)
            height: width
            anchors.left: parent.left
            anchors.leftMargin: AzTheme.px(18)
            anchors.verticalCenter: parent.verticalCenter

            AzGradientRect {
                anchors.fill:  parent
                angle:         AzTheme.cardGradientAngle
                startColor:    backMouse.pressed ? AzTheme.menuSelectedTop : AzTheme.cardGradientStart
                startPosition: AzTheme.cardGradientStartPos
                endColor:      backMouse.pressed ? AzTheme.menuSelectedBottom : AzTheme.cardGradientEnd
                endPosition:   AzTheme.cardGradientEndPos
                radius:        AzTheme.px(10)
                borderColor:   backMouse.containsMouse ? AzTheme.cardHoverBorder : AzTheme.cardBorder
                borderWidth:   1
            }

            QGCColoredImage {
                anchors.centerIn: parent
                source: "qrc:/res/AZSHIELD_ICON/Back.svg"
                width: AzTheme.px(20)
                height: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                color: AzTheme.textCard
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: closeThis()
            }
        }

        Column {
            anchors.left: backButton.right
            anchors.leftMargin: AzTheme.px(16)
            anchors.right: parent.right
            anchors.rightMargin: _m
            anchors.verticalCenter: parent.verticalCenter
            spacing: AzTheme.px(2)

            Text {
                width: parent.width
                text: qsTr("Alətlərin təhlili")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(22)
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: qsTr("Loglar pəncərəsi")
                color: AzTheme.textSecondary
                font.family: AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(13)
                elide: Text.ElideRight
            }
        }
    }

    // ------------------ Main content ------------------
    RowLayout {
        z: 1
        anchors.top: topHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0

        // LEFT MENU
        Rectangle {
            id: leftMenu
            Layout.preferredWidth: menuW
            Layout.maximumWidth: Layout.preferredWidth
            Layout.fillHeight: true
            color: "transparent"

            AzGradientRect {
                anchors.fill:  parent
                angle:         AzTheme.panelGradientAngle
                startColor:    AzTheme.panelGradientStart
                startPosition: AzTheme.panelGradientStartPos
                endColor:      AzTheme.panelGradientEnd
                endPosition:   AzTheme.panelGradientEndPos
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: _m
                anchors.rightMargin: Math.max(6, ScreenTools.defaultFontPixelWidth * 0.6)
                anchors.topMargin: _m
                anchors.bottomMargin: _m
                spacing: _m

                QGCFlickable {
                    id: menuFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    flickableDirection: Flickable.VerticalFlick
                    contentWidth: width
                    contentHeight: menuColumn.implicitHeight + 2

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Column {
                        id: menuColumn
                        width: menuFlick.width
                        spacing: AzTheme.px(6)

                        property real maxItemW: 0
                        function updateMax(w) { if (w > maxItemW) maxItemW = w }

                        Repeater {
                            model: menuModel

                            // The side menu's item: linear-gradient(180deg, #30353A, #202428),
                            // 1 px #5D646B, radius 8 when selected; a faint outline on hover.
                            delegate: Rectangle {
                                id: menuItem
                                height: qeydRoot._itemH
                                radius: AzTheme.px(AzTheme.menuSelectedRadius)

                                readonly property real _pad: AzTheme.px(12)
                                readonly property real _gap: AzTheme.px(12)
                                readonly property real _icon: AzTheme.px(20)
                                readonly property bool _selected: qeydRoot.selectedIndex === idx

                                readonly property real _idealW: (_pad * 2) + _icon + _gap + labelText.implicitWidth
                                Component.onCompleted: menuColumn.updateMax(_idealW)
                                width: Math.min(menuColumn.width, menuColumn.maxItemW)

                                property bool hovered: false

                                color: (hovered && !_selected) ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                                gradient: _selected ? selectedGradient : null
                                border.width: (_selected || hovered) ? 1 : 0
                                border.color: _selected ? AzTheme.menuSelectedBorder : AzTheme.panelBorder

                                Gradient {
                                    id: selectedGradient
                                    GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                                    GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
                                }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: menuItem._pad
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: menuItem._gap

                                    QGCColoredImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: iconPath
                                        width: menuItem._icon
                                        height: menuItem._icon
                                        sourceSize.height: height
                                        fillMode: Image.PreserveAspectFit
                                        color: menuItem._selected ? AzTheme.textPrimary : AzTheme.textCard
                                    }

                                    Text {
                                        id: labelText
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: textLabel
                                        color: menuItem._selected ? AzTheme.textPrimary : AzTheme.textCard
                                        font.family: AzTheme.fontFamily
                                        font.pixelSize: AzTheme.fontPx(16)
                                        elide: Text.ElideRight
                                        width: Math.min(implicitWidth, menuColumn.width - (menuItem._pad * 2 + menuItem._icon + menuItem._gap))
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: menuItem.hovered = true
                                    onExited: menuItem.hovered = false
                                    onClicked: openMenuByIdx(idx)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Sol menyu ilə sağ kontent arasında ayırıcı şaquli xətt
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: AzTheme.panelBorder
        }

        // RIGHT PANEL
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Loader {
                id: rightPanelLoader
                anchors.fill: parent

                // ✅ default page də qrc ilə
                source: _uiQrcBase + "Log_Download.qml"
            }

            // Pages derived from AnalyzePage can ask to be moved into their own window.
            // Pages that are not get filtered out by ignoreUnknownSignals.
            Connections {
                target: rightPanelLoader.item
                ignoreUnknownSignals: true

                function onPopout() {
                    var page = rightPanelLoader.item
                    if (!page) {
                        return
                    }

                    // Capture before anything is torn down.
                    var pageSource = rightPanelLoader.source
                    var pageTitle = qeydRoot.currentPageTitle()

                    // The page hands its loaded log over so the two instances never hold the
                    // same log at once; "" means it kept it (or had none).
                    var logPath = page.takeLogForPopout ? page.takeLogForPopout() : ""

                    mainWindow.createWindowedAnalyzePage(pageTitle, pageSource, logPath)

                    if (logPath !== "") {
                        // Rebuild the panel instance so it comes back empty rather than showing
                        // the remains of a log that now lives in the window.
                        rightPanelLoader.source = ""
                        rightPanelLoader.source = pageSource
                    }
                }
            }
        }
    }

    // MENU MODEL (page = sadəcə fayl adı)
    ListModel {
        id: menuModel
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appSet.svg";       textLabel: qsTr("Log Yükləmə");       page: "Log_Download.qml";      idx: 0 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Log_Analysis.svg"; textLabel: qsTr("Log Analizi");       page: "LogViewer_Page.qml";    idx: 1 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appFly.svg";       textLabel: qsTr("GeoTag Şəkillər");    page: "GeoTag.qml";            idx: 2 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appPlan.svg";      textLabel: qsTr("MAVLink Konsol");     page: "MAXLink_Console.qml";   idx: 3 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appVideo.svg";     textLabel: qsTr("MAVLink Inspector");  page: "MAXLink_Inspector.qml"; idx: 4 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appTelemetr.svg";  textLabel: qsTr("Vibrasiya");          page: "Vibration.qml";         idx: 5 }
    }
}

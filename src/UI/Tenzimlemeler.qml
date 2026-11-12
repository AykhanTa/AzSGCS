import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

// Application settings, in the new design: the vehicle setup frame's 80 px header on the
// top bar's panel gradient with a back card, the page list on the side menu's panel
// (its selected box and hover outline), and the page on the dark app background.
Rectangle {
    id: root
    anchors.fill: parent
    color: AzTheme.panelGradientEnd

    // =========================
    // ✅ INPUT BLOCKER (çox vacib)
    // - Mouse wheel/scroll arxaya (FlyView/Map) keçməsin
    // - Boş sahəyə klik də arxaya keçməsin
    //
    // Qeyd: z=0 saxlayırıq, UI isə z=1 olacaq.
    // Beləliklə UI normal işləyir, amma wheel boş sahədə/element qəbul etməyəndə udulur.
    // =========================
    MouseArea {
        id: inputBlocker
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        propagateComposedEvents: false

        onWheel: (wheel) => { wheel.accepted = true }
        onPressed: (mouse) => { mouse.accepted = true }
    }

    // Hansı menyu elementi seçilib
    property int selectedIndex: 0

    // ✅ Xaricdən açanda hansı səhifə açılsın
    property int startIndex: -1

    // Səhifə adı ilə açmaq (məs. "Comm_links.qml"). Sıra nömrəsindən üstündür: siyahıya
    // yeni bölmə əlavə olunanda nömrələr sürüşür, ad isə dəyişmir.
    property string startPage: ""

    function indexOfPage(page) {
        for (var i = 0; i < menuModel.count; i++) {
            if (menuModel.get(i).page === page) {
                return i
            }
        }
        return -1
    }

    function _startIndex() {
        var byPage = (startPage !== "") ? indexOfPage(startPage) : -1
        if (byPage >= 0) {
            return byPage
        }
        return (startIndex >= 0) ? startIndex : selectedIndex
    }

    function openMenuByIndex(i) {
        if (i < 0 || i >= menuModel.count) i = 0

        root.selectedIndex = i

        var it = menuModel.get(i)
        if (it.page && it.page !== "") {
            rightPanelLoader.setSource(Qt.resolvedUrl(it.page))
        } else {
            rightPanelLoader.source = ""
        }

        // (optional) seçilən item görünəcək yerə scroll
        Qt.callLater(function() {
            var itemH = root._itemH + menuColumn.spacing
            var y = i * itemH
            menuFlick.contentY = Math.max(0, Math.min(y, menuFlick.contentHeight - menuFlick.height))
        })
    }

    Component.onCompleted: Qt.callLater(function() {
        openMenuByIndex(_startIndex())
    })

    onStartIndexChanged: {
        if (startIndex >= 0) {
            Qt.callLater(function() { openMenuByIndex(startIndex) })
        }
    }

    // -------- responsive metrics --------
    readonly property bool smallScreen: width < 1100
    readonly property real _m: AzTheme.px(12)
    readonly property real topH: AzTheme.px(80)
    readonly property real _itemH: AzTheme.px(52)

    // Menu width limitləri (sabit deyil, auto + limit)
    readonly property real _minMenuW: Math.max(170, ScreenTools.defaultFontPixelWidth * 18)
    readonly property real _maxMenuW: Math.max(_minMenuW, Math.min(ScreenTools.defaultFontPixelWidth * 34, width * 0.34))

    // menu eni = ən uzun item + marginlər (auto-fit)
    readonly property real _autoMenuW: (menuColumn ? menuColumn.maxItemW : _minMenuW) + (_m * 2)
    readonly property real menuW: Math.min(_maxMenuW, Math.max(_minMenuW, _autoMenuW))

    function closeThis() {
        if (typeof sideMenuLoader !== "undefined") sideMenuLoader.source = ""
    }

    // ------------------ Menyu məlumatları ------------------
    ListModel {
        id: menuModel
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appSet.svg";      textLabel: qsTr("Ümumi");            page: "General_Settings.qml";              index: 0 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appFly.svg";      textLabel: qsTr("Uçuş Görünüşü");     page: "Fly_ViewSettings.qml";              index: 1 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appPlan.svg";     textLabel: qsTr("Plan Görünüşü");     page: "AppSettings_PlanView.qml";          index: 2 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appVideo.svg";    textLabel: qsTr("Video");            page: "AppSetting_VideoSettings.qml";      index: 3 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/GPS.svg";         textLabel: qsTr("NTRIP/RTK");        page: "NTRIP_Settings.qml";                index: 4 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appTelemetr.svg"; textLabel: qsTr("Telemetriya");       page: "Telemetry_Settings.qml";            index: 5 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appADSB.svg";     textLabel: qsTr("ADSB Server");       page: "ADSBServer.qml";                    index: 6 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appVideo.svg";    textLabel: qsTr("Gimbal");            page: "Gimbal_Settings.qml";               index: 7 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appLink.svg";     textLabel: qsTr("Rabitə Kanalları");  page: "Comm_links.qml";                    index: 8 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appMap.svg";      textLabel: qsTr("Xəritələr");         page: "AppSettings_MapSettings.qml";       index: 9 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appPX4.svg";      textLabel: qsTr("PX4 Log Transferi"); page: "PX4LogTransfer_Settings.qml";       index: 10 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appRemote.svg";   textLabel: qsTr("Remote ID");        page: "AppSettings_RemoteIdSettings.qml";  index: 11 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appConsole.svg";  textLabel: qsTr("Konsol");            page: "Console.qml";                       index: 12 }
        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/appHelp.svg";     textLabel: qsTr("Dəstək");            page: "AppHelp.qml";                       index: 13 }
    }

    // --------- Top header ---------
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
                text: qsTr("Tətbiq Tənzimləmələri")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(22)
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: qsTr("Dronunuzu uçuş üçün tənzimləyin")
                color: AzTheme.textSecondary
                font.family: AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(13)
                elide: Text.ElideRight
            }
        }
    }

    // --------- Main content: left menu + right panel ---------
    RowLayout {
        z: 1
        anchors.top: topHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0

        // ------------------ Sol menyu ------------------
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

                        // ✅ ən uzun item eni
                        property real maxItemW: 0
                        function updateMax(w) {
                            if (w > maxItemW) maxItemW = w
                        }
                        function recalcMax() {
                            var m = 0
                            for (var i = 0; i < children.length; i++) {
                                var c = children[i]
                                if (c && c._idealW !== undefined) {
                                    m = Math.max(m, c._idealW)
                                }
                            }
                            maxItemW = m
                        }

                        onWidthChanged: Qt.callLater(recalcMax)

                        Repeater {
                            model: menuModel

                            // The side menu's item: linear-gradient(180deg, #30353A, #202428),
                            // 1 px #5D646B, radius 8 when selected; a faint outline on hover.
                            delegate: Rectangle {
                                id: menuItem
                                height: root._itemH
                                radius: AzTheme.px(AzTheme.menuSelectedRadius)

                                readonly property real _pad: AzTheme.px(12)
                                readonly property real _gap: AzTheme.px(12)
                                readonly property real _icon: AzTheme.px(20)
                                readonly property bool _selected: root.selectedIndex === index

                                // ✅ ideal en: icon + gap + text + padding
                                readonly property real _idealW: (_pad * 2) + _icon + _gap + labelText.implicitWidth
                                Component.onCompleted: menuColumn.updateMax(_idealW)

                                // ✅ hamısı eyni enli: ən uzun yazının eni qədər (amma menuColumn.width limitdir)
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
                                    onClicked: root.openMenuByIndex(index)
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

        // ------------------ Sağ panel ------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Loader {
                id: rightPanelLoader
                anchors.fill: parent
                source: Qt.resolvedUrl("General_Settings.qml")
            }
        }
    }

    // Ekran ölçüsü dəyişəndə menu max eni yenidən hesablansın
    onWidthChanged: if (menuColumn) Qt.callLater(menuColumn.recalcMax)
}

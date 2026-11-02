import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import QtQuick.Layouts 1.15
import QGroundControl
import QGroundControl.Controls

// Vehicle setup, in the new design: a 80 px header on the top bar's panel gradient
// with a back card, the page list on the side menu's panel (its selected box and
// hover outline), and the page on the dark app background.
Rectangle {
    id: aparatRoot
    anchors.fill: parent
    color: AzTheme.panelGradientEnd

    // Hansı menyu elementi seçilib
    property int selectedIndex: 0

    readonly property real _m: AzTheme.px(12)
    readonly property real menuW: Math.max(AzTheme.px(220), Math.min(AzTheme.px(300), width * 0.22))
    readonly property real topH: AzTheme.px(80)
    readonly property real _itemH: AzTheme.px(52)

    // =========================
    // INPUT BLOCKERS
    // - Mouse wheel / scroll arxaya keçməsin
    // - Boş sahəyə klik arxaya keçməsin
    // =========================

    // Wheel: parent-chain üzərindən tutulur, yəni daxildə scroll olmayan yerdə də arxaya keçməyəcək
    WheelHandler {
        // parent = aparatRoot
        onWheel: function(wheel) {
            wheel.accepted = true
        }
    }

    // Click boş sahəyə düşəndə arxaya ötürülməsin
    // (UI elementləri bunun üstündədir, ona görə UI klikləri normal işləyir)
    MouseArea {
        id: mouseBlocker
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onWheel: (wheel) => { wheel.accepted = true }
    }

    // =========================
    // JOYSTICK AVAILABILITY
    // =========================
    function _listHasItems(l) {
        if (!l) return false
        if (l.length !== undefined) return l.length > 0
        if (l.count  !== undefined) return l.count > 0
        return false
    }

    // =========================
    // JOYSTICK AVAILABILITY  (FIX)
    // =========================
    readonly property bool _joystickAvailable: {
        var jm = null

        // QGC QML-də ən çox istifadə olunan yol
        if (typeof joystickManager !== "undefined" && joystickManager) {
            jm = joystickManager
        } else if (typeof QGroundControl !== "undefined" && QGroundControl && QGroundControl.joystickManager) {
            // ehtiyat variant (bəzilərində olur)
            jm = QGroundControl.joystickManager
        }

        if (!jm) return false

        // JoystickManager.h-də olan property-lərə görə:
        // joystickNames (QStringList) və joysticks (QVariantList) dəyişəndə availableJoysticksChanged gedir
        if (jm.joystickNames !== undefined && jm.joystickNames && jm.joystickNames.length > 0) return true
        if (jm.joysticks     !== undefined && jm.joysticks     && jm.joysticks.length     > 0) return true
        if (jm.activeJoystick) return true

        return false
    }


    // Summary kartından və ya soldan kliklə eyni davranış
    function openMenuByIdx(menuIdx) {

        // ✅ Joystick yoxdursa Joystick səhifəsini açma
        if (menuIdx === 3 && !_joystickAvailable) {
            return
        }

        aparatRoot.selectedIndex = menuIdx

        // menuModel-də uyğun elementi tapıb page-i yüklə
        for (var i = 0; i < menuModel.count; i++) {
            var it = menuModel.get(i)
            if (it.idx === menuIdx) {
                if (it.page && it.page !== "") {
                    rightPanelLoader.setSource(Qt.resolvedUrl(it.page))
                } else {
                    rightPanelLoader.source = ""
                }

                // (optional) seçilən element görünəcək yerə scroll elə
                Qt.callLater(function() {
                    var itemH = aparatRoot._itemH + menuColumn.spacing
                    var y = i * itemH
                    menuFlick.contentY = Math.max(0, Math.min(y, menuFlick.contentHeight - menuFlick.height))
                })

                return
            }
        }
        console.log("openMenuByIdx: idx tapılmadı:", menuIdx)
    }

    function closeThis() {
        // overlay bağla
        if (typeof sideMenuLoader !== "undefined") sideMenuLoader.source = ""
    }

    // --------- Top header ---------
    Item {
        id: topHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: topH
        z: 2

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
                text: qsTr("Təyyarənin qurulması")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(22)
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: qsTr("Təyyarənizi uçuş üçün konfiqurasiya edin")
                color: AzTheme.textSecondary
                font.family: AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(13)
                elide: Text.ElideRight
            }
        }
    }

    // --------- Main content: left menu + right panel ---------
    RowLayout {
        anchors.top: topHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0
        z: 1

        // Left menu
        Rectangle {
            id: leftMenu

            readonly property real _minMenuW: 170
            readonly property real _maxMenuW: menuW   // sənin limitin qalsın (210..300)

            // ✅ menunun eni = (ən uzun item eni) + marginlər, amma limitlə
            Layout.preferredWidth: Math.min(_maxMenuW,
                                            Math.max(_minMenuW,
                                                     (menuColumn ? menuColumn.maxItemW : 0) + (_m * 2)))

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
                anchors.margins: _m
                spacing: _m

                // Menu list (scroll)
                QGCFlickable {
                    id: menuFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: menuColumn.implicitHeight + 2
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ListModel {
                        id: menuModel
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Summary.svg";     textLabel: qsTr("Xülasə");           page: "SideMenu_Summary.qml";        idx: 0 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Frame.svg";       textLabel: qsTr("Frame");            page: "SideMenu_Cercive.qml";        idx: 1 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Radio.svg";       textLabel: qsTr("Radio");            page: "SideMenu_Radio.qml";          idx: 2 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/joystick.svg";    textLabel: qsTr("Joystick");         page: "SideMenu_Joystick.qml";       idx: 3 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/FlightModes.svg"; textLabel: qsTr("Uçuş Rejimləri");   page: "SideMenu_FlightMode.qml";     idx: 4 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/hazirliq.svg";    textLabel: qsTr("Uçuşa Hazırlıq");   page: "SideMenu_Sensors.qml";        idx: 5 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Power.svg";       textLabel: qsTr("Enerji");           page: "SideMenu_Enerji.qml";         idx: 6 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Motors.svg";      textLabel: qsTr("Aktuatorlar");      page: "SideMenu_Motors.qml";         idx: 7 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Safety.svg";      textLabel: qsTr("Təhlükəsizlik");    page: "SideMenu_Tehlukesizlik.qml";  idx: 8 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/PID.svg";         textLabel: qsTr("PID tənzimləmə");   page: "SideMenu_PIDTuning.qml";      idx: 9 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Parameters.svg";  textLabel: qsTr("Parametrlər");      page: "Side_ParameterPage.qml";      idx: 10 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Firmware.svg";    textLabel: qsTr("Proqramı Yüklə");   page: "Side_Proqram_Teminati.qml";   idx: 11 }
                    }

                    Column {
                        id: menuColumn
                        width: menuFlick.width
                        spacing: AzTheme.px(6)

                        property real maxItemW: 0
                        function updateMax(w) {
                            if (w > maxItemW) maxItemW = w
                        }

                        Repeater {
                            model: menuModel
                            // The side menu's item: linear-gradient(180deg, #30353A, #202428),
                            // 1 px #5D646B, radius 8 when selected; a faint outline on hover.
                            delegate: Rectangle {
                                id: menuItem
                                height: aparatRoot._itemH
                                radius: AzTheme.px(AzTheme.menuSelectedRadius)

                                readonly property real _pad: AzTheme.px(12)
                                readonly property real _gap: AzTheme.px(12)
                                readonly property real _icon: AzTheme.px(20)

                                // ✅ Joystick item disable şərti
                                readonly property bool _isJoystickItem: (idx === 3)
                                readonly property bool _enabledItem: (!_isJoystickItem) || aparatRoot._joystickAvailable
                                readonly property bool _selected: _enabledItem && aparatRoot.selectedIndex === idx

                                property bool hovered: false

                                color: (hovered && _enabledItem && !_selected) ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                                gradient: _selected ? selectedGradient : null
                                border.width: (_selected || (hovered && _enabledItem)) ? 1 : 0
                                border.color: _selected ? AzTheme.menuSelectedBorder : AzTheme.panelBorder

                                Gradient {
                                    id: selectedGradient
                                    GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                                    GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
                                }

                                // Disabled görünüş
                                opacity: _enabledItem ? 1.0 : 0.35

                                Row {
                                    id: contentRow
                                    spacing: menuItem._gap
                                    anchors.left: parent.left
                                    anchors.leftMargin: menuItem._pad
                                    anchors.verticalCenter: parent.verticalCenter

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

                                        width: Math.min(implicitWidth,
                                                        menuColumn.width - (menuItem._pad*2 + menuItem._icon + menuItem._gap))
                                    }
                                }

                                readonly property real _idealW: (menuItem._pad*2) + menuItem._icon + menuItem._gap + labelText.implicitWidth
                                Component.onCompleted: menuColumn.updateMax(_idealW)

                                width: Math.min(menuColumn.width, menuColumn.maxItemW)

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: menuItem._enabledItem
                                    hoverEnabled: true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onEntered: menuItem.hovered = true
                                    onExited: menuItem.hovered = false
                                    onClicked: aparatRoot.openMenuByIdx(idx)
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

        // Right panel
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Loader {
                id: rightPanelLoader
                anchors.fill: parent
                source: Qt.resolvedUrl("SideMenu_Summary.qml")

                onLoaded: {
                    if (item && item.hasOwnProperty("aparatController")) {
                        item.aparatController = aparatRoot
                    }
                }
            }
        }
    }
}

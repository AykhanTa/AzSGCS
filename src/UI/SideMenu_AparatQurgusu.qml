import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QGroundControl
import QGroundControl.Controls
//import QGroundControl.ScreenTools

Rectangle {
    id: aparatRoot
    anchors.fill: parent
    color: "#000000"

    // Hansı menyu elementi seçilib
    property int selectedIndex: 0

    readonly property real _m: Math.max(12, ScreenTools.defaultFontPixelWidth * 1.5)
    readonly property real menuW: Math.max(210, Math.min(300, width * 0.22))
    readonly property real topH: Math.max(78, ScreenTools.defaultFontPixelHeight * 4.2)

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
                    var itemH = 54 + menuColumn.spacing
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
        z: 1

        // Back (kiçik)
        Rectangle {
            width: 34
            height: 34
            radius: 6
            color: "#2a2a2a"
            anchors.left: parent.left
            anchors.leftMargin: _m
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.centerIn: parent
                source: "qrc:/res/AZSHIELD_ICON/Back.svg"
                width: 18
                height: 18
                fillMode: Image.PreserveAspectFit
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: closeThis()
            }
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: _m + 46
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: qsTr("Təyyarənin qurulması")
                color: "white"
                font.pixelSize: 24
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: qsTr("Təyyarənizi uçuş üçün konfiqurasiya edin")
                color: "#E8E8E8"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: "#FFFFFF"
            opacity: 0.25
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
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Parameters.svg";  textLabel: qsTr("Parametrlər");      page: "Side_Parameter.qml";          idx: 10 }
                        ListElement { iconPath: "qrc:/res/AZSHIELD_ICON/Firmware.svg";    textLabel: qsTr("Proqramı Yüklə");   page: "Side_Proqram_Teminati.qml";   idx: 11 }
                    }

                    Column {
                        id: menuColumn
                        width: menuFlick.width
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.7)

                        property real maxItemW: 0
                        function updateMax(w) {
                            if (w > maxItemW) maxItemW = w
                        }

                        Repeater {
                            model: menuModel
                            delegate: Rectangle {
                                id: menuItem
                                height: 48
                                radius: 10

                                readonly property real _pad: 10
                                readonly property real _gap: 10
                                readonly property real _icon: 20

                                // ✅ Joystick item disable şərti
                                readonly property bool _isJoystickItem: (idx === 3)
                                readonly property bool _enabledItem: (!_isJoystickItem) || aparatRoot._joystickAvailable

                                property bool hovered: false

                                color: (_enabledItem && aparatRoot.selectedIndex === idx) ? "#434343"
                                       : (hovered && _enabledItem ? "#2c2c2c" : "transparent")
                                border.width: (_enabledItem && aparatRoot.selectedIndex === idx) ? 1 : 0
                                border.color: "#5e5e5e"

                                // Disabled görünüş
                                opacity: _enabledItem ? 1.0 : 0.35

                                Row {
                                    id: contentRow
                                    spacing: menuItem._gap
                                    anchors.left: parent.left
                                    anchors.leftMargin: menuItem._pad
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        source: iconPath
                                        width: menuItem._icon
                                        height: menuItem._icon
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Text {
                                        id: labelText
                                        text: textLabel
                                        color: menuItem._enabledItem ? "white" : "#808080"
                                        font.pixelSize: 18
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
            color: "#3D3D3D"
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

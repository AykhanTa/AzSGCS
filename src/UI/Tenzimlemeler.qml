import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls
//import QGroundControl.ScreenTools

Rectangle {
    id: root
    anchors.fill: parent
    color: "#000000"

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
            var itemH = 48 + menuColumn.spacing
            var y = i * itemH
            menuFlick.contentY = Math.max(0, Math.min(y, menuFlick.contentHeight - menuFlick.height))
        })
    }

    Component.onCompleted: Qt.callLater(function() {
        openMenuByIndex(startIndex >= 0 ? startIndex : selectedIndex)
    })

    onStartIndexChanged: {
        if (startIndex >= 0) {
            Qt.callLater(function() { openMenuByIndex(startIndex) })
        }
    }

    // -------- responsive metrics --------
    readonly property bool smallScreen: width < 1100
    readonly property real _m: Math.max(12, ScreenTools.defaultFontPixelWidth * (smallScreen ? 1.0 : 1.4))
    readonly property real topH: Math.max(78, ScreenTools.defaultFontPixelHeight * 4.2)

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
        z: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: topH

        // Back
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
                text: qsTr("Tətbiq Tənzimləmələri")
                color: "white"
                font.pixelSize: Math.max(20, ScreenTools.defaultFontPixelHeight * 1.35)
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: qsTr("Dronunuzu uçuş üçün tənzimləyin")
                color: "#E8E8E8"
                font.pixelSize: Math.max(12, ScreenTools.defaultFontPixelHeight * 0.9)
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
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.7)

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

                            delegate: Rectangle {
                                id: menuItem
                                height: 48
                                radius: 10

                                readonly property real _pad: 10
                                readonly property real _gap: 10
                                readonly property real _icon: 18

                                // ✅ ideal en: icon + gap + text + padding
                                readonly property real _idealW: (_pad * 2) + _icon + _gap + labelText.implicitWidth
                                Component.onCompleted: menuColumn.updateMax(_idealW)

                                // ✅ hamısı eyni enli: ən uzun yazının eni qədər (amma menuColumn.width limitdir)
                                width: Math.min(menuColumn.width, menuColumn.maxItemW)

                                property bool hovered: false

                                color: root.selectedIndex === index ? "#434343"
                                       : (hovered ? "#2c2c2c" : "transparent")
                                border.width: root.selectedIndex === index ? 1 : 0
                                border.color: "#5e5e5e"

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: _pad
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: _gap

                                    Image {
                                        source: iconPath
                                        width: _icon
                                        height: _icon
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Text {
                                        id: labelText
                                        text: textLabel
                                        color: "white"
                                        font.pixelSize: 18
                                        elide: Text.ElideRight
                                        width: Math.min(implicitWidth, menuColumn.width - (_pad*2 + _icon + _gap))
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
            color: "#3D3D3D"
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

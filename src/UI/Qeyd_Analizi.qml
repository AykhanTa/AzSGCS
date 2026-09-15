import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: qeydRoot
    anchors.fill: parent
    color: "#000000"

    // QRC base (TopStatusPanel kimi)
    readonly property string _uiQrcBase: "qrc:/qml/QGroundControl/UI/"

    property int selectedIndex: 0

    readonly property real _m:    Math.max(12, ScreenTools.defaultFontPixelWidth * 1.5)
    readonly property real menuW: Math.max(210, Math.min(300, width * 0.22))
    readonly property real topH:  Math.max(78, ScreenTools.defaultFontPixelHeight * 4.2)

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

                Qt.callLater(function() {
                    var itemH = 48 + menuColumn.spacing
                    var y = i * itemH
                    menuFlick.contentY = Math.max(0, Math.min(y, menuFlick.contentHeight - menuFlick.height))
                })
                return
            }
        }
    }

    // ------------------ Top header ------------------
    Item {
        id: topHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: topH

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
            width: parent.width - (_m + 46) - _m

            Text {
                text: qsTr("Alətlərin təhlili")
                color: "white"
                font.pixelSize: 24
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: qsTr("Loglar pəncərəsi")
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

    // ------------------ Main content ------------------
    RowLayout {
        anchors.top: topHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0

        // LEFT MENU
        Rectangle {
            id: leftMenu
            color: "transparent"
            Layout.fillHeight: true

            readonly property real _minMenuW: 170
            readonly property real _maxMenuW: menuW

            Layout.preferredWidth: Math.min(_maxMenuW,
                                            Math.max(_minMenuW,
                                                     (menuColumn ? menuColumn.maxItemW : 0) + (_m * 2)))
            Layout.maximumWidth: Layout.preferredWidth

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: _m
                spacing: _m

                QGCFlickable {
                    id: menuFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    contentWidth: width
                    contentHeight: menuColumn.implicitHeight + 2

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Column {
                        id: menuColumn
                        width: menuFlick.width
                        spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.7)

                        property real maxItemW: 0
                        function updateMax(w) { if (w > maxItemW) maxItemW = w }

                        Repeater {
                            model: menuModel
                            delegate: Rectangle {
                                id: menuItem
                                height: 48
                                radius: 10

                                readonly property real _pad: 10
                                readonly property real _gap: 10
                                readonly property real _icon: 20

                                // Aparat Qurğusundakı ilə eyni hover davranışı
                                property bool hovered: false

                                color: (qeydRoot.selectedIndex === idx) ? "#434343"
                                       : (hovered ? "#2c2c2c" : "transparent")
                                border.width: (qeydRoot.selectedIndex === idx) ? 1 : 0
                                border.color: "#5e5e5e"

                                Row {
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
                                        color: "white"
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
        // (Aparat Qurğusu səhifəsindəki ilə eyni)
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: "#3D3D3D"
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

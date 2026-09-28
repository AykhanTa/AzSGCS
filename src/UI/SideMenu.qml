import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls
//import QGroundControl.ScreenTools

Rectangle {
    id: leftPanel
    color: "black"
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    z: 1

    // ---- QRC root-lar (.qrc-də prefix-lərlə uyğun olmalıdır) ----
    readonly property string _azIconRoot: "qrc:/res/AZSHIELD_ICON/"
    readonly property string _azQmlRoot:  "qrc:/qml/QGroundControl/"

    // ---------- Responsiv ölçülər ----------
    property int  originalWidth: 250
    property int  collapsedWidth: 80
    // Açılışda yığılmış başlayır: video/xəritə üçün yer qalsın. Loqoya toxunanda açılır.
    property bool isCollapsed: true

    Behavior on width { NumberAnimation { duration: 160 } }

    readonly property real _m: Math.max(10, ScreenTools.defaultFontPixelWidth * 1.2)
    readonly property real _logoH: isCollapsed ? 46 : 78

    // --- UI spacing tweaks ---
    readonly property real _menuTopGap: Math.max(14, ScreenTools.defaultFontPixelHeight * 0.9)

    // əvvəlki bottom lift səndə böyük ekranda “yaxşı” idi,
    // amma kiçik ekranda problemi yaradırdı. İndi adaptiv edirik:
    readonly property real _bottomLiftGap: Math.max(60, ScreenTools.defaultFontPixelHeight * 3)
    readonly property bool _compactHeight: (ScreenTools.isMobile || leftPanel.height < ScreenTools.defaultFontPixelHeight * 38)

    // Kiçik ekranda düymələr dibə yaxın olsun (lift azalsın),
    // böyük ekranda əvvəlki kimi bir az yuxarıda qala bilər:
    readonly property real _bottomInset: _compactHeight ? Math.max(10, ScreenTools.defaultFontPixelHeight * 0.8)
                                                       : _bottomLiftGap

    readonly property real _actionBtnWExpanded: Math.min(
                                                  200,
                                                  Math.max(160, (leftPanel.parent ? leftPanel.parent.width * 0.65 : 200))
                                               )
    readonly property real _actionBtnW: isCollapsed ? 50 : _actionBtnWExpanded

    // 3 font heights is the 60px these used to hard code. Capped against the
    // window as well, because 60 is a twentieth of a desktop screen and a ninth
    // of the G30's 533 logical pixels, so the pair dominated the menu there.
    readonly property real _actionBtnH: Math.min(ScreenTools.defaultFontPixelHeight * 3,
                                                 (leftPanel.parent ? leftPanel.parent.height : 600) * 0.10)

    width: isCollapsed ? collapsedWidth : (_actionBtnW + (2 * _m))

    // ---------- QGC state ----------
    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _communicationLost: (_activeVehicle && _activeVehicle.vehicleLinkManager)
                                             ? _activeVehicle.vehicleLinkManager.communicationLost
                                             : false
    property var  _autoConnectSettings: QGroundControl.settingsManager.autoConnectSettings

    // UI text/state
    property string disconnectButtonText: qsTr("Avto bağlantını kəs")
    property string manualConnectionText: qsTr("Manual Bağlan")
    property bool   isManualConnected: false

    // Custom auto-connect flag
    property bool autoConnectEnabled: true

    function _setBoolSetting(settingObj, v) {
        if (!settingObj) return
        if (settingObj.rawValue !== undefined) {
            settingObj.rawValue = v
            return
        }
        if (settingObj.value !== undefined) {
            settingObj.value = v
            return
        }
    }

    function disconnectVehicle() {
       // console.log("=== RESET CONNECTION (AutoConnect AÇIQ QALIR) ===")

        disconnectButtonText = qsTr("Avto bağlantı kəsildi")
        manualConnectionText = qsTr("Manual Bağlan")
        isManualConnected    = false

        if (_activeVehicle) {
            try { _activeVehicle.closeVehicle() } catch (e) { console.log(e) }
        }

        var linkManager = QGroundControl.linkManager
        if (linkManager) {
            if (typeof linkManager.disconnectAll === "function") {
                linkManager.disconnectAll()
            } else {
                if (linkManager.links && linkManager.links.count > 0) {
                    for (var i = 0; i < linkManager.links.count; i++) {
                        var link = linkManager.links.get(i)
                        if (link && link.isConnected) {
                            try { link.disconnect() } catch (e2) { console.log(e2) }
                        }
                    }
                }
            }
        }

       // console.log("=== RESET CONNECTION BITDI (AutoConnect AÇIQ) ===")
    }

    function startAutoConnect() {
        //console.log("=== AUTO-CONNECT BAŞLATILDI ===")

        if (_activeVehicle) return

        var linkManager = QGroundControl.linkManager
        if (!linkManager) return

        var cfgs = linkManager.linkConfigurations
        if (!cfgs || cfgs.count === undefined) return

        for (var i = 0; i < cfgs.count; i++) {
            var linkConfig = cfgs.get(i)
            if (!linkConfig) continue

            var isAuto = (linkConfig.autoConnect === true) || (linkConfig.autoConnect === 1)
            if (!isAuto) continue

            var already = false
            if (linkManager.links && linkManager.links.count > 0) {
                for (var j = 0; j < linkManager.links.count; j++) {
                    var existingLink = linkManager.links.get(j)
                    if (existingLink &&
                        existingLink.linkConfiguration === linkConfig &&
                        existingLink.isConnected) {
                        already = true
                        break
                    }
                }
            }
            if (already) continue

            try {
                if (typeof linkManager.createConnectedLink === "function") {
                    linkManager.createConnectedLink(linkConfig)
                } else if (typeof linkManager.connectLink === "function") {
                    linkManager.connectLink(linkConfig)
                }
            } catch (e) {
                console.log(e)
            }
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) {
            //console.log("Aktiv aparat dəyişdi:", activeVehicle ? "Bağlı" : "Bağlı deyil")

            if (activeVehicle) {
                disconnectButtonText = qsTr("Avto bağlantını kəs")
                if (isManualConnected) manualConnectionText = qsTr("Manual Bağlandı")
            } else {
                disconnectButtonText = qsTr("Avto bağlantı kəsildi")
                manualConnectionText = qsTr("Manual Bağlan")
                isManualConnected = false

                if (autoConnectEnabled) {
                    Qt.callLater(function() { startAutoConnect() })
                }
            }
        }
    }

    Connections {
        target: QGroundControl.linkManager
        ignoreUnknownSignals: true
        function onLinkConnected(link) {
           // console.log("✅ Link BAĞLANDI:", link.linkConfiguration.name, "- Tip:", link.linkConfiguration.type)
            disconnectButtonText = qsTr("Avto bağlantını kəs")
        }
    }

    Connections {
        target: (_activeVehicle && _activeVehicle.vehicleLinkManager) ? _activeVehicle.vehicleLinkManager : null
        ignoreUnknownSignals: true
        function onCommunicationLostChanged() {
            if (_communicationLost) {
                disconnectButtonText = qsTr("Avto bağlantı kəsildi")
            } else {
                if (_activeVehicle) disconnectButtonText = qsTr("Avto bağlantını kəs")
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            if (autoConnectEnabled) startAutoConnect()
        })
    }

    // =========================
    //  TOP AREA: Logo + Menu (scroll)
    // =========================
    Item {
        id: topArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomArea.top

        anchors.leftMargin:  leftPanel._m
        anchors.rightMargin: leftPanel._m
        anchors.topMargin:   leftPanel._m
        anchors.bottomMargin: leftPanel._m

        // Logo
        Item {
            id: logoArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: leftPanel._logoH

            Image {
                id: logoImage
                anchors.centerIn: parent
                source: leftPanel._azIconRoot + (isCollapsed ? "Logo2.svg" : "Logo.svg")
                width: isCollapsed ? 44 : 120
                height: isCollapsed ? 44 : 72
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: isCollapsed = !isCollapsed
            }
        }

        // Menü scroll (bu hissə artıq düymələri yuxarı “sıxmayacaq”)
        QGCFlickable {
            id: menuFlick
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: logoArea.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: leftPanel._menuTopGap

            clip: true
            contentWidth: width
            contentHeight: menuColumn.implicitHeight + 2

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: menuColumn
                width: menuFlick.width
                spacing: Math.max(8, ScreenTools.defaultFontPixelHeight * 0.5)

                // NOTE: `pageId` is the stable, never translated key used for dispatch.
                //       Never branch on `text` - it changes with the UI language.
                ListModel {
                    id: mainMenuModel
                    ListElement { pageId: "home";     icon: "qrc:/res/AZSHIELD_ICON/Home.svg";             text: qsTr("Ana səhifə") }
                    ListElement { pageId: "flyPanel"; icon: "qrc:/res/takeoff.svg";                       text: qsTr("Uçuş paneli") }
                    ListElement { pageId: "multiVeh"; icon: "qrc:/res/AZSHIELD_ICON/FlightMode.svg";       text: qsTr("Multi Vehicle") }
                    ListElement { pageId: "plan";     icon: "qrc:/res/AZSHIELD_ICON/Mission_Planner.svg";  text: qsTr("Missiya Planlayıcısı") }
                    ListElement { pageId: "setup";    icon: "qrc:/res/AZSHIELD_ICON/Vehicle_Setup.svg";    text: qsTr("Aparat Qurğusu") }
                    ListElement { pageId: "logs";     icon: "qrc:/res/AZSHIELD_ICON/Log_Analysis.svg";     text: qsTr("Qeyd Analizi") }
                    ListElement { pageId: "settings"; icon: "qrc:/res/AZSHIELD_ICON/Settings.svg";         text: qsTr("Tənzimləmələr") }
                }

                Repeater {
                    model: mainMenuModel
                    delegate: Rectangle {
                        width: parent.width
                        height: 44
                        radius: 8
                        color: hovered ? "#2c2c2c" : "transparent"
                        property bool hovered: false

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: isCollapsed ? 10 : 14
                            anchors.rightMargin: 10
                            spacing: 10

                            Image {
                                source: icon
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                text: model.text
                                visible: !isCollapsed
                                color: "white"
                                font.pixelSize: 16
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: parent.hovered = true
                            onExited: parent.hovered = false

                            onClicked: {
                                // Dispatch on the stable id, not on the (translated) label
                                switch (model.pageId) {
                                case "settings":
                                    mainWindow.hideToolDrawer()
                                    sideMenuLoader.source = leftPanel._azQmlRoot + "Tenzimlemeler.qml"
                                    break

                                case "home":
                                    mainWindow.showFlyView()
                                    mainWindow.hideToolDrawer()
                                    isCollapsed = false
                                    break

                                case "logs":
                                    mainWindow.hideToolDrawer()
                                    sideMenuLoader.source = leftPanel._azQmlRoot + "Qeyd_Analizi.qml"
                                    break

                                case "setup":
                                    mainWindow.hideToolDrawer()
                                    sideMenuLoader.source = leftPanel._azQmlRoot + "SideMenu_AparatQurgusu.qml"
                                    break

                                case "plan":
                                    mainWindow.hideToolDrawer()
                                    mainWindow.hideTopStatusPanel()
                                    mainWindow.showPlanView()
                                    leftPanel.visible = false
                                    break

                                case "flyPanel":
                                    mainWindow.showFlyView()
                                    mainWindow.hideToolDrawer()
                                    mainWindow.showFlightPanel = !mainWindow.showFlightPanel
                                    mainWindow.isFlyViewActive = !mainWindow.isFlyViewActive
                                    isCollapsed = true
                                    break

                                case "multiVeh":
                                    mainWindow.showFlyView()
                                    mainWindow.hideToolDrawer()
                                    mainWindow.showMultiVehiclePanel = !mainWindow.showMultiVehiclePanel
                                    isCollapsed = true
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================
    //  BOTTOM AREA: Manual + Disconnect (always bottom)
    // =========================
    Item {
        id: bottomArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        anchors.leftMargin:  leftPanel._m
        anchors.rightMargin: leftPanel._m
        anchors.bottomMargin: leftPanel._bottomInset

        height: actionsCol.implicitHeight

        ColumnLayout {
            id: actionsCol
            anchors.fill: parent
            spacing: Math.max(10, ScreenTools.defaultFontPixelHeight * 0.6)

            // Manual connect
            Rectangle {
                id: manualButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _actionBtnW
                Layout.minimumWidth: _actionBtnW
                Layout.maximumWidth: _actionBtnW
                Layout.preferredHeight: leftPanel._actionBtnH

                radius: 10
                color: "#434343"
                border.width: 1
                border.color: "#9D9D9D"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(manualButton.height * 0.2)
                    spacing: 10

                    Image {
                        source: leftPanel._azIconRoot + "manual.svg"
                        Layout.preferredWidth: Math.round(manualButton.height * 0.40)
                        Layout.preferredHeight: Layout.preferredWidth
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        text: leftPanel.manualConnectionText
                        visible: !isCollapsed
                        color: leftPanel.manualConnectionText === qsTr("Manual Bağlandı") ? "orange" : "white"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        leftPanel.isManualConnected = true
                        if (mainWindow.showConnectionList) mainWindow.showConnectionList()
                    }
                }
            }

            // Disconnect
            Rectangle {
                id: disconnectButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _actionBtnW
                Layout.minimumWidth: _actionBtnW
                Layout.maximumWidth: _actionBtnW
                Layout.preferredHeight: leftPanel._actionBtnH

                radius: 8
                color: "#434343"
                border.width: 1
                border.color: "#9D9D9D"

                enabled: _communicationLost

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    Image {
                        source: leftPanel._azIconRoot + "disconnect.svg"
                        width: Math.round(disconnectButton.height * 0.43)
                        height: width
                        fillMode: Image.PreserveAspectFit
                        opacity: disconnectButton.enabled ? 1.0 : 0.2
                    }

                    Text {
                        text: leftPanel.disconnectButtonText
                        color: "white"
                        opacity: disconnectButton.enabled ? 1.0 : 0.2
                        font.pixelSize: 14
                        y: 2
                        visible: !isCollapsed
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: disconnectButton.enabled
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (!disconnectButton.enabled) return
                        disconnectVehicle()
                    }
                }
            }
        }
    }
}

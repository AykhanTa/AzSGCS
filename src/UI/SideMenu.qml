import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

// Left navigation, laid out from the Figma "Ana səhifə" frame. Every length below is
// the design value in px and goes through AzTheme.px() so the menu scales with the
// window; AzTheme.compact collapses it (MainWindow._applyResponsiveMenuState).
Item {
    id: leftPanel
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    z: 1

    // ---- QRC root-lar (.qrc-də prefix-lərlə uyğun olmalıdır) ----
    readonly property string _azIconRoot: "qrc:/res/AZSHIELD_ICON/"
    readonly property string _azV2Root:   "qrc:/res/AZSHIELD_ICON/v2/"
    readonly property string _azQmlRoot:  "qrc:/qml/QGroundControl/"

    property bool isCollapsed: false

    // Page shown as current. Uçuş Paneli and Multi Vehicle are toggles over the fly
    // view, so they hold the selection only while their panel is open.
    property string selectedPageId: "home"

    Behavior on width { NumberAnimation { duration: 160 } }

    readonly property real _itemMargin: AzTheme.px(10)
    readonly property real _itemHeight: AzTheme.px(60)
    readonly property real _iconBox:    AzTheme.px(60)

    width: AzTheme.px(isCollapsed ? 80 : 278)

    // Full-screen pages (settings, setup, logs) and the plan view hide the menu; it
    // comes back on the fly view.
    onVisibleChanged: {
        if (visible) {
            selectedPageId = mainWindow.showFlightPanel ? "flyPanel" : "home"
        }
    }

    Connections {
        target: mainWindow
        function onShowFlightPanelChanged() {
            if (!mainWindow.showFlightPanel && leftPanel.selectedPageId === "flyPanel") {
                leftPanel.selectedPageId = "home"
            }
        }
        function onShowMultiVehiclePanelChanged() {
            if (!mainWindow.showMultiVehiclePanel && leftPanel.selectedPageId === "multiVeh") {
                leftPanel.selectedPageId = "home"
            }
        }
    }

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

    function _activate(pageId) {
        // Dispatch on the stable id, not on the (translated) label
        switch (pageId) {
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

        if (pageId === "flyPanel") {
            selectedPageId = mainWindow.showFlightPanel ? "flyPanel" : "home"
        } else if (pageId === "multiVeh") {
            selectedPageId = mainWindow.showMultiVehiclePanel ? "multiVeh" : "home"
        } else {
            selectedPageId = pageId
        }
    }

    // Connection actions at the bottom of the menu. They are not in the design yet;
    // they keep the status card style until they get a place of their own.
    component ActionButton: Item {
        id: action

        property string iconSource
        property string label
        property color  labelColor: AzTheme.textCard
        property bool   collapsed:  false

        signal clicked()

        height:  AzTheme.px(52)
        opacity: enabled ? 1.0 : 0.35

        AzGradientRect {
            anchors.fill:  parent
            angle:         AzTheme.cardGradientAngle
            startColor:    actionMouse.pressed ? AzTheme.menuSelectedTop : AzTheme.cardGradientStart
            startPosition: AzTheme.cardGradientStartPos
            endColor:      actionMouse.pressed ? AzTheme.menuSelectedBottom : AzTheme.cardGradientEnd
            endPosition:   AzTheme.cardGradientEndPos
            radius:        AzTheme.px(AzTheme.cardRadius)
            borderColor:   actionMouse.containsMouse ? AzTheme.menuSelectedBorder : AzTheme.cardBorder
            borderWidth:   1
        }

        Image {
            id:                     actionIcon
            anchors.verticalCenter: parent.verticalCenter
            x:                      action.collapsed ? (action.width - width) / 2 : AzTheme.px(16)
            width:                  AzTheme.px(22)
            height:                 width
            sourceSize.width:       width
            sourceSize.height:      height
            fillMode:               Image.PreserveAspectFit
            source:                 action.iconSource
        }

        Text {
            anchors.left:           actionIcon.right
            anchors.leftMargin:     AzTheme.px(12)
            anchors.right:          parent.right
            anchors.rightMargin:    AzTheme.px(12)
            anchors.verticalCenter: parent.verticalCenter
            visible:                !action.collapsed
            text:                   action.label
            color:                  action.labelColor
            font.family:            AzTheme.fontFamily
            font.pixelSize:         AzTheme.fontPx(14)
            elide:                  Text.ElideRight
        }

        MouseArea {
            id:           actionMouse
            anchors.fill: parent
            enabled:      action.enabled
            hoverEnabled: true
            cursorShape:  enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked:    action.clicked()
        }

        ToolTip.visible: action.collapsed && actionMouse.containsMouse
        ToolTip.text:    action.label
        ToolTip.delay:   400
    }

    // =========================
    //  Background: linear-gradient(155deg), 1 px right border,
    //  box-shadow 12px 0 35px rgba(0, 0, 0, 0.2) cast onto the map
    // =========================
    RectangularShadow {
        anchors.fill: panelBackground
        offset.x:     AzTheme.px(12)
        blur:         AzTheme.px(35)
        color:        AzTheme.panelShadow
    }

    AzGradientRect {
        id:            panelBackground
        anchors.fill:  parent
        angle:         AzTheme.panelGradientAngle
        startColor:    AzTheme.panelGradientStart
        startPosition: AzTheme.panelGradientStartPos
        endColor:      AzTheme.panelGradientEnd
        endPosition:   AzTheme.panelGradientEndPos
    }

    Rectangle {
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        width:          1
        color:          AzTheme.panelBorder
    }

    // =========================
    //  Logo: 254x80 at the top left; the collapsed menu keeps only its 80x80 mark
    // =========================
    Item {
        id:     logoArea
        x:      0
        y:      0
        width:  parent.width
        height: AzTheme.px(80)
        clip:   true

        Image {
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            source:                 leftPanel._azV2Root + (isCollapsed ? "logo_mark.svg" : "logo_full.svg")
            width:                  AzTheme.px(isCollapsed ? 80 : 254)
            height:                 AzTheme.px(80)
            sourceSize.width:       width
            sourceSize.height:      height
            fillMode:               Image.PreserveAspectFit
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    isCollapsed = !isCollapsed
        }
    }

    // =========================
    //  Menu: 60 px rows, 10 px apart, starting 100 px from the top
    // =========================
    QGCFlickable {
        id:                   menuFlick
        anchors.top:          parent.top
        anchors.topMargin:    AzTheme.px(100)
        anchors.left:         parent.left
        anchors.right:        parent.right
        anchors.bottom:       bottomArea.top
        anchors.bottomMargin: leftPanel._itemMargin
        clip:                 true
        contentWidth:         width
        contentHeight:        menuColumn.height

        Column {
            id:      menuColumn
            x:       leftPanel._itemMargin
            width:   menuFlick.width - (2 * leftPanel._itemMargin)
            spacing: leftPanel._itemMargin

            // NOTE: `pageId` is the stable, never translated key used for dispatch.
            //       Never branch on `text` - it changes with the UI language.
            //       iconW/iconH are the icons' sizes in the design, not all are square.
            ListModel {
                id: mainMenuModel
                ListElement { pageId: "home";     icon: "menu_home.svg";         iconW: 26; iconH: 26; text: qsTr("Ana Səhifə") }
                ListElement { pageId: "flyPanel"; icon: "menu_flight.svg";       iconW: 26; iconH: 26; text: qsTr("Uçuş Paneli") }
                ListElement { pageId: "multiVeh"; icon: "menu_multivehicle.svg"; iconW: 28; iconH: 24; text: qsTr("Multi Vehicle") }
                ListElement { pageId: "plan";     icon: "menu_mission.svg";      iconW: 26; iconH: 29; text: qsTr("Missiya Planlayıcısı") }
                ListElement { pageId: "setup";    icon: "menu_setup.svg";        iconW: 26; iconH: 23; text: qsTr("Aparat Qurğusu") }
                ListElement { pageId: "logs";     icon: "menu_logs.svg";         iconW: 26; iconH: 26; text: qsTr("Qeyd Analizi") }
                ListElement { pageId: "settings"; icon: "menu_settings.svg";     iconW: 26; iconH: 26; text: qsTr("Tənzimləmələr") }
            }

            Repeater {
                model: mainMenuModel

                delegate: Item {
                    id:     menuItem
                    width:  menuColumn.width
                    height: leftPanel._itemHeight

                    readonly property bool selected: leftPanel.selectedPageId === model.pageId

                    // linear-gradient(180deg, #30353A, #202428), 1 px #5D646B, radius 8
                    Rectangle {
                        anchors.fill: parent
                        visible:      menuItem.selected || itemMouse.pressed
                        radius:       AzTheme.px(AzTheme.menuSelectedRadius)
                        border.width: 1
                        border.color: AzTheme.menuSelectedBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                            GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
                        }
                    }

                    // Hover is not in the design: a faint outline of the selected box.
                    Rectangle {
                        anchors.fill: parent
                        visible:      !menuItem.selected && itemMouse.containsMouse && !itemMouse.pressed
                        radius:       AzTheme.px(AzTheme.menuSelectedRadius)
                        color:        Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: AzTheme.panelBorder
                    }

                    Item {
                        id:     iconBox
                        width:  leftPanel._iconBox
                        height: leftPanel._iconBox

                        Image {
                            anchors.centerIn:  parent
                            source:            leftPanel._azV2Root + model.icon
                            width:             AzTheme.px(model.iconW)
                            height:            AzTheme.px(model.iconH)
                            sourceSize.width:  width
                            sourceSize.height: height

                            // filter: drop-shadow(0 0 13.64px rgba(214, 230, 242, 0.18))
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled:          true
                                shadowColor:            AzTheme.menuIconGlow
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset:   0
                                blurMax:                AzTheme.px(14)
                                shadowBlur:             1.0
                            }
                        }
                    }

                    Text {
                        anchors.left:           iconBox.right
                        anchors.leftMargin:     leftPanel._itemMargin
                        anchors.right:          parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible:                !isCollapsed
                        text:                   model.text
                        color:                  AzTheme.textPrimary
                        font.family:            AzTheme.fontFamily
                        font.pixelSize:         AzTheme.fontPx(18)
                        elide:                  Text.ElideRight
                    }

                    MouseArea {
                        id:           itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    leftPanel._activate(model.pageId)
                    }

                    ToolTip.visible: isCollapsed && itemMouse.containsMouse
                    ToolTip.text:    model.text
                    ToolTip.delay:   400
                }
            }
        }
    }

    // =========================
    //  BOTTOM AREA: Manual + Disconnect (always bottom)
    // =========================
    Column {
        id:                   bottomArea
        anchors.left:         parent.left
        anchors.right:        parent.right
        anchors.bottom:       parent.bottom
        anchors.leftMargin:   leftPanel._itemMargin
        anchors.rightMargin:  leftPanel._itemMargin
        anchors.bottomMargin: AzTheme.px(20)
        spacing:              leftPanel._itemMargin
        clip:                 true

        ActionButton {
            width:      bottomArea.width
            collapsed:  leftPanel.isCollapsed
            iconSource: leftPanel._azIconRoot + "manual.svg"
            label:      leftPanel.manualConnectionText
            labelColor: leftPanel.manualConnectionText === qsTr("Manual Bağlandı") ? "orange" : AzTheme.textCard
            onClicked: {
                leftPanel.isManualConnected = true
                if (mainWindow.showConnectionList) mainWindow.showConnectionList()
            }
        }

        ActionButton {
            width:      bottomArea.width
            collapsed:  leftPanel.isCollapsed
            iconSource: leftPanel._azIconRoot + "disconnect.svg"
            label:      leftPanel.disconnectButtonText
            enabled:    leftPanel._communicationLost
            onClicked:  leftPanel.disconnectVehicle()
        }
    }
}

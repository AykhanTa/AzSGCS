import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl

import QGroundControl.Controls
import QGroundControl.FactControls
//import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap

ApplicationWindow {
    id: mainWindow

    // Başlanğıcda pəncərəni gizlədirik ki, splash screen görünsün
    visible: false

    // ❗Responsivlik üçün Screen.width/height binding-i SİLİNDİ (SavedState/resize pozulmasın)
    width:  ScreenTools.defaultFontPixelWidth  * 140
    height: ScreenTools.defaultFontPixelHeight * 80
    minimumWidth:  ScreenTools.defaultFontPixelWidth  * 90
    minimumHeight: ScreenTools.defaultFontPixelHeight * 55

//     // --- SPLASH SCREEN KODU BAŞLANĞICI ---
    Rectangle {
        id: splashScreen
        anchors.fill: parent
        color: "black"
        z: 9999

        Image {
            id: splashImage
            source: "qrc:/res/AZSHIELD_ICON/main_logo.svg"
            anchors.centerIn: parent
            width: 0
            height: 0
            fillMode: Image.PreserveAspectFit
            opacity: 0
            visible: true
        }

        SequentialAnimation {
            id: splashAnimation
            ScriptAction { script: splashImage.opacity = 1 }

            ParallelAnimation {
                PropertyAnimation {
                    target: splashImage
                    property: "width"
                    to: Screen.width * 0.5
                    duration: 2500
                    easing.type: Easing.OutCubic
                }
                PropertyAnimation {
                    target: splashImage
                    property: "height"
                    to: Screen.height * 0.5
                    duration: 2500
                    easing.type: Easing.OutCubic
                }
            }

            PauseAnimation { duration: 500 }

            ScriptAction {
                script: {
                    splashScreen.visible = false
                    Qt.callLater(function() {
                        mainWindow.showFullScreen()
                        mainWindow.visible = true
                    })
                    firstRunPromptManager.nextPrompt()
                }
            }
        }

        Component.onCompleted: {
            splashAnimation.start()
        }
    }
    // --- SPLASH SCREEN KODU SONU ---

    Component.onCompleted: {
        // Mobil ekranda fullscreen daha məntiqlidir
        if (ScreenTools.isMobile) {
            mainWindow.showFullScreen()
        }
        mainWindow.visible = true

        // Dar pəncərədə SideMenu avtomatik collapse (dock qalır, overlay etmirik ki UI bloklanmasın)
        Qt.callLater(_applyResponsiveMenuState)
    }

    // ===================== RESPONSIVE LAYOUT SKELETON =====================
    // readonly property bool _isNarrow: mainWindow.width < ScreenTools.defaultFontPixelWidth * 120
    // readonly property bool _overlayMenu: ScreenTools.isMobile
    // readonly property bool _autoCollapseMenu: !_overlayMenu && _isNarrow

    // === AzShield: GOTO target paylaşımı ===
    property bool azGoToActive: false
    property var  azGoToCoordinate: undefined   // QtPositioning.coordinate(...)
    property real azGoToBearingDeg: NaN         // istəsən koordinatsız da işləsin

    readonly property bool _isNarrow: mainWindow.width < ScreenTools.defaultFontPixelWidth * 120

    // ✅ Yalnız dar telefonda overlay, G20 kimi böyük ekranda dock
    readonly property bool _overlayMenu: ScreenTools.isMobile && _isNarrow

    readonly property bool _autoCollapseMenu: !_overlayMenu && _isNarrow

    // SideMenu docked olanda content soldan inset alır, overlay olanda 0
    //readonly property real _leftInset: (leftPanel && leftPanel.visible && !_overlayMenu) ? leftPanel.width : 0
    readonly property real _leftInset: (leftPanel && leftPanel.visible) ? leftPanel.width : 0

    // TopStatusPanel görünəndə content yuxarıdan inset alır
    readonly property real _topInset: (customStatusPanel && customStatusPanel.visible) ? customStatusPanel.height : 0

    readonly property real _qgcInternalToolbarH: ScreenTools.toolbarHeight

    function _applyResponsiveMenuState() {
        if (!leftPanel) return
        if (_autoCollapseMenu && leftPanel.visible) {
            // ✅ width-ə toxunma, yalnız state dəyiş
            leftPanel.isCollapsed = true
        }
    }

    onWidthChanged: Qt.callLater(_applyResponsiveMenuState)

    Item {
        id: viewsClip
        anchors.fill: contentArea
        clip: true
    }

    // Content area: FlyView/PlanView buraya düşür (TopStatus + SideMenu margin hesabı avtomatik)
    Item {
        id: contentArea
        anchors.fill: parent
        anchors.leftMargin: mainWindow._leftInset
        anchors.topMargin:  mainWindow._topInset
    }
    // ===================== /RESPONSIVE LAYOUT SKELETON =====================

    MainWindowSavedState {
        window: mainWindow
    }

    QtObject {
        id: firstRunPromptManager

        property var currentDialog:        null
        property var rgPromptIds:          QGroundControl.corePlugin.firstRunPromptsToShow()
        property int nextPromptIdIndex: 0

        function clearNextPromptSignal() {
            if (currentDialog) {
                currentDialog.closed.disconnect(nextPrompt)
            }
        }

        function nextPrompt() {
            if (nextPromptIdIndex < rgPromptIds.length) {
                var component = Qt.createComponent(QGroundControl.corePlugin.firstRunPromptResource(rgPromptIds[nextPromptIdIndex]));
                currentDialog = component.createObject(mainWindow)
                currentDialog.closed.connect(nextPrompt)
                currentDialog.open()
                nextPromptIdIndex++
            } else {
                currentDialog = null
                showPreFlightChecklistIfNeeded()
            }
        }
    }

    property bool showFlightPanel: false
    property bool isFlyViewActive: false
    property bool showMultiVehiclePanel: true

    property var bottomCenterPanelStates: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    readonly property real _topBottomMargins: ScreenTools.defaultFontPixelHeight * 0.5

    //-------------------------------------------------------------------------
    //-- Global Scope Variables

    QtObject {
        id: globals

        readonly property var     activeVehicle:               QGroundControl.multiVehicleManager.activeVehicle
        readonly property real    defaultTextHeight:           ScreenTools.defaultFontPixelHeight
        readonly property real    defaultTextWidth:            ScreenTools.defaultFontPixelWidth
        readonly property var     planMasterControllerFlyView: flyView.planController
        readonly property var     guidedControllerFlyView:     flyView.guidedController

        property int  validationErrorCount:    0
        property bool commingFromRIDIndicator: false
    }

    /// Default color palette used throughout the UI
    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    //-------------------------------------------------------------------------
    //-- Actions

    signal armVehicleRequest
    signal forceArmVehicleRequest
    signal disarmVehicleRequest
    signal vtolTransitionToFwdFlightRequest
    signal vtolTransitionToMRFlightRequest
    signal showPreFlightChecklistIfNeeded

    //-------------------------------------------------------------------------
    //-- Global Scope Functions

    function allowViewSwitch(previousValidationErrorCount = 0) {
        if (mainWindow.activeFocusControl instanceof FactTextField) {
            mainWindow.activeFocusControl._onEditingFinished()
        }
        return globals.validationErrorCount <= previousValidationErrorCount
    }

    function showPlanView() {
        flyView.visible = false
        planView.visible = true
    }

    function closePlanView() {
        flyView.visible = false
        planView.visible = false
    }

    function showFlyView() {
        flyView.visible = true
        planView.visible = false
        customStatusPanel.visible = true
        leftPanel.visible = true
        Qt.callLater(_applyResponsiveMenuState)
    }

    function showTool(toolTitle, toolSource, toolIcon) {
        toolDrawer.backIcon   = flyView.visible ? "/qmlimages/PaperPlane.svg" : "/qmlimages/Plan.svg"
        toolDrawer.toolTitle  = toolTitle
        toolDrawer.toolSource = toolSource
        toolDrawer.toolIcon   = toolIcon
        toolDrawer.visible    = true
    }

    function showAnalyzeTool() {
        showTool(qsTr("Analyze Tools"), "qrc:/qml/QGroundControl/AnalyzeView/AnalyzeView.qml", "/qmlimages/Analyze.svg")
    }

    function showVehicleConfig(userInitiated = false) {
        if (!userInitiated) {
            return
        }
        showTool(qsTr("Vehicle Configuration"), "qrc:/qml/QGroundControl/VehicleSetup/SetupView.qml", "/qmlimages/Gears.svg")
    }

    function showVehicleConfigParametersPage() {
        showVehicleConfig(true)
        toolDrawerLoader.item.showParametersPanel()
    }

    /// Aparat Qurğusu overlay-ini açıb istənilən sol menyu bəndini seçir.
    /// (SideMenu_AparatQurgusu.qml-dəki `idx` dəyərləri: 0 Xülasə, 1 Frame, 2 Radio,
    ///  3 Joystick, 4 Uçuş Rejimləri, 5 Uçuşa Hazırlıq, 6 Enerji, 7 Aktuatorlar ...)
    function showVehicleSetupPage(menuIdx) {
        hideToolDrawer()
        sideMenuLoader.source = "qrc:/qml/QGroundControl/UI/SideMenu_AparatQurgusu.qml"
        Qt.callLater(function() {
            if (sideMenuLoader.item && sideMenuLoader.item.openMenuByIdx) {
                sideMenuLoader.item.openMenuByIdx(menuIdx)
            }
        })
    }

    function showKnownVehicleComponentConfigPage(knownVehicleComponent) {
        showVehicleConfig(true)
        let vehicleComponent = globals.activeVehicle.autopilotPlugin.findKnownVehicleComponent(knownVehicleComponent)
        if (vehicleComponent) {
            toolDrawerLoader.item.showVehicleComponentPanel(vehicleComponent)
        }
    }

    function showVehicleComponentDialog(vehicle, componentName, paramName) {
        //console.log("showVehicleComponentDialog:", componentName, paramName)

        if (componentName === "ParametersComponent") {
            showVehicleConfigParametersPage()
            return
        }

        showKnownVehicleComponentConfigPage(componentName)
    }

    function showSettingsTool(settingsPage = "") {
        showTool(qsTr("Application Settings"), "qrc:/qml/QGroundControl/Controls/AppSettings.qml", "/res/QGCLogoWhite")
        if (settingsPage !== "") {
            toolDrawerLoader.item.showSettingsPage(settingsPage)
        }
    }

    // ✅ əvvəldə undefined id-lərə referans verirdi; indi təhlükəsiz şəkildə settingsLoader istifadə edir
    function showTopStatusPanel(title, qmlSource, iconSource = "") {
        settingsLoader.source = qmlSource
        Qt.callLater(function() {
            if (settingsLoader.item) {
                if (settingsLoader.item.hasOwnProperty("title")) {
                    settingsLoader.item.title = title
                }
                if (iconSource !== "" && settingsLoader.item.hasOwnProperty("iconSource")) {
                    settingsLoader.item.iconSource = iconSource
                }
            }
        })
    }

    function hideToolDrawer() {
        if (toolDrawer.visible) {
            toolDrawer.visible = false
            toolDrawerLoader.source = ""
        }
    }

    function hideTopStatusPanel() {
        customStatusPanel.visible = false
    }

    //-------------------------------------------------------------------------
    //-- Global simple message dialog

    function showMessageDialog(dialogTitle, dialogText, buttons = Dialog.Ok, acceptFunction = null, closeFunction = null) {
        simpleMessageDialogComponent.createObject(mainWindow, {
            title: dialogTitle, text: dialogText, buttons: buttons,
            acceptFunction: acceptFunction, closeFunction: closeFunction
        }).open()
    }

    function _showMessageDialog(dialogTitle, dialogText) {
        showMessageDialog(dialogTitle, dialogText)
    }

    Component {
        id: simpleMessageDialogComponent
        QGCSimpleMessageDialog { }
    }

    property bool _forceClose: false

    function finishCloseProcess() {
        _forceClose = true
        firstRunPromptManager.clearNextPromptSignal()
        QGroundControl.linkManager.shutdown()
        QGroundControl.videoManager.stopVideo()
        mainWindow.close()
    }

    readonly property int _skipUnsavedMissionCheckMask:          0x01
    readonly property int _skipPendingParameterWritesCheckMask:  0x02
    readonly property int _skipActiveConnectionsCheckMask:       0x04
    property int _closeChecksToSkip: 0

    function performCloseChecks() {
        if (!(_closeChecksToSkip & _skipUnsavedMissionCheckMask) && !checkForUnsavedMission()) {
            return false
        }
        if (!(_closeChecksToSkip & _skipPendingParameterWritesCheckMask) && !checkForPendingParameterWrites()) {
            return false
        }
        if (!(_closeChecksToSkip & _skipActiveConnectionsCheckMask) && !checkForActiveConnections()) {
            return false
        }
        finishCloseProcess()
        return true
    }

    property string customAppName: qsTr("AZSHIELD")
    property string closeDialogTitle: qsTr(customAppName)

    function checkForUnsavedMission() {
        if (planView._planMasterController.dirty) {
            showMessageDialog(closeDialogTitle,
                              qsTr("Sizdə yadda saxlanılmayan göndərilməyən missiya redaktəsi davam edir. Bağlasanız dəyişiklikləri itirəcəksiniz. Bağlamaq istədiyinizə əminsiniz?"),
                              Dialog.Yes | Dialog.No,
                              function() { _closeChecksToSkip |= _skipUnsavedMissionCheckMask; performCloseChecks() })
            return false
        } else {
            return true
        }
    }

    function checkForPendingParameterWrites() {
        for (var index = 0; index < QGroundControl.multiVehicleManager.vehicles.count; index++) {
            if (QGroundControl.multiVehicleManager.vehicles.get(index).parameterManager.pendingWrites) {
                mainWindow.showMessageDialog(closeDialogTitle,
                    qsTr("Bir təyyarə üçün gözlənilən parametr yenilənmələriniz var. Bağlasanız dəyişiklikləri itirəcəksiniz. Bağlamaq istədiyinizə əminsiniz?"),
                    Dialog.Yes | Dialog.No,
                    function() { _closeChecksToSkip |= _skipPendingParameterWritesCheckMask; performCloseChecks() })
                return false
            }
        }
        return true
    }

    function checkForActiveConnections() {
        if (QGroundControl.multiVehicleManager.activeVehicle) {
            mainWindow.showMessageDialog(closeDialogTitle,
                qsTr("Hələ də təyyarə ilə əlaqə var. Çıxmaq istədiyinizə əminsiniz?"),
                Dialog.Yes | Dialog.No,
                function() { _closeChecksToSkip |= _skipActiveConnectionsCheckMask; performCloseChecks() })
            return false
        } else {
            return true
        }
    }

    onClosing: (close) => {
        if (!_forceClose) {
            _closeChecksToSkip = 0
            close.accepted = performCloseChecks()
        }
    }

    background: Rectangle {
        anchors.fill: parent
        color: QGroundControl.globalPalette.window
    }

    FlyView {
        id: flyView
        parent: viewsClip

        x: 0
        y: -mainWindow._qgcInternalToolbarH
        width:  viewsClip.width
        height: viewsClip.height + mainWindow._qgcInternalToolbarH

        visible: true
    }

    // PlanView: eyni metod
    PlanView {
        id: planView
        parent: viewsClip

        x: 0
        y: -mainWindow._qgcInternalToolbarH
        width:  viewsClip.width
        height: viewsClip.height + mainWindow._qgcInternalToolbarH

        visible: false
    }

    // ===================== /MAIN VIEWS =====================

    // SideMenu (dock/auto-collapse)
    SideMenu {
        id: leftPanel
        z: 70
    }

    TopStatusPanel {
        id: customStatusPanel
        z: 60

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: parent.left

        // ✅ SideMenu bitən yerdən başlasın
        anchors.leftMargin: mainWindow._leftInset
        // Behavior on anchors.leftMargin { NumberAnimation { duration: 160 } }

        onExitRequested: {
            mainWindow._closeChecksToSkip = 0
            mainWindow.close()
        }

        onMinimizeRequested: {
            mainWindow.showMinimized()
        }
    }

    // Overlay Loaders (contentArea mərkəzinə bağlandı, offset-lər responsiv)
    Loader {
        id: settingsLoader
        z: 200
        anchors.fill: parent
        anchors.verticalCenterOffset: -Math.min(contentArea.height * 0.25, ScreenTools.defaultFontPixelHeight * 18)
        anchors.horizontalCenterOffset: Math.min(contentArea.width * 0.10, ScreenTools.defaultFontPixelWidth * 12)
    }

    // ======= FULLSCREEN OVERLAY (SideMenu_AparatQurgusu, Tenzimlemeler və s.) =======

    Loader {
        id: sideMenuLoader
        anchors.fill: parent
        z: 10001
        source: ""   // vacib: default boş olsun
    }

    readonly property bool overlayOpen: sideMenuLoader.source.toString().length > 0

    Rectangle {
        id: overlayLayer
        anchors.fill: parent
        z: 10000
        visible: overlayOpen
        color: "black"
        opacity: 1.0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onWheel: (wheel) => { wheel.accepted = true }
            onPressed: (mouse) => { mouse.accepted = true }
        }
    }

    // Overlay açılıb bağlananda əsas SideMenu/Status davranışı
    onOverlayOpenChanged: {
        leftPanel.visible = !overlayOpen
        // customStatusPanel.visible = !overlayOpen && flyView.visible
    }

    // Loader statusuna nəzarət: ERROR olarsa qara ekran qalmasın
    Connections {
        target: sideMenuLoader
        function onStatusChanged() {
            if (sideMenuLoader.status === Loader.Error) {
                //console.log("❌ sideMenuLoader ERROR:", sideMenuLoader.errorString)
                sideMenuLoader.source = ""
            }
        }
    }

    BottomCenterStatusPanel {
        id: bottomCenterStatusPanel
        z: 85

        width: Math.min(500, contentArea.width - 24)

        anchors.horizontalCenter: contentArea.horizontalCenter
        anchors.bottom: contentArea.bottom
       // anchors.bottomMargin: Math.max(12, ScreenTools.defaultFontPixelHeight * 1.1)

        anchors.bottomMargin: 4

        visible: flyView.visible && !planView.visible && !overlayOpen && !toolDrawer.visible

        panelTitle: qsTr("Mərmi")
        statusStates: mainWindow.bottomCenterPanelStates
    }

    MessageDialog {
        id: showTouchAreasNotification
        title: qsTr("Debug Touch Areas")
        text: qsTr("Touch Area display toggled")
        buttons: MessageDialog.Ok
    }

    MessageDialog {
        id: advancedModeOnConfirmation
        title: qsTr("Advanced Mode")
        text: QGroundControl.corePlugin.showAdvancedUIMessage
        buttons: MessageDialog.Yes | MessageDialog.No
        onButtonClicked: function (button, role) {
            if (button === MessageDialog.Yes) {
                QGroundControl.corePlugin.showAdvancedUI = true
            }
        }
    }

    MessageDialog {
        id: advancedModeOffConfirmation
        title: qsTr("Advanced Mode")
        text: qsTr("Turn off Advanced Mode?")
        buttons: MessageDialog.Yes | MessageDialog.No
        onButtonClicked: function (button, role) {
            if (button === MessageDialog.Yes) {
                QGroundControl.corePlugin.showAdvancedUI = false
            }
        }
    }

    function showToolSelectDialog() {
        if (mainWindow.allowViewSwitch()) {
            mainWindow.showIndicatorDrawer(toolSelectComponent, null)
        }
    }

    Component {
        id: toolSelectComponent

        ToolIndicatorPage {
            id: toolSelectDialog

            property real _toolButtonHeight: ScreenTools.defaultFontPixelHeight * 3
            property real _margins: ScreenTools.defaultFontPixelWidth

            contentComponent: Component {
                ColumnLayout {
                    width:  innerLayout.width + (toolSelectDialog._margins * 2)
                    height: innerLayout.height + (toolSelectDialog._margins * 2)

                    ColumnLayout {
                        id: innerLayout
                        Layout.margins: toolSelectDialog._margins
                        spacing: ScreenTools.defaultFontPixelWidth

                        SubMenuButton {
                            height: toolSelectDialog._toolButtonHeight
                            Layout.fillWidth: true
                            text: qsTr("Plan Flight")
                            imageResource: "/qmlimages/Plan.svg"
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showPlanView()
                                }
                            }
                        }

                        SubMenuButton {
                            id: analyzeButton
                            height: toolSelectDialog._toolButtonHeight
                            Layout.fillWidth: true
                            text: qsTr("Analyze Tools")
                            imageResource: "/qmlimages/Analyze.svg"
                            visible: QGroundControl.corePlugin.showAdvancedUI
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showAnalyzeTool()
                                }
                            }
                        }

                        SubMenuButton {
                            id: setupButton
                            height: toolSelectDialog._toolButtonHeight
                            Layout.fillWidth: true
                            text: qsTr("Vehicle Configuration")
                            imageResource: "/qmlimages/Gears.svg"
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showVehicleConfig(true)
                                }
                            }
                        }

                        SubMenuButton {
                            id: settingsButton
                            height: toolSelectDialog._toolButtonHeight
                            Layout.fillWidth: true
                            text: qsTr("Application Settings")
                            imageResource: "/res/QGCLogoFull.svg"
                            imageColor: "transparent"
                            visible: !QGroundControl.corePlugin.options.combineSettingsAndSetup
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    drawer.close()
                                    mainWindow.showSettingsTool()
                                }
                            }
                        }

                        SubMenuButton {
                            id: closeButton
                            height: toolSelectDialog._toolButtonHeight
                            Layout.fillWidth: true
                            text: qsTr("Bagla %1").arg(customAppName)
                            imageResource: "/res/cancel.svg"
                            visible: mainWindow.visibility === Window.FullScreen
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.finishCloseProcess()
                                }
                            }
                        }

                        ColumnLayout {
                            width: innerLayout.width
                            spacing: 0
                            Layout.alignment: Qt.AlignHCenter

                            QGCLabel {
                                id: versionLabel
                                text: qsTr("%1 Version").arg(customAppName)
                                font.pointSize: ScreenTools.smallFontPointSize
                                wrapMode: QGCLabel.WordWrap
                                Layout.maximumWidth: parent.width
                                Layout.alignment: Qt.AlignHCenter
                            }

                            QGCLabel {
                                text: QGroundControl.qgcVersion
                                font.pointSize: ScreenTools.smallFontPointSize
                                wrapMode: QGCLabel.WrapAnywhere
                                Layout.maximumWidth: parent.width
                                Layout.alignment: Qt.AlignHCenter

                                QGCMouseArea {
                                    id: easterEggMouseArea
                                    anchors.topMargin: -versionLabel.height
                                    anchors.fill: parent

                                    onClicked: (mouse) => {
                                        if (mouse.modifiers & Qt.ControlModifier) {
                                            QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                            showTouchAreasNotification.open()
                                        } else if (ScreenTools.isMobile || mouse.modifiers & Qt.ShiftModifier) {
                                            mainWindow.closeIndicatorDrawer()
                                            if(!QGroundControl.corePlugin.showAdvancedUI) {
                                                advancedModeOnConfirmation.open()
                                            } else {
                                                advancedModeOffConfirmation.open()
                                            }
                                        }
                                    }

                                    onPressAndHold: {
                                        QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                        showTouchAreasNotification.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------------------------------- manual baglan

    Popup {
        id: connectionListPopup

        readonly property real _rowHeight: Math.max(50, ScreenTools.defaultFontPixelHeight * 3.1)
        readonly property real _targetPopupWidth: ScreenTools.isMobile ? mainWindow.width * 0.92 : mainWindow.width * 0.56
        readonly property real _targetPopupHeight: ScreenTools.isMobile
                                                   ? mainWindow.height * 0.84
                                                   : (_rowHeight * Math.max(1, Math.min(_visibleManualConnectionCount(), 6))
                                                      + ScreenTools.defaultFontPixelHeight * 6.5)

        function _visibleManualConnectionCount() {
            if (!_linkManager || !_linkManager.linkConfigurations) {
                return 0
            }

            var count = 0
            for (var i = 0; i < _linkManager.linkConfigurations.count; i++) {
                var cfg = _linkManager.linkConfigurations.get(i)
                if (cfg && cfg.name && cfg.name.toLowerCase().indexOf("udp") === -1) {
                    count++
                }
            }
            return count
        }

        width: Math.min(mainWindow.width * 0.96,
                        Math.max(ScreenTools.defaultFontPixelWidth * 42,
                                 Math.min(_targetPopupWidth,
                                          ScreenTools.defaultFontPixelWidth * 78)))

        height: Math.min(mainWindow.height * 0.90,
                         Math.max(ScreenTools.defaultFontPixelHeight * 14,
                                  Math.min(_targetPopupHeight,
                                           ScreenTools.defaultFontPixelHeight * 42)))

        x: Math.round((mainWindow.width - width) * 0.5)
        y: Math.round((mainWindow.height - height) * 0.5)

        modal: true
        focus: true
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#3D3B3B"
            radius: 8
            border.color: "#FFFFFF"
            border.width: 2
        }

        property var _autoConnectSettings: QGroundControl.settingsManager.autoConnectSettings
        property bool _udpAutoConnectState: _autoConnectSettings ? _autoConnectSettings.autoConnectUDP.value : false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            QGCLabel {
                text: qsTr("Əlaqəni Seçin")
                color: "white"
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#2A2A2A"
                radius: 6

                ListView {
                    id: connectionListView
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds

                    model: _linkManager ? _linkManager.linkConfigurations : []

                    delegate: Rectangle {
                        id: delegateItem
                        width: connectionListView.width
                        color: "transparent"

                        property string linkName: object && object.name ? object.name.toLowerCase() : ""
                        property bool _isUdpLink: linkName.indexOf("udp") !== -1
                        property bool isConnected: object && object.link ? true : false

                        visible: !_isUdpLink
                        height: _isUdpLink ? 0 : connectionListPopup._rowHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: delegateItem._isUdpLink ? 0 : 2
                            visible: !delegateItem._isUdpLink
                            color: index % 2 === 0 ? "#3D3B3B" : "#2A2A2A"
                            radius: 4

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                QGCLabel {
                                    Layout.fillWidth: true
                                    text: object.name
                                    color: "white"
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                QGCLabel {
                                    id: statusLabel
                                    text: delegateItem.isConnected ? qsTr("Əlaqə qurulub") : qsTr("Əlaqə qurulmayıb")
                                    color: delegateItem.isConnected ? "#4CAF50" : "#F44336"
                                    font.pixelSize: 12
                                }

                                Rectangle {
                                    id: connectButton
                                    width: 90
                                    height: 30
                                    radius: 4
                                    color: delegateItem.isConnected ? "#F44336" : "#4CAF50"
                                    border.color: "#FFFFFF"
                                    border.width: 1

                                    QGCLabel {
                                        id: connectButtonLabel
                                        anchors.centerIn: parent
                                        text: delegateItem.isConnected ? qsTr("Əlaqəni kəs") : qsTr("Əlaqəni qur")
                                        color: "white"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    QGCMouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            //console.log("Butona tıklandı - Mevcut durum:", delegateItem.isConnected, "Bağlantı adı:", object.name)

                                            if (autoConnectBlocker.running) {
                                                //console.log("AutoConnect blok aktif, işlem engellendi")
                                                return
                                            }

                                            if (delegateItem.isConnected) {
                                                //console.log("Bağlantı kesiliyor...")

                                                _handleDisconnectWithAutoConnect(object)

                                                if (object.link) {
                                                    object.link.disconnect()
                                                }

                                                delegateItem.isConnected = false
                                                //console.log("Əlaqə kəsildi:", object.name)
                                            } else {
                                                //console.log("Bağlantı kuruluyor...")

                                                _handleConnectWithAutoConnect(object)
                                                _linkManager.createConnectedLink(object)

                                                delegateItem.isConnected = true
                                                //console.log("Əlaqə quruldu:", object.name)

                                                connectionListPopup.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 10
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    id: configButton
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 35
                    radius: 6
                    color: "#666666"
                    border.color: "#FFFFFF"
                    border.width: 1

                    QGCLabel {
                        anchors.centerIn: parent
                        text: qsTr("Konfiqurasiya")
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    QGCMouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            connectionListPopup.close()

                            if (leftPanel) {
                                leftPanel.visible = false
                            }

                            // ✅ Tənzimləmələr overlay-ini aç və "Rabitə Kanalları"na (index 6) keç
                            sideMenuLoader.setSource(Qt.resolvedUrl("Tenzimlemeler.qml"), { startIndex: 6 })
                        }
                    }
                }

                Rectangle {
                    id: closeButton2
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 35
                    radius: 6
                    color: "#F44336"
                    border.color: "#FFFFFF"
                    border.width: 1

                    QGCLabel {
                        anchors.centerIn: parent
                        text: qsTr("Bağla")
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    QGCMouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            connectionListPopup.close()
                        }
                    }
                }
            }
        }

        Connections {
            target: connectionListPopup._autoConnectSettings ? connectionListPopup._autoConnectSettings.autoConnectUDP : null
            function onValueChanged() {
               //console.log("MainWindow: AutoConnect UDP değişti:", connectionListPopup._autoConnectSettings.autoConnectUDP.value)
                connectionListPopup._udpAutoConnectState = connectionListPopup._autoConnectSettings.autoConnectUDP.value

                if (connectionListPopup._autoConnectSettings.autoConnectUDP.value) {
                    //console.log("AutoConnect UDP aktif, bağlantılar kontrol ediliyor...")
                    _checkAndConnectUDPLinks()
                }
            }
        }

        function _checkAndConnectUDPLinks() {
            if (!_linkManager) return

            for (var i = 0; i < _linkManager.linkConfigurations.count; i++) {
                var linkConfig = _linkManager.linkConfigurations.get(i)
                var linkName = linkConfig.name.toLowerCase()

                if (linkName.includes("udp") && !linkConfig.link) {
                    //console.log("UDP bağlantısı bulundu, bağlanıyor:", linkConfig.name)
                    _linkManager.createConnectedLink(linkConfig)
                    break
                }
            }
        }

        // LinkManager-də "linkConnected/linkDisconnected" siqnalları yoxdur
        // (connect/disconnect siqnalları ayrı-ayrı LinkInterface obyektlərindədir).
        // Köhnə Connections heç vaxt işləməyirdi və konsolda warning verirdi.
        // Eyni niyyət (siyahını yeniləmək / UDP AutoConnect) işlək
        // multiVehicleManager.activeVehicleChanged siqnalı ilə təmin olunur.
        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(vehicle) {
                if (vehicle && vehicle.link && vehicle.link.linkConfiguration) {
                    var linkName = vehicle.link.linkConfiguration.name.toLowerCase()
                    if (linkName.includes("udp")
                            && connectionListPopup._autoConnectSettings
                            && connectionListPopup._autoConnectSettings.autoConnectUDP) {
                        connectionListPopup._autoConnectSettings.autoConnectUDP.value = true
                    }
                }

                connectionListView.model = []
                connectionListView.model = _linkManager ? _linkManager.linkConfigurations : []
            }
        }

        Timer {
            id: autoConnectBlocker
            interval: 2000
            running: false
            repeat: false
            //onTriggered: //console.log("AutoConnect blok kalktı")
        }
    }

    function showConnectionList() {
        //console.log("Əlaqə siyahısı açılır...")
        connectionListPopup.open()
    }

    function _handleConnectWithAutoConnect(linkConfig) {
        var linkName = linkConfig.name.toLowerCase()
        //console.log("Bağlantı kuruluyor, AutoConnect kontrolü:", linkName)

        if (!linkConfig) {
            //console.log("LinkConfig nesnesi bulunamadı, işlem iptal edildi")
            return
        }

        autoConnectBlocker.restart()

        if (linkName.includes("udp")) {
            if (QGroundControl.settingsManager && QGroundControl.settingsManager.autoConnectSettings) {
                QGroundControl.settingsManager.autoConnectSettings.autoConnectUDP.value = true
                //console.log("UDP bağlantısı kuruluyor, AutoConnect AKTİF edildi")
            }
        }

        if (linkName.includes("serial") || linkName.includes("com")) {
            if (QGroundControl.settingsManager && QGroundControl.settingsManager.autoConnectSettings) {
                QGroundControl.settingsManager.autoConnectSettings.autoConnectPixhawk.value = true
                //console.log("Serial bağlantısı kuruluyor, AutoConnect AKTİF edildi")
            }
        }
    }

    function _handleDisconnectWithAutoConnect(linkConfig) {
        var linkName = linkConfig.name.toLowerCase()
        //console.log("Bağlantı kesiliyor, AutoConnect kontrolü:", linkName)

        if (!linkConfig) {
            //console.log("LinkConfig nesnesi bulunamadı, işlem iptal edildi")
            return
        }

        autoConnectBlocker.restart()

        if (linkName.includes("udp")) {
            if (QGroundControl.settingsManager && QGroundControl.settingsManager.autoConnectSettings) {
                QGroundControl.settingsManager.autoConnectSettings.autoConnectUDP.value = false
                //console.log("UDP AutoConnect devre dışı bırakıldı")
            }
        }

        if (linkName.includes("serial") || linkName.includes("com")) {
            if (QGroundControl.settingsManager && QGroundControl.settingsManager.autoConnectSettings) {
                QGroundControl.settingsManager.autoConnectSettings.autoConnectPixhawk.value = false
                //console.log("Serial AutoConnect devre dışı bırakıldı")
            }
        }
    }

    property var _linkManager: QGroundControl.linkManager

    //--------------------------------------------------------------------------------------------------- manual baglan

    Rectangle {
        id: toolDrawer
        anchors.fill: parent
        visible: false
        color: qgcPal.window

        property var backIcon
        property string toolTitle
        property alias toolSource: toolDrawerLoader.source
        property var toolIcon

        onVisibleChanged: {
            if (!toolDrawer.visible) {
                toolDrawerLoader.source = ""
            }
        }

        Rectangle {
            id: toolDrawerToolbar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: ScreenTools.toolbarHeight
            color: qgcPal.toolbarBackground

            RowLayout {
                id: toolDrawerToolbarLayout
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    font.pointSize: ScreenTools.largeFontPointSize
                    text: "<"
                }

                QGCLabel {
                    id: toolbarDrawerText
                    text: qsTr("Çıxış") + " " + toolDrawer.toolTitle
                    font.pointSize: ScreenTools.largeFontPointSize
                }
            }

            QGCMouseArea {
                anchors.fill: toolDrawerToolbarLayout
                onClicked: {
                    //console.log("Çıxış butonuna tıklandı - SideMenu aktif ediliyor")

                    if (mainWindow.allowViewSwitch()) {
                        if (leftPanel) {
                            leftPanel.visible = true
                            //console.log("SideMenu aktif edildi")
                            Qt.callLater(_applyResponsiveMenuState)
                        }
                        toolDrawer.visible = false
                    }
                }
            }
        }

        Loader {
            id: toolDrawerLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: toolDrawerToolbar.bottom
            anchors.bottom: parent.bottom

            Connections {
                target: toolDrawerLoader.item
                ignoreUnknownSignals: true
                function onPopout() { toolDrawer.visible = false }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Critical Vehicle Message Popup

    function showCriticalVehicleMessage(message) {
        closeIndicatorDrawer()
        if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
            criticalVehicleMessagePopup.additionalCriticalMessagesReceived = true
        } else {
            criticalVehicleMessagePopup.criticalVehicleMessage = message
            criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false
            criticalVehicleMessagePopup.open()
        }
    }

    Popup {
        id: criticalVehicleMessagePopup
        y: ScreenTools.toolbarHeight + ScreenTools.defaultFontPixelHeight
        x: Math.round((mainWindow.width - width) * 0.5)
        width: mainWindow.width * 0.55
        height: criticalVehicleMessageText.contentHeight + ScreenTools.defaultFontPixelHeight * 2
        modal: false
        focus: true

        property alias criticalVehicleMessage: criticalVehicleMessageText.text
        property bool additionalCriticalMessagesReceived: false

        background: Rectangle {
            anchors.fill: parent
            color: qgcPal.alertBackground
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            border.color: qgcPal.alertBorder
            border.width: 2

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -(height / 2)
                color: qgcPal.alertBackground
                radius: ScreenTools.defaultFontPixelHeight * 0.25
                border.color: qgcPal.alertBorder
                border.width: 1
                width: vehicleWarningLabel.contentWidth + _margins
                height: vehicleWarningLabel.contentHeight + _margins

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id: vehicleWarningLabel
                    anchors.centerIn: parent
                    text: qsTr("Vehicle Error")
                    font.pointSize: ScreenTools.smallFontPointSize
                    color: qgcPal.alertText
                }
            }

            Rectangle {
                id: additionalErrorsIndicator
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -(height / 2)
                color: qgcPal.alertBackground
                radius: ScreenTools.defaultFontPixelHeight * 0.25
                border.color: qgcPal.alertBorder
                border.width: 1
                width: additionalErrorsLabel.contentWidth + _margins
                height: additionalErrorsLabel.contentHeight + _margins
                visible: criticalVehicleMessagePopup.additionalCriticalMessagesReceived

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id: additionalErrorsLabel
                    anchors.centerIn: parent
                    text: qsTr("Additional errors received")
                    font.pointSize: ScreenTools.smallFontPointSize
                    color: qgcPal.alertText
                }
            }
        }

        QGCLabel {
            id: criticalVehicleMessageText
            width: criticalVehicleMessagePopup.width - ScreenTools.defaultFontPixelHeight
            anchors.centerIn: parent
            wrapMode: Text.WordWrap
            color: qgcPal.alertText
            textFormat: TextEdit.RichText
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                criticalVehicleMessagePopup.close()
                if (criticalVehicleMessagePopup.additionalCriticalMessagesReceived) {
                    criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false
                    flyView.dropMainStatusIndicatorTool()
                } else {
                    QGroundControl.multiVehicleManager.activeVehicle.resetErrorLevelMessages()
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Indicator Drawer

    function showIndicatorDrawer(drawerComponent, indicatorItem) {
        indicatorDrawer.sourceComponent = drawerComponent
        indicatorDrawer.indicatorItem = indicatorItem
        indicatorDrawer.open()
    }

    function closeIndicatorDrawer() {
        indicatorDrawer.close()
    }

    Popup {
        id: indicatorDrawer
        x: calcXPosition()
        y: ScreenTools.toolbarHeight + _margins
        leftInset: 0
        rightInset: 0
        topInset: 0
        bottomInset: 0
        padding: _margins * 2
        visible: false
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var sourceComponent
        property var indicatorItem

        property bool _expanded: false
        property real _margins: ScreenTools.defaultFontPixelHeight / 4

        function calcXPosition() {
            if (indicatorItem) {
                var xCenter = indicatorItem.mapToItem(mainWindow.contentItem, indicatorItem.width / 2, 0).x
                return Math.max(_margins,
                                Math.min(xCenter - (contentItem.implicitWidth / 2),
                                         mainWindow.contentItem.width - contentItem.implicitWidth - _margins - (indicatorDrawer.padding * 2) - (ScreenTools.defaultFontPixelHeight / 2)))
            } else {
                return _margins
            }
        }

        onOpened: {
            _expanded = false
            indicatorDrawerLoader.sourceComponent = indicatorDrawer.sourceComponent
        }
        onClosed: {
            _expanded = false
            indicatorItem = undefined
            indicatorDrawerLoader.sourceComponent = undefined
        }

        background: Item {
            Rectangle {
                id: backgroundRect
                anchors.fill: parent
                color: QGroundControl.globalPalette.window
                radius: indicatorDrawer._margins
                opacity: 0.85
            }

            Rectangle {
                anchors.horizontalCenter: backgroundRect.right
                anchors.verticalCenter: backgroundRect.top
                width: ScreenTools.largeFontPixelHeight
                height: width
                radius: width / 2
                color: QGroundControl.globalPalette.button
                border.color: QGroundControl.globalPalette.buttonText
                visible: indicatorDrawerLoader.item && indicatorDrawerLoader.item.showExpand && !indicatorDrawer._expanded

                QGCLabel {
                    anchors.centerIn: parent
                    text: ">"
                    color: QGroundControl.globalPalette.buttonText
                }

                QGCMouseArea {
                    fillItem: parent
                    onClicked: indicatorDrawer._expanded = true
                }
            }
        }

        contentItem: QGCFlickable {
            id: indicatorDrawerLoaderFlickable
            implicitWidth: Math.min(mainWindow.contentItem.width - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.width)
            implicitHeight: Math.min(mainWindow.contentItem.height - ScreenTools.toolbarHeight - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.height)
            contentWidth: indicatorDrawerLoader.width
            contentHeight: indicatorDrawerLoader.height

            Loader {
                id: indicatorDrawerLoader

                Binding {
                    target: indicatorDrawerLoader.item
                    property: "expanded"
                    value: indicatorDrawer._expanded
                }

                Binding {
                    target: indicatorDrawerLoader.item
                    property: "drawer"
                    value: indicatorDrawer
                }
            }
        }
    }

    function createrWindowedAnalyzePage(title, source) {
        var windowedPage = windowedAnalyzePage.createObject(mainWindow)
        windowedPage.title = title
        windowedPage.source = source
    }

    Component {
        id: windowedAnalyzePage

        Window {
            width: ScreenTools.defaultFontPixelWidth * 100
            height: ScreenTools.defaultFontPixelHeight * 70
            // ... (qalan Window xüsusiyyətləri)
        }
    }
}

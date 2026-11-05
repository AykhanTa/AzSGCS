import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
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
    // On a phone or remote the window is the screen. The desktop size and minimum are far
    // larger than a G20's logical screen (753x471 at dpr 2.55): Qt kept the window at the
    // minimum, the remote showed only its top left corner, and anything centred in the
    // window (the startup logo, every dialog) was drawn off screen.
    width:  ScreenTools.isMobile ? Screen.width  : ScreenTools.defaultFontPixelWidth  * 140
    height: ScreenTools.isMobile ? Screen.height : ScreenTools.defaultFontPixelHeight * 80
    minimumWidth:  ScreenTools.isMobile ? 0 : ScreenTools.defaultFontPixelWidth  * 90
    minimumHeight: ScreenTools.isMobile ? 0 : ScreenTools.defaultFontPixelHeight * 55

//     // --- SPLASH SCREEN KODU BAŞLANĞICI ---
    Rectangle {
        id: splashScreen
        anchors.fill: parent
        color: "black"
        z: 9999

        // main_logo.svg is a 593x426 bitmap wrapped in SVG, not vector art, so anything
        // drawn larger than that many device pixels is an upscale. Staying at or below it
        // keeps the logo pixel exact on both the desktop and the G30 (dpr 2.25).
        readonly property int  _artworkWidth:  593
        readonly property int  _artworkHeight: 426
        readonly property real _dpr:           Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

        // Latched when the animation starts rather than bound to width/height: the window
        // goes full screen around the same moment, and a size that changes mid-animation is
        // what made the logo jump.
        property int _logoWidth: 0

        function _computeLogoWidth() {
            var byWidth  = splashScreen.width * 0.5
            var byHeight = splashScreen.height * 0.5 * (_artworkWidth / _artworkHeight)
            var native_  = _artworkWidth / _dpr
            return Math.max(1, Math.floor(Math.min(byWidth, byHeight, native_)))
        }

        function start() {
            if (splashAnimation.running || !splashScreen.visible) {
                return
            }
            splashScreen._logoWidth = splashScreen._computeLogoWidth()
            splashAnimation.start()
        }

        Image {
            id: splashImage
            source: "qrc:/res/AZSHIELD_ICON/main_logo.svg"

            // Rasterised straight at the size it is drawn at, so nothing is scaled on the
            // way to the screen. Only the width is given; Qt takes the height from the
            // artwork's own ratio, which cannot squash it.
            sourceSize.width: splashScreen._logoWidth
            width:  implicitWidth
            height: implicitHeight

            // Whole pixels. Centering through a binding leaves the image on a half pixel,
            // and a half-pixel texture sample is what reads as shimmer.
            x: Math.round((splashScreen.width  - width)  / 2)
            y: Math.round((splashScreen.height - height) / 2)

            opacity: 0
        }

        // Nothing here moves or resizes: only opacity changes, so there is no frame where
        // the logo is drawn at a fractional size or offset.
        SequentialAnimation {
            id: splashAnimation

            NumberAnimation {
                target:         splashImage
                property:       "opacity"
                from:           0
                to:             1
                duration:       600
                easing.type:    Easing.OutCubic
            }

            PauseAnimation { duration: 1900 }

            NumberAnimation {
                target:         splashScreen
                property:       "opacity"
                from:           1
                to:             0
                duration:       500
                easing.type:    Easing.InCubic
            }

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

        // Backstop only. The window normally kicks this off once it is up, and callLater
        // folds the two requests into one call.
        Component.onCompleted: Qt.callLater(splashScreen.start)
    }
    // --- SPLASH SCREEN KODU SONU ---

    Component.onCompleted: {
        // Mobil ekranda fullscreen daha məntiqlidir
        if (ScreenTools.isMobile) {
            mainWindow.showFullScreen()
        }
        mainWindow.visible = true

        // Only once the window is up and at its final size, so the logo is placed against
        // geometry that will not move under it.
        Qt.callLater(splashScreen.start)

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
        if ((_autoCollapseMenu || AzTheme.compact) && leftPanel.visible) {
            // ✅ width-ə toxunma, yalnız state dəyiş
            leftPanel.isCollapsed = true
        }
    }

    onWidthChanged:  Qt.callLater(_applyResponsiveMenuState)
    onHeightChanged: Qt.callLater(_applyResponsiveMenuState)

    // The design tokens scale against the window, not the screen.
    Binding { target: AzTheme; property: "windowWidth";  value: mainWindow.width }
    Binding { target: AzTheme; property: "windowHeight"; value: mainWindow.height }

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
        showTool(qsTr("Application Settings"), "qrc:/qml/QGroundControl/Controls/AppSettings.qml", "qrc:/res/AZSHIELD_ICON/Logo2.svg")
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

        width: Math.min(AzTheme.px(603), contentArea.width - 24)

        anchors.horizontalCenter: contentArea.horizontalCenter
        anchors.bottom: contentArea.bottom
        anchors.bottomMargin: AzTheme.px(20)

        visible: flyView.visible && !planView.visible && !overlayOpen && !toolDrawer.visible

        panelTitle: qsTr("Mərmi")
        launcher:   typeof ammoLauncher !== "undefined" ? ammoLauncher : null
    }

    // Refused or unanswered launcher commands and a lost launcher link.
    Connections {
        target: typeof ammoLauncher !== "undefined" ? ammoLauncher : null
        function onCommandFailed(message) { mainWindow.showCriticalVehicleMessage(message) }
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
                            imageResource: "qrc:/res/AZSHIELD_ICON/Logo2.svg"
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

        // The panel card of the confirmation dialog: the title and ✕, one group box row
        // per link with its state and a connect / disconnect button, then the actions.
        readonly property real _pad:       AzTheme.px(18)
        readonly property real _rowHeight: AzTheme.px(AzTheme.groupRowHeight + 8)
        readonly property real _rowGap:    AzTheme.px(8)
        readonly property int  _rowCount:  _visibleManualConnectionCount()

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

        width:  Math.min(mainWindow.width - 2 * AzTheme.px(16), AzTheme.px(520))
        height: Math.min(mainWindow.height - 2 * AzTheme.px(16), popupColumn.implicitHeight + 2 * _pad)

        x: Math.round((mainWindow.width - width) * 0.5)
        y: Math.round((mainWindow.height - height) * 0.5)

        modal: true
        focus: true
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Item {
            RectangularShadow {
                anchors.fill: popupCard
                offset.y:     AzTheme.px(12)
                blur:         AzTheme.px(32)
                radius:       popupCard.radius
                color:        AzTheme.popupShadow
            }

            AzGradientRect {
                id:            popupCard
                anchors.fill:  parent
                angle:         AzTheme.panelGradientAngle
                startColor:    AzTheme.panelGradientStart
                startPosition: AzTheme.panelGradientStartPos
                endColor:      AzTheme.panelGradientEnd
                endPosition:   AzTheme.panelGradientEndPos
                radius:        AzTheme.px(14)
                borderColor:   AzTheme.panelBorder
                borderWidth:   1
            }
        }

        property var _autoConnectSettings: QGroundControl.settingsManager.autoConnectSettings
        property bool _udpAutoConnectState: _autoConnectSettings ? _autoConnectSettings.autoConnectUDP.value : false

        ColumnLayout {
            id: popupColumn
            anchors.fill: parent
            anchors.margins: connectionListPopup._pad
            spacing: AzTheme.px(AzTheme.popupGap)

            RowLayout {
                Layout.fillWidth: true
                spacing: AzTheme.px(8)

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Əlaqəni Seçin")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTitleSize)
                    elide: Text.ElideRight
                }

                AzIconButton {
                    iconSource: "qrc:/res/AZSHIELD_ICON/v2/popup_close.svg"
                    iconSize:   AzTheme.px(18)
                    onClicked:  connectionListPopup.close()
                }
            }

            // No manual link configured yet
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: AzTheme.px(96)
                visible: connectionListPopup._rowCount === 0
                radius: AzTheme.px(AzTheme.groupRadius)
                color: AzTheme.groupFill
                border.width: 1
                border.color: AzTheme.groupBorder

                Text {
                    anchors.fill: parent
                    anchors.margins: AzTheme.px(16)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Bağlantı yoxdur. \"Konfiqurasiya\" ilə yeni bağlantı əlavə edin.")
                    color: AzTheme.mutedText
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                }
            }

            ListView {
                id: connectionListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: connectionListPopup._rowCount * (connectionListPopup._rowHeight + spacing)
                visible: connectionListPopup._rowCount > 0
                clip: true
                spacing: connectionListPopup._rowGap
                boundsBehavior: Flickable.StopAtBounds

                model: _linkManager ? _linkManager.linkConfigurations : []

                delegate: Item {
                    id: delegateItem
                    width: connectionListView.width

                    property string linkName: object && object.name ? object.name.toLowerCase() : ""
                    property bool _isUdpLink: linkName.indexOf("udp") !== -1
                    property bool isConnected: object && object.link ? true : false

                    visible: !_isUdpLink
                    height: _isUdpLink ? 0 : connectionListPopup._rowHeight

                    Rectangle {
                        anchors.fill: parent
                        visible: !delegateItem._isUdpLink
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                            anchors.rightMargin: AzTheme.px(10)
                            spacing: AzTheme.px(12)

                            Column {
                                Layout.fillWidth: true
                                spacing: AzTheme.px(2)

                                Text {
                                    width: parent.width
                                    text: object.name
                                    color: AzTheme.textCard
                                    font.family: AzTheme.fontFamily
                                    font.weight: Font.Medium
                                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                                    elide: Text.ElideRight
                                }

                                Row {
                                    spacing: AzTheme.px(6)

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(6, AzTheme.px(8))
                                        height: width
                                        radius: width / 2
                                        color: delegateItem.isConnected ? AzTheme.statusGreen : AzTheme.statusRed
                                    }

                                    Text {
                                        id: statusLabel
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: delegateItem.isConnected ? qsTr("Əlaqə qurulub") : qsTr("Əlaqə qurulmayıb")
                                        color: AzTheme.textSecondary
                                        font.family: AzTheme.fontFamily
                                        font.pixelSize: AzTheme.fontPx(12)
                                    }
                                }
                            }

                            AzButton {
                                id: connectButton
                                Layout.preferredWidth: AzTheme.px(132)
                                Layout.preferredHeight: AzTheme.px(34)
                                text: delegateItem.isConnected ? qsTr("Əlaqəni kəs") : qsTr("Əlaqəni qur")
                                danger: delegateItem.isConnected
                                positive: !delegateItem.isConnected

                                onClicked: {
                                    if (autoConnectBlocker.running) {
                                        return
                                    }

                                    if (delegateItem.isConnected) {
                                        _handleDisconnectWithAutoConnect(object)

                                        if (object.link) {
                                            object.link.disconnect()
                                        }

                                        delegateItem.isConnected = false
                                    } else {
                                        _handleConnectWithAutoConnect(object)
                                        _linkManager.createConnectedLink(object)

                                        delegateItem.isConnected = true

                                        connectionListPopup.close()
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

            RowLayout {
                Layout.fillWidth: true
                spacing: AzTheme.px(10)

                // Opens Tənzimləmələr on "Rabitə Kanalları" to add or edit a link
                AzButton {
                    id: configButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: AzTheme.px(38)
                    text: qsTr("Konfiqurasiya")
                    iconSource: "qrc:/res/AZSHIELD_ICON/v2/popup_settings.svg"
                    onClicked: {
                        connectionListPopup.close()

                        if (leftPanel) {
                            leftPanel.visible = false
                        }

                        // Tənzimləmələr overlay-ini aç və "Rabitə Kanalları"na keç. Səhifə adı
                        // ilə açılır: sabit nömrə (7) siyahıya Gimbal əlavə olunanda Gimbal-ı açırdı.
                        sideMenuLoader.setSource(Qt.resolvedUrl("Tenzimlemeler.qml"), { startPage: "Comm_links.qml" })
                    }
                }

                AzButton {
                    id: closeButton2
                    Layout.fillWidth: true
                    Layout.preferredHeight: AzTheme.px(38)
                    text: qsTr("Bağla")
                    onClicked: connectionListPopup.close()
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

    // A panel card under the status bar outlined in the warning yellow: the message on the
    // left, then a divider and the "Vehicle Error" tag with its dot. A tap dismisses it.
    Popup {
        id: criticalVehicleMessagePopup
        y: (mainWindow._topInset > 0 ? mainWindow._topInset : ScreenTools.toolbarHeight) + AzTheme.px(10)
        x: Math.round((mainWindow.width - width) * 0.5)
        width: Math.min(mainWindow.width - 2 * AzTheme.px(16), Math.max(AzTheme.px(420), mainWindow.width * 0.42))
        height: messageRow.implicitHeight + 2 * _padY
        padding: 0
        modal: false
        focus: true

        readonly property real  _padX:        AzTheme.px(18)
        readonly property real  _padY:        AzTheme.px(12)
        readonly property color _accent:      AzTheme.statusYellow

        property alias criticalVehicleMessage: criticalVehicleMessageText.text
        property bool additionalCriticalMessagesReceived: false

        background: Item {
            RectangularShadow {
                anchors.fill: messageCard
                offset.y:     AzTheme.px(8)
                blur:         AzTheme.px(20)
                radius:       messageCard.radius
                color:        AzTheme.popupShadow
            }

            AzGradientRect {
                id:            messageCard
                anchors.fill:  parent
                angle:         AzTheme.panelGradientAngle
                startColor:    AzTheme.panelGradientStart
                startPosition: AzTheme.panelGradientStartPos
                endColor:      AzTheme.panelGradientEnd
                endPosition:   AzTheme.panelGradientEndPos
                radius:        AzTheme.px(10)
                borderColor:   Qt.rgba(1, 212 / 255, 59 / 255, 0.75)
                borderWidth:   1
            }
        }

        RowLayout {
            id: messageRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: criticalVehicleMessagePopup._padX
            anchors.rightMargin: criticalVehicleMessagePopup._padX
            spacing: AzTheme.px(14)

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: AzTheme.px(4)

                Text {
                    id: criticalVehicleMessageText
                    width: parent.width
                    wrapMode: Text.WordWrap
                    textFormat: TextEdit.RichText
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                }

                Text {
                    width: parent.width
                    visible: criticalVehicleMessagePopup.additionalCriticalMessagesReceived
                    text: qsTr("Əlavə xətalar var: toxunun və siyahıya baxın")
                    color: criticalVehicleMessagePopup._accent
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(12)
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.minimumHeight: AzTheme.px(22)
                color: AzTheme.panelBorder
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: AzTheme.px(8)

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: AzTheme.px(7)
                    height: width
                    radius: width / 2
                    color: criticalVehicleMessagePopup._accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Vehicle Error")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(12)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                criticalVehicleMessagePopup.close()
                if (criticalVehicleMessagePopup.additionalCriticalMessagesReceived) {
                    criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false
                    flyView.dropMainStatusIndicatorTool()
                } else if (QGroundControl.multiVehicleManager.activeVehicle) {
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

    /// Opens an Analyze page in its own top-level window.
    ///
    /// initialLogPath is forwarded to pages that accept one (the Log Viewer), so a log the
    /// panel handed over is reopened here. It has to go in as an initial property rather
    /// than be assigned afterwards: the page opens it from Component.onCompleted, which has
    /// already run by the time createObject() returns.
    function createWindowedAnalyzePage(title, source, initialLogPath) {
        var component = Qt.createComponent(source)
        if (component.status !== Component.Ready) {
            console.warn("createWindowedAnalyzePage failed source:", source, "error:", component.errorString())
            return
        }

        var windowedPage = windowedAnalyzePage.createObject(mainWindow, { title: title })
        if (!windowedPage) {
            console.warn("createWindowedAnalyzePage could not create the window for:", source)
            return
        }

        // popped hides the page's own popout affordance -- it is already popped out.
        var pageProperties = { popped: true }
        // Only pages that declare it, or QML warns about assigning a missing property.
        if (initialLogPath) {
            pageProperties.initialLogPath = initialLogPath
        }

        var page = component.createObject(windowedPage.contentArea, pageProperties)
        if (!page) {
            console.warn("createWindowedAnalyzePage could not create the page:", source)
            windowedPage.destroy()
            return
        }

        windowedPage.visible = true
    }

    Component {
        id: windowedAnalyzePage

        Window {
            width:  ScreenTools.defaultFontPixelWidth  * 120
            height: ScreenTools.defaultFontPixelHeight * 50
            minimumWidth:  ScreenTools.defaultFontPixelWidth  * 70
            minimumHeight: ScreenTools.defaultFontPixelHeight * 30
            visible: false
            color: qgcPal.window

            property alias contentArea: contentRect

            Rectangle {
                id: contentRect
                anchors.fill: parent
                color: qgcPal.window
            }

            onClosing: {
                // The page was parented here by createWindowedAnalyzePage rather than loaded,
                // so nothing else will tear it down.
                for (var i = contentRect.children.length - 1; i >= 0; i--) {
                    contentRect.children[i].destroy()
                }
                Qt.callLater(destroy)
            }
        }
    }
}

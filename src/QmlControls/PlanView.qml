

// // import QGroundControl.FlightDisplay
// // import QGroundControl.UTMSP


// // Item {
// //     id: _root

// //     property bool planControlColapsed: false

// //     readonly property int   _decimalPlaces:             8
// //     readonly property real  _margin:                    ScreenTools.defaultFontPixelHeight * 0.5
// //     readonly property real  _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
// //     readonly property real  _radius:                    ScreenTools.defaultFontPixelWidth  * 0.5
// //     readonly property real  _rightPanelWidth:           Math.min(width / 3, ScreenTools.defaultFontPixelWidth * 30)
// //     readonly property var   _defaultVehicleCoordinate:  QtPositioning.coordinate(37.803784, -122.462276)
// //     readonly property bool  _waypointsOnlyMode:         QGroundControl.corePlugin.options.missionWaypointsOnly

// //     property var    _planMasterController:              planMasterController
// //     property var    _missionController:                 _planMasterController.missionController
// //     property var    _geoFenceController:                _planMasterController.geoFenceController
// //     property var    _rallyPointController:              _planMasterController.rallyPointController
// //     property var    _visualItems:                       _missionController.visualItems
// //     property bool   _lightWidgetBorders:                editorMap.isSatelliteMap
// //     property bool   _addROIOnClick:                     false
// //     property bool   _singleComplexItem:                 _missionController.complexMissionItemNames.length === 1
// //      property int    _editingLayer:                      {if(!_utmspEnabled){layerTabBar.currentIndex ? _layers[layerTabBar.currentIndex] : _layerMission}else{layerTabBarUTMSP.currentIndex ? _layersUTMSP[layerTabBarUTMSP.currentIndex] : _layerMission}}
// //     property int    _toolStripBottom:                   toolStrip.height + toolStrip.y
// //     property var    _appSettings:                       QGroundControl.settingsManager.appSettings
// //     property var    _planViewSettings:                  QGroundControl.settingsManager.planViewSettings
// //     property bool   _promptForPlanUsageShowing:         false
// //     property bool   _utmspEnabled:                      QGroundControl.utmspSupported
// //     property bool   _resetGeofencePolygon:              false   //Reset the Geofence Polygon
// //     property var    _vehicleID
// //     property bool   _triggerSubmit
// //     property bool   _resetRegisterFlightPlan

// //     readonly property var       _layers:                    [_layerMission, _layerGeoFence, _layerRallyPoints]
// //     readonly property var       _layersUTMSP:               [_layerMission, _layerRallyPoints, _layerUTMSP] //Adds additional UTMSP layer

// //     readonly property int       _layerMission:              1
// //     readonly property int       _layerGeoFence:             2
// //     readonly property int       _layerRallyPoints:          3
// //     readonly property int       _layerUTMSP:                4 // Additional Tab button when UTMSP is enabled
// //     readonly property string    _armedVehicleUploadPrompt:  qsTr("Vehicle is currently armed. Do you want to upload the mission to the vehicle?")







// import QtQuick
// import QtQuick.Controls
// import QtQuick.Dialogs
// import QtLocation
// import QtPositioning
// import QtQuick.Layouts
// import QtQuick.Window

// import QGroundControl
// import QGroundControl.FlightMap

// import QGroundControl.Controls

// import QGroundControl.FactControls


// import QGroundControl.FlightDisplay
// import QGroundControl.UTMSP


// Item {
//     id: _root

//     property bool planControlColapsed: false

//     readonly property int   _decimalPlaces:             8
//     readonly property real  _margin:                    ScreenTools.defaultFontPixelHeight * 0.5
//     readonly property real  _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
//     readonly property real  _radius:                    ScreenTools.defaultFontPixelWidth  * 0.5
//     readonly property real  _rightPanelWidth:           Math.min(width / 3, ScreenTools.defaultFontPixelWidth * 30)
//     readonly property var   _defaultVehicleCoordinate:  QtPositioning.coordinate(37.803784, -122.462276)
//     readonly property bool  _waypointsOnlyMode:         QGroundControl.corePlugin.options.missionWaypointsOnly

//     property var    _planMasterController:              planMasterController
//     property var    _missionController:                 _planMasterController.missionController
//     property var    _geoFenceController:                _planMasterController.geoFenceController
//     property var    _rallyPointController:              _planMasterController.rallyPointController
//     property var    _visualItems:                       _missionController.visualItems
//     property bool   _lightWidgetBorders:                editorMap.isSatelliteMap
//     property bool   _addROIOnClick:                     false
//     property bool   _singleComplexItem:                 _missionController.complexMissionItemNames.length === 1
//      property int    _editingLayer:                      {if(!_utmspEnabled){layerTabBar.currentIndex ? _layers[layerTabBar.currentIndex] : _layerMission}else{layerTabBarUTMSP.currentIndex ? _layersUTMSP[layerTabBarUTMSP.currentIndex] : _layerMission}}
//     property int    _toolStripBottom:                   toolStrip.height + toolStrip.y
//     property var    _appSettings:                       QGroundControl.settingsManager.appSettings
//     property var    _planViewSettings:                  QGroundControl.settingsManager.planViewSettings
//     property bool   _promptForPlanUsageShowing:         false
//     property bool   _utmspEnabled:                      QGroundControl.utmspSupported
//     property bool   _resetGeofencePolygon:              false   //Reset the Geofence Polygon
//     property var    _vehicleID
//     property bool   _triggerSubmit
//     property bool   _resetRegisterFlightPlan

//     readonly property real _topCompensation: Math.max(0, -_root.y)


//     readonly property var       _layers:                    [_layerMission, _layerGeoFence, _layerRallyPoints]
//     readonly property var       _layersUTMSP:               [_layerMission, _layerRallyPoints, _layerUTMSP] //Adds additional UTMSP layer

//     readonly property int       _layerMission:              1
//     readonly property int       _layerGeoFence:             2
//     readonly property int       _layerRallyPoints:          3
//     readonly property int       _layerUTMSP:                4 // Additional Tab button when UTMSP is enabled
//     readonly property string    _armedVehicleUploadPrompt:  qsTr("Vehicle is currently armed. Do you want to upload the mission to the vehicle?")




//     Item {
//         id:             panel
//         anchors.left:   parent.left
//         anchors.right:  parent.right
//         anchors.top:    planToolBar.bottom
//         anchors.bottom: parent.bottom

//         Rectangle {
//                 anchors.fill: parent
//                 color: "black"
//                 z: -1  // ✅ Digər elementlərin arxasında qalsın
//             }

















//             MissionStats {
//                 id: missionStats
//                 Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
//                 Layout.fillWidth: false

//                 visible: missionStatsButton.checked

//                 // ✅ görünmürsə layoutda yer tutmasın
//                 Layout.preferredHeight: visible ? implicitHeight : 0
//                 Layout.preferredWidth:  visible ? Math.min(implicitWidth, missionStatus._availableStatusWidth) : 0
//                 Layout.maximumWidth:    visible ? missionStatus._availableStatusWidth : 0

//                 planMasterController: _root._planMasterController
//             }





//             // MissionStats {
//             //     id: missionStats
//             //     Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
//             //     Layout.fillWidth: false
//             //     // Layout.preferredWidth / maximumWidth yazma — implicitWidth özü kifayətdir
//             //     visible: missionStatsButton.checked
//             //     planMasterController: _root._planMasterController
//             // }





import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import QtLocation
import QtPositioning
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.FlightMap
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.FlightDisplay
import QGroundControl.UTMSP


Item {
    id: _root

    // ✅ qgcPal istifadə etdiyiniz üçün burada palette əlavə edirik
    QGCPalette {
        id: qgcPal
        colorGroupEnabled: true
    }

    // The text fields, combo boxes, check boxes, labels and section headers of the
    // item editors take the new design's look (see QGCTextField._az).
    readonly property bool azInputStyle: true

    // Terrain profile / mission statistics / hide, as small map buttons: the card
    // gradient, the side menu's selected box on the one showing.
    // A row of the Fayl panel's file and vehicle actions
    component ActionRow: MissionMenuButton {
        Layout.fillWidth:       true
        Layout.preferredHeight: AzTheme.px(38)
    }

    component StatusButton: Item {
        id: statusButton

        property string iconSource
        property bool   checked: false
        property string toolTipText

        signal clicked()

        implicitWidth:  AzTheme.px(40)
        implicitHeight: implicitWidth

        AzGradientRect {
            anchors.fill:  parent
            visible:       !statusButton.checked
            angle:         AzTheme.cardGradientAngle
            startColor:    AzTheme.cardGradientStart
            startPosition: AzTheme.cardGradientStartPos
            endColor:      AzTheme.cardGradientEnd
            endPosition:   AzTheme.cardGradientEndPos
            radius:        AzTheme.px(AzTheme.menuSelectedRadius)
            borderColor:   statusMouse.containsMouse ? AzTheme.cardHoverBorder : AzTheme.cardBorder
            borderWidth:   1
        }

        Rectangle {
            anchors.fill: parent
            visible:      statusButton.checked
            radius:       AzTheme.px(AzTheme.menuSelectedRadius)
            border.width: 1
            border.color: AzTheme.menuSelectedBorder
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
            }
        }

        QGCColoredImage {
            anchors.centerIn:  parent
            width:             AzTheme.px(20)
            height:            width
            sourceSize.height: height
            fillMode:          Image.PreserveAspectFit
            source:            statusButton.iconSource
            color:             statusButton.checked ? AzTheme.textPrimary : AzTheme.textCard
        }

        MouseArea {
            id:           statusMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked:    statusButton.clicked()
        }

        ToolTip.visible: statusMouse.containsMouse && toolTipText !== ""
        ToolTip.text:    toolTipText
        ToolTip.delay:   400
    }

    // Sağ panelin yığılma vəziyyəti
    property bool planControlColapsed: false

    readonly property int   _decimalPlaces:             8
    readonly property real  _margin:                    ScreenTools.defaultFontPixelHeight * 0.5
    readonly property real  _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    readonly property real  _radius:                    ScreenTools.defaultFontPixelWidth  * 0.5
    readonly property var   _defaultVehicleCoordinate:  QtPositioning.coordinate(37.803784, -122.462276)
    readonly property bool  _waypointsOnlyMode:         QGroundControl.corePlugin.options.missionWaypointsOnly

    readonly property bool showBorder: qgcPal.globalTheme === QGCPalette.Light


    // ==========================================================
    // ✅ Sağ panel responsiv eni + collapse handle
    // - Kiçik ekranda kəsilmə olmasın deyə minimum en saxlanır
    // - Böyük ekranda artıq en böyümür (kontentə uyğun qalır)
    // ==========================================================
    // readonly property real _rightPanelHandleWidth:          Math.round(ScreenTools.defaultFontPixelHeight * 1.8)   // handle düyməsinin sahəsi
    // readonly property real _rightPanelMinContentWidth:      Math.round(ScreenTools.defaultFontPixelHeight * 20)    // ~320
    // readonly property real _rightPanelTargetContentWidth:   Math.round(ScreenTools.defaultFontPixelHeight * 22)    // ~352
    // readonly property real _rightPanelMaxContentWidth:      Math.round(ScreenTools.defaultFontPixelHeight * 24)    // ~384 (istəsən artır)
    // readonly property real _rightPanelAvailableContentWidth: Math.max(0, width - toolStrip.width - (_toolsMargin * 2) - _rightPanelHandleWidth)

    // // Kontent eni (handle daxil deyil)
    // readonly property real _rightPanelWidth: Math.min(
    //                                             _rightPanelAvailableContentWidth,
    //                                             Math.max(
    //                                                 _rightPanelMinContentWidth,
    //                                                 Math.min(_rightPanelMaxContentWidth, _rightPanelTargetContentWidth)
    //                                             )
    //                                         )

    // // Panelin ümumi eni (kontent + handle sahəsi)
    // readonly property real _rightPanelTotalWidth: _rightPanelWidth + _rightPanelHandleWidth

    // ✅ Sağ panel responsiv eni + collapse handle (kontent eninə uyğun, artıq boşluq yoxdur)
    // Yığma düyməsi üçün ayrılan sol zolaq — düymənin diametrindən bir az geniş,
    // artıq boşluq yaratmasın deyə mümkün qədər dar saxlanılır.
    readonly property real _rightPanelHandleWidth: AzTheme.px(46)

    // What the content would like, and the most the window can spare for it.
    // 40 font widths leaves the editors' labels room beside their fields (32 wrapped
    // "Bütün yüksəkliklər" onto two lines). The cap matters on a tablet: the G30
    // lays out in 853 logical pixels, where a fixed 320 took 40% of the width for
    // the item list. It does not bind on a desktop window.
    readonly property real _rightPanelPreferredContentWidth: Math.min(
                                                                 ScreenTools.defaultFontPixelWidth * 40,
                                                                 width * 0.30
                                                             )

    // Ekranda sağ panel üçün qalan real yer (ToolStrip + marginlər çıxılır)
    readonly property real _rightPanelAvailableContentWidth: Math.max(
                                                                0,
                                                                width - toolStrip.width - (_toolsMargin * 2) - _rightPanelHandleWidth
                                                            )

    // Panel kontenti heç vaxt kontentdən böyük olmasın, amma ekran kiçikdirsə yer qədər olsun
    readonly property real _rightPanelWidth: Math.min(_rightPanelAvailableContentWidth, _rightPanelPreferredContentWidth)

    // Ümumi en = kontent + handle
    readonly property real _rightPanelTotalWidth: _rightPanelWidth + _rightPanelHandleWidth


    property var    _planMasterController:              planMasterController
    property var    _missionController:                 _planMasterController.missionController
    property var    _geoFenceController:                _planMasterController.geoFenceController
    property var    _rallyPointController:              _planMasterController.rallyPointController
    property var    _visualItems:                       _missionController.visualItems
    property bool   _lightWidgetBorders:                editorMap.isSatelliteMap
    property bool   _addROIOnClick:                     false
    property bool   _singleComplexItem:                 _missionController.complexMissionItemNames.length === 1

    // ✅ FIX: əvvəl return yox idi, _editingLayer undefined ola bilərdi
    property int _editingLayer: {
        if (!_utmspEnabled) {
            return (layerTabBar.currentIndex >= 0 && layerTabBar.currentIndex < _layers.length)
                    ? _layers[layerTabBar.currentIndex]
                    : _layerMission
        } else {
            return (layerTabBarUTMSP.currentIndex >= 0 && layerTabBarUTMSP.currentIndex < _layersUTMSP.length)
                    ? _layersUTMSP[layerTabBarUTMSP.currentIndex]
                    : _layerMission
        }
    }

    property int    _toolStripBottom:                   toolStrip.height + toolStrip.y
    property var    _appSettings:                       QGroundControl.settingsManager.appSettings
    property var    _planViewSettings:                  QGroundControl.settingsManager.planViewSettings
    property bool   _promptForPlanUsageShowing:         false
    property bool   _utmspEnabled:                      QGroundControl.utmspSupported
    property bool   _resetGeofencePolygon:              false   //Reset the Geofence Polygon
    property var    _vehicleID
    property bool   _triggerSubmit
    property bool   _resetRegisterFlightPlan

    readonly property real _topCompensation: Math.max(0, -_root.y)

    readonly property var       _layers:                    [_layerMission, _layerGeoFence, _layerRallyPoints]
    readonly property var       _layersUTMSP:               [_layerMission, _layerRallyPoints, _layerUTMSP] //Adds additional UTMSP layer

    readonly property int       _layerMission:              1
    readonly property int       _layerGeoFence:             2
    readonly property int       _layerRallyPoints:          3
    readonly property int       _layerUTMSP:                4 // Additional Tab button when UTMSP is enabled
    readonly property string    _armedVehicleUploadPrompt:  qsTr("Vehicle is currently armed. Do you want to upload the mission to the vehicle?")

    function mapCenter() {
        var coordinate = editorMap.center
        coordinate.latitude  = coordinate.latitude.toFixed(_decimalPlaces)
        coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
        coordinate.altitude  = coordinate.altitude.toFixed(_decimalPlaces)
        return coordinate
    }

    property bool _firstMissionLoadComplete:    false
    property bool _firstFenceLoadComplete:      false
    property bool _firstRallyLoadComplete:      false
    property bool _firstLoadComplete:           false

    MapFitFunctions {
        id:                         mapFitFunctions
        map:                        editorMap
        usePlannedHomePosition:     true
        planMasterController:       _planMasterController
    }

    onVisibleChanged: {
        if(visible) {
            editorMap.zoomLevel = QGroundControl.flightMapZoom
            editorMap.center    = QGroundControl.flightMapPosition
            // if (!_planMasterController.containsItems) {
            //     toolStrip.simulateClick(toolStrip.fileButtonIndex)
            // }
        }
    }

    Connections {
        target: _appSettings ? _appSettings.defaultMissionItemAltitude : null
        function onRawValueChanged() {
            if (_visualItems.count > 1) {
                mainWindow.showMessageDialog(qsTr("Yeni hündürlük tətbiq edin"),
                                             qsTr("Siz missiya elementləri üçün standart hündürlüyü dəyişmisiniz. Bu yüksəkliyi cari missiyanın bütün elementlərinə tətbiq etmək istərdinizmi?"),
                                             Dialog.Yes | Dialog.No,
                                             function() { _missionController.applyDefaultMissionAltitude() })
            }
        }
    }

    Component {
        id: promptForPlanUsageOnVehicleChangePopupComponent
        QGCPopupDialog {
            title:      _planMasterController.managerVehicle.isOfflineEditingVehicle ? qsTr("Plan Görünüşü - Təyyarənin əlaqəsi kəsilib") : qsTr("Plan Görünüşü - Təyyarə Dəyişdi")
            buttons:    Dialog.NoButton

            ColumnLayout {
                QGCLabel {
                    Layout.maximumWidth:    parent.width
                    wrapMode:               QGCLabel.WordWrap
                    text:                   _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                qsTr("Plan Görünüşündə planla əlaqəli təyyarə artıq mövcud deyil. Bu planla nə etmək istərdiniz?") :
                                                qsTr("Plan Görünüşündə üzərində işlənən plan cari təyyarədən deyil. Bu planla nə etmək istərdiniz?")
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               _planMasterController.dirty ?
                                            (_planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                 qsTr("Saxlanmamış Dəyişiklikləri ləğv edin") :
                                                 qsTr("Saxlanmamış Dəyişiklikləri Silin, Yeni Planı Təyyarədən Yükləyin")) :
                                            qsTr("Təyyarədən Yeni Plan Yükləyin")
                    onClicked: {
                        _planMasterController.showPlanFromManagerVehicle()
                        _promptForPlanUsageShowing = false
                        close();
                    }
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                            qsTr("Cari Planı Saxlayın") :
                                            qsTr("Cari Planı Saxlayın, Təyyarədən Yeniləməyin")
                    onClicked: {
                        if (!_planMasterController.managerVehicle.isOfflineEditingVehicle) {
                            _planMasterController.dirty = true
                        }
                        _promptForPlanUsageShowing = false
                        close()
                    }
                }
            }
        }
    }

    PlanMasterController {
        id:         planMasterController
        flyView:    false

        Component.onCompleted: {
            _planMasterController.start()
            _missionController.setCurrentPlanViewSeqNum(0, true)
        }

        onPromptForPlanUsageOnVehicleChange: {
            if (!_promptForPlanUsageShowing) {
                _promptForPlanUsageShowing = true
                promptForPlanUsageOnVehicleChangePopupComponent.createObject(mainWindow).open()
            }
        }

        function waitingOnIncompleteDataMessage(save) {
            var saveOrUpload = save ? qsTr("Save") : qsTr("Upload")
            mainWindow.showMessageDialog(qsTr("Unable to %1").arg(saveOrUpload), qsTr("Planda natamam maddələr var. Bütün elementləri tamamlayın və yenidən %1.").arg(saveOrUpload))
        }

        function waitingOnTerrainDataMessage(save) {
            var saveOrUpload = save ? qsTr("Save") : qsTr("Upload")
            mainWindow.showMessageDialog(qsTr("Unable to %1").arg(saveOrUpload), qsTr("Plan düzgün hündürlük dəyərləri üçün serverdən ərazi məlumatlarını gözləyir."))
        }

        function checkReadyForSaveUpload(save) {
            if (readyForSaveState() == VisualMissionItem.NotReadyForSaveData) {
                waitingOnIncompleteDataMessage(save)
                return false
            } else if (readyForSaveState() == VisualMissionItem.NotReadyForSaveTerrain) {
                waitingOnTerrainDataMessage(save)
                return false
            }
            return true
        }

        function upload() {
            if (!checkReadyForSaveUpload(false /* save */)) {
                return
            }
            switch (_missionController.sendToVehiclePreCheck()) {
                case MissionController.SendToVehiclePreCheckStateOk:
                    sendToVehicle()
                    break
                case MissionController.SendToVehiclePreCheckStateActiveMission:
                    mainWindow.showMessageDialog(qsTr("Send To Vehicle"), qsTr("Current mission must be paused prior to uploading a new Plan"))
                    break
                case MissionController.SendToVehiclePreCheckStateFirwmareVehicleMismatch:
                    mainWindow.showMessageDialog(qsTr("Plan Upload"),
                                                 qsTr("This Plan was created for a different firmware or vehicle type than the firmware/vehicle type of vehicle you are uploading to. " +
                                                      "This can lead to errors or incorrect behavior. " +
                                                      "It is recommended to recreate the Plan for the correct firmware/vehicle type.\n\n" +
                                                      "Click 'Ok' to upload the Plan anyway."),
                                                 Dialog.Ok | Dialog.Cancel,
                                                 function() { _planMasterController.sendToVehicle() })
                    break
            }
        }

        function loadFromSelectedFile() {
            fileDialog.title =          qsTr("Select Plan File")
            fileDialog.planFiles =      true
            fileDialog.nameFilters =    _planMasterController.loadNameFilters
            fileDialog.openForLoad()
        }

        function saveToSelectedFile() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save Plan")
            fileDialog.planFiles =      true
            fileDialog.nameFilters =    _planMasterController.saveNameFilters
            fileDialog.openForSave()
        }

        function fitViewportToItems() {
            mapFitFunctions.fitMapViewportToMissionItems()
        }

        function saveKmlToSelectedFile() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save KML")
            fileDialog.planFiles =      false
            fileDialog.nameFilters =    ShapeFileHelper.fileDialogKMLFilters
            fileDialog.openForSave()
        }
    }

    Connections {
        target: _missionController

        function onNewItemsFromVehicle() {
            if (_visualItems && _visualItems.count !== 1) {
                mapFitFunctions.fitMapViewportToMissionItems()
            }
            _missionController.setCurrentPlanViewSeqNum(0, true)
        }
    }

    function insertSimpleItemAfterCurrent(coordinate) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
    }

    function insertROIAfterCurrent(coordinate) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertROIMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
    }

    function insertCancelROIAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertCancelROIMissionItem(nextIndex, true /* makeCurrentItem */)
    }

    function insertComplexItemAfterCurrent(complexItemName) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertComplexMissionItem(complexItemName, mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function insertTakeoffItemAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertTakeoffItem(mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function insertLandItemAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertLandItem(mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function selectNextNotReady() {
        for (var i=0; i<_missionController.visualItems.count; i++) {
            var vmi = _missionController.visualItems.get(i)
            if (vmi.readyForSaveState === VisualMissionItem.NotReadyForSaveData) {
                _missionController.setCurrentPlanViewSeqNum(vmi.sequenceNumber, true)
                break
            }
        }
    }

    QGCFileDialog {
        id:             fileDialog
        folder:         _appSettings ? _appSettings.missionSavePath : ""

        property bool planFiles: true

        onAcceptedForSave: (file) => {
            if (planFiles) {
                _planMasterController.saveToFile(file)
            } else {
                _planMasterController.saveToKml(file)
            }
            close()
        }

        onAcceptedForLoad: (file) => {
            _planMasterController.loadFromFile(file)
            _planMasterController.fitViewportToItems()
            _missionController.setCurrentPlanViewSeqNum(0, true)
            close()
        }
    }

    PlanViewToolBar {
        id:                     planToolBar
        planMasterController:   _planMasterController

        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top

        anchors.topMargin: _topCompensation
        z: QGroundControl.zOrderWidgets + 10
    }

    Item {
        id:             panel
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    planToolBar.bottom
        anchors.bottom: parent.bottom

        // The map runs from the tool strip's edge to the right of the window; the strip,
        // the top bar and the right panel cast their shadows onto it.
        FlightMap {
            id:                         editorMap
            anchors.fill:               parent
            anchors.leftMargin:         toolStrip.width
            mapName:                    "MissionEditor"
            allowGCSLocationCenter:     true
            allowVehicleLocationCenter: true
            planView:                   true

            zoomLevel:                  QGroundControl.flightMapZoom
            center:                     QGroundControl.flightMapPosition

            // ✅ Sağ panel yığılanda (_rightToolWidth = 0) viewport tam genişlik işləyir
            property real _rightToolWidth: planControlColapsed ? 0 : (rightPanel.width + rightPanel.anchors.rightMargin)
            property real _bottomYForViewport: missionStatus.visible ? (missionStatus.y - editorMap.y) : (height - _margin)
            property rect centerViewport: Qt.rect(
                _margin,
                _margin,
                editorMap.width - _rightToolWidth - (_margin * 2),
                _bottomYForViewport - _margin
            )

            property real _nonInteractiveOpacity:  0.5

            Component.onCompleted: editorMap.center = QGroundControl.flightMapPosition

            QGCMapPalette { id: mapPal; lightColors: editorMap.isSatelliteMap }

            onZoomLevelChanged: QGroundControl.flightMapZoom = editorMap.zoomLevel
            onCenterChanged:    QGroundControl.flightMapPosition = editorMap.center

            onMapClicked: (mouse) => {
                editorMap.focus = true
                if (!mainWindow.allowViewSwitch()) {
                    return
                }
                var coordinate = editorMap.toCoordinate(Qt.point(mouse.x, mouse.y), false)
                coordinate.latitude = coordinate.latitude.toFixed(_decimalPlaces)
                coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
                coordinate.altitude = coordinate.altitude.toFixed(_decimalPlaces)
                if(_utmspEnabled){
                    QGroundControl.utmspManager.utmspVehicle.updateLastCoordinates(coordinate.latitude, coordinate.longitude)
                }

                switch (_editingLayer) {
                case _layerMission:
                    if (addWaypointRallyPointAction.checked) {
                        insertSimpleItemAfterCurrent(coordinate)
                    } else if (_addROIOnClick) {
                        insertROIAfterCurrent(coordinate)
                        _addROIOnClick = false
                    }
                    break

                case _layerRallyPoints:
                    if (_rallyPointController.supported && addWaypointRallyPointAction.checked) {
                        _rallyPointController.addPoint(coordinate)
                    }
                    break

                case _layerUTMSP:
                    if (addWaypointRallyPointAction.checked) {
                        insertSimpleItemAfterCurrent(coordinate)
                    } else if (_addROIOnClick) {
                        insertROIAfterCurrent(coordinate)
                        _addROIOnClick = false
                    }
                    break
                }
            }

            Repeater {
                model: _missionController.visualItems
                delegate: MissionItemMapVisual {
                    map:         editorMap
                    opacity:     _editingLayer == _layerMission || _editingLayer == _layerUTMSP ? 1 : editorMap._nonInteractiveOpacity
                    interactive: _editingLayer == _layerMission || _editingLayer == _layerUTMSP
                    vehicle:     _planMasterController.controllerVehicle
                    onClicked:   (sequenceNumber) => { _missionController.setCurrentPlanViewSeqNum(sequenceNumber, false) }
                }
            }

            MissionLineView {
                showSpecialVisual:  _missionController.isROIBeginCurrentItem
                model:              _missionController.simpleFlightPathSegments
                opacity:            _editingLayer == _layerMission ||  _editingLayer == _layerUTMSP  ? 1 : editorMap._nonInteractiveOpacity
            }

            MapItemView {
                model: _editingLayer == _layerMission ||_editingLayer == _layerUTMSP ? _missionController.directionArrows : undefined
                delegate: MapLineArrow {
                    fromCoord:      object ? object.coordinate1 : undefined
                    toCoord:        object ? object.coordinate2 : undefined
                    arrowPosition:  3
                    z:              QGroundControl.zOrderWaypointLines + 1
                }
            }

            MapItemView {
                model: _missionController.incompleteComplexItemLines
                delegate: MapPolyline {
                    path:       [ object.coordinate1, object.coordinate2 ]
                    line.width: 1
                    line.color: "red"
                    z:          QGroundControl.zOrderWaypointLines
                    opacity:    _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
                }
            }

            MapQuickItem {
                id:             splitSegmentItem
                anchorPoint.x:  sourceItem.width / 2
                anchorPoint.y:  sourceItem.height / 2
                z:              QGroundControl.zOrderWaypointLines + 1
                visible:        _editingLayer == _layerMission ||  _editingLayer == _layerUTMSP

                sourceItem: SplitIndicator {
                    onClicked:  _missionController.insertSimpleMissionItem(splitSegmentItem.coordinate,
                                                                           _missionController.currentPlanViewVIIndex,
                                                                           true)
                }

                function _updateSplitCoord() {
                    if (_missionController.splitSegment) {
                        var distance = _missionController.splitSegment.coordinate1.distanceTo(_missionController.splitSegment.coordinate2)
                        var azimuth = _missionController.splitSegment.coordinate1.azimuthTo(_missionController.splitSegment.coordinate2)
                        splitSegmentItem.coordinate = _missionController.splitSegment.coordinate1.atDistanceAndAzimuth(distance / 2, azimuth)
                    } else {
                        coordinate = QtPositioning.coordinate()
                    }
                }

                Connections {
                    target: _missionController
                    function onSplitSegmentChanged()  { splitSegmentItem._updateSplitCoord() }
                }

                Connections {
                    target: _missionController.splitSegment
                    function onCoordinate1Changed()   { splitSegmentItem._updateSplitCoord() }
                    function onCoordinate2Changed()   { splitSegmentItem._updateSplitCoord() }
                }
            }

            MapItemView {
                model: QGroundControl.multiVehicleManager.vehicles
                delegate: VehicleMapItem {
                    vehicle:        object
                    coordinate:     object.coordinate
                    map:            editorMap
                    size:           ScreenTools.defaultFontPixelHeight * 3
                    z:              QGroundControl.zOrderMapItems - 1
                }
            }

            GeoFenceMapVisuals {
                map:                    editorMap
                myGeoFenceController:   _geoFenceController
                interactive:            _editingLayer == _layerGeoFence
                homePosition:           _missionController.plannedHomePosition
                planView:               true
                opacity:                _editingLayer != _layerGeoFence ? editorMap._nonInteractiveOpacity : 1
            }

            RallyPointMapVisuals {
                map:                    editorMap
                myRallyPointController: _rallyPointController
                interactive:            _editingLayer == _layerRallyPoints
                planView:               true
                opacity:                _editingLayer != _layerRallyPoints ? editorMap._nonInteractiveOpacity : 1
            }

            UTMSPMapVisuals {
                id: utmspvisual
                enabled:                _utmspEnabled
                map:                    editorMap
                currentMissionItems:    _visualItems
                myGeoFenceController:   _geoFenceController
                interactive:            _editingLayer == _layerUTMSP
                homePosition:           _missionController.plannedHomePosition
                planView:               true
                opacity:                _editingLayer != _layerUTMSP ? editorMap._nonInteractiveOpacity : 1
                resetCheck:             _resetGeofencePolygon
            }

            Connections {
                target: utmspEditor
                function onResetGeofencePolygonTriggered() {
                    resetTimer.start()
                }
            }

            Timer {
                id: resetTimer
                interval: 2500
                running: false
                repeat: false
                onTriggered: _resetGeofencePolygon = true
            }
        }

        //-----------------------------------------------------------
        // Left tool strip
        ToolStrip {
            id:                 toolStrip
            anchors.margins:    0
            anchors.left:       parent.left
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            // Alət lentindən açılan panellər (Fayl, Pattern, Mərkəz...) missiya
            // statusu / terrain diaqramının (zOrderWidgets + 5) üstündə olmalıdır,
            // əks halda panelin aşağı hissəsi diaqramın altında qalır.
            z:                  QGroundControl.zOrderWidgets + 6

            readonly property int fileButtonIndex:      0
            readonly property int takeoffButtonIndex:   1
            readonly property int waypointButtonIndex:  2
            readonly property int roiButtonIndex:       3
            readonly property int patternButtonIndex:   4
            readonly property int landButtonIndex:      5
            readonly property int centerButtonIndex:    6

            property bool _isRallyLayer:    _editingLayer == _layerRallyPoints
            property bool _isMissionLayer:  _editingLayer == _layerMission
            property bool _isUtmspLayer:    _editingLayer == _layerUTMSP

            ToolStripActionList {
                id: toolStripActionList
                model: [
                    ToolStripAction {
                        text:                   qsTr("Fayl")
                        enabled:                !_planMasterController.syncInProgress
                        visible:                true
                        showAlternateIcon:      _planMasterController.dirty
                        iconSource:             "qrc:/res/AZSHIELD_ICON/v2/plan_file.svg"
                        alternateIconSource:    "qrc:/res/AZSHIELD_ICON/v2/plan_file.svg"
                        dropPanelComponent:     syncDropPanel
                    },
                    ToolStripAction {
                        text:       qsTr("Takeoff")
                        iconSource: "qrc:/res/AZSHIELD_ICON/v2/fly_takeoff.svg"
                        enabled:    _missionController.isInsertTakeoffValid
                        visible:    (toolStrip._isMissionLayer || toolStrip._isUtmspLayer) && !_planMasterController.controllerVehicle.rover
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            insertTakeoffItemAfterCurrent()
                            _triggerSubmit = true
                        }
                    },
                    ToolStripAction {
                        id:                 addWaypointRallyPointAction
                        text:               _editingLayer == _layerRallyPoints ? qsTr("Rally Point") : qsTr("Waypoint")
                        iconSource:         "qrc:/res/AZSHIELD_ICON/v2/plan_waypoint.svg"
                        enabled:            toolStrip._isRallyLayer ? true : _missionController.flyThroughCommandsAllowed
                        visible:            toolStrip._isRallyLayer || toolStrip._isMissionLayer || toolStrip._isUtmspLayer
                        checkable:          true
                    },
                    ToolStripAction {
                        text:               _missionController.isROIActive ? qsTr("ROI Ləğv et") : qsTr("ROI")
                        iconSource:         "qrc:/res/AZSHIELD_ICON/v2/plan_roi.svg"
                        enabled:            !_missionController.onlyInsertTakeoffValid
                        visible:            toolStrip._isMissionLayer && _planMasterController.controllerVehicle.roiModeSupported
                        checkable:          !_missionController.isROIActive
                        onCheckedChanged:   _addROIOnClick = checked
                        onTriggered: {
                            if (_missionController.isROIActive) {
                                toolStrip.allAddClickBoolsOff()
                                insertCancelROIAfterCurrent()
                            }
                        }
                        property bool myAddROIOnClick: _addROIOnClick
                        onMyAddROIOnClickChanged: checked = _addROIOnClick
                    },
                    ToolStripAction {
                        text:               _singleComplexItem ? _missionController.complexMissionItemNames[0] : qsTr("Pattern")
                        iconSource:         "qrc:/res/AZSHIELD_ICON/v2/plan_pattern.svg"
                        enabled:            _missionController.flyThroughCommandsAllowed
                        visible:            toolStrip._isMissionLayer
                        dropPanelComponent: _singleComplexItem ? undefined : patternDropPanel
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            if (_singleComplexItem) {
                                insertComplexItemAfterCurrent(_missionController.complexMissionItemNames[0])
                            }
                        }
                    },
                    ToolStripAction {
                        text:       _planMasterController.controllerVehicle.multiRotor
                                    ? qsTr("Return")
                                    : _missionController.isInsertLandValid && _missionController.hasLandItem
                                      ? qsTr("Alt Land")
                                      : qsTr("Land")
                        iconSource: _planMasterController.controllerVehicle.multiRotor
                                    ? "qrc:/res/AZSHIELD_ICON/v2/fly_rtl.svg"
                                    : "qrc:/res/AZSHIELD_ICON/v2/fly_land.svg"
                        enabled:    _missionController.isInsertLandValid
                        visible:    toolStrip._isMissionLayer || toolStrip._isUtmspLayer
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            insertLandItemAfterCurrent()
                        }
                    },
                    ToolStripAction {
                        text:               qsTr("Mərkəz")
                        iconSource:         "qrc:/res/AZSHIELD_ICON/v2/plan_center.svg"
                        enabled:            true
                        visible:            true
                        dropPanelComponent: centerMapDropPanel
                    },

                    // ✅ Stats düyməsi yalnız missionStatus gizlidirsə ToolStrip-də görünsün
                    ToolStripAction {
                        text: qsTr("Stats")
                        iconSource: "qrc:/res/AZSHIELD_ICON/v2/plan_stats.svg"
                        visible: missionStatus.hidden
                                 && (toolStrip._isMissionLayer || toolStrip._isUtmspLayer)
                                 && QGroundControl.corePlugin.options.showMissionStatus
                        onTriggered: missionStatus.showMissionStatus()
                    }
                ]
            }

            model: toolStripActionList.model

            function allAddClickBoolsOff() {
                _addROIOnClick = false
                addWaypointRallyPointAction.checked = false
            }

            onDropped: allAddClickBoolsOff()
        }

        // ==========================================================
        // ✅ Sağ Panel (responsive + collapse)
        // ==========================================================
        Item {
            id: rightPanel

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right

            // Panel açıq: _toolsMargin
            // Panel yığılı: yalnız handle görünür
            anchors.rightMargin: planControlColapsed ? (_toolsMargin + _rightPanelHandleWidth - width) : _toolsMargin

            width:  _rightPanelTotalWidth
            z:      QGroundControl.zOrderWidgets + 2

            Behavior on anchors.rightMargin {
                NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
            }

            // Bloklar öz fonlarını daşıyır — panel arxasında əlavə yarımşəffaf
            // qat saxlansa, bloklarla xəritə arasında görünən "boşluq zolağı" yaranır.

            // Handle area (always clickable)
            Item {
                id: rightPanelHandle
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: _rightPanelHandleWidth

                // A round map button: the card gradient with its border and shadow.
                Item {
                    id: rightPanelToggleButton
                    width: AzTheme.px(36)
                    height: width
                    anchors.top: parent.top
                    anchors.topMargin: _toolsMargin + Math.max(0, (layerSelector.height - height) / 2)
                    anchors.horizontalCenter: parent.horizontalCenter

                    RectangularShadow {
                        anchors.fill: toggleBackground
                        offset.y:     AzTheme.px(4)
                        blur:         AzTheme.px(12)
                        radius:       toggleBackground.radius
                        color:        AzTheme.cardShadow
                    }

                    AzGradientRect {
                        id:            toggleBackground
                        anchors.fill:  parent
                        angle:         AzTheme.cardGradientAngle
                        startColor:    toggleMouse.pressed ? AzTheme.menuSelectedTop : AzTheme.cardGradientStart
                        startPosition: AzTheme.cardGradientStartPos
                        endColor:      toggleMouse.pressed ? AzTheme.menuSelectedBottom : AzTheme.cardGradientEnd
                        endPosition:   AzTheme.cardGradientEndPos
                        radius:        width / 2
                        borderColor:   toggleMouse.containsMouse ? AzTheme.cardHoverBorder : AzTheme.cardBorder
                        borderWidth:   1
                    }

                    QGCColoredImage {
                        anchors.centerIn: parent
                        width: AzTheme.px(16)
                        height: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        source: planControlColapsed
                                ? "qrc:/res/AZSHIELD_ICON/chevron-double-left.svg"
                                : "qrc:/res/AZSHIELD_ICON/chevron-double-right.svg"
                        color: AzTheme.textCard
                    }

                    MouseArea {
                        id: toggleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: planControlColapsed = !planControlColapsed
                    }
                }
            }

            // Panel content (hidden when collapsed)
            Item {
                id: rightPanelContent
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: _rightPanelHandleWidth
                anchors.topMargin: _toolsMargin
               // anchors.rightMargin: _toolsMargin
                anchors.rightMargin: 0
                anchors.bottomMargin: _toolsMargin

                visible: !planControlColapsed
                clip: true

                DeadMouseArea { }

                Column {
                    id:                 rightControls
                    spacing:            AzTheme.px(8)
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        parent.top

                    // Layer selector: a segmented control on the dark pill of the top bar
                    // panels; the segments themselves are Mission_Panel.
                    Item {
                        id: layerSelector

                        // ❗ visible-i uşaq elementə bağlamaq olmaz (effektiv görünürlük
                        //    geri oxunduğu üçün binding loop yaranır) — ortaq şərt saxlanılır.
                        readonly property bool selectorVisible: QGroundControl.corePlugin.options.enablePlanViewSelector && !_utmspEnabled
                        readonly property real segPad: AzTheme.px(4)

                        width:   parent.width
                        height:  selectorVisible ? (layerTabBar.implicitHeight + segPad * 2) : 0
                        visible: selectorVisible

                        RectangularShadow {
                            anchors.fill: selectorBackground
                            offset.y:     AzTheme.px(8)
                            blur:         AzTheme.px(20)
                            radius:       selectorBackground.radius
                            color:        AzTheme.cardShadow
                        }

                        Rectangle {
                            id:           selectorBackground
                            anchors.fill: parent
                            radius:       AzTheme.px(12)
                            border.width: 1
                            border.color: AzTheme.panelBorder
                            gradient: Gradient {
                                GradientStop { position: 0; color: AzTheme.pillTop }
                                GradientStop { position: 1; color: AzTheme.pillBottom }
                            }
                        }

                        TabBar {
                            id: layerTabBar
                            anchors.fill:        parent
                            anchors.margins:     layerSelector.segPad
                            spacing:             AzTheme.px(4)
                            background:          Item { }
                            Component.onCompleted: currentIndex = 0

                            Mission_Panel {
                                text:    qsTr("Mission")
                                enabled: _geoFenceController.supported
                            }

                            Mission_Panel {
                                text:    qsTr("Fence")
                                enabled: _geoFenceController.supported
                            }

                            Mission_Panel {
                                text:    qsTr("Rally")
                                enabled: _rallyPointController.supported
                            }
                        }
                    }

                    QGCTabBar {
                        id:         layerTabBarUTMSP
                        width:      parent.width
                        visible:    QGroundControl.corePlugin.options.enablePlanViewSelector && _utmspEnabled
                        Mission_Panel { text: qsTr("Mission") }
                        Mission_Panel { text: qsTr("Rally"); enabled: _rallyPointController.supported }
                        Mission_Panel { id: utmspbutton; text: qsTr("UTM-Adapter"); visible: _utmspEnabled }
                    }
                }

                //-------------------------------------------------------
                // Mission Item Editor
                Item {
                    id:                     missionItemEditor
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    anchors.top:            rightControls.bottom
                    anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                    anchors.bottom:         parent.bottom
                    anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 0.25
                    visible:                _editingLayer == _layerMission && !planControlColapsed

                    QGCListView {
                        id:                 missionItemEditorListView
                        anchors.fill:       parent
                        spacing:            AzTheme.px(8)
                        orientation:        ListView.Vertical
                        model:              _missionController.visualItems
                        cacheBuffer:        Math.max(height * 2, 0)
                        clip:               true
                        currentIndex:       _missionController.currentPlanViewSeqNum
                        highlightMoveDuration: 250
                        visible:            _editingLayer == _layerMission && !planControlColapsed

                        delegate: MissionItemEditor {
                            map:               editorMap
                            masterController:  _planMasterController
                            missionItem:       object
                            width:             missionItemEditorListView.width
                            readOnly:          false
                            onClicked:         (sequenceNumber) => { _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false) }
                            onRemove: {
                                var removeVIIndex = index
                                _missionController.removeVisualItem(removeVIIndex)
                                if (removeVIIndex >= _missionController.visualItems.count) {
                                    removeVIIndex--
                                }
                            }
                            onSelectNextNotReadyItem: selectNextNotReady()
                        }
                    }
                }

                GeoFenceEditor {
                    anchors.top:            rightControls.bottom
                    anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                    anchors.bottom:         parent.bottom
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    myGeoFenceController:   _geoFenceController
                    flightMap:              editorMap
                    visible:                _editingLayer == _layerGeoFence && !planControlColapsed
                }

                RallyPointEditorHeader {
                    id:                     rallyPointHeader
                    anchors.top:            rightControls.bottom
                    anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    visible:                _editingLayer == _layerRallyPoints && !planControlColapsed
                    controller:             _rallyPointController
                }

                RallyPointItemEditor {
                    id:                     rallyPointEditor
                    anchors.top:            rallyPointHeader.bottom
                    anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    visible:                _editingLayer == _layerRallyPoints && _rallyPointController.points.count && !planControlColapsed
                    rallyPoint:             _rallyPointController.currentRallyPoint
                    controller:             _rallyPointController
                }

                UTMSPAdapterEditor {
                    id: utmspEditor
                    enabled:                 _utmspEnabled
                    anchors.top:             rightControls.bottom
                    anchors.topMargin:       ScreenTools.defaultFontPixelHeight * 0.25
                    anchors.bottom:          parent.bottom
                    anchors.left:            parent.left
                    anchors.right:           parent.right
                    currentMissionItems:     _visualItems
                    myGeoFenceController:    _geoFenceController
                    flightMap:               editorMap
                    visible:                 _editingLayer == _layerUTMSP && !planControlColapsed
                    triggerSubmitButton:     _triggerSubmit
                    resetRegisterFlightPlan: _resetRegisterFlightPlan
                }
            }
        }

        // ==========================================================
        // ✅ missionStatus
        // ==========================================================
        RowLayout {
            id: missionStatus

            anchors.margins: _toolsMargin
            anchors.left: editorMap.left
            anchors.right: rightPanel.left
            anchors.bottom: parent.bottom

            spacing: 0
            clip:true
            z: QGroundControl.zOrderWidgets + 5

            readonly property real _availableStatusWidth: Math.max(0, width - missionStatsButtonLayout.implicitWidth)
            readonly property bool hidden: !_planViewSettings.showMissionItemStatus.rawValue

            function showMissionStatus() {
                _planViewSettings.showMissionItemStatus.rawValue = true
            }

            function _toggleMissionStatusVisibility() {
                _planViewSettings.showMissionItemStatus.rawValue = !_planViewSettings.showMissionItemStatus.rawValue
            }

            visible: !hidden
                     && (_editingLayer === _layerMission || _editingLayer === _layerUTMSP)
                     && QGroundControl.corePlugin.options.showMissionStatus

            ColumnLayout {
                id: missionStatsButtonLayout
                Layout.alignment: Qt.AlignBottom
                Layout.rightMargin: AzTheme.px(6)
                spacing: AzTheme.px(4)

                StatusButton {
                    id: terrainButton
                    iconSource:  "qrc:/res/AZSHIELD_ICON/v2/plan_terrain.svg"
                    toolTipText: qsTr("Relyef profili")
                    checked:     true
                    onClicked: {
                        terrainButton.checked = true
                        missionStatsButton.checked = false
                    }
                }

                StatusButton {
                    id: missionStatsButton
                    iconSource:  "qrc:/res/AZSHIELD_ICON/v2/plan_stats.svg"
                    toolTipText: qsTr("Missiya statistikası")
                    onClicked: {
                        missionStatsButton.checked = true
                        terrainButton.checked = false
                    }
                }

                StatusButton {
                    id: bottomStatusOpenCloseButton
                    iconSource:  "qrc:/res/AZSHIELD_ICON/chevron-double-left.svg"
                    toolTipText: qsTr("Gizlət")
                    onClicked:   missionStatus._toggleMissionStatusVisibility()
                }
            }

            TerrainStatus {
                id: terrainStatus
                Layout.alignment: Qt.AlignBottom
                Layout.fillWidth: true
                // Capped as well as font relative: 11 font heights suits a desktop
                // window and is 41% of a short one, which left the map a strip.
                // Through Layout.preferredHeight rather than height, because
                // TerrainStatus is a plain Rectangle with no implicit size, so the
                // row it sits in has nothing else to take its own height from.
                Layout.preferredHeight: Math.min(ScreenTools.defaultFontPixelHeight * 11,
                                                 mainWindow.height * 0.32)
                missionController: _missionController
                visible: terrainButton.checked
                onSetCurrentSeqNum: _missionController.setCurrentPlanViewSeqNum(seqNum, true)
            }

            MissionStats {
                id: missionStats
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: false

                visible: missionStatsButton.checked

                Layout.preferredHeight: visible ? implicitHeight : 0
                Layout.preferredWidth:  visible ? Math.min(implicitWidth, missionStatus._availableStatusWidth) : 0
                Layout.maximumWidth:    visible ? missionStatus._availableStatusWidth : 0

                planMasterController: _root._planMasterController
            }
        }

        QGCLabel {
            readonly property string _licenseString: QGroundControl.elevationProviderNotice
            id: licenseLabel

            visible: missionStatus.visible && terrainButton.checked && _licenseString !== ""
            anchors.bottom: missionStatus.top
            anchors.horizontalCenter: missionStatus.horizontalCenter
            anchors.bottomMargin: ScreenTools.defaultFontPixelWidth * 0.5

            font.pointSize: ScreenTools.smallFontPointSize
            //text: qsTr("Powered by %1").arg(_licenseString)
            z: missionStatus.z + 1
        }

        MapScale {
            id:                     mapScale
            anchors.margins:        _toolsMargin
            anchors.bottom:         missionStatus.visible ? missionStatus.top : parent.bottom
            anchors.left:           toolStrip.y + toolStrip.height + _toolsMargin > mapScale.y ? toolStrip.right : parent.left
            mapControl:             editorMap
            buttonsOnLeft:          true
            terrainButtonVisible:   false
            terrainButtonChecked:   false
        }
    }

    function showLoadFromFileOverwritePrompt(title) {
        mainWindow.showMessageDialog(title,
                                     qsTr("Yadda saxlanmamış/göndərilməyən dəyişiklikləriniz var. Fayldan yükləmə bu dəyişiklikləri itirəcək. Fayldan yükləmək istədiyinizə əminsiniz?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() { _planMasterController.loadFromSelectedFile() } )
    }

    Component {
        id: createPlanRemoveAllPromptDialog

        QGCSimpleMessageDialog {
            title:      qsTr("Plan yarat")
            text:       qsTr("Cari planı silmək və yeni plan yaratmaq istədiyinizə əminsiniz? ")
            buttons:    Dialog.Yes | Dialog.No

            property var mapCenter
            property var planCreator

            onAccepted: planCreator.createPlan(mapCenter)
        }
    }

    function clearButtonClicked() {
        mainWindow.showMessageDialog(qsTr("Təmizlə"),
                                     qsTr("Bütün missiya elementlərini silmək və missiyanı təyyarədən təmizləmək istədiyinizə əminsiniz?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() {
                                         _planMasterController.removeAllFromVehicle();
                                         _missionController.setCurrentPlanViewSeqNum(0, true);
                                         if(_utmspEnabled) {
                                             _resetRegisterFlightPlan = true;
                                             QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(false);
                                             UTMSPStateStorage.startTimeStamp = "";
                                             UTMSPStateStorage.showActivationTab = false;
                                             UTMSPStateStorage.flightID = "";
                                             UTMSPStateStorage.enableMissionUploadButton = false;
                                             UTMSPStateStorage.indicatorPendingStatus = true;
                                             UTMSPStateStorage.indicatorApprovedStatus = false;
                                             UTMSPStateStorage.indicatorActivatedStatus = false;
                                             UTMSPStateStorage.currentStateIndex = 0
                                         }
                                     })
    }

    Component {
        id: centerMapDropPanel
        CenterMapDropPanel {
            map:            editorMap
            fitFunctions:   mapFitFunctions
        }
    }

    Component {
        id: patternDropPanel

        // Rows of the top bar's window menu: a faint tint on hover, the side menu's
        // selected box while pressed.
        Column {
            id:      patternPanel
            width:   AzTheme.px(260)
            spacing: AzTheme.px(4)

            Text {
                width:          parent.width
                bottomPadding:  AzTheme.px(6)
                text:           qsTr("Kompleks nümunə yaradın")
                color:          AzTheme.textCard
                font.family:    AzTheme.fontFamily
                font.weight:    Font.Medium
                font.pixelSize: AzTheme.fontPx(AzTheme.popupTitleSize - 2)
                wrapMode:       Text.WordWrap
            }

            Rectangle {
                width:  parent.width
                height: 1
                color:  AzTheme.panelBorder
            }

            Item { width: 1; height: AzTheme.px(2) }

            Repeater {
                model: _missionController.complexMissionItemNames

                Item {
                    width:  patternPanel.width
                    height: AzTheme.px(40)

                    Rectangle {
                        anchors.fill: parent
                        radius:       AzTheme.px(AzTheme.menuSelectedRadius)
                        visible:      patternMouseArea.pressed
                        border.width: 1
                        border.color: AzTheme.menuSelectedBorder
                        gradient: Gradient {
                            GradientStop { position: 0; color: AzTheme.menuSelectedTop }
                            GradientStop { position: 1; color: AzTheme.menuSelectedBottom }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius:       AzTheme.px(AzTheme.menuSelectedRadius)
                        visible:      patternMouseArea.containsMouse && !patternMouseArea.pressed
                        color:        Qt.rgba(1, 1, 1, 0.06)
                    }

                    QGCColoredImage {
                        id:                     patternIcon
                        anchors.left:           parent.left
                        anchors.leftMargin:     AzTheme.px(10)
                        anchors.verticalCenter: parent.verticalCenter
                        width:                  AzTheme.px(18)
                        height:                 width
                        sourceSize.height:      height
                        fillMode:               Image.PreserveAspectFit
                        source:                 "qrc:/res/AZSHIELD_ICON/v2/plan_pattern.svg"
                        color:                  AzTheme.textSecondary
                    }

                    Text {
                        anchors.left:           patternIcon.right
                        anchors.leftMargin:     AzTheme.px(10)
                        anchors.right:          parent.right
                        anchors.rightMargin:    AzTheme.px(10)
                        anchors.verticalCenter: parent.verticalCenter
                        text:                   modelData
                        color:                  AzTheme.textCard
                        font.family:            AzTheme.fontFamily
                        font.pixelSize:         AzTheme.fontPx(AzTheme.popupTextSize)
                        elide:                  Text.ElideRight
                    }

                    MouseArea {
                        id:           patternMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor

                        onClicked: {
                            insertComplexItemAfterCurrent(modelData)
                            dropPanel.hide()
                        }
                    }
                }
            }
        }
    }

    function downloadClicked(title) {
        if (_planMasterController.dirty) {
            mainWindow.showMessageDialog(title,
                                         qsTr("Yadda saxlanmamış/göndərilməyən dəyişiklikləriniz var. Təyyarədən yükləmə bu dəyişiklikləri itirəcək. Təyyarədən yükləmək istədiyinizə əminsiniz?"),
                                         Dialog.Yes | Dialog.Cancel,
                                         function() { _planMasterController.loadFromVehicle() })
        } else {
            _planMasterController.loadFromVehicle()
        }
    }

    Component {
        id: syncDropPanel

        // The "Fayl" tool's panel: plan templates as small cards, then the file and
        // vehicle actions as rows of the top bar's window menu.
        ColumnLayout {
            id: columnHolder
            width: AzTheme.px(300)
            spacing: AzTheme.px(8)

            property string _overwriteText: qsTr("Plan overwrite")

            Rectangle {
                id: warningBackground
                Layout.fillWidth: true
                implicitHeight: warningLabel.implicitHeight + AzTheme.px(20)
                visible: _planMasterController.dirty
                radius: AzTheme.px(AzTheme.groupRadius)
                color: Qt.rgba(1, 159 / 255, 26 / 255, 0.10)
                border.width: 1
                border.color: Qt.rgba(1, 159 / 255, 26 / 255, 0.55)

                Text {
                    id: warningLabel
                    anchors.fill: parent
                    anchors.margins: AzTheme.px(10)
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    text: globals.activeVehicle ?
                          qsTr("Saxlanmamış dəyişiklikləriniz var. Siz təyyarənizə yükləməli və ya faylda saxlamalısınız.") :
                          qsTr("Saxlanmamış dəyişiklikləriniz var.")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(13)
                }
            }

            SectionHeader {
                id: createSection
                Layout.fillWidth: true
                text: qsTr("Missiyanın başlanğıcı")
                showSpacer: false
                checked: true
            }

            GridLayout {
                columns: 2
                columnSpacing: AzTheme.px(8)
                rowSpacing: AzTheme.px(8)
                Layout.fillWidth: true
                visible: createSection.checked

                Repeater {
                    model: _planMasterController.planCreators

                    Item {
                        id: creatorCard
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: AzTheme.px(150)

                        AzGradientRect {
                            anchors.fill:  parent
                            angle:         AzTheme.cardGradientAngle
                            startColor:    AzTheme.cardGradientStart
                            startPosition: AzTheme.cardGradientStartPos
                            endColor:      AzTheme.cardGradientEnd
                            endPosition:   AzTheme.cardGradientEndPos
                            radius:        AzTheme.px(10)
                            borderColor:   mouseArea.containsMouse ? AzTheme.cardHoverBorder : AzTheme.cardBorder
                            borderWidth:   1
                        }

                        Image {
                            id: planCreatorImage
                            anchors.top: parent.top
                            anchors.topMargin: AzTheme.px(8)
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - AzTheme.px(16)
                            height: AzTheme.px(96)
                            source: object.imageResource
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }

                        Text {
                            anchors.top: planCreatorImage.bottom
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: AzTheme.px(6)
                            text: object.name
                            color: mouseArea.containsMouse ? AzTheme.textPrimary : AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(13)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        QGCMouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (_planMasterController.containsItems) {
                                    createPlanRemoveAllPromptDialog.createObject(mainWindow, { mapCenter: _mapCenter(), planCreator: object }).open()
                                } else {
                                    object.createPlan(_mapCenter())
                                }
                                dropPanel.hide()
                            }

                            function _mapCenter() {
                                var centerPoint = Qt.point(
                                    editorMap.centerViewport.left + (editorMap.centerViewport.width / 2),
                                    editorMap.centerViewport.top + (editorMap.centerViewport.height / 2)
                                )
                                return editorMap.toCoordinate(centerPoint, false)
                            }
                        }
                    }
                }
            }

            SectionHeader {
                id: storageSection
                Layout.fillWidth: true
                text: qsTr("Saxlama")
                checked: false
            }

            ColumnLayout {
                spacing: AzTheme.px(2)
                Layout.fillWidth: true
                visible: storageSection.checked

                ActionRow {
                    text: qsTr("Aç...")
                    enabled: !_planMasterController.syncInProgress
                    onClicked: {
                        dropPanel.hide()
                        if (_planMasterController.dirty) {
                            showLoadFromFileOverwritePrompt(columnHolder._overwriteText)
                        } else {
                            _planMasterController.loadFromSelectedFile()
                        }
                    }
                }

                ActionRow {
                    text: qsTr("Saxla")
                    enabled: !_planMasterController.syncInProgress && _planMasterController.currentPlanFile !== ""
                    onClicked: {
                        dropPanel.hide()
                        if(_planMasterController.currentPlanFile !== "") {
                            _planMasterController.saveToCurrent()
                        } else {
                            _planMasterController.saveToSelectedFile()
                        }
                    }
                }

                ActionRow {
                    text: qsTr("Fərqli saxla...")
                    enabled: !_planMasterController.syncInProgress && _planMasterController.containsItems
                    onClicked: {
                        dropPanel.hide()
                        _planMasterController.saveToSelectedFile()
                    }
                }

                ActionRow {
                    text: qsTr("KML kimi yadda saxla...")
                    enabled: !_planMasterController.syncInProgress && _visualItems.count > 1
                    onClicked: {
                        if (_visualItems.count < 2) {
                            mainWindow.showMessageDialog(qsTr("KML"), qsTr("KML yaratmaq üçün ən azı bir missiya elementi lazımdır."))
                            return
                        }
                        dropPanel.hide()
                        _planMasterController.saveKmlToSelectedFile()
                    }
                }
            }

            SectionHeader {
                id: vehicleSection
                Layout.fillWidth: true
                text: qsTr("Təyyarə")
                checked: false
                visible: !QGroundControl.corePlugin.options.disableVehicleConnection
            }

            ColumnLayout {
                spacing: AzTheme.px(2)
                Layout.fillWidth: true
                visible: vehicleSection.checked && vehicleSection.visible

                ActionRow {
                    text: qsTr("Təyyarəyə yüklə")
                    enabled: !_planMasterController.offline && !_planMasterController.syncInProgress && _planMasterController.containsItems
                    onClicked: {
                        dropPanel.hide()
                        _planMasterController.upload()
                    }
                }

                ActionRow {
                    text: qsTr("Təyyarədən endir")
                    enabled: !_planMasterController.offline && !_planMasterController.syncInProgress
                    onClicked: {
                        dropPanel.hide()
                        downloadClicked(columnHolder._overwriteText)
                    }
                }

                ActionRow {
                    text: qsTr("Təyyarədən təmizlə")
                    enabled: !_planMasterController.offline && !_planMasterController.syncInProgress
                    onClicked: {
                        dropPanel.hide()
                        clearButtonClicked()
                    }
                }
            }
        }
    }

    Connections {
        target: utmspEditor
        function onVehicleIDSent(id) { _vehicleID = id }
    }

    Connections {
        target: utmspEditor
        function onRemoveFlightPlanTriggered() {
            _planMasterController.removeAllFromVehicle();
            _missionController.setCurrentPlanViewSeqNum(0, true);
            if(_utmspEnabled){ _resetRegisterFlightPlan = true }
        }
    }
}


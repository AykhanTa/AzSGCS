// import QtQuick
// import QtQuick.Controls
// import QtQuick.Dialogs
// import QtQuick.Layouts

// import QtLocation
// import QtPositioning
// import QtQuick.Window
// import QtQml.Models

// import QGroundControl
// import QGroundControl.Controls

// import QGroundControl.FlightDisplay
// import QGroundControl.FlightMap


// Item {
//     id: _root

//     property var    parentToolInsets
//     property var    totalToolInsets:        _totalToolInsets
//     property var    mapControl
//     property bool   isViewer3DOpen:         false

//     property Item topStatusPanelRef



//     property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
//     property var    _planMasterController:  globals.planMasterControllerFlyView
//     property var    _missionController:     _planMasterController.missionController
//     property var    _geoFenceController:    _planMasterController.geoFenceController
//     property var    _rallyPointController:  _planMasterController.rallyPointController
//     property var    _guidedController:      globals.guidedControllerFlyView
//     property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
//     property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
//     property rect   _centerViewport:        Qt.rect(0, 0, width, height)
//     property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
//     property alias  _gripperMenu:           gripperOptions
//     property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
//     property real   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
//     property bool   _showSingleVehicleUI:   true

//     property bool utmspActTrigger

//     QGCToolInsets {
//         id:                     _totalToolInsets
//         leftEdgeTopInset:       toolStrip.leftEdgeTopInset
//         leftEdgeCenterInset:    toolStrip.leftEdgeCenterInset
//         leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
//         // rightEdgeTopInset:      topRightPanel.rightEdgeTopInset
//         // rightEdgeCenterInset:   topRightPanel.rightEdgeCenterInset
// //        rightEdgeBottomInset:   bottomRightRowLayout.rightEdgeBottomInset
//         topEdgeLeftInset:       toolStrip.topEdgeLeftInset
//         topEdgeCenterInset:     mapScale.topEdgeCenterInset
//        // topEdgeRightInset:      topRightPanel.topEdgeRightInset
//         bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
//        // bottomEdgeCenterInset:  bottomRightRowLayout.bottomEdgeCenterInset
//        // bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : bottomRightRowLayout.bottomEdgeRightInset
//         // TOP-RIGHT artıq sənin stack-dir
//            rightEdgeTopInset:    bottomRightRowLayout.visible ? (bottomRightRowLayout.width * bottomRightRowLayout.scale + _layoutMargin) : 0
//            rightEdgeCenterInset: rightEdgeTopInset
//            topEdgeRightInset:    bottomRightRowLayout.visible ? (bottomRightRowLayout.height * bottomRightRowLayout.scale + _layoutMargin) : 0

//            // bottomEdgeCenterInset/bottomEdgeRightInset stack-dən gəlməsin
//            bottomEdgeCenterInset: parentToolInsets.bottomEdgeCenterInset
//            bottomEdgeRightInset:  virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : parentToolInsets.bottomEdgeRightInset

//            // rightEdgeBottomInset də bottom widget-dən gəlməlidir
//            rightEdgeBottomInset:  virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.rightEdgeBottomInset : 0

//     }

//     FlyViewTopRightPanel {
//         id:                     topRightPanel
//         anchors.top:            parent.top
//         anchors.right:          parent.right
//         anchors.topMargin:      _layoutMargin
//         anchors.rightMargin:    _layoutMargin
//         maximumHeight:          parent.height - (bottomRightRowLayout.height + _margins * 5)

//         property real topEdgeRightInset:    height + _layoutMargin
//         property real rightEdgeTopInset:    width + _layoutMargin
//         property real rightEdgeCenterInset: rightEdgeTopInset
//     }

//     FlyViewTopRightColumnLayout {
//         id:                 topRightColumnLayout
//         anchors.margins:    _layoutMargin
//         anchors.top:        parent.top
//         anchors.bottom:     bottomRightRowLayout.top
//         anchors.right:      parent.right
//         spacing:            _layoutSpacing
//         visible:           !topRightPanel.visible

//         property real topEdgeRightInset:    childrenRect.height + _layoutMargin
//         property real rightEdgeTopInset:    width + _layoutMargin
//         property real rightEdgeCenterInset: rightEdgeTopInset
//     }
// ////////////////compass
//     // FlyViewBottomRightRowLayout {
//     //     id:                 bottomRightRowLayout
//     //     anchors.margins:    _layoutMargin
//     //     anchors.bottom:     parent.bottom
//     //     anchors.right:      parent.right
//     //     spacing:            _layoutSpacing

//     //     property real bottomEdgeRightInset:     height + _layoutMargin
//     //     property real bottomEdgeCenterInset:    bottomEdgeRightInset
//     //     property real rightEdgeBottomInset:     width + _layoutMargin
//     // }

//     FlyViewBottomRightRowLayout {
//             id:                 bottomRightRowLayout
//             anchors.margins:    _layoutMargin
//             anchors.top:     parent.top
//             anchors.right:     parent.right
//             anchors.rightMargin: 1
//             spacing:            _layoutSpacing

//             transform: Translate {
//                 // y: -150 // 🔥 150px YUKARI KAYDIR
//             }


//             property real bottomEdgeRightInset:     height + _layoutMargin
//             property real bottomEdgeCenterInset:    bottomEdgeRightInset
//             property real rightEdgeBottomInset:     width + _layoutMargin
//             // Rectangle {
//             //     anchors.fill: parent
//             //     // color: "red" // İstediğiniz renk
//             //     z: -1 // Diğer widget'ların arkasında kalması için
//             // }

//         }

//     // FlyViewBottomRightRowLayout {
//     //     id: bottomRightRowLayout

//     //     anchors.top: parent.top
//     //     anchors.right: parent.right
//     //     anchors.margins: _layoutMargin

//     //     // Top-right-a “kilidlə” və ekrana sığdır
//     //     transformOrigin: Item.TopRight

//     //     readonly property real _availW: parent.width  - (2 * anchors.margins)
//     //     readonly property real _availH: parent.height - (2 * anchors.margins)

//     //     // “istənən” ölçü = implicit ölçü
//     //     readonly property real _sW: _availW / Math.max(1, implicitWidth)
//     //     readonly property real _sH: _availH / Math.max(1, implicitHeight)

//     //     // Hədd: istəsən minimum scale qoy (məs: 0.65)
//     //     scale: Math.min(1.0, _sW, _sH)
//     // }



//     FlyViewMissionCompleteDialog {
//         missionController:      _missionController
//         geoFenceController:     _geoFenceController
//         rallyPointController:   _rallyPointController
//     }

//     GuidedActionConfirm {
//         anchors.margins:            _toolsMargin
//         anchors.top:                parent.top
//         anchors.horizontalCenter:   parent.horizontalCenter
//         z:                          QGroundControl.zOrderTopMost
//         guidedController:           _guidedController
//         guidedValueSlider:          _guidedValueSlider
//         utmspSliderTrigger:         utmspActTrigger
//     }

//     //-- Virtual Joystick
//     Loader {
//         id:                         virtualJoystickMultiTouch
//         z:                          QGroundControl.zOrderTopMost + 1
//         anchors.right:              parent.right
//         anchors.rightMargin:        anchors.leftMargin
//         height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
//         visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
//         anchors.bottom:             parent.bottom
//         anchors.bottomMargin:       bottomLoaderMargin
//         anchors.left:               parent.left
//         anchors.leftMargin:         ( y > toolStrip.y + toolStrip.height ? toolStrip.width / 2 : toolStrip.width * 1.05 + toolStrip.x)
//         source:                     "qrc:/qml/QGroundControl/FlightDisplay/VirtualJoystick.qml"
//         active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

//         property real bottomEdgeLeftInset:     parent.height-y
//         property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
//         property bool leftHandedMode:          QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
//         property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
//         property real bottomEdgeRightInset:    parent.height-y
//         property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 :
//                                                bottomRightRowLayout.height + ScreenTools.defaultFontPixelHeight * 1.5

//         property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin

//         // Width is difficult to access directly hence this hack which may not work in all circumstances
//         property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
//         property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
//         property real rootWidth:            _root.width
//         property var  itemX:                virtualJoystickMultiTouch.x   // real X on screen

//         onRootWidthChanged: virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth : undefined
//         onItemXChanged:     virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiRealX = itemX : undefined

//         //Loader status logic
//         onLoaded: {
//             if (virtualJoystickMultiTouch.visible) {
//                 virtualJoystickMultiTouch.item.calibration = true
//                 virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth
//                 virtualJoystickMultiTouch.item.uiRealX = itemX
//             } else {
//                 virtualJoystickMultiTouch.item.calibration = false
//             }
//         }
//     }

//     // FlyViewToolStrip {
//     //     id:                     toolStrip
//     //     anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
//     //     anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
//     //     anchors.left:           parent.left
//     //     anchors.top:            parent.top
//     //     z:                      QGroundControl.zOrderWidgets
//     //     maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
//     //     visible:                !QGroundControl.videoManager.fullScreen

//     //     onDisplayPreFlightChecklist: {
//     //         if (!preFlightChecklistLoader.active) {
//     //             preFlightChecklistLoader.active = true
//     //         }
//     //         preFlightChecklistLoader.item.open()
//     //     }

//     //     property real topEdgeLeftInset:     visible ? y + height : 0
//     //     property real leftEdgeTopInset:     visible ? x + width : 0
//     //     property real leftEdgeCenterInset:  leftEdgeTopInset
//     // }

//     // FlyViewToolStrip {
//     //             id:                     toolStrip
//     //             anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
//     //             anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
//     //             anchors.right:           parent.right
//     //             anchors.bottom:            parent.bottom
//     //             anchors.bottomMargin:   270
//     //             z:                      QGroundControl.zOrderWidgets
//     //             //maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
//     //             height: 120
//     //             width: 270
//     //             visible:                !QGroundControl.videoManager.fullScreen && mainWindow.isFlyViewActive

//     //             onDisplayPreFlightChecklist: {
//     //                 if (!preFlightChecklistLoader.active) {
//     //                     preFlightChecklistLoader.active = true
//     //                 }
//     //                 preFlightChecklistLoader.item.open()
//     //             }

//     //             property real topEdgeLeftInset:     visible ? y + height : 0
//     //             property real leftEdgeTopInset:     visible ? x + width : 0
//     //             property real leftEdgeCenterInset:  leftEdgeTopInset
//     //         }

//     GripperMenu {
//         id: gripperOptions
//     }

//     VehicleWarnings {
//         anchors.centerIn:   parent
//         z:                  QGroundControl.zOrderTopMost
//     }

//     // MapScale {
//     //     id:                 mapScale
//     //     anchors.margins:    _toolsMargin
//     //     anchors.left:       toolStrip.right
//     //     anchors.top:        parent.top
//     //     mapControl:         _mapControl
//     //     buttonsOnLeft:      true
//     //     visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

//     //     property real topEdgeCenterInset: visible ? y + height : 0
//     // }
//     MapScale {
//         id: mapScale

//         readonly property real _topBottomY: (_root.topStatusPanelRef && _root.topStatusPanelRef.visible)
//             ? _root.topStatusPanelRef.mapToItem(_root, 0, _root.topStatusPanelRef.height).y
//             : 0

//         // ✅ toolStrip sağ kənarı (_root koordinatında)
//         readonly property real _toolRightX: (toolStrip && toolStrip.visible)
//             ? toolStrip.mapToItem(_root, toolStrip.width, 0).x
//             : 0

//         property real extraYOffset: ScreenTools.defaultFontPixelHeight * 0.8
//         property real extraXOffset: ScreenTools.defaultFontPixelWidth * 1

//         x: _toolRightX + _toolsMargin + extraXOffset
//         y: _topBottomY + _toolsMargin + extraYOffset

//         z: QGroundControl.zOrderTopMost

//         mapControl: _mapControl
//         buttonsOnLeft: true
//         visible: !ScreenTools.isTinyScreen
//                  && QGroundControl.corePlugin.options.flyView.showMapScale
//                  && !isViewer3DOpen
//                  && mapControl.pipState.state === mapControl.pipState.fullState

//         property real topEdgeCenterInset: visible ? y + height : 0
//     }





//     Loader {
//         id: preFlightChecklistLoader
//         sourceComponent: preFlightChecklistPopup
//         active: false
//     }

//     Component {
//         id: preFlightChecklistPopup
//         FlyViewPreFlightChecklistPopup {
//         }
//     }
// }









//-----------androidkod----------
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls

import QGroundControl.FlightDisplay
import QGroundControl.FlightMap

Item {
    id: _root

    property var    parentToolInsets
    property var    totalToolInsets: _totalToolInsets
    property var    mapControl
    property bool   isViewer3DOpen: false
    property Item   topStatusPanelRef

    // ✅ compact UI threshold
    readonly property bool _compactUi: (_root.width < 1200 || _root.height < 700)

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property alias  _gripperMenu:           gripperOptions
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property real   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true

    property bool utmspActTrigger

    // ✅ Kiçik ekranda soldakı toolstrip insets verir
    QGCToolInsets {
        id: _totalToolInsets

        leftEdgeTopInset:       toolStrip.visible ? toolStrip.leftEdgeTopInset    : (parentToolInsets ? parentToolInsets.leftEdgeTopInset    : 0)
        leftEdgeCenterInset:    toolStrip.visible ? toolStrip.leftEdgeCenterInset : (parentToolInsets ? parentToolInsets.leftEdgeCenterInset : 0)
        topEdgeLeftInset:       toolStrip.visible ? toolStrip.topEdgeLeftInset    : (parentToolInsets ? parentToolInsets.topEdgeLeftInset    : 0)

        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible
                                ? virtualJoystickMultiTouch.leftEdgeBottomInset
                                : (parentToolInsets ? parentToolInsets.leftEdgeBottomInset : 0)

        topEdgeCenterInset:     mapScale.topEdgeCenterInset

        // ✅ Sağ tərəf overlay stack (compass + telemetry bar)
        rightEdgeTopInset:      bottomRightRowLayout.visible ? (bottomRightRowLayout.width  * bottomRightRowLayout.scale + _layoutMargin) : 0
        rightEdgeCenterInset:   rightEdgeTopInset
        topEdgeRightInset:      bottomRightRowLayout.visible ? (bottomRightRowLayout.height * bottomRightRowLayout.scale + _layoutMargin) : 0

        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible
                                ? virtualJoystickMultiTouch.bottomEdgeLeftInset
                                : (parentToolInsets ? parentToolInsets.bottomEdgeLeftInset : 0)

        bottomEdgeCenterInset:  parentToolInsets ? parentToolInsets.bottomEdgeCenterInset : 0
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible
                                ? virtualJoystickMultiTouch.bottomEdgeRightInset
                                : (parentToolInsets ? parentToolInsets.bottomEdgeRightInset : 0)

        rightEdgeBottomInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.rightEdgeBottomInset : 0
    }

    FlyViewTopRightPanel {
        id:                     topRightPanel
        anchors.top:            parent.top
        anchors.right:          parent.right
        anchors.topMargin:      _layoutMargin
        anchors.rightMargin:    _layoutMargin
        maximumHeight:          parent.height - (bottomRightRowLayout.height + _margins * 5)

        property real topEdgeRightInset:    height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewTopRightColumnLayout {
        id:                 topRightColumnLayout
        anchors.margins:    _layoutMargin
        // anchors.top:        parent.top
        // anchors.bottom:     bottomRightRowLayout.top
        anchors.top:        bottomRightRowLayout.bottom
        anchors.right:      parent.right
        spacing:            _layoutSpacing
        visible:           !topRightPanel.visible

        property real topEdgeRightInset:    childrenRect.height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    // ✅ Sağ stack: Compass + TelemetryValuesBar (+ böyük ekranda ToolStripRight)
    FlyViewBottomRightRowLayout {
        id:                 bottomRightRowLayout
        anchors.right:      parent.right
        anchors.top:        parent.top
        //anchors.rightMargin:_layoutMargin
        anchors.rightMargin: 0
        anchors.topMargin:  (topStatusPanelRef && topStatusPanelRef.visible)
                            ? (topStatusPanelRef.height + _layoutMargin)
                            : _layoutMargin

        spacing:            _layoutSpacing
        transformOrigin:    Item.TopRight

        // ✅ Kiçik ekranda sağdakı ToolStripRight GİZLƏNSİN
        showRightToolStrip: !_compactUi

        readonly property real _availW: _root.width  - (_layoutMargin * 2)
        readonly property real _availH: _root.height - (_layoutMargin * 2)
                                       - ((topStatusPanelRef && topStatusPanelRef.visible) ? topStatusPanelRef.height : 0)

        readonly property real _iw: Math.max(1, (implicitWidth  > 0) ? implicitWidth  : childrenRect.width)
        readonly property real _ih: Math.max(1, (implicitHeight > 0) ? implicitHeight : childrenRect.height)

        readonly property real _sW: _availW / _iw
        readonly property real _sH: _availH / _ih

        // ✅ Kiçik ekranda daha çox kiçilə bilsin ki, TELEMETRY BAR aşağıya yapışmasın
        readonly property real _minScale: _compactUi ? 0.68 : 0.80
        scale: Math.max(_minScale, Math.min(1.0, _sW, _sH))

        property real bottomEdgeRightInset:     height * scale + _layoutMargin
        property real bottomEdgeCenterInset:    bottomEdgeRightInset
        property real rightEdgeBottomInset:     width  * scale + _layoutMargin
    }

    // ✅ Kiçik ekranda solda column toolstrip (SideMenu enindən sonra başlayır)
    FlyViewToolStrip {
        id: toolStrip
        z: QGroundControl.zOrderWidgets

        visible: _compactUi
                 && !QGroundControl.videoManager.fullScreen
                 && mainWindow.isFlyViewActive

        verticalMode: true

        // ✅ eni bir az da dar
        width: Math.max(88, ScreenTools.defaultFontPixelHeight * 5.2)

        anchors.left: parent.left
        anchors.top: parent.top

        anchors.leftMargin: (parentToolInsets ? parentToolInsets.leftEdgeCenterInset : 0) + _layoutMargin
        anchors.topMargin:  (topStatusPanelRef && topStatusPanelRef.visible)
                            ? (topStatusPanelRef.height + _layoutMargin)
                            : _layoutMargin

        // ✅ hündürlük kontentə görə + lazım olsa scroll üçün cap
        readonly property real _maxH: _root.height
                                      - anchors.topMargin
                                      - ((parentToolInsets ? parentToolInsets.bottomEdgeLeftInset : 0) + _layoutMargin)

        height: Math.min(implicitHeight, Math.max(120, _maxH))
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    GuidedActionConfirm {
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
        utmspSliderTrigger:         utmspActTrigger
    }

    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        anchors.right:              parent.right
        anchors.rightMargin:        anchors.leftMargin
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       bottomLoaderMargin
        anchors.left:               parent.left
        anchors.leftMargin:         ( y > toolStrip.y + toolStrip.height ? toolStrip.width / 2 : toolStrip.width * 1.05 + toolStrip.x)
        source:                     "qrc:/qml/QGroundControl/FlightDisplay/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property real bottomEdgeLeftInset:     parent.height-y
        property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool leftHandedMode:          QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
        property real bottomEdgeRightInset:    parent.height-y
        property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 :
                                               bottomRightRowLayout.height + ScreenTools.defaultFontPixelHeight * 1.5

        property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin

        property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rootWidth:            _root.width
        property var  itemX:                virtualJoystickMultiTouch.x

        onRootWidthChanged: virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth : undefined
        onItemXChanged:     virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiRealX = itemX : undefined

        onLoaded: {
            if (virtualJoystickMultiTouch.visible) {
                virtualJoystickMultiTouch.item.calibration = true
                virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth
                virtualJoystickMultiTouch.item.uiRealX = itemX
            } else {
                virtualJoystickMultiTouch.item.calibration = false
            }
        }
    }

    GripperMenu { id: gripperOptions }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    // ✅ MapScale: soldakı toolstrip varsa onun sağından, yoxdursa sideMenu inset-dən
    MapScale {
        id: mapScale

        readonly property real _topBottomY: (_root.topStatusPanelRef && _root.topStatusPanelRef.visible)
            ? _root.topStatusPanelRef.mapToItem(_root, 0, _root.topStatusPanelRef.height).y
            : 0

        readonly property real _leftInsetX: (parentToolInsets ? parentToolInsets.leftEdgeCenterInset : 0)

        readonly property real _toolRightX: (toolStrip && toolStrip.visible)
            ? toolStrip.mapToItem(_root, toolStrip.width, 0).x
            : _leftInsetX

        property real extraYOffset: ScreenTools.defaultFontPixelHeight * 0.8
        property real extraXOffset: ScreenTools.defaultFontPixelWidth * 1

        x: _toolRightX + _toolsMargin + extraXOffset
        y: _topBottomY + _toolsMargin + extraYOffset

        z: QGroundControl.zOrderTopMost

        mapControl: _mapControl
        buttonsOnLeft: true
        visible: !ScreenTools.isTinyScreen
                 && QGroundControl.corePlugin.options.flyView.showMapScale
                 && !isViewer3DOpen
                 && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Loader {
        id: preFlightChecklistLoader
        sourceComponent: preFlightChecklistPopup
        active: false
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup { }
    }
}




// Item {
//     id: _root

//     property var    parentToolInsets
//     property var    totalToolInsets:        _totalToolInsets
//     property var    mapControl
//     property bool   isViewer3DOpen:         false

//     property Item topStatusPanelRef










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
        // The column needs the same margin every other edge element gets, and for
        // two reasons beyond tidiness: the dial paints its N/E/S/W letters centred
        // on the rim, so half of each glyph falls outside the ring and the E was
        // clipped by the screen, and the telemetry bar lost its right border.
        anchors.rightMargin: _root._layoutMargin
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

    // Skydroid pod shortcuts down the right edge, like Skydroid's own ground station.
    // They sit under whatever the compass/telemetry stack is drawing, and only move to
    // its left when even the smallest buttons would not fit beneath it.
    SkydroidGimbalShortcuts {
        id:                     skydroidShortcuts
        z:                      QGroundControl.zOrderWidgets
        anchors.right:          parent.right
        anchors.rightMargin:    _besideStack ? (_totalToolInsets.rightEdgeCenterInset + _margin) : _margin

        readonly property real _margin:     _root._layoutMargin
        readonly property real _topInset:   (_root.topStatusPanelRef && _root.topStatusPanelRef.visible) ? _root.topStatusPanelRef.height : 0
        readonly property var  _settings:   QGroundControl.settingsManager.skydroidGimbalSettings

        // The instrument panel keeps its size with no vehicle but draws nothing, so the
        // stack only counts once it has something to show.
        readonly property bool _stackShowing: bottomRightRowLayout.visible && (!!_root._activeVehicle || mainWindow.showFlightPanel)
        readonly property real _stackBottom:  _stackShowing ? (bottomRightRowLayout.y + (bottomRightRowLayout.height * bottomRightRowLayout.scale)) : _topInset
        readonly property real _roomBelow:    _root.height - _stackBottom - (_margin * 2)
        readonly property bool _besideStack:  _roomBelow < minimumHeight

        availableHeight: _besideStack ? (_root.height - _topInset - (_margin * 2)) : _roomBelow
        y:               (_besideStack ? (_topInset + _margin) : (_stackBottom + _margin)) + ((availableHeight - height) / 2)
        // This layer only exists on the fly view, so the pod being enabled is what shows
        // them. They step aside while the flight panel is open rather than squeeze in
        // next to its compass and telemetry.
        visible:         _settings.enabled.rawValue && !mainWindow.showFlightPanel
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


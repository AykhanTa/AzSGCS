/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls

// The panel a tool of the Plan view's strip opens (Fayl, Pattern, Mərkəz): a card of the
// top bar panels just right of the strip, level with its tool and kept on the map.
Item {
    id:         _root
    visible:    false

    signal          clicked()
    property var    toolStrip

    readonly property real _dropMargin: AzTheme.px(14)
    readonly property real _mapGap:     AzTheme.px(8)

    property var    _dropEdgeTopPoint
    property alias  _dropDownComponent: panelLoader.sourceComponent
    property real   _viewportMaxTop:    _mapGap
    property real   _viewportMaxBottom: parent.parent.height - parent.y - _mapGap
    property real   _viewportMaxHeight: _viewportMaxBottom - _viewportMaxTop
    property var    _dropPanelCancel
    property var    _parentButton

    function show(panelEdgeTopPoint, panelComponent, parentButton) {
        _parentButton = parentButton
        _dropEdgeTopPoint = panelEdgeTopPoint
        _dropDownComponent = panelComponent
        _calcPositions()
        visible = true
        _dropPanelCancel = dropPanelCancelComponent.createObject(toolStrip.parent)
    }

    function hide() {
        if (_dropPanelCancel) {
            _dropPanelCancel.destroy()
            _parentButton.checked = false
            visible = false
            _dropDownComponent = undefined
        }
    }

    function _calcPositions() {
        if (!panelLoader.item || !_dropEdgeTopPoint) {
            return
        }

        dropDownItem.width  = panelLoader.item.width  + (_dropMargin * 2)
        dropDownItem.height = panelLoader.item.height + (_dropMargin * 2)

        // Right of the strip, centred on the tool that opened it
        var buttonHeight = _parentButton ? _parentButton.height : 0
        dropDownItem.x = Math.min(toolStrip.width + _mapGap, toolStrip.parent.width - dropDownItem.width - _mapGap)
        dropDownItem.y = _dropEdgeTopPoint.y + (buttonHeight / 2) - (dropDownItem.height / 2)

        // Kept inside the map, and no taller than it
        dropDownItem.y = Math.min(dropDownItem.y + dropDownItem.height, _viewportMaxBottom) - dropDownItem.height
        dropDownItem.y = Math.max(dropDownItem.y, _viewportMaxTop)
        dropDownItem.height = Math.min(dropDownItem.height, _viewportMaxBottom - dropDownItem.y)
    }

    Component {
        // Overlay which is used to cancel the panel when the user clicks away
        id: dropPanelCancelComponent

        MouseArea {
            anchors.fill:   parent
            z:              toolStrip.z - 1
            onClicked:      _root.hide()
        }
    }

    Item {
        id: dropDownItem

        RectangularShadow {
            anchors.fill: cardBackground
            offset.y:     AzTheme.px(12)
            blur:         AzTheme.px(32)
            radius:       cardBackground.radius
            color:        AzTheme.popupShadow
        }

        AzGradientRect {
            id:            cardBackground
            anchors.fill:  parent
            angle:         AzTheme.panelGradientAngle
            startColor:    AzTheme.panelGradientStart
            startPosition: AzTheme.panelGradientStartPos
            endColor:      AzTheme.panelGradientEnd
            endPosition:   AzTheme.panelGradientEndPos
            radius:        AzTheme.px(AzTheme.popupRadius)
            borderColor:   AzTheme.panelBorder
            borderWidth:   1
        }

        DeadMouseArea {
            anchors.fill: parent
        }

        QGCFlickable {
            id:                 panelItemFlickable
            anchors.margins:    _dropMargin
            anchors.fill:       parent
            flickableDirection: Flickable.VerticalFlick
            contentWidth:       panelLoader.width
            contentHeight:      panelLoader.height
            clip:               true

            Loader {
                id: panelLoader

                onHeightChanged:    _calcPositions()
                onWidthChanged:     _calcPositions()

                property var dropPanel: _root
            }
        }
    }
}

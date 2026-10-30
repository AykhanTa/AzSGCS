import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls

// Top bar of the Plan view, on the fly view's top bar: the 155deg panel gradient, 64 px
// high, with its shadow on the map. A home card at the left goes back to the fly view.
Item {
    id: _root
    width: parent.width
    height: AzTheme.px(64)

    property var planMasterController

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _controllerProgressPct: planMasterController.missionController.progressPct

    readonly property real _padH: AzTheme.px(12)

    QGCPalette { id: qgcPal }

    RectangularShadow {
        anchors.fill: barBackground
        offset.y:     AzTheme.px(8)
        blur:         AzTheme.px(16)
        color:        AzTheme.topBarShadow
    }

    AzGradientRect {
        id:            barBackground
        anchors.fill:  parent
        angle:         AzTheme.panelGradientAngle
        startColor:    AzTheme.panelGradientStart
        startPosition: AzTheme.panelGradientStartPos
        endColor:      AzTheme.panelGradientEnd
        endPosition:   AzTheme.panelGradientEndPos
    }

    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          AzTheme.panelBorder
    }

    // Back to the fly view, on the status card style.
    Item {
        id:                     homeButton
        anchors.left:           parent.left
        anchors.leftMargin:     _root._padH
        anchors.verticalCenter: parent.verticalCenter
        width:                  AzTheme.px(44)
        height:                 width

        AzGradientRect {
            anchors.fill:  parent
            angle:         AzTheme.cardGradientAngle
            startColor:    homeMouse.pressed ? AzTheme.menuSelectedTop : AzTheme.cardGradientStart
            startPosition: AzTheme.cardGradientStartPos
            endColor:      homeMouse.pressed ? AzTheme.menuSelectedBottom : AzTheme.cardGradientEnd
            endPosition:   AzTheme.cardGradientEndPos
            radius:        AzTheme.px(10)
            borderColor:   homeMouse.containsMouse ? AzTheme.cardHoverBorder : AzTheme.cardBorder
            borderWidth:   1
        }

        QGCColoredImage {
            anchors.centerIn:  parent
            width:             AzTheme.px(22)
            height:            width
            sourceSize.height: height
            fillMode:          Image.PreserveAspectFit
            source:            "qrc:/res/AZSHIELD_ICON/v2/menu_home.svg"
            color:             AzTheme.textCard
        }

        MouseArea {
            id:           homeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked: {
                if (mainWindow.allowViewSwitch()) {
                    mainWindow.showFlyView()
                }
            }
        }

        ToolTip.visible: homeMouse.containsMouse
        ToolTip.text:    qsTr("Ana Səhifə")
        ToolTip.delay:   400
    }

    QGCFlickable {
        id: toolsFlickable
        anchors.left: homeButton.right
        anchors.leftMargin: _root._padH
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        anchors.right: parent.right
        contentWidth: toolIndicators.width + _root._padH
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        PlanToolBarIndicators {
            id: toolIndicators
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            planMasterController: _root.planMasterController
        }
    }

    // Small mission download progress bar
    Rectangle {
        id: progressBar
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: Math.max(2, AzTheme.px(3))
        width: _controllerProgressPct * parent.width
        color: AzTheme.statusGreen
        visible: false

        onVisibleChanged: {
            if (visible) {
                largeProgressBar._userHide = false
            }
        }
    }

    // Large mission download progress bar
    Rectangle {
        id: largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height
        color: qgcPal.window
        visible: _showLargeProgress

        property bool _userHide: false
        property bool _showLargeProgress: progressBar.visible && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: _controllerProgressPct * parent.width
            color: qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn: parent
            text: qsTr("Syncing Mission")
            font.pointSize: ScreenTools.largeFontPointSize
            visible: _controllerProgressPct !== 1
        }

        QGCLabel {
            anchors.centerIn: parent
            text: qsTr("Done")
            font.pointSize: ScreenTools.largeFontPointSize
            visible: _controllerProgressPct === 1
        }

        QGCLabel {
            anchors.margins: _margin
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: qsTr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill: parent
            onClicked: largeProgressBar._userHide = true
        }
    }

    // Progress bar
    Connections {
        target: planMasterController.missionController

        function onProgressPctChanged(progressPct) {
            if (progressPct === 1) {
                if (_root.visible) {
                    resetProgressTimer.start()
                } else {
                    progressBar.visible = false
                }
            } else if (progressPct > 0) {
                progressBar.visible = true
            }
        }
    }

    Timer {
        id: resetProgressTimer
        interval: 3000
        onTriggered: progressBar.visible = false
    }
}

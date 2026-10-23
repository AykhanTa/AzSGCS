





//-------------------------------androidkod------------------



import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.Controls

Item {
    id: control

    property real extraWidth: 0

    property alias factValueGrid:          factValueGrid
    property alias settingsGroup:          factValueGrid.settingsGroup
    property alias specificVehicleForCard: factValueGrid.specificVehicleForCard

    // Card padding of the design (282 px card, 20 px sides)
    readonly property real _toolsMargin: AzTheme.px(20)

    // ✅ parent.width istifadə etmə (binding loop yarada bilər)
    readonly property real _windowW: (control.window && control.window.width > 0) ? control.window.width : Screen.width

    // Panel width clamp
    readonly property real _targetW:  AzTheme.px(282) + extraWidth
    readonly property real _minW:     240
    readonly property real _maxW:     Math.max(_minW,
                                              Math.min(ScreenTools.defaultFontPixelHeight * 26.0,
                                                       _windowW - (_toolsMargin * 2)))
    readonly property real _panelW:   Math.max(_minW, Math.min(_maxW, _targetW))

    width:         _panelW
    implicitWidth: width

    implicitHeight: mainLayout.implicitHeight + (_toolsMargin * 2)
    height:         implicitHeight

    // ✅ Outer yerləşdirmə yoxdur (anchors YOXDUR) — parent idarə edəcək
    clip: true

    AzGradientRect {
        id:            backgroundRect
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

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: _toolsMargin
        spacing: AzTheme.px(12)

        // Lock icon row (unlock olanda görünür)
        RowLayout {
            Layout.fillWidth: true
            visible: factValueGrid.settingsUnlocked

            Item { Layout.fillWidth: true }

            QGCColoredImage {
                source:             "qrc:/InstrumentValueIcons/lock-open.svg"
                mipmap:             true
                width:              ScreenTools.minTouchPixels * 0.75
                height:             width
                sourceSize.width:   width
                fillMode:           Image.PreserveAspectFit
                color:              AzTheme.textCard

                QGCMouseArea {
                    anchors.fill:    parent
                    preventStealing: true
                    cursorShape:     Qt.PointingHandCursor
                    onClicked:       factValueGrid.settingsUnlocked = false
                }
            }
        }

        HorizontalFactValueGrid {
            id: factValueGrid
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight

            // Grid panelin daxilində daşmasın
            availableWidth:  mainLayout.width
            availableHeight: (control.height - (_toolsMargin * 2))
        }
    }

    // Sağ klik/press&hold unlock — bütün paneldə işləsin
    QGCMouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        visible: !factValueGrid.settingsUnlocked

        onClicked: (mouse) => {
            if (!ScreenTools.isMobile && mouse.button === Qt.RightButton) {
                factValueGrid.settingsUnlocked = true
                mouse.accepted = true
            } else {
                // Sol kliki altdaki MouseArea-ya ötür (məs. MultiVehicleList kart seçimi)
                mouse.accepted = false
            }
        }

        onPressAndHold: (mouse) => {
            factValueGrid.settingsUnlocked = true
            mouse.accepted = true
        }
    }
}









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

    // Panelin daxili padding-i
    readonly property real _toolsMargin: Math.max(6, ScreenTools.defaultFontPixelWidth * 0.75)

    // ✅ parent.width istifadə etmə (binding loop yarada bilər)
    readonly property real _windowW: (control.window && control.window.width > 0) ? control.window.width : Screen.width

    // Panel width clamp
    readonly property real _targetW:  (ScreenTools.defaultFontPixelHeight * 17.1) + extraWidth
    readonly property real _minW:     Math.max(240, ScreenTools.defaultFontPixelHeight * 14.5)
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

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: "#3D3B3B"
        border.color: "white"
        border.width: 1
        radius: 3
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: _toolsMargin
        spacing: Math.max(6, ScreenTools.defaultFontPixelWidth * 0.75)

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
                color:              qgcPal.text

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

    QGCPalette { id: qgcPal; colorGroupEnabled: true }
}



import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.Controls 1.0

Item {
    id: page
    anchors.fill: parent

    // Loader-dən gəlir
    property var  goBack
    property bool showPanel: false

    signal cancelClicked()
    signal nextClicked()

    // Fayl yolları (səndəki kimi)
    property string imageDir: "file:///C:/Users/user/qgroundcontrol/resources/AZSHIELD_ICON/"
    property string backIconSource: imageDir + "back_.svg"

    // Demo progress
    property real progressValue: 0
    property int  completedCount: 0
    readonly property int totalOrientations: 6

    // Responsiv ölçülər
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property bool _stacked: (width < 980)  || ScreenTools.isShortScreen

    readonly property real _m:    Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.70 : 1.0))
    readonly property real _side: _stacked ? Math.max(10, _m) : Math.max(28, _m * 2.0)

    readonly property var _cards: [
        { title: "Top",        img: imageDir + "t1.png" },
        { title: "Bottom",     img: imageDir + "t2.png" },
        { title: "Left Side",  img: imageDir + "t3.png" },
        { title: "Right Side", img: imageDir + "t4.png" },
        { title: "Front",      img: imageDir + "t5.png" },
        { title: "Back",       img: imageDir + "t6.png" }
    ]

    Rectangle { anchors.fill: parent; color: "black" }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: progressValue = Math.min(progressValue + 1, 100)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: page._side
        spacing: page._m

        // Title / Subtitle
        ColumnLayout {
            Layout.fillWidth: true
            spacing: page._compact ? 2 : 6

            Text {
                text: "Accelerometer Calibration"
                color: "white"
                font.pixelSize: page._compact ? 22 : 26
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: "Calibrate the accelerometer for accurate flight control"
                color: "#E8E8E8"
                font.pixelSize: page._compact ? 13 : 16
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // Instruction
        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: "#3D3B3B"
            border.width: 1
            border.color: "#9D9D9D"
            implicitHeight: instructionText.implicitHeight + page._m * 1.6

            Text {
                id: instructionText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: page._m
                text: "Place your vehicle into one of the incomplete orientations shown below and hold it still"
                color: "#E8E8E8"
                font.pixelSize: page._compact ? 13 : 16
                font.bold: true
                wrapMode: Text.WordWrap
            }
        }

        // Progress row
        RowLayout {
            Layout.fillWidth: true
            spacing: page._m

            Text {
                text: "Progress"
                color: "white"
                font.pixelSize: page._compact ? 13 : 16
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: page.completedCount + " / " + page.totalOrientations + " orientations complete"
                color: "white"
                font.pixelSize: page._compact ? 13 : 16
                font.bold: true
            }
        }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: height / 2
            color: "#707070"

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * (page.progressValue / 100.0)
                color: "white"
            }
        }

        // ORIENTATIONS BLOCK (fill remaining height, inside scroll if needed)
        Rectangle {
            id: orientationsBlock
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: "black"
            border.width: 1
            border.color: "#9D9D9D"

            readonly property real pad: Math.max(10, page._m)
            readonly property real gap: Math.max(12, page._m)
            readonly property real ratio: 0.625   // 300/480
            readonly property real maxCardW: 520
            readonly property real minCardW: page._compact ? 200 : 240

            readonly property real innerW: Math.max(1, width  - pad * 2)
            readonly property real innerH: Math.max(1, height - pad * 2)

            // ✅ Kiçik ekranda ALT-ALTA (1 sütun)
            readonly property int cols: page._stacked ? 1 : (function() {
                var c = Math.floor((innerW + gap) / (minCardW + gap))
                c = Math.max(1, Math.min(3, c))
                return c
            })()

            readonly property int rows: Math.ceil(page.totalOrientations / cols)

            readonly property real cardW_byWidth: Math.floor((innerW - gap * (cols - 1)) / cols)
            readonly property real cardW: Math.floor(Math.min(cardW_byWidth, maxCardW))
            readonly property real cardH: Math.floor(cardW * ratio)

            readonly property real gridW: cols * cardW + gap * (cols - 1)
            readonly property real gridH: rows * cardH + gap * (rows - 1)

            QGCFlickable {
                anchors.fill: parent
                anchors.margins: orientationsBlock.pad
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                contentWidth: width
                contentHeight: Math.max(orientationsBlock.gridH, height)
                interactive: orientationsBlock.gridH > height + 2

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                Item {
                    width: parent.width
                    height: orientationsBlock.gridH

                    Flow {
                        width: orientationsBlock.gridW
                        height: orientationsBlock.gridH
                        spacing: orientationsBlock.gap
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: page._cards

                            Rectangle {
                                width: orientationsBlock.cardW
                                height: orientationsBlock.cardH
                                color: "transparent"
                                radius: 16
                                border.width: page._compact ? 4 : 6
                                border.color: "#FF0000"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Math.max(8, page._m * 0.65)
                                    spacing: Math.max(6, page._m * 0.55)

                                    Text {
                                        text: modelData.title
                                        color: "white"
                                        font.pixelSize: page._compact ? 14 : 18
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Item { Layout.fillHeight: true; Layout.fillWidth: true }

                                    Image {
                                        source: modelData.img
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        asynchronous: true
                                        mipmap: true
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: parent.width * 0.82
                                        Layout.preferredHeight: parent.height * 0.62
                                    }

                                    Item { Layout.fillHeight: true; Layout.fillWidth: true }

                                    Text {
                                        text: "Incomplete"
                                        color: "white"
                                        font.pixelSize: page._compact ? 14 : 18
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: page._m

            // Back
            Rectangle {
                Layout.preferredHeight: 48
                Layout.preferredWidth: Math.max(120, ScreenTools.defaultFontPixelWidth * 10)
                color: "#3D3B3B"
                radius: 6
                border.width: 0.5
                border.color: "#9D9D9D"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Image {
                        source: page.backIconSource
                        width: 22
                        height: 22
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        text: "Back"
                        color: "#E8E8E8"
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof page.goBack === "function") page.goBack()
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Cancel
            Rectangle {
                Layout.preferredHeight: 45
                Layout.preferredWidth: Math.max(140, ScreenTools.defaultFontPixelWidth * 12)
                color: "#3D3B3B"
                radius: 6
                border.width: 0.5
                border.color: "#9D9D9D"

                Text {
                    text: "Cancel"
                    color: "#E8E8E8"
                    anchors.centerIn: parent
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.cancelClicked()
                }
            }

            // Next
            Rectangle {
                Layout.preferredHeight: 45
                Layout.preferredWidth: Math.max(140, ScreenTools.defaultFontPixelWidth * 12)
                color: "#3D3B3B"
                radius: 6
                border.width: 0.5
                border.color: "#9D9D9D"

                Text {
                    text: "Next"
                    color: "#E8E8E8"
                    anchors.centerIn: parent
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.nextClicked()
                }
            }
        }
    }
}

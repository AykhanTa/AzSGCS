// SideMenu_Sensors_Compass.qml (RESPONSIVE - Accelerometer ilə eyni məntiq, daha böyük kartlar)

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

    // İstəsən Loader tərəfdən qoşarsan
    signal cancelClicked()
    signal nextClicked()

    // Fayl yolları (səndəki kimi saxladım)
    property string imageDir: "file:///C:/Users/user/qgroundcontrol/resources/AZSHIELD_ICON/"
    property string backIconSource: imageDir + "back_.svg"

    // Progress (demo/placeholder)
    property real progressValue: 0
    property int  completedCount: 0
    readonly property int totalOrientations: 6

    // Responsiv ölçülər
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property bool _stacked: (width < 980)  || ScreenTools.isShortScreen

    readonly property real _m:    Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.70 : 1.0))
    readonly property real _side: _stacked ? Math.max(10, _m) : Math.max(28, _m * 2.0)

    // Orientasiya kartları
    readonly property var _cards: [
        { title: "Top",        img: imageDir + "t1.png" },
        { title: "Bottom",     img: imageDir + "t2.png" },
        { title: "Left Side",  img: imageDir + "t3.png" },
        { title: "Right Side", img: imageDir + "t4.png" },
        { title: "Front",      img: imageDir + "t5.png" },
        { title: "Back",       img: imageDir + "t6.png" }
    ]

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Demo progress (istəmirsənsə running:false et)
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: progressValue = Math.min(progressValue + 1, 100)
    }

    // Səhifədə orientasiya bloku üçün maksimum hündürlük
    readonly property real _orientMaxH: Math.max(240,
        mainLayout.height
        - headerCol.implicitHeight
        - instructionCard.implicitHeight
        - progressRow.implicitHeight
        - progressBar.height
        - bottomRow.implicitHeight
        - (mainLayout.spacing * 6)
    )

    // Compass səhifəsində kartlar bir az daha böyük olsun deyə min artırılıb
    readonly property real _orientMinH: _compact ? 460 : 760

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: page._side
        spacing: page._m

        // ---------------- Title / Subtitle
        ColumnLayout {
            id: headerCol
            Layout.fillWidth: true
            spacing: page._compact ? 2 : 6

            Text {
                text: "Compass Calibration"
                color: "white"
                font.pixelSize: page._compact ? 22 : 26
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: "Calibrate the compass for accurate flight control"
                color: "#E8E8E8"
                font.pixelSize: page._compact ? 13 : 16
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // ---------------- Instruction
        Rectangle {
            id: instructionCard
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

        // ---------------- Progress row
        RowLayout {
            id: progressRow
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

        // ---------------- Progress bar
        Rectangle {
            id: progressBar
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

        // ================== ORIENTATIONS BLOCK (responsiv grid, daha böyük kartlar)
        Rectangle {
            id: orientationsBlock
            Layout.fillWidth: true

            // Daha böyük görünüş üçün hündürlük daha geniş aralıqda seçilir
            Layout.preferredHeight: Math.min(
                                        Math.max(desiredBlockH, page._orientMinH),
                                        page._orientMaxH
                                    )

            radius: 16
            color: "black"
            border.width: 1
            border.color: "#9D9D9D"
            clip: true

            // Bir az daha az padding/gap -> kartların eni artsın
            readonly property real pad:   Math.max(8,  page._m * 0.75)
            readonly property real gap:   Math.max(10, page._m * 0.70)
            readonly property real ratio: 0.625  // 300/480

            readonly property real innerW: Math.max(1, width  - pad * 2)
            readonly property real innerH: Math.max(1, height - pad * 2)

            // Kiçik ekranda 2-2 (çox dar olsa 1), böyükdə 3 sütun
            readonly property int cols: page._stacked
                                       ? ((innerW < 520) ? 1 : 2)
                                       : 3
            readonly property int rows: Math.ceil(page.totalOrientations / cols)

            // Kart ölçüsü ENƏ görə (böyük olsun deyə hündürlüyə görə məcburi kiçiltmirik)
            readonly property real cardW: Math.max(170, Math.floor((innerW - gap * (cols - 1)) / cols))
            readonly property real cardH: Math.floor(cardW * ratio)

            readonly property real gridW: cols * cardW + gap * (cols - 1)
            readonly property real gridH: rows * cardH + gap * (rows - 1)

            readonly property real desiredBlockH: gridH + pad * 2

            Item {
                anchors.fill: parent
                anchors.margins: orientationsBlock.pad

                // Əgər hündürlük çatmasa -> bu hissənin içində scroll olsun (kartlar kiçilməsin)
                Flickable {
                    id: orientFlick
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    contentWidth:  width
                    contentHeight: Math.max(height, orientationsBlock.gridH)
                    interactive:   orientationsBlock.gridH > height + 2

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                    Item {
                        id: orientContent
                        width: orientFlick.width
                        height: Math.max(orientFlick.height, orientationsBlock.gridH)

                        Grid {
                            id: cardsGrid
                            columns: orientationsBlock.cols
                            spacing: orientationsBlock.gap

                            width: orientationsBlock.gridW
                            height: orientationsBlock.gridH

                            // Üfüqi mərkəz; şaquli mərkəz yalnız scroll lazım deyilsə
                            x: Math.max(0, (orientContent.width - width) / 2)
                            y: orientFlick.interactive ? 0 : Math.max(0, (orientContent.height - height) / 2)

                            Repeater {
                                model: page._cards

                                Rectangle {
                                    width: orientationsBlock.cardW
                                    height: orientationsBlock.cardH
                                    color: "transparent"
                                    radius: 16
                                    border.width: page._compact ? 6 : 7
                                    border.color: "#FF0000"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: Math.max(10, page._m * 0.70)
                                        spacing: Math.max(8, page._m * 0.60)

                                        Text {
                                            text: modelData.title
                                            color: "white"
                                            font.pixelSize: page._compact ? 15 : 18
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

                                            // Şəkil daha böyük görünsün
                                            Layout.preferredWidth:  parent.width  * 0.86
                                            Layout.preferredHeight: parent.height * 0.66
                                        }

                                        Item { Layout.fillHeight: true; Layout.fillWidth: true }

                                        Text {
                                            text: "Incomplete"
                                            color: "white"
                                            font.pixelSize: page._compact ? 15 : 18
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
        }

        // Spacer: düymələr aşağıda qalsın
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // ---------------- Bottom buttons
        RowLayout {
            id: bottomRow
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
                        if (typeof page.goBack === "function") {
                            page.goBack()
                        } else {
                            console.warn("SideMenu_Sensors_Compass: goBack is not a function")
                        }
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

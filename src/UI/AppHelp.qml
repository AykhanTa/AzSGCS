import QtQuick
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: root
    color: "#2a2a2a"

    anchors.top: parent.top
    anchors.topMargin: 50
    anchors.left: parent.left
    anchors.leftMargin: 50
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 70
    anchors.right: parent.right
    anchors.rightMargin: 100

    radius: 16
    border.width: 2
    border.color: "white"

    // Linkləri ağ + hover-da underline (vizual olaraq kliklənəndir)
    readonly property string _whiteLinkStyle:
        "<style>a{color:#ffffff;text-decoration:none;} a:hover{color:#ffffff;text-decoration:underline;}</style>"

    Text {
        text: "AzShieldControl Panel"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        font.pixelSize: 26
        font.bold: true
        color: "white"
    }

    QGCFlickable {
        id: flick
        anchors.fill: parent

        // padding
        anchors.topMargin: 90
        anchors.leftMargin: 30
        anchors.rightMargin: 30
        anchors.bottomMargin: 30

        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        // sağa scroll olmasın
        contentWidth: width
        contentHeight: grid.implicitHeight

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        readonly property bool narrow: width < 820

        GridLayout {
            id: grid
            width: flick.width
            columns: flick.narrow ? 1 : 2
            columnSpacing: flick.narrow ? 12 : 40
            rowSpacing: 14

            // --- 1 ---
            QGCLabel {
                text: qsTr("AzShieldControl İstifadəçi Təlimatı")
                font.pointSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
            QGCLabel {
                id: link1
                linkColor: "white"
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                font.pointSize: 10
                text: root._whiteLinkStyle +
                      "<a href=\"https://www.instagram.com/_abilov_?igsh=MWxib3h2d2V0NjV0OA==\">https://www.instagram.com/_abilov_?igsh=MWxib3h2d2V0NjV0OA==</a>"
                onLinkActivated: (link) => Qt.openUrlExternally(link)

                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            // --- 2 ---
            QGCLabel {
                text: qsTr("PX4 İstifadəçiləri Müzakirə Forumu")
                font.pointSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
            QGCLabel {
                id: link2
                linkColor: "white"
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                font.pointSize: 10
                text: root._whiteLinkStyle +
                      "<a href=\"https://www.youtube.com\">https://www.youtube.com/</a>"
                onLinkActivated: (link) => Qt.openUrlExternally(link)

                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            // --- 3 ---
            QGCLabel {
                text: qsTr("ArduPilot İstifadəçiləri Müzakirə Forumu")
                font.pointSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
            QGCLabel {
                id: link3
                linkColor: "white"
                textFormat: Text.RichText
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                font.pointSize: 10
                text: root._whiteLinkStyle +
                      "<a href=\"https://discuss.ardupilot.org/c/ground-control-software/qgroundcontrol\">https://discuss.ardupilot.org/c/ground-control-software/qgroundcontrol</a>"
                onLinkActivated: (link) => Qt.openUrlExternally(link)

                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

        }
    }
}

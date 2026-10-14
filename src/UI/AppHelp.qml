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

    Text {
        text: qsTr("%1 Dəstək").arg(QGroundControl.appName)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        font.pixelSize: 26
        font.bold: true
        color: "white"
    }

    // Dəstək səhifələri hazır olana qədər burada heç bir xarici link göstərilmir.
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 90
        anchors.leftMargin: 30
        anchors.rightMargin: 30
        anchors.bottomMargin: 30
        spacing: 14

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 40
            rowSpacing: 14

            QGCLabel {
                text: qsTr("Versiya")
                color: "white"
                font.pixelSize: 18
                font.bold: true
            }
            QGCLabel {
                text: QGroundControl.qgcVersion
                color: "#E8E8E8"
                font.pixelSize: 18
                wrapMode: Text.WrapAnywhere
                Layout.fillWidth: true
            }
        }

        QGCLabel {
            text: qsTr("Dəstək əlaqə məlumatları sonradan əlavə olunacaq.")
            color: "#E8E8E8"
            font.pixelSize: 16
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true }
    }
}

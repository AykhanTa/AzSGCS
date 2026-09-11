// SimplePopup.qml
import QtQuick
import QtQuick.Controls

Rectangle {
    id: popup
    width: 300
    height: 200
    color: "lightblue"
    border.color: "black"
    border.width: 2
    radius: 5

    property string message: "Battery Popup Test"

    Text {
        id: title
        text: "BATTERY INFO"
        font.bold: true
        font.pixelSize: 16
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10
    }

    Text {
        text: popup.message
        font.pixelSize: 14
        anchors.centerIn: parent
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popup.destroy()
    }

    Component.onCompleted: {
        console.log("SimplePopup oluşturuldu")
    }

    Component.onDestruction: {
        console.log("SimplePopup yok edildi")
    }
}

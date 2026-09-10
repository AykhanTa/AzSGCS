import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: page
    width: 1560
    height: 1080 // black eas sehife
    // Loader-dən gəlir
    property var goBack
    property bool showPanel: false     // Loader bunu true göndərir

// Baro/Airspeed Calibration
        Text {
            text: "Level Horizon Calibration";
            color: "white";
            x: 50; y: 40;
            font.pixelSize: 26; font.bold:  true
            }

        Text {
            text: "Calibrate the level Horizon for accurate flight control";
            color: "#E8E8E8";
            x: 57; y: 86;
            font.pixelSize: 16; font.bold: true
        } // ------------------------------------------------------------------------------------------------------------------------------------------

        Text { text:"Progress";
            x: 50
            y:153
            color: "#FFFFFF";
            font.pixelSize: 16;font.bold: true }

    // Proqress bar ---------------------------------------------------------------------------------------------------------------------------
            Rectangle {
                x: 50
                y: 189
                width: 1490
                height: 8
                color: "#707070" // Arxa fon (boz)
    // Proqressin dolmuş hissəsi
                Rectangle {
                    width: parent.width * (progressValue / 100) // Proqressin uzunluğu, value ilə tənzimlənir
                    height: parent.height
                    color: "#FFFFFF" // Ağ rəngdə
                    radius: height / 2 // Küncləri yuvarlaqlaşdırmaq
                }
            }
   // Proqress dəyəri
            property real progressValue: 0  // Başlanğıc dəyəri 0%

    // Timer istifadə edirik, hər 100ms proqress dəyərini artırırıq
            Timer {
                id: progressTimer
                interval: 100  // hər 100ms
                running: true  // Başlanğıcda işləməsin
                repeat: true
                    onTriggered: {
                        // Proqress dəyərini artırırıq
                        progressValue = Math.min(progressValue + 1, 100) // Proqress dəyəri 100-ə qədər artacaq
                    }
                }

            Text {
                text: "[cal] calibration started: 2 level\n[cal] calibration done: level";
                color: "#E8E8E8";
                x: 50; y: 223
                font.pixelSize: 14; font.bold: true
            }

            Rectangle {x: 60; y: 992; width:98; height: 48; color: "#3D3B3B"; radius: 5; border.width: 0.5; border.color: "#9D9D9D"

                Row {anchors.centerIn: parent; spacing: 8
                        Image {source: "file:///C:/Users/user/qgroundcontrol/resources/AZSHIELD_ICON/back_.svg"
                            width: 24; height: 24; x: 15; y: 1;fillMode: Image.PreserveAspectFit;smooth: true
                               }  // -- goBack funksiyasını çağırırıq ki, SideMenu_Sensors.qml açılacaq

                    Text { text:"Back"; color: "#E8E8E8"; x: 43; y: 2; font.pixelSize: 16;font.bold: true }
                     }
                MouseArea {anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                    onClicked: {
                    // Loader-dən gələn səhifəni açırıq
                    page.goBack() } }
                        }

}



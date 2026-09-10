// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// import QtQuick
// import QtQuick.Controls
// import QtQuick.Dialogs
// import QtQuick.Layouts

// import QGroundControl
// import QGroundControl.Controls


// QGCPopupDialog {
//     title:   qsTr("Select Altitude Mode")
//     buttons: Dialog.Close

//     property var rgRemoveModes
//     property var updateAltModeFn
//     property var currentAltMode

//     Component.onCompleted: {
//         // Check for custom build override on AMSL usage
//         if (!QGroundControl.corePlugin.options.showMissionAbsoluteAltitude && currentAltMode != QGroundControl.AltitudeModeAbsolute) {
//             rgRemoveModes.push(QGroundControl.AltitudeModeAbsolute)
//         }

//         // Remove modes specified by consumer
//         for (var i=0; i<rgRemoveModes.length; i++) {
//             for (var j=0; j<buttonModel.count; j++) {
//                 if (buttonModel.get(j).modeValue == rgRemoveModes[i]) {
//                     buttonModel.remove(j)
//                     break
//                 }
//             }
//         }


//         buttonRepeater.model = buttonModel
//     }

//     ListModel {
//         id: buttonModel

//         ListElement {
//             modeName:   qsTr("Relative To Launch")
//             help:       qsTr("Müəyyən edilmiş hündürlüklər buraxılış mövqeyinin hündürlüyünə nisbətəndir.")
//             modeValue:  QGroundControl.AltitudeModeRelative
//         }
//         ListElement {
//             modeName:   qsTr("AMSL")
//             help:       qsTr("Müəyyən edilmiş yüksəkliklər Orta Dəniz səviyyəsindən yuxarıdır.")
//             modeValue:  QGroundControl.AltitudeModeAbsolute
//         }
//         ListElement {
//             modeName:   qsTr("Calculated Above Terrain")
//             help:       qsTr("Müəyyən edilmiş hündürlüklər ərazidən yuxarı məsafədir. Təyyarəyə göndərilən faktiki hündürlüklər ərazi məlumatlarından hesablanır və AMSL dəyərləri kimi göndərilir.")
//             modeValue:  QGroundControl.AltitudeModeCalcAboveTerrain
//         }
//         ListElement {
//             modeName:   qsTr("Terrain Frame")
//             help:       qsTr("Müəyyən edilmiş hündürlüklər ərazidən yuxarı məsafədir. Uçuşun həqiqi hündürlüyü təyyarə tərəfindən ya təyyarəyə göndərilən ərazi hündürlüyü xəritələrindən, ya da məsafə sensorundan idarə olunur.")
//             modeValue:  QGroundControl.AltitudeModeTerrainFrame
//         }
//         ListElement {
//             modeName:   qsTr("Mixed Modes")
//             help:       qsTr("Hündürlük rejimi hər bir fərdi element üçün fərqli ola bilər.")
//             modeValue:  QGroundControl.AltitudeModeMixed
//         }
//     }

//     Column {
//         spacing: ScreenTools.defaultFontPixelWidth

//         Repeater {
//             id: buttonRepeater

//             Button {
//                 hoverEnabled:   true
//                 checked:        modeValue == currentAltMode

//                 background: Rectangle {
//                     radius: ScreenTools.defaultFontPixelHeight / 2
//                     color:  pressed | hovered | checked ? QGroundControl.globalPalette.buttonHighlight: QGroundControl.globalPalette.button
//                 }

//                 contentItem: Column {
//                     spacing: 0

//                     QGCLabel {
//                         id:     modeNameLabel
//                         text:   modeName
//                         color:  pressed | hovered | checked ? QGroundControl.globalPalette.buttonHighlightText: QGroundControl.globalPalette.buttonText
//                     }

//                     QGCLabel {
//                         width:              ScreenTools.defaultFontPixelWidth * 40
//                         text:               help
//                         wrapMode:           Label.WordWrap
//                         font.pointSize:     ScreenTools.smallFontPointSize
//                         color:              modeNameLabel.color
//                     }
//                 }

//                 onClicked: {
//                     updateAltModeFn(modeValue)
//                     close()
//                 }
//             }
//         }
//     }
// }



import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls


QGCPopupDialog {
    title:   qsTr("Hündürlük rejimini seçin")
    buttons: Dialog.Close

    property var rgRemoveModes
    property var updateAltModeFn
    property var currentAltMode

    Component.onCompleted: {
        // Check for custom build override on AMSL usage
        if (!QGroundControl.corePlugin.options.showMissionAbsoluteAltitude && currentAltMode != QGroundControl.AltitudeModeAbsolute) {
            rgRemoveModes.push(QGroundControl.AltitudeModeAbsolute)
        }

        // Remove modes specified by consumer
        for (var i=0; i<rgRemoveModes.length; i++) {
            for (var j=0; j<buttonModel.count; j++) {
                if (buttonModel.get(j).modeValue == rgRemoveModes[i]) {
                    buttonModel.remove(j)
                    break
                }
            }
        }


        buttonRepeater.model = buttonModel
    }

    ListModel {
        id: buttonModel

        ListElement {
            modeName:   qsTr("Başlamaq üçün Nisbi")
            help:       qsTr("Müəyyən edilmiş hündürlüklər buraxılış mövqeyinin hündürlüyünə nisbətəndir.")
            modeValue:  QGroundControl.AltitudeModeRelative

        }
        ListElement {
            modeName:   qsTr("AMSL")
            help:       qsTr("Müəyyən edilmiş yüksəkliklər Orta Dəniz səviyyəsindən yuxarıdır.")
            modeValue:  QGroundControl.AltitudeModeAbsolute
        }
        ListElement {
            modeName:   qsTr("Ərazidən yuxarı hesablanmışdır")
            help:       qsTr("Müəyyən edilmiş hündürlüklər ərazidən yuxarı məsafədir. Təyyarəyə göndərilən faktiki hündürlüklər ərazi məlumatlarından hesablanır və AMSL dəyərləri kimi göndərilir.")
            modeValue:  QGroundControl.AltitudeModeCalcAboveTerrain
        }
        ListElement {
            modeName:   qsTr("Ərazi çərçivəsi")
            help:       qsTr("Müəyyən edilmiş hündürlüklər ərazidən yuxarı məsafədir. Uçuşun həqiqi hündürlüyü təyyarə tərəfindən ya təyyarəyə göndərilən ərazi hündürlüyü xəritələrindən, ya da məsafə sensorundan idarə olunur.")
            modeValue:  QGroundControl.AltitudeModeTerrainFrame
        }
        ListElement {
            modeName:   qsTr("Qarışıq rejimlər")
            help:       qsTr("Hündürlük rejimi hər bir fərdi element üçün fərqli ola bilər.")
            modeValue:  QGroundControl.AltitudeModeMixed
        }
    }

    Column {
        spacing: ScreenTools.defaultFontPixelWidth

        Repeater {
            id: buttonRepeater

            Button {
                id:             modeButton
                hoverEnabled:   true
                checked:        modeValue == currentAltMode
                padding:        ScreenTools.defaultFontPixelWidth

                readonly property bool _active: modeButton.checked
                readonly property bool _lit:    modeButton.pressed || modeButton.hovered

                background: Rectangle {
                    radius:         10
                    color:          modeButton.pressed ? "#454545"
                                                       : (modeButton.hovered ? "#3A3A3A" : "#2F2F2F")
                    border.width:   modeButton._active ? 2 : 1
                    border.color:   modeButton._active ? "#00C853" : "#4A4A4A"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    // Seçilmiş rejimi bildirən sol kənar
                    Rectangle {
                        anchors.left:           parent.left
                        anchors.leftMargin:     2
                        anchors.verticalCenter: parent.verticalCenter
                        width:                  3
                        height:                 parent.height * 0.6
                        radius:                 1.5
                        color:                  "#00C853"
                        visible:                modeButton._active || modeButton._lit
                    }
                }

                contentItem: Column {
                    spacing: 2

                    QGCLabel {
                        id:             modeNameLabel
                        text:           modeName
                        color:          "#FFFFFF"
                        font.bold:      true
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }

                    QGCLabel {
                        width:              ScreenTools.defaultFontPixelWidth * 40
                        text:               help
                        wrapMode:           Label.WordWrap
                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.92
                        color:              "#B9B9B9"
                    }
                }

                onClicked: {
                    updateAltModeFn(modeValue)
                    close()
                }
            }
        }
    }
}


import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
//import QtQuick.Dialogs 1.3

import QGroundControl 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Controls 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "black"

    property bool parametersReady: globals.activeVehicle
                                   && globals.activeVehicle.parameterManager
                                   && globals.activeVehicle.parameterManager.parametersReady

    AirframeComponentController {
        id: controller
    }

    // Arxadakı xəritəyə boş sahələrdən klik/wheel getməsin
    MouseArea {
        anchors.fill: parent
        z: 1
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onWheel: (wheel) => { wheel.accepted = true }
    }

    // SetupPage-dəki gizli top padding/margin olmasın deyə Loader istifadə edirik
    Loader {
        id: pageLoader
        z: 2
        anchors.fill: parent
        sourceComponent: !root.parametersReady
                         ? waitingFrame
                         : ((controller && controller.showCustomConfigPanel) ? customFrame : normalFrame)
    }

    // -------------------------
    // Avtopilot bağlantısı gözləyən panel
    // -------------------------
    Component {
        id: waitingFrame

        Rectangle {
            anchors.fill: parent
            color: "black"

            readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
            readonly property bool _stacked: (width < 900) || ScreenTools.isShortScreen
            readonly property real _m:    Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.75 : 1.0))
            readonly property real _side: Math.max(12, _m * 0.9)

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: _side
                anchors.rightMargin: _side
                anchors.bottomMargin: _side
                anchors.topMargin: 0
                spacing: _m

                // Header (başlıq + açıqlama bir-birinə yaxın)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: _compact ? 3 : 6

                    Text {
                        text: qsTr("Çərçivə Konfiqurasiyası")
                        color: "white"
                        font.bold: true
                        font.pixelSize: _compact ? 21 : 26
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: qsTr("Təyyarənizə uyğun olan hava gövdəsi konfiqurasiyanı seçin. Seçimdən sonra yenidən başlamalısınız.")
                        color: "#E8E8E8"
                        font.bold: false
                        font.pixelSize: _compact ? 13 : 16
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                // Gözləmə kartı
                Rectangle {
                    Layout.fillWidth: true
                    radius: 16
                    color: "#3D3B3B"
                    border.width: 1
                    border.color: "#9D9D9D"
                    implicitHeight: 220

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 2 * _m
                        text: qsTr("Parametrlər yüklənir...\nAvtopilot bağlantısını gözləyin")
                        color: "#FFFFFF"
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }

                Item { Layout.fillHeight: true; Layout.fillWidth: true }
            }
        }
    }

    // -------------------------
    // Custom config panel
    // -------------------------
    Component {
        id: customFrame

        Rectangle {
            anchors.fill: parent
            color: "black"

            readonly property bool _compact: (width < 900) || ScreenTools.isShortScreen
            readonly property real _m: Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.75 : 1.0))
            readonly property real _side: Math.max(12, _m * 0.9)

            QGCFlickable {
                anchors.fill: parent
                clip: true
                flickableDirection: Flickable.VerticalFlick
                contentWidth: width
                contentHeight: contentCol.implicitHeight + _side

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                ColumnLayout {
                    id: contentCol
                    width: Math.min(parent.width - (_side * 2), 1100)
                    x: (parent.width - width) / 2
                    spacing: _m

                    // ✅ yuxarıdan boşluq YOX

                    QGCLabel {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "white"
                        text:
                            qsTr("Your vehicle is using a custom airframe configuration. ") +
                            qsTr("This configuration can only be modified through the Parameter Editor.\n\n") +
                            qsTr("If you want to reset your airframe configuration and select a standard configuration, click 'Reset' below.")
                    }

                    QGCButton {
                        text: qsTr("Reset")
                        enabled: sys_autostart
                        Layout.alignment: Qt.AlignHCenter

                        property Fact sys_autostart: controller.getParameterFact(-1, "SYS_AUTOSTART")
                        onClicked: {
                            if (sys_autostart) {
                                sys_autostart.value = 0
                            }
                        }
                    }

                    Item { Layout.preferredHeight: _m; Layout.fillWidth: true }
                }
            }
        }
    }

    // -------------------------
    // Normal frame page
    // -------------------------
    Component {
        id: normalFrame

        Rectangle {
            anchors.fill: parent
            color: "black"

            // ===== Responsive flags =====
            readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
            readonly property bool _stacked: (width < 900) || ScreenTools.isShortScreen

            // Spacing/margins
            readonly property real _m:    Math.max(8, ScreenTools.defaultFontPixelHeight * (_compact ? 0.75 : 1.0))
            readonly property real _side: Math.max(12, _m * 0.9)
            readonly property real _maxContentW: 1600

            // // ✅ Kiçik ekranda kartlar böyük olmasın
            // readonly property real _cardW: _stacked ? flowView.width : 354
            // readonly property real _cardH: _stacked ? cardHeightForWidth(_cardW) : 309
            // readonly property real _flowSpacing: _stacked ? Math.max(10, _m) : 24
            // readonly property int  _comboH: _compact ? 46 : 52

            // function cardHeightForWidth(w) {
            //     // Əvvəl max 380 idi -> çox böyük görünürdü.
            //     // İndi daha yığcam:
            //     var h = Math.round(w * 0.70)
            //     return Math.max(240, Math.min(320, h))
            // }


            // Aralıqlar (sən istəsən rəqəmləri azaldıb/çoxalda bilərsən)
            readonly property real _flowSpacing: _stacked ? Math.max(10, _m) : 24

            // G20 kimi qısa/dar ekranlarda kartlar daha balaca olsun
            readonly property real _minCardW: ScreenTools.isShortScreen ? 180 : 260
            readonly property real _maxCardW: ScreenTools.isShortScreen ? 240 : 354

            // neçə sütun sığırsa onu seç (1, 2, 3...)
            readonly property int _cols: Math.max(1,
                Math.floor((flowView.width + _flowSpacing) / (_minCardW + _flowSpacing))
            )

            // kart eni = mövcud eni sütun sayına böl
            readonly property real _cardW: Math.min(_maxCardW,
                Math.floor((flowView.width - (_cols - 1) * _flowSpacing) / _cols)
            )

            readonly property real _cardH: cardHeightForWidth(_cardW)

            // Combobox hündürlüyünü də bir az yığcam et
            readonly property int  _comboH: _compact ? 38 : 44

            function cardHeightForWidth(w) {
                // əvvəl min 240 idi, G20-də böyük görünürdü
                var h = Math.round(w * 0.70)
                return Math.max(200, Math.min(280, h))
            }

            QGCFlickable {
                id: pageFlick
                anchors.fill: parent
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                contentWidth: width
                contentHeight: contentCol.implicitHeight + _side

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                ColumnLayout {
                    id: contentCol
                    width: Math.min(pageFlick.width - (_side * 2), _maxContentW)
                    x: (pageFlick.width - width) / 2
                    spacing: _m

                    // ✅ yuxarıdan boşluq YOX

                    // ===== Header row (stacked olanda alt‑alta) =====
                    GridLayout {
                        Layout.fillWidth: true
                        columns: _stacked ? 1 : 2
                        columnSpacing: _m
                        rowSpacing: _stacked ? Math.max(6, _m * 0.6) : 0

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: _compact ? 3 : 6

                            Text {
                                text: qsTr("Çərçivə Konfiqurasiyası")
                                color: "white"
                                font.bold: true
                                font.pixelSize: _compact ? 21 : 26
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Text {
                                text: qsTr("Təyyarənizə uyğun olan hava gövdəsi konfiqurasiyanı seçin. Seçimdən sonra yenidən başlamalısınız.")
                                color: "#E8E8E8"
                                font.bold: false
                                font.pixelSize: _compact ? 13 : 16
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            Layout.alignment: _stacked ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignTop)
                            Layout.fillWidth: _stacked
                            Layout.preferredWidth: _stacked ? -1 : 285
                            Layout.maximumWidth: _stacked ? -1 : 285
                            Layout.preferredHeight: Math.max(42, Math.round(ScreenTools.defaultFontPixelHeight * (_compact ? 2.1 : 2.6)))

                            color: "#474747"
                            border.color: "#9D9D9D"
                            border.width: 1
                            radius: 8

                            Text {
                                anchors.fill: parent
                                anchors.margins: 8
                                text: qsTr("Tətbiq et və Yenidən başlat")
                                color: "#E8E8E8"
                                font.pixelSize: _compact ? 14 : 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mainWindow.showMessageDialog(
                                               qsTr("Tətbiq et və Yenidən başlat"),
                                               qsTr("'Tətbiq et' düyməsini klikləməklə, hava gövdəsi konfiqurasiyanızda etdiyiniz dəyişikliklər yadda saxlanılacaq<br><br>\
Radio Kalibrləmədən başqa bütün təyyarə parametrləri sıfırlanacaq.<br><br>\
Prosesi başa çatdırmaq üçün təyyarəniz də yenidən işə salınacaq."),
                                               Dialog.Apply | Dialog.Cancel,
                                               function() { controller.changeAutostart() }
                                           )
                            }
                        }
                    }

                    // ===== Cards =====
                    Flow {
                        id: flowView
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: _flowSpacing

                        ButtonGroup { id: airframeTypeExclusive }

                        Repeater {
                            // Cards shown on this page, in the order they are listed here.
                            // controller.airframeTypes is sorted alphabetically, so picking by name
                            // keeps the layout stable no matter what a new entry is called.
                            readonly property var _shownAirframeTypes: [
                                "Qırat H10",
                                "Qırat H20",
                                "Qırat H30",
                                "Hədəf",
                                "Boran"
                            ]

                            model: {
                                var allTypes = controller.airframeTypes
                                var filteredModels = []

                                for (var a = 0; a < _shownAirframeTypes.length; a++) {
                                    for (var i = 0; i < allTypes.length; i++) {
                                        if (allTypes[i].name === _shownAirframeTypes[a]) {
                                            filteredModels.push(allTypes[i])
                                            break
                                        }
                                    }
                                }
                                return (filteredModels.length > 0) ? filteredModels : allTypes
                            }

                            delegate: Rectangle {
                                width:  _cardW
                                height: _cardH

                                color:  "#3D3B3B"
                                radius: 14
                                border.width: airframeCheckBox.checked ? 2 : 1
                                border.color: airframeCheckBox.checked ? "#00FF00" : "#9D9D9D"

                                property bool isCurrentType: modelData.name === controller.currentAirframeType

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        airframeCheckBox.checked = true
                                        if (combo.currentIndex !== -1) {
                                            controller.autostartId = modelData.airframes[combo.currentIndex].autostartId
                                        }
                                    }
                                }

                                Text {
                                    id: title
                                    text: modelData.name
                                    color: airframeCheckBox.checked ? "#00FF00" : "#FFFFFF"
                                    font.pixelSize: _compact ? 13 : 14
                                    font.bold: true
                                    anchors.left: parent.left
                                    anchors.leftMargin: _compact ? 16 : 22
                                    anchors.top: parent.top
                                    anchors.topMargin: _compact ? 10 : 12
                                    elide: Text.ElideRight
                                    width: parent.width - ((_compact ? 16 : 22) * 2)
                                }

                                Rectangle {
                                    anchors.top: title.bottom
                                    anchors.topMargin: _compact ? 10 : 12
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: _comboH
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 1
                                    // Dark, because the airframe artwork is drawn in mid to light
                                    // greys -- on the light panel this used to be, the aircraft
                                    // washed out into the background.
                                    color: airframeCheckBox.checked ? "#2C4430" : "#2E3035"
                                    radius: 8

                                    Image {
                                        anchors.centerIn: parent
                                        width: parent.width * (_compact ? 0.84 : 0.88)
                                        height: parent.height * (_compact ? 0.86 : 0.9)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                        source: modelData.imageResource
                                    }
                                }

                                Rectangle {
                                    width: parent.width - 2
                                    height: _comboH
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#3D3B3B"
                                    radius: 8
                                    border.color: "#9D9D9D"
                                    border.width: 0.5

                                    QGCComboBox {
                                        id: combo
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        model: modelData.airframes
                                        textRole: "text"

                                        background: Rectangle { color: "transparent"; border.color: "transparent" }

                                        contentItem: Text {
                                            text: combo.displayText
                                            color: "#FFFFFF"
                                            font.pixelSize: _compact ? 14 : 15
                                            font.bold: true
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignLeft
                                            elide: Text.ElideRight
                                            leftPadding: 8
                                        }

                                        popup: Popup {
                                            y: combo.height
                                            width: combo.width
                                            implicitHeight: Math.min(contentItem.implicitHeight, ScreenTools.defaultFontPixelHeight * 16)
                                            padding: 1

                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: combo.popup.visible ? combo.delegateModel : null
                                                currentIndex: combo.highlightedIndex
                                                ScrollIndicator.vertical: ScrollIndicator { }
                                            }

                                            background: Rectangle {
                                                color: "#3D3B3B"
                                                border.color: "#9D9D9D"
                                                radius: 5
                                            }
                                        }

                                        delegate: ItemDelegate {
                                            width: combo.width
                                            text: modelData.text
                                            highlighted: combo.highlightedIndex === index

                                            background: Rectangle { color: highlighted ? "#557D55" : "transparent" }

                                            contentItem: Text {
                                                text: modelData.text
                                                color: "#FFFFFF"
                                                font.pixelSize: 14
                                                elide: Text.ElideRight
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        onActivated: function(index) {
                                            airframeCheckBox.checked = true
                                            controller.autostartId = modelData.airframes[index].autostartId
                                            controller.currentAirframeType = modelData.name
                                        }

                                        Component.onCompleted: {
                                            var currentAutostartId = controller.autostartId
                                            if (modelData.airframes && modelData.airframes.length > 0) {
                                                var foundIndex = -1
                                                for (var i = 0; i < modelData.airframes.length; i++) {
                                                    if (modelData.airframes[i].autostartId === currentAutostartId) {
                                                        foundIndex = i
                                                        break
                                                    }
                                                }
                                                currentIndex = (foundIndex !== -1) ? foundIndex : 0
                                                if (modelData.name === controller.currentAirframeType) {
                                                    airframeCheckBox.checked = true
                                                }
                                            }
                                        }
                                    }
                                }

                                QGCCheckBox {
                                    id:             airframeCheckBox
                                    checked:        isCurrentType
                                    buttonGroup:    airframeTypeExclusive
                                    visible:        false

                                    onCheckedChanged: {
                                        if (checked && combo && combo.currentIndex !== -1) {
                                            controller.autostartId = modelData.airframes[combo.currentIndex].autostartId
                                            controller.currentAirframeType = modelData.name
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: _m; Layout.fillWidth: true }
                }
            }
        }
    }
}

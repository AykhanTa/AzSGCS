import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

// Airframe selection, in the new design: the page header of the vehicle setup pages,
// one status card per airframe type (green outline on the selected one) with its
// variant picker, and the apply button.
Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    // The combo boxes, labels and buttons take the new design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    property bool parametersReady: globals.activeVehicle
                                   && globals.activeVehicle.parameterManager
                                   && globals.activeVehicle.parameterManager.parametersReady

    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property bool _stacked: (width < 900) || ScreenTools.isShortScreen
    readonly property real _side:    AzTheme.px(_stacked ? 12 : 20)
    readonly property real _gap:     AzTheme.px(_compact ? 12 : 16)

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

    // The page title and its description, shared by the three states
    component PageHeader: ColumnLayout {
        spacing: AzTheme.px(6)

        Text {
            Layout.fillWidth: true
            text: qsTr("Çərçivə Konfiqurasiyası")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: AzTheme.fontPx(root._compact ? 18 : 20)
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("Təyyarənizə uyğun olan hava gövdəsi konfiqurasiyanı seçin. Seçimdən sonra yenidən başlamalısınız.")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: AzTheme.fontPx(13)
            wrapMode: Text.WordWrap
        }
    }

    // -------------------------
    // Avtopilot bağlantısı gözləyən panel
    // -------------------------
    Component {
        id: waitingFrame

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: root._side
            anchors.rightMargin: root._side
            anchors.topMargin: AzTheme.px(20)
            anchors.bottomMargin: root._side
            spacing: AzTheme.px(16)

            PageHeader { Layout.fillWidth: true }

            // A status card with the vehicle state and what to expect
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: AzTheme.px(200)
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 2 * root._side
                    spacing: AzTheme.px(10)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: AzTheme.px(12)
                        height: width
                        radius: width / 2
                        color: globals.activeVehicle ? AzTheme.statusOrange : AzTheme.mutedText
                    }

                    Text {
                        width: parent.width
                        text: globals.activeVehicle ? qsTr("Parametrlər yüklənir...") : qsTr("Aktiv aparat yoxdur")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: AzTheme.fontPx(17)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: globals.activeVehicle ? qsTr("Avtopilot bağlantısını gözləyin")
                                                    : qsTr("Qoşulduqdan sonra çərçivə seçilə bilər.")
                        color: AzTheme.textSecondary
                        font.family: AzTheme.fontFamily
                        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item { Layout.fillHeight: true; Layout.fillWidth: true }
        }
    }

    // -------------------------
    // Custom config panel
    // -------------------------
    Component {
        id: customFrame

        QGCFlickable {
            anchors.fill: parent
            clip: true
            flickableDirection: Flickable.VerticalFlick
            contentWidth: width
            contentHeight: customCol.implicitHeight + AzTheme.px(20) + root._side

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

            ColumnLayout {
                id: customCol
                y: AzTheme.px(20)
                x: root._side
                width: parent.width - root._side * 2
                spacing: AzTheme.px(16)

                PageHeader { Layout.fillWidth: true }

                // An orange-tinted group box with the explanation and the reset
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: customInner.implicitHeight + AzTheme.px(32)
                    radius: AzTheme.px(AzTheme.groupRadius)
                    color: Qt.rgba(1, 159 / 255, 26 / 255, 0.10)
                    border.width: 1
                    border.color: Qt.rgba(1, 159 / 255, 26 / 255, 0.55)

                    ColumnLayout {
                        id: customInner
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: AzTheme.px(16)
                        spacing: AzTheme.px(14)

                        QGCLabel {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text:
                                qsTr("Your vehicle is using a custom airframe configuration. ") +
                                qsTr("This configuration can only be modified through the Parameter Editor.\n\n") +
                                qsTr("If you want to reset your airframe configuration and select a standard configuration, click 'Reset' below.")
                        }

                        AzButton {
                            text: qsTr("Reset")
                            danger: true
                            enabled: sys_autostart
                            Layout.alignment: Qt.AlignLeft

                            property Fact sys_autostart: controller.getParameterFact(-1, "SYS_AUTOSTART")
                            onClicked: {
                                if (sys_autostart) {
                                    sys_autostart.value = 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // -------------------------
    // Normal frame page
    // -------------------------
    Component {
        id: normalFrame

        Item {
            anchors.fill: parent

            readonly property real _maxContentW: 1600
            readonly property real _flowSpacing: root._gap

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
            readonly property real _cardPad: AzTheme.px(root._compact ? 12 : 16)
            readonly property real _comboH: AzTheme.px(root._compact ? 34 : 38)

            function cardHeightForWidth(w) {
                var h = Math.round(w * 0.78)
                return Math.max(220, Math.min(300, h))
            }

            QGCFlickable {
                id: pageFlick
                anchors.fill: parent
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                contentWidth: width
                contentHeight: contentCol.implicitHeight + AzTheme.px(20) + root._side

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                ColumnLayout {
                    id: contentCol
                    y: AzTheme.px(20)
                    width: Math.min(pageFlick.width - (root._side * 2), _maxContentW)
                    x: (pageFlick.width - width) / 2
                    spacing: AzTheme.px(16)

                    // ===== Header row (stacked olanda alt‑alta) =====
                    GridLayout {
                        Layout.fillWidth: true
                        columns: root._stacked ? 1 : 2
                        columnSpacing: root._gap
                        rowSpacing: AzTheme.px(10)

                        PageHeader { Layout.fillWidth: true }

                        AzButton {
                            Layout.alignment: root._stacked ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignTop)
                            Layout.preferredHeight: AzTheme.px(40)
                            text: qsTr("Tətbiq et və Yenidən başlat")
                            iconSource: "qrc:/res/AZSHIELD_ICON/v2/popup_settings.svg"
                            positive: true

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
                                "Arrow-2",
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

                            // The status card: card gradient, 1 px #353A3F (#5D646B on hover),
                            // a green outline and title on the selected airframe.
                            delegate: Item {
                                id: airframeCard
                                width:  _cardW
                                height: _cardH

                                property bool isCurrentType: modelData.name === controller.currentAirframeType

                                AzGradientRect {
                                    anchors.fill:  parent
                                    angle:         AzTheme.cardGradientAngle
                                    startColor:    AzTheme.cardGradientStart
                                    startPosition: AzTheme.cardGradientStartPos
                                    endColor:      AzTheme.cardGradientEnd
                                    endPosition:   AzTheme.cardGradientEndPos
                                    radius:        AzTheme.px(AzTheme.cardRadius)
                                    borderColor:   airframeCheckBox.checked ? AzTheme.statusGreen
                                                                            : (cardMouse.containsMouse ? AzTheme.cardHoverBorder : AzTheme.cardBorder)
                                    borderWidth:   airframeCheckBox.checked ? 2 : 1
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        airframeCheckBox.checked = true
                                        if (combo.currentIndex !== -1) {
                                            controller.autostartId = modelData.airframes[combo.currentIndex].autostartId
                                        }
                                    }
                                }

                                RowLayout {
                                    id: titleRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.leftMargin: _cardPad
                                    anchors.rightMargin: _cardPad
                                    anchors.topMargin: AzTheme.px(12)
                                    spacing: AzTheme.px(8)

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: airframeCheckBox.checked ? AzTheme.statusGreen : AzTheme.textCard
                                        font.family: AzTheme.fontFamily
                                        font.weight: Font.Medium
                                        font.pixelSize: AzTheme.fontPx(15)
                                        elide: Text.ElideRight
                                    }

                                    // The selected airframe's dot
                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: AzTheme.px(8)
                                        Layout.preferredHeight: AzTheme.px(8)
                                        radius: width / 2
                                        color: AzTheme.statusGreen
                                        visible: airframeCheckBox.checked
                                    }
                                }

                                // Dark, because the airframe artwork is drawn in mid to light
                                // greys -- on a light panel the aircraft washes out.
                                Rectangle {
                                    anchors.top: titleRow.bottom
                                    anchors.topMargin: AzTheme.px(10)
                                    anchors.bottom: comboHolder.top
                                    anchors.bottomMargin: AzTheme.px(10)
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: _cardPad
                                    anchors.rightMargin: _cardPad
                                    radius: AzTheme.px(AzTheme.groupRadius)
                                    color: airframeCheckBox.checked ? Qt.rgba(0, 181 / 255, 70 / 255, 0.10) : AzTheme.groupFill
                                    border.width: 1
                                    border.color: airframeCheckBox.checked ? Qt.rgba(0, 181 / 255, 70 / 255, 0.35) : AzTheme.groupBorder

                                    Image {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.88
                                        height: parent.height * 0.88
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                        source: modelData.imageResource
                                    }
                                }

                                Item {
                                    id: comboHolder
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: _cardPad
                                    anchors.rightMargin: _cardPad
                                    anchors.bottomMargin: _cardPad
                                    height: _comboH

                                    QGCComboBox {
                                        id: combo
                                        anchors.fill: parent
                                        model: modelData.airframes
                                        textRole: "text"

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
                }
            }
        }
    }
}

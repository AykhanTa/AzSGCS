import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

// Parametrlər səhifəsi. Aparat qoşulub parametrləri yüklənənə qədər digər quraşdırma
// səhifələri kimi status kartı göstərir, redaktor isə yalnız bundan sonra yaradılır.
//
// Səbəb: ParameterEditorController yarandığı anda aktiv aparata bağlanır, aparat yoxdursa
// offline aparata. Səhifə aparatsız açılıb sonra aparat qoşulanda redaktor offline
// aparatın parametrlərini göstərməyə davam edirdi.
Rectangle {
    id: root
    anchors.fill: parent
    color: "transparent"

    readonly property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _parametersReady: !!_activeVehicle
                                             && !!_activeVehicle.parameterManager
                                             && _activeVehicle.parameterManager.parametersReady

    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property real _side:    AzTheme.px(_compact ? 12 : 20)

    Loader {
        anchors.fill: parent
        active: root._parametersReady
        sourceComponent: Component { Side_Parameter { } }
    }

    ColumnLayout {
        visible: !root._parametersReady
        x: root._side
        y: AzTheme.px(_compact ? 12 : 20)
        width: root.width - (root._side * 2)
        spacing: AzTheme.px(16)

        ColumnLayout {
            Layout.fillWidth: true
            spacing: AzTheme.px(6)

            Text {
                text: qsTr("Parametrlər")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(root._compact ? 18 : 20)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: qsTr("Parametrləri axtarın, kateqoriya və qruplara görə seçin.")
                color: AzTheme.textSecondary
                font.family: AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(13)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

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
                width: parent.width - (root._side * 2)
                spacing: AzTheme.px(10)

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: AzTheme.px(12); height: width; radius: width / 2
                    color: root._activeVehicle ? AzTheme.statusOrange : AzTheme.mutedText
                }

                Text {
                    width: parent.width
                    text: root._activeVehicle ? qsTr("Parametrlər yüklənir...") : qsTr("Aktiv aparat yoxdur")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(17)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: root._activeVehicle ? qsTr("Avtopilot bağlantısını gözləyin")
                                              : qsTr("Qoşulduqdan sonra parametrlər görünəcək.")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}

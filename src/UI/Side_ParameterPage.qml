import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

// Parametrlər səhifəsi. Aparat qoşulub parametrləri yüklənənə qədər digər quraşdırma
// səhifələri kimi boz panel göstərir, redaktor isə yalnız bundan sonra yaradılır.
//
// Səbəb: ParameterEditorController yarandığı anda aktiv aparata bağlanır, aparat yoxdursa
// offline aparata. Səhifə aparatsız açılıb sonra aparat qoşulanda redaktor offline
// aparatın parametrlərini göstərməyə davam edirdi.
Rectangle {
    id: root
    anchors.fill: parent
    color: "black"

    readonly property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _parametersReady: !!_activeVehicle
                                             && !!_activeVehicle.parameterManager
                                             && _activeVehicle.parameterManager.parametersReady

    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen
    readonly property real _m:       Math.max(6, ScreenTools.defaultFontPixelHeight * (_compact ? 0.45 : 0.55))
    readonly property real _side:    _compact ? Math.max(6, _m * 0.9) : _m * 2

    Loader {
        anchors.fill: parent
        active: root._parametersReady
        sourceComponent: Component { Side_Parameter { } }
    }

    ColumnLayout {
        visible: !root._parametersReady
        x: root._side
        width: root.width - (root._side * 2)
        spacing: root._compact ? (root._m * 0.55) : root._m

        ColumnLayout {
            Layout.fillWidth: true
            spacing: root._compact ? 2 : 4

            Text {
                text: qsTr("Parametrlər")
                color: "white"
                font.bold: true
                font.pixelSize: root._compact ? 22 : 28
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: qsTr("Parametrləri axtarın, kateqoriya və qruplara görə seçin.")
                color: "#E8E8E8"
                font.pixelSize: root._compact ? 12 : 14
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            radius: 16
            color: "#3D3B3B"
            border.width: 1
            border.color: "#9D9D9D"

            Text {
                anchors.centerIn: parent
                width: parent.width - (root._side * 2)
                text: root._activeVehicle
                      ? qsTr("Parametrlər yüklənir...\nAvtopilot bağlantısını gözləyin")
                      : qsTr("Aktiv aparat yoxdur.\nQoşulduqdan sonra parametrlər görünəcək.")
                color: "#FFFFFF"
                font.pixelSize: Math.max(16, ScreenTools.defaultFontPixelHeight * 0.95)
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}

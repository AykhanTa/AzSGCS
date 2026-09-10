import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    default property alias contentItem: mainLayout.data

    readonly property real sidePadding: Math.max(12, ScreenTools.defaultFontPixelWidth * 1.6)

    // Başlıq Aparat Qurğusu səhifələrindəki kimi lap yuxarıdan başlasın deyə üst boşluq yoxdur;
    // aşağıda isə scroll üçün nəfəslik saxlanılır.
    readonly property real topPadding:    0
    readonly property real bottomPadding: Math.max(12, ScreenTools.defaultFontPixelHeight)

    // Bloklar arası boşluq — Rectangle əsaslı səhifələrdəki "gap" ilə eyni
    readonly property real blockSpacing:  Math.max(10, ScreenTools.defaultFontPixelWidth * 1.6)

    readonly property real wheelStepPx: Math.max(60, ScreenTools.defaultFontPixelHeight * 3.2)

    // Boş sahələrdə click/drag arxaya keçməsin (map və s. aktivləşməsin)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        propagateComposedEvents: false
        onPressed:  (m) => { m.accepted = true }
        onReleased: (m) => { m.accepted = true }
        onClicked:  (m) => { m.accepted = true }
        onPositionChanged: (m) => { m.accepted = true }
    }

    QGCFlickable {
        id: flick
        anchors.fill: parent
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        // ✅ Horizontal scroll olmasın
        contentWidth:  root.width
        contentHeight: mainLayout.implicitHeight + root.topPadding + root.bottomPadding

        ScrollBar.vertical:   ScrollBar { policy: ScrollBar.AsNeeded }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        // ✅ Wheel həmişə burada tutulur -> arxaya keçməyəcək
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            onWheel: (event) => {
                event.accepted = true

                var delta = (event.pixelDelta.y !== 0)
                          ? event.pixelDelta.y
                          : (event.angleDelta.y / 120.0) * root.wheelStepPx

                var maxY = Math.max(0, flick.contentHeight - flick.height)
                flick.contentY = Math.max(0, Math.min(maxY, flick.contentY - delta))
            }
        }

        ColumnLayout {
            id: mainLayout

            // ✅ Artıq ortada deyil — sol-yuxarıdan başlayır
            x: root.sidePadding
            y: root.topPadding
            width: Math.max(0, root.width - 2 * root.sidePadding)

            spacing: root.blockSpacing
        }
    }
}

import QtQuick

import QGroundControl
import QGroundControl.Controls

// The panel of the "Yoxlama Paneli" card: the preflight checklist of the vehicle type.
AzPopupFrame {
    id: root

    title:     qsTr("Uçuşdan əvvəl yoxlama")
    cardWidth: AzTheme.px(AzTheme.popupWideWidth)

    onCloseRequested: closePanel()

    function closePanel() {
        panelVisible = false
        if ((typeof settingsLoader !== "undefined") && settingsLoader) {
            settingsLoader.source = ""
        }
    }

    Loader {
        id:     checkList
        source: QGroundControl.corePlugin.options.preFlightChecklistUrl

        onLoaded: {
            item.width     = Qt.binding(function() { return root.contentWidth })
            item.listWidth = Qt.binding(function() { return root.contentWidth })
        }
    }
}

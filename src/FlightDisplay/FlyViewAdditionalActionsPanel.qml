// import QtQuick
// import QtQuick.Layouts

// import QGroundControl
// import QGroundControl.Controls

// ColumnLayout {
//     property var additionalActions
//     property var mavlinkActions
//     property var customActions

//     property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
//     property var  _guidedController:    globals.guidedControllerFlyView

//     // Pre-defined Additional Guided Actions
//     Repeater {
//         model: additionalActions.model

//         QGCButton {
//             Layout.fillWidth:   true
//             text:               modelData.title
//             visible:            modelData.visible

//             onClicked: {
//                 dropPanel.hide()
//                 _guidedController.confirmAction(modelData.action)
//             }
//         }
//     }

//     // Custom Build Actions
//     Repeater {
//         model: customActions.model

//         QGCButton {
//             Layout.fillWidth:   true
//             text:               modelData.title
//             visible:            modelData.visible

//             onClicked: {
//                 dropPanel.hide()
//                 _guidedController.confirmAction(modelData.action)
//             }
//         }
//     }

//     // User-defined Mavlink Actions
//     Repeater {
//         model: _activeVehicle ? mavlinkActions : undefined // The action list is a QmlObjectListModel

//         QGCButton {
//             Layout.fillWidth:   true
//             text:               object.label

//             onClicked: {
//                 dropPanel.hide()
//                 object.sendTo(_activeVehicle)
//             }
//         }
//     }
// }








import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

ColumnLayout {
    property var additionalActions
    property var mavlinkActions
    property var customActions

    property var  _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property var  _guidedController: globals.guidedControllerFlyView

    function _hideDropPanelSafe() {
        // dropPanel bu komponenti host edən yerdə varsa işləyəcək
        if (typeof dropPanel !== "undefined" && dropPanel && dropPanel.hide) {
            dropPanel.hide()
        }
    }

    function _modelFrom(x) {
        if (!x) return null
        // bəzən x özü model olur, bəzən x.model olur
        return (x.model !== undefined) ? x.model : x
    }

    // Pre-defined Additional Guided Actions
    Repeater {
        model: _modelFrom(additionalActions)

        QGCButton {
            Layout.fillWidth:   true
            text:               modelData && modelData.title ? modelData.title : ""
            visible:            modelData && modelData.visible !== undefined ? modelData.visible : true

            onClicked: {
                _hideDropPanelSafe()
                if (_guidedController && typeof _guidedController.confirmAction === "function" && modelData) {
                    _guidedController.confirmAction(modelData.action)
                }
            }
        }
    }

    // Custom Build Actions
    Repeater {
        model: _modelFrom(customActions)

        QGCButton {
            Layout.fillWidth:   true
            text:               modelData && modelData.title ? modelData.title : ""
            visible:            modelData && modelData.visible !== undefined ? modelData.visible : true

            onClicked: {
                _hideDropPanelSafe()
                if (_guidedController && typeof _guidedController.confirmAction === "function" && modelData) {
                    _guidedController.confirmAction(modelData.action)
                }
            }
        }
    }

    // User-defined Mavlink Actions
    Repeater {
        model: (_activeVehicle && mavlinkActions) ? mavlinkActions : null

        QGCButton {
            Layout.fillWidth:   true
            text:               object && object.label ? object.label : ""

            onClicked: {
                _hideDropPanelSafe()
                if (object && _activeVehicle && typeof object.sendTo === "function") {
                    object.sendTo(_activeVehicle)
                }
            }
        }
    }
}

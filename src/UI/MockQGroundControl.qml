// MockQGroundControl.qml
pragma Singleton
import QtQuick 2.15

QtObject {
    // multiVehicleManager mock
    property QtObject multiVehicleManager: QtObject {
        property QtObject activeVehicle: QtObject {
            property bool available: true

            // Batarya listesi
            property list<QtObject> batteries: [
                QtObject {
                    property QtObject id: QtObject { property int rawValue: 0 }
                    property QtObject percentRemaining: QtObject {
                        property real rawValue: 75
                        property string valueString: "75"
                        property string units: "%"
                    }
                    property QtObject voltage: QtObject {
                        property real rawValue: 12.6
                        property string valueString: "12.6"
                        property string units: "V"
                    }
                }
            ]

            // AutoPilot plugin
            property QtObject autopilotPlugin: QtObject {
                function knownVehicleComponentAvailable(type) {
                    return type === MockAutoPilot.KnownPowerVehicleComponent
                }
            }
        }
    }

    // settingsManager mock
    property QtObject settingsManager: QtObject {
        property QtObject batteryIndicatorSettings: QtObject {
            property QtObject valueDisplay: QtObject {
                property int rawValue: 0
                property int value: 0
            }
            property QtObject threshold1: QtObject {
                property int rawValue: 60
            }
            property QtObject threshold2: QtObject {
                property int rawValue: 30
            }

            function setThreshold1(val) { threshold1.rawValue = val }
            function setThreshold2(val) { threshold2.rawValue = val }
        }
    }

    // corePlugin mock
    property QtObject corePlugin: QtObject {
        property bool showAdvancedUI: true
    }

    // globalPalette mock
    property QtObject globalPalette: QtObject {
        property color groupBorder: "#666666"
        property color text: "white"
    }
}

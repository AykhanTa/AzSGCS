// MockAutoPilot.qml - DÜZELTİLDİ!
pragma Singleton
import QtQuick 2.15

QtObject {
    // Property isimleri KÜÇÜK HARFLE başlamalı!
    readonly property int knownRadioVehicleComponent: 0
    readonly property int knownFlightModesVehicleComponent: 1
    readonly property int knownSensorsVehicleComponent: 2
    readonly property int knownSafetyVehicleComponent: 3
    readonly property int knownPowerVehicleComponent: 4  // ⬅️ İHTİYACIMIZ OLAN
    readonly property int unknownVehicleComponent: 5

    // Enum kullanımı için alias (büyük harf için)
    readonly property int KnownPowerVehicleComponent: knownPowerVehicleComponent  // ⬅️ Büyük harf için alias
    // readonly property int KnownRadioVehicleComponent: knownRadioVehicleComponent
}

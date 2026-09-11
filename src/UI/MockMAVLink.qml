// MockMAVLink.qml - DÜZELTİLDİ!
pragma Singleton
import QtQuick 2.15

QtObject {
    // Küçük harfle başla
    readonly property int mavBatteryChargeStateUndefined: 0
    readonly property int mavBatteryChargeStateOk: 1
    readonly property int mavBatteryChargeStateLow: 2
    readonly property int mavBatteryChargeStateCritical: 3
    readonly property int mavBatteryChargeStateEmergency: 4
    readonly property int mavBatteryChargeStateFailed: 5
    readonly property int mavBatteryChargeStateUnhealthy: 6

    // Diğer enum'lar
    readonly property int mavBatteryFunctionUnknown: 0
    readonly property int mavBatteryFunctionAll: 1

    // Orjinal isimler için alias (büyük harf)
    readonly property int MAV_BATTERY_CHARGE_STATE_OK: mavBatteryChargeStateOk
    readonly property int MAV_BATTERY_CHARGE_STATE_LOW: mavBatteryChargeStateLow
    readonly property int MAV_BATTERY_CHARGE_STATE_CRITICAL: mavBatteryChargeStateCritical
    readonly property int MAV_BATTERY_CHARGE_STATE_EMERGENCY: mavBatteryChargeStateEmergency
    readonly property int MAV_BATTERY_CHARGE_STATE_FAILED: mavBatteryChargeStateFailed
    readonly property int MAV_BATTERY_CHARGE_STATE_UNHEALTHY: mavBatteryChargeStateUnhealthy
    readonly property int MAV_BATTERY_FUNCTION_UNKNOWN: mavBatteryFunctionUnknown
    readonly property int MAV_BATTERY_FUNCTION_ALL: mavBatteryFunctionAll
}

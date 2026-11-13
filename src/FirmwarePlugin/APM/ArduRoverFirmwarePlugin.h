/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "APMFirmwarePlugin.h"

struct APMRoverMode
{
    enum Mode : uint32_t{
        MANUAL          = 0,
        ACRO            = 1,
        LEARNING        = 2, // Deprecated
        STEERING        = 3,
        HOLD            = 4,
        LOITER          = 5,
        FOLLOW          = 6,
        SIMPLE          = 7,
        DOCK            = 8,
        CIRCLE          = 9,
        AUTO            = 10,
        RTL             = 11,
        SMART_RTL       = 12,
        GUIDED          = 15,
        INITIALIZING    = 16
    };
};

class ArduRoverFirmwarePlugin : public APMFirmwarePlugin
{
    Q_OBJECT

public:
    explicit ArduRoverFirmwarePlugin(QObject *parent = nullptr);
    ~ArduRoverFirmwarePlugin();

    void guidedModeChangeAltitude(Vehicle* vehicle, double altitudeChange, bool pauseVehicle) override;
    int remapParamNameHigestMinorVersionNumber(int majorVersionNumber) const override;
    const FirmwarePlugin::remapParamNameMajorVersionMap_t& paramNameRemapMajorVersionMap() const override { return _remapParamName; }
    bool supportsNegativeThrust(Vehicle*) const override { return true; }
    bool supportsSmartRTL() const override { return true; }
    QString offlineEditingParamFile(Vehicle *vehicle) const override { Q_UNUSED(vehicle); return QStringLiteral(":/FirmwarePlugin/APM/Rover.OfflineEditing.params"); }

    QString pauseFlightMode() const override;
    QString followFlightMode() const override;
    QString stabilizedFlightMode() const override;
    void updateAvailableFlightModes(FlightModeList &modeList) override;

protected:
    uint32_t _convertToCustomFlightModeEnum(uint32_t val) const override;

    // Flight mode names stay as the autopilot names them, untranslated in every UI language:

    // they are what the pilot knows from the radio, the FC and its documentation.

    const QString _manualFlightMode = QStringLiteral("Manual");
    const QString _acroFlightMode = QStringLiteral("Acro");
    const QString _learningFlightMode = QStringLiteral("Learning");
    const QString _steeringFlightMode = QStringLiteral("Steering");
    const QString _holdFlightMode = QStringLiteral("Hold");
    const QString _loiterFlightMode = QStringLiteral("Loiter");
    const QString _followFlightMode = QStringLiteral("Follow");
    const QString _simpleFlightMode = QStringLiteral("Simple");
    const QString _dockFlightMode = QStringLiteral("Dock");
    const QString _circleFlightMode = QStringLiteral("Circle");
    const QString _autoFlightMode = QStringLiteral("Auto");
    const QString _rtlFlightMode = QStringLiteral("RTL");
    const QString _smartRtlFlightMode = QStringLiteral("Smart RTL");
    const QString _guidedFlightMode = QStringLiteral("Guided");
    const QString _initializingFlightMode = QStringLiteral("Initializing");

private:
    static bool _remapParamNameIntialized;
    static FirmwarePlugin::remapParamNameMajorVersionMap_t _remapParamName;
};

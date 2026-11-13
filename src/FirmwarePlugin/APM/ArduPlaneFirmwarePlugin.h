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

struct APMPlaneMode
{
    enum Mode : uint32_t {
        MANUAL        = 0,
        CIRCLE        = 1,
        STABILIZE     = 2,
        TRAINING      = 3,
        ACRO          = 4,
        FLY_BY_WIRE_A = 5,
        FLY_BY_WIRE_B = 6,
        CRUISE        = 7,
        AUTOTUNE      = 8,
        RESERVED_9    = 9,  // RESERVED FOR FUTURE USE
        AUTO          = 10,
        RTL           = 11,
        LOITER        = 12,
        TAKEOFF       = 13,
        AVOID_ADSB    = 14,
        GUIDED        = 15,
        INITIALIZING  = 16,
        QSTABILIZE    = 17,
        QHOVER        = 18,
        QLOITER       = 19,
        QLAND         = 20,
        QRTL          = 21,
        QAUTOTUNE     = 22,
        QACRO         = 23,
        THERMAL       = 24,
        LOITER2QLAND  = 25,
        AUTOLAND      = 26,
    };
};

class ArduPlaneFirmwarePlugin : public APMFirmwarePlugin
{
    Q_OBJECT

public:
    explicit ArduPlaneFirmwarePlugin(QObject *parent = nullptr);
    ~ArduPlaneFirmwarePlugin();

    QString offlineEditingParamFile(Vehicle *vehicle) const override { Q_UNUSED(vehicle); return QStringLiteral(":/FirmwarePlugin/APM/Plane.OfflineEditing.params"); }
    QString autoDisarmParameter(Vehicle *vehicle) const override { Q_UNUSED(vehicle); return QStringLiteral("LAND_DISARMDELAY"); }
    int remapParamNameHigestMinorVersionNumber(int majorVersionNumber) const override;
    const FirmwarePlugin::remapParamNameMajorVersionMap_t &paramNameRemapMajorVersionMap() const override { return _remapParamName; }
    QString pauseFlightMode() const override;
    QString takeOffFlightMode() const override;
    QString stabilizedFlightMode() const override;
    void updateAvailableFlightModes(FlightModeList &modeList) override;

protected:
    uint32_t _convertToCustomFlightModeEnum(uint32_t val) const override;

    // Flight mode names stay as the autopilot names them, untranslated in every UI language:

    // they are what the pilot knows from the radio, the FC and its documentation.

    const QString _manualFlightMode = QStringLiteral("Manual");
    const QString _circleFlightMode = QStringLiteral("Circle");
    const QString _stabilizeFlightMode = QStringLiteral("Stabilize");
    const QString _trainingFlightMode = QStringLiteral("Training");
    const QString _acroFlightMode = QStringLiteral("Acro");
    const QString _flyByWireAFlightMode = QStringLiteral("FBW A");
    const QString _flyByWireBFlightMode = QStringLiteral("FBW B");
    const QString _cruiseFlightMode = QStringLiteral("Cruise");
    const QString _autoTuneFlightMode = QStringLiteral("Autotune");
    const QString _autoFlightMode = QStringLiteral("Auto");
    const QString _rtlFlightMode = QStringLiteral("RTL");
    const QString _loiterFlightMode = QStringLiteral("Loiter");
    const QString _takeoffFlightMode = QStringLiteral("Takeoff");
    const QString _avoidADSBFlightMode = QStringLiteral("Avoid ADSB");
    const QString _guidedFlightMode = QStringLiteral("Guided");
    const QString _initializingFlightMode = QStringLiteral("Initializing");
    const QString _qStabilizeFlightMode = QStringLiteral("QuadPlane Stabilize");
    const QString _qHoverFlightMode = QStringLiteral("QuadPlane Hover");
    const QString _qLoiterFlightMode = QStringLiteral("QuadPlane Loiter");
    const QString _qLandFlightMode = QStringLiteral("QuadPlane Land");
    const QString _qRTLFlightMode = QStringLiteral("QuadPlane RTL");
    const QString _qAutotuneFlightMode = QStringLiteral("QuadPlane AutoTune");
    const QString _qAcroFlightMode = QStringLiteral("QuadPlane Acro");
    const QString _thermalFlightMode = QStringLiteral("Thermal");
    const QString _loiter2qlandFlightMode = QStringLiteral("Loiter to QLand");
    const QString _autolandFlightMode = QStringLiteral("Autoland");

private:
    static bool _remapParamNameIntialized;
    static FirmwarePlugin::remapParamNameMajorVersionMap_t  _remapParamName;
};

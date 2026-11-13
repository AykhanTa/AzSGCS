/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QLoggingCategory>

#include "FactGroup.h"
#include "APMFirmwarePlugin.h"

Q_DECLARE_LOGGING_CATEGORY(APMSubmarineFactGroupLog)

class APMSubmarineFactGroup : public FactGroup
{
    Q_OBJECT
    Q_PROPERTY(Fact *camTilt                READ camTilt                CONSTANT)
    Q_PROPERTY(Fact *tetherTurns            READ tetherTurns            CONSTANT)
    Q_PROPERTY(Fact *lightsLevel1           READ lightsLevel1           CONSTANT)
    Q_PROPERTY(Fact *lightsLevel2           READ lightsLevel2           CONSTANT)
    Q_PROPERTY(Fact *pilotGain              READ pilotGain              CONSTANT)
    Q_PROPERTY(Fact *inputHold              READ inputHold              CONSTANT)
    Q_PROPERTY(Fact *rangefinderDistance    READ rangefinderDistance    CONSTANT)
    Q_PROPERTY(Fact *rangefinderTarget      READ rangefinderTarget      CONSTANT)

public:
    explicit APMSubmarineFactGroup(QObject *parent = nullptr);
    ~APMSubmarineFactGroup();

    Fact *camTilt() { return &_camTiltFact; }
    Fact *tetherTurns() { return &_tetherTurnsFact; }
    Fact *lightsLevel1() { return &_lightsLevel1Fact; }
    Fact *lightsLevel2() { return &_lightsLevel2Fact; }
    Fact *pilotGain() { return &_pilotGainFact; }
    Fact *inputHold() { return &_inputHoldFact; }
    Fact *rangefinderDistance() { return &_rangefinderDistanceFact; }
    Fact *rangefinderTarget() { return &_rangefinderTargetFact; }

private:
    Fact _camTiltFact = Fact(0, QStringLiteral("cameraTilt"), FactMetaData::valueTypeDouble);
    Fact _tetherTurnsFact = Fact(0, QStringLiteral("tetherTurns"), FactMetaData::valueTypeDouble);
    Fact _lightsLevel1Fact = Fact(0, QStringLiteral("lights1"), FactMetaData::valueTypeDouble);
    Fact _lightsLevel2Fact = Fact(0, QStringLiteral("lights2"), FactMetaData::valueTypeDouble);
    Fact _pilotGainFact = Fact(0, QStringLiteral("pilotGain"), FactMetaData::valueTypeDouble);
    Fact _inputHoldFact = Fact(0, QStringLiteral("inputHold"), FactMetaData::valueTypeDouble);
    Fact _rollPitchToggleFact = Fact(0, QStringLiteral("rollPitchToggle"), FactMetaData::valueTypeDouble);
    Fact _rangefinderDistanceFact = Fact(0, QStringLiteral("rangefinderDistance"), FactMetaData::valueTypeDouble);
    Fact _rangefinderTargetFact = Fact(0, QStringLiteral("rangefinderTarget"), FactMetaData::valueTypeDouble);
};

/*===========================================================================*/

struct APMSubMode
{
    enum Mode : uint32_t {
        STABILIZE         = 0,   // Hold level position
        ACRO              = 1,   // Manual angular rate, throttle
        ALT_HOLD          = 2,   // Depth hold
        AUTO              = 3,   // Full auto to waypoint
        GUIDED            = 4,   // Full auto to coordinate/direction
        RESERVED_5        = 5,
        RESERVED_6        = 6,
        CIRCLE            = 7,   // Auto circling
        RESERVED_8        = 8,
        SURFACE           = 9,   // Auto return to surface
        RESERVED_10       = 10,
        RESERVED_11       = 11,
        RESERVED_12       = 12,
        RESERVED_13       = 13,
        RESERVED_14       = 14,
        RESERVED_15       = 15,
        POSHOLD           = 16,  // Hold position
        RESERVED_17       = 17,
        RESERVED_18       = 18,
        MANUAL            = 19,
        MOTORDETECTION    = 20,
        SURFTRAK          = 21,  // Surface (seafloor) tracking, aka hold range
    };
};

class ArduSubFirmwarePlugin : public APMFirmwarePlugin
{
    Q_OBJECT

public:
    explicit ArduSubFirmwarePlugin(QObject *parent = nullptr);
    ~ArduSubFirmwarePlugin();

    int defaultJoystickTXMode() const override { return 3; }
    void initializeStreamRates(Vehicle *vehicle) override;
    bool isCapable(const Vehicle *vehicle, FirmwareCapabilities capabilities) const override;
    bool supportsThrottleModeCenterZero() const override { return false; }
    bool supportsRadio() const override { return false; }
    bool supportsJSButton() const override { return true; }
    bool supportsMotorInterference() const override { return false; }

    /// Return the resource file which contains the vehicle icon used in the flight view when the view is dark (Satellite for instance)
    QString vehicleImageOpaque(const Vehicle* vehicle) const override { return QStringLiteral("/qmlimages/subVehicleArrowOpaque.png"); }

    /// Return the resource file which contains the vehicle icon used in the flight view when the view is light (Map for instance)
    QString vehicleImageOutline(const Vehicle* vehicle) const override;

    QString brandImageIndoor(const Vehicle *vehicle) const override { Q_UNUSED(vehicle); return QStringLiteral("/qmlimages/APM/BrandImageSub"); }
    QString brandImageOutdoor(const Vehicle *vehicle) const override { Q_UNUSED(vehicle); return QStringLiteral("/qmlimages/APM/BrandImageSub"); }
    const FirmwarePlugin::remapParamNameMajorVersionMap_t& paramNameRemapMajorVersionMap() const override { return _remapParamName; }
    int remapParamNameHigestMinorVersionNumber(int majorVersionNumber) const override;
    const QVariantList &toolIndicators(const Vehicle *vehicle) override;
    const QVariantList &modeIndicators(const Vehicle *vehicle) override;
    bool adjustIncomingMavlinkMessage(Vehicle *vehicle, mavlink_message_t *message) override;
    QMap<QString, FactGroup*> *factGroups() override;
    void adjustMetaData(MAV_TYPE vehicleType, FactMetaData *metaData) override;

    QString stabilizedFlightMode() const override;
    QString motorDetectionFlightMode() const override;
    void updateAvailableFlightModes(FlightModeList &modeList) override;

    QString offlineEditingParamFile(Vehicle *vehicle) const override { Q_UNUSED(vehicle); return QStringLiteral(":/FirmwarePlugin/APM/Sub.OfflineEditing.params"); }

protected:
    uint32_t _convertToCustomFlightModeEnum(uint32_t val) const override;

    // Flight mode names stay as the autopilot names them, untranslated in every UI language:

    // they are what the pilot knows from the radio, the FC and its documentation.

    const QString _manualFlightMode = QStringLiteral("Manual");
    const QString _stabilizeFlightMode = QStringLiteral("Stabilize");
    const QString _acroFlightMode = QStringLiteral("Acro");
    const QString _altHoldFlightMode = QStringLiteral("Depth Hold");
    const QString _autoFlightMode = QStringLiteral("Auto");
    const QString _guidedFlightMode = QStringLiteral("Guided");
    const QString _circleFlightMode = QStringLiteral("Circle");
    const QString _surfaceFlightMode = QStringLiteral("Surface");
    const QString _posHoldFlightMode =QStringLiteral("Position Hold");
    const QString _motorDetectionFlightMode = QStringLiteral("Motor Detection");
    const QString _surftrakFlightMode = QStringLiteral("Surftrak");

private:
    QVariantList _toolIndicators;
    QVariantList _modeIndicators;
    static bool _remapParamNameIntialized;
    QMap<QString, QString> _factRenameMap;
    static FirmwarePlugin::remapParamNameMajorVersionMap_t _remapParamName;
    void _handleNamedValueFloat(mavlink_message_t *message);
    void _handleMavlinkMessage(mavlink_message_t *message);

    QMap<QString, FactGroup*> _nameToFactGroupMap;
    APMSubmarineFactGroup _infoFactGroup;
};

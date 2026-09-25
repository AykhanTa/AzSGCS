/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "AirframeComponentController.h"
#include "AirframeComponentAirframes.h"
#include "MultiVehicleManager.h"
#include "QGCApplication.h"
#include "LinkManager.h"
#include "Fact.h"
#include "Vehicle.h"
#include "ParameterManager.h"

#include <QtCore/QSettings>
#include <QtCore/QThread>
#include <QtCore/QVariant>
#include <QtGui/QCursor>

bool AirframeComponentController::_typesRegistered = false;

/// QSettings group holding the applied card per autostart id.
static const char *kAirframeSelectionSettingsGroup = "AirframeSelection";

QString AirframeComponentController::savedAirframeGroup(int autostartId)
{
    QSettings settings;
    settings.beginGroup(kAirframeSelectionSettingsGroup);
    return settings.value(QString::number(autostartId)).toString();
}

void AirframeComponentController::saveAirframeGroup(int autostartId, const QString &group)
{
    if (group.isEmpty()) {
        return;
    }

    QSettings settings;
    settings.beginGroup(kAirframeSelectionSettingsGroup);
    settings.setValue(QString::number(autostartId), group);
}

AirframeComponentController::AirframeComponentController(void) :
    _currentVehicleIndex(0),
    _autostartId(0),
    _showCustomConfigPanel(false)
{
    if (!_typesRegistered) {
        _typesRegistered = true;
    }
    
    QStringList usedParams;
    usedParams << "SYS_AUTOSTART" << "SYS_AUTOCONFIG";
    if (!_allParametersExists(ParameterManager::defaultComponentId, usedParams)) {
        return;
    }
    
    // Load up member variables
    
    bool autostartFound = false;
    _autostartId = getParameterFact(ParameterManager::defaultComponentId, "SYS_AUTOSTART")->rawValue().toInt();
    _currentVehicleName = QString::number(_autostartId); // Temp val. Replaced with actual vehicle name if found

    // The card the user applied for this id, if it was this ground station that applied it.
    const QString rememberedGroup = savedAirframeGroup(_autostartId);
    bool selectionRemembered = false;
    
    for (int tindex = 0; tindex < AirframeComponentAirframes::get().count(); tindex++) {

        const AirframeComponentAirframes::AirframeType_t* pType = AirframeComponentAirframes::get().values().at(tindex);

        AirframeType* airframeType = new AirframeType(pType->name, pType->imageResource, this);
        Q_CHECK_PTR(airframeType);

        // Cards deliberately share an autostart id when one airframe flies another's
        // configuration (see PX4AirframeLoader::_insertCustomAirframes), so a repeat across
        // groups is expected and the secondary ones yield the selection. Only a repeat within
        // one group is a meta data error, which is what this counts.
        int matchesInGroup = 0;

        for (int index = 0; index < pType->rgAirframeInfo.count(); index++) {
            const AirframeComponentAirframes::AirframeInfo_t* pInfo = pType->rgAirframeInfo.at(index);
            Q_CHECK_PTR(pInfo);

            if (_autostartId == pInfo->autostartId) {
                matchesInGroup++;
                if (matchesInGroup > 1) {
                    qWarning() << "AirframeComponentController::AirframeComponentController duplicate ids found:" << _autostartId;
                }

                const bool isRemembered = !rememberedGroup.isEmpty() && (pType->name == rememberedGroup);

                bool claimsSelection;
                if (!autostartFound) {
                    claimsSelection = true;
                } else if (selectionRemembered) {
                    // What the user actually applied outranks every other rule.
                    claimsSelection = false;
                } else if (isRemembered) {
                    claimsSelection = true;
                } else {
                    claimsSelection = !pType->secondary;
                }
                autostartFound = true;

                if (claimsSelection) {
                    selectionRemembered = isRemembered;
                    _currentAirframeType = pType->name;
                    _currentVehicleName = pInfo->name;
                    _currentVehicleIndex = index;
                }
            }
            airframeType->addAirframe(pInfo->name, pInfo->autostartId);
        }
        
        _airframeTypes.append(QVariant::fromValue(airframeType));
    }
    
    if (_autostartId != 0 && !autostartFound) {
        _showCustomConfigPanel = true;
        emit showCustomConfigPanelChanged(true);
    }
}

AirframeComponentController::~AirframeComponentController()
{

}

void AirframeComponentController::changeAutostart(void)
{
    if (MultiVehicleManager::instance()->vehicles()->count() > 1) {
        qgcApp()->showAppMessage(tr("You cannot change airframe configuration while connected to multiple vehicles."));
                return;
        }
    QGuiApplication::setOverrideCursor(QCursor(Qt::WaitCursor));

    // Record the card before the vehicle reboots. It reports back only SYS_AUTOSTART, which two
    // cards can share, so this is the only place the choice between them can be kept.
    saveAirframeGroup(_autostartId, _currentAirframeType);

    Fact* sysAutoStartFact  = getParameterFact(-1, "SYS_AUTOSTART");
    Fact* sysAutoConfigFact = getParameterFact(-1, "SYS_AUTOCONFIG");
    
    // We need to wait for the vehicleUpdated signals to come back before we reboot
    _waitParamWriteSignalCount = 0;
    connect(sysAutoStartFact, &Fact::vehicleUpdated, this, &AirframeComponentController::_waitParamWriteSignal);
    connect(sysAutoConfigFact, &Fact::vehicleUpdated, this, &AirframeComponentController::_waitParamWriteSignal);
    
    // We use forceSetValue to ensure params are sent even if the previous value is that same as the new value
    sysAutoStartFact->forceSetRawValue(_autostartId);
    sysAutoConfigFact->forceSetRawValue(1);
}

void AirframeComponentController::_waitParamWriteSignal(QVariant value)
{
    Q_UNUSED(value);
    
    _waitParamWriteSignalCount++;
    if (_waitParamWriteSignalCount == 2) {
        // Now that both params have made it to the vehicle we can reboot it. All these signals are flying
        // around on the main thread, so we need to allow the stack to unwind back to the event loop before
        // we reboot.
        QTimer::singleShot(800, this, &AirframeComponentController::_rebootAfterStackUnwind);
    }
}

void AirframeComponentController::_rebootAfterStackUnwind(void)
{    
    _vehicle->sendMavCommand(_vehicle->defaultComponentId(), MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN, true /* showError */, 1.0f);
    QCoreApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
    for (unsigned i = 0; i < 2000; i++) {
        QThread::usleep(500);
        QCoreApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
    }
    QGuiApplication::restoreOverrideCursor();
    LinkManager::instance()->disconnectAll();
}

AirframeType::AirframeType(const QString& name, const QString& imageResource, QObject* parent) :
    QObject(parent),
    _name(name),
    _imageResource(imageResource)
{
    
}

AirframeType::~AirframeType()
{
    
}

void AirframeType::addAirframe(const QString& name, int autostartId)
{
    Airframe* airframe = new Airframe(name, autostartId);
    Q_CHECK_PTR(airframe);
    
    _airframes.append(QVariant::fromValue(airframe));
}

Airframe::Airframe(const QString& name, int autostartId, QObject* parent) :
    QObject(parent),
    _name(name),
    _autostartId(autostartId)
{
    
}

Airframe::~Airframe()
{
    
}

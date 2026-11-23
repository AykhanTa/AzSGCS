















// #include "ExternalPositionManager.h"

// #include "MAVLink/MAVLinkLib.h"
// #include "mavlink/v2.0/intercept/mavlink_msg_intercept.h"


// #include "MAVLinkProtocol.h"
// #include "Vehicle/Vehicle.h"
// #include <QtCore/QDateTime>
// #include <QtCore/QDebug>





#include "ExternalPositionManager.h"
#include "ExternalTrajectoryPoints.h"

// MAVLinkProtocol.h özü MAVLinkLib.h-ı düzgün sıra ilə include edir
// Birbaşa MAVLinkLib.h include etmə — operator& konflikti yaranır
#include "MAVLinkProtocol.h"


// Vehicle
#include "Vehicle/Vehicle.h"
#include "Vehicle/VehicleLinkManager.h"

// Qt
#include <QtCore/QDateTime>
#include <QtCore/QDebug>
#include <QtPositioning/QGeoCoordinate>

ExternalPositionManager::ExternalPositionManager(quint16 port, QObject *parent)
    : QObject(parent)
      , _port(port)
{
    _thread = new QThread(this);
    _thread->setObjectName("ExternalPositionThread");

    _trajectoryPoints = new ExternalTrajectoryPoints(this);
}

ExternalPositionManager::~ExternalPositionManager()
{
    stopListening();
}

void ExternalPositionManager::setVehicle(Vehicle *vehicle)
{
    _vehicle = vehicle;
}

void ExternalPositionManager::start()
{
    startListening(_port);
}

void ExternalPositionManager::stop()
{
    stopListening();
}

void ExternalPositionManager::setSendEnabled(bool v)
{
    if (_sendEnabled == v) return;
    _sendEnabled = v;
    emit sendEnabledChanged(v);
    //qDebug() << "[ExternalPos] MAVLink göndərmə:" << (v ? "AKTİV" : "PASİV");
}

void ExternalPositionManager::startListening(quint16 port)
{
    //qDebug() << "[ExternalPos] startListening:" << port;

    if (_thread->isRunning()) {
        if (_worker) {
            QMetaObject::invokeMethod(
                _worker, "stop", Qt::BlockingQueuedConnection);
        }
        _thread->quit();
        if (!_thread->wait(3000)) {
            _thread->terminate();
            _thread->wait();
        }
    }

    _thread->disconnect();
    _worker = nullptr;

    resetPosition();

    _port = port;
    emit listenPortChanged(_port);

    _restartWorker(port);
}

void ExternalPositionManager::stopListening()
{
    //qDebug() << "[ExternalPos] stopListening";

    if (_thread->isRunning()) {
        if (_worker) {
            QMetaObject::invokeMethod(
                _worker, "stop", Qt::BlockingQueuedConnection);
        }
        _thread->quit();
        if (!_thread->wait(3000)) {
            _thread->terminate();
            _thread->wait();
        }
    }

    _thread->disconnect();
    _worker    = nullptr;
    _listening = false;
    _active    = false;

    if (_trajectoryPoints) {
        _trajectoryPoints->clear();
    }

    emit listeningChanged(false);
    emit activeChanged(false);
}

void ExternalPositionManager::resetPosition()
{
    _lat      = 0.0;
    _lon      = 0.0;
    _alt      = 0.0f;
    _spd      = 0.0f;
    _pktCount = 0;
    if (_trajectoryPoints) {
        _trajectoryPoints->clear();
    }
    emit positionUpdated(_lat, _lon, _alt, _spd);
}

void ExternalPositionManager::_restartWorker(quint16 port)
{
    _worker = new ExternalPositionWorker(port);
    _worker->moveToThread(_thread);

    connect(_thread, &QThread::started,
            _worker, &ExternalPositionWorker::start);

    connect(_thread, &QThread::finished,
            _worker, &QObject::deleteLater);

    connect(_worker, &ExternalPositionWorker::positionReceived,
            this,    &ExternalPositionManager::_onPositionReceived,
            Qt::QueuedConnection);

    connect(_worker, &ExternalPositionWorker::statusChanged,
            this,    &ExternalPositionManager::_onStatusChanged,
            Qt::QueuedConnection);

    _thread->start();

    _listening = true;
    emit listeningChanged(true);

    //qDebug() << "[ExternalPos] Worker başladı, port:" << port;
}

void ExternalPositionManager::_onPositionReceived(ExternalPositionData data)
{
    // Böyük mövqe sıçrayışını aşkarla (emulator dayandırılıb yenidən başladılanda
    // pozisiya başlanğıc nöqtəsinə "tullanır"). Real hərəkət üçün mümkün olmayan qədər
    // böyük sıçrayış varsa köhnə track-i sıfırla ki, köhnə son nöqtə ilə yeni başlanğıc
    // nöqtəsi arasında qəribə uzun xətt çəkilməsin. (Timeout tez restart-da işə düşməyə
    // bilər, ona görə əsas həll budur.)
    static constexpr double kMaxTrajectoryJumpMeters = 500.0;
    if (_trajectoryPoints && (_trajectoryPoints->count() > 0)) {
        const QGeoCoordinate prev(_lat, _lon);
        const QGeoCoordinate next(data.lat, data.lon);
        if (prev.isValid() && next.isValid() &&
            (prev.distanceTo(next) > kMaxTrajectoryJumpMeters)) {
            _trajectoryPoints->clear();
        }
    }

    _lat = data.lat;
    _lon = data.lon;
    _alt = data.alt;
    _spd = data.spd;
    _pktCount++;

    if (_trajectoryPoints) {
        _trajectoryPoints->addCoordinate(QGeoCoordinate(_lat, _lon, _alt));
    }

    emit positionUpdated(_lat, _lon, _alt, _spd);

    qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (_sendEnabled && _vehicle && (now - _lastSendMs) >= SEND_INTERVAL_MS) {
        _lastSendMs = now;
        _sendMavlinkIntercept();
    }
}

void ExternalPositionManager::_onStatusChanged(bool active, QString message)
{
    if (_active != active) {
        _active = active;
        emit activeChanged(_active);

        // Data kəsiləndə (timeout) köhnə trayektoriyanı sıfırla. Əks halda data
        // yenidən gələndə köhnə son nöqtə ilə yeni nöqtə arasında boşluq üzərindən
        // qəribə uzun xətt çəkilir. Beləliklə hər yeni axın təmiz track kimi başlayır.
        if (!active && _trajectoryPoints) {
            _trajectoryPoints->clear();
        }
    }
    // qDebug() << "[ExternalPositionManager]"
    //          << (active ? "AKTİV" : "PASİV")
    //          << message;
}

void ExternalPositionManager::_sendMavlinkIntercept()
{
    if (!_vehicle || !_vehicle->vehicleLinkManager()) {
        emit mavlinkSendError(QStringLiteral("Vehicle yoxdur"));
        return;
    }

    const auto sharedLink =
        _vehicle->vehicleLinkManager()->primaryLink().lock();

    if (!sharedLink) {
        emit mavlinkSendError(QStringLiteral("Primary link yoxdur"));
        return;
    }

            // Custom intercept mesajı
            // MAVLinkProtocol.h vasitəsilə MAVLink artıq include edilib
    mavlink_intercept_t pkt{};
    pkt.target_system    = static_cast<uint8_t>(_vehicle->id());
    pkt.target_component = static_cast<uint8_t>(_vehicle->defaultComponentId());
    pkt.time_usec        = static_cast<uint64_t>(
                        QDateTime::currentMSecsSinceEpoch()) * 1000ULL;
    pkt.intercept_lat    = static_cast<int32_t>(_lat * 1e7);
    pkt.intercept_lon    = static_cast<int32_t>(_lon * 1e7);
    pkt.intercept_alt    = _alt;
    pkt.intercept_vel    = _spd;

    mavlink_message_t msg{};
    mavlink_msg_intercept_encode_chan(
        static_cast<uint8_t>(MAVLinkProtocol::instance()->getSystemId()),
        static_cast<uint8_t>(MAVLinkProtocol::instance()->getComponentId()),
        sharedLink->mavlinkChannel(),
        &msg,
        &pkt);

    if (!_vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg)) {
        emit mavlinkSendError(
            tr("INTERCEPT göndərilməsi uğursuz oldu"));
    }

    // qDebug() << "[ExternalPos] INTERCEPT göndərildi:"
    //          << _lat << _lon << _alt << _spd;
}

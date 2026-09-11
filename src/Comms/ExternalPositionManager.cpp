// // // #include "ExternalPositionManager.h"

// // // //#include "Vehicle.h"

// // // //#include <mavlink.h>

// // // ExternalPositionManager::ExternalPositionManager(quint16 port, QObject *parent)
// // //     : QObject(parent)
// // //       , _port(port)
// // // {
// // //     _thread = new QThread(this);
// // //     _thread->setObjectName("ExternalPositionThread");

// // //     _worker = new ExternalPositionWorker(_port);
// // //     _worker->moveToThread(_thread);

// // //     connect(_thread, &QThread::started,
// // //             _worker, &ExternalPositionWorker::start);

// // //     connect(_thread, &QThread::finished,
// // //             _worker, &QObject::deleteLater);

// // //     connect(_worker, &ExternalPositionWorker::positionReceived,
// // //             this,    &ExternalPositionManager::_onPositionReceived,
// // //             Qt::QueuedConnection);

// // //     connect(_worker, &ExternalPositionWorker::statusChanged,
// // //             this,    &ExternalPositionManager::_onStatusChanged,
// // //             Qt::QueuedConnection);
// // // }

// // // ExternalPositionManager::~ExternalPositionManager()
// // // {
// // //     stop();
// // // }

// // // void ExternalPositionManager::setVehicle(Vehicle *vehicle)
// // // {
// // //     _vehicle = vehicle;
// // // }

// // // void ExternalPositionManager::start()
// // // {
// // //     if (!_thread->isRunning()) {
// // //         _thread->start();
// // //     }
// // // }

// // // void ExternalPositionManager::stop()
// // // {
// // //     if (_thread->isRunning()) {
// // //         QMetaObject::invokeMethod(_worker, "stop", Qt::QueuedConnection);
// // //         _thread->quit();
// // //         _thread->wait(3000);
// // //     }
// // // }

// // // void ExternalPositionManager::_onPositionReceived(ExternalPositionData data)
// // // {
// // //     _lat = data.lat;
// // //     _lon = data.lon;
// // //     _alt = data.alt;
// // //     _hdg = data.hdg;
// // //     _pktCount++;

// // //     emit positionUpdated(_lat, _lon, _alt, _hdg);

// // //     // if (_vehicle) {
// // //     //     mavlink_message_t msg;
// // //     //     mavlink_set_position_target_global_int_t tgt{};

// // //     //     tgt.target_system    = static_cast<uint8_t>(_vehicle->id());
// // //     //     tgt.target_component = MAV_COMP_ID_AUTOPILOT1;
// // //     //     tgt.coordinate_frame = MAV_FRAME_GLOBAL_RELATIVE_ALT_INT;
// // //     //     tgt.type_mask        = 0b0000111111111000;
// // //     //     tgt.lat_int          = static_cast<int32_t>(_lat * 1e7);
// // //     //     tgt.lon_int          = static_cast<int32_t>(_lon * 1e7);
// // //     //     tgt.alt              = _alt;
// // //     //     tgt.yaw              = _hdg * static_cast<float>(M_PI) / 180.0f;

// // //     //     mavlink_msg_set_position_target_global_int_encode(
// // //     //         255, MAV_COMP_ID_MISSIONPLANNER, &msg, &tgt);

// // //     //     _vehicle->sendMessageOnLinkThreadSafe(
// // //     //         _vehicle->priorityLink(), msg);
// // //     // }
// // // }

// // // void ExternalPositionManager::_onStatusChanged(bool active, QString message)
// // // {
// // //     if (_active != active) {
// // //         _active = active;
// // //         emit activeChanged(_active);
// // //     }
// // //     qDebug() << "[ExternalPositionManager]"
// // //              << (active ? "AKTİV" : "PASİV")
// // //              << message;
// // // }







// // #include "ExternalPositionManager.h"

// // ExternalPositionManager::ExternalPositionManager(quint16 port, QObject *parent)
// //     : QObject(parent)
// //       , _port(port)
// // {
// //     // Thread sadece yaradılır, _restartWorker çağırılana qədər başlamır
// //     _thread = new QThread(this);
// //     _thread->setObjectName("ExternalPositionThread");
// // }

// // ExternalPositionManager::~ExternalPositionManager()
// // {
// //     stopListening();
// // }

// // void ExternalPositionManager::setVehicle(Vehicle *vehicle)
// // {
// //     _vehicle = vehicle;
// // }

// // // Köhnə API — avtomatik olaraq default port ilə başladır
// // void ExternalPositionManager::start()
// // {
// //     startListening(_port);
// // }

// // void ExternalPositionManager::stop()
// // {
// //     stopListening();
// // }

// // void ExternalPositionManager::startListening(quint16 port)
// // {
// //     // Əvvəlki worker-i dayandır
// //     if (_thread->isRunning()) {
// //         if (_worker) {
// //             QMetaObject::invokeMethod(_worker, "stop", Qt::BlockingQueuedConnection);
// //         }
// //         _thread->quit();
// //         _thread->wait(3000);
// //     }

// //     _port = port;
// //     emit listenPortChanged(_port);

// //     _restartWorker(port);
// // }

// // void ExternalPositionManager::stopListening()
// // {
// //     if (_thread->isRunning()) {
// //         if (_worker) {
// //             QMetaObject::invokeMethod(_worker, "stop", Qt::QueuedConnection);
// //         }
// //         _thread->quit();
// //         _thread->wait(3000);
// //     }

// //     _listening = false;
// //     _active    = false;
// //     emit listeningChanged(false);
// //     emit activeChanged(false);
// // }

// // void ExternalPositionManager::_restartWorker(quint16 port)
// // {
// //     _worker = new ExternalPositionWorker(port);
// //     _worker->moveToThread(_thread);

// //     connect(_thread, &QThread::started,
// //             _worker, &ExternalPositionWorker::start);

// //     connect(_thread, &QThread::finished,
// //             _worker, &QObject::deleteLater);

// //     connect(_worker, &ExternalPositionWorker::positionReceived,
// //             this,    &ExternalPositionManager::_onPositionReceived,
// //             Qt::QueuedConnection);

// //     connect(_worker, &ExternalPositionWorker::statusChanged,
// //             this,    &ExternalPositionManager::_onStatusChanged,
// //             Qt::QueuedConnection);

// //     _thread->start();

// //     _listening = true;
// //     emit listeningChanged(true);
// // }

// // void ExternalPositionManager::_onPositionReceived(ExternalPositionData data)
// // {
// //     _lat = data.lat;
// //     _lon = data.lon;
// //     _alt = data.alt;
// //     _hdg = data.hdg;
// //     _pktCount++;
// //     emit positionUpdated(_lat, _lon, _alt, _hdg);
// // }

// // void ExternalPositionManager::_onStatusChanged(bool active, QString message)
// // {
// //     if (_active != active) {
// //         _active = active;
// //         emit activeChanged(_active);
// //     }
// //     qDebug() << "[ExternalPositionManager]"
// //              << (active ? "AKTİV" : "PASİV")
// //              << message;
// // }








// #include "ExternalPositionManager.h"
// // #include "Vehicle.h"
// // #include <mavlink.h>
// #include <QtCore/QDateTime>

// ExternalPositionManager::ExternalPositionManager(quint16 port, QObject *parent)
//     : QObject(parent)
//       , _port(port)
// {
//     _thread = new QThread(this);
//     _thread->setObjectName("ExternalPositionThread");
// }

// ExternalPositionManager::~ExternalPositionManager()
// {
//     stopListening();
// }

// void ExternalPositionManager::setVehicle(Vehicle *vehicle)
// {
//     _vehicle = vehicle;
// }

// void ExternalPositionManager::start()
// {
//     startListening(_port);
// }

// void ExternalPositionManager::stop()
// {
//     stopListening();
// }

// void ExternalPositionManager::setSendEnabled(bool v)
// {
//     if (_sendEnabled == v) return;
//     _sendEnabled = v;
//     emit sendEnabledChanged(v);
//     qDebug() << "[ExternalPos] MAVLink göndərmə:" << (v ? "AKTİV" : "PASİV");
// }

// void ExternalPositionManager::startListening(quint16 port)
// {
//     if (_thread->isRunning()) {
//         if (_worker) {
//             QMetaObject::invokeMethod(_worker, "stop", Qt::BlockingQueuedConnection);
//         }
//         _thread->quit();
//         _thread->wait(3000);
//     }

//     resetPosition();

//     _port = port;
//     emit listenPortChanged(_port);

//     _restartWorker(port);
// }

// void ExternalPositionManager::stopListening()
// {
//     if (_thread->isRunning()) {
//         if (_worker) {
//             QMetaObject::invokeMethod(_worker, "stop", Qt::QueuedConnection);
//         }
//         _thread->quit();
//         _thread->wait(3000);
//     }

//     _listening = false;
//     _active    = false;
//     emit listeningChanged(false);
//     emit activeChanged(false);
// }

// void ExternalPositionManager::resetPosition()
// {
//     _lat      = 0.0;
//     _lon      = 0.0;
//     _alt      = 0.0f;
//     _spd      = 0.0f;
//     _pktCount = 0;
//     emit positionUpdated(_lat, _lon, _alt, _spd);
// }

// void ExternalPositionManager::_restartWorker(quint16 port)
// {
//     _worker = new ExternalPositionWorker(port);
//     _worker->moveToThread(_thread);

//     connect(_thread, &QThread::started,
//             _worker, &ExternalPositionWorker::start);

//     connect(_thread, &QThread::finished,
//             _worker, &QObject::deleteLater);

//     connect(_worker, &ExternalPositionWorker::positionReceived,
//             this,    &ExternalPositionManager::_onPositionReceived,
//             Qt::QueuedConnection);

//     connect(_worker, &ExternalPositionWorker::statusChanged,
//             this,    &ExternalPositionManager::_onStatusChanged,
//             Qt::QueuedConnection);

//     _thread->start();

//     _listening = true;
//     emit listeningChanged(true);
// }

// void ExternalPositionManager::_onPositionReceived(ExternalPositionData data)
// {
//     _lat = data.lat;
//     _lon = data.lon;
//     _alt = data.alt;
//     _spd = data.spd;
//     _pktCount++;

//     emit positionUpdated(_lat, _lon, _alt, _spd);

//             // Throttle: maksimum 10 Hz göndər
//     qint64 now = QDateTime::currentMSecsSinceEpoch();
//     if (_sendEnabled && _vehicle && (now - _lastSendMs) >= SEND_INTERVAL_MS) {
//         _lastSendMs = now;
//         _sendMavlinkGpsInput();
//     }
// }

// void ExternalPositionManager::_onStatusChanged(bool active, QString message)
// {
//     if (_active != active) {
//         _active = active;
//         emit activeChanged(_active);
//     }
//     qDebug() << "[ExternalPositionManager]"
//              << (active ? "AKTİV" : "PASİV")
//              << message;
// }

// void ExternalPositionManager::_sendMavlinkGpsInput()
// {
//    // Vehicle.h və mavlink.h include edildikdən sonra aktiv ediləcək
//    //
//    // if (!_vehicle) return;
//    //
//    // mavlink_gps_input_t gps{};
//    // gps.time_usec          = static_cast<quint64>(
//    //                            QDateTime::currentMSecsSinceEpoch()) * 1000ULL;
//    // gps.gps_id             = 0;
//    // gps.ignore_flags       = GPS_INPUT_IGNORE_FLAG_VEL_HORIZ |
//    //                          GPS_INPUT_IGNORE_FLAG_VEL_VERT  |
//    //                          GPS_INPUT_IGNORE_FLAG_SPEED_ACCURACY;
//    // gps.lat                = static_cast<qint32>(_lat * 1e7);
//    // gps.lon                = static_cast<qint32>(_lon * 1e7);
//    // gps.alt                = _alt;
//    // gps.hdop               = 1.0f;
//    // gps.vdop               = 1.0f;
//    // gps.fix_type           = 3;
//    // gps.satellites_visible = 12;
//    // gps.speed_accuracy     = 0.5f;
//    // gps.horiz_accuracy     = 1.0f;
//    // gps.vert_accuracy      = 1.5f;
//    //
//    // // Sürət — spd horizontal speed kimi göndərilir
//    // gps.vn = _spd;   // north komponent (sadələşdirilmiş)
//    // gps.ve = 0.0f;
//    // gps.vd = 0.0f;
//    //
//    // mavlink_message_t msg;
//    // mavlink_msg_gps_input_encode(255, MAV_COMP_ID_MISSIONPLANNER, &msg, &gps);
//    //
//    // if (_vehicle->vehicleLinkManager() &&
//    //     _vehicle->vehicleLinkManager()->primaryLink())
//    // {
//    //     _vehicle->sendMessageOnLinkThreadSafe(
//    //         _vehicle->vehicleLinkManager()->primaryLink().get(), msg);
//    // }
// }



// #include "ExternalPositionManager.h"

// #include "MAVLink/MAVLinkLib.h"
// #include "mavlink/v2.0/intercept/mavlink_msg_intercept.h"


// #include "MAVLinkProtocol.h"
// #include "Vehicle/Vehicle.h"
// #include <QtCore/QDateTime>
// #include <QtCore/QDebug>


// ExternalPositionManager::ExternalPositionManager(quint16 port, QObject *parent)
//     : QObject(parent)
//       , _port(port)
// {
//     _thread = new QThread(this);
//     _thread->setObjectName("ExternalPositionThread");
// }

// ExternalPositionManager::~ExternalPositionManager()
// {
//     stopListening();
// }

// void ExternalPositionManager::setVehicle(Vehicle *vehicle)
// {
//     _vehicle = vehicle;
// }

// void ExternalPositionManager::start()
// {
//     startListening(_port);
// }

// void ExternalPositionManager::stop()
// {
//     stopListening();
// }

// void ExternalPositionManager::setSendEnabled(bool v)
// {
//     if (_sendEnabled == v) return;
//     _sendEnabled = v;
//     emit sendEnabledChanged(v);
//     qDebug() << "[ExternalPos] MAVLink göndərmə:" << (v ? "AKTİV" : "PASİV");
// }

// void ExternalPositionManager::startListening(quint16 port)
// {
//     if (_thread->isRunning()) {
//         if (_worker) {
//             QMetaObject::invokeMethod(_worker, "stop", Qt::BlockingQueuedConnection);
//         }
//         _thread->quit();
//         _thread->wait(3000);
//     }

//     resetPosition();

//     _port = port;
//     emit listenPortChanged(_port);

//     _restartWorker(port);
// }

// void ExternalPositionManager::stopListening()
// {
//     if (_thread->isRunning()) {
//         if (_worker) {
//             QMetaObject::invokeMethod(_worker, "stop", Qt::QueuedConnection);
//         }
//         _thread->quit();
//         _thread->wait(3000);
//     }

//     _listening = false;
//     _active    = false;
//     emit listeningChanged(false);
//     emit activeChanged(false);
// }

// void ExternalPositionManager::resetPosition()
// {
//     _lat      = 0.0;
//     _lon      = 0.0;
//     _alt      = 0.0f;
//     _spd      = 0.0f;
//     _pktCount = 0;
//     emit positionUpdated(_lat, _lon, _alt, _spd);
// }

// void ExternalPositionManager::_restartWorker(quint16 port)
// {
//     _worker = new ExternalPositionWorker(port);
//     _worker->moveToThread(_thread);

//     connect(_thread, &QThread::started,
//             _worker, &ExternalPositionWorker::start);

//     connect(_thread, &QThread::finished,
//             _worker, &QObject::deleteLater);

//     connect(_worker, &ExternalPositionWorker::positionReceived,
//             this,    &ExternalPositionManager::_onPositionReceived,
//             Qt::QueuedConnection);

//     connect(_worker, &ExternalPositionWorker::statusChanged,
//             this,    &ExternalPositionManager::_onStatusChanged,
//             Qt::QueuedConnection);

//     _thread->start();

//     _listening = true;
//     emit listeningChanged(true);
// }

// void ExternalPositionManager::_onPositionReceived(ExternalPositionData data)
// {
//     _lat = data.lat;
//     _lon = data.lon;
//     _alt = data.alt;
//     _spd = data.spd;
//     _pktCount++;

//     emit positionUpdated(_lat, _lon, _alt, _spd);

//             // Throttle: maksimum 10 Hz göndər
//     qint64 now = QDateTime::currentMSecsSinceEpoch();
//     if (_sendEnabled && _vehicle && (now - _lastSendMs) >= SEND_INTERVAL_MS) {
//         _lastSendMs = now;
//         _sendMavlinkIntercept();
//     }
// }

// void ExternalPositionManager::_onStatusChanged(bool active, QString message)
// {
//     if (_active != active) {
//         _active = active;
//         emit activeChanged(_active);
//     }
//     qDebug() << "[ExternalPositionManager]"
//              << (active ? "AKTİV" : "PASİV")
//              << message;
// }

// void ExternalPositionManager::_sendMavlinkIntercept()
// {
//     if (!_vehicle || !_vehicle->vehicleLinkManager()) {
//         emit mavlinkSendError(QStringLiteral("Vehicle yoxdur"));
//         return;
//     }

//     const auto sharedLink = _vehicle->vehicleLinkManager()->primaryLink().lock();

//     if (!sharedLink) {
//         emit mavlinkSendError(QStringLiteral("Primary link yoxdur"));
//         return;
//     }

//     mavlink_msg_intercept_t pkt{};
//     pkt.target_system    = static_cast<uint8_t>(_vehicle->id());
//     pkt.target_component = static_cast<uint8_t>(_vehicle->defaultComponentId());
//     pkt.time_usec        = static_cast<uint64_t>(QDateTime::currentMSecsSinceEpoch()) * 1000ULL;
//     pkt.intercept_lat    = static_cast<int32_t>(_lat * 1e7);
//     pkt.intercept_lon    = static_cast<int32_t>(_lon * 1e7);
//     pkt.intercept_alt    = _alt;
//     pkt.intercept_vel    = _spd;

//     mavlink_message_t msg{};
//     mavlink_msg_intercept_encode_chan(
//         static_cast<uint8_t>(MAVLinkProtocol::instance()->getSystemId()),
//         static_cast<uint8_t>(MAVLinkProtocol::getComponentId()),
//         sharedLink->mavlinkChannel(),
//         &msg,
//         &pkt);

//     if (!_vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg)) {
//         emit mavlinkSendError(QStringLiteral("INTERCEPT göndərilməsi uğursuz oldu"));
//     }
// }




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
            QStringLiteral("INTERCEPT göndərilməsi uğursuz oldu"));
    }

    // qDebug() << "[ExternalPos] INTERCEPT göndərildi:"
    //          << _lat << _lon << _alt << _spd;
}

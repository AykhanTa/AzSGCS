/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "TerrainQueryInterface.h"
#include "TerrainTileManager.h"
#include "QGCLoggingCategory.h"

#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkProxy>
#include <QtPositioning/QGeoCoordinate>

QGC_LOGGING_CATEGORY(TerrainQueryInterfaceLog, "qgc.terrain.terrainqueryinterface")

TerrainQueryInterface::TerrainQueryInterface(QObject *parent)
    : QObject(parent)
{
    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
}

TerrainQueryInterface::~TerrainQueryInterface()
{
    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
}

void TerrainQueryInterface::requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates)
{
    Q_UNUSED(coordinates);
    qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
}

void TerrainQueryInterface::requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord)
{
    Q_UNUSED(fromCoord);
    Q_UNUSED(toCoord);
    qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
}

void TerrainQueryInterface::requestCarpetHeights(const QGeoCoordinate &swCoord, const QGeoCoordinate &neCoord, bool statsOnly)
{
    Q_UNUSED(swCoord);
    Q_UNUSED(neCoord);
    Q_UNUSED(statsOnly);
    qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
}

void TerrainQueryInterface::signalCoordinateHeights(bool success, const QList<double> &heights)
{
    emit coordinateHeightsReceived(success, heights);
}

void TerrainQueryInterface::signalPathHeights(bool success, double distanceBetween, double finalDistanceBetween, const QList<double> &heights)
{
    emit pathHeightsReceived(success, distanceBetween, finalDistanceBetween, heights);
}

void TerrainQueryInterface::signalCarpetHeights(bool success, double minHeight, double maxHeight, const QList<QList<double>> &carpet)
{
    emit carpetHeightsReceived(success, minHeight, maxHeight, carpet);
}

void TerrainQueryInterface::_requestFailed()
{
    switch (_queryMode) {
    case TerrainQuery::QueryModeCoordinates:
        emit coordinateHeightsReceived(false, QList<double>());
        break;
    case TerrainQuery::QueryModePath:
        emit pathHeightsReceived(false, qQNaN(), qQNaN(), QList<double>());
        break;
    case TerrainQuery::QueryModeCarpet:
        emit carpetHeightsReceived(false, qQNaN(), qQNaN(), QList<QList<double>>());
        break;
    default:
        qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Query Mode Not Supported";
        break;
    }
}

/*===========================================================================*/

TerrainOfflineQuery::TerrainOfflineQuery(QObject *parent)
    : TerrainQueryInterface(parent)
{
    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
}

TerrainOfflineQuery::~TerrainOfflineQuery()
{
    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
}

void TerrainOfflineQuery::requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates)
{
    if (coordinates.isEmpty()) {
        return;
    }

    _queryMode = TerrainQuery::QueryModeCoordinates;
    TerrainTileManager::instance()->addCoordinateQuery(this, coordinates);
}

void TerrainOfflineQuery::requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord)
{
    _queryMode = TerrainQuery::QueryModePath;
    TerrainTileManager::instance()->addPathQuery(this, fromCoord, toCoord);
}

/*===========================================================================*/

TerrainOnlineQuery::TerrainOnlineQuery(QObject *parent)
    : TerrainQueryInterface(parent)
    , _networkManager(new QNetworkAccessManager(this))
{
    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;

    qCDebug(TerrainQueryInterfaceLog) << "supportsSsl" << QSslSocket::supportsSsl() << "sslLibraryBuildVersionString" << QSslSocket::sslLibraryBuildVersionString();

#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    QNetworkProxy proxy = _networkManager->proxy();
    proxy.setType(QNetworkProxy::DefaultProxy);
    _networkManager->setProxy(proxy);
#endif
}

TerrainOnlineQuery::~TerrainOnlineQuery()
{
    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
}

void TerrainOnlineQuery::_requestFinished()
{
    QNetworkReply* const reply = qobject_cast<QNetworkReply*>(QObject::sender());
    if (!reply) {
        qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "null reply";
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "error:url:data" << reply->error() << reply->url() << reply->readAll();
        reply->deleteLater();
        _requestFailed();
        return;
    }

    const QByteArray responseBytes = reply->readAll();
    reply->deleteLater();

    qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "success";
}

void TerrainOnlineQuery::_requestError(QNetworkReply::NetworkError code)
{
    if (code != QNetworkReply::NoError) {
        QNetworkReply* const reply = qobject_cast<QNetworkReply*>(QObject::sender());
        qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "error:url:data" << reply->error() << reply->url() << reply->readAll();
    }
}

void TerrainOnlineQuery::_sslErrors(const QList<QSslError> &errors)
{
    for (const QSslError &error : errors) {
        qCWarning(TerrainQueryInterfaceLog) << "SSL error:" << error.errorString();

        const QSslCertificate &certificate = error.certificate();
        if (!certificate.isNull()) {
            qCWarning(TerrainQueryInterfaceLog) << "SSL Certificate problem:" << certificate.toText();
        }
    }
}

// /****************************************************************************
//  *
//  * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// #include "TerrainQueryInterface.h"
// #include "TerrainTileManager.h"
// #include "QGCLoggingCategory.h"

// #include <QtNetwork/QNetworkAccessManager>
// #include <QtNetwork/QNetworkProxy>
// #include <QtPositioning/QGeoCoordinate>

// //yeni elave edilenler
// #include <QtCore/QJsonArray>
// #include <QtCore/QJsonDocument>
// #include <QtCore/QJsonObject>
// #include <QtCore/QUrlQuery>

// QGC_LOGGING_CATEGORY(TerrainQueryInterfaceLog, "qgc.terrain.terrainqueryinterface")

// TerrainQueryInterface::TerrainQueryInterface(QObject *parent)
//     : QObject(parent)
// {
//    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
// }

// TerrainQueryInterface::~TerrainQueryInterface()
// {
//    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
// }

// void TerrainQueryInterface::requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates)
// {
//     Q_UNUSED(coordinates);
//     qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
// }

// void TerrainQueryInterface::requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord)
// {
//     Q_UNUSED(fromCoord);
//     Q_UNUSED(toCoord);
//     qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
// }

// void TerrainQueryInterface::requestCarpetHeights(const QGeoCoordinate &swCoord, const QGeoCoordinate &neCoord, bool statsOnly)
// {
//     Q_UNUSED(swCoord);
//     Q_UNUSED(neCoord);
//     Q_UNUSED(statsOnly);
//     qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
// }

// void TerrainQueryInterface::signalCoordinateHeights(bool success, const QList<double> &heights)
// {
//     emit coordinateHeightsReceived(success, heights);
// }

// void TerrainQueryInterface::signalPathHeights(bool success, double distanceBetween, double finalDistanceBetween, const QList<double> &heights)
// {
//     emit pathHeightsReceived(success, distanceBetween, finalDistanceBetween, heights);
// }

// void TerrainQueryInterface::signalCarpetHeights(bool success, double minHeight, double maxHeight, const QList<QList<double>> &carpet)
// {
//     emit carpetHeightsReceived(success, minHeight, maxHeight, carpet);
// }

// void TerrainQueryInterface::_requestFailed()
// {
//     switch (_queryMode) {
//         case TerrainQuery::QueryModeCoordinates:
//             emit coordinateHeightsReceived(false, QList<double>());
//             break;
//         case TerrainQuery::QueryModePath:
//             emit pathHeightsReceived(false, qQNaN(), qQNaN(), QList<double>());
//             break;
//         case TerrainQuery::QueryModeCarpet:
//             emit carpetHeightsReceived(false, qQNaN(), qQNaN(), QList<QList<double>>());
//             break;
//         default:
//             qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Query Mode Not Supported";
//             break;
//     }
// }

// /*===========================================================================*/

// TerrainOfflineQuery::TerrainOfflineQuery(QObject *parent)
//     : TerrainQueryInterface(parent)
// {
//    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
// }

// TerrainOfflineQuery::~TerrainOfflineQuery()
// {
//    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
// }

// void TerrainOfflineQuery::requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates)
// {
//     if (coordinates.isEmpty()) {
//         return;
//     }

//     _queryMode = TerrainQuery::QueryModeCoordinates;
//     TerrainTileManager::instance()->addCoordinateQuery(this, coordinates);
// }

// void TerrainOfflineQuery::requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord)
// {
//     _queryMode = TerrainQuery::QueryModePath;
//     TerrainTileManager::instance()->addPathQuery(this, fromCoord, toCoord);
// }

// /*===========================================================================*/

// TerrainOnlineQuery::TerrainOnlineQuery(QObject *parent)
//     : TerrainQueryInterface(parent)
//       , _networkManager(new QNetworkAccessManager(this))
// {
//     // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;

//     qCDebug(TerrainQueryInterfaceLog) << "supportsSsl" << QSslSocket::supportsSsl() << "sslLibraryBuildVersionString" << QSslSocket::sslLibraryBuildVersionString();

// #if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
//     QNetworkProxy proxy = _networkManager->proxy();
//     proxy.setType(QNetworkProxy::DefaultProxy);
//     _networkManager->setProxy(proxy);
// #endif
// }

// TerrainOnlineQuery::~TerrainOnlineQuery()
// {
//    // qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << this;
// }

// void TerrainOnlineQuery::_requestFinished()
// {
//     QNetworkReply* const reply = qobject_cast<QNetworkReply*>(QObject::sender());
//     if (!reply) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "null reply";
//         return;
//     }

//     if (reply->error() != QNetworkReply::NoError) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "error:url:data" << reply->error() << reply->url() << reply->readAll();
//         reply->deleteLater();
//         _requestFailed();
//         return;
//     }

//     const QByteArray responseBytes = reply->readAll();
//     reply->deleteLater();

//     qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "success";
// }

// void TerrainOnlineQuery::_requestError(QNetworkReply::NetworkError code)
// {
//     if (code != QNetworkReply::NoError) {
//         QNetworkReply* const reply = qobject_cast<QNetworkReply*>(QObject::sender());
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "error:url:data" << reply->error() << reply->url() << reply->readAll();
//     }
// }

// void TerrainOnlineQuery::_sslErrors(const QList<QSslError> &errors)
// {
//     for (const QSslError &error : errors) {
//         qCWarning(TerrainQueryInterfaceLog) << "SSL error:" << error.errorString();

//         const QSslCertificate &certificate = error.certificate();
//         if (!certificate.isNull()) {
//             qCWarning(TerrainQueryInterfaceLog) << "SSL Certificate problem:" << certificate.toText();
//         }
//     }
// }


// /*=====================================yeni elave edilen======================================-------------------------------------------------------------------------------*/
// /*===========================================================================*/

// TerrainOpenTopoQuery::TerrainOpenTopoQuery(QObject* parent)
//     : TerrainQueryInterface(parent)
//       , _networkManager(new QNetworkAccessManager(this))
// {
//     qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "OpenTopoData query created";
// }

// void TerrainOpenTopoQuery::requestCoordinateHeights(const QList<QGeoCoordinate>& coordinates)
// {
//     if (coordinates.isEmpty()) {
//         return;
//     }

//     _queryMode = TerrainQuery::QueryModeCoordinates;

//             // locations=lat1,lon1|lat2,lon2|...
//     QStringList locs;
//     locs.reserve(coordinates.size());
//     for (const QGeoCoordinate& c : coordinates) {
//         locs << QStringLiteral("%1,%2")
//         .arg(c.latitude(), 0, 'f', 6)
//             .arg(c.longitude(), 0, 'f', 6);
//     }

//     QUrl url(QStringLiteral("https://api.opentopodata.org/v1/srtm30m"));
//     QUrlQuery query;
//     query.addQueryItem(QStringLiteral("locations"), locs.join('|'));
//     url.setQuery(query);

//     qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "OpenTopoData url:" << url;

//     QNetworkRequest request(url);
//     QNetworkReply* reply = _networkManager->get(request);
//     if (!reply) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "QNetworkAccessManager::get returned null";
//         _requestFailed();
//         return;
//     }

//     (void) connect(reply, &QNetworkReply::finished,
//                   this, &TerrainOpenTopoQuery::_requestFinished);
//     (void) connect(reply, &QNetworkReply::errorOccurred,
//                   this, &TerrainOpenTopoQuery::_requestError);
// }

// void TerrainOpenTopoQuery::_requestFinished()
// {
//     QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
//     if (!reply) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "null reply";
//         _requestFailed();
//         return;
//     }

//     if (reply->error() != QNetworkReply::NoError) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO
//                                             << "error from OpenTopoData:" << reply->error()
//                                             << reply->errorString();
//         reply->deleteLater();
//         _requestFailed();
//         return;
//     }

//     const QByteArray bytes = reply->readAll();
//     reply->deleteLater();

//     QJsonParseError parseError;
//     const QJsonDocument doc = QJsonDocument::fromJson(bytes, &parseError);
//     if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "JSON parse error:" << parseError.errorString();
//         _requestFailed();
//         return;
//     }

//     const QJsonObject root = doc.object();
//     const QString status = root.value(QStringLiteral("status")).toString();
//     if (status != QStringLiteral("OK")) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "OpenTopoData status not OK:" << status;
//         _requestFailed();
//         return;
//     }

//     const QJsonArray results = root.value(QStringLiteral("results")).toArray();
//     QList<double> heights;
//     heights.reserve(results.size());
//     for (const QJsonValue& v : results) {
//         const QJsonObject obj = v.toObject();
//         const double elev = obj.value(QStringLiteral("elevation")).toDouble(qQNaN());
//         heights.append(elev);
//     }

//     qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "OpenTopoData success, count:" << heights.count();
//     emit coordinateHeightsReceived(true, heights);
// }

// void TerrainOpenTopoQuery::_requestError(QNetworkReply::NetworkError code)
// {
//     if (code != QNetworkReply::NoError) {
//         QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
//         if (reply) {
//             qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO
//                                                 << "network error from OpenTopoData:" << reply->errorString();
//             reply->deleteLater();
//         }
//     }

//     _requestFailed();
// }

// /****************************************************************************
//  *
//  * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// #include "TerrainQueryInterface.h"
// #include "TerrainTileManager.h"
// #include "QGCLoggingCategory.h"

// #include <QtNetwork/QNetworkAccessManager>
// #include <QtNetwork/QNetworkProxy>
// #include <QtNetwork/QNetworkReply>
// #include <QtNetwork/QSslSocket>
// #include <QtNetwork/QSslError>
// #include <QtNetwork/QSslCertificate>
// #include <QtPositioning/QGeoCoordinate>

// #include <QtCore/QJsonArray>
// #include <QtCore/QJsonDocument>
// #include <QtCore/QJsonObject>
// #include <QtCore/QUrlQuery>
// #include <QtCore/QStringList>
// #include <QtCore/QtMath>

// QGC_LOGGING_CATEGORY(TerrainQueryInterfaceLog, "qgc.terrain.terrainqueryinterface")

// TerrainQueryInterface::TerrainQueryInterface(QObject *parent)
//     : QObject(parent)
// {
// }

// TerrainQueryInterface::~TerrainQueryInterface()
// {
// }

// void TerrainQueryInterface::requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates)
// {
//     Q_UNUSED(coordinates);
//     qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
// }

// void TerrainQueryInterface::requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord)
// {
//     Q_UNUSED(fromCoord);
//     Q_UNUSED(toCoord);
//     qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
// }

// void TerrainQueryInterface::requestCarpetHeights(const QGeoCoordinate &swCoord, const QGeoCoordinate &neCoord, bool statsOnly)
// {
//     Q_UNUSED(swCoord);
//     Q_UNUSED(neCoord);
//     Q_UNUSED(statsOnly);
//     qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Not Supported";
// }

// void TerrainQueryInterface::signalCoordinateHeights(bool success, const QList<double> &heights)
// {
//     emit coordinateHeightsReceived(success, heights);
// }

// void TerrainQueryInterface::signalPathHeights(bool success,
//                                               double distanceBetween,
//                                               double finalDistanceBetween,
//                                               const QList<double> &heights)
// {
//     emit pathHeightsReceived(success, distanceBetween, finalDistanceBetween, heights);
// }

// void TerrainQueryInterface::signalCarpetHeights(bool success,
//                                                 double minHeight,
//                                                 double maxHeight,
//                                                 const QList<QList<double>> &carpet)
// {
//     emit carpetHeightsReceived(success, minHeight, maxHeight, carpet);
// }

// void TerrainQueryInterface::_requestFailed()
// {
//     switch (_queryMode) {
//         case TerrainQuery::QueryModeCoordinates:
//             emit coordinateHeightsReceived(false, QList<double>());
//             break;
//         case TerrainQuery::QueryModePath:
//             emit pathHeightsReceived(false, qQNaN(), qQNaN(), QList<double>());
//             break;
//         case TerrainQuery::QueryModeCarpet:
//             emit carpetHeightsReceived(false, qQNaN(), qQNaN(), QList<QList<double>>());
//             break;
//         default:
//             qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "Query Mode Not Supported";
//             break;
//     }
// }

// /*===========================================================================*/
// /*                             TerrainOfflineQuery                           */
// /*===========================================================================*/

// TerrainOfflineQuery::TerrainOfflineQuery(QObject *parent)
//     : TerrainQueryInterface(parent)
// {
// }

// TerrainOfflineQuery::~TerrainOfflineQuery()
// {
// }

// void TerrainOfflineQuery::requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates)
// {
//     if (coordinates.isEmpty()) {
//         return;
//     }

//     _queryMode = TerrainQuery::QueryModeCoordinates;
//     TerrainTileManager::instance()->addCoordinateQuery(this, coordinates);
// }

// void TerrainOfflineQuery::requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord)
// {
//     _queryMode = TerrainQuery::QueryModePath;
//     TerrainTileManager::instance()->addPathQuery(this, fromCoord, toCoord);
// }

// /*===========================================================================*/
// /*                              TerrainOnlineQuery                           */
// /*===========================================================================*/

// TerrainOnlineQuery::TerrainOnlineQuery(QObject *parent)
//     : TerrainQueryInterface(parent)
//       , _networkManager(new QNetworkAccessManager(this))
// {
//     qCDebug(TerrainQueryInterfaceLog) << "supportsSsl" << QSslSocket::supportsSsl()
//     << "sslLibraryBuildVersionString"
//     << QSslSocket::sslLibraryBuildVersionString();

// #if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
//     QNetworkProxy proxy = _networkManager->proxy();
//     proxy.setType(QNetworkProxy::DefaultProxy);
//     _networkManager->setProxy(proxy);
// #endif
// }

// TerrainOnlineQuery::~TerrainOnlineQuery()
// {
// }

// void TerrainOnlineQuery::_requestFinished()
// {
//     QNetworkReply* const reply = qobject_cast<QNetworkReply*>(sender());
//     if (!reply) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "null reply";
//         return;
//     }

//     if (reply->error() != QNetworkReply::NoError) {
//         qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO
//                                             << "error:url:data"
//                                             << reply->error()
//                                             << reply->url()
//                                             << reply->readAll();
//         reply->deleteLater();
//         _requestFailed();
//         return;
//     }

//     const QByteArray responseBytes = reply->readAll();
//     reply->deleteLater();

//     qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "success, bytes:" << responseBytes.size();
// }

// void TerrainOnlineQuery::_requestError(QNetworkReply::NetworkError code)
// {
//     if (code != QNetworkReply::NoError) {
//         QNetworkReply* const reply = qobject_cast<QNetworkReply*>(sender());
//         if (reply) {
//             qCWarning(TerrainQueryInterfaceLog) << Q_FUNC_INFO
//                                                 << "error:url:data"
//                                                 << reply->error()
//                                                 << reply->url()
//                                                 << reply->readAll();
//         }
//     }
// }

// void TerrainOnlineQuery::_sslErrors(const QList<QSslError> &errors)
// {
//     for (const QSslError &error : errors) {
//         qCWarning(TerrainQueryInterfaceLog) << "SSL error:" << error.errorString();

//         const QSslCertificate &certificate = error.certificate();
//         if (!certificate.isNull()) {
//             qCWarning(TerrainQueryInterfaceLog) << "SSL Certificate problem:" << certificate.toText();
//         }
//     }
// }

// /*===========================================================================*/
// /*                            TerrainOpenTopoQuery                           */
// /*===========================================================================*/

// TerrainOpenTopoQuery::TerrainOpenTopoQuery(QObject* parent)
//     : TerrainQueryInterface(parent)
//       , _networkManager(new QNetworkAccessManager(this))
// {
//     qCDebug(TerrainQueryInterfaceLog) << Q_FUNC_INFO << "OpenTopoData query created";
// }

// TerrainOpenTopoQuery::~TerrainOpenTopoQuery()
// {
// }

// bool TerrainOpenTopoQuery::_isValidCoordinate(const QGeoCoordinate& coord)
// {
//     return coord.isValid() &&
//            !qIsNaN(coord.latitude()) &&
//            !qIsNaN(coord.longitude()) &&
//            coord.latitude() >= -90.0 && coord.latitude() <= 90.0 &&
//            coord.longitude() >= -180.0 && coord.longitude() <= 180.0;
// }

// void TerrainOpenTopoQuery::requestCoordinateHeights(const QList<QGeoCoordinate>& coordinates)
// {
//     if (coordinates.isEmpty()) {
//         qCWarning(TerrainQueryInterfaceLog) << "Empty coordinates list";
//         _requestFailed();
//         return;
//     }

//             // Rate limiting: Önceki istekler bitene kadar bekle
//     if (_isWaitingForRetry) {
//         qCDebug(TerrainQueryInterfaceLog) << "Delaying request, waiting for retry...";
//         _pendingCoordinates = coordinates;
//         return;
//     }

//     _queryMode     = TerrainQuery::QueryModeCoordinates;
//     _isPathRequest = false;
//     _retryCount = 0; // Reset retry count

//             // Koordinat validasyonu
//     QList<QGeoCoordinate> validCoords;
//     for (const QGeoCoordinate& coord : coordinates) {
//         if (_isValidCoordinate(coord)) {
//             validCoords.append(coord);
//         } else {
//             qCWarning(TerrainQueryInterfaceLog) << "Invalid coordinate skipped:" << coord;
//         }
//     }

//     if (validCoords.isEmpty()) {
//         qCWarning(TerrainQueryInterfaceLog) << "No valid coordinates after validation";
//         _requestFailed();
//         return;
//     }

//     _sendCoordinateRequest(validCoords);
// }

// void TerrainOpenTopoQuery::_sendCoordinateRequest(const QList<QGeoCoordinate>& coordinates)
// {
//     QStringList locs;
//     locs.reserve(coordinates.size());
//     for (const QGeoCoordinate& c : coordinates) {
//         locs << QStringLiteral("%1,%2")
//         .arg(c.latitude(), 0, 'f', 6)
//             .arg(c.longitude(), 0, 'f', 6);
//     }

//     QUrl url(QStringLiteral("https://api.opentopodata.org/v1/srtm30m"));
//     QUrlQuery query;
//     query.addQueryItem(QStringLiteral("locations"), locs.join('|'));
//     url.setQuery(query);

//     QNetworkRequest request(url);
//     request.setRawHeader("User-Agent", "QGroundControl/1.0");
//     request.setAttribute(QNetworkRequest::Http2AllowedAttribute, true);

//     QNetworkReply* reply = _networkManager->get(request);
//     if (!reply) {
//         qCWarning(TerrainQueryInterfaceLog) << "Failed to create network reply";
//         _requestFailed();
//         return;
//     }

//     connect(reply, &QNetworkReply::finished,
//             this, &TerrainOpenTopoQuery::_requestFinished);
//     connect(reply, &QNetworkReply::errorOccurred,
//             this, &TerrainOpenTopoQuery::_requestError);

//     qCDebug(TerrainQueryInterfaceLog) << "Sent coordinate request with" << coordinates.size() << "locations";
// }

// void TerrainOpenTopoQuery::requestPathHeights(const QGeoCoordinate& fromCoord,
//                                               const QGeoCoordinate& toCoord)
// {
//     // Coordinate validasyonu
//     if (!_isValidCoordinate(fromCoord) || !_isValidCoordinate(toCoord)) {
//         qCWarning(TerrainQueryInterfaceLog) << "Invalid coordinates in path request";
//         _requestFailed();
//         return;
//     }

//             // Aynı nokta kontrolü
//     if (fromCoord.distanceTo(toCoord) < 1.0) {
//         qCDebug(TerrainQueryInterfaceLog) << "Path too short, using single point";
//         requestCoordinateHeights({fromCoord});
//         return;
//     }

//     _queryMode       = TerrainQuery::QueryModePath;
//     _isPathRequest   = true;
//     _pathFrom        = fromCoord;
//     _pathTo          = toCoord;
//     _pathCoords.clear();
//     _pathHeightsAccum.clear();
//     _currentChunkIndex = 0;
//     _retryCount = 0;

//     const double distance = fromCoord.distanceTo(toCoord);
//     const double spacing  = 100.0; // 100 m aralık
//     const int steps = qMax(2, qCeil(distance / spacing)); // En az 2 nokta

//     const double lat0 = fromCoord.latitude();
//     const double lon0 = fromCoord.longitude();
//     const double dLat = toCoord.latitude()  - lat0;
//     const double dLon = toCoord.longitude() - lon0;

//     _pathCoords.reserve(steps + 1);
//     for (int i = 0; i <= steps; ++i) {
//         const double t   = static_cast<double>(i) / static_cast<double>(steps);
//         const double lat = lat0 + dLat * t;
//         const double lon = lon0 + dLon * t;

//         QGeoCoordinate coord(lat, lon);
//         if (_isValidCoordinate(coord)) {
//             _pathCoords.append(coord);
//         }
//     }

//     if (_pathCoords.size() < 2) {
//         qCWarning(TerrainQueryInterfaceLog) << "Not enough valid path coordinates";
//         _requestFailed();
//         return;
//     }

//     _pathCoords.last() = toCoord;

//     _currentChunkIndex = 0;
//     _requestNextPathChunk();
// }

// void TerrainOpenTopoQuery::_requestNextPathChunk()
// {
//     const int maxLocationsPerRequest = 50; // Daha güvenli limit

//     if (_currentChunkIndex >= _pathCoords.size()) {
//         // Tüm chunk'lar bitti, final sonucu üret
//         const int n = _pathHeightsAccum.size();
//         const double totalDistance = _pathFrom.distanceTo(_pathTo);

//         double distanceBetween = 0.0;
//         double finalDistanceBetween = 0.0;
//         if (n > 1 && totalDistance > 0.0) {
//             distanceBetween      = totalDistance / static_cast<double>(n - 1);
//             finalDistanceBetween = distanceBetween;
//         }

//         qCDebug(TerrainQueryInterfaceLog) << "Path query completed, points:" << n;
//         emit pathHeightsReceived(true, distanceBetween, finalDistanceBetween, _pathHeightsAccum);
//         return;
//     }

//     const int remaining = _pathCoords.size() - _currentChunkIndex;
//     const int count     = qMin(maxLocationsPerRequest, remaining);

//     QStringList locs;
//     locs.reserve(count);
//     for (int i = 0; i < count; ++i) {
//         const QGeoCoordinate& c = _pathCoords[_currentChunkIndex + i];
//         locs << QStringLiteral("%1,%2")
//                     .arg(c.latitude(), 0, 'f', 6)
//                     .arg(c.longitude(), 0, 'f', 6);
//     }

//     QUrl url(QStringLiteral("https://api.opentopodata.org/v1/srtm30m"));
//     QUrlQuery query;
//     query.addQueryItem(QStringLiteral("locations"), locs.join('|'));
//     url.setQuery(query);

//     QNetworkRequest request(url);
//     request.setRawHeader("User-Agent", "QGroundControl/1.0");
//     request.setAttribute(QNetworkRequest::Http2AllowedAttribute, true);

//     QNetworkReply* reply = _networkManager->get(request);
//     if (!reply) {
//         qCWarning(TerrainQueryInterfaceLog) << "Failed to create network reply for path chunk";
//         _requestFailed();
//         return;
//     }

//     connect(reply, &QNetworkReply::finished,
//             this, &TerrainOpenTopoQuery::_requestFinished);
//     connect(reply, &QNetworkReply::errorOccurred,
//             this, &TerrainOpenTopoQuery::_requestError);

//     qCDebug(TerrainQueryInterfaceLog) << "Sent path chunk request:" << _currentChunkIndex << "to" << (_currentChunkIndex + count - 1);
// }

// void TerrainOpenTopoQuery::_requestFinished()
// {
//     QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
//     if (!reply) {
//         qCWarning(TerrainQueryInterfaceLog) << "Null reply in _requestFinished";
//         _requestFailed();
//         return;
//     }

//             // Reply'ın hala valid olduğundan emin ol
//     if (reply->isFinished() && reply->error() != QNetworkReply::NoError) {
//         qCWarning(TerrainQueryInterfaceLog) << "Reply finished with error:" << reply->errorString();
//         reply->deleteLater();
//         _requestFailed();
//         return;
//     }

//     const QByteArray bytes = reply->readAll();
//     reply->deleteLater();

//             // Boş response kontrolü
//     if (bytes.isEmpty()) {
//         qCWarning(TerrainQueryInterfaceLog) << "Empty response from OpenTopoData";
//         _requestFailed();
//         return;
//     }

//     _isWaitingForRetry = false;
//     _retryCount = 0; // Başarılı istekte resetle

//     QJsonParseError parseError;
//     const QJsonDocument doc = QJsonDocument::fromJson(bytes, &parseError);
//     if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
//         qCWarning(TerrainQueryInterfaceLog) << "JSON parse error:" << parseError.errorString();
//         _requestFailed();
//         return;
//     }

//     const QJsonObject root = doc.object();
//     const QString status = root.value(QStringLiteral("status")).toString();
//     if (status != QStringLiteral("OK")) {
//         qCWarning(TerrainQueryInterfaceLog) << "OpenTopoData API error status:" << status;
//         _requestFailed();
//         return;
//     }

//     const QJsonArray results = root.value(QStringLiteral("results")).toArray();
//     QList<double> heights;
//     heights.reserve(results.size());

//     for (const QJsonValue& v : results) {
//         const QJsonObject obj = v.toObject();
//         const double elev = obj.value(QStringLiteral("elevation")).toDouble(qQNaN());
//         heights.append(elev);
//     }

//     if (!_isPathRequest) {
//         qCDebug(TerrainQueryInterfaceLog) << "Coordinate heights received, count:" << heights.size();
//         emit coordinateHeightsReceived(true, heights);
//         return;
//     }

//             // Path chunk
//     _pathHeightsAccum.append(heights);
//     _currentChunkIndex += heights.size();

//             // Rate limiting: Chunk'lar arasında delay
//     QTimer::singleShot(500, this, &TerrainOpenTopoQuery::_requestNextPathChunk);
// }

// void TerrainOpenTopoQuery::_requestError(QNetworkReply::NetworkError code)
// {
//     QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());

//     if (reply) {
//         QString errorMsg = reply->errorString();
//         int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

//         qCWarning(TerrainQueryInterfaceLog) << "Network error:" << code
//                                             << "HTTP:" << httpStatus
//                                             << "Message:" << errorMsg;

//                 // Rate limiting kontrolü
//         if (httpStatus == 429 || errorMsg.contains("rate limit", Qt::CaseInsensitive) ||
//             errorMsg.contains("too many requests", Qt::CaseInsensitive)) {

//             qCWarning(TerrainQueryInterfaceLog) << "Rate limit hit, retrying...";

//             if (_retryCount < _maxRetries) {
//                 _retryCount++;
//                 _isWaitingForRetry = true;

//                 int delayMs = _requestDelayMs * _retryCount;
//                 qCDebug(TerrainQueryInterfaceLog) << "Retrying in" << delayMs << "ms, attempt:" << _retryCount;

//                 QTimer::singleShot(delayMs, this, [this]() {
//                     _isWaitingForRetry = false;
//                     _retryRequest();
//                 });

//                 reply->deleteLater();
//                 return;
//             } else {
//                 qCWarning(TerrainQueryInterfaceLog) << "Max retries exceeded for rate limiting";
//             }
//         }

//         reply->deleteLater();
//     }

//     _retryCount = 0;
//     _isWaitingForRetry = false;
//     _requestFailed();
// }

// void TerrainOpenTopoQuery::_retryRequest()
// {
//     qCDebug(TerrainQueryInterfaceLog) << "Retrying request, attempt:" << _retryCount;

//     if (_isPathRequest) {
//         // Path için mevcut chunk'ı yeniden dene
//         _requestNextPathChunk();
//     } else if (!_pendingCoordinates.isEmpty()) {
//         // Coordinate request için pending coordinates'ı kullan
//         _sendCoordinateRequest(_pendingCoordinates);
//         _pendingCoordinates.clear();
//     } else {
//         _requestFailed();
//     }
// }

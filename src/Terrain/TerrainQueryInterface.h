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
#include <QtCore/QList>
#include <QtCore/QObject>
#include <QtNetwork/QNetworkReply>

class QGeoCoordinate;
class QNetworkAccessManager;

Q_DECLARE_LOGGING_CATEGORY(TerrainQueryInterfaceLog)

namespace TerrainQuery
{
    enum QueryMode {
        QueryModeNone,
        QueryModeCoordinates,
        QueryModePath,
        QueryModeCarpet
    };

    enum class State {
        Idle,
        Downloading,
    };
}

/// Base class for offline/online terrain queries
class TerrainQueryInterface : public QObject
{
    Q_OBJECT

public:
    explicit TerrainQueryInterface(QObject *parent = nullptr);
    virtual ~TerrainQueryInterface();

    /// Request terrain heights for specified coodinates.
    /// Signals: coordinateHeights when data is available
    ///     @param coordinates to query
    virtual void requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates);

    /// Requests terrain heights along the path specified by the two coordinates.
    /// Signals: pathHeights
    ///     @param coordinates to query
    virtual void requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord);

    /// Request terrain heights for the rectangular area specified.
    /// Signals: carpetHeights when data is available
    ///     @param swCoord South-West bound of rectangular area to query
    ///     @param neCoord North-East bound of rectangular area to query
    ///     @param statsOnly true: Return only stats, no carpet data
    virtual void requestCarpetHeights(const QGeoCoordinate &swCoord, const QGeoCoordinate &neCoord, bool statsOnly);

    void signalCoordinateHeights(bool success, const QList<double> &heights);
    void signalPathHeights(bool success, double distanceBetween, double finalDistanceBetween, const QList<double> &heights);
    void signalCarpetHeights(bool success, double minHeight, double maxHeight, const QList<QList<double>> &carpet);

signals:
    void coordinateHeightsReceived(bool success, const QList<double> &heights);
    void pathHeightsReceived(bool success, double distanceBetween, double finalDistanceBetween, const QList<double> &heights);
    void carpetHeightsReceived(bool success, double minHeight, double maxHeight, const QList<QList<double>> &carpet);

protected:
    virtual void _requestFailed();

    TerrainQuery::QueryMode _queryMode = TerrainQuery::QueryMode::QueryModeNone;
};

/*===========================================================================*/

class TerrainOfflineQuery : public TerrainQueryInterface
{
    Q_OBJECT

public:
    explicit TerrainOfflineQuery(QObject *parent = nullptr);
    ~TerrainOfflineQuery();

    void requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates) override;
    void requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord) override;
};

/*===========================================================================*/

class TerrainOnlineQuery : public TerrainQueryInterface
{
    Q_OBJECT

public:
    explicit TerrainOnlineQuery(QObject *parent = nullptr);
    virtual ~TerrainOnlineQuery();

protected slots:
    virtual void _requestFinished();
    virtual void _requestError(QNetworkReply::NetworkError code);
    virtual void _sslErrors(const QList<QSslError> &errors);

protected:
    QNetworkAccessManager *_networkManager = nullptr;
};


// /****************************************************************************
//  *
//  * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// #pragma once

// #include <QtCore/QLoggingCategory>
// #include <QtCore/QList>
// #include <QtCore/QObject>
// #include <QtNetwork/QNetworkReply>

// class QGeoCoordinate;
// class QNetworkAccessManager;

// Q_DECLARE_LOGGING_CATEGORY(TerrainQueryInterfaceLog)

// namespace TerrainQuery
// {
// enum QueryMode {
//     QueryModeNone,
//     QueryModeCoordinates,
//     QueryModePath,
//     QueryModeCarpet
// };

// enum class State {
//     Idle,
//     Downloading,
// };
// }

// /// Base class for offline/online terrain queries
// class TerrainQueryInterface : public QObject
// {
//     Q_OBJECT

//    public:
//     explicit TerrainQueryInterface(QObject *parent = nullptr);
//     virtual ~TerrainQueryInterface();

//             /// Request terrain heights for specified coodinates.
//             /// Signals: coordinateHeights when data is available
//             ///     @param coordinates to query
//     virtual void requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates);

//             /// Requests terrain heights along the path specified by the two coordinates.
//             /// Signals: pathHeights
//             ///     @param coordinates to query
//     virtual void requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord);

//             /// Request terrain heights for the rectangular area specified.
//             /// Signals: carpetHeights when data is available
//             ///     @param swCoord South-West bound of rectangular area to query
//             ///     @param neCoord North-East bound of rectangular area to query
//             ///     @param statsOnly true: Return only stats, no carpet data
//     virtual void requestCarpetHeights(const QGeoCoordinate &swCoord, const QGeoCoordinate &neCoord, bool statsOnly);

//     void signalCoordinateHeights(bool success, const QList<double> &heights);
//     void signalPathHeights(bool success, double distanceBetween, double finalDistanceBetween, const QList<double> &heights);
//     void signalCarpetHeights(bool success, double minHeight, double maxHeight, const QList<QList<double>> &carpet);

//    signals:
//     void coordinateHeightsReceived(bool success, const QList<double> &heights);
//     void pathHeightsReceived(bool success, double distanceBetween, double finalDistanceBetween, const QList<double> &heights);
//     void carpetHeightsReceived(bool success, double minHeight, double maxHeight, const QList<QList<double>> &carpet);

//    protected:
//     virtual void _requestFailed();

//     TerrainQuery::QueryMode _queryMode = TerrainQuery::QueryMode::QueryModeNone;
// };

// /*===========================================================================*/

// class TerrainOfflineQuery : public TerrainQueryInterface
// {
//     Q_OBJECT

//    public:
//     explicit TerrainOfflineQuery(QObject *parent = nullptr);
//     ~TerrainOfflineQuery();

//     void requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates) override;
//     void requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord) override;
// };

// /*===========================================================================*/

// class TerrainOnlineQuery : public TerrainQueryInterface
// {
//     Q_OBJECT

//    public:
//     explicit TerrainOnlineQuery(QObject *parent = nullptr);
//     virtual ~TerrainOnlineQuery();

//    protected slots:
//     virtual void _requestFinished();
//     virtual void _requestError(QNetworkReply::NetworkError code);
//     virtual void _sslErrors(const QList<QSslError> &errors);

//    protected:
//     QNetworkAccessManager *_networkManager = nullptr;
// };

// /*================================yeni elave edilen===========================================*/

// class TerrainOpenTopoQuery : public TerrainQueryInterface
// {
//     Q_OBJECT

//    public:
//     explicit TerrainOpenTopoQuery(QObject* parent = nullptr);
//     ~TerrainOpenTopoQuery() override = default;

//     void requestCoordinateHeights(const QList<QGeoCoordinate>& coordinates) override;

//    private slots:
//     void _requestFinished();
//     void _requestError(QNetworkReply::NetworkError code);

//    private:
//     QNetworkAccessManager* _networkManager = nullptr;
// };


// /****************************************************************************
//  *
//  * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// #pragma once

// #include <QtCore/QLoggingCategory>
// #include <QtCore/QList>
// #include <QtCore/QObject>
// #include <QtCore/QTimer>
// #include <QtNetwork/QNetworkReply>
// #include <QtNetwork/QSslError>
// #include <QtPositioning/QGeoCoordinate>

// class QNetworkAccessManager;

// Q_DECLARE_LOGGING_CATEGORY(TerrainQueryInterfaceLog)

// namespace TerrainQuery
// {
// enum QueryMode {
//     QueryModeNone,
//     QueryModeCoordinates,
//     QueryModePath,
//     QueryModeCarpet
// };

// enum class State {
//     Idle,
//     Downloading,
// };
// }

// /// Base class for offline/online terrain queries
// class TerrainQueryInterface : public QObject
// {
//     Q_OBJECT

//    public:
//     explicit TerrainQueryInterface(QObject *parent = nullptr);
//     virtual ~TerrainQueryInterface();

//             /// Request terrain heights for specified coordinates.
//             /// Signals: coordinateHeightsReceived when data is available
//     virtual void requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates);

//             /// Requests terrain heights along the path specified by the two coordinates.
//             /// Signals: pathHeightsReceived
//     virtual void requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord);

//             /// Request terrain heights for the rectangular area specified.
//             /// Signals: carpetHeightsReceived when data is available
//     virtual void requestCarpetHeights(const QGeoCoordinate &swCoord, const QGeoCoordinate &neCoord, bool statsOnly);

//     void signalCoordinateHeights(bool success, const QList<double> &heights);
//     void signalPathHeights(bool success, double distanceBetween, double finalDistanceBetween, const QList<double> &heights);
//     void signalCarpetHeights(bool success, double minHeight, double maxHeight, const QList<QList<double>> &carpet);

//    signals:
//     void coordinateHeightsReceived(bool success, const QList<double> &heights);
//     void pathHeightsReceived(bool success, double distanceBetween, double finalDistanceBetween, const QList<double> &heights);
//     void carpetHeightsReceived(bool success, double minHeight, double maxHeight, const QList<QList<double>> &carpet);

//    protected:
//     virtual void _requestFailed();

//     TerrainQuery::QueryMode _queryMode = TerrainQuery::QueryMode::QueryModeNone;
// };

// /*===========================================================================*/

// class TerrainOfflineQuery : public TerrainQueryInterface
// {
//     Q_OBJECT

//    public:
//     explicit TerrainOfflineQuery(QObject *parent = nullptr);
//     ~TerrainOfflineQuery() override;

//     void requestCoordinateHeights(const QList<QGeoCoordinate> &coordinates) override;
//     void requestPathHeights(const QGeoCoordinate &fromCoord, const QGeoCoordinate &toCoord) override;
// };

// /*===========================================================================*/

// class TerrainOnlineQuery : public TerrainQueryInterface
// {
//     Q_OBJECT

//    public:
//     explicit TerrainOnlineQuery(QObject *parent = nullptr);
//     ~TerrainOnlineQuery() override;

//    protected slots:
//     virtual void _requestFinished();
//     virtual void _requestError(QNetworkReply::NetworkError code);
//     virtual void _sslErrors(const QList<QSslError> &errors);

//    protected:
//     QNetworkAccessManager *_networkManager = nullptr;
// };

// /*===========================================================================*/
// /*                         OpenTopo Elevation Provider                       */
// /*===========================================================================*/

// class TerrainOpenTopoQuery : public TerrainQueryInterface
// {
//     Q_OBJECT

//    public:
//     explicit TerrainOpenTopoQuery(QObject* parent = nullptr);
//     ~TerrainOpenTopoQuery() override;

//             // Nokta / koordinat listesi (ground elevation)
//     void requestCoordinateHeights(const QList<QGeoCoordinate>& coordinates) override;

//             // Path (profil grafiği)
//     void requestPathHeights(const QGeoCoordinate& fromCoord,
//                             const QGeoCoordinate& toCoord) override;

//    private slots:
//     void _requestFinished();
//     void _requestError(QNetworkReply::NetworkError code);

//    private:
//     void _requestNextPathChunk();
//     void _retryRequest();
//     void _sendCoordinateRequest(const QList<QGeoCoordinate>& coordinates);
//     bool _isValidCoordinate(const QGeoCoordinate& coord);

//     QNetworkAccessManager* _networkManager = nullptr;

//     bool _isPathRequest = false;
//     QGeoCoordinate _pathFrom;
//     QGeoCoordinate _pathTo;

//     QList<QGeoCoordinate> _pathCoords;   // tüm path noktaları
//     int _currentChunkIndex = 0;          // şu an işlenen index
//     QList<double> _pathHeightsAccum;     // tüm chunk'lardan gelen yükseklikler

//             // Yeni: Rate limiting değişkenleri
//     int _retryCount = 0;
//     const int _maxRetries = 3;
//     const int _requestDelayMs = 1500; // 1.5 saniye
//     bool _isWaitingForRetry = false;
//     QList<QGeoCoordinate> _pendingCoordinates;
// };

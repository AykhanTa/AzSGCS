/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QByteArray>
#include <QtCore/QList>
#include <QtCore/QLoggingCategory>
#include <QtCore/QString>
#include <QtCore/QVector>

class QFile;

Q_DECLARE_LOGGING_CATEGORY(LocalDtedElevationLog)

/// Native offline elevation source backed by local DTED (.dt2) tiles.
///
/// This is a C++ port of the standalone Python "Azerbaijan DTED elevation server"
/// (elevation_server_dt2.py). Instead of running an external HTTP server, the DTED
/// tiles are read directly from the application's Qt resources (":/dted/*.dt2") and
/// converted into the QGroundControl Copernicus "carpet" JSON format on demand.
///
/// The tiles are embedded into the executable, so no Python interpreter, no external
/// process, no localhost server and no separate data files are required. It works in a
/// release build that only ships the .exe (plus Qt DLLs).
class LocalDtedElevation
{
public:
    static LocalDtedElevation *instance();

    /// True if at least one DTED tile was discovered.
    bool hasData() const { return !_tiles.isEmpty(); }

    /// True if the given bounding box is fully covered by local DTED tiles.
    bool coversBbox(double latMin, double lonMin, double latMax, double lonMax) const;

    /// Build QGC Copernicus-compatible carpet JSON for the given bounding box.
    /// Returns an empty array if the area is not (fully) covered locally.
    QByteArray carpetJson(double latMin, double lonMin, double latMax, double lonMax, int gridSize = 36) const;

private:
    LocalDtedElevation();

    struct TileMeta {
        QString path;
        double  originLat = 0.0;
        double  originLon = 0.0;
        double  latIntervalDeg = 0.0;
        double  lonIntervalDeg = 0.0;
        int     latPoints = 0;
        int     lonLines = 0;
        qint64  dataOffset = 0;
        qint64  recordSize = 0;
        double  latMax = 0.0;
        double  lonMax = 0.0;

        bool contains(double lat, double lon) const;
    };

    void _scan();
    static bool _readMeta(const QString &path, TileMeta &meta);
    static bool _readProfile(const TileMeta &t, QFile &f, int lonIdx, QVector<float> &out);
    const TileMeta *_tileForPoint(double lat, double lon) const;

    QList<TileMeta> _tiles;
};

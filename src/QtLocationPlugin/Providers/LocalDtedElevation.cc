/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "LocalDtedElevation.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QHash>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QSet>
#include <QtCore/QStandardPaths>
#include <QtCore/QStringList>
#include <QtCore/QVector>
#include <QtCore/QtEndian>
#include <QtCore/QtMath>

#include "QGCLoggingCategory.h"

#include <limits>

QGC_LOGGING_CATEGORY(LocalDtedElevationLog, "qgc.qtlocationplugin.localdtedelevation")

namespace {
// Qt resource holding the tiles compiled in by QGC_EMBED_DTED. Kept as the last
// resort so a desktop build still works with nothing installed alongside it.
constexpr const char *kDtedResourceDir = ":/dted";

/// Directories searched for .dt2 tiles, best source first.
///
/// The tiles are a few hundred megabytes, which is fine compiled into a desktop
/// binary but not into an APK, so on Android they are pushed to the app's data
/// directory instead and found here. Searching rather than hard-coding also lets
/// a tile dropped next to the app override the compiled-in one without a rebuild.
QStringList dtedSearchDirs()
{
    QStringList dirs;

    // Explicit override wins: points at an SD card or a shared coverage set.
    const QByteArray envPath = qgetenv("QGC_DTED_PATH");
    if (!envPath.isEmpty()) {
        dirs << QString::fromLocal8Bit(envPath);
    }

    // Writable app data. This is where the tiles land on Android.
    const QStringList appDataDirs = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation);
    for (const QString &base : appDataDirs) {
        dirs << (base + QStringLiteral("/dted"));
    }

    // Beside the executable, for a portable install.
    dirs << (QCoreApplication::applicationDirPath() + QStringLiteral("/dted"));

    dirs << QString::fromLatin1(kDtedResourceDir);

    return dirs;
}

// DTED header layout (bytes)
constexpr int kUhlSize = 80;
constexpr int kDsiSize = 648;
constexpr int kAccSize = 2700;
constexpr int kHeaderSize = kUhlSize + kDsiSize + kAccSize; // 3428
constexpr int kNullElevation = -32767;
}

LocalDtedElevation *LocalDtedElevation::instance()
{
    static LocalDtedElevation s_instance;
    return &s_instance;
}

LocalDtedElevation::LocalDtedElevation()
{
    _scan();
}

bool LocalDtedElevation::TileMeta::contains(double lat, double lon) const
{
    constexpr double eps = 1e-9;
    return (originLat - eps) <= lat && lat <= (latMax + eps) &&
           (originLon - eps) <= lon && lon <= (lonMax + eps);
}

// -----------------------------------------------------------------------------
// UHL header parsing helpers (port of elevation_server_dt2.py)
// -----------------------------------------------------------------------------

// UHL stores an origin coordinate as DDDMMSSH (8 chars).
static bool parseUhlDms(const QString &sIn, double &out)
{
    const QString s = sIn.trimmed();
    if (s.length() < 8) {
        return false;
    }

    const QChar hemi = s.at(s.length() - 1).toUpper();
    const QString digits = s.left(s.length() - 1);
    if (digits.length() != 7) {
        return false;
    }
    for (const QChar &c : digits) {
        if (!c.isDigit()) {
            return false;
        }
    }

    const int deg = digits.mid(0, 3).toInt();
    const int minutes = digits.mid(3, 2).toInt();
    const int sec = digits.mid(5, 2).toInt();

    double val = deg + (minutes / 60.0) + (sec / 3600.0);
    if (hemi == QLatin1Char('W') || hemi == QLatin1Char('S')) {
        val = -val;
    }
    out = val;
    return true;
}

// UHL interval: SSSS with implied decimal after 3rd digit => value / 10 (arcsec).
static bool parseUhlIntervalSeconds(const QString &sIn, double &out)
{
    const QString s = sIn.trimmed();
    if (s.isEmpty()) {
        return false;
    }
    for (const QChar &c : s) {
        if (!c.isDigit()) {
            return false;
        }
    }
    out = s.toInt() / 10.0;
    return true;
}

// Infer (lonLines, latPoints) from file size when the UHL count fields are missing.
static bool inferCountsFromFileSize(qint64 fileSize, int latPointsHint, int &lonLinesOut, int &latPointsOut)
{
    if (fileSize <= kHeaderSize) {
        return false;
    }
    const qint64 dataBytes = fileSize - kHeaderSize;

    QList<int> candidates;
    if (latPointsHint > 0) {
        candidates.append(latPointsHint);
    }
    candidates << 3601 << 1201 << 601 << 901 << 121;

    for (int latPoints : candidates) {
        const qint64 recordSize = 8 + (static_cast<qint64>(latPoints) * 2) + 4;
        if (recordSize <= 0) {
            continue;
        }
        if ((dataBytes % recordSize) == 0) {
            const qint64 lonLines = dataBytes / recordSize;
            if (lonLines > 0) {
                lonLinesOut = static_cast<int>(lonLines);
                latPointsOut = latPoints;
                return true;
            }
        }
    }
    return false;
}

bool LocalDtedElevation::_readMeta(const QString &path, TileMeta &meta)
{
    QFile file(path);
    const qint64 fileSize = file.size();
    if (fileSize <= kHeaderSize) {
        return false;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        return false;
    }

    const QByteArray uhl = file.read(kUhlSize);
    file.close();
    if (uhl.size() != kUhlSize) {
        return false;
    }

    const QString uhlTxt = QString::fromLatin1(uhl);
    if (!uhlTxt.startsWith(QLatin1String("UHL"))) {
        return false;
    }

    // UHL fields (0-indexed slices matching the DTED spec)
    const QString lonStr      = uhlTxt.mid(4, 8);    // bytes 5-12
    const QString latStr      = uhlTxt.mid(12, 8);   // bytes 13-20
    const QString lonIntStr   = uhlTxt.mid(20, 4);   // bytes 21-24
    const QString latIntStr   = uhlTxt.mid(24, 4);   // bytes 25-28
    const QString lonLinesStr = uhlTxt.mid(47, 4);   // bytes 48-51
    const QString latPtsStr   = uhlTxt.mid(51, 4);   // bytes 52-55

    double originLon = 0.0;
    double originLat = 0.0;
    double lonIntervalSec = 0.0;
    double latIntervalSec = 0.0;
    if (!parseUhlDms(lonStr, originLon) || !parseUhlDms(latStr, originLat) ||
        !parseUhlIntervalSeconds(lonIntStr, lonIntervalSec) ||
        !parseUhlIntervalSeconds(latIntStr, latIntervalSec)) {
        return false;
    }

    const int lonLinesHint = lonLinesStr.trimmed().toInt();
    const int latPointsHint = latPtsStr.trimmed().toInt();

    int lonLines = 0;
    int latPoints = 0;
    if (lonLinesHint <= 0 || latPointsHint <= 0) {
        if (!inferCountsFromFileSize(fileSize, latPointsHint > 0 ? latPointsHint : 0, lonLines, latPoints)) {
            return false;
        }
    } else {
        lonLines = lonLinesHint;
        latPoints = latPointsHint;
        // Validate against file size, re-infer if the hint does not fit.
        const qint64 recordSize = 8 + (static_cast<qint64>(latPoints) * 2) + 4;
        const qint64 dataBytes = fileSize - kHeaderSize;
        if (recordSize <= 0 || (dataBytes % recordSize) != 0) {
            if (!inferCountsFromFileSize(fileSize, latPoints, lonLines, latPoints)) {
                return false;
            }
        }
    }

    meta.path = path;
    meta.originLat = originLat;
    meta.originLon = originLon;
    meta.latIntervalDeg = latIntervalSec / 3600.0;
    meta.lonIntervalDeg = lonIntervalSec / 3600.0;
    meta.latPoints = latPoints;
    meta.lonLines = lonLines;
    meta.dataOffset = kHeaderSize;
    meta.recordSize = 8 + (static_cast<qint64>(latPoints) * 2) + 4;
    meta.latMax = originLat + meta.latIntervalDeg * (latPoints - 1);
    meta.lonMax = originLon + meta.lonIntervalDeg * (lonLines - 1);
    return true;
}

void LocalDtedElevation::_scan()
{
    const QStringList searchDirs = dtedSearchDirs();
    const QStringList nameFilters = QStringList() << QStringLiteral("*.dt2") << QStringLiteral("*.DT2");

    // A tile found in an earlier directory shadows the same name later on, so a
    // pushed or updated tile takes precedence over the compiled-in one.
    QSet<QString> seen;

    for (const QString &dirPath : searchDirs) {
        const QDir dir(dirPath);
        if (!dir.exists()) {
            continue;
        }

        const QStringList files = dir.entryList(nameFilters, QDir::Files);
        for (const QString &name : files) {
            if (seen.contains(name.toLower())) {
                continue;
            }

            const QString path = dir.filePath(name);
            TileMeta meta;
            if (_readMeta(path, meta)) {
                seen.insert(name.toLower());
                _tiles.append(meta);
                qCDebug(LocalDtedElevationLog).nospace()
                    << "Found DTED tile: " << path
                    << " SW=(" << meta.originLat << "," << meta.originLon << ")"
                    << " NE=(" << meta.latMax << "," << meta.lonMax << ")"
                    << " grid=" << meta.lonLines << "x" << meta.latPoints;
            } else {
                qCWarning(LocalDtedElevationLog) << "Failed to read DTED tile:" << path;
            }
        }
    }

    if (_tiles.isEmpty()) {
        qCWarning(LocalDtedElevationLog) << "No DTED (.dt2) tiles found. Searched:" << searchDirs;
    } else {
        qCInfo(LocalDtedElevationLog) << "Loaded" << _tiles.count() << "DTED elevation tiles";
    }
}

const LocalDtedElevation::TileMeta *LocalDtedElevation::_tileForPoint(double lat, double lon) const
{
    for (const TileMeta &tile : _tiles) {
        if (tile.contains(lat, lon)) {
            return &tile;
        }
    }
    return nullptr;
}

bool LocalDtedElevation::coversBbox(double latMin, double lonMin, double latMax, double lonMax) const
{
    if (_tiles.isEmpty()) {
        return false;
    }

    const double latMid = (latMin + latMax) / 2.0;
    const double lonMid = (lonMin + lonMax) / 2.0;
    const double samples[5][2] = {
        { latMin, lonMin },
        { latMin, lonMax },
        { latMax, lonMin },
        { latMax, lonMax },
        { latMid, lonMid },
    };

    for (const auto &s : samples) {
        if (!_tileForPoint(s[0], s[1])) {
            return false;
        }
    }
    return true;
}

// Read a single elevation profile (one longitude column) of signed-magnitude int16
// values from an already-open tile file.
bool LocalDtedElevation::_readProfile(const TileMeta &t, QFile &f, int lonIdx, QVector<float> &out)
{
    if (lonIdx < 0 || lonIdx >= t.lonLines) {
        return false;
    }

    const qint64 off = t.dataOffset + (static_cast<qint64>(lonIdx) * t.recordSize);
    if (!f.seek(off)) {
        return false;
    }

    const QByteArray buf = f.read(t.recordSize);
    if (buf.size() != t.recordSize) {
        return false;
    }

    out.resize(t.latPoints);
    const uchar *data = reinterpret_cast<const uchar *>(buf.constData()) + 8; // skip 8-byte record preamble
    for (int i = 0; i < t.latPoints; ++i) {
        const quint16 u16 = qFromBigEndian<quint16>(data + (i * 2));
        const bool negative = (u16 & 0x8000) != 0;
        int value = static_cast<int>(u16 & 0x7FFF);
        if (negative) {
            value = -value;
        }
        out[i] = (value == kNullElevation) ? 0.0f : static_cast<float>(value);
    }
    return true;
}

QByteArray LocalDtedElevation::carpetJson(double latMin, double lonMin, double latMax, double lonMax, int gridSize) const
{
    if (!coversBbox(latMin, lonMin, latMax, lonMax)) {
        return QByteArray();
    }

    gridSize = qBound(2, gridSize, 100);

    QVector<double> latPoints(gridSize);
    QVector<double> lonPoints(gridSize);
    for (int i = 0; i < gridSize; ++i) {
        const double t = static_cast<double>(i) / (gridSize - 1);
        latPoints[i] = latMin + (latMax - latMin) * t;
        lonPoints[i] = lonMin + (lonMax - lonMin) * t;
    }

    // grid[i][j] : i indexes latitude (rows), j indexes longitude (cols)
    QVector<QVector<float>> grid(gridSize, QVector<float>(gridSize, 0.0f));

    // Cache opened tile files and read profiles for the duration of this call.
    QHash<QString, QFile *> openFiles;
    QHash<QString, QHash<int, QVector<float>>> profileCache;
    auto tileFile = [&openFiles](const TileMeta *tile) -> QFile * {
        QFile *&f = openFiles[tile->path];
        if (!f) {
            f = new QFile(tile->path);
            if (!f->open(QIODevice::ReadOnly)) {
                delete f;
                f = nullptr;
            }
        }
        return f;
    };

    for (int i = 0; i < gridSize; ++i) {
        const double la = latPoints[i];
        for (int j = 0; j < gridSize; ++j) {
            const double lo = lonPoints[j];
            const TileMeta *tile = _tileForPoint(la, lo);
            if (!tile) {
                continue; // leave 0.0
            }

            int lonIdx = static_cast<int>(qRound((lo - tile->originLon) / tile->lonIntervalDeg));
            int latIdx = static_cast<int>(qRound((la - tile->originLat) / tile->latIntervalDeg));
            lonIdx = qBound(0, lonIdx, tile->lonLines - 1);
            latIdx = qBound(0, latIdx, tile->latPoints - 1);

            QHash<int, QVector<float>> &tileProfiles = profileCache[tile->path];
            auto it = tileProfiles.find(lonIdx);
            if (it == tileProfiles.end()) {
                QFile *f = tileFile(tile);
                QVector<float> prof;
                if (f && _readProfile(*tile, *f, lonIdx, prof)) {
                    it = tileProfiles.insert(lonIdx, prof);
                } else {
                    continue;
                }
            }
            grid[i][j] = it.value().value(latIdx, 0.0f);
        }
    }

    qDeleteAll(openFiles);

    // Build carpet JSON + stats.
    double minH = std::numeric_limits<double>::max();
    double maxH = std::numeric_limits<double>::lowest();
    double sum = 0.0;
    QJsonArray carpetArray;
    for (int i = 0; i < gridSize; ++i) {
        QJsonArray row;
        for (int j = 0; j < gridSize; ++j) {
            const double v = qRound(grid[i][j] * 10.0) / 10.0;
            row.append(v);
            minH = qMin(minH, v);
            maxH = qMax(maxH, v);
            sum += v;
        }
        carpetArray.append(row);
    }
    const double avg = sum / (static_cast<double>(gridSize) * gridSize);

    QJsonArray sw; sw.append(latMin); sw.append(lonMin);
    QJsonArray ne; ne.append(latMax); ne.append(lonMax);
    QJsonObject bounds;
    bounds.insert(QStringLiteral("sw"), sw);
    bounds.insert(QStringLiteral("ne"), ne);

    QJsonObject stats;
    stats.insert(QStringLiteral("min"), minH);
    stats.insert(QStringLiteral("max"), maxH);
    stats.insert(QStringLiteral("avg"), avg);

    QJsonObject dataObj;
    dataObj.insert(QStringLiteral("bounds"), bounds);
    dataObj.insert(QStringLiteral("stats"), stats);
    dataObj.insert(QStringLiteral("carpet"), carpetArray);

    QJsonObject root;
    root.insert(QStringLiteral("status"), QStringLiteral("success"));
    root.insert(QStringLiteral("data"), dataObj);

    return QJsonDocument(root).toJson(QJsonDocument::Compact);
}

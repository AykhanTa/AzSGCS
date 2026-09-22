/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtGui/QPixmap>
#include <QtCore/QObject>
#include <QtGui/QImage>
#include <QtGui/QPainter>
#include <QtCore/QDebug>
#include <QtPositioning/QGeoCoordinate>

#include "Viewer3DTileReply.h"


///     @author Omid Esrafilian <esrafilian.omid@gmail.com>


class MapTileQuery : public QObject
{

public:
    typedef struct MapTileContainer_s
    {
        int L = 256; // length of each square image downloaded tile

        QList<QString> tileList;
        int zoomLevel;
        QPoint tileMinIndex;
        QPoint tileMaxIndex;
        int currentTileStat;

        QPoint currentTileIndex;
        QByteArray currentTileData;

        QImage mapTextureImage;
        // QByteArray mapTextureImageData;
        int mapWidth, mapHeight;
        void init(){
            mapWidth = (tileMaxIndex.x() - tileMinIndex.x() + 1) * L;
            mapHeight = (tileMaxIndex.y() - tileMinIndex.y() + 1) * L;
            mapTextureImage = QImage(mapWidth, mapHeight, QImage::Format_RGBA32FPx4);
            mapTextureImage.fill(Qt::gray);
            // mapTextureImageData.resize(mapWidth * mapHeight * 4 * 4); // 4 channnels and each 4 bytes
            // mapTextureImageData = QByteArray((char*)mapTextureImage.bits(), mapTextureImage.sizeInBytes());
        }

        void setMapTile(){
            QPixmap tmpPixmap;
            tmpPixmap.loadFromData(currentTileData);
            QImage tmpImage = tmpPixmap.toImage().convertToFormat(QImage::Format_RGBA32FPx4);

            QPainter painter(&mapTextureImage);
            int idxX = (currentTileIndex.x() - tileMinIndex.x()) * L;
            int idxY = (currentTileIndex.y() - tileMinIndex.y()) * L;
            painter.drawImage(idxX,
                              idxY,
                              tmpImage);

        }

        QByteArray getMapData(){
            QByteArray tmpImageData =  QByteArray::fromRawData((const char*)mapTextureImage.bits(), mapTextureImage.sizeInBytes());
            tmpImageData.data();
            return tmpImageData;
            // return mapTextureImageData;
        }

        void clear(){
            tileList.clear();
        }
    }MapTileContainer_t;

    typedef struct TileStatistics_s{
        QGeoCoordinate coordinateMin;
        QGeoCoordinate coordinateMax;
        QSize tileCounts;
        int zoomLevel;
    } TileStatistics_t;


    Q_OBJECT
public:
    explicit MapTileQuery(QObject *parent = nullptr);
    void adaptiveMapTilesLoader(QString mapType, int mapId, QGeoCoordinate coordinate_1, QGeoCoordinate coordinate_2);
    int maxTileCount(int zoomLevel, QGeoCoordinate coordinateMin, QGeoCoordinate coordinateMax);
    QByteArray getMapData(){ return _mapToBeLoaded.getMapData();}
    QSize getMapSize(){ return QSize(_mapToBeLoaded.mapWidth, _mapToBeLoaded.mapHeight);}

private:
    int _mapTilesLoadStat;
    MapTileContainer_t _mapToBeLoaded;
    int totalTilesCount, downloadedTilesCount;
    int _mapId;
    int _zoomLevel;
    QString _mapType;
    QGeoCoordinate _textureCoordinateMin, _textureCoordinateMax;

    void loadMapTiles(int zoomLevel, QPoint tileMinIndex, QPoint tileMaxIndex);
    TileStatistics_t findAndLoadMapTiles(int zoomLevel, QGeoCoordinate coordinate_1, QGeoCoordinate coordinate_2);
    double valueClip(double n, double _minValue, double _maxValue);
    QPoint latLonToPixelXY(QGeoCoordinate pointCoordinate, int zoomLevel);
    QPoint pixelXYToTileXY(QPoint pixel);
    QPoint tileXYToPixelXY(QPoint tile);
    QGeoCoordinate pixelXYToLatLong(QPoint pixel, int zoomLevel);
    void tileDone(Viewer3DTileReply::tileInfo_t _tileData);
    void tileGiveUp(Viewer3DTileReply::tileInfo_t _tileData);
    void tileEmpty(Viewer3DTileReply::tileInfo_t _tileData);
    void httpReadyRead();
    QString getTileKey(int mapId, int x, int y, int zoomLevel);

signals:
    void loadingMapCompleted();
    void mapTileDownloaded(float progress);
    void textureGeometryReady(TileStatistics_t tileInfo);
};

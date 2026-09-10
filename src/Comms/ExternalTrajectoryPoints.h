#pragma once

#include <QtCore/QObject>
#include <QtCore/QVariantList>
#include <QtPositioning/QGeoCoordinate>

class ExternalTrajectoryPoints : public QObject
{
    Q_OBJECT
public:
    explicit ExternalTrajectoryPoints(QObject* parent = nullptr);

    Q_INVOKABLE QVariantList list() const { return _points; }

    int count() const { return _points.count(); }

    void addCoordinate(const QGeoCoordinate& coordinate);

public slots:
    void clear();

signals:
    void pointAdded(QGeoCoordinate coordinate);
    void updateLastPoint(QGeoCoordinate coordinate);
    void pointsCleared();

private:
    QVariantList   _points;
    QGeoCoordinate _lastPoint;
    double         _lastAzimuth;

    static constexpr double _distanceTolerance = 2.0;
    static constexpr double _azimuthTolerance  = 1.5;
};

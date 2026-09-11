#include "ExternalTrajectoryPoints.h"

#include <QtCore/QtMath>

ExternalTrajectoryPoints::ExternalTrajectoryPoints(QObject* parent)
    : QObject       (parent)
    , _lastAzimuth  (qQNaN())
{
}

void ExternalTrajectoryPoints::addCoordinate(const QGeoCoordinate& coordinate)
{
    if (!coordinate.isValid()) {
        return;
    }

    if (_lastPoint.isValid()) {
        const double distance = _lastPoint.distanceTo(coordinate);
        if (distance > _distanceTolerance) {
            const double newAzimuth = _lastPoint.azimuthTo(coordinate);
            if (qIsNaN(_lastAzimuth) || qAbs(newAzimuth - _lastAzimuth) > _azimuthTolerance) {
                _lastAzimuth = newAzimuth;
                _lastPoint   = coordinate;
                _points.append(QVariant::fromValue(coordinate));
                emit pointAdded(coordinate);
            } else {
                _lastPoint = coordinate;
                _points[_points.count() - 1] = QVariant::fromValue(coordinate);
                emit updateLastPoint(coordinate);
            }
        } else if (!_points.isEmpty()) {
            // Tolerance altında da sonuncu görünən nöqtəni marker-lə eyniləşdir
            // _lastPoint dəyişmir ki, tolerance məntiqi qorunsun
            _points[_points.count() - 1] = QVariant::fromValue(coordinate);
            emit updateLastPoint(coordinate);
        }
    } else {
        _lastPoint = coordinate;
        _points.append(QVariant::fromValue(coordinate));
        emit pointAdded(coordinate);
    }
}

void ExternalTrajectoryPoints::clear()
{
    _points.clear();
    _lastPoint   = QGeoCoordinate();
    _lastAzimuth = qQNaN();
    emit pointsCleared();
}

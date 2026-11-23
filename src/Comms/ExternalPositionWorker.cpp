





#include "ExternalPositionWorker.h"
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtNetwork/QNetworkDatagram>

ExternalPositionWorker::ExternalPositionWorker(quint16 port, QObject *parent)
    : QObject(parent)
      , _port(port)
{
}

ExternalPositionWorker::~ExternalPositionWorker()
{
    stop();
}

void ExternalPositionWorker::start()
{
    _socket = new QUdpSocket(this);
    if (!_socket->bind(QHostAddress::AnyIPv4, _port,
                       QAbstractSocket::ReuseAddressHint |
                           QAbstractSocket::ShareAddress))
    {
        emit statusChanged(false,
                           tr("Port %1 bind uğursuz: %2")
                               .arg(_port)
                               .arg(_socket->errorString()));
        return;
    }

    connect(_socket, &QUdpSocket::readyRead,
            this,    &ExternalPositionWorker::_onReadyRead);

    _timeoutTimer = new QTimer(this);
    _timeoutTimer->setInterval(TIMEOUT_MS);
    _timeoutTimer->setSingleShot(false);
    connect(_timeoutTimer, &QTimer::timeout,
            this,          &ExternalPositionWorker::_onTimeout);
    _timeoutTimer->start();

    // Bind = yalnız dinləmə; hələ data yoxdur. "Aktiv" (xəritədə marker/trayektoriya)
    // yalnız real data gələndə (_onReadyRead) true olur, timeout-da yenidən false.
    emit statusChanged(false, tr("Port %1 dinlənilir").arg(_port));
}

void ExternalPositionWorker::stop()
{
    if (_timeoutTimer) {
        _timeoutTimer->stop();
        _timeoutTimer->deleteLater();
        _timeoutTimer = nullptr;
    }
    if (_socket) {
        _socket->close();
        _socket->deleteLater();
        _socket = nullptr;
    }
    _active = false;
    emit statusChanged(false, tr("Dayandırıldı"));
}

void ExternalPositionWorker::_onReadyRead()
{
    while (_socket && _socket->hasPendingDatagrams()) {
        const QNetworkDatagram dg = _socket->receiveDatagram();
        if (dg.isNull() || dg.data().isEmpty()) continue;

        const QJsonDocument doc = QJsonDocument::fromJson(dg.data());
        if (doc.isNull() || !doc.isObject()) {
            qWarning() << "[ExternalPos] JSON parse xətası:" << dg.data().left(64);
            continue;
        }

        const QJsonObject obj = doc.object();

                // lat, lon, alt məcburidir — spd olmasa 0 götürülür
        if (!obj.contains("lat") || !obj.contains("lon") || !obj.contains("alt")) {
            qWarning() << "[ExternalPos] Çatışmayan sahə:" << obj.keys();
            continue;
        }

        ExternalPositionData pos;
        pos.lat = obj["lat"].toDouble();
        pos.lon = obj["lon"].toDouble();
        pos.alt = static_cast<float>(obj["alt"].toDouble());
        pos.spd = static_cast<float>(obj.value("spd").toDouble(0.0)); // optional

        if (_timeoutTimer) _timeoutTimer->start();

        if (!_active) {
            _active = true;
            emit statusChanged(true, tr("Məlumat gəlir"));
        }

        emit positionReceived(pos);
    }
}

void ExternalPositionWorker::_onTimeout()
{
    if (_active) {
        _active = false;
        emit statusChanged(false, tr("Məlumat kəsildi — timeout 3s"));
    }
}

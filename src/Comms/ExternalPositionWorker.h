




#pragma once
#include <QtCore/QObject>
#include <QtCore/QTimer>
#include <QtNetwork/QUdpSocket>

struct ExternalPositionData {
    double lat = 0.0;
    double lon = 0.0;
    float  alt = 0.0f;
    float  spd = 0.0f;   // m/s
};

class ExternalPositionWorker : public QObject {
    Q_OBJECT
   public:
    explicit ExternalPositionWorker(quint16 port, QObject *parent = nullptr);
    ~ExternalPositionWorker();

   public slots:
    void start();
    void stop();

   signals:
    void positionReceived(ExternalPositionData data);
    void statusChanged(bool active, QString message);

   private slots:
    void _onReadyRead();
    void _onTimeout();

   private:
    quint16      _port;
    QUdpSocket  *_socket       = nullptr;
    QTimer      *_timeoutTimer = nullptr;
    bool         _active       = false;

    static constexpr int TIMEOUT_MS = 3000;
};

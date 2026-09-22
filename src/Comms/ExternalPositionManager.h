












#pragma once
#include "ExternalPositionWorker.h"
#include "ExternalTrajectoryPoints.h"
#include <QtCore/QObject>
#include <QtCore/QThread>

class Vehicle;
class MAVLinkProtocol;

class ExternalPositionManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(double  extLat      READ extLat       NOTIFY positionUpdated)
    Q_PROPERTY(double  extLon      READ extLon       NOTIFY positionUpdated)
    Q_PROPERTY(float   extAlt      READ extAlt       NOTIFY positionUpdated)
    Q_PROPERTY(float   extSpd      READ extSpd       NOTIFY positionUpdated)
    Q_PROPERTY(bool    extActive   READ extActive    NOTIFY activeChanged)
    Q_PROPERTY(int     pktCount    READ pktCount     NOTIFY positionUpdated)
    Q_PROPERTY(quint16 listenPort  READ listenPort   NOTIFY listenPortChanged)
    Q_PROPERTY(bool    isListening READ isListening  NOTIFY listeningChanged)
    Q_PROPERTY(bool    sendEnabled READ sendEnabled  WRITE setSendEnabled NOTIFY sendEnabledChanged)
    Q_PROPERTY(ExternalTrajectoryPoints* trajectoryPoints READ trajectoryPoints CONSTANT)

   public:
    explicit ExternalPositionManager(quint16 port = 15550, QObject *parent = nullptr);
    ~ExternalPositionManager();

    void setVehicle(Vehicle *vehicle);
    void start();
    void stop();

    double  extLat()     const { return _lat;        }
    double  extLon()     const { return _lon;        }
    float   extAlt()     const { return _alt;        }
    float   extSpd()     const { return _spd;        }
    bool    extActive()  const { return _active;     }
    int     pktCount()   const { return _pktCount;   }
    quint16 listenPort() const { return _port;       }
    bool    isListening()const { return _listening;  }
    bool    sendEnabled()const { return _sendEnabled;}
    ExternalTrajectoryPoints* trajectoryPoints() const { return _trajectoryPoints; }

    void setSendEnabled(bool v);

   public slots:
    void startListening(quint16 port);
    void stopListening();
    void resetPosition();

   signals:
    void positionUpdated(double lat, double lon, float alt, float spd);
    void activeChanged(bool active);
    void listenPortChanged(quint16 port);
    void listeningChanged(bool listening);
    void sendEnabledChanged(bool enabled);
    void mavlinkSendError(QString message);

   private slots:
    void _onPositionReceived(ExternalPositionData data);
    void _onStatusChanged(bool active, QString message);

   private:
    void _restartWorker(quint16 port);
    void _sendMavlinkIntercept();

    QThread                  *_thread            = nullptr;
    ExternalPositionWorker   *_worker            = nullptr;
    Vehicle                  *_vehicle           = nullptr;
    ExternalTrajectoryPoints *_trajectoryPoints  = nullptr;

    quint16 _port;
    double  _lat         = 0.0;
    double  _lon         = 0.0;
    float   _alt         = 0.0f;
    float   _spd         = 0.0f;
    bool    _active      = false;
    bool    _listening   = false;
    bool    _sendEnabled = false;
    int     _pktCount    = 0;

    qint64  _lastSendMs  = 0;
    static constexpr int SEND_INTERVAL_MS = 100; // 10 Hz
};

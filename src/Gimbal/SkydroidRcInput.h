/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
#pragma once

#include <QtCore/QList>
#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QString>

#ifdef Q_OS_ANDROID
#include <jni.h>
#endif

Q_DECLARE_LOGGING_CATEGORY(SkydroidRcInputLog)

/// Channel values read from the Skydroid remote controller itself (G20, G30 and the
/// rest of the range) through Skydroid's RCSDK. This is what lets a Skydroid pod follow
/// the sticks when there is no flight controller to report RC_CHANNELS.
///
/// Read only: the controller is asked for its channel values and nothing else.
///
/// Only Android has an implementation. Elsewhere the state stays Unavailable and no
/// channels are ever reported.
class SkydroidRcInput : public QObject
{
    Q_OBJECT

public:
    /// Matches the STATE_ constants in SkydroidRcReader.java.
    enum State {
        Unavailable = -1,   ///< No RCSDK on this platform
        Stopped     = 0,
        Connecting  = 1,
        Connected   = 2,
        Failed      = 3,    ///< Retried every few seconds while active
    };
    Q_ENUM(State)

    explicit SkydroidRcInput(QObject *parent = nullptr);
    ~SkydroidRcInput();

    /// Starts or stops reading the controller. Stopping hands the SDK's port back, so
    /// the Skydroid assistant app can connect again.
    void setActive(bool active);
    bool active() const { return _active; }

    State   state() const { return _state; }
    QString message() const { return _message; }

#ifdef Q_OS_ANDROID
    static void setNativeMethods();
#endif

signals:
    void channelsReceived(const QList<int> &channels);
    void stateChanged();

private:
    void _setState(State state, const QString &message);

#ifdef Q_OS_ANDROID
    static void _jniChannels(JNIEnv *env, jclass clazz, jintArray channels);
    static void _jniState(JNIEnv *env, jclass clazz, jint state, jstring message);
#endif

    bool    _active = false;
    State   _state = Unavailable;
    QString _message;
};

/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SkydroidRcInput.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QPointer>

#ifdef Q_OS_ANDROID
#include <QtCore/QJniEnvironment>
#include <QtCore/QJniObject>
#include <QtCore/qcoreapplication_platform.h>
#endif

QGC_LOGGING_CATEGORY(SkydroidRcInputLog, "qgc.gimbal.skydroidrcinput")

namespace {
// Only ever read and written on the main thread. JNI callbacks hop over to it before
// they look at this.
QPointer<SkydroidRcInput> s_instance;

#ifdef Q_OS_ANDROID
constexpr const char *kReaderClass = "org/mavlink/qgroundcontrol/SkydroidRcReader";
#endif
}

SkydroidRcInput::SkydroidRcInput(QObject *parent)
    : QObject(parent)
{
    if (s_instance) {
        qCDebug(SkydroidRcInputLog) << "A second instance replaces the first as the JNI target";
    }
    s_instance = this;

#ifdef Q_OS_ANDROID
    _state = Stopped;
#endif
}

SkydroidRcInput::~SkydroidRcInput()
{
    // Hands the SDK's port back before the process goes, so the Skydroid assistant
    // can connect next time.
    setActive(false);

    if (s_instance == this) {
        s_instance = nullptr;
    }
}

void SkydroidRcInput::setActive(bool active)
{
    if (active == _active) {
        return;
    }
    _active = active;

#ifdef Q_OS_ANDROID
    qCDebug(SkydroidRcInputLog) << (active ? "Starting" : "Stopping") << "remote controller input";

    if (active) {
        const QJniObject context = QNativeInterface::QAndroidApplication::context();
        QJniObject::callStaticMethod<void>(kReaderClass, "start", "(Landroid/content/Context;)V", context.object());
    } else {
        QJniObject::callStaticMethod<void>(kReaderClass, "stop", "()V");
    }

    QJniEnvironment env;
    if (env.checkAndClearExceptions()) {
        qCWarning(SkydroidRcInputLog) << "Java exception while" << (active ? "starting" : "stopping") << "the reader";
        _setState(Failed, QStringLiteral("Java exception"));
    }
#endif
}

void SkydroidRcInput::_setState(State state, const QString &message)
{
    if ((state == _state) && (message == _message)) {
        return;
    }

    qCDebug(SkydroidRcInputLog) << "State" << state << message;
    _state = state;
    _message = message;
    emit stateChanged();
}

#ifdef Q_OS_ANDROID

void SkydroidRcInput::setNativeMethods()
{
    const JNINativeMethod javaMethods[] {
        {"nativeChannels", "([I)V",                  reinterpret_cast<void*>(_jniChannels)},
        {"nativeState",    "(ILjava/lang/String;)V", reinterpret_cast<void*>(_jniState)},
    };

    QJniEnvironment jniEnv;
    const jclass javaClass = jniEnv.findClass(kReaderClass);
    if (!javaClass) {
        qCWarning(SkydroidRcInputLog) << "Couldn't find class for RegisterNatives:" << kReaderClass;
        (void) jniEnv.checkAndClearExceptions();
        return;
    }

    if (jniEnv->RegisterNatives(javaClass, javaMethods, std::size(javaMethods)) != JNI_OK) {
        qCWarning(SkydroidRcInputLog) << "Error registering native methods";
    }

    (void) jniEnv.checkAndClearExceptions();
}

void SkydroidRcInput::_jniChannels(JNIEnv *env, jclass clazz, jintArray channels)
{
    Q_UNUSED(clazz);

    if (!channels) {
        return;
    }

    const jsize count = env->GetArrayLength(channels);
    QList<int> values(count);
    static_assert(sizeof(jint) == sizeof(int));
    env->GetIntArrayRegion(channels, 0, count, reinterpret_cast<jint*>(values.data()));
    if (env->ExceptionCheck()) {
        env->ExceptionClear();
        return;
    }

    // Called on the reader's own thread.
    (void) QMetaObject::invokeMethod(QCoreApplication::instance(), [values]() {
        if (s_instance && s_instance->_active) {
            emit s_instance->channelsReceived(values);
        }
    }, Qt::QueuedConnection);
}

void SkydroidRcInput::_jniState(JNIEnv *env, jclass clazz, jint state, jstring message)
{
    Q_UNUSED(clazz);

    QString text;
    if (message) {
        const char *chars = env->GetStringUTFChars(message, nullptr);
        if (chars) {
            text = QString::fromUtf8(chars);
            env->ReleaseStringUTFChars(message, chars);
        }
    }

    // Called on the reader's own thread.
    (void) QMetaObject::invokeMethod(QCoreApplication::instance(), [state, text]() {
        if (s_instance) {
            s_instance->_setState(static_cast<State>(state), text);
        }
    }, Qt::QueuedConnection);
}

#endif

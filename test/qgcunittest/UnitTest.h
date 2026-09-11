/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "MockLink.h"
#include "MAVLinkLib.h"

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QRegularExpression>
#include <QtPositioning/QGeoCoordinate>
#include <QtTest/QSignalSpy>
#include <QtTest/QTest>

#include <chrono>

#define UT_REGISTER_TEST(className) static UnitTestWrapper<className> className(#className, false);
#define UT_REGISTER_TEST_STANDALONE(className) static UnitTestWrapper<className> className(#className, true);  // Test will only be run with specifically called to from command line

Q_DECLARE_LOGGING_CATEGORY(UnitTestLog)

// ============================================================================
// Test timeout configuration
//
// Async tests must not hard-code wall-clock numbers: CI machines are slower and
// far noisier than a dev box, which is where flaky timeouts come from. Use these
// instead of literals so one place controls the CI/local split.
// ============================================================================

namespace TestTimeout {

/// True when running under CI (GitHub Actions, etc.). Evaluated on every call so
/// a test may toggle the environment variable and observe the change.
inline bool isCI()
{
    return qEnvironmentVariableIsSet("CI") || qEnvironmentVariableIsSet("GITHUB_ACTIONS");
}

/// Quick operations (1s local, 2s CI)
inline std::chrono::milliseconds shortDuration() { return std::chrono::milliseconds{isCI() ? 2000 : 1000}; }

/// Normal async operations (5s local, 10s CI)
inline std::chrono::milliseconds mediumDuration() { return std::chrono::milliseconds{isCI() ? 10000 : 5000}; }

/// Slow operations such as network round trips (15s local, 30s CI)
inline std::chrono::milliseconds longDuration() { return std::chrono::milliseconds{isCI() ? 30000 : 15000}; }

inline int shortMs() { return static_cast<int>(shortDuration().count()); }
inline int mediumMs() { return static_cast<int>(mediumDuration().count()); }
inline int longMs() { return static_cast<int>(longDuration().count()); }

}  // namespace TestTimeout

/// Wait for a signal with a timeout, failing with the spy's name on timeout.
///     @param spy QSignalSpy to wait on
///     @param timeoutMs Timeout in milliseconds
#define QVERIFY_SIGNAL_WAIT(spy, timeoutMs) \
    QVERIFY2(UnitTest::waitForSignal((spy), (timeoutMs), QStringLiteral(#spy)), \
             qPrintable(QStringLiteral("Timeout waiting for signal after %1ms: %2").arg(timeoutMs).arg(QStringLiteral(#spy))))

/// Compare with polling until equal or timeout. Named for symmetry with QVERIFY_SIGNAL_WAIT.
#define QCOMPARE_TRUE_WAIT(actual, expected, timeoutMs) QTRY_COMPARE_WITH_TIMEOUT(actual, expected, timeoutMs)

class Vehicle;
class Fact;
class LinkInterface;
class MissionItem;

class UnitTest : public QObject
{
    Q_OBJECT

public:
    UnitTest(QObject *parent = nullptr);
    virtual ~UnitTest();

    /// @brief Called to run all the registered unit tests
    ///     @param singleTest Name of test to just run a single test
    static int run(QStringView singleTest);

    bool standalone() const { return _standalone; }
    void setStandalone(bool standalone) { _standalone = standalone; }

    /// @brief Adds a unit test to the list. Should only be called by UnitTestWrapper.
    static void _addTest(UnitTest *test);

    /// Will throw qWarning at location where files differ
    /// @return true: files are alike, false: files differ
    static bool fileCompare(const QString &file1, const QString &file2);

    /// Changes the Facts rawValue such that it emits a valueChanged signal.
    ///     @param increment 0 use standard increment, other increment by specified amount if double value
    void changeFactValue(Fact *fact, double increment = 0);

    QGeoCoordinate changeCoordinateValue(const QGeoCoordinate &coordinate);

    /// Returns true is the position of the two coordinates is less then a meter from each other.
    /// Does not check altitude.
    static bool fuzzyCompareLatLon(const QGeoCoordinate &coord1, const QGeoCoordinate &coord2);

    /// Wait for @a spy to receive a signal, logging a diagnostic on timeout.
    /// Prefer the QVERIFY_SIGNAL_WAIT macro, which reports the spy name automatically.
    /// @return true if the signal arrived within @a timeout
    static bool waitForSignal(QSignalSpy &spy, std::chrono::milliseconds timeout, QStringView signalName = {});

    static bool waitForSignal(QSignalSpy &spy, int timeoutMs, QStringView signalName = {})
    {
        return waitForSignal(spy, std::chrono::milliseconds{timeoutMs}, signalName);
    }

protected slots:
    // These are all pure virtuals to force the derived class to implement each one and in turn
    // call the UnitTest private implementation.

    /// @brief Called before each test.
    ///         Make sure to call UnitTest::init first in your derived class.
    virtual void init();

    /// @brief Called after each test.
    ///         Make sure to call UnitTest::cleanup last in your derived class.
    virtual void cleanup();

protected:
    void _connectMockLink(MAV_AUTOPILOT autopilot = MAV_AUTOPILOT_PX4, MockConfiguration::FailureMode_t failureMode = MockConfiguration::FailNone);
    void _connectMockLinkNoInitialConnectSequence() { _connectMockLink(MAV_AUTOPILOT_INVALID); }
    void _disconnectMockLink();
    static void _missionItemsEqual(const MissionItem &actual, const MissionItem &expected);

    // ------------------------------------------------------------------
    // Log message assertions
    //
    // Messages emitted while a test runs are captured between init() and
    // cleanup(). These let a test assert that a specific warning is part of
    // the behavior under test, or silence noise it cannot control.
    // ------------------------------------------------------------------

    /// Declare that a log message matching @a pattern is expected from @a category at @a type.
    /// Only messages logged *after* this call are considered.
    ///
    /// Contract:
    /// - Multiple pending expectations are allowed (FIFO verification order).
    /// - Every expectation must be consumed by verifyExpectedLogMessage(); cleanup() fails otherwise.
    void expectLogMessage(const char *category, QtMsgType type, const QRegularExpression &pattern);

    /// Verify and consume the next pending expectLogMessage() expectation.
    /// Fails the test if no matching message was captured after that call.
    void verifyExpectedLogMessage();

    /// Suppress all log messages matching @a pattern at @a type in @a category for
    /// the rest of the test, so expected noise does not clutter the test output.
    ///
    /// Prefer expectLogMessage() + verifyExpectedLogMessage() when the log line is
    /// actually part of the behavior under test — that asserts instead of hiding.
    void ignoreLogMessage(const char *category, QtMsgType type, const QRegularExpression &pattern);

    MockLink *_mockLink = nullptr;
    Vehicle *_vehicle = nullptr;

private slots:
    void _linkDeleted(const LinkInterface *link);

private:
    void _unitTestCalled() { _unitTestRun = true; }

    /// @brief Returns the list of unit tests.
    static QList<UnitTest*> &_testList();

    struct CapturedMessage {
        QtMsgType type;
        QString category;
        QString message;
    };

    struct LogRule {
        QtMsgType type;
        QString category;
        QRegularExpression pattern;
    };

    struct PendingExpectation {
        LogRule rule;
        int startIndex;     ///< index into _capturedMessages at the time the expectation was armed
    };

    static void _captureMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &message);
    static bool _ruleMatches(const LogRule &rule, const CapturedMessage &message);

    void _startMessageCapture();
    void _stopMessageCapture();

    QList<CapturedMessage> _capturedMessages;
    QList<LogRule> _ignoredMessages;
    QList<PendingExpectation> _pendingExpectations;

    bool _unitTestRun = false;      ///< true: Unit Test was run
    bool _initCalled = false;       ///< true: UnitTest::_init was called
    bool _cleanupCalled = false;    ///< true: UnitTest::_cleanup was called
    bool _standalone = false;       ///< true: Only run when requested specifically from command line
};

template <class T>
class UnitTestWrapper
{
public:
    UnitTestWrapper(const QString &name, bool standalone)
        : _unitTest(new T)
    {
        _unitTest->setObjectName(name);
        _unitTest->setStandalone(standalone);
        UnitTest::_addTest(_unitTest.data());
    }

private:
    QSharedPointer<T> _unitTest;
};

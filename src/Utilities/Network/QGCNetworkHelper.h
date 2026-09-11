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
#include <QtCore/QPair>
#include <QtCore/QString>
#include <QtCore/QUrl>
#include <QtCore/QVariant>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>

class QNetworkAccessManager;

/// Shared helpers for building and inspecting QNetworkRequest/QNetworkReply.
///
/// This is the focused subset consumed by the NTRIP module. It intentionally
/// mirrors the upstream QGroundControl QGCNetworkHelper namespace — same
/// names, same signatures, same behavior — so ported NTRIP sources compile
/// unchanged and can be re-synced from upstream without edits. Multipart
/// upload, HTTP-server and compression helpers are deliberately omitted; add
/// them here (matching upstream) if a future port needs them.
namespace QGCNetworkHelper
{

constexpr int kDefaultTimeoutMs = 30000;

// ============================================================================
// Request Configuration
// ============================================================================

/// Common request configuration options
struct RequestConfig
{
    int timeoutMs = kDefaultTimeoutMs;
    bool allowRedirects = true;
    bool http2Allowed = true;
    bool cacheEnabled = true;
    bool backgroundRequest = false;
    QString userAgent;
    QString accept = QStringLiteral("*/*");
    QString acceptEncoding;
    QString contentType;
    QList<QPair<QNetworkRequest::Attribute, QVariant>> requestAttributes;
};

/// Configure a QNetworkRequest with standard settings
/// @param request Request to configure
/// @param config Configuration options (uses defaults if not specified)
void configureRequest(QNetworkRequest& request, const RequestConfig& config = {});

/// Create a pre-configured QNetworkRequest
/// @param url The URL for the request
/// @param config Configuration options (uses defaults if not specified)
/// @return Configured QNetworkRequest ready for use
QNetworkRequest createRequest(const QUrl& url, const RequestConfig& config = {});

/// Get the default User-Agent string for QGC
QString defaultUserAgent();

// ============================================================================
// Authentication Helpers
// ============================================================================

/// Set HTTP Basic Authentication header
/// @param request Request to modify
/// @param credentials Base64-encoded "username:password" string
void setBasicAuth(QNetworkRequest& request, const QString& credentials);

/// Set HTTP Basic Authentication header from username and password
/// @param request Request to modify
/// @param username The username
/// @param password The password
void setBasicAuth(QNetworkRequest& request, const QString& username, const QString& password);

/// Build the Base64 "username:password" payload for HTTP Basic auth (RFC 7617).
/// The caller is responsible for rejecting a username containing ':'.
QString createBasicAuthCredentials(const QString& username, const QString& password);

// ============================================================================
// Reply Inspection
// ============================================================================

/// HTTP status code of a finished reply, or -1 for a non-HTTP reply.
int httpStatusCode(const QNetworkReply* reply);

/// True for a 2xx status code.
constexpr bool isHttpSuccess(int statusCode) { return (statusCode >= 200) && (statusCode < 300); }

/// User-facing error string for a finished reply. Empty when the reply succeeded.
QString errorMessage(const QNetworkReply* reply);

// ============================================================================
// Network Access Manager
// ============================================================================

/// Create a QNetworkAccessManager with QGC's standard proxy configuration.
QNetworkAccessManager* createNetworkManager(QObject* parent = nullptr);

/// Apply QGC's standard proxy configuration to an existing manager.
void configureProxy(QNetworkAccessManager* manager);

}  // namespace QGCNetworkHelper

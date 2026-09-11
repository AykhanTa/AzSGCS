/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "QGCNetworkHelper.h"

#include <QtCore/QCoreApplication>
#include <QtNetwork/QHttpHeaders>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkProxy>

namespace QGCNetworkHelper
{

// ============================================================================
// Request Configuration
// ============================================================================

void configureRequest(QNetworkRequest& request, const RequestConfig& config)
{
    request.setTransferTimeout(config.timeoutMs);

    if (config.allowRedirects) {
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    } else {
        request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    }

    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, config.http2Allowed);

    if (config.cacheEnabled) {
        request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::PreferCache);
        request.setAttribute(QNetworkRequest::CacheSaveControlAttribute, true);
    } else {
        request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);
        request.setAttribute(QNetworkRequest::CacheSaveControlAttribute, false);
    }

    request.setAttribute(QNetworkRequest::BackgroundRequestAttribute, config.backgroundRequest);

    using WK = QHttpHeaders::WellKnownHeader;
    QHttpHeaders headers = request.headers();
    headers.replaceOrAppend(WK::UserAgent, config.userAgent.isEmpty() ? defaultUserAgent() : config.userAgent);
    if (!config.accept.isEmpty()) {
        headers.replaceOrAppend(WK::Accept, config.accept);
    }
    if (!config.acceptEncoding.isEmpty()) {
        headers.replaceOrAppend(WK::AcceptEncoding, config.acceptEncoding);
    }
    if (!config.contentType.isEmpty()) {
        headers.replaceOrAppend(WK::ContentType, config.contentType);
    }
    headers.replaceOrAppend(WK::Connection, "keep-alive");
    request.setHeaders(headers);

    for (const auto& [attribute, value] : config.requestAttributes) {
        request.setAttribute(attribute, value);
    }
}

QNetworkRequest createRequest(const QUrl& url, const RequestConfig& config)
{
    QNetworkRequest request(url);
    configureRequest(request, config);
    return request;
}

QString defaultUserAgent()
{
    static QString userAgent;
    if (userAgent.isEmpty()) {
        userAgent = QStringLiteral("%1/%2 (Qt %3)")
                        .arg(QCoreApplication::applicationName())
                        .arg(QCoreApplication::applicationVersion())
                        .arg(QString::fromLatin1(qVersion()));
    }
    return userAgent;
}

// ============================================================================
// Authentication Helpers
// ============================================================================

void setBasicAuth(QNetworkRequest& request, const QString& credentials)
{
    QHttpHeaders headers = request.headers();
    headers.replaceOrAppend(QHttpHeaders::WellKnownHeader::Authorization, "Basic " + credentials);
    request.setHeaders(headers);
}

void setBasicAuth(QNetworkRequest& request, const QString& username, const QString& password)
{
    setBasicAuth(request, createBasicAuthCredentials(username, password));
}

QString createBasicAuthCredentials(const QString& username, const QString& password)
{
    const QString credentials = username + QLatin1Char(':') + password;
    return QString::fromLatin1(credentials.toUtf8().toBase64());
}

// ============================================================================
// Reply Inspection
// ============================================================================

int httpStatusCode(const QNetworkReply* reply)
{
    if (!reply) {
        return -1;
    }

    const QVariant status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
    return status.isValid() ? status.toInt() : -1;
}

QString errorMessage(const QNetworkReply* reply)
{
    if (!reply) {
        return QStringLiteral("No reply");
    }

    // Network-level failure takes precedence — its string is the most specific.
    if (reply->error() != QNetworkReply::NoError) {
        return reply->errorString();
    }

    const int status = httpStatusCode(reply);
    if (status >= 400) {
        const QString reason = reply->attribute(QNetworkRequest::HttpReasonPhraseAttribute).toString();
        return reason.isEmpty() ? QStringLiteral("HTTP %1").arg(status)
                                : QStringLiteral("HTTP %1: %2").arg(status).arg(reason);
    }

    return {};
}

// ============================================================================
// Network Access Manager
// ============================================================================

QNetworkAccessManager* createNetworkManager(QObject* parent)
{
    auto* manager = new QNetworkAccessManager(parent);
    configureProxy(manager);
    return manager;
}

void configureProxy(QNetworkAccessManager* manager)
{
    if (!manager) {
        return;
    }

#if !defined(Q_OS_IOS) && !defined(Q_OS_ANDROID)
    QNetworkProxy proxy = manager->proxy();
    proxy.setType(QNetworkProxy::DefaultProxy);
    manager->setProxy(proxy);
#endif
}

}  // namespace QGCNetworkHelper

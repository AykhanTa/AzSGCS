#pragma once

#include <QString>
#include <QHash>
#include <QList>
#include <QPair>
#include <QRegularExpression>
#include <QtGlobal>

/*!
 * SpeechLocalizer
 * - QGC TTS mətni üçün “on-the-fly” lokallaşdırma.
 * - İngiliscə gələn StatusText (ArduPilot) və QGC xəbərdarlıqlarını TR/AZ-a çevirir.
 * - Sadə mexanizm: 1) dəqiq xəritə (exact map), 2) regex əsaslı qaydalar.
 */
class SpeechLocalizer {
   public:
    enum class Locale {
        English = 0,
        Turkish,
        Azerbaijani,
    };

    static SpeechLocalizer& instance();

            // Dil seçimi (Settings-dən də çağırıla bilər)
    void setLocale(Locale l);
    Locale locale() const;

            // Əsas giriş: mətni lokallaşdırmağa cəhd edir, tapa bilməsə orijinalı qaytarır.
    QString localize(const QString& original) const;

            // Utility: enum üçün string çevirmələri (opsional)
    static QString localeToString(Locale l);
    static Locale  stringToLocale(const QString& s);

   private:
    SpeechLocalizer(); // singleton

            // İki mərhələli çevirmə: əvvəl exact-map, sonra regex
    QString _applyExactMap(const QString& s) const;
    QString _applyRegexMap(const QString& s) const;

            // Normalizasiya: map açarları lower-case saxlanır
    static QString _norm(const QString& s);

            // Resursların qurulması
    void _initTurkish();
    void _initAzerbaijani();

   private:
    Locale _locale { Locale::Turkish }; // default: TR (istəyə görə AZ/EN)
    // Dəqiq xəritələr (lower-case açarla)
    QHash<QString, QString> _exactTR;
    QHash<QString, QString> _exactAZ;
    // Regex qaydaları
    QList<QPair<QRegularExpression, QString>> _regexTR;
    QList<QPair<QRegularExpression, QString>> _regexAZ;
};

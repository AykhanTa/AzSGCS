#include "SpeechLocalizer.h"

SpeechLocalizer& SpeechLocalizer::instance() {
    static SpeechLocalizer inst;
    return inst;
}

SpeechLocalizer::SpeechLocalizer() {
    _initTurkish();
    _initAzerbaijani();
}

void SpeechLocalizer::setLocale(Locale l) { _locale = l; }
SpeechLocalizer::Locale SpeechLocalizer::locale() const { return _locale; }

QString SpeechLocalizer::localeToString(Locale l) {
    switch (l) {
        case Locale::English:     return QStringLiteral("en");
        case Locale::Turkish:     return QStringLiteral("tr");
        case Locale::Azerbaijani: return QStringLiteral("az");
    }
    return QStringLiteral("en");
}

SpeechLocalizer::Locale SpeechLocalizer::stringToLocale(const QString& s) {
    const QString k = s.trimmed().toLower();
    if (k == "tr" || k == "turkish" || k == "tr-tr") return Locale::Turkish;
    if (k == "az" || k == "azerbaijani" || k == "az-az") return Locale::Azerbaijani;
    return Locale::English;
}

QString SpeechLocalizer::_norm(const QString& s) {
    // QGC bəzi yerlərdə say() öncəsi .toLower() çağırır. Açarları lower-case saxlayırıq ki, tapılsın.
    return s.toLower().trimmed();
}

QString SpeechLocalizer::localize(const QString& original) const {
    if (_locale == Locale::English) return original;
    if (original.isEmpty()) return original;

            // Dəqiq xəritəyə bax
    if (const QString exact = _applyExactMap(original); !exact.isEmpty())
        return exact;

            // Regex qaydaları
    if (const QString rx = _applyRegexMap(original); !rx.isEmpty())
        return rx;

            // Heç nə uyğun gəlmədisə, orijinalı saxla
    return original;
}

QString SpeechLocalizer::_applyExactMap(const QString& s) const {
    const auto& map = (_locale == Locale::Turkish) ? _exactTR : _exactAZ;
    const QString key = _norm(s);
    auto it = map.constFind(key);
    return (it == map.constEnd()) ? QString() : *it;
}

QString SpeechLocalizer::_applyRegexMap(const QString& s) const {
    const auto& rules = (_locale == Locale::Turkish) ? _regexTR : _regexAZ;

            // Həm orijinal, həm lowercase versiyanı yoxlayaq
    const QString orig = s;
    const QString low  = _norm(s);

    for (const auto& pair : rules) {
        const QRegularExpression& re = pair.first;
        // Case-insensitive regex istifadə etdiyimiz üçün aşağıdakılardan biri yetər
        // ancaq bəzi hallarda orijinalda böyük/kiçik hərf saxlanması istəyə bilərik.
        auto m = re.match(orig);
        if (!m.hasMatch()) m = re.match(low);
        if (m.hasMatch()) {
            QString fmt = pair.second;
            for (int i = 1; i <= m.lastCapturedIndex(); ++i) {
                fmt = fmt.arg(m.captured(i));
            }
            return fmt;
        }
    }
    return {};
}

void SpeechLocalizer::_initTurkish() {
    // QGC notifikasiyaları (VehicleLinkManager və s.)
    _exactTR.insert(_norm("Communication lost"),                         "İletişim kesildi");
    _exactTR.insert(_norm("Communication regained"),                     "İletişim tekrar sağlandı");
    _exactTR.insert(_norm("Switching communication to secondary link."), "İletişim ikincil bağlantıya aktarılıyor.");
    _exactTR.insert(_norm("Switching communication to new primary link"),"İletişim yeni birincil bağlantıya aktarılıyor");

            // ArduPilot - tez-tez STATUSTEXT-lər
    _exactTR.insert(_norm("PreArm: Motors: Check frame class and type"), "PreArm: Motorlar: Çerçeve sınıfını ve tipini kontrol edin");
    _exactTR.insert(_norm("PreArm: Hardware Safety Switch"),             "PreArm: Donanım güvenlik anahtarı");
    _exactTR.insert(_norm("PreArm: Battery 1 low voltage failsafe"),      "PreArm: Pil 1 düşük voltaj emniyeti");
    _exactTR.insert(_norm("PreArm: 3D Accel calibration needed"),        "PreArm: 3D Accel kalibrasyonu gerekli");
    _exactTR.insert(_norm("PreArm: RC not calibrated"),                  "PreArm: RC kalibre edilmemiş");
    _exactTR.insert(_norm("PreArm: RC not found"),                       "PreArm: RC bulunamadı");
    _exactTR.insert(_norm("PreArm: Barometer not healthy"),              "PreArm: Barometre sağlıklı değil");
    _exactTR.insert(_norm("PreArm: Gyros not healthy"),                  "PreArm: Jiroskoplar sağlıklı değil");
    _exactTR.insert(_norm("PreArm: Accelerometers not healthy"),         "PreArm: İvmeölçerler sağlıklı değil");
    _exactTR.insert(_norm("PreArm: Compass not calibrated"),             "PreArm: Pusula kalibre edilmemiş");
    _exactTR.insert(_norm("PreArm: Compass not healthy"),                "PreArm: Pusula sağlıklı değil");
    _exactTR.insert(_norm("PreArm: GPS 3D fix required"),                "PreArm: GPS 3D kilidi gerekli");
    _exactTR.insert(_norm("PreArm: Battery level too low"),              "PreArm: Pil seviyesi çok düşük");
    _exactTR.insert(_norm("Arm: Safety Switch"),                         "Arm: Güvenlik anahtarı");
    _exactTR.insert(_norm("Arm: RC not found"),                          "Arm: RC bulunamadı");
    _exactTR.insert(_norm("Arm: Thr below FS"),                          "Arm: Gaz failsafe altında");
    _exactTR.insert(_norm("Arm: GPS not locked"),                        "Arm: GPS kilidi yok");
    _exactTR.insert(_norm("Arm: Compass not calibrated"),                "Arm: Pusula kalibre edilmemiş");
    _exactTR.insert(_norm("EKF variance"),                               "EKF varyansı");
    _exactTR.insert(_norm("EKF primary changed"),                        "EKF birincil kaynağı değişti");
    _exactTR.insert(_norm("GPS Glitch"),                                 "GPS hatası");
    _exactTR.insert(_norm("GPS Glitch cleared"),                         "GPS hatası giderildi");
    _exactTR.insert(_norm("Compass inconsistent"),                       "Pusula tutarsız");
    _exactTR.insert(_norm("Inconsistent accelerometers"),                "Tutarsız ivmeölçerler");
    _exactTR.insert(_norm("Inconsistent gyros"),                         "Tutarsız jiroskoplar");
    _exactTR.insert(_norm("Failsafe: Land"),                             "Failsafe: İniş");
    _exactTR.insert(_norm("Failsafe: RTL"),                              "Failsafe: Eve dönüş (RTL)");
    _exactTR.insert(_norm("RC signal lost"),                             "RC sinyali kaybedildi");
    _exactTR.insert(_norm("RC signal recovered"),                        "RC sinyali geri geldi");
    _exactTR.insert(_norm("Geofence triggered"),                         "Sınır (geofence) tetiklendi");
    _exactTR.insert(_norm("Geofence cleared"),                           "Sınır (geofence) temizlendi");
    _exactTR.insert(_norm("Rally point set"),                            "Ralli noktası ayarlandı");
    _exactTR.insert(_norm("Mission complete"),                           "Misyon tamamlandı");
    _exactTR.insert(_norm("Mission resumed"),                            "Misyon devam ediyor");
    _exactTR.insert(_norm("Mission paused"),                             "Misyon duraklatıldı");
    _exactTR.insert(_norm("Landing"),                                    "İniş");
    _exactTR.insert(_norm("Takeoff"),                                    "Kalkış");

    auto CS = QRegularExpression::CaseInsensitiveOption;

            // Generic PreArm/Arm
    _regexTR.append({ QRegularExpression("^prearm:\\s*(.+)$", CS), QStringLiteral("PreArm: %1") });
    _regexTR.append({ QRegularExpression("^arm:\\s*(.+)$",    CS), QStringLiteral("Arm: %1") });

            // Mode changed
    _regexTR.append({ QRegularExpression("^mode\\s+changed\\s+to\\s+(.+)$", CS),
                     QStringLiteral("Uçuş modu %1 olarak değiştirildi") });

            // Param set
    _regexTR.append({ QRegularExpression("^param\\s+(.+)\\s+set\\s+to\\s+(.+)$", CS),
                     QStringLiteral("Parametre %1 %2 olarak ayarlandı") });

            // EKF prefix
    _regexTR.append({ QRegularExpression("^ekf\\s+(.+)$", CS), QStringLiteral("EKF %1") });

            // Battery low
    _regexTR.append({ QRegularExpression("^battery\\s+low\\s*\\((.+)\\)$", CS),
                     QStringLiteral("Pil düşük (%1)") });

            // GPS fix type
    _regexTR.append({ QRegularExpression("^gps\\s+fix\\s+type:\\s*(.+)$", CS),
                     QStringLiteral("GPS kilit türü: %1") });

            // Compass calibration
    _regexTR.append({ QRegularExpression("^compass\\s+calibration\\s+started$",  CS),
                     QStringLiteral("Pusula kalibrasyonu başlatıldı") });
    _regexTR.append({ QRegularExpression("^compass\\s+calibration\\s+finished$", CS),
                     QStringLiteral("Pusula kalibrasyonu tamamlandı") });

            // RTL reason
    _regexTR.append({ QRegularExpression("^rtl\\s+triggered\\s+by\\s+(.+)$", CS),
                     QStringLiteral("RTL şu nedenle tetiklendi: %1") });

            // AltHold setpoint
    _regexTR.append({ QRegularExpression("^althold\\s+setpoint\\s+(.+)$", CS),
                     QStringLiteral("Yükseklik tutma hedefi %1") });
}


void SpeechLocalizer::_initAzerbaijani() {
    // QGC notifikasiyaları
    _exactAZ.insert(_norm("Communication lost"),                         "Əlaqə kəsildi");
    _exactAZ.insert(_norm("Communication regained"),                     "Əlaqə bərpa olundu");
    _exactAZ.insert(_norm("Switching communication to secondary link."), "Əlaqə ikinci linkə keçirilir.");
    _exactAZ.insert(_norm("Switching communication to new primary link"),"Əlaqə yeni əsas linkə keçirilir");

            // ArduPilot STATUSTEXT
    _exactAZ.insert(_norm("PreArm: Motors: Check frame class and type"), "PreArm: Mühərriklər: Çərçivə sinfini və tipini yoxlayın");
    _exactAZ.insert(_norm("PreArm: Hardware Safety Switch"),             "PreArm: Avadanlıq təhlükəsizlik düyməsi");
    _exactAZ.insert(_norm("PreArm: Battery 1 low voltage failsafe"),     "PreArm: Batareya 1 aşağı gərginlikli uğursuzluq");
    _exactAZ.insert(_norm("PreArm: RC not calibrated"),                  "PreArm: RC kalibrlənməyib");
    _exactAZ.insert(_norm("PreArm: RC not found"),                       "PreArm: RC tapılmadı");
    _exactAZ.insert(_norm("PreArm: 3D Accel calibration needed"),        "PreArm: 3D Accel kalibrlənməsi lazımdır");
    _exactAZ.insert(_norm("PreArm: Barometer not healthy"),              "PreArm: Barometr sağlam deyil");
    _exactAZ.insert(_norm("PreArm: Gyros not healthy"),                  "PreArm: Gyro sağlam deyil");
    _exactAZ.insert(_norm("PreArm: Accelerometers not healthy"),         "PreArm: Akselerometrlər sağlam deyil");
    _exactAZ.insert(_norm("PreArm: Compass not calibrated"),             "PreArm: Kompas kalibrlənməyib");
    _exactAZ.insert(_norm("PreArm: Compass not healthy"),                "PreArm: Kompas sağlam deyil");
    _exactAZ.insert(_norm("PreArm: GPS 3D fix required"),                "PreArm: GPS 3D kilid tələb olunur");
    _exactAZ.insert(_norm("PreArm: Battery level too low"),              "PreArm: Batareya səviyyəsi çox aşağıdır");
    _exactAZ.insert(_norm("Arm: Battery 1 low voltage failsafe"),        "Arm: Batareya 1 aşağı gərginlikli uğursuzluq");
    _exactAZ.insert(_norm("Arm: Compass not healthy"),                   "Arm: Kompas sağlam deyil");
    _exactAZ.insert(_norm("Arm: RC not found"),                          "Arm: RC tapılmadı");
    _exactAZ.insert(_norm("Arm: 3D Accel calibration needed"),           "Arm: 3D Accel kalibrlənməsi lazımdır");
    _exactAZ.insert(_norm("Arm: Safety Switch"),                         "Arm: Təhlükəsizlik düyməsi");
    _exactAZ.insert(_norm("Arm: Thr below FS"),                          "Arm: Qaz failsafe həddindən aşağıdır");
    _exactAZ.insert(_norm("Arm: GPS not locked"),                        "Arm: GPS kilidi yoxdur");
    _exactAZ.insert(_norm("Arm: Compass not calibrated"),                "Arm: Kompas kalibrlənməyib");
    _exactAZ.insert(_norm("EKF variance"),                               "EKF varyansı");
    _exactAZ.insert(_norm("EKF primary changed"),                        "EKF əsas mənbə dəyişdi");
    _exactAZ.insert(_norm("GPS Glitch"),                                 "GPS nasazlığı");
    _exactAZ.insert(_norm("GPS Glitch cleared"),                         "GPS nasazlığı aradan qaldırıldı");
    _exactAZ.insert(_norm("Compass inconsistent"),                       "Kompas uyğunsuzdur");
    _exactAZ.insert(_norm("Inconsistent accelerometers"),                "Uyğunsuz akselerometrlər");
    _exactAZ.insert(_norm("Inconsistent gyros"),                         "Uyğunsuz giroskoplar");
    _exactAZ.insert(_norm("Failsafe: Land"),                             "Failsafe: Enmə");
    _exactAZ.insert(_norm("Failsafe: RTL"),                              "Failsafe: Geriyə qayıdış (RTL)");
    _exactAZ.insert(_norm("RC signal lost"),                             "RC siqnalı itdi");
    _exactAZ.insert(_norm("RC signal recovered"),                        "RC siqnalı bərpa olundu");
    _exactAZ.insert(_norm("Geofence triggered"),                         "Sərhəd (geofence) işə düşdü");
    _exactAZ.insert(_norm("Geofence cleared"),                           "Sərhəd (geofence) sıfırlandı");
    _exactAZ.insert(_norm("Rally point set"),                            "Ralli nöqtəsi təyin olundu");
    _exactAZ.insert(_norm("Mission complete"),                           "Missiya tamamlandı");
    _exactAZ.insert(_norm("Mission resumed"),                            "Missiya davam edir");
    _exactAZ.insert(_norm("Mission paused"),                             "Missiya dayandırıldı");
    _exactAZ.insert(_norm("Landing"),                                    "Enmə");
    _exactAZ.insert(_norm("Takeoff"),                                    "Uçuş");

    auto CS = QRegularExpression::CaseInsensitiveOption;

            // Generic PreArm/Arm
    _regexAZ.append({ QRegularExpression("^prearm:\\s*(.+)$", CS), QStringLiteral("PreArm: %1") });
    _regexAZ.append({ QRegularExpression("^arm:\\s*(.+)$",    CS), QStringLiteral("Arm: %1") });

            // Mode changed
    _regexAZ.append({ QRegularExpression("^mode\\s+changed\\s+to\\s+(.+)$", CS),
                     QStringLiteral("Uçuş rejimi %1 olaraq dəyişdirildi") });

            // Param set
    _regexAZ.append({ QRegularExpression("^param\\s+(.+)\\s+set\\s+to\\s+(.+)$", CS),
                     QStringLiteral("Parametr %1 %2 olaraq təyin edildi") });

            // EKF prefix
    _regexAZ.append({ QRegularExpression("^ekf\\s+(.+)$", CS), QStringLiteral("EKF %1") });

            // Battery low
    _regexAZ.append({ QRegularExpression("^battery\\s+low\\s*\\((.+)\\)$", CS),
                     QStringLiteral("Batareya aşağıdır (%1)") });

            // GPS fix type
    _regexAZ.append({ QRegularExpression("^gps\\s+fix\\s+type:\\s*(.+)$", CS),
                     QStringLiteral("GPS kilid növü: %1") });

            // Compass calibration
    _regexAZ.append({ QRegularExpression("^compass\\s+calibration\\s+started$",  CS),
                     QStringLiteral("Kompas kalibrlənməsi başladı") });
    _regexAZ.append({ QRegularExpression("^compass\\s+calibration\\s+finished$", CS),
                     QStringLiteral("Kompas kalibrlənməsi tamamlandı") });

            // RTL reason
    _regexAZ.append({ QRegularExpression("^rtl\\s+triggered\\s+by\\s+(.+)$", CS),
                     QStringLiteral("RTL bu səbəbdən işə düşdü: %1") });

            // AltHold setpoint
    _regexAZ.append({ QRegularExpression("^althold\\s+setpoint\\s+(.+)$", CS),
                     QStringLiteral("Hündürlük tutma hədəfi %1") });
}



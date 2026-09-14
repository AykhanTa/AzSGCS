/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/// @file
///     @author Don Gagne <don@thegagnes.com>

#include "PX4AirframeLoader.h"
#include "QGCApplication.h"
#include "QGCLoggingCategory.h"
#include "AirframeComponentAirframes.h"
#include "AutoPilotPlugin.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QtCore/QXmlStreamReader>
#include <QtCore/QSettings>

QGC_LOGGING_CATEGORY(PX4AirframeLoaderLog, "PX4AirframeLoaderLog")

bool PX4AirframeLoader::_airframeMetaDataLoaded = false;

PX4AirframeLoader::PX4AirframeLoader(AutoPilotPlugin* autopilot, QObject* parent)
{
    Q_UNUSED(autopilot);
    Q_UNUSED(parent);
}

QString PX4AirframeLoader::aiframeMetaDataFile(void)
{
    QSettings settings;
    QDir parameterDir = QFileInfo(settings.fileName()).dir();
    return parameterDir.filePath("PX4AirframeFactMetaData.xml");
}

/// Load Airframe Fact meta data
///
/// The meta data comes from firmware airframes.xml file.
void PX4AirframeLoader::loadAirframeMetaData(void)
{
    if (_airframeMetaDataLoaded) {
        return;
    }

    qCDebug(PX4AirframeLoaderLog) << "Loading PX4 airframe fact meta data";

    if (AirframeComponentAirframes::get().count() != 0) {
        qCWarning(PX4AirframeLoaderLog) << "Internal error";
        return;
    }

    QString airframeFilename;

    // We want unit test builds to always use the resource based meta data to provide repeatable results
    if (!qgcApp()->runningUnitTests()) {
        // First look for meta data that comes from a firmware download. Fall back to resource if not there.
        airframeFilename = aiframeMetaDataFile();
    }
    if (airframeFilename.isEmpty() || !QFile(airframeFilename).exists()) {
        airframeFilename = ":/AutoPilotPlugins/PX4/AirframeFactMetaData.xml";
    }

    qCDebug(PX4AirframeLoaderLog) << "Loading meta data file:" << airframeFilename;

    QFile xmlFile(airframeFilename);
    if (!xmlFile.exists()) {
        qCWarning(PX4AirframeLoaderLog) << "Internal error";
        return;
    }

    bool success = xmlFile.open(QIODevice::ReadOnly);

    if (!success) {
        qCWarning(PX4AirframeLoaderLog) << "Failed opening airframe XML";
        return;
    }

    QXmlStreamReader xml(xmlFile.readAll());
    xmlFile.close();
    if (xml.hasError()) {
        qCWarning(PX4AirframeLoaderLog) << "Badly formed XML" << xml.errorString();
        return;
    }

    QString         airframeGroup;
    QString         image;
    int             xmlState = XmlStateNone;

    while (!xml.atEnd()) {
        if (xml.isStartElement()) {
            QString elementName = xml.name().toString();

            if (elementName == "airframes") {
                if (xmlState != XmlStateNone) {
                    qCWarning(PX4AirframeLoaderLog) << "Badly formed XML";
                    return;
                }
                xmlState = XmlStateFoundAirframes;

            } else if (elementName == "version") {
                if (xmlState != XmlStateFoundAirframes) {
                    qCWarning(PX4AirframeLoaderLog) << "Badly formed XML";
                    return;
                }
                xmlState = XmlStateFoundVersion;

                bool convertOk;
                QString strVersion = xml.readElementText();
                int intVersion = strVersion.toInt(&convertOk);
                if (!convertOk) {
                    qCWarning(PX4AirframeLoaderLog) << "Badly formed XML";
                    return;
                }
                if (intVersion < 1) {
                    // We can't read these old files
                    qDebug() << "Airframe version stamp too old, skipping load. Found:" << intVersion << "Want: 3 File:" << airframeFilename;
                    return;
                }

            } else if (elementName == "airframe_version_major") {
                // Just skip over for now
            } else if (elementName == "airframe_version_minor") {
                // Just skip over for now

            } else if (elementName == "airframe_group") {
                if (xmlState != XmlStateFoundVersion) {
                    // We didn't get a version stamp, assume older version we can't read
                    qDebug() << "Parameter version stamp not found, skipping load" << airframeFilename;
                    return;
                }
                xmlState = XmlStateFoundGroup;

                if (!xml.attributes().hasAttribute("name") || !xml.attributes().hasAttribute("image")) {
                    qCWarning(PX4AirframeLoaderLog) << "Badly formed XML";
                    return;
                }
                airframeGroup = xml.attributes().value("name").toString();
                image = xml.attributes().value("image").toString();
                qCDebug(PX4AirframeLoaderLog) << "Found group: " << airframeGroup << " image:" << image;

            } else if (elementName == "airframe") {
                if (xmlState != XmlStateFoundGroup) {
                    qCWarning(PX4AirframeLoaderLog) << "Badly formed XML";
                    return;
                }
                xmlState = XmlStateFoundAirframe;

                if (!xml.attributes().hasAttribute("name") || !xml.attributes().hasAttribute("id")) {
                    qCWarning(PX4AirframeLoaderLog) << "Badly formed XML";
                    return;
                }

                QString name = xml.attributes().value("name").toString();
                QString id = xml.attributes().value("id").toString();

                qCDebug(PX4AirframeLoaderLog) << "Found airframe name:" << name << " type:" << airframeGroup << " id:" << id;

                // Now that we know type we can airframe meta data object and add it to the system
                AirframeComponentAirframes::insert(airframeGroup, image, name, id.toInt());

            } else {
                // We should be getting meta data now
                if (xmlState != XmlStateFoundAirframe) {
                    qCWarning(PX4AirframeLoaderLog) << "Badly formed XML";
                    return;
                }
            }
        } else if (xml.isEndElement()) {
            QString elementName = xml.name().toString();

            if (elementName == "airframe") {
                // Reset for next airframe
                xmlState = XmlStateFoundGroup;
            } else if (elementName == "airframe_group") {
                xmlState = XmlStateFoundVersion;
            } else if (elementName == "airframes") {
                xmlState = XmlStateFoundAirframes;
            }
        }
        xml.readNext();
    }

    _insertCustomAirframes();

    _airframeMetaDataLoaded = true;
}

/// AzShield ships artwork for airframes that fly a stock PX4 configuration under their own name.
///
/// They are added here rather than in AirframeFactMetaData.xml because that file is only the
/// fallback: flashing firmware from within the app caches the firmware's own airframe meta data
/// (see FirmwareImage) and loadAirframeMetaData() prefers it, which would silently drop anything
/// we had added to the bundled resource.
void PX4AirframeLoader::_insertCustomAirframes(void)
{
    struct CustomAirframe_t {
        const char *group;          ///< Card title, and the key AirframeComponentAirframes groups on
        const char *image;          ///< Basename of the artwork under :/qmlimages/Airframe/
        const char *name;           ///< Entry shown in the card's combo box
        int         autostartId;    ///< SYS_AUTOSTART value written to the vehicle
    };

    // These share the autostart id of the stock configuration they are a variant of, so that
    // selecting one flashes exactly the same parameters.
    static const CustomAirframe_t rgCustomAirframes[] = {
        { "AzShield Wing", "AzShieldWing", "AzShield Flying Wing", 3000 },  // "Generic Flying Wing"
    };

    for (const CustomAirframe_t &custom : rgCustomAirframes) {
        QString group = QString::fromLatin1(custom.group);
        if (AirframeComponentAirframes::get().contains(group)) {
            // Already supplied by the meta data file
            continue;
        }

        QString image = QString::fromLatin1(custom.image);
        QString name = QString::fromLatin1(custom.name);
        AirframeComponentAirframes::insert(group, image, name, custom.autostartId);

        qCDebug(PX4AirframeLoaderLog) << "Added custom airframe group:" << group << "id:" << custom.autostartId;
    }
}

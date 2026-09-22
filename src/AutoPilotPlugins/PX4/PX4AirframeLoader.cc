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

/// AzShield flies its own airframes on stock PX4 configurations, under their own names
/// and artwork.
///
/// They are applied here rather than edited into AirframeFactMetaData.xml because that file is
/// only the fallback: flashing firmware from within the app caches the firmware's own airframe
/// meta data (see FirmwareImage) and loadAirframeMetaData() prefers it, which would silently
/// drop anything we had changed in the bundled resource.
void PX4AirframeLoader::_insertCustomAirframes(void)
{
    /// A stock group shown under an AzShield name. Taking the group over rather than adding a
    /// new one keeps its autostart id and its list of models, and leaves the id unique -- with
    /// two groups on one id, AirframeComponentController cannot tell which one a vehicle
    /// reporting that id is running.
    struct Rebrand_t {
        const char *stockGroup;      ///< Group as the firmware meta data names it
        const char *group;           ///< Name to show instead
        const char *image;           ///< Artwork basename under :/qmlimages/Airframe/
        const char *airframeName;    ///< Renames the combo box entry of a single-model group
        int         keepAutostartId; ///< Narrows a multi-model group to this one; 0 keeps them all
    };

    static const Rebrand_t rgRebrands[] = {
        { "Flying Wing",    "Qırat H10", "QiratH10", "Qırat H10", 0 },
        { "Standard Plane", "Qırat H20", "QiratH20", "Qırat H20", 0 },
        // Quadrotor x lists 16 models. Only the generic one (4001) is flown here, so the rest
        // are dropped rather than offered as configurations nobody selects.
        { "Quadrotor x",    "Boran",          "Boran",    "Quadcopter",     4001 },
    };

    /// An extra card for an airframe that flies a configuration a rebranded card already covers,
    /// so the two flash identical parameters. These are registered as secondary: a vehicle
    /// reports only its autostart id and cannot say which of the airframes sharing it is fitted,
    /// and the rebranded card owns the selection rather than whichever group is visited last.
    struct Added_t {
        const char *group;
        const char *image;
        const char *name;
        int         autostartId;    ///< SYS_AUTOSTART value written to the vehicle
    };

    static const Added_t rgAdded[] = {
        { "Arrow-2",   "Arrow-2",  "Arrow-2",   3000 },  // as Qırat H10
        { "Qırat H30", "QiratH30", "Qırat H30", 2100 },  // as Qırat H20
    };

    for (const Rebrand_t &rebrand : rgRebrands) {
        const QString stockGroup = QString::fromUtf8(rebrand.stockGroup);
        const QString group = QString::fromUtf8(rebrand.group);
        if (!AirframeComponentAirframes::get().contains(stockGroup)) {
            qCDebug(PX4AirframeLoaderLog) << "Cannot rebrand missing airframe group:" << stockGroup;
            continue;
        }

        AirframeComponentAirframes::rename(stockGroup, group, QString::fromUtf8(rebrand.image),
                                           rebrand.airframeName ? QString::fromUtf8(rebrand.airframeName) : QString(),
                                           rebrand.keepAutostartId);

        qCDebug(PX4AirframeLoaderLog) << "Rebranded airframe group:" << stockGroup << "as" << group;
    }

    for (const Added_t &added : rgAdded) {
        QString group = QString::fromUtf8(added.group);
        if (AirframeComponentAirframes::get().contains(group)) {
            // Already supplied by the meta data file
            continue;
        }

        QString image = QString::fromUtf8(added.image);
        QString name = QString::fromUtf8(added.name);
        AirframeComponentAirframes::insert(group, image, name, added.autostartId, true /* secondary */);

        qCDebug(PX4AirframeLoaderLog) << "Added airframe group:" << group << "id:" << added.autostartId;
    }
}

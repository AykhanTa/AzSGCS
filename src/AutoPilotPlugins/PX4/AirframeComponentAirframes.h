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

#pragma once

#include <QtCore/QList>
#include <QtCore/QMap>

/// MVC Controller for AirframeComponent.qml.
class AirframeComponentAirframes
{
public:
    typedef struct {
        QString name;
        int         autostartId;
    } AirframeInfo_t;
    
    typedef struct {
        QString name;
        QString imageResource;
        /// true: this group shares its autostart id with another one and yields the selection to
        /// it. A vehicle reports only the id, so it cannot say which of them is fitted.
        /// Set by insert(); no default initializer, because MSVC rejects one in a typedef of an
        /// unnamed struct (C7626).
        bool    secondary;
        QList<AirframeInfo_t*> rgAirframeInfo;
    } AirframeType_t;

    static QMap<QString, AirframeComponentAirframes::AirframeType_t*>& get();
    static void clear();
    static void insert(QString& group, QString& image, QString& name, int id, bool secondary = false);

    /// Renames a group and swaps its artwork, keeping the autostart ids it carries.
    ///
    /// keepAutostartId, when non-zero, drops every model in the group except that one, so a group
    /// standing for a family of airframes can be narrowed to the single branded one. It is
    /// ignored if the group does not carry that id, since an empty group would leave a card with
    /// nothing to select. singleAirframeName renames the remaining entry, and is ignored while
    /// the group still lists several models. No-op when the group is not there.
    static void rename(const QString &oldGroup, const QString &newGroup, const QString &image,
                       const QString &singleAirframeName = QString(), int keepAutostartId = 0);
    
protected:
    static QMap<QString, AirframeType_t*> rgAirframeTypes;
    
private:
};

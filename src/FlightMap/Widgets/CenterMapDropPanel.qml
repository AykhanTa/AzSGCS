// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: centerMapPanel

    // ✅ PROPERTIES
    property var  map
    property var  fitFunctions
    property bool showMission:  true
    property bool showAllItems: true

    readonly property real pad:   Math.max(10, ScreenTools.defaultFontPixelWidth)
    readonly property real rowH:  Math.max(40, ScreenTools.defaultFontPixelHeight * 2.2)
    readonly property real gap:   Math.max(5,  ScreenTools.defaultFontPixelHeight * 0.3)

    // Gizli sətirlər yer tutmasın deyə hündürlük məzmundan hesablanır
    width:  Math.max(210, ScreenTools.defaultFontPixelWidth * 26)
    height: mainColumn.implicitHeight + pad * 2
    color:  "#2A2A2A"
    radius: 12
    border.width: 1
    border.color: "#6E6E6E"

    /// Menyu sətri — etiket solda, hover-də yaşıl sol kənar
    component MenuRow: Rectangle {
        id: mrow

        property alias  label:  mrowLabel.text
        property bool   active: true
        property real   pad:    10
        property real   rowH:   40

        signal activated()

        width:  parent ? parent.width : 0
        height: rowH
        radius: 8
        color:  !active ? "#333131"
                        : (mrowMouse.pressed ? "#565454"
                                             : (mrowMouse.containsMouse ? "#4A4848" : "#3D3B3B"))

        Behavior on color { ColorAnimation { duration: 110 } }

        Rectangle {
            anchors.left:           parent.left
            anchors.leftMargin:     2
            anchors.verticalCenter: parent.verticalCenter
            width:                  3
            height:                 parent.height * 0.6
            radius:                 1.5
            color:                  "#00C853"
            visible:                mrow.active && mrowMouse.containsMouse
        }

        QGCLabel {
            id: mrowLabel
            anchors.left:           parent.left
            anchors.leftMargin:     mrow.pad
            anchors.right:          parent.right
            anchors.rightMargin:    mrow.pad
            anchors.verticalCenter: parent.verticalCenter
            color:                  mrow.active ? "#FFFFFF" : "#7E7E7E"
            font.pointSize:         ScreenTools.defaultFontPointSize
            elide:                  Text.ElideRight
        }

        QGCMouseArea {
            id:             mrowMouse
            anchors.fill:   parent
            hoverEnabled:   true
            enabled:        mrow.active
            cursorShape:    mrow.active ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked:      mrow.activated()
        }
    }

    Column {
        id: mainColumn
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.margins:    centerMapPanel.pad
        spacing:            centerMapPanel.gap

        // ---------- Başlıq ----------
        QGCLabel {
            width:               parent.width
            text:                qsTr("Xəritə mərkəzi")
            color:               "#FFFFFF"
            font.bold:           true
            font.pointSize:      ScreenTools.defaultFontPointSize
            horizontalAlignment: Text.AlignHCenter
            bottomPadding:       centerMapPanel.gap
        }

        Rectangle {
            width:  parent.width
            height: 1
            color:  "#4A4A4A"
        }

        Item { width: 1; height: centerMapPanel.gap * 0.5 }

        // ---------- Missiya ----------
        MenuRow {
            label:      qsTr("Missiya")
            pad:        centerMapPanel.pad
            rowH:       centerMapPanel.rowH
            visible:    showMission
            onActivated: {
                dropPanel.hide()
                fitFunctions.fitMapViewportToMissionItems()
            }
        }

        // ---------- Bütün nöqtələr ----------
        MenuRow {
            label:      qsTr("Bütün nöqtələr")
            pad:        centerMapPanel.pad
            rowH:       centerMapPanel.rowH
            visible:    showAllItems
            onActivated: {
                dropPanel.hide()
                fitFunctions.fitMapViewportToAllItems()
            }
        }

        // ---------- Başlanğıc nöqtəsi ----------
        MenuRow {
            label:      qsTr("Başlanğıc nöqtəsi")
            pad:        centerMapPanel.pad
            rowH:       centerMapPanel.rowH
            onActivated: {
                dropPanel.hide()
                map.center = fitFunctions.fitHomePosition()
            }
        }

        // ---------- Təyyarə ----------
        MenuRow {
            label:      qsTr("Təyyarə")
            pad:        centerMapPanel.pad
            rowH:       centerMapPanel.rowH
            active:     globals.activeVehicle && globals.activeVehicle.coordinate.isValid
            onActivated: {
                dropPanel.hide()
                map.center = globals.activeVehicle.coordinate
            }
        }

        // ---------- Cari məkan ----------
        MenuRow {
            label:      qsTr("Cari Məkan")
            pad:        centerMapPanel.pad
            rowH:       centerMapPanel.rowH
            active:     map.gcsPosition.isValid
            onActivated: {
                dropPanel.hide()
                map.center = map.gcsPosition
            }
        }

        // ---------- Müəyyən edilmiş yer ----------
        MenuRow {
            label:      qsTr("Müəyyən edilmiş Yer")
            pad:        centerMapPanel.pad
            rowH:       centerMapPanel.rowH
            onActivated: {
                dropPanel.hide()
                map.centerToSpecifiedLocation()
            }
        }
    }
}

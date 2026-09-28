/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQml.Models

import QGroundControl
import QGroundControl.Controls


/// A PreFlightCheckGroup manages a set of PreFlightCheckButtons as a single entity.
Column  {
    id: checkGroup

    property string name
    property bool   passed: false
    property bool   failed: false

    // Düymələrlə eyni yığcamlıq eşiyi, yoxsa aralıqlar tək başına yer yeyir.
    readonly property bool _compact: ScreenTools.isShortScreen

    spacing: ScreenTools.defaultFontPixelHeight * (_compact ? 0.28 : 0.5)

    property alias _checked: header.checked

    onPassedChanged: parent.groupPassedChanged(ObjectModel.index, passed)

    Component.onCompleted: {
        enabled = _checked
        var moveList = []
        var i = 0
        for (i = 2; i < children.length; i++) {
            moveList.push(children[i])
        }
        for (i = 0; i < moveList.length; i++) {
            moveList[i].parent = innerColumn
        }
    }

    function reset() {
        for (var i=0; i<innerColumn.children.length; i++) {
            innerColumn.children[i].reset()
        }
    }

    SectionHeader {
        id:             header
        anchors.left:   parent.left
        anchors.right:  parent.right
        // Üç qrup başlığı kiçik ekranda siyahı hündürlüyünün dörddə birini
        // yeyirdi. Toxunma sahəsi hələ də rahat qalacaq qədər saxlanılıb.
        headerHeight:   checkGroup._compact ? Math.max(32, ScreenTools.defaultFontPixelHeight * 1.7)
                                            : Math.max(40, ScreenTools.defaultFontPixelHeight * 2.2)
        _sectionSpacer: ScreenTools.defaultFontPixelWidth * (checkGroup._compact ? 0.25 : 0.5)
        // Qrup adları cümlədir ("Zəhmət olmasa aparatı burada işə salın") və dar panelə
        // sığmayanda kəsilirdi.
        shrinkToFit:    true
        text:           name + (passed ? qsTr(" (passed)") : "")
        color:          failed ? qgcPal.statusFailedText : (passed ? qgcPal.statusPassedText : qgcPal.statusPendingText)
    }

    Column {
        id:         innerColumn
        spacing:    ScreenTools.defaultFontPixelHeight * (checkGroup._compact ? 0.28 : 0.5)
        visible:    header.checked

        function buttonPassedChanged() {
            for (var i=0; i<children.length; i++) {
                if (!children[i].passed) {
                    passed = false
                    failed = children[i].failed
                    return
                }
            }
            failed = false
            passed = true
        }
    }
}

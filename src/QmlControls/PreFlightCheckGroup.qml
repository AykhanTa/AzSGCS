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

    // Every button of the group takes this width. PreFlightCheckList sets it to its own
    // width when the list is given one; the default is the old fixed button width.
    property real   contentWidth: ScreenTools.defaultFontPixelWidth * (_compact ? 29 : 40)

    width: contentWidth

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

    // Group heading: the name in the state colour and a chevron; a click folds it.
    Item {
        id:     header
        width:  checkGroup.width
        height: Math.max(AzTheme.px(40), headerText.implicitHeight + AzTheme.px(12))

        property bool checked: true

        Text {
            id:                     headerText
            anchors.left:           parent.left
            anchors.right:          headerChevron.left
            anchors.rightMargin:    AzTheme.px(8)
            anchors.verticalCenter: parent.verticalCenter
            // Qrup adları cümlədir ("Zəhmət olmasa aparatı burada işə salın") və dar
            // panelə sığmayanda kəsilirdi.
            wrapMode:               Text.WordWrap
            text:                   name + (passed ? qsTr(" (passed)") : "")
            color:                  failed ? AzTheme.statusRed : (passed ? AzTheme.statusGreen : AzTheme.textCard)
            font.family:            AzTheme.fontFamily
            font.weight:            Font.Medium
            font.pixelSize:         AzTheme.fontPx(16)
        }

        QGCColoredImage {
            id:                     headerChevron
            anchors.right:          parent.right
            anchors.rightMargin:    AzTheme.px(4)
            anchors.verticalCenter: parent.verticalCenter
            width:                  AzTheme.px(20)
            height:                 width
            sourceSize.height:      height
            source:                 "qrc:/res/AZSHIELD_ICON/v2/popup_chevron.svg"
            color:                  AzTheme.textCard
            rotation:               header.checked ? 180 : 0
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    header.checked = !header.checked
        }
    }

    Column {
        id:         innerColumn
        width:      checkGroup.width
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

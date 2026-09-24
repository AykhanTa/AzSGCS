import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

/// Açılıb-bağlanan bölmə başlığı.
/// API dəyişməyib (CheckBox: text / checked / buttonGroup / color / showSpacer),
/// yalnız görünüş plan panelindəki blok dizaynı ilə eyniləşdirilib.
CheckBox {
    id:             control
    focusPolicy:    Qt.ClickFocus
    checked:        true
    padding:        0
    leftPadding:    0
    rightPadding:   0

    property var            color:          "#FFFFFF"
    property bool           showSpacer:     true
    property ButtonGroup    buttonGroup:    null

    property color accentColor:    "#00C853"

    /// Başlıq zolağının hündürlüyü. Yığcam yerlərdə (məs. uçuşdan əvvəl yoxlama
    /// siyahısı) kiçildilə bilsin deyə açıq saxlanılıb; default dəyər dəyişməyib.
    property real  headerHeight:   Math.max(40, ScreenTools.defaultFontPixelHeight * 2.2)

    property real  _pad:           Math.max(8, ScreenTools.defaultFontPixelWidth * 0.9)
    property real  _sectionSpacer: ScreenTools.defaultFontPixelWidth / 2

    onButtonGroupChanged: {
        if (buttonGroup) {
            buttonGroup.addButton(control)
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    contentItem: Item {
        implicitHeight: headerRect.height + (control.showSpacer ? control._sectionSpacer : 0)

        Rectangle {
            id:             headerRect
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            height:         control.headerHeight
            radius:         8
            color:          headerHover.hovered ? "#3A3A3A" : "#2A2A2A"

            Behavior on color { ColorAnimation { duration: 120 } }

            HoverHandler { id: headerHover }

            // Açıq olduğunu bildirən sol kənar
            Rectangle {
                anchors.left:           parent.left
                anchors.leftMargin:     1
                anchors.verticalCenter: parent.verticalCenter
                width:                  3
                height:                 parent.height * 0.55
                radius:                 1.5
                color:                  control.accentColor
                visible:                control.checked
            }

            QGCLabel {
                anchors.left:           parent.left
                anchors.leftMargin:     control._pad
                anchors.right:          chevron.left
                anchors.rightMargin:    control._pad * 0.5
                anchors.verticalCenter: parent.verticalCenter
                text:                   control.text
                color:                  control.color
                font.bold:              true
                font.pointSize:         ScreenTools.defaultFontPointSize
                elide:                  Text.ElideRight
            }

            QGCColoredImage {
                id:                     chevron
                anchors.right:          parent.right
                anchors.rightMargin:    control._pad
                anchors.verticalCenter: parent.verticalCenter
                width:                  Math.max(10, ScreenTools.defaultFontPixelHeight * 0.45)
                height:                 width
                source:                 "/res/DropArrow.svg"
                color:                  "#CFCFCF"
                rotation:               control.checked ? 180 : 0

                Behavior on rotation { NumberAnimation { duration: 140 } }
            }
        }
    }

    indicator: Item {}
}

import QtQuick
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls

// Support page, in the new design: the page header of the setup pages and a status card with
// the version on a group box row. No external links are shown until the support pages exist.
Item {
    id: root
    anchors.fill: parent

    // The labels take the new design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    readonly property bool phone:   ScreenTools.isMobile || width < 720
    readonly property real sidePad: AzTheme.px(phone ? 12 : 20)

    ColumnLayout {
        x:       root.sidePad
        y:       AzTheme.px(20)
        width:   Math.max(0, root.width - 2 * root.sidePad)
        spacing: AzTheme.px(16)

        // Header
        ColumnLayout {
            Layout.fillWidth: true
            spacing: AzTheme.px(6)

            Text {
                Layout.fillWidth: true
                text: qsTr("%1 Dəstək").arg(QGroundControl.appName)
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(root.phone ? 18 : 20)
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Proqram versiyası və dəstək məlumatları")
                color: AzTheme.textSecondary
                font.family: AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(13)
                wrapMode: Text.WordWrap
            }
        }

        // The status card
        Rectangle {
            id: infoCard
            Layout.fillWidth: true
            Layout.maximumWidth: AzTheme.px(820)
            implicitHeight: infoLayout.implicitHeight + pad * 2
            radius: AzTheme.px(AzTheme.cardRadius)
            border.width: 1
            border.color: AzTheme.cardBorder
            gradient: Gradient {
                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
            }

            readonly property real pad: AzTheme.px(16)

            ColumnLayout {
                id: infoLayout
                x: infoCard.pad
                y: infoCard.pad
                width: infoCard.width - 2 * infoCard.pad
                spacing: AzTheme.px(8)

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Proqram haqqında")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(16)
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(AzTheme.px(AzTheme.groupRowHeight + 4), versionRow.implicitHeight + AzTheme.px(16))
                    radius: AzTheme.px(AzTheme.groupRadius)
                    color: AzTheme.groupFill
                    border.width: 1
                    border.color: AzTheme.groupBorder

                    RowLayout {
                        id: versionRow
                        anchors.fill: parent
                        anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                        anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                        spacing: AzTheme.px(16)

                        QGCLabel {
                            text: qsTr("Versiya")
                            font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            text: QGroundControl.qgcVersion
                            color: AzTheme.textSecondary
                            font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                            horizontalAlignment: Text.AlignRight
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: qsTr("Dəstək əlaqə məlumatları sonradan əlavə olunacaq.")
                    color: AzTheme.textSecondary
                    font.pixelSize: AzTheme.fontPx(12)
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}

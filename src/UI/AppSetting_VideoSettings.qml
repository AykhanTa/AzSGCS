

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

// Video settings, in the new design: the page header of the setup pages, status cards with
// group box rows, and the new combo boxes, fields and switches.
SettingsPage {
    id: root

    // The combo boxes, fields and labels take the new design's look (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ------------------ Data ------------------
    property var    _settingsManager:            QGroundControl.settingsManager
    property var    _videoManager:               QGroundControl.videoManager
    property var    _videoSettings:              _settingsManager.videoSettings
    property string _videoSource:                _videoSettings.videoSource.rawValue
    property bool   _isGST:                      _videoManager.gstreamerEnabled
    property bool   _isStreamSource:             _videoManager.isStreamSource
    property bool   _isUDP264:                   _isStreamSource && (_videoSource === _videoSettings.udp264VideoSource)
    property bool   _isUDP265:                   _isStreamSource && (_videoSource === _videoSettings.udp265VideoSource)
    property bool   _isRTSP:                     _isStreamSource && (_videoSource === _videoSettings.rtspVideoSource)
    property bool   _isTCP:                      _isStreamSource && (_videoSource === _videoSettings.tcpVideoSource)
    property bool   _isMPEGTS:                   _isStreamSource && (_videoSource === _videoSettings.mpegtsVideoSource)
    property bool   _videoAutoStreamConfig:      _videoManager.autoStreamConfigured
    property bool   _videoSourceDisabled:        _videoSource === _videoSettings.disabledVideoSource
    property bool   _requiresUDPUrl:             _isUDP264 || _isUDP265 || _isMPEGTS

    // ------------------ Responsive metrics ------------------
    readonly property bool phone:  ScreenTools.isMobile || width < 720
    readonly property bool tablet: width < 1100
    readonly property bool tiny:   width < 560

    readonly property real sidePad: AzTheme.px(phone ? 12 : 20)
    readonly property real gap:     AzTheme.px(phone ? 10 : 16)
    readonly property real cardPad: AzTheme.px(16)

    readonly property real titlePx: AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descPx:  AzTheme.fontPx(13)

    readonly property real sectionPx: AzTheme.fontPx(16)
    readonly property real labelPx:   AzTheme.fontPx(AzTheme.popupTextSize)

    readonly property real rowPadX: AzTheme.px(AzTheme.groupPadding)
    readonly property real rowPadY: AzTheme.px(8)
    readonly property real rowMinH: AzTheme.px(AzTheme.groupRowHeight + 4)

    readonly property real availableW: Math.max(0, width - 2 * sidePad)
    readonly property real cardW: availableW

    // Blok ölçüləri Uçuş Görünüşü səhifəsi ilə eynidir (Fly_ViewSettings.qml)
    readonly property real innerW:  contentCol.width
    readonly property real minColW: (tablet ? 520 : 720)
    readonly property real maxColW: 820

    readonly property int columns: (phone || innerW < (2 * minColW + gap)) ? 1 : 2

    readonly property real colW: (columns === 1)
                                 ? innerW
                                 : Math.min(maxColW, Math.floor((innerW - gap) / 2))

    readonly property real panelW: colW

    // ✅ Sağdakı kontrol elementləri (combo / textfield) üçün sabit en
    readonly property real ctrlW:  Math.max(140, Math.min(260, colW * (phone ? 0.60 : 0.42)))


    // URL field width - responsiv
    readonly property real _urlFieldWidth: ctrlW

    // Wheel addım
    readonly property real wheelStepPx: Math.max(60, ScreenTools.defaultFontPixelHeight * 3.2)

    // ✅ Wheel həmişə tutulur -> arxa xəritəyə keçməsin
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse
        onWheel: (event) => {
            event.accepted = true

            // ScrollView-un daxili Flickable-ı
            var f = scrollView.contentItem
            if (!f) return

            var delta = (event.pixelDelta.y !== 0)
                      ? event.pixelDelta.y
                      : (event.angleDelta.y / 120.0) * root.wheelStepPx

            var maxY = Math.max(0, f.contentHeight - f.height)
            f.contentY = Math.max(0, Math.min(maxY, f.contentY - delta))
        }
    }

    // ================== Header ==================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: AzTheme.px(20)
        spacing: AzTheme.px(6)

        Text {
            text: qsTr("Video Ayarları")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titlePx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Text {
            text: qsTr("Video mənbəyi və qeyd parametrləri")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descPx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }

    // ================== Scroll (only vertical, no horizontal) ==================
    ScrollView {
        id: scrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        // ❗ Sağa scroll olmasın
        contentWidth: width

        Column {
            id: contentCol
            width: scrollView.width
            spacing: root.gap

        Flow {
            id: panelFlow
            width: contentCol.width
            spacing: root.gap
            height: childrenRect.height

            // ================== VIDEO SOURCE SECTION ==================
            Rectangle {
                id: videoSourcePanel
                width: Math.min(root.panelW, panelFlow.width)
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                readonly property real desiredH: videoSourceGroup.implicitHeight + root.cardPad * 2
                height: desiredH

                ColumnLayout {
                    id: videoSourceGroup
                    anchors.fill: parent
                    anchors.margins: root.cardPad
                    spacing: AzTheme.px(8)

                    QGCLabel {
                        text: qsTr("Video Mənbə")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionPx
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _videoSettings.videoSource.visible
                        implicitHeight: Math.max(rowMinH, srcGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: srcGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("Mənbə")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            FactComboBox {
                                indexModel: false
                                sizeToContents: false
                                fact: _videoSettings.videoSource
                                Layout.fillWidth: root.phone
                                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                            }
                        }
                    }
                }
            }

            // ================== CONNECTION SECTION ==================
            Rectangle {
                id: connectionPanel
                width: Math.min(root.panelW, panelFlow.width)
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                visible: !_videoSourceDisabled && !_videoAutoStreamConfig && (_isTCP || _isRTSP || _requiresUDPUrl)

                readonly property real desiredH: connectionGroup.implicitHeight + root.cardPad * 2
                height: desiredH

                ColumnLayout {
                    id: connectionGroup
                    anchors.fill: parent
                    anchors.margins: root.cardPad
                    spacing: AzTheme.px(8)

                    QGCLabel {
                        text: qsTr("Əlaqə")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionPx
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _isRTSP && _videoSettings.rtspUrl.visible
                        implicitHeight: Math.max(rowMinH, rtspGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: rtspGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("RTSP URL")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            FactTextField {
                                fact: _videoSettings.rtspUrl
                                Layout.fillWidth: root.phone
                                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _isTCP && _videoSettings.tcpUrl.visible
                        implicitHeight: Math.max(rowMinH, tcpGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: tcpGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("TCP URL")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            FactTextField {
                                fact: _videoSettings.tcpUrl
                                Layout.fillWidth: root.phone
                                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _requiresUDPUrl && _videoSettings.udpUrl.visible
                        implicitHeight: Math.max(rowMinH, udpGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: udpGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("UDP URL")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            FactTextField {
                                fact: _videoSettings.udpUrl
                                Layout.fillWidth: root.phone
                                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                            }
                        }
                    }
                }
            }

            // ================== SETTINGS SECTION ==================
            Rectangle {
                id: settingsPanel
                width: Math.min(root.panelW, panelFlow.width)
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                visible: !_videoSourceDisabled

                readonly property real desiredH: settingsGroup.implicitHeight + root.cardPad * 2
                height: desiredH

                ColumnLayout {
                    id: settingsGroup
                    anchors.fill: parent
                    anchors.margins: root.cardPad
                    spacing: AzTheme.px(8)

                    QGCLabel {
                        text: qsTr("Parametrlər")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionPx
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
                        implicitHeight: Math.max(rowMinH, arGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: arGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("Aspekt nisbəti")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            FactTextField {
                                fact: _videoSettings.aspectRatio
                                Layout.fillWidth: root.phone
                                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.disableWhenDisarmed.visible
                        implicitHeight: Math.max(rowMinH, disarmGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: disarmGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("Disarm zaman qeydi dayandırın")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            AzSwitch {
                                checked: _videoSettings.disableWhenDisarmed.value
                                Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                                onClicked: _videoSettings.disableWhenDisarmed.value = !_videoSettings.disableWhenDisarmed.value
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.lowLatencyMode.visible && _isGST
                        implicitHeight: Math.max(rowMinH, llGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: llGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("Low Latency rejimi")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            AzSwitch {
                                checked: _videoSettings.lowLatencyMode.value
                                Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                                onClicked: _videoSettings.lowLatencyMode.value = !_videoSettings.lowLatencyMode.value
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _videoSettings.forceVideoDecoder.visible
                        implicitHeight: Math.max(rowMinH, decGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: decGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("Videonun deşifrə prioriteti")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            FactComboBox {
                                indexModel: false
                                sizeToContents: false
                                fact: _videoSettings.forceVideoDecoder
                                Layout.fillWidth: root.phone
                                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                            }
                        }
                    }
                }
            }

            // ================== LOCAL VIDEO STORAGE SECTION ==================
            Rectangle {
                id: storagePanel
                width: Math.min(root.panelW, panelFlow.width)
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }

                readonly property real desiredH: storageGroup.implicitHeight + root.cardPad * 2
                height: desiredH

                ColumnLayout {
                    id: storageGroup
                    anchors.fill: parent
                    anchors.margins: root.cardPad
                    spacing: AzTheme.px(8)

                    QGCLabel {
                        text: qsTr("Yerli Video Yaddaşı")
                        color: AzTheme.textCard
                        font.family: AzTheme.fontFamily
                        font.weight: Font.Medium
                        font.pixelSize: sectionPx
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _videoSettings.recordingFormat.visible
                        implicitHeight: Math.max(rowMinH, fmtGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: fmtGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("Qeyd Fayl Formatı")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            FactComboBox {
                                indexModel: false
                                sizeToContents: false
                                fact: _videoSettings.recordingFormat
                                Layout.fillWidth: root.phone
                                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _videoSettings.enableStorageLimit.visible
                        implicitHeight: Math.max(rowMinH, delGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: delGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("Saxlanılan qeydləri avtomatik silmək")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            AzSwitch {
                                checked: _videoSettings.enableStorageLimit.value
                                Layout.alignment: phone ? Qt.AlignLeft : Qt.AlignRight
                                onClicked: _videoSettings.enableStorageLimit.value = !_videoSettings.enableStorageLimit.value
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: AzTheme.px(AzTheme.groupRadius)
                        color: AzTheme.groupFill
                        border.width: 1
                        border.color: AzTheme.groupBorder
                        visible: _videoSettings.maxVideoSize.visible
                        implicitHeight: Math.max(rowMinH, maxGrid.implicitHeight + rowPadY * 2)
                        height: implicitHeight

                        GridLayout {
                            id: maxGrid
                            anchors.fill: parent
                            anchors.leftMargin: rowPadX
                            anchors.rightMargin: rowPadX
                            anchors.topMargin: rowPadY
                            anchors.bottomMargin: rowPadY
                            columns: phone ? 1 : 2
                            columnSpacing: gap
                            rowSpacing: Math.max(6, gap * 0.4)

                            QGCLabel {
                                text: qsTr("Maksimum Yaddaş İstifadəsi")
                                font.pixelSize: labelPx
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }

                            FactTextField {
                                fact: _videoSettings.maxVideoSize
                                enabled: _videoSettings.enableStorageLimit.rawValue
                                Layout.fillWidth: root.phone
                                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                                Layout.minimumWidth: 0
                                Layout.alignment: root.phone ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
                            }
                        }
                    }
                }
            }

        } // panelFlow

            Item { width: 1; height: root.sidePad }
        }
    }
}

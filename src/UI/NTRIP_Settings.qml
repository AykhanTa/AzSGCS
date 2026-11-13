import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.GPS.NTRIP

// NTRIP / RTK settings, in the new design: the page header of the setup pages, status cards
// with group box rows, and the new fields, combo boxes, switches and buttons.
SettingsPage {
    id: root

    // The fields, combo boxes, switches, labels and buttons take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    // ---- Data ----
    property var  _ntrip:    QGroundControl.settingsManager.ntripSettings
    property var  _ntripMgr: QGroundControl.ntripManager
    property Fact _enabled:  _ntrip.ntripServerConnectEnabled

    readonly property int  _status:    _ntripMgr ? _ntripMgr.connectionStatus : NTRIPManager.Disconnected
    readonly property var  _stats:     _ntripMgr ? _ntripMgr.connectionStats : null
    readonly property var  _rtcm:      _ntripMgr ? _ntripMgr.rtcmMavlink : null
    readonly property bool _connected: _status === NTRIPManager.Connected

    // Transport-affecting fields are locked while the client is enabled: editing a
    // half-typed host would only make the manager churn through failed connects.
    readonly property bool _isActive:  _enabled.rawValue
    readonly property bool _hasHost:   _ntrip.ntripServerHostAddress.rawValue !== ""

    // ---- Responsive metrics (same idiom as the sibling settings pages) ----
    readonly property bool phone:  ScreenTools.isMobile || width < 720

    readonly property real gap:     AzTheme.px(phone ? 8 : 10)
    readonly property real cardPad: AzTheme.px(16)
    readonly property real ctrlW:   Math.max(150, Math.min(260, width * 0.22))

    readonly property real titlePx: AzTheme.fontPx(phone ? 18 : 20)
    readonly property real descPx:  AzTheme.fontPx(13)
    readonly property real labelPx: AzTheme.fontPx(AzTheme.popupTextSize)
    readonly property real smallPx: AzTheme.fontPx(12)

    // ---- Helpers ----
    function _fmtSize(bytes) {
        if (!bytes) return "0 B"
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB"
        return (bytes / 1048576).toFixed(1) + " MB"
    }

    function _fmtRate(bps) {
        if (!bps) return "0 B/s"
        if (bps < 1024) return bps.toFixed(0) + " B/s"
        return (bps / 1024).toFixed(1) + " KB/s"
    }

    // =====================================================================
    // Reusable row. Self-contained on purpose: an inline component cannot
    // reach the outer file scope, so every metric is derived locally.
    // =====================================================================
    component SettingRow: Rectangle {
        id: rowRoot

        property string label
        property string hint
        default property alias content: rowGrid.data

        readonly property bool _narrow: width < 720
        readonly property real _padX:   AzTheme.px(AzTheme.groupPadding)
        readonly property real _padY:   AzTheme.px(8)
        readonly property real _minH:   AzTheme.px(AzTheme.groupRowHeight + 4)

        Layout.fillWidth: true
        radius: AzTheme.px(AzTheme.groupRadius)
        color: AzTheme.groupFill
        border.width: 1
        border.color: AzTheme.groupBorder
        implicitHeight: Math.max(_minH, rowGrid.implicitHeight + _padY * 2)
        height: implicitHeight

        GridLayout {
            id: rowGrid
            anchors.fill: parent
            anchors.leftMargin: rowRoot._padX
            anchors.rightMargin: rowRoot._padX
            anchors.topMargin: rowRoot._padY
            anchors.bottomMargin: rowRoot._padY
            columns: rowRoot._narrow ? 1 : 2
            columnSpacing: AzTheme.px(10)
            rowSpacing: AzTheme.px(6)

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 2

                QGCLabel {
                    text: rowRoot.label
                    font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                QGCLabel {
                    text: rowRoot.hint
                    visible: rowRoot.hint !== ""
                    color: AzTheme.textSecondary
                    font.pixelSize: AzTheme.fontPx(12)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }
            }
        }
    }

    // ---- Card shell ----
    component Card: Rectangle {
        id: cardRoot

        property string title
        default property alias content: cardLayout.data

        readonly property real _pad: AzTheme.px(16)

        Layout.fillWidth: true
        radius: AzTheme.px(AzTheme.cardRadius)
        border.width: 1
        border.color: AzTheme.cardBorder
        gradient: Gradient {
            GradientStop { position: 0; color: AzTheme.cardGradientStart }
            GradientStop { position: 1; color: AzTheme.cardGradientEnd }
        }
        implicitHeight: cardLayout.implicitHeight + _pad * 2
        height: implicitHeight

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: cardRoot._pad
            spacing: AzTheme.px(8)

            Text {
                text: cardRoot.title
                visible: cardRoot.title !== ""
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.weight: Font.Medium
                font.pixelSize: AzTheme.fontPx(16)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }
    }

    // =====================================================================
    // Header
    // =====================================================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: AzTheme.px(20)
        spacing: AzTheme.px(6)

        Text {
            text: qsTr("NTRIP / RTK")
            color: AzTheme.textCard
            font.family: AzTheme.fontFamily
            font.weight: Font.Medium
            font.pixelSize: root.titlePx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }

        Text {
            text: qsTr("Bu bölmə RTK dəqiqliyi üçün NTRIP kaster bağlantısını və RTCM korreksiya axınını idarə edir.")
            color: AzTheme.textSecondary
            font.family: AzTheme.fontFamily
            font.pixelSize: root.descPx
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.minimumWidth: 0
        }
    }

    // =====================================================================
    // Bağlantı
    // =====================================================================
    Card {
        title: qsTr("Bağlantı")

        Rectangle {
            Layout.fillWidth: true
            radius: AzTheme.px(AzTheme.groupRadius)
            color: AzTheme.groupFill
            border.width: 1
            border.color: AzTheme.groupBorder
            implicitHeight: Math.max(AzTheme.px(AzTheme.groupRowHeight + 4),
                                     statusRow.implicitHeight + root.gap * 2)
            height: implicitHeight

            RowLayout {
                id: statusRow
                anchors.fill: parent
                anchors.leftMargin: AzTheme.px(AzTheme.groupPadding)
                anchors.rightMargin: AzTheme.px(AzTheme.groupPadding)
                spacing: AzTheme.px(10)

                Rectangle {
                    id: statusDot
                    readonly property real _size: AzTheme.px(12)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: statusDot._size
                    Layout.preferredHeight: statusDot._size
                    radius: statusDot._size / 2
                    color: {
                        switch (root._status) {
                        case NTRIPManager.Connected:    return AzTheme.statusGreen
                        case NTRIPManager.Connecting:
                        case NTRIPManager.Reconnecting: return AzTheme.statusOrange
                        case NTRIPManager.Error:        return AzTheme.statusRed
                        default:                        return AzTheme.mutedText
                        }
                    }
                }

                QGCLabel {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root._ntripMgr ? (root._ntripMgr.statusMessage || qsTr("Bağlantı yoxdur"))
                                         : qsTr("Əlçatmazdır")
                    color: AzTheme.textCard
                    font.pixelSize: root.labelPx
                    wrapMode: Text.WordWrap
                }

                QGCButton {
                    Layout.alignment: Qt.AlignVCenter
                    text: {
                        switch (root._status) {
                        case NTRIPManager.Connecting:   return qsTr("Qoşulur…")
                        case NTRIPManager.Reconnecting: return qsTr("Yenidən qoşulur…")
                        case NTRIPManager.Connected:    return qsTr("Ayır")
                        default:                        return qsTr("Qoşul")
                        }
                    }
                    // Connecting stays disabled regardless: the manager is mid-handshake.
                    enabled: root._ntripMgr
                             && root._status !== NTRIPManager.Connecting
                             && (root._isActive || root._hasHost)
                    onClicked: root._enabled.rawValue = !root._isActive
                }
            }
        }

        // ---- Canlı statistika ----
        SettingRow {
            label: qsTr("Mountpoint")
            visible: root._connected && root._ntrip.ntripMountpoint.valueString !== ""

            QGCLabel {
                text: root._ntrip.ntripMountpoint.valueString
                color: AzTheme.textSecondary
                font.pixelSize: root.labelPx
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }

        SettingRow {
            label: qsTr("Alınan mesajlar")
            visible: root._connected && root._stats && root._stats.messagesReceived > 0

            QGCLabel {
                text: root._stats ? root._stats.messagesReceived : ""
                color: AzTheme.textSecondary
                font.pixelSize: root.labelPx
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }

        SettingRow {
            label: qsTr("Alınan məlumat")
            visible: root._connected && root._stats && root._stats.bytesReceived > 0

            QGCLabel {
                text: root._stats ? (root._fmtSize(root._stats.bytesReceived) + "  ("
                                     + root._fmtRate(root._stats.dataRateBytesPerSec) + ")") : ""
                color: AzTheme.textSecondary
                font.pixelSize: root.labelPx
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }

        SettingRow {
            label: qsTr("Təyyarəyə göndərilən")
            visible: root._connected && root._rtcm && root._rtcm.totalBytesSent > 0

            QGCLabel {
                text: root._rtcm ? (root._fmtSize(root._rtcm.totalBytesSent) + "  ("
                                    + root._rtcm.bandwidthKBps.toFixed(1) + " KB/s)") : ""
                color: AzTheme.textSecondary
                font.pixelSize: root.labelPx
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }

        SettingRow {
            label: qsTr("GGA mənbəyi")
            visible: root._connected && root._ntripMgr && root._ntripMgr.ggaSource !== ""

            QGCLabel {
                text: root._ntripMgr ? root._ntripMgr.ggaSource : ""
                color: AzTheme.textSecondary
                font.pixelSize: root.labelPx
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }

        // ---- Xəbərdarlıqlar ----
        QGCLabel {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: root._connected && root._stats && root._stats.dataStale
            text: qsTr("Qoşuludur, lakin son vaxtlar məlumat alınmır.")
            color: AzTheme.statusOrange
            font.pixelSize: root.smallPx
            wrapMode: Text.WordWrap
        }

        QGCLabel {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: root._connected && root._ntripMgr && root._ntripMgr.securityWarning !== ""
            text: root._ntripMgr ? root._ntripMgr.securityWarning : ""
            color: AzTheme.statusOrange
            font.pixelSize: root.smallPx
            wrapMode: Text.WordWrap
        }

        QGCLabel {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: root._status === NTRIPManager.Error && root._ntripMgr
                     && root._ntripMgr.statusMessage !== ""
            text: root._ntripMgr ? root._ntripMgr.statusMessage : ""
            color: AzTheme.statusRed
            font.pixelSize: root.smallPx
            wrapMode: Text.WordWrap
        }
    }

    // =====================================================================
    // Kaster
    // =====================================================================
    Card {
        title: qsTr("Kaster Serveri")

        SettingRow {
            label: qsTr("Host ünvanı")
            enabled: !root._isActive

            FactTextField {
                fact: root._ntrip.ntripServerHostAddress
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }

        SettingRow {
            label: qsTr("Port")
            enabled: !root._isActive

            FactTextField {
                fact: root._ntrip.ntripServerPort
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }

        SettingRow {
            label: qsTr("İstifadəçi adı")
            enabled: !root._isActive

            FactTextField {
                fact: root._ntrip.ntripUsername
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }

        SettingRow {
            id: passwordRow
            label: qsTr("Şifrə")
            enabled: !root._isActive

            property bool showPassword: false

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Math.max(6, ScreenTools.defaultFontPixelWidth * 0.6)

                FactTextField {
                    fact: root._ntrip.ntripPassword
                    echoMode: passwordRow.showPassword ? TextInput.Normal : TextInput.Password
                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                    Layout.fillWidth: root.phone
                    Layout.minimumWidth: 0
                }

                QGCButton {
                    text: passwordRow.showPassword ? qsTr("Gizlə") : qsTr("Göstər")
                    onClicked: passwordRow.showPassword = !passwordRow.showPassword
                }
            }
        }

        SettingRow {
            label: qsTr("TLS şifrələmə")
            hint: qsTr("Bəzi kasterlər üçün tələb olunur (adətən port 2102).")
            enabled: !root._isActive

            FactCheckBoxSlider {
                text: ""
                fact: root._ntrip.ntripUseTls
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }

        SettingRow {
            label: qsTr("Öz-imzalı sertifikatı qəbul et")
            hint: qsTr("Yalnız öz-imzalı zəncir buraxılır; digər bütün TLS xətaları ölümcül qalır.")
            // Only meaningful over TLS.
            enabled: !root._isActive && root._ntrip.ntripUseTls.rawValue

            FactCheckBoxSlider {
                text: ""
                fact: root._ntrip.ntripAllowSelfSignedCerts
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }
    }

    // =====================================================================
    // Mountpoint
    // =====================================================================
    Card {
        title: qsTr("Mountpoint")

        SettingRow {
            label: qsTr("Mountpoint adı")
            hint: qsTr("Boş buraxılsa, TCP üzərindən xam RTCM dinlənilir.")
            enabled: !root._isActive

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Math.max(6, ScreenTools.defaultFontPixelWidth * 0.6)

                FactTextField {
                    fact: root._ntrip.ntripMountpoint
                    Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                    Layout.fillWidth: root.phone
                    Layout.minimumWidth: 0
                }

                QGCButton {
                    text: qsTr("Axtar")
                    enabled: !root._isActive && root._hasHost && root._ntripMgr
                             && root._ntripMgr.sourceTableController.fetchStatus !== NTRIPSourceTableController.InProgress
                    onClicked: root._ntripMgr.fetchMountpoints()
                }
            }
        }

        QGCLabel {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: root._ntripMgr
                     && root._ntripMgr.sourceTableController.fetchStatus === NTRIPSourceTableController.InProgress
            text: qsTr("Mountpoint siyahısı alınır…")
            color: AzTheme.statusOrange
            font.pixelSize: root.smallPx
            wrapMode: Text.WordWrap
        }

        QGCLabel {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: root._ntripMgr
                     && root._ntripMgr.sourceTableController.fetchStatus === NTRIPSourceTableController.Error
            text: root._ntripMgr ? root._ntripMgr.sourceTableController.fetchError : ""
            color: AzTheme.statusRed
            font.pixelSize: root.smallPx
            wrapMode: Text.WordWrap
        }

        NTRIPMountpointList {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: root._ntripMgr && root._ntripMgr.sourceTableController.mountpointModel
                     && root._ntripMgr.sourceTableController.mountpointModel.count > 0
            model: root._ntripMgr ? root._ntripMgr.sourceTableController.mountpointModel : null
            selectedMountpoint: root._ntrip.ntripMountpoint.rawValue
            onMountpointSelected: (mountpoint) => root._ntripMgr.selectMountpoint(mountpoint)
        }
    }

    // =====================================================================
    // GGA (VRS mountpoint-ləri üçün)
    // =====================================================================
    Card {
        title: qsTr("GGA Mövqe Bildirişi")

        SettingRow {
            label: qsTr("Mövqe mənbəyi")
            hint: qsTr("Avto rejim mövcud ən yaxşı mənbəni seçir.")

            FactComboBox {
                fact: root._ntrip.ntripGgaPositionSource
                sizeToContents: true
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }

        SettingRow {
            label: qsTr("Göndərmə intervalı")
            hint: qsTr("VRS mountpoint-ləri adətən 1-10 saniyə tələb edir.")

            FactTextField {
                fact: root._ntrip.ntripGgaIntervalSec
                showUnits: true
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }
    }

    // =====================================================================
    // RTCM filtri
    // =====================================================================
    Card {
        title: qsTr("RTCM Mesaj Filtri")

        SettingRow {
            label: qsTr("Buraxılan mesaj İD-ləri")
            hint: qsTr("Vergüllə ayrılmış siyahı, məsələn 1005,1077,1087. Boş buraxılsa hamısı ötürülür.")

            FactTextField {
                fact: root._ntrip.ntripWhitelist
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }
    }

    // =====================================================================
    // UDP yönləndirmə (çıxış)
    // =====================================================================
    Card {
        title: qsTr("UDP Yönləndirmə")

        SettingRow {
            label: qsTr("RTCM-i UDP ilə yönləndir")
            hint: qsTr("Alınan korreksiyaları başqa tətbiqə ötürür.")

            FactCheckBoxSlider {
                text: ""
                fact: root._ntrip.ntripUdpForwardEnabled
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }

        SettingRow {
            label: qsTr("Hədəf ünvanı")
            enabled: root._ntrip.ntripUdpForwardEnabled.rawValue

            FactTextField {
                fact: root._ntrip.ntripUdpTargetAddress
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }

        SettingRow {
            label: qsTr("Hədəf portu")
            enabled: root._ntrip.ntripUdpForwardEnabled.rawValue

            FactTextField {
                fact: root._ntrip.ntripUdpTargetPort
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }
    }

    // =====================================================================
    // UDP RTCM girişi
    // =====================================================================
    Card {
        title: qsTr("UDP RTCM Girişi")

        SettingRow {
            label: qsTr("UDP RTCM girişini aktivləşdir")
            hint: qsTr("Xarici mənbədən gələn RTCM3 axınını təyyarəyə ötürür.")

            FactCheckBoxSlider {
                text: ""
                fact: root._ntrip.rtcmUdpInputEnabled
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }

        SettingRow {
            label: qsTr("Dinlənilən port")
            enabled: root._ntrip.rtcmUdpInputEnabled.rawValue

            FactTextField {
                fact: root._ntrip.rtcmUdpInputPort
                Layout.preferredWidth: root.phone ? -1 : root.ctrlW
                Layout.fillWidth: root.phone
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: 0
            }
        }

        SettingRow {
            label: qsTr("Məlumatı yoxla")
            hint: qsTr("RTCM kadrlarını CRC ilə yoxlayır və zibil məlumatı atır.")
            enabled: root._ntrip.rtcmUdpInputEnabled.rawValue

            FactCheckBoxSlider {
                text: ""
                fact: root._ntrip.rtcmUdpValidate
                Layout.alignment: root.phone ? Qt.AlignLeft : Qt.AlignRight
            }
        }
    }
}

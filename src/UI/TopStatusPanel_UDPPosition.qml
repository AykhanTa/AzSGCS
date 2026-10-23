import QtQuick

import QGroundControl.Controls

AzPopupFrame {
    id: udpPanel

    panelVisible: false
    title:        qsTr("UDP Xarici Pozisiya")
    cardWidth:    AzTheme.px(440)

    onCloseRequested: panelVisible = false

    readonly property bool   _act:       (typeof externalPositionManager !== "undefined") ? externalPositionManager.extActive   : false
    readonly property double _rawLat:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.extLat      : 0.0
    readonly property double _rawLon:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.extLon      : 0.0
    readonly property real   _rawAlt:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.extAlt      : 0.0
    readonly property real   _rawSpd:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.extSpd      : 0.0
    readonly property int    _rawPkt:    (typeof externalPositionManager !== "undefined") ? externalPositionManager.pktCount    : 0
    readonly property bool   _listening: (typeof externalPositionManager !== "undefined") ? externalPositionManager.isListening : false
    readonly property int    _curPort:   (typeof externalPositionManager !== "undefined") ? externalPositionManager.listenPort  : 15550
    readonly property bool   _sending:   (typeof externalPositionManager !== "undefined") ? externalPositionManager.sendEnabled : false

    readonly property real _textPx: AzTheme.fontPx(AzTheme.popupTextSize)

    property double dispLat: 0.0
    property double dispLon: 0.0
    property real   dispAlt: 0.0
    property real   dispSpd: 0.0
    property int    dispPkt: 0
    property bool   hasData: false

    property string portInput: ""
    property string portError: ""

    property bool actWatcher: _act
    property int  pktWatcher: _rawPkt

    onActWatcherChanged: { if (_act) _refreshDisplay() }
    onPktWatcherChanged: { if (_act) _refreshDisplay() }

    function _refreshDisplay() {
        dispLat = _rawLat
        dispLon = _rawLon
        dispAlt = _rawAlt
        dispSpd = _rawSpd
        dispPkt = _rawPkt
        hasData = true
    }

    function _clearDisplayData() {
        dispLat = 0.0
        dispLon = 0.0
        dispAlt = 0.0
        dispSpd = 0.0
        dispPkt = 0
        hasData = false
    }

    Component.onCompleted: {
        portInput = _curPort.toString()
    }

    function applyPort() {
        var p = parseInt(portInput, 10)
        if (isNaN(p) || p < 1024 || p > 65535) {
            portError = qsTr("Port 1024–65535 arasında olmalıdır")
            return
        }
        portError = ""
        _clearDisplayData()
        if (typeof externalPositionManager !== "undefined") {
            externalPositionManager.startListening(p)
        }
    }

    function toggleListening() {
        if (typeof externalPositionManager === "undefined") return
        if (_listening) {
            _clearDisplayData()
            externalPositionManager.stopListening()
        } else {
            applyPort()
        }
    }

    AzGroup {
        width: udpPanel.contentWidth

        AzInfoRow {
            label:      qsTr("Vəziyyət")
            value:      udpPanel._act ? qsTr("Canlı") : (udpPanel._listening ? qsTr("Gözləyir") : qsTr("Passiv"))
            valueColor: udpPanel._act ? AzTheme.statusGreen : (udpPanel._listening ? AzTheme.statusYellow : AzTheme.statusRed)
        }

        // Port
        Item {
            width:  parent.width
            height: AzTheme.px(AzTheme.groupRowHeight)

            Text {
                anchors.left:           parent.left
                anchors.leftMargin:     AzTheme.px(AzTheme.groupPadding)
                anchors.verticalCenter: parent.verticalCenter
                text:                   qsTr("Port")
                color:                  AzTheme.textCard
                font.family:            AzTheme.fontFamily
                font.weight:            Font.Medium
                font.pixelSize:         udpPanel._textPx
            }

            Row {
                anchors.right:          parent.right
                anchors.rightMargin:    AzTheme.px(AzTheme.groupPadding)
                anchors.verticalCenter: parent.verticalCenter
                spacing:                AzTheme.px(8)

                Rectangle {
                    width:        AzTheme.px(AzTheme.pillWidth)
                    height:       AzTheme.px(AzTheme.pillHeight)
                    radius:       AzTheme.px(8)
                    border.width: 1
                    border.color: portField.activeFocus ? AzTheme.cardHoverBorder : AzTheme.groupBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.pillTop }
                        GradientStop { position: 1; color: AzTheme.pillBottom }
                    }

                    TextInput {
                        id:                  portField
                        anchors.fill:        parent
                        anchors.leftMargin:  AzTheme.px(10)
                        anchors.rightMargin: AzTheme.px(10)
                        verticalAlignment:   Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text:                udpPanel.portInput
                        color:               AzTheme.textCard
                        font.family:         AzTheme.fontFamily
                        font.pixelSize:      udpPanel._textPx
                        inputMethodHints:    Qt.ImhDigitsOnly
                        selectByMouse:       true
                        onTextChanged: { udpPanel.portInput = text; udpPanel.portError = "" }
                        onAccepted: udpPanel.applyPort()
                    }
                }

                AzButton {
                    height:    AzTheme.px(AzTheme.pillHeight)
                    text:      udpPanel._listening ? qsTr("Dayandır") : qsTr("Başlat")
                    danger:    udpPanel._listening
                    onClicked: udpPanel.toggleListening()
                }
            }
        }

        // MAVLink toggle
        Item {
            width:  parent.width
            height: AzTheme.px(AzTheme.groupRowHeight)

            Text {
                anchors.left:           parent.left
                anchors.leftMargin:     AzTheme.px(AzTheme.groupPadding)
                anchors.verticalCenter: parent.verticalCenter
                text:                   qsTr("Avtopilota göndər")
                color:                  AzTheme.textCard
                font.family:            AzTheme.fontFamily
                font.weight:            Font.Medium
                font.pixelSize:         udpPanel._textPx
            }

            AzSwitch {
                anchors.right:          parent.right
                anchors.rightMargin:    AzTheme.px(AzTheme.groupPadding)
                anchors.verticalCenter: parent.verticalCenter
                checked:                udpPanel._sending
                onClicked: {
                    if (typeof externalPositionManager !== "undefined")
                        externalPositionManager.sendEnabled = !udpPanel._sending
                }
            }
        }
    }

    Text {
        visible:        udpPanel.portError !== "" || udpPanel._listening
        width:          udpPanel.contentWidth
        wrapMode:       Text.WordWrap
        text:           udpPanel.portError !== "" ? udpPanel.portError : qsTr("Aktiv port: %1").arg(udpPanel._curPort)
        color:          udpPanel.portError !== "" ? AzTheme.statusRed : AzTheme.statusGreen
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(13)
    }

    AzSectionTitle {
        text: qsTr("Məlumat")
    }

    Text {
        visible:        !udpPanel.hasData
        width:          udpPanel.contentWidth
        text:           udpPanel._listening ? qsTr("Məlumat gözlənilir...") : qsTr("Dinləmə başladılmayıb")
        color:          AzTheme.textSecondary
        font.family:    AzTheme.fontFamily
        font.pixelSize: udpPanel._textPx
    }

    AzGroup {
        width:   udpPanel.contentWidth
        visible: udpPanel.hasData

        AzInfoRow { label: qsTr("Enlik");      value: udpPanel.dispLat.toFixed(6) + " °" }
        AzInfoRow { label: qsTr("Uzunluq");    value: udpPanel.dispLon.toFixed(6) + " °" }
        AzInfoRow { label: qsTr("Hündürlük");  value: udpPanel.dispAlt.toFixed(1) + " m" }
        AzInfoRow {
            label: qsTr("Sürət")
            value: udpPanel.dispSpd.toFixed(1) + " m/s"
            valueColor: {
                var s = udpPanel.dispSpd
                if (s < 3.0)  return AzTheme.statusGreen    // yavaş
                if (s < 10.0) return AzTheme.statusYellow   // orta
                return AzTheme.statusRed                    // sürətli
            }
        }
        AzInfoRow { label: qsTr("Paket sayı"); value: udpPanel.dispPkt.toString() }
    }

    Text {
        width:          udpPanel.contentWidth
        text:           qsTr("Format: JSON  { lat, lon, alt, spd }")
        color:          AzTheme.mutedText
        font.family:    AzTheme.fontFamily
        font.pixelSize: AzTheme.fontPx(12)
    }
}

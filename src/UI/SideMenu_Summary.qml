import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
// import QGroundControl.ScreenTools
// import QGroundControl.Palette



Rectangle {
    id: _summaryRoot
    anchors.fill: parent
    color: "black"

    property var aparatController: null

    // Aparat / parametr vəziyyəti — digər səhifələrdəki "Parametrlər yüklənir" bloku üçün
    readonly property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool _parametersReady: _activeVehicle
                                             && _activeVehicle.parameterManager
                                             && _activeVehicle.parameterManager.parametersReady

    // // -------- responsive metrics --------
    // readonly property bool smallScreen: width < 1200

    // readonly property real sidePadding: Math.max(12, ScreenTools.defaultFontPixelWidth * (smallScreen ? 1.2 : 1.6))
    // readonly property real gridGap:     Math.max(10, ScreenTools.defaultFontPixelWidth * (smallScreen ? 1.2 : 1.6))

    // // Ekran daralanda 2 sütun -> 1 sütuna düşsün, kartlar enli qalsın
    // readonly property real minCardW: smallScreen ? 440 : 520
    // readonly property real maxCardW: 780

    // readonly property real availableW: Math.max(0, width - 2 * sidePadding)
    // readonly property int  columns:    Math.max(1, Math.floor((availableW + gridGap) / (minCardW + gridGap)))
    // readonly property real cardW:      Math.min(maxCardW, Math.floor((availableW - gridGap * (columns - 1)) / columns))

    // readonly property real titleFont:  Math.max(20, ScreenTools.defaultFontPixelHeight * (smallScreen ? 1.35 : 1.25))
    // readonly property real warnH:      Math.max(48, ScreenTools.defaultFontPixelHeight * (smallScreen ? 3.2 : 2.8))

    // // ✅ Kiçik ekranda iç kontent böyüsün (max 1.22)
    // // width 1200 -> 1.00, width 900 -> 1.22 (limit)
    // readonly property real contentScale: {
    //     if (!smallScreen) return 1.0;
    //     var s = 1200 / Math.max(1, width);
    //     return Math.max(1.06, Math.min(1.22, s));
    // }

    // -------- responsive metrics --------
    // Çərçivə səhifəsi ilə eyni eşik — G30/G20 kimi kiçik ekranlarda başlıq yığcamlaşır.
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen

    readonly property bool phone:  width < 700
    readonly property bool tablet: width < 1100
    readonly property bool smallScreen: tablet  // köhnə ad istifadə edən yerlər üçün

    readonly property real sidePadding: Math.max(8,  ScreenTools.defaultFontPixelWidth  * (phone ? 0.9 : tablet ? 1.2 : 1.6))
    readonly property real gridGap:     Math.max(8,  ScreenTools.defaultFontPixelWidth  * (phone ? 0.9 : tablet ? 1.2 : 1.6))

    // Kart minimum eni (telefon üçün daha kiçik)
    readonly property real minCardW: phone ? 280 : tablet ? 360 : 520
    readonly property real maxCardW: 780

    readonly property real availableW: Math.max(0, width - 2 * sidePadding)

    // Telefon: 1 sütun məcburi. Tablet/desktop: avtomatik.
    readonly property int columns: phone ? 1
                                    : Math.max(1, Math.floor((availableW + gridGap) / (minCardW + gridGap)))

    // 1 sütunda kart tam eni doldursun. 2/3 sütunda hesabla.
    readonly property real cardW: (columns === 1)
                                    ? availableW
                                    : Math.min(maxCardW,
                                               Math.floor((availableW - gridGap * (columns - 1)) / columns))

    readonly property real titleFont: Math.max(18, ScreenTools.defaultFontPixelHeight * (phone ? 1.20 : tablet ? 1.30 : 1.25))

    // Kiçik ekranda iç kontent bir az böyüsün (telefon/tablet)
    readonly property real contentScale: {
        if (!tablet) return 1.0;
        var base = phone ? 800 : 1200;
        var s = base / Math.max(1, width);
        return Math.max(1.06, Math.min(1.22, s));
    }


    function capitalizeWords(sentence) {
        return sentence.replace(/(?:^|\s)\S/g, function(a) { return a.toUpperCase(); });
    }

    // -------------------- BLOCK BACKGROUND MAP INPUT --------------------
    // Summary üstündə scroll/pinch edəndə arxadakı xəritəyə getməsin
    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    WheelHandler {
        // bütün Summary sahəsində wheel-i tut
        target: _summaryRoot
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: function(w) {
            // 1) mütləq accepted et ki, event arxaya keçməsin
            w.accepted = true

            // 2) wheel-i Summary Flickable scroll-a çevir
            if (!flick) return

            var step = 0
            // touchpad: pixelDelta daha düzgündür
            if (w.pixelDelta && w.pixelDelta.y !== 0) {
                step = w.pixelDelta.y
            } else {
                // mouse wheel: angleDelta adətən 120 olur -> ~40px addım yaxşıdır
                step = w.angleDelta.y / 3
            }

            var maxY = Math.max(0, flick.contentHeight - flick.height)
            flick.contentY = _clamp(flick.contentY - step, 0, maxY)
        }
    }

    // pinch (2 barmaq zoom) də xəritəyə getməsin
    PinchHandler {
        // Pinch jestini sadəcə “tut”, UI-ni böyütmə/kiçiltmə/daşıma ETMƏ
        target: null

        acceptedDevices: PointerDevice.TouchScreen

        // təhlükəsizlik üçün: scale/rotation kilidlə (target null olsa da problem çıxmaz)
        minimumScale: 1
        maximumScale: 1
        minimumRotation: 0
        maximumRotation: 0

        // (əgər versiyada varsa) jesti mütləq özünə götürsün
        grabPermissions: PointerHandler.CanTakeOverFromAnything
    }
    function prettyTitle(name) {
        var n = (name || "").toUpperCase()

        if (n.indexOf("AIRFRAME") !== -1)      return qsTr("Frame")
        if (n.indexOf("SENSORS") !== -1 ||
            n.indexOf("SENSOR") !== -1)        return qsTr("Uçuşa Hazırlıq")
        if (n.indexOf("RADIO") !== -1)         return qsTr("Radio")
        if (n.indexOf("FLIGHT") !== -1)        return qsTr("Uçuş Rejimləri")
        if (n.indexOf("POWER") !== -1)         return qsTr("Enerji")
        if (n.indexOf("SAFETY") !== -1)        return qsTr("Təhlükəsizlik")
        if (n.indexOf("MOTOR") !== -1 ||
            n.indexOf("ACTUATOR") !== -1)      return qsTr("Aktuatorlar")
        if (n.indexOf("PARAM") !== -1)         return qsTr("Parametrlər")

        return capitalizeWords(name)
    }


    function menuIdxFromComponentName(name) {
        var n = (name || "").toUpperCase()

        if (n.indexOf("SUMMARY") !== -1) return 0

        if (n.indexOf("AIRFRAME") !== -1 || n.indexOf("FRAME") !== -1) return 1
        if (n.indexOf("RADIO") !== -1) return 2
        if (n.indexOf("JOYSTICK") !== -1) return 3

        if ((n.indexOf("FLIGHT") !== -1 && n.indexOf("MODE") !== -1) || n.indexOf("FLIGHTMODES") !== -1) return 4
        if (n.indexOf("SENSOR") !== -1) return 5

        if (n.indexOf("POWER") !== -1 || n.indexOf("ENERGY") !== -1) return 6
        if (n.indexOf("ACTUATOR") !== -1 || n.indexOf("MOTOR") !== -1) return 7
        if (n.indexOf("SAFETY") !== -1) return 8

        if (n.indexOf("PID") !== -1 || n.indexOf("TUNING") !== -1) return 9
        if (n.indexOf("PARAM") !== -1) return 10
        if (n.indexOf("FIRMWARE") !== -1) return 11

        return 0
    }

    function goToComponent(comp) {
        if (!comp) return

        var idx = menuIdxFromComponentName(comp.name)

        if (aparatController && typeof aparatController.openMenuByIdx === "function") {
            aparatController.openMenuByIdx(idx)
        } else {
            console.log("Summary: aparatController yoxdur və ya openMenuByIdx yoxdur")
        }
    }


    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }


    // -------- Scroll content --------
    QGCFlickable {
        id: flick
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        clip: true
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + sidePadding

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: contentColumn
            width: parent.width
            spacing: 0

            // -------- Header (məzmunla birlikdə sürüşür) --------
            Column {
                id: headerArea
                // Başlıq artıq scroll məzmununun bir parçasıdır: aşağı sürüşdürəndə
                // Çərçivə səhifəsindəki kimi yuxarı çıxır və yer tutmur.
                x: sidePadding
                width: Math.max(0, contentColumn.width - sidePadding * 2)
                bottomPadding: Math.max(8, ScreenTools.defaultFontPixelHeight * 0.8)
                spacing: Math.max(6, ScreenTools.defaultFontPixelHeight * (_summaryRoot._compact ? 0.4 : 0.6))

                Text {
                    text: qsTr("Təyyarənin Konfiqurasiyası Xülasəsi")
                    color: "white"
                    font.pixelSize: _summaryRoot._compact ? 21 : 26
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                // Subtitle — səhifənin məqsədini izah edir (digər səhifələrlə eyni üslub)
                Text {
                    text: qsTr("Təyyarənizin bütün komponentlərinin quraşdırma vəziyyətinə buradan nəzər salın; hər blok müvafiq konfiqurasiya səhifəsinə keçid edir.")
                    color: "#E8E8E8"
                    font.pixelSize: _summaryRoot._compact ? 13 : 16
                    font.bold: false
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // subtitle YOX (sənin istədiyin kimi)

                Rectangle {
                    id: warningBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    radius: 10
                    color: "#B3947272"
                    border.width: 1
                    border.color: "#B3FF0000"

                    readonly property real padX: Math.max(10, ScreenTools.defaultFontPixelWidth * 1.2)
                    readonly property real padY: Math.max(8,  ScreenTools.defaultFontPixelHeight * 0.6)
                    readonly property real minH: Math.max(46, ScreenTools.defaultFontPixelHeight * 2.6)

                    // ✅ hündürlük mətinə görə böyüsün, min hündürlük də olsun
                    height: Math.max(minH, warnText.implicitHeight + padY * 2)

                    readonly property bool setupComplete: QGroundControl.multiVehicleManager.activeVehicle ?
                        QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin.setupComplete : false

                    // Yalnız aparat qoşulub, parametrlər hazırdır VƏ hələ də tamamlanmamış
                    // quraşdırma (qırmızı işıqlı komponent) qalıbsa göstər. Hər şey hazırdırsa
                    // (bütün işıqlar yaşıl) və ya aparat yoxdursa — gizli.
                    visible: _summaryRoot._parametersReady && !setupComplete

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: warningBar.padX
                        anchors.rightMargin: warningBar.padX
                        anchors.topMargin: warningBar.padY
                        anchors.bottomMargin: warningBar.padY
                        spacing: Math.max(10, ScreenTools.defaultFontPixelWidth)

                        Image {
                            source: "qrc:/res/AZSHIELD_ICON/bx_error.svg"
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Layout.alignment: Qt.AlignVCenter
                            fillMode: Image.PreserveAspectFit
                        }

                        QGCLabel {
                            id: warnText
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap

                            // ✅ sağa/sola daşma olmasın
                            elide: Text.ElideRight

                            // center yazanda bəzi ölçülərdə pis görünür, səliqəli üçün Left daha yaxşıdır
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter

                            color: warningBar.setupComplete ? qgcPal.text : qgcPal.warningText
                            font.bold: true
                            font.pixelSize: Math.max(12, ScreenTools.defaultFontPixelHeight * 0.85)

                            text: warningBar.setupComplete ?
                                qsTr("Aşağıda təyyarəniz üçün parametrlərin xülasəsini tapa bilərsiniz. Solda hər bir komponent üçün quraşdırma menyuları var.") :
                                qsTr("XƏBƏRDARLIQ: Təyyarəniz uçuşdan əvvəl quraşdırma tələb edir. Zəhmət olmasa, soldakı menyudan istifadə edərək qırmızı ilə işarələnmiş elementləri həll edin.")
                        }
                    }
                }


            }

            // -------- Parametrlər yüklənir (digər səhifələrlə eyni üslub) --------
            // Aparat qoşulmayıb və ya parametrlər hələ hazır deyil.
            Item {
                width: parent.width
                visible: !_summaryRoot._parametersReady
                height: visible ? (220 + sidePadding) : 0

                Rectangle {
                    x: sidePadding
                    width: parent.width - 2 * sidePadding
                    height: 220
                    radius: 16
                    color: "#3D3B3B"
                    border.width: 1
                    border.color: "#9D9D9D"

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 2 * sidePadding
                        text: _summaryRoot._activeVehicle
                              ? qsTr("Parametrlər yüklənir...\nAvtopilot bağlantısını gözləyin")
                              : qsTr("Aktiv aparat yoxdur.\nQoşulduqdan sonra xülasə görünəcək.")
                        color: "#FFFFFF"
                        font.pixelSize: Math.max(16, ScreenTools.defaultFontPixelHeight * 0.95)
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Flow {
                id: summaryFlow
                x: sidePadding
                width: parent.width - 2 * sidePadding
                spacing: gridGap
                height: childrenRect.height
                // Kartlar yalnız parametrlər hazır olanda görünsün (yarımçıq render olmasın)
                visible: _summaryRoot._parametersReady

                Repeater {
                    model: (_summaryRoot._parametersReady &&
                            QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin) ?
                        QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin.vehicleComponents : []

                    delegate: Rectangle {
                        //width: _summaryRoot.cardW
                        width: Math.min(_summaryRoot.cardW, summaryFlow.width)

                        // ✅ kiçik ekranda kartın hündürlüyünü bir az artır (oxunaqlılıq)
                        height: Math.max(230, Math.min(_summaryRoot.smallScreen ? 300 : 220,
                                                      _summaryRoot.height * (_summaryRoot.smallScreen ? 0.48 : 0.36)))

                        color: "#3C3838"
                        radius: 16
                        border.width: 1
                        border.color: "#9D9D9D"
                        visible: modelData && modelData.summaryQmlSource && modelData.summaryQmlSource.toString() !== ""

                        readonly property real titleH: Math.max(46, ScreenTools.defaultFontPixelHeight * (_summaryRoot.smallScreen ? 2.7 : 2.4))

                        QGCButton {
                            id: titleBar
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: titleH
                            text:prettyTitle(modelData.name)
                            font.bold: true
                            // ✅ kiçik ekranda title da böyüsün
                            font.pixelSize: Math.max(17, ScreenTools.defaultFontPixelHeight * (_summaryRoot.smallScreen ? 1.2 : 1.0))

                            background: Rectangle {
                                anchors.fill: parent
                                color: "#333131"
                                radius: 13
                                border.width: 1
                                border.color: "#888888"
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: Math.max(10, ScreenTools.defaultFontPixelWidth)
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(12, ScreenTools.defaultFontPixelWidth * 1.6)
                                height: width
                                radius: width / 2
                                color: modelData.setupComplete ? "#00d932" : "red"
                                visible: modelData.requiresSetup && modelData.setupSource !== ""
                            }

                            onClicked: _summaryRoot.goToComponent(modelData)

                        }

                        Rectangle {
                            id: bodyRect
                            anchors.top: titleBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            color: "transparent"
                            clip: true

                            readonly property real innerPad: Math.max(8, Math.min(18, parent.width * 0.04))

                            // ✅ scale üçün kompensasiya: content area ölçüsünü scale-ə bölürük
                            Item {
                                id: contentHost
                                x: bodyRect.innerPad
                                y: bodyRect.innerPad

                                width:  Math.max(0, bodyRect.width  - 2 * bodyRect.innerPad) / _summaryRoot.contentScale
                                height: Math.max(0, bodyRect.height - 2 * bodyRect.innerPad) / _summaryRoot.contentScale

                                clip: true
                                transformOrigin: Item.TopLeft
                                scale: _summaryRoot.contentScale

                                // Loader {
                                //     id: compLoader
                                //     anchors.fill: parent
                                //     source: modelData.summaryQmlSource
                                //     property var vehicleComponent: modelData
                                // }
                                Loader {
                                    id: compLoader
                                    anchors.fill: parent
                                    source: modelData.summaryQmlSource
                                    property var vehicleComponent: modelData

                                    onStatusChanged: {
                                        if (status === Loader.Error) {
                                            console.warn("Summary loader ERROR:", source, errorString)
                                        }
                                    }
                                }

                            }
                        }

                    }
                }
            }

            Item { width: 1; height: sidePadding }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
// import QGroundControl.ScreenTools
// import QGroundControl.Palette



// Vehicle setup summary, in the new design: one status card per component with its
// setup state, on the vehicle setup page's dark background.
Rectangle {
    id: _summaryRoot
    anchors.fill: parent
    color: "transparent"

    property var aparatController: null

    // The component summaries' labels and rows take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

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

    readonly property real sidePadding: AzTheme.px(phone ? 12 : 20)
    readonly property real gridGap:     AzTheme.px(phone ? 10 : 16)

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
                topPadding: AzTheme.px(20)
                bottomPadding: AzTheme.px(16)
                spacing: AzTheme.px(6)

                Text {
                    width: parent.width
                    text: qsTr("Təyyarənin Konfiqurasiyası Xülasəsi")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(_summaryRoot._compact ? 18 : 20)
                    wrapMode: Text.WordWrap
                }

                // Subtitle — səhifənin məqsədini izah edir (digər səhifələrlə eyni üslub)
                Text {
                    text: qsTr("Təyyarənizin bütün komponentlərinin quraşdırma vəziyyətinə buradan nəzər salın; hər blok müvafiq konfiqurasiya səhifəsinə keçid edir.")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(13)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Item { width: 1; height: AzTheme.px(4) }

                // subtitle YOX (sənin istədiyin kimi)

                Rectangle {
                    id: warningBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    // A red-tinted group box
                    radius: AzTheme.px(AzTheme.groupRadius)
                    color: Qt.rgba(1, 52 / 255, 67 / 255, 0.10)
                    border.width: 1
                    border.color: Qt.rgba(1, 52 / 255, 67 / 255, 0.55)

                    readonly property real padX: AzTheme.px(16)
                    readonly property real padY: AzTheme.px(12)
                    readonly property real minH: AzTheme.px(52)

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

                        QGCColoredImage {
                            source: "qrc:/res/AZSHIELD_ICON/bx_error.svg"
                            Layout.preferredWidth: AzTheme.px(22)
                            Layout.preferredHeight: AzTheme.px(22)
                            Layout.alignment: Qt.AlignVCenter
                            sourceSize.height: AzTheme.px(22)
                            fillMode: Image.PreserveAspectFit
                            color: AzTheme.statusRed
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

                            color: AzTheme.textCard
                            font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)

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
                height: visible ? (emptyCard.height + sidePadding) : 0

                // A status card with the vehicle state and what to expect
                Rectangle {
                    id: emptyCard
                    x: sidePadding
                    width: parent.width - 2 * sidePadding
                    height: AzTheme.px(200)
                    radius: AzTheme.px(AzTheme.cardRadius)
                    border.width: 1
                    border.color: AzTheme.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0; color: AzTheme.cardGradientStart }
                        GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 2 * sidePadding
                        spacing: AzTheme.px(10)

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: AzTheme.px(12)
                            height: width
                            radius: width / 2
                            color: _summaryRoot._activeVehicle ? AzTheme.statusOrange : AzTheme.mutedText
                        }

                        Text {
                            width: parent.width
                            text: _summaryRoot._activeVehicle ? qsTr("Parametrlər yüklənir...")
                                                              : qsTr("Aktiv aparat yoxdur")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(17)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            width: parent.width
                            text: _summaryRoot._activeVehicle ? qsTr("Avtopilot bağlantısını gözləyin")
                                                              : qsTr("Qoşulduqdan sonra xülasə görünəcək.")
                            color: AzTheme.textSecondary
                            font.family: AzTheme.fontFamily
                            font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
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

                        // The status card: linear-gradient(145deg, #25272A, #181B1E), 1 px #353A3F,
                        // radius 14; its outline brightens while the header is hovered.
                        id: componentCard
                        color: "transparent"
                        visible: modelData && modelData.summaryQmlSource && modelData.summaryQmlSource.toString() !== ""

                        readonly property real titleH: AzTheme.px(52)
                        readonly property bool _needsSetup: modelData.requiresSetup && modelData.setupSource !== ""

                        AzGradientRect {
                            anchors.fill:  parent
                            angle:         AzTheme.cardGradientAngle
                            startColor:    AzTheme.cardGradientStart
                            startPosition: AzTheme.cardGradientStartPos
                            endColor:      AzTheme.cardGradientEnd
                            endPosition:   AzTheme.cardGradientEndPos
                            radius:        AzTheme.px(AzTheme.cardRadius)
                            borderColor:   titleMouse.containsMouse ? AzTheme.cardHoverBorder : AzTheme.cardBorder
                            borderWidth:   1
                        }

                        // Title, setup state and a chevron: opens the component's page
                        Item {
                            id: titleBar
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: titleH

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: AzTheme.px(18)
                                anchors.right: stateRow.left
                                anchors.rightMargin: AzTheme.px(10)
                                anchors.verticalCenter: parent.verticalCenter
                                text: prettyTitle(modelData.name)
                                color: AzTheme.textCard
                                font.family: AzTheme.fontFamily
                                font.weight: Font.Medium
                                font.pixelSize: AzTheme.fontPx(16)
                                elide: Text.ElideRight
                            }

                            Row {
                                id: stateRow
                                anchors.right: parent.right
                                anchors.rightMargin: AzTheme.px(14)
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: AzTheme.px(10)

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: AzTheme.px(6)
                                    visible: componentCard._needsSetup

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(6, AzTheme.px(8))
                                        height: width
                                        radius: width / 2
                                        color: modelData.setupComplete ? AzTheme.statusGreen : AzTheme.statusRed
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.setupComplete ? qsTr("Hazırdır") : qsTr("Quraşdırılmayıb")
                                        color: AzTheme.textSecondary
                                        font.family: AzTheme.fontFamily
                                        font.pixelSize: AzTheme.fontPx(12)
                                    }
                                }

                                QGCColoredImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: AzTheme.px(16)
                                    height: width
                                    sourceSize.height: height
                                    rotation: -90
                                    fillMode: Image.PreserveAspectFit
                                    source: "qrc:/res/AZSHIELD_ICON/v2/popup_chevron.svg"
                                    color: titleMouse.containsMouse ? AzTheme.textCard : AzTheme.textSecondary
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 1
                                anchors.rightMargin: 1
                                anchors.bottom: parent.bottom
                                height: 1
                                color: AzTheme.groupBorder
                            }

                            MouseArea {
                                id: titleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _summaryRoot.goToComponent(modelData)
                            }
                        }

                        Rectangle {
                            id: bodyRect
                            anchors.top: titleBar.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            color: "transparent"
                            clip: true

                            readonly property real innerPad: AzTheme.px(16)

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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QGroundControl

Item {
    id: root
    anchors.fill: parent
    z: 100

    // TopStatusPanel.qml loader-dən gələnlər
    property Item anchorItem: null
    property Item topPanelItem: null
    property var  hostPanel: null
    property var  activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property var statusPanel: null   // TopStatusPanel-in özü
    property real _leftInset: 0


    // ölçü parametrləri
    property int  preferredW: 376
    property int  preferredMaxH: 655
    property int  margin: 12
    property int  gap: 12          // ✅ TopStatusPanel-dən aşağı məsafə

    // list ölçüləri (delegate)
    property int itemH: 44
    property int listMargins: 12

    // Top panel-in alt xətti
    property real _topInset: 0

    function close() {
        // Loader-i bağla
        var hp = hostPanel || statusPanel
        if (hp && hp.closeFlightModePopup) {
            hp.closeFlightModePopup()
        } else if (typeof topStatusPanel !== "undefined" && topStatusPanel) {
            topStatusPanel.flightModePopupVisible = false
        }
    }



    function _calcLeftInset(win) {
        if (!win) return 0

        // 1) Əgər sən özün side menu id-ni ötürmək istəsən (opsional)
        // property Item leftAvoidItem: null
        // if (leftAvoidItem && leftAvoidItem.visible) return leftAvoidItem.x + leftAvoidItem.width

        // 2) Auto-detect: x≈0-da duran, hündür, enli görünən item-ları tap
        var inset = 0
        var ch = win.children
        for (var i = 0; i < ch.length; i++) {
            var c = ch[i]
            if (!c || !c.visible) continue
            if (c === root || c === panel || c === dim) continue

            // solda dayanır?
            if (c.x > 2) continue

            // çox kiçikləri keç (icon/button kimi)
            if (c.width < 40) continue

            // side menu adətən ekranın yarısından çox hündür olur
            if (c.height < win.height * 0.4) continue

            // ən böyük eni götür
            inset = Math.max(inset, c.x + c.width)
        }
        return inset
    }

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(v, hi)) }

    function _wantedHeight(availH) {
        // List kontenti (flightModeModel boşdursa emptyText hündürlüyünü götür)
        var listContent = (flightModeModel.count > 0) ? modeList.contentHeight : (emptyText.implicitHeight + 10)

        // Panelin real kontent hündürlüyü:
        // titleBar + listMargins*2 + listContent
        var contentH = titleBar.height + (listMargins * 2) + listContent

        // max limitlər
        var maxH = Math.min(preferredMaxH, availH)
        return clamp(contentH, titleBar.height + listMargins * 2 + itemH, maxH)
    }

    function reposition() {
        var win = root.parent
        if (!win) return

        // 1) TopStatusPanel bottom (koordinat)
        var topBottom = 0
        if (topPanelItem) {
            var tb = topPanelItem.mapToItem(win, 0, topPanelItem.height)
            topBottom = tb.y
        }
        _topInset = topBottom

        // 2) anchor bottom və center
        var ay = topBottom
        var acx = margin
        if (anchorItem) {
            var pBottom = anchorItem.mapToItem(win, 0, anchorItem.height)
            ay = pBottom.y

            var pCenter = anchorItem.mapToItem(win, anchorItem.width / 2, anchorItem.height)
            acx = pCenter.x
        }

        // ✅ Sol side menu üçün inset hesabla
        _leftInset = _calcLeftInset(win)

        // sol sərhəd: side menu sonu + margin
        var leftBound = Math.max(margin, _leftInset + margin)

        // 3) Panel width: əvvəl preferredW, sonra ekrana sığdır (leftBound nəzərə alınır)
        var maxW = win.width - leftBound - margin
        panel.width = Math.min(preferredW, maxW)
        panel.width = Math.max(240, panel.width)   // min width
        if (panel.width > maxW) panel.width = Math.max(180, maxW) // çox balaca ekranda məcburi

        // 4) X: anchor center - panel/2, amma leftBound-dan sola keçməsin
        var x = acx - panel.width / 2
        x = clamp(x, leftBound, win.width - panel.width - margin)
        panel.x = x


        // 5) Y (TopStatusPanel-in altından + gap)
        var yFromAnchor = ay + gap
        var yFromTop    = topBottom + gap
        panel.y = Math.max(yFromAnchor, yFromTop)

        // 6) Height (kontentə görə, amma ekrana sığacaq)
        var availH = win.height - panel.y - margin
        panel.height = _wantedHeight(availH)
    }

    // ölçü dəyişəndə yenilə
    onWidthChanged:  Qt.callLater(reposition)
    onHeightChanged: Qt.callLater(reposition)
    onAnchorItemChanged: Qt.callLater(reposition)
    onTopPanelItemChanged: Qt.callLater(reposition)

    Component.onCompleted: {
        updateFlightModes()
        Qt.callLater(reposition)
    }

    // model və list ölçüsü dəyişəndə panel height yenilənsin (boş sahə qalmasın)
    ListModel {
        id: flightModeModel
        onCountChanged: Qt.callLater(reposition)
    }

    // ===================== Dim area (yalnız TopStatusPanel-dən aşağı) =====================
    Rectangle {
        id: dim
        x: 0
        y: root._topInset
        width: parent.width
        height: Math.max(0, parent.height - y)
        color: "#00000080"
    }

    // Panel açıq olduqda arxadakı xəritəyə heç bir mouse hadisəsi keçməməlidir
    // (sağ klik xəritənin kontekst menyusunu açırdı, çarx isə xəritəni zoom edirdi).
    MouseArea {
        anchors.fill: dim
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        preventStealing: true
        onWheel: (wheel) => { wheel.accepted = true }
        onPressed: (mouse) => { mouse.accepted = true }
        onReleased: (mouse) => { mouse.accepted = true }
        onClicked: (mouse) => {
            mouse.accepted = true
            if (mouse.button === Qt.LeftButton) {
                root.close()
            }
        }
    }

    // ===================== PANEL =====================
    Rectangle {
        id: panel
        color: "#2A2A2A"
        radius: 12
        border.width: 1
        border.color: "#6E6E6E"
        z: 101
        clip: true

        // Panelin özündə də hadisələr arxaya keçməsin
        MouseArea {
            id: panelMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            preventStealing: true
            onWheel: (wheel) => { wheel.accepted = true }
            onPressed: (mouse) => { mouse.accepted = true }
            onReleased: (mouse) => { mouse.accepted = true }
            onClicked: (mouse) => { mouse.accepted = true }
        }

        Item {
            id: titleBar
            width: parent.width
            height: 44
            anchors.top: parent.top

            Text {
                anchors.centerIn: parent
                text: qsTr("Uçuş Rejimi")
                color: "white"
                font.pixelSize: 15
                font.bold: true
            }

            // Tənzimləmələr — Batareya panelindəki ilə eyni məntiq
            Rectangle {
                id: settingsButton
                width: 28; height: 28
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: 10
                color: settingsMouse.containsMouse ? "#4A4848" : "transparent"

                Behavior on color { ColorAnimation { duration: 110 } }

                Image {
                    source: "qrc:/res/AZSHIELD_ICON/TopStatusPanel_Settings.svg"
                    width: 18; height: 18
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        const loaderExists = (typeof settingsLoader !== "undefined") && settingsLoader !== null
                        if (!loaderExists) return

                        var a = root.anchorItem
                        var t = root.topPanelItem
                        var src = "qrc:/qml/QGroundControl/UI/TopStatusPanel_UcusRejimi_Settings.qml"

                        // Batareyada olduğu kimi: tənzimləmə paneli açılanda
                        // rejim siyahısı bağlanmalıdır, əks halda üst-üstə düşür.
                        Qt.callLater(function() { root.close() })

                        if (typeof settingsLoader.setSource === "function") {
                            settingsLoader.setSource(src, {
                                anchorItem: a,
                                topPanelItem: t
                            })
                        } else {
                            settingsLoader.source = src
                            Qt.callLater(function() {
                                if (!settingsLoader.item) return
                                settingsLoader.item.anchorItem = a
                                settingsLoader.item.topPanelItem = t
                                if (settingsLoader.item.hasOwnProperty("reposition"))
                                    settingsLoader.item.reposition()
                            })
                        }
                    }
                }
            }

            Rectangle {
                id: closeButton
                width: 28; height: 28
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right; anchors.rightMargin: 10
                color: closeMouse.containsMouse ? "#4A4848" : "transparent"

                Behavior on color { ColorAnimation { duration: 110 } }

                Image {
                    source: "qrc:/res/AZSHIELD_ICON/TopStatusPanel_Cixis.svg"
                    width: 18; height: 18
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            // Başlığı siyahıdan ayıran xətt
            Rectangle {
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin:  listMargins
                anchors.rightMargin: listMargins
                height: 1
                color: "#4A4A4A"
            }
        }

        ListView {
            id: modeList
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: listMargins

            model: flightModeModel
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }

            onContentHeightChanged: Qt.callLater(reposition)

            delegate: Rectangle {
                id: modeItem
                width: modeList.width
                height: root.itemH
                radius: 8

                property bool hovered: false
                readonly property bool isCurrent: root.activeVehicle && root.activeVehicle.flightMode === model.label

                color: hovered ? "#4A4848" : "#3D3B3B"
                border.width: 1
                border.color: isCurrent ? "#00C853" : "#4A4A4A"

                Behavior on color { ColorAnimation { duration: 110 } }

                // Hazırkı rejimi / hover-i bildirən sol kənar
                Rectangle {
                    anchors.left:           parent.left
                    anchors.leftMargin:     2
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  3
                    height:                 parent.height * 0.6
                    radius:                 1.5
                    color:                  "#00C853"
                    visible:                modeItem.isCurrent || modeItem.hovered
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered:  modeItem.hovered = true
                    onExited:   modeItem.hovered = false

                    onClicked: {
                        var vehicle = root.activeVehicle
                        if (!vehicle) return

                        if (model.label === "Takeoff") {
                            if (!vehicle.takeoffVehicleSupported &&
                                !vehicle.guidedTakeoffSupported &&
                                !vehicle.startTakeoff) {
                                console.warn("Bu təyyarə üçün Takeoff əmri dəstəklənmir")
                                return
                            }

                            if (vehicle.guidedTakeoffSupported && vehicle.guidedModeTakeoff) {
                                var targetAlt = 10
                                if (vehicle.minimumTakeoffAltitudeMeters) {
                                    targetAlt = vehicle.minimumTakeoffAltitudeMeters()
                                }
                                vehicle.guidedModeTakeoff(targetAlt)
                            } else if (vehicle.startTakeoff) {
                                vehicle.startTakeoff()
                            } else {
                                console.warn("Vehicle üzərində guidedModeTakeoff / startTakeoff tapılmadı")
                            }
                            return
                        }

                        if (!vehicle.flightModeSetAvailable) return
                        vehicle.flightMode = model.label
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        text: model.label
                        color: "white"
                        font.bold: modeItem.isCurrent
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                    }
                }
            }
        }

        Text {
            id: emptyText
            anchors.centerIn: parent
            text: qsTr("Uçuş rejimi mövcud deyil")
            color: "#AAAAAA"
            font.pixelSize: 14
            visible: flightModeModel.count === 0
        }
    }

    function updateFlightModes() {
        flightModeModel.clear()

        var vehicle = root.activeVehicle
        if (!vehicle) {
            Qt.callLater(reposition)
            return
        }

        var modes = vehicle.flightModes
        if (!modes || modes.length === 0) {
            Qt.callLater(reposition)
            return
        }

        for (var i = 0; i < modes.length; i++) {
            flightModeModel.append({ label: modes[i] })
        }
        flightModeModel.append({ label: "Takeoff" })

        Qt.callLater(reposition)
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) {
            root.activeVehicle = activeVehicle
            updateFlightModes()
        }
    }

    Connections {
        target: root.activeVehicle
        function onFlightModesChanged() {
            updateFlightModes()
        }
    }
}

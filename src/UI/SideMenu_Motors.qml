import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.AutoPilotPlugins.PX4 1.0

// Actuators, in the new design: the vehicle setup page header, status cards for the
// mixer, the geometry, the test and the outputs, a pill tab bar for the outputs, and the
// new fields, sliders and switches.
Rectangle {
    id: actuatorPage
    anchors.fill: parent
    color: "transparent"

    // The fields, combo boxes, sliders, tabs and buttons take the new design's look
    // (see QGCLabel._az).
    readonly property bool azInputStyle: true

    property bool parametersReady: globals.activeVehicle
                                   && globals.activeVehicle.parameterManager
                                   && globals.activeVehicle.parameterManager.parametersReady

    property var  actuators: (globals.activeVehicle && globals.activeVehicle.actuators) ? globals.activeVehicle.actuators : null
    property bool _showAdvanced: true

    readonly property real _m:       AzTheme.px(_compact ? 12 : 16)
    readonly property real _side:    AzTheme.px(_compact ? 12 : 20)
    readonly property real _margins: AzTheme.px(14)
    readonly property real _cardPad: AzTheme.px(_compact ? 14 : 18)

    // Breakpoint: kiçik ekranda alt-alta, böyükdə yan-yana
    readonly property bool _twoCols: width >= 1200

    // Çərçivə səhifəsi ilə eyni eşik — kiçik ekranlarda başlıq yığcamlaşır.
    readonly property bool _compact: (width < 1200) || (height < 820) || ScreenTools.isShortScreen

    function _popupParent() {
        return (typeof mainWindow !== "undefined") ? mainWindow : actuatorPage
    }

    function openMotorAssignConfirm() {
        var d = motorAssignmentConfirmDlgComponent.createObject(_popupParent())
        d.open()
    }

    function openMotorAssignFailure() {
        var d = motorAssignmentFailureDlgComponent.createObject(_popupParent())
        d.open()
    }

    // (istəsən saxla) altdakı map-a klik keçməsin
    MouseArea {
        anchors.fill: parent
        z: 1
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
    }
    WheelHandler {
        // wheel harada olsa qəbul elə – map-a keçməsin
        onWheel: function(w) {
            w.accepted = true

            // vFlick body Loader/Component daxilindədir; bu scope-dan görünməyə bilər
            if (typeof vFlick === "undefined" || !vFlick) return

            // kontent scroll olmursa belə event qəbul olunacaq (map zoom olmayacaq)
            var maxY = Math.max(0, vFlick.contentHeight - vFlick.height)
            if (maxY <= 0) return

            // trackpad üçün pixelDelta, mouse üçün angleDelta
            var dy = 0
            if (w.pixelDelta && w.pixelDelta.y !== 0) {
                dy = w.pixelDelta.y
            } else if (w.angleDelta && w.angleDelta.y !== 0) {
                dy = (w.angleDelta.y / 120) * (ScreenTools.defaultFontPixelHeight * 3)
            }

            if (dy === 0) return

            // dy pozitivdirsə yuxarı scroll, negativdirsə aşağı scroll
            vFlick.contentY = Math.max(0, Math.min(vFlick.contentY - dy, maxY))
        }
    }


    // Səhifənin yeganə scroll sahəsi. Başlıq da onun məzmunudur, ona görə
    // aşağı sürüşdürəndə Çərçivə səhifəsindəki kimi yuxarı çıxır və yer tutmur.
    QGCFlickable {
        id: vFlick
        z: 2
        anchors.fill: parent
        anchors.leftMargin: _side
        anchors.rightMargin: _side
        anchors.topMargin: 0
        clip: true

        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        // ✅ interaktiv control-lar üstündə drag edəndə belə scroll başlasın
        pressDelay: 150

        contentWidth: width
        contentHeight: pageCol.implicitHeight + AzTheme.px(20) + _side

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        ColumnLayout {
            id: pageCol
            y: AzTheme.px(20)
            width: vFlick.width
            spacing: _m

            // Header (başlıq + açıqlama bir-birinə yaxın)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: AzTheme.px(6)

                Text {
                    text: qsTr("Aktuator Konfiqurasiyası")
                    color: AzTheme.textCard
                    font.family: AzTheme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: AzTheme.fontPx(actuatorPage._compact ? 18 : 20)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Ötürücü çıxışlarını və motor konfiqurasiyasını idarə edin. Mikserin həndəsəsini tənzimləyin və aktuator testini həyata keçirin.")
                    color: AzTheme.textSecondary
                    font.family: AzTheme.fontFamily
                    font.pixelSize: AzTheme.fontPx(13)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // Avtopilot bağlantısı gözləyən kart: the vehicle state and what to expect
            Rectangle {
                Layout.fillWidth: true
                radius: AzTheme.px(AzTheme.cardRadius)
                border.width: 1
                border.color: AzTheme.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: AzTheme.cardGradientStart }
                    GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                }
                visible: !actuatorPage.parametersReady
                implicitHeight: AzTheme.px(200)

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 2 * _m
                    spacing: AzTheme.px(10)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: AzTheme.px(12); height: width; radius: width / 2
                        color: globals.activeVehicle ? AzTheme.statusOrange : AzTheme.mutedText
                    }
                    Text {
                        width: parent.width
                        text: globals.activeVehicle ? qsTr("Parametrlər yüklənir...") : qsTr("Aktiv aparat yoxdur")
                        color: AzTheme.textCard; font.family: AzTheme.fontFamily; font.weight: Font.Medium
                        font.pixelSize: AzTheme.fontPx(17)
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    }
                    Text {
                        width: parent.width
                        text: globals.activeVehicle ? qsTr("Avtopilot bağlantısını gözləyin")
                                                    : qsTr("Qoşulduqdan sonra aktuatorlar görünəcək.")
                        color: AzTheme.textSecondary; font.family: AzTheme.fontFamily
                        font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    }
                }
            }

            // Body Loader — yalnız avtopilot qoşulduqda yüklənir.
            Loader {
                id: bodyLoader
                Layout.fillWidth: true
                visible: actuatorPage.parametersReady
                active: actuatorPage.parametersReady
                sourceComponent: bodyComponent
            }
        }
    }

    // -------------------------
    // Body — Advanced switch + aktuator məzmunu
    // (yalnız avtopilot qoşulduqda yaradılır)
    // -------------------------
    Component {
        id: bodyComponent

        ColumnLayout {
            spacing: _m

        // Advanced switch
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: actuatorPage.parametersReady

            AzSwitch {
                checked: actuatorPage._showAdvanced
                onClicked: actuatorPage._showAdvanced = !actuatorPage._showAdvanced
            }

            Text {
                text: qsTr("Qabaqcıl Parametrləri göstərin")
                color: AzTheme.textCard
                font.family: AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(AzTheme.popupTextSize)
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }

        // Scroll artıq səhifə səviyyəsindədir; burada yalnız məzmunu boyuna
        // görə yer tutan bir qab lazımdır.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: contentGrid.implicitHeight
            visible: actuatorPage.parametersReady

            GridLayout {
                id: contentGrid
                width: parent.width
                columns: actuatorPage._twoCols ? 2 : 1
                columnSpacing: _m
                rowSpacing: _m

                // ---------- SOL BLOK ----------
                Item {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: actuatorPage._twoCols
                                           ? (contentGrid.width - contentGrid.columnSpacing) / 2
                                           : contentGrid.width
                    implicitHeight: leftColumn.implicitHeight

                    Column {
                        id: leftColumn
                        width: parent.width
                        spacing: _m

                        // Mixer card
                        Rectangle {
                            width: parent.width
                            implicitHeight: mixerUi.height + 2 * _cardPad
                            visible: actuators.mixer.groups.count > 0
                            radius: AzTheme.px(AzTheme.cardRadius)
                            border.width: 1
                            border.color: AzTheme.cardBorder
                            gradient: Gradient {
                                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                            }

                            Column {
                                id: mixerUi
                                spacing: _margins
                                anchors {
                                    top: parent.top
                                    topMargin: _cardPad
                                    left: parent.left
                                    right: parent.right
                                    margins: _cardPad
                                }
                                enabled: !safetySwitch.checked && !actuators.motorAssignmentActive

                                Repeater {
                                    model: actuators.mixer.groups
                                    ColumnLayout {
                                        width: mixerUi.width
                                        property var mixerGroup: object

                                        RowLayout {
                                            QGCLabel {
                                                text: mixerGroup.label
                                                font.weight: Font.Medium
                                                rightPadding: ScreenTools.defaultFontPixelWidth * 3
                                            }
                                            ActuatorFact {
                                                property var countParam: mixerGroup.countParam
                                                visible: countParam != null && (_showAdvanced || !countParam.advanced)
                                                fact: countParam ? countParam.fact : null
                                            }
                                        }

                                        // ✅ Mixer cədvəli horizontal scroll alsın (advanced açılınca sağa daşmasın)
                                        QGCFlickable {
                                            Layout.fillWidth: true
                                            clip: true
                                            flickableDirection: Flickable.HorizontalFlick
                                            boundsBehavior: Flickable.StopAtBounds
                                            pressDelay: 120
                                            //interactive: contentWidth > width

                                            // contentWidth: mixerGrid.implicitWidth
                                            // contentHeight: mixerGrid.implicitHeight
                                            // implicitHeight: mixerGrid.implicitHeight
                                            contentWidth: Math.max(width, mixerGrid.implicitWidth)
                                                contentHeight: mixerGrid.implicitHeight
                                                implicitHeight: mixerGrid.implicitHeight

                                                interactive: mixerGrid.implicitWidth > width

                                            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                                            GridLayout {
                                                id: mixerGrid
                                                width: implicitWidth
                                                height: implicitHeight
                                                rows: 1 + mixerGroup.channels.count
                                                columns: 1 + mixerGroup.channelConfigs.count

                                                QGCLabel { text: "" }

                                                Repeater {
                                                    model: mixerGroup.channelConfigs
                                                    QGCLabel {
                                                        text: object.label
                                                        visible: object.visible && (_showAdvanced || !object.advanced)
                                                        Layout.row: 0
                                                        Layout.column: 1 + index
                                                        color: AzTheme.textSecondary
                                                    }
                                                }

                                                Repeater {
                                                    model: mixerGroup.channels
                                                    QGCLabel {
                                                        text: object.label + ":"
                                                        Layout.row: 1 + index
                                                        Layout.column: 0
                                                    }
                                                }

                                                Repeater {
                                                    model: mixerGroup.channels
                                                    Repeater {
                                                        property var channel: object
                                                        property var channelIndex: index
                                                        model: object.configInstances
                                                        ActuatorFact {
                                                            fact: object.fact
                                                            Layout.row: 1 + channelIndex
                                                            Layout.column: 1 + index
                                                            visible: object.config.visible && (_showAdvanced || !object.config.advanced) && object.visible
                                                            enabled: object.enabled
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Repeater {
                                            model: mixerGroup.configParams
                                            RowLayout {
                                                spacing: ScreenTools.defaultFontPixelWidth
                                                visible: _showAdvanced || !object.advanced
                                                QGCLabel { text: object.label + ":"; color: AzTheme.textSecondary }
                                                ActuatorFact { fact: object.fact }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Aktuator görüntüsü
                        Rectangle {
                            width: parent.width
                            height: AzTheme.px(200)
                            color: AzTheme.groupFill
                            visible: actuators.isMultirotor
                            radius: AzTheme.px(AzTheme.cardRadius)
                            border.color: AzTheme.groupBorder
                            border.width: 1

                            Image {
                                id: actuatorImage
                                source: "image://actuators/geometry" + refreshFlag
                                sourceSize.width: 150
                                sourceSize.height: 150
                                anchors.centerIn: parent
                                visible: actuators.isMultirotor
                                cache: false

                                property var refreshFlag: actuators.imageRefreshFlag

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: (mouse) => {
                                        if (mouse.button == Qt.LeftButton) {
                                            actuators.imageClicked(Qt.size(width, height), mouse.x, mouse.y);
                                        }
                                    }
                                }
                            }
                        }

                        // Aktuator testi
                        Rectangle {
                            width: parent.width
                            implicitHeight: actuatorTesting.height + 2 * _cardPad
                            radius: AzTheme.px(AzTheme.cardRadius)
                            border.width: 1
                            border.color: AzTheme.cardBorder
                            gradient: Gradient {
                                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                            }

                            Column {
                                id: actuatorTesting
                                spacing: _margins
                                anchors {
                                    top: parent.top
                                    topMargin: _cardPad
                                    left: parent.left
                                    right: parent.right
                                    margins: _cardPad
                                }

                                QGCLabel {
                                    text: qsTr("Test etmək üçün bəzi çıxışları konfiqurasiya edin.")
                                    visible: actuators.actuatorTest.actuators.count == 0
                                }

                                Row {
                                    spacing: ScreenTools.defaultFontPixelWidth
                                    visible: actuators.actuatorTest.actuators.count > 0

                                    Switch {
                                        id: safetySwitch
                                        enabled: !actuators.motorAssignmentActive && !actuators.actuatorTest.hadFailure

                                        // ✅ implicitWidth/Height əvəzinə width/height
                                        // AzSwitch's look; the Switch itself stays, its state drives the test
                                        indicator: Rectangle {
                                            width: AzTheme.px(44)
                                            height: AzTheme.px(24)
                                            x: safetySwitch.leftPadding
                                            y: parent.height / 2 - height / 2
                                            radius: height / 2
                                            color: safetySwitch.checked ? AzTheme.statusGreen : AzTheme.pillBottom
                                            border.width: 1
                                            border.color: safetySwitch.checked ? AzTheme.statusGreen : AzTheme.groupBorder
                                            opacity: safetySwitch.enabled ? 1 : 0.45

                                            Rectangle {
                                                x: safetySwitch.checked ? parent.width - width - AzTheme.px(3) : AzTheme.px(3)
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.height - AzTheme.px(6)
                                                height: width
                                                radius: width / 2
                                                color: AzTheme.textCard
                                                Behavior on x { NumberAnimation { duration: 150 } }
                                            }
                                        }

                                        Connections {
                                            target: actuators.actuatorTest
                                            onHadFailureChanged: {
                                                if (actuators.actuatorTest.hadFailure) {
                                                    safetySwitch.checked = false;
                                                    safetySwitch.switchUpdated();
                                                }
                                            }
                                        }

                                        onClicked: switchUpdated()

                                        function switchUpdated() {
                                            if (!checked) {
                                                for (var channelIdx=0; channelIdx<sliderRepeater.count; channelIdx++) {
                                                    sliderRepeater.itemAt(channelIdx).stop();
                                                }
                                                if (allMotorsLoader.item != null)
                                                    allMotorsLoader.item.stop();
                                            }
                                            actuators.actuatorTest.setActive(checked);
                                        }
                                    }

                                    QGCLabel {
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: safetySwitch.checked ? AzTheme.statusRed : AzTheme.statusOrange
                                        text: safetySwitch.checked
                                              ? qsTr("Diqqət: Aktuator parametrləri aktivləşdirilib")
                                              : qsTr("Pərvanələr çıxarıldı - Parametrləri aktivləşdirin.")
                                    }
                                }

                                Row {
                                    spacing: ScreenTools.defaultFontPixelWidth * 2
                                    enabled: safetySwitch.checked

                                    Loader {
                                        id: allMotorsLoader
                                        sourceComponent: actuators.actuatorTest.allMotorsActuator ? allMotorsComponent : null
                                    }

                                    Component {
                                        id: allMotorsComponent
                                        ActuatorSlider {
                                            channel: actuators.actuatorTest.allMotorsActuator
                                            rightPadding: ScreenTools.defaultFontPixelWidth * 3
                                            onActuatorValueChanged: (value, sliderValue) => {
                                                stopTimer();
                                                for (var channelIdx=0; channelIdx<sliderRepeater.count; channelIdx++) {
                                                    var channelSlider = sliderRepeater.itemAt(channelIdx);
                                                    if (channelSlider.channel.isMotor) {
                                                        channelSlider.value = sliderValue;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Repeater {
                                        id: sliderRepeater
                                        model: actuators.actuatorTest.actuators
                                        ActuatorSlider {
                                            channel: object
                                            onActuatorValueChanged: (value) => {
                                                if (isNaN(value)) {
                                                    actuators.actuatorTest.stopControl(index);
                                                    stop();
                                                } else {
                                                    actuators.actuatorTest.setChannelTo(index, value);
                                                }
                                            }
                                        }
                                    }
                                }

                                Column {
                                    visible: actuators.actuatorActions.count > 0
                                    enabled: !safetySwitch.checked && !actuators.motorAssignmentActive

                                    Flow {
                                        width: parent.width
                                        spacing: ScreenTools.defaultFontPixelWidth * 2

                                        Repeater {
                                            model: actuators.actuatorActions
                                            QGCButton {
                                                property var actionGroup: object
                                                text: actionGroup.label
                                                onClicked: actionMenu.popup()
                                                QGCMenu {
                                                    id: actionMenu
                                                    Instantiator {
                                                        model: actionGroup.actions
                                                        QGCMenuItem {
                                                            text: object.label
                                                            onTriggered: object.trigger()
                                                        }
                                                        onObjectAdded: actionMenu.insertItem(index, object)
                                                        onObjectRemoved: actionMenu.removeItem(object)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------- SAĞ BLOK ----------
                Item {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: actuatorPage._twoCols
                                           ? (contentGrid.width - contentGrid.columnSpacing) / 2
                                           : contentGrid.width
                    implicitHeight: rightColumn.implicitHeight

                    Column {
                        id: rightColumn
                        width: parent.width
                        spacing: _m

                        Text {
                            width: parent.width
                            text: qsTr("Aktuator çıxışları")
                            color: AzTheme.textCard
                            font.family: AzTheme.fontFamily
                            font.weight: Font.Medium
                            font.pixelSize: AzTheme.fontPx(16)
                        }

                        Rectangle {
                            width: parent.width
                            height: unsetRow.implicitHeight + AzTheme.px(20)
                            radius: AzTheme.px(AzTheme.groupRadius)
                            color: Qt.rgba(1, 52 / 255, 67 / 255, 0.10)
                            border.color: Qt.rgba(1, 52 / 255, 67 / 255, 0.55)
                            border.width: 1
                            visible: actuators.hasUnsetRequiredFunctions

                            RowLayout {
                                id: unsetRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: AzTheme.px(12)
                                spacing: AzTheme.px(10)

                                QGCColoredImage {
                                    Layout.preferredWidth: AzTheme.px(18)
                                    Layout.preferredHeight: AzTheme.px(18)
                                    source: "qrc:/res/AZSHIELD_ICON/bx_error.svg"
                                    sourceSize.height: AzTheme.px(18)
                                    fillMode: Image.PreserveAspectFit
                                    color: AzTheme.statusRed
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Bir və ya bir neçə aktuator hələ də çıxışa təyin edilməyib.")
                                    color: AzTheme.textCard
                                    font.family: AzTheme.fontFamily
                                    font.pixelSize: AzTheme.fontPx(13)
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Flickable {
                            width: parent.width
                            height: tabBar.implicitHeight
                            contentWidth: tabBar.implicitWidth
                            clip: true
                            flickableDirection: Flickable.HorizontalFlick
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentWidth > width

                            QGCTabBar {
                                id: tabBar
                                Repeater {
                                    model: actuators.actuatorOutputs
                                    QGCTabButton {
                                        text: object.label
                                        width: implicitWidth + AzTheme.px(24)
                                    }
                                }
                                onCurrentIndexChanged: actuators.selectActuatorOutput(currentIndex)
                            }
                        }

                        Rectangle {
                            // Named so that nested children do not have to count parent
                            // levels - that is what produced the `groupsVisible of
                            // undefined` error below.
                            id: actuatorGroupPanel

                            width: parent.width
                            implicitHeight: actuatorGroupColumn.height + 2 * _cardPad
                            radius: AzTheme.px(AzTheme.cardRadius)
                            border.width: 1
                            border.color: AzTheme.cardBorder
                            gradient: Gradient {
                                GradientStop { position: 0; color: AzTheme.cardGradientStart }
                                GradientStop { position: 1; color: AzTheme.cardGradientEnd }
                            }

                            property var actuatorOutput: actuators.selectedActuatorOutput

                            Column {
                                id: actuatorGroupColumn
                                spacing: _margins
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: _cardPad
                                    topMargin: _cardPad
                                }

                                // ✅ Buttonlar dar ekranda sətirə düşsün
                                Flow {
                                    width: parent.width
                                    visible: actuators.isMultirotor
                                    enabled: !safetySwitch.checked
                                    spacing: _margins

                                    QGCButton {
                                        text: qsTr("Mühərrikləri müəyyənləşdirin və təyin edin")
                                        visible: !actuators.motorAssignmentActive && !!actuatorGroupPanel.actuatorOutput && actuatorGroupPanel.actuatorOutput.groupsVisible
                                        enabled: actuators.motorAssignmentEnabled
                                        onClicked: {
                                            var success = actuators.initMotorAssignment()
                                            if (success) actuatorPage.openMotorAssignConfirm()
                                            else actuatorPage.openMotorAssignFailure()
                                        }
                                    }
                                    QGCButton {
                                        text: qsTr("Mühərriki Yenidən Döndürün")
                                        visible: actuators.motorAssignmentActive
                                        onClicked: actuators.spinCurrentMotor()
                                    }
                                    QGCButton {
                                        text: qsTr("Ləğv et")
                                        visible: actuators.motorAssignmentActive
                                        onClicked: actuators.abortMotorAssignment()
                                    }
                                }

                                Column {
                                    enabled: !safetySwitch.checked && !actuators.motorAssignmentActive
                                    spacing: _margins
                                    width: parent.width

                                    RowLayout {
                                        property var enableParam: actuatorGroupPanel.actuatorOutput ? actuatorGroupPanel.actuatorOutput.enableParam : null
                                        width: parent.width
                                        visible: _showAdvanced || (enableParam && !enableParam.advanced)

                                        QGCLabel {
                                            visible: parent.enableParam != null
                                            text: parent.enableParam ? parent.enableParam.label + ":" : ""
                                            color: AzTheme.textSecondary
                                        }
                                        ActuatorFact {
                                            visible: parent.enableParam != null
                                            fact: parent.enableParam ? parent.enableParam.fact : null
                                        }
                                    }

                                    Repeater {
                                        model: actuatorGroupPanel.actuatorOutput ? actuatorGroupPanel.actuatorOutput.subgroups : 0
                                        ColumnLayout {
                                            property var subgroup: object
                                            visible: !!actuatorGroupPanel.actuatorOutput && actuatorGroupPanel.actuatorOutput.groupsVisible && (_showAdvanced || !subgroup.advanced)
                                            width: parent.width

                                            RowLayout {
                                                visible: subgroup.label != ""
                                                width: parent.width
                                                QGCLabel {
                                                    text: subgroup.label
                                                    font.weight: Font.Medium
                                                    rightPadding: ScreenTools.defaultFontPixelWidth * 3
                                                }
                                                ActuatorFact {
                                                    property var primaryParam: subgroup.primaryParam
                                                    visible: primaryParam != null && (_showAdvanced || !primaryParam.advanced)
                                                    fact: primaryParam ? primaryParam.fact : null
                                                }
                                            }

                                            // ✅ Output cədvəli də horizontal scroll alsın
                                            QGCFlickable {
                                                Layout.fillWidth: true
                                                clip: true
                                                flickableDirection: Flickable.HorizontalFlick
                                                boundsBehavior: Flickable.StopAtBounds
                                                pressDelay: 120
                                                //interactive: contentWidth > width


                                                // contentWidth: outGrid.implicitWidth
                                                // contentHeight: outGrid.implicitHeight
                                                // implicitHeight: outGrid.implicitHeight

                                                contentWidth: Math.max(width, outGrid.implicitWidth)
                                                    contentHeight: outGrid.implicitHeight
                                                    implicitHeight: outGrid.implicitHeight

                                                    interactive: outGrid.implicitWidth > width

                                                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                                                GridLayout {
                                                    id: outGrid
                                                    width: implicitWidth
                                                    height: implicitHeight
                                                    rows: 1 + subgroup.channels.count
                                                    columns: 1 + subgroup.channelConfigs.count

                                                    QGCLabel { text: "" }

                                                    Repeater {
                                                        model: subgroup.channelConfigs
                                                        QGCLabel {
                                                            text: object.label
                                                            visible: object.visible && (_showAdvanced || !object.advanced)
                                                            Layout.row: 0
                                                            Layout.column: 1 + index
                                                            color: AzTheme.textSecondary
                                                        }
                                                    }

                                                    Repeater {
                                                        model: subgroup.channels
                                                        QGCLabel {
                                                            text: object.label + ":"
                                                            Layout.row: 1 + index
                                                            Layout.column: 0
                                                        }
                                                    }

                                                    Repeater {
                                                        model: subgroup.channels
                                                        Repeater {
                                                            property var channel: object
                                                            property var channelIndex: index
                                                            model: object.configInstances
                                                            ActuatorFact {
                                                                fact: object.fact
                                                                Layout.row: 1 + channelIndex
                                                                Layout.column: 1 + index
                                                                visible: object.config.visible && (_showAdvanced || !object.config.advanced)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Repeater {
                                                model: subgroup.configParams
                                                RowLayout {
                                                    width: parent.width
                                                    visible: _showAdvanced || !object.advanced
                                                    QGCLabel { text: object.label + ":"; color: AzTheme.textSecondary }
                                                    ActuatorFact { fact: object.fact }
                                                }
                                            }
                                        }
                                    }

                                    Repeater {
                                        model: actuatorGroupPanel.actuatorOutput ? actuatorGroupPanel.actuatorOutput.configParams : 0
                                        RowLayout {
                                            width: parent.width
                                            visible: _showAdvanced || !object.advanced
                                            QGCLabel { text: object.label + ":"; color: AzTheme.textSecondary }
                                            ActuatorFact { fact: object.fact }
                                        }
                                    }

                                    Repeater {
                                        model: actuatorGroupPanel.actuatorOutput ? actuatorGroupPanel.actuatorOutput.notes : 0
                                        ColumnLayout {
                                            spacing: ScreenTools.defaultFontPixelHeight
                                            width: parent.width
                                            QGCLabel {
                                                text: modelData
                                                color: AzTheme.statusOrange
                                                width: parent.width
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        }    // bodyComponent ColumnLayout
    }    // bodyComponent

    // Dialoglar (QtQuick.Dialogs lazım deyil)
    Component {
        id: motorAssignmentConfirmDlgComponent

        QGCPopupDialog {
            title: qsTr("Mühərrikin ardıcıllığının tərifi və təyinatı")
            buttons: Dialog.Yes | Dialog.No

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight
                QGCLabel {
                    text: actuators.motorAssignmentMessage
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.maximumWidth: (typeof mainWindow !== "undefined") ? (mainWindow.width * 0.7) : 700
                }
            }

            onAccepted: actuators.startMotorAssignment()
            onClosed: destroy()
        }
    }

    Component {
        id: motorAssignmentFailureDlgComponent

        QGCPopupDialog {
            title: qsTr("Xəta")
            buttons: Dialog.Ok

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight
                QGCLabel {
                    text: actuators.motorAssignmentMessage
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.maximumWidth: (typeof mainWindow !== "undefined") ? (mainWindow.width * 0.7) : 700
                }
            }

            onClosed: destroy()
        }
    }
}

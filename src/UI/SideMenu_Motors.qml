import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.AutoPilotPlugins.PX4 1.0

Rectangle {
    id: actuatorPage
    anchors.fill: parent
    color: "black"

    property bool parametersReady: globals.activeVehicle
                                   && globals.activeVehicle.parameterManager
                                   && globals.activeVehicle.parameterManager.parametersReady

    property var  actuators: (globals.activeVehicle && globals.activeVehicle.actuators) ? globals.activeVehicle.actuators : null
    property bool _showAdvanced: true

    readonly property real _m:       Math.max(12, ScreenTools.defaultFontPixelHeight * 0.75)
    readonly property real _side:    Math.max(12, _m * 0.9)
    readonly property real _margins: ScreenTools.defaultFontPixelHeight

    // Breakpoint: kiçik ekranda alt-alta, böyükdə yan-yana
    readonly property bool _twoCols: width >= 1200

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


    ColumnLayout {
        z: 2
        anchors.fill: parent
        anchors.leftMargin: _side
        anchors.rightMargin: _side
        anchors.bottomMargin: _side
        anchors.topMargin: 0

        spacing: _m

        // Header (başlıq + açıqlama bir-birinə yaxın)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Aktuator Konfiqurasiyası")
                color: "#FFFFFF"
                font.pixelSize: 26
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("Ötürücü çıxışlarını və motor konfiqurasiyasını idarə edin. Mikserin həndəsəsini tənzimləyin və aktuator testini həyata keçirin.")
                color: "#E8E8E8"
                font.pixelSize: 16
                font.bold: false
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // Avtopilot bağlantısı gözləyən kart
        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: "#3D3B3B"
            border.width: 1
            border.color: "#9D9D9D"
            visible: !actuatorPage.parametersReady
            implicitHeight: 220

            Text {
                anchors.centerIn: parent
                width: parent.width - 2 * _m
                text: qsTr("Parametrlər yüklənir...\nAvtopilot bağlantısını gözləyin")
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        // Body Loader — yalnız avtopilot qoşulduqda yüklənir.
        Loader {
            id: bodyLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: actuatorPage.parametersReady
            active: actuatorPage.parametersReady
            sourceComponent: bodyComponent
        }

        // Avtopilot qoşulu olmadıqda boş yeri aşağıda saxlayan filler
        // (Frame səhifəsindəki kimi)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: !actuatorPage.parametersReady
            Layout.preferredHeight: actuatorPage.parametersReady ? 0 : -1
            visible: !actuatorPage.parametersReady
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

            Switch {
                id: advancedSwitch
                checked: actuatorPage._showAdvanced

                // ✅ implicitWidth/Height əvəzinə width/height
                indicator: Rectangle {
                    width: 48
                    height: 26
                    x: advancedSwitch.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 13
                    color: advancedSwitch.checked ? "#4CAF50" : "#cccccc"
                    border.color: advancedSwitch.checked ? "#4CAF50" : "#999999"

                    Rectangle {
                        x: advancedSwitch.checked ? parent.width - width : 0
                        width: 26
                        height: 26
                        radius: 13
                        color: advancedSwitch.down ? "#cccccc" : "#ffffff"
                        border.color: advancedSwitch.checked ? "#4CAF50" : "#999999"
                    }
                }

                onCheckedChanged: actuatorPage._showAdvanced = checked
            }

            Text {
                text: qsTr("Qabaqcıl Parametrləri göstərin")
                color: "white"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }

        // ✅ ScrollView yerinə QGCFlickable: mouse ilə “tutub sürüşdürüb” scroll işləyəcək
        QGCFlickable {
            id: vFlick
            Layout.fillWidth: true
            Layout.fillHeight: actuatorPage.parametersReady
            Layout.preferredHeight: actuatorPage.parametersReady ? -1 : 0
            clip: true
            visible: actuatorPage.parametersReady

            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            // ✅ interaktiv control-lar üstündə drag edəndə belə scroll başlasın
            pressDelay: 150

            contentWidth: width
            contentHeight: contentGrid.implicitHeight

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }



            GridLayout {
                id: contentGrid
                width: vFlick.width
                columns: actuatorPage._twoCols ? 2 : 1
                columnSpacing: 30
                rowSpacing: 30

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
                        spacing: 20

                        // Mixer card
                        Rectangle {
                            width: parent.width
                            implicitHeight: mixerUi.height + 30
                            color: "#3D3B3B"
                            visible: actuators.mixer.groups.count > 0
                            radius: 12
                            border.color: "#9D9D9D"
                            border.width: 2

                            Column {
                                id: mixerUi
                                spacing: _margins
                                anchors {
                                    top: parent.top
                                    topMargin: 20
                                    left: parent.left
                                    right: parent.right
                                    margins: 20
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
                                                font.bold: true
                                                rightPadding: ScreenTools.defaultFontPixelWidth * 3
                                                color: "#FFFFFF"
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
                                                        color: "#B8D4E8"
                                                    }
                                                }

                                                Repeater {
                                                    model: mixerGroup.channels
                                                    QGCLabel {
                                                        text: object.label + ":"
                                                        Layout.row: 1 + index
                                                        Layout.column: 0
                                                        color: "#E8F4FF"
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
                                                QGCLabel { text: object.label + ":"; color: "#B8D4E8" }
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
                            height: 200
                            color: "#1a1f2c"
                            visible: actuators.isMultirotor
                            radius: 12
                            border.color: "#2a3a5c"
                            border.width: 2

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
                            implicitHeight: actuatorTesting.height + 50
                            color: "#3D3B3B"
                            radius: 12
                            border.color: "#9D9D9D"
                            border.width: 2

                            Column {
                                id: actuatorTesting
                                spacing: _margins
                                anchors {
                                    top: parent.top
                                    topMargin: 20
                                    left: parent.left
                                    right: parent.right
                                    margins: 20
                                }

                                QGCLabel {
                                    text: qsTr("Test etmək üçün bəzi çıxışları konfiqurasiya edin.")
                                    visible: actuators.actuatorTest.actuators.count == 0
                                    color: "#FFFFFF"
                                }

                                Row {
                                    spacing: ScreenTools.defaultFontPixelWidth
                                    visible: actuators.actuatorTest.actuators.count > 0

                                    Switch {
                                        id: safetySwitch
                                        enabled: !actuators.motorAssignmentActive && !actuators.actuatorTest.hadFailure

                                        // ✅ implicitWidth/Height əvəzinə width/height
                                        indicator: Rectangle {
                                            width: 48
                                            height: 26
                                            x: safetySwitch.leftPadding
                                            y: parent.height / 2 - height / 2
                                            radius: 13
                                            color: safetySwitch.checked ? "#4CAF50" : "#cccccc"
                                            border.color: safetySwitch.checked ? "#4CAF50" : "#999999"

                                            Rectangle {
                                                x: safetySwitch.checked ? parent.width - width : 0
                                                width: 26
                                                height: 26
                                                radius: 13
                                                color: safetySwitch.down ? "#cccccc" : "#ffffff"
                                                border.color: safetySwitch.checked ? "#4CAF50" : "#999999"
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
                                        color: "#FFA500"
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
                                            onActuatorValueChanged: {
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
                        spacing: 20

                        Rectangle {
                            width: parent.width
                            height: 50
                            color: "#3D3B3B"
                            radius: 12
                            border.color: "#9D9D9D"
                            border.width: 2

                            Text {
                                text: qsTr("AKTUATOR ÇIXIŞLARI")
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 40
                            radius: 8
                            color: "#3D3B3B"
                            border.color: "#9D9D9D"
                            border.width: 1
                            visible: actuators.hasUnsetRequiredFunctions

                            Text {
                                text: qsTr("⚠️ Bir və ya bir neçə aktuator hələ də çıxışa təyin edilməyib.")
                                color: "#D21404"
                                font.pixelSize: 12
                                anchors.centerIn: parent
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 50
                            color: "#3D3B3B"
                            radius: 12
                            border.color: "#9D9D9D"
                            border.width: 2

                            QGCTabBar {
                                id: tabBar
                                anchors.centerIn: parent
                                Repeater {
                                    model: actuators.actuatorOutputs
                                    QGCTabButton {
                                        text: "   " + object.label + "   "
                                        width: implicitWidth
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
                            implicitHeight: actuatorGroupColumn.height + 30
                            color: "#3D3B3B"
                            radius: 12
                            border.color: "#9D9D9D"
                            border.width: 2

                            property var actuatorOutput: actuators.selectedActuatorOutput

                            Column {
                                id: actuatorGroupColumn
                                spacing: _margins
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: 20
                                    topMargin: 20
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
                                            color: "#C8E8C8"
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
                                                    font.bold: true
                                                    rightPadding: ScreenTools.defaultFontPixelWidth * 3
                                                    color: "#90C890"
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
                                                            color: "#E8F4E8"
                                                        }
                                                    }

                                                    Repeater {
                                                        model: subgroup.channels
                                                        QGCLabel {
                                                            text: object.label + ":"
                                                            Layout.row: 1 + index
                                                            Layout.column: 0
                                                            color: "#F4F8F4"
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
                                                    QGCLabel { text: object.label + ":"; color: "#E8F4E8" }
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
                                            QGCLabel { text: object.label + ":"; color: "#E8F4E8" }
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
                                                color: "#FFA500"
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

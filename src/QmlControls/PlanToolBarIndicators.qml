import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.UTMSP

// Toolbar for Plan View
RowLayout {
    required property var planMasterController

    id: root
    spacing: AzTheme.px(8)

    property var _planMasterController: planMasterController
    property var _missionController: _planMasterController.missionController
    property var _geoFenceController: _planMasterController.geoFenceController
    property var _rallyPointController: _planMasterController.rallyPointController
    property bool _controllerOffline: _planMasterController.offline
    property var _controllerDirty: _planMasterController.dirty
    property var _syncInProgress: _planMasterController.syncInProgress
    property var _visualItems: _missionController.visualItems
    property bool _hasPlanItems: _planMasterController.containsItems

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    // Properties of UTM adapter
    property bool _utmspEnabled: QGroundControl.utmspSupported

    function _uploadClicked() {
        if (_utmspEnabled) {
            QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true);
            UTMSPStateStorage.removeFlightPlanState = true
            UTMSPStateStorage.indicatorDisplayStatus = true
        }
        _planMasterController.upload();
    }

    function _downloadClicked() {
        if (_planMasterController.dirty) {
            mainWindow.showMessageDialog(qsTr("Yüklə"),
                                         qsTr("Yadda saxlanmamış/göndərilməyən dəyişiklikləriniz var. Təyyarədən endirmə bu dəyişiklikləri itirəcək. Əminsən?"),
                                         Dialog.Yes | Dialog.Cancel,
                                         function() { _planMasterController.loadFromVehicle() })
        } else {
            _planMasterController.loadFromVehicle()
        }
    }

    function _openButtonClicked() {
        if (_planMasterController.dirty) {
            mainWindow.showMessageDialog(qsTr("Open Plan"),
                                        qsTr("Yadda saxlanmamış/göndərilməyən dəyişiklikləriniz var. Yeni Planın yüklənməsi bu dəyişiklikləri itirəcək. Əminsən?"),
                                        Dialog.Yes | Dialog.Cancel,
                                        function() { _planMasterController.loadFromSelectedFile() } )
        } else {
            _planMasterController.loadFromSelectedFile()
        }
    }

    function _saveButtonClicked() {
        if(_planMasterController.currentPlanFile !== "") {
            _planMasterController.saveToCurrent()
            mainWindow.showMessageDialog(qsTr("Saxla"),
                                        qsTr("Plan `%1`-də yadda saxlanıldı").arg(_planMasterController.currentPlanFile),
                                        Dialog.Ok)
        } else {
            _planMasterController.saveToSelectedFile()
        }
    }

    function _saveAsKMLClicked() {
        // Don't save if we only have Mission Settings item
        if (_visualItems.count > 1) {
            _planMasterController.saveKmlToSelectedFile()
        }
    }

    function _storageClearButtonClicked() {
        mainWindow.showMessageDialog(qsTr("Təmizlə"),
                                     qsTr("Plan redaktorundan bütün elementləri silmək istədiyinizə əminsiniz?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() { _planMasterController.removeAll(); })
    }

    function _vehicleClearButtonClicked() {
        mainWindow.showMessageDialog(qsTr("Təmizlə"),
                                     qsTr("Planı təyyarədən və plan redaktorundan silmək istədiyinizə əminsiniz?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() {
                                        _planMasterController.removeAllFromVehicle();
                                        if (_utmspEnabled) {
                                            _resetRegisterFlightPlan = true;
                                            QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(false);
                                            UTMSPStateStorage.startTimeStamp = "";
                                            UTMSPStateStorage.showActivationTab = false;
                                            UTMSPStateStorage.flightID = "";
                                            UTMSPStateStorage.enableMissionUploadButton = false;
                                            UTMSPStateStorage.indicatorPendingStatus = true;
                                            UTMSPStateStorage.indicatorApprovedStatus = false;
                                            UTMSPStateStorage.indicatorActivatedStatus = false;
                                            UTMSPStateStorage.currentStateIndex = 0}})
    }

    function _clearClicked() {
        if (_planMasterController.offline) {
            _storageClearButtonClicked();
        } else {
            _vehicleClearButtonClicked();
        }
    }

    QGCPalette { id: qgcPal }

    readonly property real _buttonH: AzTheme.px(40)

    AzButton {
        Layout.alignment:       Qt.AlignVCenter
        Layout.preferredHeight: root._buttonH
        text:       qsTr("Aç")
        iconSource: "qrc:/res/AZSHIELD_ICON/v2/plan_open.svg"
        enabled:    !_planMasterController.syncInProgress
        onClicked:  _openButtonClicked()
    }

    AzButton {
        Layout.alignment:       Qt.AlignVCenter
        Layout.preferredHeight: root._buttonH
        text:       _planMasterController.currentPlanFile === "" ? qsTr("Fərqli saxla") : qsTr("Saxla")
        iconSource: "qrc:/res/AZSHIELD_ICON/v2/plan_save.svg"
        enabled:    !_syncInProgress && _hasPlanItems
        onClicked:  _saveButtonClicked()
    }

    // Green while the plan has changes the vehicle does not have yet.
    AzButton {
        id: uploadButton
        Layout.alignment:       Qt.AlignVCenter
        Layout.preferredHeight: root._buttonH
        text:       qsTr("Yüklə")
        iconSource: "qrc:/res/AZSHIELD_ICON/v2/plan_upload.svg"
        enabled:    _utmspEnabled ? (!_syncInProgress && UTMSPStateStorage.enableMissionUploadButton) : (!_syncInProgress && _hasPlanItems)
        visible:    !_syncInProgress
        positive:   _controllerDirty && enabled
        onClicked:  _uploadClicked()
    }

    AzButton {
        Layout.alignment:       Qt.AlignVCenter
        Layout.preferredHeight: root._buttonH
        text:       qsTr("Təmizlə")
        iconSource: "qrc:/res/AZSHIELD_ICON/v2/popup_trash.svg"
        enabled:    !_syncInProgress
        onClicked:  _clearClicked()
    }

    AzButton {
        Layout.alignment:       Qt.AlignVCenter
        Layout.preferredHeight: root._buttonH
        Layout.preferredWidth:  root._buttonH
        minimumWidth: root._buttonH
        iconSource:   "qrc:/res/AZSHIELD_ICON/v2/plan_menu.svg"

        onClicked: {
            let position = Qt.point(width, height / 2)
            // For some strange reason using mainWindow in mapToItem doesn't work, so we use globals.parent instead which also gets us mainWindow
            position = mapToItem(globals.parent, position)
            var dropPanel = hamburgerDropPanelComponent.createObject(mainWindow, { clickRect: Qt.rect(position.x, position.y, 0, 0) })
            dropPanel.open()
        }
    }

    Row {
        Layout.alignment:  Qt.AlignVCenter
        Layout.leftMargin: AzTheme.px(6)
        spacing:           AzTheme.px(8)
        visible:           hintColumn.visibleChildren.length > 0

        QGCColoredImage {
            anchors.verticalCenter: parent.verticalCenter
            width:                  AzTheme.px(16)
            height:                 width
            sourceSize.height:      height
            fillMode:               Image.PreserveAspectFit
            source:                 "qrc:/res/AZSHIELD_ICON/v2/popup_info.svg"
            color:                  AzTheme.mutedText
        }

        Column {
            id:                     hintColumn
            anchors.verticalCenter: parent.verticalCenter
            spacing:                AzTheme.px(2)

            Text {
                text:           _editingLayer === _layerMission ? qsTr("Waypoint əlavə etmək üçün xəritəyə klikləyin")
                                                                : qsTr("Rally Point əlavə etmək üçün xəritəyə klikləyin")
                visible:        _editingLayer === _layerMission || _editingLayer === _layerRallyPoints
                color:          AzTheme.textSecondary
                font.family:    AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(13)
            }

            Text {
                text:           qsTr("ROI əlavə etmək üçün %1").arg(ScreenTools.isMobile ? qsTr("basıb saxlayın") : qsTr("sağ klikləyin"))
                                + (_missionController.isROIActive ? qsTr(" və ya ROI-ni ləğv edin") : "")
                visible:        _editingLayer === _layerMission && _planMasterController.controllerVehicle.roiModeSupported
                color:          AzTheme.textSecondary
                font.family:    AzTheme.fontFamily
                font.pixelSize: AzTheme.fontPx(13)
            }
        }
    }

    Component {
        id: hamburgerDropPanelComponent

        DropPanel {
            id: dropPanel
            panelColor:  AzTheme.menuSelectedBottom
            panelBorder: AzTheme.panelBorder

            sourceComponent: Component {
                ColumnLayout {
                    spacing: AzTheme.px(8)

                    AzButton {
                        Layout.fillWidth:       true
                        Layout.preferredHeight: AzTheme.px(38)
                        text:    qsTr("KML kimi yadda saxla")
                        enabled: !_syncInProgress && _hasPlanItems

                        onClicked: {
                            dropPanel.close()
                            _saveAsKMLClicked()
                        }
                    }

                    AzButton {
                        Layout.fillWidth:       true
                        Layout.preferredHeight: AzTheme.px(38)
                        text:    qsTr("Təyyarədən endir")
                        enabled: _utmspEnabled ? !_syncInProgress && UTMSPStateStorage.enableMissionDownloadButton : !_syncInProgress
                        visible: !_syncInProgress

                        onClicked: {
                            dropPanel.close()
                            _downloadClicked()
                        }
                    }
                }
            }
        }
    }
}

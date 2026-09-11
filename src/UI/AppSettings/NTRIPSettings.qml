/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick
import QtQuick.Layouts

import QGroundControl

import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.GPS.NTRIP

SettingsPage {
    id: root

    property var  _ntrip:       QGroundControl.settingsManager.ntripSettings
    property var  _ntripMgr:    QGroundControl.ntripManager
    property Fact _enabled:     _ntrip.ntripServerConnectEnabled

    // Transport-affecting fields are locked while the client is enabled: changing them
    // mid-session forces a reconnect anyway, and editing a half-typed host would make
    // the manager churn through failed connect attempts.
    property bool _isActive:    _enabled.rawValue
    property bool _hasHost:     _ntrip.ntripServerHostAddress.rawValue !== ""

    property real _fieldWidth:  ScreenTools.defaultFontPixelWidth * 30

    QGCPalette { id: qgcPal }

    //-------------------------------------------------------------------------
    // Connection status + connect/disconnect
    //-------------------------------------------------------------------------
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Connection")
        visible:            root._ntrip.visible

        NTRIPConnectionStatusRow {
            Layout.fillWidth:   true
            ntripManager:       root._ntripMgr
            canConnect:         root._isActive || root._hasHost
            onClicked:          root._enabled.rawValue = !root._isActive
        }

        NTRIPConnectionStatus {
            Layout.fillWidth:   true
            rtcmMavlink:        root._ntripMgr ? root._ntripMgr.rtcmMavlink : null
        }
    }

    //-------------------------------------------------------------------------
    // Caster
    //-------------------------------------------------------------------------
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Server")
        visible:            root._ntrip.ntripServerHostAddress.visible || root._ntrip.ntripServerPort.visible ||
                            root._ntrip.ntripUsername.visible || root._ntrip.ntripPassword.visible

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    root._fieldWidth
            label:                      fact.shortDescription
            fact:                       root._ntrip.ntripServerHostAddress
            visible:                    fact.visible
            enabled:                    !root._isActive
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    root._fieldWidth
            label:                      fact.shortDescription
            fact:                       root._ntrip.ntripServerPort
            visible:                    fact.visible
            enabled:                    !root._isActive
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    root._fieldWidth
            label:                      fact.shortDescription
            fact:                       root._ntrip.ntripUsername
            visible:                    fact.visible
            enabled:                    !root._isActive
        }

        RowLayout {
            Layout.fillWidth:   true
            visible:            root._ntrip.ntripPassword.visible
            spacing:            ScreenTools.defaultFontPixelWidth * 0.5

            LabelledFactTextField {
                id:                         passwordField
                Layout.fillWidth:           true
                textFieldPreferredWidth:    root._fieldWidth
                label:                      fact.shortDescription
                fact:                       root._ntrip.ntripPassword
                textField.echoMode:         passwordField._showPassword ? TextInput.Normal : TextInput.Password
                enabled:                    !root._isActive

                property bool _showPassword: false
            }

            QGCButton {
                Layout.alignment:   Qt.AlignBottom
                text:               passwordField._showPassword ? qsTr("Hide") : qsTr("Show")
                onClicked:          passwordField._showPassword = !passwordField._showPassword
            }
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               fact.shortDescription
            fact:               root._ntrip.ntripUseTls
            visible:            fact.visible
            enabled:            !root._isActive
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               fact.shortDescription
            fact:               root._ntrip.ntripAllowSelfSignedCerts
            visible:            fact.visible
            // Only meaningful over TLS, and only a self-signed chain is ever ignored —
            // every other certificate error stays fatal.
            enabled:            !root._isActive && root._ntrip.ntripUseTls.rawValue
        }
    }

    //-------------------------------------------------------------------------
    // Mountpoint + source-table browser
    //-------------------------------------------------------------------------
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Mountpoint")
        visible:            root._ntrip.ntripMountpoint.visible

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth

            LabelledFactTextField {
                Layout.fillWidth:           true
                textFieldPreferredWidth:    root._fieldWidth
                label:                      fact.shortDescription
                fact:                       root._ntrip.ntripMountpoint
                enabled:                    !root._isActive
            }

            QGCButton {
                text:       qsTr("Browse")
                enabled:    !root._isActive && root._hasHost && root._ntripMgr &&
                            root._ntripMgr.sourceTableController.fetchStatus !== NTRIPSourceTableController.InProgress
                onClicked:  root._ntripMgr.fetchMountpoints()
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            visible:            root._ntripMgr &&
                                root._ntripMgr.sourceTableController.fetchStatus === NTRIPSourceTableController.InProgress
            text:               qsTr("Fetching mountpoints…")
            color:              qgcPal.colorOrange
        }

        QGCLabel {
            Layout.fillWidth:   true
            visible:            root._ntripMgr &&
                                root._ntripMgr.sourceTableController.fetchStatus === NTRIPSourceTableController.Error
            text:               root._ntripMgr ? root._ntripMgr.sourceTableController.fetchError : ""
            color:              qgcPal.colorRed
            wrapMode:           Text.WordWrap
        }

        NTRIPMountpointList {
            Layout.fillWidth:       true
            visible:                root._ntripMgr && root._ntripMgr.sourceTableController.mountpointModel &&
                                    root._ntripMgr.sourceTableController.mountpointModel.count > 0
            model:                  root._ntripMgr ? root._ntripMgr.sourceTableController.mountpointModel : null
            selectedMountpoint:     root._ntrip.ntripMountpoint.rawValue
            onMountpointSelected:   (mountpoint) => root._ntripMgr.selectMountpoint(mountpoint)
        }
    }

    //-------------------------------------------------------------------------
    // GGA upstream (required by VRS mountpoints)
    //-------------------------------------------------------------------------
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("GGA Position Reporting")
        visible:            root._ntrip.ntripGgaPositionSource.visible || root._ntrip.ntripGgaIntervalSec.visible

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              fact.shortDescription
            fact:               root._ntrip.ntripGgaPositionSource
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    root._fieldWidth
            label:                      fact.shortDescription
            fact:                       root._ntrip.ntripGgaIntervalSec
            visible:                    fact.visible
        }
    }

    //-------------------------------------------------------------------------
    // RTCM message filter (applied in the parser — no reconnect needed)
    //-------------------------------------------------------------------------
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Options")
        visible:            root._ntrip.ntripWhitelist.visible

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    root._fieldWidth
            label:                      fact.shortDescription
            fact:                       root._ntrip.ntripWhitelist
            visible:                    fact.visible
        }
    }

    //-------------------------------------------------------------------------
    // Outbound RTCM relay
    //-------------------------------------------------------------------------
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("UDP Forwarding")
        visible:            root._ntrip.ntripUdpForwardEnabled.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               fact.shortDescription
            fact:               root._ntrip.ntripUdpForwardEnabled
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    root._fieldWidth
            label:                      fact.shortDescription
            fact:                       root._ntrip.ntripUdpTargetAddress
            visible:                    fact.visible
            enabled:                    root._ntrip.ntripUdpForwardEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    root._fieldWidth
            label:                      fact.shortDescription
            fact:                       root._ntrip.ntripUdpTargetPort
            visible:                    fact.visible
            enabled:                    root._ntrip.ntripUdpForwardEnabled.rawValue
        }
    }

    //-------------------------------------------------------------------------
    // Inbound RTCM over UDP (third-party correction source)
    //-------------------------------------------------------------------------
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("UDP RTCM Input")
        visible:            root._ntrip.rtcmUdpInputEnabled.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               fact.shortDescription
            fact:               root._ntrip.rtcmUdpInputEnabled
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    root._fieldWidth
            label:                      fact.shortDescription
            fact:                       root._ntrip.rtcmUdpInputPort
            visible:                    fact.visible
            enabled:                    root._ntrip.rtcmUdpInputEnabled.rawValue
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               fact.shortDescription
            fact:               root._ntrip.rtcmUdpValidate
            visible:            fact.visible
            enabled:            root._ntrip.rtcmUdpInputEnabled.rawValue
        }
    }
}

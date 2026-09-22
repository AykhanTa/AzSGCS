





//---------------androidkod---------------
import QtQuick

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id:     root
    width:  size
    height: size
    radius: width / 2
    color:  "transparent"
    border.color:   qgcPal.text
    border.width:   usedByMultipleVehicleList ? 1 : 0
    opacity:        vehicle && usedByMultipleVehicleList && !vehicle.armed ? 0.5 : 1

    property real size:                         _defaultSize
    property var  vehicle:                      null
    property bool usedByMultipleVehicleList:    false

    // ✅ yalnız halqa göstərmək üçün
    property bool ringOnly:                     false

    property real _defaultSize:                 usedByMultipleVehicleList ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 10
    property real _sizeRatio:                   (usedByMultipleVehicleList || ScreenTools.isTinyScreen) ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:                    ScreenTools.defaultFontPointSize * _sizeRatio < 8 ? 8 : ScreenTools.defaultFontPointSize * _sizeRatio
    property real _heading:                     vehicle ? vehicle.heading.rawValue : 0
    property real _headingToHome:               vehicle ? vehicle.headingToHome.rawValue : 0
    property real _groundSpeed:                 vehicle ? vehicle.groundSpeed.rawValue : 0
    property real _headingToNextWP:             vehicle ? vehicle.headingToNextWP.rawValue : 0
    property real _courseOverGround:            vehicle ? vehicle.gps.courseOverGround.rawValue : 0
    property var  _flyViewSettings:             QGroundControl.settingsManager.flyViewSettings
    property bool _showAdditionalIndicators:    _flyViewSettings.showAdditionalIndicatorsCompass.value && !usedByMultipleVehicleList && !ringOnly
    property bool _lockNoseUpCompass:           _flyViewSettings.lockNoseUpCompass.value && !usedByMultipleVehicleList

    function showCOG(){
        if (ringOnly) return false
        if (_groundSpeed < 0.5) return false
        return vehicle && _showAdditionalIndicators
    }

    function showHeadingHome() {
        if (ringOnly) return false
        return vehicle && _showAdditionalIndicators && !isNaN(_headingToHome)
    }

    function showHeadingToNextWP() {
        if (ringOnly) return false
        return vehicle && _showAdditionalIndicators && !isNaN(_headingToNextWP)
    }

    function translateCenterToAngleX(radius, angle) {
        return radius * Math.sin(angle * (Math.PI / 180))
    }

    function translateCenterToAngleY(radius, angle) {
        return -radius * Math.cos(angle * (Math.PI / 180))
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Item {
        id:             rotationParent
        anchors.fill:   parent

        transform: Rotation {
            origin.x:       rotationParent.width  / 2
            origin.y:       rotationParent.height / 2
            angle:         _lockNoseUpCompass ? -_heading : 0
        }

        CompassDial {
            anchors.fill:   parent
            visible:        !usedByMultipleVehicleList
        }

        CompassHeadingIndicator {
            compassSize:    size
            heading:        _heading
            simplified:     usedByMultipleVehicleList
        }

        Image {
            id:                 cogPointer
            source:             "/qmlimages/cOGPointer.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height
            visible:            showCOG()

            transform: Rotation {
                origin.x:   cogPointer.width  / 2
                origin.y:   cogPointer.height / 2
                angle:      _courseOverGround
            }
        }

        Image {
            id:                 nextWPPointer
            source:             "/qmlimages/compassDottedLine.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height
            visible:            showHeadingToNextWP()

            transform: Rotation {
                origin.x:   nextWPPointer.width  / 2
                origin.y:   nextWPPointer.height / 2
                angle:      _headingToNextWP
            }
        }

        Rectangle {
            width:              Math.max(label.contentWidth, label.contentHeight)
            height:             width
            color:              qgcPal.mapIndicator
            radius:             width / 2
            anchors.centerIn:   parent
            visible:            showHeadingHome()

            QGCLabel {
                id:                 label
                text:               qsTr("L")
                font.bold:          true
                color:              qgcPal.text
                anchors.centerIn:   parent
            }

            transform: Translate {
                property double _angle: _headingToHome
                x: translateCenterToAngleX(parent.width / 2, _angle)
                y: translateCenterToAngleY(parent.height / 2, _angle)
            }
        }
    }

    // Əlavə headingDisplay yalnız ringOnly=false olanda
    Rectangle {
        id: headingDisplay
        visible: !ringOnly

        width: headingLabel.contentWidth + 20
        height: 28
        color: "#000000"
        opacity: 0.85
        radius: 3
        border.color: "#ffffff"
        border.width: 1
        anchors.left: parent.right
        anchors.leftMargin: -50
        anchors.top: parent.bottom
        anchors.topMargin: -280

        QGCLabel {
            id: headingLabel
            anchors.centerIn: parent
            text: vehicle && !usedByMultipleVehicleList ? Math.round(_heading) + "°" : "---"
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
            font.family: "Monospace"
        }
    }
}




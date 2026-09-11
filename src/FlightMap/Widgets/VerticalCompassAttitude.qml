


// //------isleyenkod-----------

// // import QtQuick

// // import QGroundControl
// // import QGroundControl.Controls


// // import QGroundControl.FlightMap

// // Rectangle {
// //     // Global property'e bağlı görünürlük
// //     property bool showFlightPanel: mainWindow.showFlightPanel

// //     //------------------------------------------------------------------------------------------------------------------------------------------------------
// //     width:  ScreenTools.defaultFontPixelHeight * 17.1 // 🔥 GENİŞLİK ARTIRILDI
// //     height: _outerRadius * 2.1
// //     radius: 0
// //     color:  "transparent"
// //     visible: showFlightPanel  // Global property'e bağlı
// //    /* border.color: "white"      // Border rengi
// //     border.width: 1      */      // Border kalınlığı



// //     anchors.left: parent.left
// //     anchors.leftMargin: 0
// //     anchors.top: parent.top
// //     anchors.topMargin: 50 // Yukarıdan 10px boşluk

// //     property real extraInset:           0
// //     property real extraValuesWidth:     _outerRadius

// //     property real _outerMargin: (width * 0.05) / 2
// //     property real _outerRadius: width / 2
// //     property real _innerRadius: ScreenTools.defaultFontPixelHeight * 5  // 🔥 SABİT DEĞER

// //     DeadMouseArea {
// //         anchors.fill: parent
// //     }

// //     QGCAttitudeWidget {
// //         id:                         attitude
// //         anchors.horizontalCenter:   parent.horizontalCenter
// //         anchors.topMargin:          _outerMargin
// //         anchors.top:                parent.top
// //         size:                       (_innerRadius * 2.3)+40  // 🔥 SABİT KALACAK
// //         vehicle:                    globals.activeVehicle
// //         transform: Translate {
// //             x:-1

// //             y: 31.5//25

// //         }
// //     }

// //     QGCCompassWidget {
// //         id:                         compass
// //         anchors.horizontalCenter:   parent.horizontalCenter
// //         anchors.topMargin:          _outerMargin * 2
// //         anchors.top:                attitude.bottom
// //         size:                       (_innerRadius * 2)+104  // 🔥 SABİT KALACAK
// //         vehicle:                    globals.activeVehicle
// //         transform: Translate {
// //             y: -249//-260
// //         }
// //     }
// // }








// ///----------------------------androidkod-------------------------
// import QtQuick

// import QGroundControl
// import QGroundControl.Controls
// import QGroundControl.FlightMap

// Item {
//     id: root

//     visible: mainWindow.showFlightPanel

//     readonly property real _fontH: ScreenTools.defaultFontPixelHeight
//     readonly property real _innerRadius: _fontH * 5

//     readonly property real _baseAttitudeSize: (_innerRadius * 2.3) + 40

//     // ✅ halqalar attitude-a bir az daha yaxın
//     readonly property real _baseCompassRatio: 1.12

//     // // 1280x720 = 1.0, kiçiləndə düşür, minimum 0.70
//     // readonly property real _shrinkFactor: Math.max(
//     //                                          0.85,
//     //                                          Math.min(
//     //                                              1.0,
//     //                                              Math.min(mainWindow.width / 1280, mainWindow.height / 720)
//     //                                          )
//     //                                      )


//     readonly property real _raw: Math.min(1.0, Math.min(mainWindow.width / 1280, mainWindow.height / 720))
//     readonly property real _shrinkFactor: Math.max(0.85, 0.92 + 0.08 * _raw)


//     property real attitudeSize: _baseAttitudeSize * _shrinkFactor
//     property real compassSize:  attitudeSize * _baseCompassRatio

//     implicitWidth:  compassSize
//     implicitHeight: compassSize
//     width:  implicitWidth
//     height: implicitHeight

//     DeadMouseArea { anchors.fill: parent }

//     readonly property var _v: globals.activeVehicle
//     readonly property real _heading: _v ? _v.heading.rawValue : NaN

//     QGCAttitudeWidget {
//         id: attitude
//         anchors.centerIn: parent
//         size: root.attitudeSize
//         vehicle: globals.activeVehicle
//         z: 1
//     }

//     QGCCompassWidget {
//         id: compass
//         anchors.centerIn: parent
//         size: root.compassSize
//         vehicle: globals.activeVehicle
//         ringOnly: true
//         z: 2
//     }

//     // ✅ Sağ yuxarı: yalnız dərəcə (007 yox, 7° kimi)
//     Rectangle {
//         id: headingBox
//         visible: _v !== null
//         z: 10

//         anchors.top: parent.top
//         anchors.right: parent.right
//         anchors.topMargin: Math.max(6, root.compassSize * 0.03)
//         anchors.rightMargin: Math.max(6, root.compassSize * 0.03)

//         color: "#000000"
//         opacity: 0.85
//         radius: 4
//         border.color: "#FFFFFF"
//         border.width: 1

//         property string _hText: isNaN(_heading) ? "---" : (Math.round(_heading) + "°")

//         width: headingLabel.contentWidth + Math.max(16, root.compassSize * 0.06)
//         height: Math.max(26, root.compassSize * 0.10)

//         QGCLabel {
//             id: headingLabel
//             anchors.centerIn: parent
//             text: headingBox._hText
//             color: "#FFFFFF"
//             font.bold: true
//             font.family: "Monospace"
//             font.pixelSize: Math.max(12, root.compassSize * 0.055)
//         }
//     }
// }




import QtQuick
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

Item {
    id: root
    visible: mainWindow.showFlightPanel

    readonly property real _fontH: ScreenTools.defaultFontPixelHeight
    readonly property real _innerRadius: _fontH * 5
    readonly property real _baseAttitudeSize: (_innerRadius * 2.3) + 40
    readonly property real _baseCompassRatio: 1.12

    readonly property real _raw: Math.min(1.0, Math.min(mainWindow.width / 1280, mainWindow.height / 720))
    readonly property real _shrinkFactor: Math.max(0.85, 0.92 + 0.08 * _raw)

    property real attitudeSize: _baseAttitudeSize * _shrinkFactor
    property real compassSize:  attitudeSize * _baseCompassRatio

    implicitWidth:  compassSize
    implicitHeight: compassSize
    width:  implicitWidth
    height: implicitHeight

    DeadMouseArea { anchors.fill: parent }

    readonly property var  _v: globals.activeVehicle
    readonly property real _headingAbs: _v ? _v.heading.rawValue : NaN

    // QGC setting: lock nose up
    readonly property bool _noseUp: QGroundControl.settingsManager.flyViewSettings.lockNoseUpCompass.value

    function _norm360(a) {
        var x = a % 360
        if (x < 0) x += 360
        return x
    }

    function _angleDiffDeg(fromDeg, toDeg) {
        var d = (toDeg - fromDeg) % 360
        if (d > 180) d -= 360
        if (d < -180) d += 360
        return d
    }

    function _coordValid(c) {
        if (!c) return false
        if (typeof c.isValid === "function") return c.isValid()
        if (typeof c.isValid === "boolean")  return c.isValid
        return (c.latitude !== undefined && c.longitude !== undefined)
    }

    function _bearingDeg(fromCoord, toCoord) {
        var lat1 = fromCoord.latitude * Math.PI/180
        var lat2 = toCoord.latitude   * Math.PI/180
        var dLon = (toCoord.longitude - fromCoord.longitude) * Math.PI/180

        var y = Math.sin(dLon) * Math.cos(lat2)
        var x = Math.cos(lat1) * Math.sin(lat2) -
                Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon)

        var brng = Math.atan2(y, x) * 180/Math.PI
        return _norm360(brng)
    }

    // =========================
    // Mission: next WP bearing
    // =========================
    readonly property real _wpBearingAbs: {
        if (!_v || !_v.headingToNextWP) return NaN
        var b = _v.headingToNextWP.rawValue
        return isNaN(b) ? NaN : _norm360(b)
    }

    // =========================
    // GoTo bearing
    // =========================
    readonly property bool _goToActive: _v ? _v.goToActive : false
    readonly property var  _goToCoord:  _v ? _v.goToCoordinate : null

    readonly property real _goToBearingAbs: {
        if (!_goToActive) return NaN
        if (_v && _coordValid(_v.coordinate) && _coordValid(_goToCoord)) {
            return _bearingDeg(_v.coordinate, _goToCoord)
        }
        return NaN
    }

    // Target selection: GoTo varsa -> GoTo, yoxsa -> Mission WP
    readonly property real _targetBearingAbs: {
        if (!isNaN(_goToBearingAbs)) return _goToBearingAbs
        return _wpBearingAbs
    }

    // Attitude içində göstərəcəyimiz bucaq:
    // NoseUp ON -> relative (bearing - heading)
    // NoseUp OFF -> absolute (bearing)
    readonly property real _targetAngleDisplay: {
        if (isNaN(_targetBearingAbs)) return NaN
        if (_noseUp && !isNaN(_headingAbs)) {
            return _norm360(_targetBearingAbs - _headingAbs)
        }
        return _norm360(_targetBearingAbs)
    }

    // “on course” (üst‑üstə düşür) – rəng dəyişməsi üçün
    readonly property bool _targetOnCourse: {
        if (isNaN(_targetBearingAbs) || isNaN(_headingAbs)) return false
        return Math.abs(_angleDiffDeg(_headingAbs, _targetBearingAbs)) <= 5
    }

    // GoTo: cyan, Mission: white
    readonly property color _targetColor: (!isNaN(_goToBearingAbs) ? "#00BFFF" : "#FFFFFF")

    QGCAttitudeWidget {
        id: attitude
        anchors.centerIn: parent
        size: root.attitudeSize
        vehicle: _v
        z: 1

        // ✅ target input
        targetIndicatorEnabled: !isNaN(root._targetAngleDisplay)
        targetAngleDeg:         root._targetAngleDisplay
        targetOnCourse:         root._targetOnCourse
        targetColor:            root._targetColor
    }

    QGCCompassWidget {
        id: compass
        anchors.centerIn: parent
        size: root.compassSize
        vehicle: _v
        ringOnly: true
        z: 2
    }

    // Heading box
    Rectangle {
        id: headingBox
        visible: _v !== null
        z: 10

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Math.max(6, root.compassSize * 0.03)
        anchors.rightMargin: Math.max(6, root.compassSize * 0.03)

        color: "#000000"
        opacity: 0.85
        radius: 4
        border.color: "#FFFFFF"
        border.width: 1

        property string _hText: isNaN(_headingAbs) ? "---" : (Math.round(_headingAbs) + "°")

        width: headingLabel.contentWidth + Math.max(16, root.compassSize * 0.06)
        height: Math.max(26, root.compassSize * 0.10)

        QGCLabel {
            id: headingLabel
            anchors.centerIn: parent
            text: headingBox._hText
            color: "#FFFFFF"
            font.bold: true
            font.family: "Monospace"
            font.pixelSize: Math.max(12, root.compassSize * 0.055)
        }
    }
}

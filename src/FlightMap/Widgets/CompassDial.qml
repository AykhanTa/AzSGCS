
///------------------------------androidkod-----------------------

import QtQuick

import QGroundControl
import QGroundControl.Controls

Item {
    id: control

    readonly property real size: Math.min(width, height)

    // 2 qara halqa (həmişə görünsün) + az məsafə
    readonly property real _outerBW: Math.max(6, size * 0.032)
    readonly property real _gap:     Math.max(2, size * 0.010)   // əvvəlkindən daha az
    readonly property real _innerBW: Math.max(3, size * 0.018)

    // N/E/S/W ən kənar halqanın üzərində
    readonly property real _cardinalRadius: (size / 2) - (_outerBW * 0.52)

    // N/E/S/W biraz böyüdü
    readonly property real _fontCardinal: Math.max(13, size * 0.078)
    readonly property real _fontN:        Math.max(15, size * 0.085)

    // Vehicle-də "headingChanged" signal-ı yoxdur (heading bir Fact-dır). Ona görə
    // sınıq Connections əvəzinə birbaşa Fact.rawValue-ya declarative binding:
    // heading dəyişəndə avtomatik yenilənir.
    property real currentHeading: {
        var v = QGroundControl.multiVehicleManager.activeVehicle
        return (v && v.heading) ? v.heading.rawValue : 0
    }

    function translateCenterToAngleX(radius, angle) {
        return radius * Math.sin(angle * (Math.PI / 180))
    }

    function translateCenterToAngleY(radius, angle) {
        return -radius * Math.cos(angle * (Math.PI / 180))
    }

    // ✅ OUTER qara halqa
    Rectangle {
        anchors.centerIn: parent
        width: control.size
        height: control.size
        radius: width / 2
        color: "transparent"
        border.width: control._outerBW
        border.color: "#000000"
        opacity: 0.92
    }

    // ✅ INNER qara halqa (ikinci halqa)
    Rectangle {
        anchors.centerIn: parent
        width: control.size - 2 * (control._outerBW + control._gap)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: control._innerBW
        border.color: "#000000"
        opacity: 0.82
    }

    // ✅ Ağ tick-lər birbaşa ən kənar qara halqanın üstündə, qısa
    readonly property real _tickMajorH: Math.max(6,  control._outerBW * 0.95)
    readonly property real _tickMidH:   Math.max(5,  control._outerBW * 0.75)
    readonly property real _tickSmallH: Math.max(4,  control._outerBW * 0.60)

    readonly property real _tickMajorW: Math.max(2,  size * 0.010)
    readonly property real _tickMidW:   Math.max(1,  size * 0.007)
    readonly property real _tickSmallW: Math.max(1,  size * 0.006)

    // Major ticks (45°)
    Repeater {
        model: 8
        Rectangle {
            width: control._tickMajorW
            height: control._tickMajorH
            x: control.size / 2 - width / 2
            // tick halqanın içində otursun
            y: Math.max(1, (control._outerBW - height) / 2)
            color: "#FFFFFF"
            opacity: 0.95

            transform: Rotation {
                origin.x: width / 2
                origin.y: (control.size / 2) - y
                angle: 22.5 + (45 * index)
            }
        }
    }

    // Mid ticks (22.5°)
    Repeater {
        model: 16
        Rectangle {
            width: control._tickMidW
            height: control._tickMidH
            x: control.size / 2 - width / 2
            y: Math.max(1, (control._outerBW - height) / 2)
            color: "#FFFFFF"
            opacity: 0.65

            transform: Rotation {
                origin.x: width / 2
                origin.y: (control.size / 2) - y
                angle: 11.25 + (22.5 * index)
            }
        }
    }

    // Small ticks (11.25°)
    Repeater {
        model: 32
        Rectangle {
            width: control._tickSmallW
            height: control._tickSmallH
            x: control.size / 2 - width / 2
            y: Math.max(1, (control._outerBW - height) / 2)
            color: "#FFFFFF"
            opacity: 0.35

            transform: Rotation {
                origin.x: width / 2
                origin.y: (control.size / 2) - y
                angle: 5.625 + (11.25 * index)
            }
        }
    }

    // --- N ---
    Item {
        anchors.centerIn: parent
        QGCLabel {
            anchors.centerIn: parent
            text: "N"
            color: "#FF0000"
            font.pixelSize: control._fontN
            font.bold: true
            font.family: "Courier New"
            style: Text.Outline
            styleColor: "#000000"
        }
        transform: Translate {
            x: translateCenterToAngleX(control._cardinalRadius, 0)
            y: translateCenterToAngleY(control._cardinalRadius, 0)
        }
    }

    // --- E ---
    Item {
        anchors.centerIn: parent
        QGCLabel {
            anchors.centerIn: parent
            text: "E"
            color: "#00FF00"
            font.pixelSize: control._fontCardinal
            font.bold: true
            font.family: "Courier New"
            style: Text.Outline
            styleColor: "#000000"
        }
        transform: Translate {
            x: translateCenterToAngleX(control._cardinalRadius, 90)
            y: translateCenterToAngleY(control._cardinalRadius, 90)
        }
    }

    // --- S ---
    Item {
        anchors.centerIn: parent
        QGCLabel {
            anchors.centerIn: parent
            text: "S"
            color: "blue"
            font.pixelSize: control._fontCardinal
            font.bold: true
            font.family: "Courier New"
            style: Text.Outline
            styleColor: "#000000"
        }
        transform: Translate {
            x: translateCenterToAngleX(control._cardinalRadius, 180)
            y: translateCenterToAngleY(control._cardinalRadius, 180)
        }
    }

    // --- W ---
    Item {
        anchors.centerIn: parent
        QGCLabel {
            anchors.centerIn: parent
            text: "W"
            color: "white"
            font.pixelSize: control._fontCardinal
            font.bold: true
            font.family: "Courier New"
            style: Text.Outline
            styleColor: "#000000"
        }
        transform: Translate {
            x: translateCenterToAngleX(control._cardinalRadius, 270)
            y: translateCenterToAngleY(control._cardinalRadius, 270)
        }
    }
}

//------isleyen kod-------------

// import QtQuick
// import QtQuick.Controls

// import QGroundControl
// import QGroundControl.Controls
// // import QGroundControl.ScreenTools

// Canvas {
//     id:                 control
//     anchors.centerIn:   parent
//     width:              compassSize
//     height:             compassSize

//     property real compassSize
//     property real heading
//     property bool simplified:    false

//     property var _qgcPal: QGroundControl.globalPalette

//     // HEADING DEĞİŞİNCE YENİDEN ÇİZ
//     onHeadingChanged: {
//         control.requestPaint()
//     }
//     onPaint: {
//         var ctx = getContext("2d")

//         // Önce canvas'ı temizle
//         ctx.clearRect(0, 0, width, height)

//         ctx.strokeStyle = "#EE3424"
//         ctx.fillStyle = "#EE3424"  // 🔥 İÇİ KIRMIZI DOLU
//         ctx.lineWidth = 2  // 🔥 DAHA İNCE KENARLAR

//         // Çemberin merkezi ve yarıçapı
//         var centerX = width / 2
//         var centerY = height / 2
//         var radius = width / 2 - 12  // Kenardan biraz içerde

//         // Akrebin açısı (heading'e göre)
//         var angleRad = (heading * Math.PI) / 180

//         // Akrebin konumu - çember üzerinde
//         var pointerX = centerX + radius * Math.sin(angleRad)
//         var pointerY = centerY - radius * Math.cos(angleRad)

//         // 🔥 İÇE BAKAN ÜÇGEN - BOYUTLARI KÜÇÜLTÜLDÜ
//         var triangleSize = 8  // 🔥 DAHA KÜÇÜK ÜÇGEN (25 yerine 15)

//         // Üçgenin üç noktası - HEPSİ MERKEZE BAKACAK ŞEKİLDE
//         var point1X = pointerX - triangleSize * Math.sin(angleRad)        // 🔥 EKSİ İŞARETİ - İÇE BAKSIN
//         var point1Y = pointerY + triangleSize * Math.cos(angleRad)

//         var point2X = pointerX - triangleSize * Math.sin(angleRad + (2 * Math.PI / 3))  // 🔥 EKSİ İŞARETİ
//         var point2Y = pointerY + triangleSize * Math.cos(angleRad + (2 * Math.PI / 3))

//         var point3X = pointerX - triangleSize * Math.sin(angleRad + (4 * Math.PI / 3))  // 🔥 EKSİ İŞARETİ
//         var point3Y = pointerY + triangleSize * Math.cos(angleRad + (4 * Math.PI / 3))

//         // 🔥 İÇİ KIRMIZI DOLU ÜÇGEN ÇİZİMİ
//         ctx.strokeStyle = "#EE3424"
//         ctx.fillStyle = "#EE3424"  // 🔥 İÇİ KIRMIZI
//         ctx.lineWidth = 2  // 🔥 İNCE KENARLAR

//         ctx.beginPath()
//         ctx.moveTo(point1X, point1Y)    // Nokta 1
//         ctx.lineTo(point2X, point2Y)    // Nokta 2
//         ctx.lineTo(point3X, point3Y)    // Nokta 3
//         ctx.closePath()                 // Üçgeni tamamla
//         ctx.fill()                      // 🔥 İÇİNİ KIRMIZI DOLDUR
//         ctx.stroke()                    // KENARLARI ÇİZ

//         // 🔥 MERKEZ NOKTASI - DAHA KÜÇÜK
//         ctx.fillStyle = "#EE3424"
//         ctx.beginPath()
//         ctx.arc(pointerX, pointerY, 4, 0, 2 * Math.PI)  // 🔥 6 yerine 4
//         ctx.fill()
//     }
// }
















//-------------------androidkod-----------------
import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

Canvas {
    id:                 control
    anchors.centerIn:   parent
    width:              compassSize
    height:             compassSize

    property real compassSize
    property real heading
    property bool simplified:    false

    property var _qgcPal: QGroundControl.globalPalette

    onHeadingChanged: control.requestPaint()
    onWidthChanged:   control.requestPaint()
    onHeightChanged:  control.requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        ctx.strokeStyle = "#EE3424"
        ctx.fillStyle = "#EE3424"
        ctx.lineWidth = 2

        var centerX = width / 2
        var centerY = height / 2
        var radius = width / 2 - 12

        var angleRad = (heading * Math.PI) / 180

        var pointerX = centerX + radius * Math.sin(angleRad)
        var pointerY = centerY - radius * Math.cos(angleRad)

        var triangleSize = 8

        var point1X = pointerX - triangleSize * Math.sin(angleRad)
        var point1Y = pointerY + triangleSize * Math.cos(angleRad)

        var point2X = pointerX - triangleSize * Math.sin(angleRad + (2 * Math.PI / 3))
        var point2Y = pointerY + triangleSize * Math.cos(angleRad + (2 * Math.PI / 3))

        var point3X = pointerX - triangleSize * Math.sin(angleRad + (4 * Math.PI / 3))
        var point3Y = pointerY + triangleSize * Math.cos(angleRad + (4 * Math.PI / 3))

        ctx.beginPath()
        ctx.moveTo(point1X, point1Y)
        ctx.lineTo(point2X, point2Y)
        ctx.lineTo(point3X, point3Y)
        ctx.closePath()
        ctx.fill()
        ctx.stroke()

        ctx.fillStyle = "#EE3424"
        ctx.beginPath()
        ctx.arc(pointerX, pointerY, 4, 0, 2 * Math.PI)
        ctx.fill()
    }
}

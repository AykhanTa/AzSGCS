// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// import QtQuick
// import QtQuick.Window
// import QtQuick.Controls
// import QtQuick.Templates as T

// import QGroundControl


// import QGroundControl.Controls

// T.ComboBox {
//     id:             control
//     padding:        ScreenTools.comboBoxPadding
//     spacing:        ScreenTools.defaultFontPixelWidth
//     font.pointSize: ScreenTools.defaultFontPointSize
//     font.family:    ScreenTools.normalFontFamily
//     implicitWidth:  Math.max(background ? background.implicitWidth : 0,
//                              contentItem.implicitWidth + leftPadding + rightPadding + padding)
//     implicitHeight: Math.max(background ? background.implicitHeight : 0,
//                              Math.max(contentItem.implicitHeight, indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
//     baselineOffset: contentItem.y + text.baselineOffset
//     leftPadding:    padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
//     rightPadding:   padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width)

//     property bool   centeredLabel:  false
//     property bool   sizeToContents: false
//     property string alternateText:  ""

//     property real   _popupWidth:    width
//     property bool   _onCompleted:   false
//     property bool   _showBorder:    qgcPal.globalTheme === QGCPalette.Light

//     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

//     TextMetrics {
//         id:                 textMetrics
//         font.family:        control.font.family
//         font.pointSize:     control.font.pointSize
//     }

//     ItemDelegate {
//         id:             itemDelegateMetrics
//         visible:        false
//         font.family:    control.font.family
//         font.pointSize: control.font.pointSize
//     }

//     function _calcPopupWidth() {
//         if (_onCompleted && sizeToContents && model) {
//             var largestTextWidth = 0
//             for (var i = 0; i < model.length; i++){
//                 textMetrics.text = control.textRole ? model[i][control.textRole] : model[i]
//                 largestTextWidth = Math.max(textMetrics.width, largestTextWidth)
//             }
//             _popupWidth = largestTextWidth + itemDelegateMetrics.leftPadding + itemDelegateMetrics.rightPadding
//         }
//     }

//     onModelChanged: _calcPopupWidth()

//     Component.onCompleted: {
//         _onCompleted = true
//         _calcPopupWidth()
//     }

//     // The items in the popup
//     delegate: ItemDelegate {
//         width:  _popupWidth
//         height: Math.round(popupItemMetrics.height * 1.75)

//         property string _text: control.textRole ?
//                                     (model.hasOwnProperty(control.textRole) ? model[control.textRole] : modelData[control.textRole]) :
//                                     modelData

//         TextMetrics {
//             id:             popupItemMetrics
//             font:           control.font
//             text:           _text
//         }

//         contentItem: Text {
//             text:                   _text
//             font:                   control.font
//             //color:                  control.currentIndex === index ? qgcPal.buttonHighlightText : qgcPal.buttonText
//             color:"white"
//             verticalAlignment:      Text.AlignVCenter
//         }

//         background: Rectangle {
//             color:                  control.currentIndex === index ? qgcPal.buttonHighlight : qgcPal.button
//         }

//         highlighted:                control.highlightedIndex === index
//     }

//     indicator: QGCColoredImage {
//         anchors.rightMargin:    control.padding
//         anchors.right:          parent.right
//         anchors.verticalCenter: parent.verticalCenter
//         height:                 ScreenTools.defaultFontPixelWidth
//         width:                  height
//         source:                 "/qmlimages/arrow-down.png"
//         color:                  qgcPal.buttonText
//     }

//     // The label of the button
//     contentItem: QGCLabel {
//         id:                         text
//         anchors.verticalCenter:     parent.verticalCenter
//         anchors.horizontalCenter:   centeredLabel ? parent.horizontalCenter : undefined
//         text:                       control.alternateText === "" ? control.currentText : control.alternateText
//         font:                       control.font
//         color:                      qgcPal.buttonText
//     }

//     background: Rectangle {
//         color:          qgcPal.button
//         border.color:   qgcPal.buttonBorder
//         border.width:   _showBorder ? 1 : 0
//         radius:         ScreenTools.buttonBorderRadius
//     }

//     popup: T.Popup {
//         x:              control.width - _popupWidth
//         y:              control.height
//         width:          _popupWidth
//         height:         Math.min(contentItem.implicitHeight, control.Window.height - topMargin - bottomMargin)
//         topMargin:      6
//         bottomMargin:   6

//         contentItem: ListView {
//             clip:                   true
//             implicitHeight:         contentHeight
//             model:                  control.delegateModel
//             currentIndex:           control.highlightedIndex
//             highlightMoveDuration:  0

//             Rectangle {
//                 z:              10
//                 width:          parent.width
//                 height:         parent.height
//                 color:          "transparent"
//                 border.color:   qgcPal.text
//             }

//             T.ScrollIndicator.vertical: ScrollIndicator { }
//         }

//         background: Rectangle {
//             color: qgcPal.window
//         }
//     }
// }







import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Templates as T

import QGroundControl
import QGroundControl.Controls

T.ComboBox {
    id:             control
    padding:        ScreenTools.comboBoxPadding
    spacing:        ScreenTools.defaultFontPixelWidth
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    _az ? AzTheme.fontFamily : ScreenTools.normalFontFamily

    // Mətn ox ilə sıxılmasın deyə bir az əlavə nəfəslik saxlanılır
    implicitWidth:  Math.max(background ? background.implicitWidth : 0,
                             contentItem.implicitWidth + leftPadding + rightPadding + padding
                             + ScreenTools.defaultFontPixelWidth)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             Math.max(contentItem.implicitHeight, indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)

    baselineOffset: contentItem.y + text.baselineOffset
    leftPadding:    padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding:   padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width)

    property bool   centeredLabel:  false
    property bool   sizeToContents: false
    property string alternateText:  ""

    // popup ölçüləri (limitli)
    property real   _popupWidth:    width
    property bool   _onCompleted:   false
    property bool   _showBorder:    qgcPal.globalTheme === QGCPalette.Light
    // The new design's look for screens that ask for it by declaring
    // `readonly property bool azInputStyle: true` on their root (the Plan view so far);
    // everywhere else the control keeps its old look.
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    // Popup üçün limitlər
    readonly property real _popupMaxWidth:  Math.max(control.width, Math.min(control.Window ? (control.Window.width - 12) : 600, ScreenTools.defaultFontPixelWidth * 42))
    readonly property real _popupMaxHeight: Math.max(ScreenTools.defaultFontPixelHeight * 10,
                                                     Math.min(control.Window ? (control.Window.height * 0.55) : 320,
                                                              ScreenTools.defaultFontPixelHeight * 18))

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    TextMetrics {
        id:                 textMetrics
        font.family:        control.font.family
        font.pointSize:     control.font.pointSize
        // Seçili bənd delegate-də qalın göstərilir; en hesablaması da qalın
        // ölçməlidir, əks halda ən enli (seçili) bənd kəsilir.
        font.bold:          true
    }

    ItemDelegate {
        id:             itemDelegateMetrics
        visible:        false
        font.family:    control.font.family
        font.pointSize: control.font.pointSize
    }

    function _clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    // Popup ən azı bir neçə simvolluq yer saxlamalıdır: dar combo-larda
    // (məs. "1"/"2" seçimi) bənd mətni doldurma altında tamamilə itirdi.
    readonly property real _popupMinWidth: Math.max(control.width,
                                                    ScreenTools.defaultFontPixelWidth * 8 + itemPad * 2)

    function _applyPopupWidth(w) {
        var minW = _popupMinWidth
        var maxW = Math.max(minW, _popupMaxWidth)
        return _clamp(Math.max(minW, w), minW, maxW)
    }

    function _calcPopupWidth() {
        if (_onCompleted && sizeToContents && model) {
            var largestTextWidth = 0

            // model JS array olarsa length, ListModel olarsa count ola bilər
            var count = (model.count !== undefined) ? model.count : model.length
            if (count === undefined) {
                _popupWidth = _applyPopupWidth(control.width)
                return
            }

            for (var i = 0; i < count; i++) {
                var v = (model.get !== undefined) ? model.get(i) : model[i]
                textMetrics.text = control.textRole && v ? v[control.textRole] : v
                largestTextWidth = Math.max(textMetrics.width, largestTextWidth)
            }

            // Bənd doldurması (itemPad, hər iki tərəf) + popup daxili doldurması +
            // yaşıl sol kənar üçün nəfəslik. Bol götürülür ki, heç bir bənd kəsilməsin.
            _popupWidth = _applyPopupWidth(largestTextWidth + itemPad * 3 + ScreenTools.defaultFontPixelWidth * 1.5)
        } else {
            _popupWidth = _applyPopupWidth(control.width)
        }
    }

    onModelChanged:       _calcPopupWidth()
    onCountChanged:       _calcPopupWidth()
    onCurrentTextChanged: _calcPopupWidth()
    onWidthChanged: _popupWidth = _applyPopupWidth(_popupWidth)

    Component.onCompleted: {
        _onCompleted = true
        _calcPopupWidth()
    }

    // Popup item delegate
    delegate: ItemDelegate {
        // Popup-un daxili doldurması səbəbindən ListView _popupWidth-dən bir az dardır;
        // delegate onun eninə uyğunlaşır ki, mətn kəsilməsin.
        width:  ListView.view ? ListView.view.width : control._popupWidth

        // əvvəlki 1.75 çox böyük edirdi → daha kompakt
        height: Math.max(ScreenTools.defaultFontPixelHeight * 1.8,
                         Math.round(popupItemMetrics.height * 1.35))

        property string _text: {
            if (!control.textRole) {
                return String(modelData)
            }
            if (modelData && modelData[control.textRole] !== undefined) {
                return String(modelData[control.textRole])
            }
            if (model && model[control.textRole] !== undefined) {
                return String(model[control.textRole])
            }
            return String(modelData)
        }

        TextMetrics {
            id:     popupItemMetrics
            font:   control.font
            text:   _text
        }

        readonly property bool _isCurrent: control.currentIndex === index
        readonly property bool _isHot:     control.highlightedIndex === index || itemHover.hovered

        HoverHandler { id: itemHover }

        contentItem: Text {
            text:               _text
            // ❗ `font:` qrupu ilə `font.bold:` bir yerdə təyin edilə bilməz —
            //    ona görə lazımi xüsusiyyətlər ayrı-ayrı verilir.
            font.family:        control.font.family
            font.pointSize:     control.font.pointSize
            font.bold:          _isCurrent
            color:              control._az ? AzTheme.textCard : "#FFFFFF"
            leftPadding:        control.itemPad
            rightPadding:       control.itemPad
            verticalAlignment:  Text.AlignVCenter
            elide:              Text.ElideRight
        }

        background: Rectangle {
            radius: control._az ? AzTheme.px(6) : 6
            color:  _isHot ? (control._az ? Qt.rgba(1, 1, 1, 0.06) : "#3A3A3A") : "transparent"

            Behavior on color { ColorAnimation { duration: 100 } }

            // Hazırda seçili bənd yaşıl sol kənarla işarələnir
            Rectangle {
                anchors.left:           parent.left
                anchors.leftMargin:     2
                anchors.verticalCenter: parent.verticalCenter
                width:                  3
                height:                 parent.height * 0.6
                radius:                 1.5
                color:                  control.accentColor
                visible:                _isCurrent
            }
        }

        highlighted: control.highlightedIndex === index
    }

    property color accentColor: _az ? AzTheme.statusGreen : "#00C853"
    property real  itemPad:     Math.max(8, ScreenTools.defaultFontPixelWidth * 0.9)

    // ✅ parent yox → control (null problemi bitir)
    indicator: QGCColoredImage {
        anchors.rightMargin:    control.padding
        anchors.right:          control.right
        anchors.verticalCenter: control.verticalCenter
        height:                 control._az ? AzTheme.px(14) : ScreenTools.defaultFontPixelWidth
        width:                  height
        source:                 control._az ? "qrc:/res/AZSHIELD_ICON/v2/popup_chevron.svg" : "/qmlimages/arrow-down.png"
        color:                  control.popup.visible ? control.accentColor : (control._az ? AzTheme.textSecondary : "#E0E0E0")
        rotation:               control.popup.visible ? 180 : 0

        Behavior on rotation { NumberAnimation { duration: 140 } }
    }

    // Button label
    contentItem: QGCLabel {
        id:                         text
        anchors.verticalCenter:     control.verticalCenter
        anchors.horizontalCenter:   centeredLabel ? control.horizontalCenter : undefined
        text:                       control.alternateText === "" ? control.currentText : control.alternateText
        font:                       control.font
        color:                      control._az ? AzTheme.textCard : "#FFFFFF"
        elide:                      Text.ElideRight
    }

    HoverHandler { id: comboHover; enabled: control.enabled }

    // Az: the dark pill of the top bar panels; blue outline while its list is open
    background: Rectangle {
        color:          control._az ? AzTheme.pillBottom
                                    : (control.down ? "#454545"
                                                    : (control.enabled && comboHover.hovered ? "#3F3F3F" : "#333333"))
        border.color:   control._az ? (control.popup.visible ? AzTheme.activeBorder
                                                             : (control.enabled && comboHover.hovered ? AzTheme.cardHoverBorder : AzTheme.panelBorder))
                                    : ((control.enabled && (comboHover.hovered || control.popup.visible))
                                       ? control.accentColor : "#5D5B5B")
        border.width:   1
        radius:         control._az ? AzTheme.px(8) : 6
        opacity:        control.enabled ? 1.0 : 0.5

        Behavior on color        { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    popup: T.Popup {
        // ❗ Bəzi modellər (məs. factValueNames) eyni obyekt kimi yenilənir, ona görə
        //    onModelChanged işə düşmür və en köhnə qalırdı. Hər açılışda yenidən ölçürük.
        onAboutToShow: control._calcPopupWidth()

        // Sağa hizalanır, amma ekrandan kənara çıxmır
        x:              Math.max(-control.x, control.width - control._popupWidth)
        y:              control.height
        width:          control._popupWidth

        // ✅ Hündürlük limit: çox böyük dropdown olmasın
        height:         Math.min(contentItem.implicitHeight, control._popupMaxHeight)

        topMargin:      6
        bottomMargin:   6

        contentItem: ListView {
            clip:                   true
            implicitHeight:         contentHeight
            model:                  control.delegateModel
            currentIndex:           control.highlightedIndex
            highlightMoveDuration:  0

            T.ScrollIndicator.vertical: ScrollIndicator { }
        }

        padding: control.itemPad * 0.5

        background: Rectangle {
            color:          control._az ? AzTheme.menuSelectedBottom : "#242424"
            border.color:   control._az ? AzTheme.panelBorder : "#6E6E6E"
            border.width:   1
            radius:         control._az ? AzTheme.px(AzTheme.popupRadius) : 10
        }
    }
}

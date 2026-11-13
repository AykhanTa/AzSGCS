
import QtQuick
import QtQuick.Controls

import QGroundControl

import QGroundControl.Controls


/// Base view control for all Analyze pages
Item {
    anchors.fill:               parent
    anchors.margins:            _az ? AzTheme.px(ScreenTools.isMobile ? 12 : 20) : ScreenTools.defaultFontPixelWidth

    property alias  pageComponent:      pageLoader.sourceComponent
    /// The instantiated page, so a host can talk to it before popping it out.
    property alias  pageItem:           pageLoader.item
    property alias  pageName:           pageNameLabel.text
    property alias  pageDescription:    pageDescriptionLabel.text
    property alias  headerComponent:    headerLoader.sourceComponent
    property real   availableWidth:     width  - pageLoader.x
    property real   availableHeight:    height - mainContent.y
    property bool   allowPopout:        false
    property bool   popped:             false
    property real   _margins:           _az ? AzTheme.px(6) : ScreenTools.defaultFontPixelHeight * 0.5

    // The new design's look for screens that ask for it by declaring
    // `readonly property bool azInputStyle: true` (see QGCLabel._az).
    readonly property bool _az: typeof azInputStyle !== "undefined" && azInputStyle === true

    signal popout()

    Loader {
        id:                     headerLoader
        anchors.topMargin:      _margins
        anchors.top:            parent.top
        anchors.left:           parent.left
        anchors.rightMargin:    _margins
        anchors.right:          floatIcon.left
        visible:                !ScreenTools.isShortScreen && headerLoader.sourceComponent !== null
    }

    Column {
        id:                     headingColumn
        anchors.topMargin:      _margins
        anchors.top:            parent.top
        anchors.left:           parent.left
        anchors.rightMargin:    _margins
        anchors.right:          floatIcon.visible ? floatIcon.left : parent.right
        spacing:                _margins
        visible:                !ScreenTools.isShortScreen && headerLoader.sourceComponent === null
        QGCLabel {
            id:                 pageNameLabel
            font.pointSize:     ScreenTools.largeFontPointSize
            visible:            !popped && !_az
        }
        QGCLabel {
            id:                 pageDescriptionLabel
            anchors.left:       parent.left
            anchors.right:      parent.right
            wrapMode:           Text.WordWrap
            visible:            !_az
        }

        // The page header of the setup pages
        Text {
            anchors.left:       parent.left
            anchors.right:      parent.right
            text:               pageNameLabel.text
            visible:            _az && !popped && text !== ""
            color:              AzTheme.textCard
            font.family:        AzTheme.fontFamily
            font.weight:        Font.Medium
            font.pixelSize:     AzTheme.fontPx(ScreenTools.isMobile ? 18 : 20)
            wrapMode:           Text.WordWrap
        }
        Text {
            anchors.left:       parent.left
            anchors.right:      parent.right
            text:               pageDescriptionLabel.text
            visible:            _az && text !== ""
            color:              AzTheme.textSecondary
            font.family:        AzTheme.fontFamily
            font.pixelSize:     AzTheme.fontPx(13)
            wrapMode:           Text.WordWrap
        }
    }

    Item {
        id:                     mainContent
        anchors.topMargin:      _az ? AzTheme.px(16) : ScreenTools.defaultFontPixelHeight
        anchors.top:            headerLoader.sourceComponent === null ? (headingColumn.visible ? headingColumn.bottom : parent.top) : headerLoader.bottom
        anchors.bottom:         parent.bottom
        anchors.left:           parent.left
        anchors.right:          parent.right
        clip:                   true
        Loader {
            id:                 pageLoader
            anchors.fill: parent
        }
    }

    QGCColoredImage {
        id:                     floatIcon
        anchors.verticalCenter: headerLoader.visible ? headerLoader.verticalCenter : headingColumn.verticalCenter
        anchors.right:          parent.right
        width:                  ScreenTools.defaultFontPixelHeight * 2
        height:                 width
        sourceSize.width:       width
        source:                 "/qmlimages/FloatingWindow.svg"
        fillMode:               Image.PreserveAspectFit
        color:                  _az ? AzTheme.textCard : qgcPal.text
        visible:                allowPopout && !popped && !ScreenTools.isMobile
        MouseArea {
            anchors.fill:   parent
            onClicked:      popout()
        }
    }
}

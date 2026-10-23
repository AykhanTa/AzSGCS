import QtQuick

// A section heading inside a panel ("Aparat mesajları", "Ümumi Vəziyyət").
Text {
    width:          parent ? parent.width : implicitWidth
    elide:          Text.ElideRight
    color:          AzTheme.textCard
    font.family:    AzTheme.fontFamily
    font.pixelSize: AzTheme.fontPx(AzTheme.popupTitleSize)
}

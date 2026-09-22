










import QtQuick
import QtQuick.Controls
import QGroundControl
import QGroundControl.Controls

Rectangle {
    id:         _root
    radius:     ScreenTools.defaultFontPixelWidth / 2
    color:      "#3D3B3B"
    border.color:"white"
    border.width:1

    // 3x3 (3 sütun) görünüş üçün parametrlər
    property alias  model:              repeater.model
    property alias  title:              titleLabel.text
    property var    fontSize:           ScreenTools.smallFontPointSize
    property real   maxHeight

    // Grid parametrləri
    property int    columns:            3
    property real   _hSpacing:          ScreenTools.defaultFontPixelWidth * 0.4
    property real   _vSpacing:          ScreenTools.defaultFontPixelWidth * 0.4
    property real   _margins:           ScreenTools.defaultFontPixelWidth * 0.8 // Kənar boşluqları biraz artırdım

    // ✅ DƏYİŞİKLİK: buttonWidth və buttonHeight artıq statik deyil, dinamik olaraq ümumi panel ölçüsünə görə hesablanır.
    // Beləliklə, panel böyüdükcə düymələr də böyüyəcək və kənarlarda bərabər boşluq qalacaq.
    property real   buttonWidth:        (_root.width - 2 * _margins - (columns - 1) * _hSpacing) / columns

    // Hündürlüyü əgər 2 sətirdirsə (title ilə birlikdə) ona görə bölürük, əgər təkcə hündürlük vermək istəsəniz belə yaza bilərsiniz:
    // (Aşağıdakı düsturda ümumi hündürlükdən marginləri çıxıb 2 sətirə (title+düymələr) bölürük. Əgər title yoxdursa, başqa məntiq lazımdır. Standart 2 sətir sayılır).
    property real   buttonHeight:       (_root.height - 2 * _margins - _vSpacing) / 2

    // Drop panel
    property var    _dropPanel:         dropPanel

    // ✅ Ölçüləri parent-dən (FlyViewToolStrip-dən) alsın deyə implicitWidth/Height-i dinamik saxlayırıq və ya sadəcə anxcors.fill veririk
    // Burada width/height hesablamasını sildim, çünki xaricdən ölçü verilir.
    // width və height-i FlyViewToolStrip təyin edəcək.

    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: 2
        color: "black"
    }

    function simulateClick(buttonIndex) {
        // 0-cı uşaq titleLabel-dir, ona görə +1
        buttonIndex = buttonIndex + 1
        var button = toolStripGrid.children[buttonIndex]
        if (!button)
            return
        if (button.checkable) {
            button.checked = !button.checked
        }
        button.clicked()
    }

    signal dropped(int index)

    DeadMouseArea {
        anchors.fill: parent
    }

    QGCFlickable {
        id:                 flickable
        anchors.margins:    _margins
        anchors.fill:       parent

        // Kontent en/hündürlük həmişə ən azı görünən sahə qədər olsun
        contentWidth:       Math.max(toolStripGrid.width, width - 2*_margins)
        contentHeight:      Math.max(toolStripGrid.height, height - 2*_margins)
        flickableDirection: Flickable.AutoFlickDirection
        clip:               true

        Grid {
            id:                 toolStripGrid
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter
            columns:                  _root.columns
            rowSpacing:               _vSpacing
            columnSpacing:            _hSpacing

            // 1-ci hüceyrə: title (əgər varsa)
            QGCLabel {
                id:                     titleLabel
                width:                  buttonWidth
                height:                 buttonHeight
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.mediumFontPointSize
                visible:                title != ""
            }

            // Qalan hüceyrələr: ToolStrip düymələri
            Repeater {
                id: repeater

                ToolStripHoverButton {
                    id:                 buttonTemplate
                    // ✅ Dinamik hesablanmış ölçülər istifadə olunur
                    width:              buttonWidth
                    height:             buttonHeight
                    radius:             ScreenTools.defaultFontPixelWidth / 2
                    fontPointSize:      ScreenTools.defaultFontPointSize
                    toolStripAction:    modelData
                    dropPanel:          _dropPanel
                    onDropped: (index) => _root.dropped(index)

                    onCheckedChanged: {
                        if (checked) {
                            for (var i = 0; i < repeater.count; i++) {
                                if (i !== index) {
                                    var b = repeater.itemAt(i)
                                    if (b && b.checked) {
                                        b.checked = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ToolStripDropPanel {
        id:         dropPanel
        toolStrip:  _root
    }
}

import QtQuick

// A bordered box of rows in a panel ("RC Siqnalı" table, message and problem lists).
// The rows go in as children; a 1 px line is drawn between each pair of visible rows.
Rectangle {
    id: control

    default property alias rows: rowColumn.data
    property real verticalPadding: 0
    property real dividerInset:    0
    property bool dividers:        true

    implicitHeight: rowColumn.implicitHeight + 2 * verticalPadding
    radius:         AzTheme.px(AzTheme.groupRadius)
    color:          AzTheme.groupFill
    border.width:   1
    border.color:   AzTheme.groupBorder

    Column {
        id:     rowColumn
        y:      control.verticalPadding
        width:  control.width
    }

    Repeater {
        model: control.dividers ? rowColumn.children.length : 0

        Rectangle {
            readonly property Item row: rowColumn.children[index]

            visible: !!row && row.visible && row.height > 0 && _hasVisibleRowAfter(index)
            x:       control.dividerInset
            y:       row ? rowColumn.y + row.y + row.height : 0
            width:   control.width - 2 * control.dividerInset
            height:  1
            color:   AzTheme.groupBorder
        }
    }

    function _hasVisibleRowAfter(index) {
        var children = rowColumn.children
        for (var i = index + 1; i < children.length; ++i) {
            if (children[i].visible && children[i].height > 0) {
                return true
            }
        }
        return false
    }
}

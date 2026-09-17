import QtQuick
import qs

Item {
    property string text: ""
    width: parent ? parent.width : Theme.panelWidth
    height: Theme.rowHeight
    Label {
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        text: parent.text
        dim: true
    }
}

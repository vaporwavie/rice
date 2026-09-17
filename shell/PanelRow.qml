import QtQuick
import qs

Item {
    id: root
    property string text: ""
    property string icon: ""
    property string trailing: ""
    property bool active: false
    signal clicked()

    width: parent ? parent.width : Theme.panelWidth
    height: Theme.rowHeight

    Rectangle {
        anchors.fill: parent
        color: area.containsMouse && root.enabled ? Theme.bgElev : "transparent"
    }
    Label {
        id: lead
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        text: root.icon
        icon: true
        visible: root.icon !== ""
        color: root.active ? Theme.accent : Theme.fg
    }
    Label {
        anchors {
            left: lead.visible ? lead.right : parent.left
            leftMargin: lead.visible ? 10 : 6
            right: tail.left
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        text: root.text
        color: !root.enabled ? Theme.muted : (root.active ? Theme.accent : Theme.fg)
    }
    Label {
        id: tail
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        text: root.trailing
        dim: true
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}

import QtQuick
import qs

Item {
    id: root
    property string text: ""
    property string icon: ""
    property string trailing: ""
    property bool active: false
    property bool selected: false
    readonly property bool navigable: true
    readonly property bool lit: selected || area.containsMouse
    signal clicked()
    function activate() { clicked() }

    width: parent ? parent.width : Theme.panelWidth
    height: Theme.rowHeight

    Rectangle {
        anchors.fill: parent
        color: root.lit && root.enabled ? Theme.bgElev : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.quick; easing.type: Theme.easing } }
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
        color: !root.enabled ? Theme.muted : (root.active || root.lit ? Theme.accent : Theme.fg)
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

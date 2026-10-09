import QtQuick
import qs

Item {
    id: root
    property real value: 0
    property real max: 1
    property bool muted: false
    property bool selected: false
    readonly property bool navigable: true
    signal moved(real value)
    function nudge(direction) { moved(Math.max(0, Math.min(max, value + max * 0.05 * direction))) }

    width: parent ? parent.width : Theme.panelWidth
    height: Theme.rowHeight

    Rectangle {
        anchors.fill: parent
        color: root.selected ? Theme.bgElev : "transparent"
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 6; rightMargin: 6 }
        height: 4
        color: root.selected ? Theme.lineStrong : Theme.bgElev
        Rectangle {
            width: parent.width * Math.min(1, root.value / root.max)
            height: parent.height
            color: root.muted ? Theme.muted : Theme.accent
        }
    }
    MouseArea {
        anchors.fill: parent
        function set(x) { root.moved(Math.max(0, Math.min(root.max, (x - 6) / (width - 12) * root.max))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
        onWheel: wheel => root.nudge(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}

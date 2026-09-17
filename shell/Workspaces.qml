import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs

RowLayout {
    id: root
    property var bar
    spacing: 0

    function list() {
        var out = []
        var all = Hyprland.workspaces.values
        for (var i = 0; i < all.length; i++) if (all[i].id > 0) out.push(all[i])
        out.sort(function(a, b) { return a.id - b.id })
        return out
    }

    Repeater {
        model: root.list()
        Item {
            required property var modelData
            readonly property bool focused: modelData.focused
            implicitWidth: ws.implicitWidth + 12
            implicitHeight: Theme.barHeight

            Label {
                id: ws
                anchors.centerIn: parent
                text: modelData.name
                color: modelData.urgent ? Theme.red : (focused || hover.containsMouse ? Theme.fg : Theme.muted)
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 2
                color: focused ? Theme.accent : "transparent"
            }
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
            }
        }
    }
}

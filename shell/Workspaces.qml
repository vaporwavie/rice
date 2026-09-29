import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs

Item {
    id: root
    property var bar

    function list() {
        var out = []
        var all = Hyprland.workspaces.values
        for (var i = 0; i < all.length; i++) if (all[i].id > 0) out.push(all[i])
        out.sort(function(a, b) { return a.id - b.id })
        return out
    }

    readonly property Item current: {
        for (var i = 0; i < tabs.count; i++) {
            var item = tabs.itemAt(i)
            if (item && item.focused) return item
        }
        return null
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: row
        height: parent.height
        Repeater {
            id: tabs
            model: root.list()
            Item {
                required property var modelData
                readonly property bool focused: modelData.focused
                width: ws.implicitWidth + 12
                height: Theme.barHeight

                Label {
                    id: ws
                    anchors.centerIn: parent
                    text: modelData.name
                    color: modelData.urgent ? Theme.red : (parent.focused ? Theme.fg : hover.containsMouse ? Theme.fgDim : Theme.muted)
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

    // One hairline under the focused workspace, gliding between them on the landing's curve.
    Rectangle {
        anchors.bottom: parent.bottom
        height: 2
        color: Theme.accent
        visible: root.current !== null
        x: root.current ? root.current.x : 0
        width: root.current ? root.current.width : 0
        Behavior on x { NumberAnimation { duration: Theme.enter; easing.type: Theme.easing } }
        Behavior on width { NumberAnimation { duration: Theme.enter; easing.type: Theme.easing } }
    }
}

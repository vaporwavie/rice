import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

Panel {
    id: root
    property var item
    property var stack: []
    contentWidth: 240

    QsMenuOpener { id: opener; menu: root.item ? root.item.menu : null }
    Component { id: subOpener; QsMenuOpener { } }

    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : opener
    readonly property var entries: current && current.children ? current.children.values : []

    function reset() {
        var old = stack
        stack = []
        for (var i = old.length - 1; i >= 0; i--) old[i].destroy()
    }
    onOpenChanged: if (!open) reset()
    onItemChanged: reset()

    function enter(entry) {
        var o = subOpener.createObject(root, { menu: entry })
        var s = stack.slice(); s.push(o); stack = s
    }
    function back() {
        var s = stack.slice(); var top = s.pop(); stack = s; top.destroy()
    }

    Column {
        width: parent.width
        PanelRow {
            visible: root.stack.length > 0
            icon: "󰅁"
            text: "Back"
            onClicked: root.back()
        }
        Repeater {
            model: root.entries
            Item {
                required property var modelData
                width: parent.width
                height: modelData.isSeparator ? 9 : Theme.rowHeight
                Rectangle {
                    visible: modelData.isSeparator
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 6 }
                    height: 1
                    color: Theme.border
                }
                PanelRow {
                    visible: !modelData.isSeparator
                    enabled: modelData.enabled
                    icon: modelData.checkState === Qt.Checked ? "󰄬" : ""
                    text: modelData.text
                    trailing: modelData.hasChildren ? "󰅂" : ""
                    onClicked: {
                        if (modelData.hasChildren) root.enter(modelData)
                        else { modelData.triggered(); Panels.close() }
                    }
                }
            }
        }
        Label { visible: root.entries.length === 0; text: "empty menu"; dim: true; leftPadding: 6; height: Theme.rowHeight }
    }
}

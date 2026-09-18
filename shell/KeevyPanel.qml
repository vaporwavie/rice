import QtQuick
import qs

Panel {
    id: root
    name: "keevy"
    grab: false
    grabFocus: true
    property int selected: 0
    onVisibleChanged: if (!visible && open) root.close()

    onOpenChanged: {
        if (!open) return
        selected = 0
        Keevy.refresh()
    }
    onBackingWindowVisibleChanged: if (backingWindowVisible) Qt.callLater(() => body.forceActiveFocus())

    Connections {
        target: Keevy
        function onSwitched() { if (root.open) root.close() }
    }

    Column {
        id: body
        width: root.contentWidth
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close()
            } else if (Keevy.busy || Keevy.loading || event.isAutoRepeat) {
                event.accepted = true
                return
            } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down
                       || event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                var count = Keevy.machines.length
                var direction = event.key === Qt.Key_J || event.key === Qt.Key_Down ? 1 : -1
                if (count > 0) root.selected = (root.selected + direction + count) % count
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (Keevy.machines[root.selected]) Keevy.select(Keevy.machines[root.selected].name)
            } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_3) {
                var machine = Keevy.machines.find(m => m.key === event.key - Qt.Key_0)
                if (machine) Keevy.select(machine.name)
            } else {
                return
            }
            event.accepted = true
        }

        PanelHeader { text: "Keevy" }

        Repeater {
            model: Keevy.machines
            PanelRow {
                required property var modelData
                required property int index
                icon: "󰍹"
                text: modelData.name
                trailing: Keevy.switchingTo === modelData.name ? "…" : String(modelData.key)
                active: root.selected === index
                enabled: !Keevy.busy && !Keevy.loading
                onClicked: { root.selected = index; Keevy.select(modelData.name) }
            }
        }

        PanelHeader {
            visible: Keevy.loading || (!Keevy.machines.length && !Keevy.error)
            text: Keevy.loading ? "Loading…" : "No machines configured"
        }

        Label {
            visible: Keevy.busy || Keevy.error !== ""
            text: Keevy.busy ? "Switching to " + Keevy.switchingTo + "…" : Keevy.error
            textFormat: Text.PlainText
            color: Keevy.error ? Theme.red : Theme.muted
            width: parent.width
            leftPadding: 6
            rightPadding: 6
            topPadding: 6
            wrapMode: Text.Wrap
            maximumLineCount: 5
        }
    }
}

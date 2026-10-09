import QtQuick
import qs

Panel {
    id: root
    name: "keevy"
    onOpenChanged: if (open) Keevy.refresh()
    extraKeys: event => {
        if (event.key === Qt.Key_Escape) return false
        if (Keevy.busy || Keevy.loading || event.isAutoRepeat) return true
        if (event.key < Qt.Key_1 || event.key > Qt.Key_3) return false
        var machine = Keevy.machines.find(m => m.key === event.key - Qt.Key_0)
        if (machine) Keevy.select(machine.name)
        return true
    }

    Connections {
        target: Keevy
        function onSwitched() { if (root.open) root.close() }
        function onLoadingChanged() { if (!Keevy.loading && root.open && !Panels.fromPointer && !root.cursor) root.step(1) }
    }

    Column {
        id: body
        width: root.contentWidth

        PanelHeader { text: "Keevy" }

        Repeater {
            model: Keevy.machines
            PanelRow {
                required property var modelData
                icon: "󰍹"
                text: modelData.name
                trailing: Keevy.switchingTo === modelData.name ? "…" : String(modelData.key)
                enabled: !Keevy.busy && !Keevy.loading
                onClicked: Keevy.select(modelData.name)
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

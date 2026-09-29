import QtQuick
import qs

Panel {
    id: root
    name: "events"
    contentWidth: 440

    Column {
        width: root.contentWidth

        PanelHeader { text: "Notion Calendar" }
        EventsList {
            width: parent.width
            onOpened: { NotionCalendar.openApp(); root.close() }
        }
        Item { width: 1; height: 6 }
        PanelRow {
            icon: "󰃭"
            text: "Open Notion Calendar"
            onClicked: { NotionCalendar.openApp(); root.close() }
        }
    }
}

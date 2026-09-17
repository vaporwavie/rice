import QtQuick
import qs

Panel {
    id: root
    name: "events"
    contentWidth: 440

    Column {
        width: root.contentWidth

        Flickable {
            width: parent.width
            height: Math.min(list.height, 420)
            contentHeight: list.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: NotionCalendar.events.length > 0

            Column {
                id: list
                width: parent.width

                Repeater {
                    model: NotionCalendar.days
                    Column {
                        id: day
                        required property var modelData
                        width: list.width

                        PanelHeader { text: day.modelData.label || Qt.formatDate(new Date(day.modelData.startsAt), "dddd, MMM d") }
                        Repeater {
                            model: day.modelData.events
                            Item {
                                id: row
                                required property var modelData
                                width: day.width
                                height: Theme.rowHeight

                                Rectangle {
                                    anchors.fill: parent
                                    color: area.containsMouse ? Theme.bgElev : "transparent"
                                }
                                Label {
                                    id: time
                                    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                                    text: Qt.formatTime(new Date(row.modelData.startsAt), "HH:mm")
                                    dim: true
                                }
                                Label {
                                    anchors {
                                        left: time.right; leftMargin: 10
                                        right: countdown.left; rightMargin: 8
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: row.modelData.title
                                    textFormat: Text.PlainText
                                }
                                Label {
                                    id: countdown
                                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                                    text: NotionCalendar.remaining(row.modelData.startsAt)
                                    dim: true
                                }
                                MouseArea {
                                    id: area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: { NotionCalendar.openApp(); root.close() }
                                }
                            }
                        }
                    }
                }
            }
        }

        PanelHeader {
            visible: NotionCalendar.events.length === 0
            text: NotionCalendar.live ? "No upcoming events" : "Notion Calendar is not running"
        }

        Item { width: 1; height: 6 }
        PanelRow {
            icon: "󰃭"
            text: "Open Calendar"
            onClicked: { NotionCalendar.openApp(); root.close() }
        }
    }
}

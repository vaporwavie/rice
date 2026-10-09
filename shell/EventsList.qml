import QtQuick
import qs

Column {
    id: root
    property int maxHeight: 420
    signal opened()

    Flickable {
        width: parent.width
        height: Math.min(list.height, root.maxHeight)
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
                            property bool selected: false
                            readonly property bool navigable: true
                            function activate() { root.opened() }
                            width: day.width
                            height: Theme.rowHeight

                            Rectangle {
                                anchors.fill: parent
                                color: area.containsMouse || row.selected ? Theme.bgElev : "transparent"
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
                                onClicked: root.opened()
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
}

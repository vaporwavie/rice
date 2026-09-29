import QtQuick
import QtQuick.Controls
import qs

Flickable {
    id: root
    property var groups: []
    property bool filtered: false
    contentHeight: list.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    onGroupsChanged: contentY = 0

    Column {
        id: list
        width: root.width - 8
        spacing: 8

        Repeater {
            model: root.groups
            Column {
                id: group
                required property var modelData
                width: list.width
                spacing: 4
                Item {
                    width: parent.width
                    height: Theme.rowHeight
                    Label {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: group.modelData.title
                        color: group.modelData.overdue ? Theme.red : Theme.fgDim
                    }
                    Label {
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        text: group.modelData.items.length
                        color: group.modelData.overdue ? Theme.red : Theme.fgDim
                    }
                }
                Repeater {
                    model: group.modelData.items
                    Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool overdue: Todoist.isOverdue(modelData)
                        width: group.width
                        height: details.height + 12
                        color: Theme.bgAlt

                        Column {
                            id: details
                            anchors { left: parent.left; leftMargin: 8; right: actions.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 4
                            Label {
                                width: parent.width
                                text: row.modelData.title
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                            }
                            Label {
                                width: parent.width
                                text: Todoist.when(row.modelData) + (row.modelData.recurring ? " · repeats" : "")
                                color: row.overdue ? Theme.red : Theme.fgDim
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }
                        Row {
                            id: actions
                            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                            BarButton {
                                text: Todoist.actingOn === row.modelData.id ? "󰔟" : "󰄬"
                                tip: row.modelData.recurring ? "Complete this occurrence" : "Mark done"
                                enabled: !Todoist.busy
                                color: enabled ? Theme.green : Theme.muted
                                onClicked: Todoist.markDone(row.modelData.id)
                            }
                        }
                    }
                }
            }
        }
        Label {
            width: parent.width
            topPadding: 12
            visible: root.groups.every(group => group.items.length === 0)
            text: Todoist.error ? "Agenda unavailable. Try refresh."
                : !Todoist.loaded ? "Loading Todoist…"
                : root.filtered ? "Nothing scheduled for this day."
                : "Nothing scheduled."
            wrapMode: Text.Wrap
            color: Theme.fgDim
        }
    }
}

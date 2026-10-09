import QtQuick
import qs

Panel {
    id: root
    name: "calendar"
    contentWidth: 700

    property date shown: new Date()
    property string selected: ""
    readonly property date today: new Date(Todoist.now)
    readonly property var groups: Todoist.agenda(selected)

    onOpenChanged: if (open) { reset(); Todoist.refresh() }
    extraKeys: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) root.shift(-1)
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) root.shift(1)
        else if (event.key === Qt.Key_T) root.reset()
        else if (event.key === Qt.Key_R) Todoist.refresh()
        else return false
        return true
    }

    function reset() { shown = new Date(); selected = "" }
    function shift(months) {
        shown = new Date(shown.getFullYear(), shown.getMonth() + months, 1)
        selected = ""
    }
    function selectDate(date) { selected = Todoist.dayKey(date) }
    function dateFor(day) { return new Date(shown.getFullYear(), shown.getMonth(), day) }
    function cells() {
        var first = new Date(shown.getFullYear(), shown.getMonth(), 1)
        var lead = (first.getDay() + 6) % 7
        var days = new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
        var out = []
        for (var i = 0; i < 42; i++) out.push(i >= lead && i < lead + days ? i - lead + 1 : 0)
        return out
    }

    Column {
        id: body
        width: root.contentWidth
        spacing: 10

        Item {
            width: parent.width
            height: Theme.rowHeight
            Label {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: "Todoist"
                font.bold: true
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 8
                BarButton {
                    text: "󰑐"
                    tip: "Refresh (R)"
                    enabled: !Todoist.loading
                    color: enabled ? Theme.fgDim : Theme.muted
                    onClicked: Todoist.refresh()
                }
                BarButton { text: "󰅖"; tip: "Close (Esc)"; onClicked: root.close() }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.border }

        Row {
            width: parent.width
            spacing: 16

            Column {
                width: 252
                spacing: 6
                Item {
                    width: parent.width
                    height: Theme.rowHeight
                    BarButton {
                        anchors.left: parent.left
                        text: "󰅁"; tip: "Previous month (H)"
                        onClicked: root.shift(-1)
                    }
                    Label { anchors.centerIn: parent; text: Qt.formatDate(root.shown, "MMMM yyyy") }
                    BarButton {
                        anchors.right: parent.right
                        text: "󰅂"; tip: "Next month (L)"
                        onClicked: root.shift(1)
                    }
                }
                Grid {
                    columns: 7
                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        Item {
                            required property string modelData
                            width: 36; height: 24
                            Label { anchors.centerIn: parent; text: modelData; color: Theme.fgDim }
                        }
                    }
                }
                Grid {
                    columns: 7
                    Repeater {
                        model: root.cells()
                        Rectangle {
                            id: cell
                            required property int modelData
                            readonly property string key: modelData ? Todoist.dayKey(root.dateFor(modelData)) : ""
                            readonly property bool isToday: key === Todoist.dayKey(root.today)
                            readonly property bool chosen: key !== "" && key === root.selected
                            width: 36; height: 32
                            color: chosen ? Theme.bgElev : dayArea.containsMouse ? Theme.bgAlt : "transparent"
                            border.width: chosen ? 1 : 0
                            border.color: Theme.accent
                            Label {
                                anchors.centerIn: parent
                                text: cell.modelData ? String(cell.modelData) : ""
                                color: cell.isToday ? Theme.accent : Theme.fg
                                font.bold: cell.isToday
                            }
                            Rectangle {
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 3 }
                                width: 4; height: 4; radius: 2
                                color: Theme.accent
                                visible: (Todoist.dayCounts[cell.key] || 0) > 0
                            }
                            MouseArea {
                                id: dayArea
                                anchors.fill: parent
                                enabled: cell.modelData > 0
                                hoverEnabled: true
                                onClicked: root.selectDate(root.dateFor(cell.modelData))
                            }
                        }
                    }
                }
                PanelRow {
                    icon: "󰃭"; text: "Today / agenda"; trailing: "T"
                    onClicked: root.reset()
                }
            }

            Rectangle { width: 1; height: 334; color: Theme.border }

            TodoistAgenda {
                width: 415
                height: 334
                groups: root.groups
                filtered: root.selected !== ""
            }
        }

        Label {
            width: parent.width
            visible: Todoist.error !== "" || Todoist.actionError !== ""
            text: (Todoist.actionError || Todoist.error).split("\n")[0]
                + (Todoist.error && Todoist.loaded ? " · Showing last update" : "")
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            color: Theme.red
        }
        Rectangle { width: parent.width; height: 1; color: Theme.border }
        PanelRow {
            icon: "󰖟"; text: "Open Todoist"; trailing: "add / edit"
            onClicked: { root.close(); Todoist.openApp() }
        }
    }
}

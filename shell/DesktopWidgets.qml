import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import "clock-format.js" as ClockFormat

// The empty desktop (Super, Super) shows the bar's widgets and the overseer report laid out as cards, under any window opened there.
PanelWindow {
    id: root

    readonly property string screenName: screen ? screen.name : ""
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var workspace: monitor ? monitor.activeWorkspace : null
    readonly property bool active: workspace !== null && workspace.name === Desktop.workspace
    readonly property int pillarWidth: 224

    visible: active
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "altura-desktop"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property real shown: 0
    onActiveChanged: if (active) { shown = 0; reveal.restart() } else reveal.stop()
    NumberAnimation { id: reveal; target: root; property: "shown"; from: 0; to: 1; duration: Theme.hero; easing.type: Theme.easing }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    component Card: Rectangle {
        id: card
        property string title: ""
        property int order: 0
        property alias actions: actionRow.data
        default property alias body: holder.data
        readonly property real rise: Math.max(0, Math.min(1, root.shown * 1.6 - order * 0.2))
        color: Theme.bgAlt
        border.color: Theme.lineStrong
        border.width: Theme.panelBorder
        opacity: rise
        transform: Translate { y: (1 - card.rise) * 12 }

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.panelBorder }
            height: 160
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.glow }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Item {
            id: head
            x: Theme.panelPadding
            y: Theme.panelPadding
            width: card.width - Theme.panelPadding * 2
            height: Theme.rowHeight
            Label {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: card.title
                font.bold: true
            }
            Row {
                id: actionRow
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 8
            }
        }
        Rectangle {
            id: rule
            anchors { left: head.left; right: head.right; top: head.bottom; topMargin: 6 }
            height: 1
            color: Theme.border
        }
        Item {
            id: holder
            anchors { left: head.left; right: head.right; top: rule.bottom; topMargin: 6; bottom: parent.bottom; bottomMargin: Theme.panelPadding }
        }
    }

    Item {
        id: stage
        anchors.fill: parent

        Column {
            id: layout
            // Centered on the screen, pushed right only when it would run under the pillar.
            x: Math.max(root.pillarWidth, Math.round((stage.width - width) / 2))
            anchors.verticalCenter: parent.verticalCenter
            spacing: 28

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: root.shown
                transform: Translate { y: (1 - root.shown) * 12 }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: 72
                    font.weight: Font.Light
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd ") + ClockFormat.ordinalDay(clock.date.getDate())
                        + Qt.formatDateTime(clock.date, " MMMM")
                    dim: true
                }
            }

            Row {
                spacing: 24

                Card {
                    id: todoistCard
                    objectName: "todoist"
                    title: "Todoist"
                    order: 0
                    width: 440
                    height: activityCard.height
                    actions: [
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Todoist.overdue.length > 0
                            text: Todoist.overdue.length + " overdue"
                            color: Theme.red
                        }
                    ]
                    TodoistAgenda {
                        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: todoistFooter.top; bottomMargin: 6 }
                        groups: Todoist.agenda("")
                    }
                    PanelRow {
                        id: todoistFooter
                        anchors.bottom: parent.bottom
                        icon: "󰖟"; text: "Open Todoist"; trailing: "add / edit"
                        onClicked: { Desktop.leave(); Todoist.openApp() }
                    }
                }

                Card {
                    id: eventsCard
                    objectName: "events"
                    title: "Notion Calendar"
                    order: 1
                    width: 420
                    height: activityCard.height
                    EventsList {
                        width: parent.width
                        maxHeight: parent.height - eventsFooter.height - 6
                        onOpened: { Desktop.leave(); NotionCalendar.openApp() }
                    }
                    PanelRow {
                        id: eventsFooter
                        anchors.bottom: parent.bottom
                        icon: "󰃭"; text: "Open Notion Calendar"
                        onClicked: { Desktop.leave(); NotionCalendar.openApp() }
                    }
                }

                Card {
                    id: activityCard
                    objectName: "activity"
                    title: "Activity"
                    order: 2
                    width: 360
                    height: activity.implicitHeight + Theme.rowHeight + Theme.panelPadding * 2 + 13
                    ActivityView {
                        id: activity
                        width: parent.width
                        onConnections: Panels.toggle("network", root.screenName)
                    }
                }

                Card {
                    id: overseerCard
                    objectName: "overseer"
                    title: "Overseer"
                    order: 3
                    width: 400
                    height: activityCard.height
                    OverseerView {
                        anchors.fill: parent
                        onOpenReport: { Desktop.leave(); Overseer.openReport() }
                    }
                }
            }
        }
    }
}

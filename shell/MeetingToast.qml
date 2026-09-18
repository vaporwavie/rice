import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    readonly property var event: NotionCalendar.alert
    readonly property bool focusedHere: !Hyprland.focusedMonitor || !screen || Hyprland.focusedMonitor.name === screen.name
    readonly property bool started: event !== null && event.startsAt <= NotionCalendar.now

    visible: event !== null && focusedHere
    anchors { top: true; right: true }
    margins { top: 10; right: 10 }
    implicitWidth: 380
    implicitHeight: content.implicitHeight + (Theme.panelPadding + Theme.panelBorder) * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "meeting-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.color: Theme.accent
        border.width: Theme.panelBorder

        MouseArea {
            anchors.fill: parent
            onClicked: { NotionCalendar.openApp(); NotionCalendar.dismiss() }
        }

        Column {
            id: content
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                margins: Theme.panelPadding + Theme.panelBorder
            }
            spacing: 6

            Item {
                width: parent.width
                height: Theme.rowHeight

                Label {
                    anchors { left: parent.left; right: close.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    text: root.event ? root.event.title : ""
                    textFormat: Text.PlainText
                    font.bold: true
                }
                BarButton {
                    id: close
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    implicitHeight: Theme.rowHeight
                    text: "󰅖"
                    color: Theme.muted
                    onClicked: NotionCalendar.dismiss()
                }
            }

            Item {
                width: parent.width
                height: Theme.rowHeight

                Row {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    spacing: 10
                    Label { text: root.event ? Qt.formatTime(new Date(root.event.startsAt), "HH:mm") : ""; dim: true }
                    Label {
                        text: root.started ? "now" : (root.event ? NotionCalendar.remaining(root.event.startsAt) : "")
                        color: Theme.accent
                    }
                }

                Rectangle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: action.implicitWidth + 24
                    height: Theme.rowHeight
                    color: actionArea.containsMouse ? Theme.accentAlt : Theme.accent

                    Label {
                        id: action
                        anchors.centerIn: parent
                        text: root.event && root.event.join ? root.event.join : "Open Calendar"
                        textFormat: Text.PlainText
                        color: Theme.bg
                    }
                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.event && root.event.join) NotionCalendar.join()
                            else { NotionCalendar.openApp(); NotionCalendar.dismiss() }
                        }
                    }
                }
            }
        }
    }
}

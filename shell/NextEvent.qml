import QtQuick
import qs

Item {
    id: root
    property var bar
    readonly property var event: NotionCalendar.next
    readonly property int maxTitleWidth: 260

    visible: NotionCalendar.live
    implicitWidth: visible ? row.implicitWidth + 16 : 0
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 14; color: Theme.lineStrong }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxTitleWidth)
            text: root.event ? root.event.title : "No events"
            dim: root.event === null
            visible: text !== ""
            textFormat: Text.PlainText
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.event !== null
            text: root.event ? NotionCalendar.remaining(root.event.startsAt) : ""
            color: root.event && root.event.startsAt - NotionCalendar.now <= 300000 ? Theme.accent : Theme.muted
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) NotionCalendar.openApp()
            else root.bar.togglePanel("events")
        }
    }
    Tooltip {
        anchorItem: root
        text: root.event ? "Notion Calendar · " + root.event.title : "Open Notion Calendar events"
        open: area.containsMouse
    }
}

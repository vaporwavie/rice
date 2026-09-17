import QtQuick
import qs

Item {
    id: root
    property var bar
    readonly property var event: NotionCalendar.next
    readonly property int maxTitleWidth: 260

    visible: event !== null
    implicitWidth: visible ? row.implicitWidth + 16 : 0
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Label { anchors.verticalCenter: parent.verticalCenter; text: "|"; dim: true }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxTitleWidth)
            text: root.event ? root.event.title : ""
            textFormat: Text.PlainText
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.event ? NotionCalendar.remaining(root.event.startsAt) : ""
            color: root.event && root.event.startsAt - NotionCalendar.now <= 300000 ? Theme.accent : Theme.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) NotionCalendar.openApp()
            else root.bar.togglePanel("events")
        }
    }
}

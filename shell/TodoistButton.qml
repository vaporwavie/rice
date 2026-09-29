import QtQuick
import qs

Item {
    id: root
    property var bar
    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 14; color: Theme.lineStrong }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: "Todoist"
            color: Todoist.error ? Theme.red : Theme.fgDim
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: Todoist.overdue.length > 0 && !Todoist.error
            text: Todoist.overdue.length + " overdue"
            color: Theme.red
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: Todoist.today.length > 0 && !Todoist.error
            text: Todoist.today.length + " today"
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: Todoist.error !== ""
            text: "unavailable"
            color: Theme.red
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) Todoist.openApp()
            else root.bar.togglePanel("calendar")
        }
    }
    Tooltip {
        anchorItem: root
        text: "Open Todoist agenda"
        open: area.containsMouse
    }
}

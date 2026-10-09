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
        spacing: 6
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 14; color: Theme.lineStrong }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: "Tasks"
            color: Todoist.error ? Theme.red : Theme.fgDim
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: Todoist.overdue.length > 0 && !Todoist.error
            text: Todoist.overdue.length + "o"
            color: Theme.red
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: Todoist.today.length > 0 && !Todoist.error
            text: Todoist.today.length + "t"
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: Todoist.error !== ""
            text: "!"
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
        text: Todoist.error ? "Todoist unavailable" : Todoist.overdue.length + " overdue, " + Todoist.today.length + " today"
        open: area.containsMouse
    }
}

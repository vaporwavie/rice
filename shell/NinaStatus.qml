import QtQuick
import qs

// Panel header: the app name and what Nina is doing right now.
Item {
    id: root
    readonly property var status: {
        if (!Nina.connected) return { text: "Not running", color: Theme.muted }
        if (Nina.state === "recording") return { text: "Listening", color: Theme.red }
        if (Nina.state === "transcribing") return { text: "Transcribing", color: Theme.yellow }
        if (Nina.state === "error") return { text: "Error", color: Theme.red }
        return { text: "Ready", color: Theme.green }
    }

    width: parent ? parent.width : Theme.panelWidth
    height: Theme.rowHeight + (error.visible ? error.implicitHeight + 4 : 0)

    Row {
        anchors { left: parent.left; leftMargin: 6; top: parent.top; topMargin: (Theme.rowHeight - height) / 2 }
        spacing: 8
        NinaIcon { anchors.verticalCenter: parent.verticalCenter; size: Theme.iconSize; color: Theme.fg }
        Label { anchors.verticalCenter: parent.verticalCenter; text: "Nina" }
    }

    Row {
        anchors { right: parent.right; rightMargin: 6; top: parent.top; topMargin: (Theme.rowHeight - height) / 2 }
        spacing: 6
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: root.status.color
            Behavior on color { ColorAnimation { duration: Theme.quick; easing.type: Theme.easing } }
        }
        Label { anchors.verticalCenter: parent.verticalCenter; text: root.status.text; dim: true }
    }

    Label {
        id: error
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Theme.rowHeight; leftMargin: 6; rightMargin: 6 }
        visible: Nina.state === "error" && Nina.message !== ""
        text: Nina.message
        textFormat: Text.PlainText
        color: Theme.red
        wrapMode: Text.Wrap
        maximumLineCount: 3
    }
}

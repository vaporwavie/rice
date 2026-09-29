import QtQuick
import qs

Item {
    id: root
    signal openReport()

    readonly property var earlier: Overseer.verdicts.slice(1, 5)
    readonly property string tag: Overseer.running ? "running…"
        : Overseer.failed ? "last run " + Overseer.result
        : Overseer.priority !== "default" ? Overseer.priority : ""
    readonly property color tagColor: Overseer.running ? Theme.accent
        : Overseer.failed || Overseer.priority === "high" || Overseer.priority === "urgent" || Overseer.priority === "max" ? Theme.red
        : Theme.fgDim

    Item {
        id: status
        width: parent.width
        height: Theme.rowHeight
        Label {
            anchors { left: parent.left; leftMargin: 6; right: tagLabel.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: Overseer.latest ? Overseer.when(Overseer.latest.at) + " · " + Overseer.ago(Overseer.latest.at) : "No overseer runs yet"
            dim: true
        }
        Label {
            id: tagLabel
            objectName: "tag"
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            text: root.tag
            color: root.tagColor
        }
    }

    Flickable {
        id: report
        anchors { left: parent.left; right: parent.right; top: status.bottom; bottom: history.top; bottomMargin: 6 }
        contentHeight: reportBody.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: reportBody
            width: report.width
            spacing: 8
            Label {
                objectName: "headline"
                width: parent.width
                leftPadding: 6
                rightPadding: 6
                text: Overseer.headline
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Theme.accent
            }
            Label {
                objectName: "details"
                width: parent.width
                leftPadding: 6
                rightPadding: 6
                visible: text !== ""
                text: Overseer.details
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                lineHeight: 1.15
            }
            Label {
                width: parent.width
                leftPadding: 6
                visible: Overseer.error !== ""
                text: Overseer.error
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Theme.red
            }
        }
    }

    Column {
        id: history
        anchors { left: parent.left; right: parent.right; bottom: footer.top; bottomMargin: 6 }
        PanelHeader { visible: root.earlier.length > 0; text: "Earlier" }
        Repeater {
            model: root.earlier
            Item {
                required property var modelData
                width: history.width
                height: 24
                Label {
                    id: at
                    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                    width: 88
                    text: Overseer.when(modelData.at)
                    dim: true
                }
                Label {
                    anchors { left: at.right; leftMargin: 6; right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    text: modelData.text.replace(/^Next:\s*/, "")
                    textFormat: Text.PlainText
                }
            }
        }
    }

    Column {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        PanelRow {
            icon: "󰈙"; text: "Open report"
            trailing: Overseer.next > 0 ? "next " + Overseer.when(Overseer.next) : ""
            enabled: Overseer.latest !== null
            onClicked: root.openReport()
        }
        PanelRow {
            objectName: "runNow"
            icon: "󰑐"; text: Overseer.running ? "Running…" : "Run now"
            enabled: !Overseer.running
            onClicked: Overseer.runNow()
        }
    }
}

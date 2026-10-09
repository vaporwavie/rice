import QtQuick
import Quickshell
import qs
import "nina-format.js" as Format

Panel {
    id: root
    name: "nina"
    onOpenChanged: if (open) Nina.refresh()

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Column {
        width: root.contentWidth

        NinaStatus { width: parent.width }

        PanelRow { icon: "󰧑"; text: "Model"; trailing: Nina.modelName; enabled: Nina.connected }
        PanelRow { icon: "󰗊"; text: "Language"; trailing: Nina.languageLabel; enabled: Nina.connected }
        PanelRow { icon: "󰌌"; text: "Push to talk"; trailing: Nina.hotkeyLabel; enabled: Nina.connected }

        Rectangle { width: parent.width; height: 1; color: Theme.border }

        Item {
            id: latestTake
            width: parent.width
            height: take.implicitHeight + 16
            visible: Nina.latest !== null
            property bool selected: false
            readonly property bool navigable: true
            function activate() { Nina.copy(Nina.latest) }
            readonly property bool copied: Nina.latest && Nina.copiedId === Nina.latest.id

            Rectangle {
                anchors.fill: parent
                color: takeArea.containsMouse || latestTake.selected ? Theme.bgElev : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.quick; easing.type: Theme.easing } }
            }

            Column {
                id: take
                x: 6
                y: 8
                width: parent.width - 12
                spacing: 4

                Item {
                    width: parent.width
                    height: stamp.implicitHeight
                    Label {
                        id: stamp
                        text: Nina.latest ? Format.when(Nina.latest.createdAt, clock.date.getTime()) : ""
                        dim: true
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Label {
                        anchors.right: parent.right
                        text: latestTake.copied ? "Copied" : takeArea.containsMouse || latestTake.selected ? "Copy" : ""
                        color: Theme.accent
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
                Label {
                    width: parent.width
                    text: Nina.latest ? Nina.latest.text : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                }
            }

            MouseArea {
                id: takeArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Nina.copy(Nina.latest)
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.border; visible: Nina.latest !== null }

        PanelRow {
            icon: "󰋚"
            text: "History"
            trailing: Nina.history.length > 0 ? String(Nina.history.length) : ""
            onClicked: Panels.replace("nina-full")
        }
        PanelRow {
            icon: Nina.connected ? "󰒓" : "󰐊"
            text: Nina.connected ? "Open Nina" : "Start Nina"
            onClicked: { Nina.openSettings(); root.close() }
        }
    }
}

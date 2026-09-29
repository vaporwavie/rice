import QtQuick
import Quickshell
import qs
import "nina-format.js" as Format

// Nina fully opened from the bar: today's numbers, the setup at a glance and every take,
// searchable, click to copy. Editing stays in Nina's own window.
Panel {
    id: root
    name: "nina-full"
    contentWidth: 560
    grab: false
    grabFocus: true
    property string query: ""
    readonly property var entries: Nina.history.filter(entry => Format.matches(entry, query))
    readonly property var today: Format.todayStats(Nina.history, clock.date.getTime())

    onVisibleChanged: if (!visible && open) root.close()
    onOpenChanged: {
        if (!open) return
        query = ""
        search.text = ""
        list.positionViewAtBeginning()
        Nina.refresh()
    }
    onBackingWindowVisibleChanged: if (backingWindowVisible) Qt.callLater(() => search.forceActiveFocus())

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Column {
        width: root.contentWidth
        spacing: 0

        NinaStatus { width: parent.width }

        Row {
            width: parent.width
            topPadding: 6
            bottomPadding: 10

            Repeater {
                model: [
                    { label: "Takes today", value: String(root.today.takes) },
                    { label: "Words", value: String(root.today.words) },
                    { label: "Spoken", value: Format.duration(root.today.audio) },
                    { label: "Push to talk", value: Nina.hotkeyLabel }
                ]
                Column {
                    required property var modelData
                    width: root.contentWidth / 4
                    leftPadding: 6
                    spacing: 2
                    Label { text: modelData.value; width: parent.width - 12; font.pixelSize: Theme.fontSize + 4 }
                    Label { text: modelData.label; dim: true; font.pixelSize: Theme.fontSize - 2 }
                }
            }
        }

        Item {
            width: parent.width
            height: Theme.rowHeight
            Label {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: Nina.modelName + "  ·  " + Nina.languageLabel + (Nina.fillers ? "  ·  fillers removed" : "")
                dim: true
                font.pixelSize: Theme.fontSize - 2
            }
        }

        Rectangle {
            width: parent.width
            height: Theme.rowHeight + 4
            color: Theme.bg
            border.color: search.activeFocus ? Theme.lineStrong : Theme.border
            border.width: 1

            Label {
                id: glass
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                text: "󰍉"
                icon: true
                dim: true
            }
            TextInput {
                id: search
                anchors { left: glass.right; leftMargin: 10; right: count.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.fg
                selectionColor: Theme.lineStrong
                selectedTextColor: Theme.fg
                clip: true
                onTextChanged: root.query = text
                Keys.onEscapePressed: event => {
                    if (text !== "") text = ""
                    else root.close()
                    event.accepted = true
                }
                Keys.onReturnPressed: Nina.copy(root.entries[0])
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "Search takes"
                    color: Theme.muted
                }
            }
            Label {
                id: count
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                text: root.query === "" ? String(Nina.history.length) : root.entries.length + " / " + Nina.history.length
                dim: true
                font.pixelSize: Theme.fontSize - 2
            }
        }

        Item { width: 1; height: 6 }

        ListView {
            id: list
            width: parent.width
            height: 440
            clip: true
            spacing: 2
            model: root.entries
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: row
                required property var modelData
                readonly property bool copied: Nina.copiedId === modelData.id
                width: ListView.view.width
                height: body.implicitHeight + 16

                Rectangle {
                    anchors.fill: parent
                    color: rowArea.containsMouse ? Theme.bgElev : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.quick; easing.type: Theme.easing } }
                }

                Column {
                    id: body
                    x: 8
                    y: 8
                    width: parent.width - 16
                    spacing: 4

                    Item {
                        width: parent.width
                        height: meta.implicitHeight
                        Label {
                            id: meta
                            text: Format.when(row.modelData.createdAt, clock.date.getTime())
                                + (row.modelData.audioMs > 0 ? "  ·  " + Format.duration(row.modelData.audioMs) : "")
                            dim: true
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Label {
                            anchors.right: parent.right
                            text: row.copied ? "Copied" : rowArea.containsMouse ? "Copy" : ""
                            color: Theme.accent
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                    Label {
                        width: parent.width
                        text: row.modelData.text
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Nina.copy(row.modelData)
                }
            }

            Label {
                anchors.centerIn: parent
                visible: list.count === 0
                text: Nina.history.length === 0 ? "Nothing dictated yet" : "No takes match"
                dim: true
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.border }

        PanelRow {
            icon: Nina.connected ? "󰒓" : "󰐊"
            text: Nina.connected ? "Open Nina" : "Start Nina"
            onClicked: { Nina.openSettings(); root.close() }
        }
    }
}

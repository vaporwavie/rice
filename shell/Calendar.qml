import QtQuick
import Quickshell
import qs

Panel {
    id: root
    name: "calendar"
    contentWidth: 7 * 36

    property date shown: new Date()
    readonly property date today: clock.date
    onOpenChanged: if (open) shown = new Date()

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function shift(months) {
        shown = new Date(shown.getFullYear(), shown.getMonth() + months, 1)
    }
    function cells() {
        var first = new Date(shown.getFullYear(), shown.getMonth(), 1)
        var lead = (first.getDay() + 6) % 7
        var days = new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
        var out = []
        for (var i = 0; i < lead; i++) out.push(0)
        for (var d = 1; d <= days; d++) out.push(d)
        while (out.length % 7 !== 0) out.push(0)
        return out
    }
    function isToday(d) {
        return d === today.getDate() && shown.getMonth() === today.getMonth() && shown.getFullYear() === today.getFullYear()
    }

    Column {
        width: root.contentWidth
        spacing: 4

        Item {
            width: parent.width
            height: Theme.rowHeight
            Label {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                text: "󰅁"; icon: true
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.shift(-1) }
            }
            Label {
                anchors.centerIn: parent
                text: Qt.formatDate(root.shown, "MMMM yyyy")
            }
            Label {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"; icon: true
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.shift(1) }
            }
        }

        Grid {
            columns: 7
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Item {
                    required property string modelData
                    width: 36; height: 24
                    Label { anchors.centerIn: parent; text: modelData; dim: true }
                }
            }
        }

        Grid {
            columns: 7
            Repeater {
                model: root.cells()
                Item {
                    required property int modelData
                    width: 36; height: 28
                    Label {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "" : String(modelData)
                        color: root.isToday(modelData) ? Theme.accent : Theme.fg
                        font.bold: root.isToday(modelData)
                    }
                    Rectangle {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 2 }
                        width: 18; height: 2
                        color: root.isToday(modelData) ? Theme.accent : "transparent"
                    }
                }
            }
        }
    }
}

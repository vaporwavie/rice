import QtQuick
import qs

Column {
    id: root
    signal connections()

    component Line: Item {
        property string label: ""
        property string value: ""
        property bool heading: false
        property color valueColor: Theme.fg
        width: parent ? parent.width : Theme.panelWidth
        height: 24
        Label {
            anchors { left: parent.left; leftMargin: 6; right: readout.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: parent.label
            dim: parent.heading
            color: parent.heading ? Theme.fgDim : Theme.fg
        }
        Label {
            id: readout
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            text: parent.value
            color: parent.valueColor
        }
    }
    component Gap: Item { width: 1; height: 10 }
    component Graph: Item {
        default property alias graph: holder.data
        width: parent ? parent.width : Theme.panelWidth
        height: 38
        Item { id: holder; anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 2; bottomMargin: 2 } }
    }

    Line {
        heading: true
        label: Activity.host
        value: "up " + Activity.since(Activity.uptime)
        valueColor: Theme.fgDim
    }
    Gap { }

    Line {
        heading: true
        label: "CPU"
        value: (Activity.temp >= 0 ? Activity.temp + "°C   " : "") + Activity.cpu + "%"
        valueColor: Activity.tone(Activity.cpu) || Theme.fg
    }
    Graph { Sparkline { width: parent.width; height: parent.height; values: Activity.cpuHistory; max: 100 } }
    Item {
        width: parent.width
        height: 18
        Row {
            id: cores
            anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 2 }
            spacing: 2
            Repeater {
                model: Activity.cores
                Rectangle {
                    required property var modelData
                    width: (cores.width - cores.spacing * (Activity.cores.length - 1)) / Activity.cores.length
                    height: cores.height
                    color: Theme.bgElev
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(1, parent.height * modelData / 100)
                        color: Activity.tone(modelData) || Theme.fgDim
                        Behavior on height { NumberAnimation { duration: Theme.enter; easing.type: Theme.easing } }
                    }
                }
            }
        }
    }
    Line {
        heading: true
        label: "load"
        value: Activity.load.map(function(n) { return n.toFixed(2) }).join("  ")
        valueColor: Theme.fgDim
    }
    Gap { }

    Line {
        heading: true
        label: "Memory"
        value: Activity.gib(Activity.memUsed) + " / " + Activity.gib(Activity.memTotal) + " GiB"
        valueColor: Activity.tone(Activity.mem) || Theme.fg
    }
    Item {
        width: parent.width
        height: 10
        Rectangle {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 6; rightMargin: 6 }
            height: 4
            color: Theme.bgElev
            Rectangle {
                width: parent.width * Math.min(1, Activity.mem / 100)
                height: parent.height
                color: Activity.tone(Activity.mem) || Theme.fg
                Behavior on width { NumberAnimation { duration: Theme.enter; easing.type: Theme.easing } }
            }
        }
    }
    Line {
        visible: Activity.swapTotal > 0
        heading: true
        label: "swap"
        value: Activity.gib(Activity.swapUsed) + " / " + Activity.gib(Activity.swapTotal) + " GiB"
        valueColor: Theme.fgDim
    }
    Gap { }

    Line {
        heading: true
        label: "Network"
        value: Activity.link ? Activity.link.name : "offline"
        valueColor: Activity.online ? Theme.fg : Theme.red
    }
    Graph {
        Sparkline {
            width: parent.width
            height: parent.height
            values: Activity.rxHistory
            under: Activity.txHistory
        }
    }
    Line {
        label: "↓ " + Activity.rate(Activity.rx) + "   ↑ " + Activity.rate(Activity.tx)
        value: Activity.link ? (Activity.link.ip !== "" ? Activity.link.ip : Activity.link.device) : "all devices"
        valueColor: Theme.fgDim
    }
    PanelRow {
        icon: "󰛳"
        text: "Connections"
        trailing: "›"
        onClicked: root.connections()
    }
    Gap { }

    Line { heading: true; label: "Processes"; value: "cpu    mem"; valueColor: Theme.fgDim }
    Repeater {
        model: Activity.top
        Line {
            required property var modelData
            label: modelData.name
            value: (modelData.cpu.toFixed(1) + "%").padStart(6) + (modelData.mem.toFixed(1) + "%").padStart(7)
            valueColor: Activity.tone(modelData.cpu / Math.max(1, Activity.cores.length)) || Theme.fgDim
        }
    }
    Line { visible: Activity.top.length === 0; heading: true; label: "sampling…" }
}

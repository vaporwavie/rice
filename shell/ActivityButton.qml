import QtQuick
import qs

Item {
    id: root
    property var bar
    readonly property bool open: bar.panelOpen("activity") || bar.panelOpen("network")
    readonly property bool lit: area.containsMouse || open
    readonly property color rest: lit ? Theme.fg : Theme.fgDim
    readonly property var readouts: [
        { text: Activity.cpu + "%", widest: "100%", tone: Activity.tone(Activity.cpu), shown: true },
        { text: Activity.temp + "°", widest: "99°", tone: Activity.tone(Activity.temp), shown: Activity.temp >= 0 },
        { text: Activity.gib(Activity.memUsed) + "G", widest: Activity.gib(Activity.memTotal) + "G", tone: Activity.tone(Activity.mem), shown: true },
        { text: Activity.short(Activity.rx + Activity.tx), widest: "999k", tone: "", shown: Activity.online }
    ]
    readonly property string text: readouts.filter(function(r) { return r.shown }).map(function(r) { return r.text }).join(" ")

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Label {
            anchors.verticalCenter: parent.verticalCenter
            icon: true
            text: Activity.linkIcon
            color: !Activity.online ? Theme.red : root.rest
        }
        Repeater {
            model: root.readouts
            Label {
                id: readout
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                visible: modelData.shown
                text: modelData.text
                width: Math.ceil(gauge.advanceWidth)
                horizontalAlignment: Text.AlignRight
                color: modelData.tone !== "" ? modelData.tone : root.rest
                TextMetrics { id: gauge; font: readout.font; text: readout.modelData.widest }
                Behavior on color { ColorAnimation { duration: Theme.quick; easing.type: Theme.easing } }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.bar.togglePanel(mouse.button === Qt.RightButton ? "network" : "activity")
    }

    Tooltip {
        anchorItem: root
        open: area.containsMouse && !root.open
        text: "cpu " + Activity.cpu + "%" + (Activity.temp >= 0 ? "  " + Activity.temp + "°C" : "") + "   mem " + Activity.gib(Activity.memUsed) + "/" + Activity.gib(Activity.memTotal)
            + " GiB   " + (Activity.online ? "↓ " + Activity.rate(Activity.rx) + "  ↑ " + Activity.rate(Activity.tx) : "offline")
    }

    ActivityPanel { anchorItem: root; open: root.bar.panelOpen("activity") }
    NetworkPanel { anchorItem: root; open: root.bar.panelOpen("network") }
}

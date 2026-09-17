import QtQuick
import Quickshell.Io
import qs

BarButton {
    id: root
    property real last: 0
    property real lastIdle: 0
    property int usage: 0
    text: "󰘚"
    tip: usage + "% cpu"

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            var f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            var total = f.reduce(function(a, b) { return a + b }, 0)
            var idle = f[3] + f[4]
            if (root.last > 0 && total > root.last)
                root.usage = Math.round(100 * (1 - (idle - root.lastIdle) / (total - root.last)))
            root.last = total
            root.lastIdle = idle
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: stat.reload() }
}

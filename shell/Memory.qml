import QtQuick
import Quickshell.Io
import qs

BarButton {
    id: root
    property real used: 0
    property real total: 0
    text: "󰍛"
    tip: used.toFixed(1) + " GiB of " + total.toFixed(1) + " GiB"

    FileView {
        id: info
        path: "/proc/meminfo"
        onLoaded: {
            var m = {}
            text().split("\n").forEach(function(l) {
                var p = l.split(/:\s+/)
                if (p.length === 2) m[p[0]] = parseInt(p[1])
            })
            root.total = m.MemTotal / 1048576
            root.used = (m.MemTotal - m.MemAvailable) / 1048576
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: info.reload() }
}

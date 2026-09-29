pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property string dir: Quickshell.env("OVERSEER_DIR") || Quickshell.env("HOME") + "/reports/overseer"
    property real now: Date.now()
    property var verdicts: []
    property string body: ""
    property string priority: "default"
    property string state: ""
    property string result: ""
    property real next: 0
    property real finished: 0
    property string error: ""
    readonly property bool running: state === "activating" || state === "active"
    readonly property bool failed: result !== "" && result !== "success"
    readonly property var latest: verdicts.length > 0 ? verdicts[0] : null
    readonly property string headline: body.split("\n")[0] || (latest ? latest.text : "")
    readonly property string details: body.split("\n").slice(1).join("\n").trim()

    function stampDate(stamp) {
        var m = /^(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})$/.exec(stamp)
        return m ? new Date(+m[1], m[2] - 1, +m[3], +m[4], +m[5]).getTime() : NaN
    }
    function readVerdicts(text) {
        var out = []
        for (var line of text.split("\n")) {
            var i = line.indexOf(" ")
            var at = stampDate(line.slice(0, i))
            if (i > 0 && Number.isFinite(at)) out.push({ stamp: line.slice(0, i), at: at, text: line.slice(i + 1).trim() })
        }
        verdicts = out.reverse()
    }
    function readStatus(text) {
        var blocks = text.trim().split(/\n\s*\n/)
        var timer = {}, service = {}
        blocks.forEach(function(block, n) {
            block.split("\n").forEach(function(line) {
                var i = line.indexOf("=")
                if (i > 0) (n === 0 ? timer : service)[line.slice(0, i)] = line.slice(i + 1)
            })
        })
        var unix = value => /^@\d+$/.test(value || "") ? parseInt(value.slice(1)) * 1000 : 0
        next = unix(timer.NextElapseUSecRealtime)
        finished = unix(service.ExecMainExitTimestamp)
        state = service.ActiveState || ""
        result = service.Result || ""
    }
    function ago(at) {
        var minutes = Math.max(0, Math.round((now - at) / 60000))
        if (minutes < 60) return minutes + "m ago"
        var hours = Math.floor(minutes / 60)
        return hours < 24 ? hours + "h " + (minutes % 60) + "m ago" : Math.floor(hours / 24) + "d ago"
    }
    function when(at) {
        var sameDay = new Date(at).toDateString() === new Date(now).toDateString()
        return (sameDay ? "" : Qt.formatDate(new Date(at), "ddd ")) + Qt.formatTime(new Date(at), "HH:mm")
    }

    function refresh() {
        now = Date.now()
        verdictsFile.reload()
        pushFile.reload()
        priorityFile.reload()
        if (!status.running) status.running = true
    }
    function runNow() {
        if (running || starter.running) return
        error = ""
        state = "activating"
        starter.running = true
    }
    function openReport() {
        if (!latest) return
        Quickshell.execDetached(["kitty", "--class", "overseer", "--title", "overseer", "nvim", "-R", dir + "/" + latest.stamp + ".md"])
    }

    onRunningChanged: if (!running) refresh()
    Connections {
        target: Desktop
        function onShownChanged() { if (Desktop.shown) root.refresh() }
    }

    FileView {
        id: verdictsFile
        path: root.dir + "/verdicts.log"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.readVerdicts(text())
        onLoadFailed: root.verdicts = []
    }
    // The wrapper deletes push.txt when a run starts, so the last body stays until a new one lands.
    FileView {
        id: pushFile
        path: root.dir + "/push.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: if (text().trim() !== "") root.body = text().trim()
    }
    FileView {
        id: priorityFile
        path: root.dir + "/priority.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.priority = text().trim() || "default"
    }

    Process {
        id: status
        command: ["systemctl", "--user", "show", "overseer.timer", "overseer.service", "--timestamp=unix",
            "-p", "NextElapseUSecRealtime", "-p", "ActiveState", "-p", "Result", "-p", "ExecMainExitTimestamp"]
        stdout: StdioCollector { onStreamFinished: root.readStatus(text) }
    }
    Process {
        id: starter
        command: ["systemctl", "--user", "start", "--no-block", "overseer.service"]
        stderr: StdioCollector { id: starterError }
        onExited: code => {
            if (code !== 0) root.error = starterError.text.trim() || "Could not start overseer (exit " + code + ")"
            root.refresh()
        }
    }

    Component.onCompleted: refresh()
    Timer {
        interval: root.running ? 5000 : 30000
        running: Desktop.shown || root.running
        repeat: true
        onTriggered: root.refresh()
    }
}

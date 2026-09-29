pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property string proc: Quickshell.env("ACTIVITY_PROC") || "/proc"
    readonly property string hwmon: Quickshell.env("ACTIVITY_HWMON") || "/sys/class/hwmon"
    readonly property int interval: 2000
    readonly property int span: 90
    readonly property bool watching: Panels.open === "activity" || Desktop.shown

    property string host: ""
    property real uptime: 0
    property var load: [0, 0, 0]
    property int reads: 0

    property int cpu: 0
    property var cores: []
    property var cpuHistory: []
    property real temp: -1
    property string tempPath: ""
    property var lastStat: []

    property real memTotal: 0
    property real memUsed: 0
    property real swapTotal: 0
    property real swapUsed: 0
    readonly property int mem: memTotal > 0 ? Math.round(100 * memUsed / memTotal) : 0

    readonly property var link: Nm.wired.length > 0 ? Nm.wired[0] : Nm.wifi.length > 0 ? Nm.wifi[0] : null
    readonly property bool online: Nm.online
    readonly property string linkIcon: Nm.wired.length > 0 ? "󰈀" : Nm.wifi.length > 0 ? "󰤨" : "󰤮"
    property string iface: ""
    property real rx: 0
    property real tx: 0
    property var rxHistory: []
    property var txHistory: []
    property var lastNet: null
    readonly property real netLevel: Math.max(0, Math.min(1, Math.log(Math.max(1, (rx + tx) / 1000)) / Math.LN10 / 5))

    property var top: []

    function push(list, value) {
        var out = list.concat([value])
        return out.length > span ? out.slice(out.length - span) : out
    }
    function tone(percent) { return percent >= 90 ? Theme.red : percent >= 75 ? Theme.yellow : "" }
    function gib(kib) { return (kib / 1048576).toFixed(1) }
    function rate(bytes) {
        if (bytes < 1000) return Math.round(bytes) + " B/s"
        var units = ["kB/s", "MB/s", "GB/s"], i = -1
        do { bytes /= 1000; i++ } while (bytes >= 1000 && i < units.length - 1)
        return (bytes < 10 ? bytes.toFixed(1) : Math.round(bytes)) + " " + units[i]
    }
    function short(bytes) {
        if (bytes < 1000) return Math.round(bytes) + ""
        var units = ["k", "M", "G"], i = -1
        do { bytes /= 1000; i++ } while (bytes >= 1000 && i < units.length - 1)
        return (bytes < 10 ? bytes.toFixed(1) : Math.round(bytes)) + units[i]
    }
    function since(seconds) {
        var d = Math.floor(seconds / 86400), h = Math.floor(seconds % 86400 / 3600), m = Math.floor(seconds % 3600 / 60)
        return d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m"
    }

    function readStat(text) {
        var next = []
        var lines = text.split("\n")
        for (var i = 0; i < lines.length && lines[i].startsWith("cpu"); i++) {
            var f = lines[i].trim().split(/\s+/).slice(1).map(Number)
            next.push({ total: f.reduce(function(a, b) { return a + b }, 0), idle: f[3] + (f[4] || 0) })
        }
        var prev = lastStat
        lastStat = next
        reads++
        if (prev.length !== next.length || next.length === 0 || next[0].total <= prev[0].total) return
        var usage = next.map(function(n, i) {
            var span = n.total - prev[i].total
            return span > 0 ? Math.max(0, Math.min(100, Math.round(100 * (1 - (n.idle - prev[i].idle) / span)))) : 0
        })
        cpu = usage[0]
        cores = usage.slice(1)
        cpuHistory = push(cpuHistory, cpu)
    }

    function readMem(text) {
        var m = {}
        text.split("\n").forEach(function(l) {
            var p = l.split(/:\s+/)
            if (p.length === 2) m[p[0]] = parseInt(p[1])
        })
        memTotal = m.MemTotal || 0
        memUsed = memTotal - (m.MemAvailable || 0)
        swapTotal = m.SwapTotal || 0
        swapUsed = swapTotal - (m.SwapFree || 0)
    }

    // The link's own counters, so tunnels riding on it are not counted twice; every non-loopback device when offline.
    function readNet(text) {
        var counters = {}
        text.split("\n").slice(2).forEach(function(line) {
            var i = line.indexOf(":")
            if (i < 0) return
            var f = line.slice(i + 1).trim().split(/\s+/).map(Number)
            counters[line.slice(0, i).trim()] = { rx: f[0], tx: f[8] }
        })
        var dev = link && counters[link.device] ? link.device : ""
        var r = 0, t = 0
        for (var name in counters) {
            if (dev !== "" ? name !== dev : name === "lo") continue
            r += counters[name].rx
            t += counters[name].tx
        }
        var now = Date.now()
        var prev = lastNet
        lastNet = { dev: dev, rx: r, tx: t, at: now }
        iface = dev
        if (!prev || prev.dev !== dev || now <= prev.at) return
        var seconds = (now - prev.at) / 1000
        rx = Math.max(0, (r - prev.rx) / seconds)
        tx = Math.max(0, (t - prev.tx) / seconds)
        rxHistory = push(rxHistory, rx)
        txHistory = push(txHistory, tx)
    }

    // Parses top's second frame by its header, so custom toprc columns and spaced command names survive.
    function readTop(text) {
        var frames = text.split(/^top - /m)
        var lines = frames[frames.length - 1].split("\n")
        var head = -1
        for (var i = 0; i < lines.length; i++) if (/^\s*PID\s/.test(lines[i])) { head = i; break }
        if (head < 0) return
        var cols = lines[head].trim().split(/\s+/)
        var pid = cols.indexOf("PID"), pcpu = cols.indexOf("%CPU"), pmem = cols.indexOf("%MEM"), cmd = cols.indexOf("COMMAND")
        if (pcpu < 0 || cmd < 0) return
        var out = []
        lines.slice(head + 1).forEach(function(line) {
            var f = line.trim().split(/\s+/)
            if (f.length <= cmd) return
            var name = f.slice(cmd).join(" ")
            if (name === "top") return
            out.push({ pid: parseInt(f[pid]), name: name, cpu: parseFloat(f[pcpu]) || 0, mem: pmem < 0 ? 0 : parseFloat(f[pmem]) || 0 })
        })
        top = out.slice(0, 6)
    }

    FileView { id: stat; path: root.proc + "/stat"; onLoaded: root.readStat(text()) }
    FileView { id: meminfo; path: root.proc + "/meminfo"; onLoaded: root.readMem(text()) }
    FileView { id: netdev; path: root.proc + "/net/dev"; onLoaded: root.readNet(text()) }
    FileView { id: loadavg; path: root.proc + "/loadavg"; onLoaded: root.load = text().trim().split(/\s+/).slice(0, 3).map(Number) }
    FileView { id: uptimeFile; path: root.proc + "/uptime"; onLoaded: root.uptime = parseFloat(text()) || 0 }
    FileView { path: root.proc + "/sys/kernel/hostname"; onLoaded: root.host = text().trim() }
    FileView {
        id: sensor
        path: root.tempPath
        onLoaded: root.temp = Math.round(parseInt(text()) / 1000)
        onLoadFailed: root.temp = -1
    }

    Process {
        command: ["sh", "-c", "for h in \"$1\"/*; do case $(cat \"$h/name\" 2>/dev/null) in k10temp|coretemp|zenpower|cpu_thermal) echo \"$h/temp1_input\"; exit;; esac; done", "sh", root.hwmon]
        running: true
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }

    Process {
        id: topProc
        command: ["top", "-b", "-n", "2", "-d", "1", "-w", "512", "-o", "%CPU"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { onStreamFinished: root.readTop(text) }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload()
            meminfo.reload()
            netdev.reload()
            loadavg.reload()
            uptimeFile.reload()
            if (root.tempPath !== "") sensor.reload()
        }
    }

    Timer {
        interval: 1000
        running: root.watching
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!topProc.running) topProc.running = true
    }
}

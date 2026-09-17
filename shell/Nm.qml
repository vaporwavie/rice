pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var devices: []
    property var connections: []
    property string error: ""

    readonly property var active: connections.filter(function(c) { return c.active })
    readonly property var wired: active.filter(function(c) { return c.type === "802-3-ethernet" })
    readonly property var wifi: active.filter(function(c) { return c.type === "802-11-wireless" })
    readonly property bool online: wired.length > 0 || wifi.length > 0

    function refresh() { debounce.restart() }
    function up(name) { run(["nmcli", "connection", "up", "id", name]) }
    function down(name) { run(["nmcli", "connection", "down", "id", name]) }
    function run(cmd) {
        error = ""
        action.command = cmd
        action.running = true
    }
    function icon(type) {
        if (type === "802-3-ethernet") return "󰈀"
        if (type === "802-11-wireless") return "󰤨"
        if (type === "vpn" || type === "wireguard" || type === "tun") return "󰖂"
        if (type === "bridge" || type === "bond") return "󰛳"
        return "󰛳"
    }
    function fields(line) {
        var out = [], cur = ""
        for (var i = 0; i < line.length; i++) {
            var ch = line[i]
            if (ch === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
            if (ch === ":") { out.push(cur); cur = ""; continue }
            cur += ch
        }
        out.push(cur)
        return out
    }
    function device(name) {
        for (var i = 0; i < devices.length; i++) if (devices[i].name === name) return devices[i]
        return null
    }

    Timer { id: debounce; interval: 300; onTriggered: { devs.running = true; conns.running = true } }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

    Process {
        id: devs
        command: ["nmcli", "-t", "-f", "GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS", "device", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                text.split("\n\n").forEach(function(block) {
                    var d = { name: "", type: "", state: "", connection: "", ip: "" }
                    block.split("\n").forEach(function(line) {
                        var i = line.indexOf(":")
                        if (i < 0) return
                        var k = line.slice(0, i), v = line.slice(i + 1)
                        if (k === "GENERAL.DEVICE") d.name = v
                        else if (k === "GENERAL.TYPE") d.type = v
                        else if (k === "GENERAL.STATE") d.state = v.replace(/^\d+ \((.*)\)$/, "$1")
                        else if (k === "GENERAL.CONNECTION") d.connection = v
                        else if (k === "IP4.ADDRESS[1]") d.ip = v
                    })
                    if (d.name !== "" && d.type !== "loopback") out.push(d)
                })
                root.devices = out
            }
        }
    }

    Process {
        id: conns
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                text.split("\n").forEach(function(line) {
                    var f = root.fields(line)
                    if (f.length < 4 || f[1] === "loopback") return
                    var dev = root.device(f[2])
                    out.push({ name: f[0], type: f[1], device: f[2], active: f[3] === "yes", ip: dev ? dev.ip : "" })
                })
                out.sort(function(a, b) {
                    if (a.active !== b.active) return a.active ? -1 : 1
                    return a.name.localeCompare(b.name)
                })
                root.connections = out
            }
        }
    }

    Process {
        id: action
        stdout: StdioCollector { }
        stderr: StdioCollector { id: actionErr }
        onExited: code => {
            if (code !== 0) root.error = actionErr.text.trim().split("\n").pop().replace(/^Error: /, "")
            root.refresh()
        }
    }

    Process {
        id: monitor
        command: ["setpriv", "--pdeathsig", "TERM", "nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: root.refresh() }
    }
}

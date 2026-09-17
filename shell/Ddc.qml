pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int bus: -1
    property string model: ""
    property int brightness: -1
    property int contrast: -1
    property int preset: -1
    property int input: -1
    property var presetCodes: []
    property var inputCodes: []
    readonly property var presets: options(presetCodes, presetNames, preset)
    readonly property var inputs: options(inputCodes, inputNames, input)
    property string error: ""
    property var pending: ({})
    readonly property bool ready: bus >= 0 && brightness >= 0

    readonly property var presetNames: ({
        0x01: "sRGB", 0x02: "Native", 0x03: "4000K", 0x04: "5000K", 0x05: "6500K", 0x06: "7500K",
        0x07: "8200K", 0x08: "9300K", 0x09: "10000K", 0x0a: "11500K", 0x0b: "User 1", 0x0c: "User 2",
        0x0d: "User 3", 0x0e: "User 1", 0x0f: "User 2"
    })
    readonly property var inputNames: ({
        0x01: "VGA 1", 0x02: "VGA 2", 0x03: "DVI 1", 0x04: "DVI 2", 0x0f: "DisplayPort 1",
        0x10: "DisplayPort 2", 0x11: "HDMI 1", 0x12: "HDMI 2", 0x13: "USB-C"
    })

    function refresh() {
        if (bus < 0) detect.running = true
        else read.running = true
    }
    function setBrightness(v) {
        brightness = Math.max(0, Math.min(100, Math.round(v)))
        queue("10", brightness)
    }
    function setContrast(v) {
        contrast = Math.max(0, Math.min(100, Math.round(v)))
        queue("12", contrast)
    }
    function setPreset(code) { preset = code; queue("14", "x" + code.toString(16)) }
    function setInput(code) { input = code; queue("60", "x" + code.toString(16)) }

    function queue(vcp, value) {
        var p = pending
        p[vcp] = value
        pending = p
        flush.restart()
    }
    function next() {
        if (bus < 0 || writer.running) return
        var keys = Object.keys(pending)
        if (keys.length === 0) return
        var vcp = keys[0], value = pending[vcp]
        var p = pending
        delete p[vcp]
        pending = p
        error = ""
        writer.command = ["ddcutil", "--bus", String(bus), "setvcp", vcp, String(value), "--noverify"]
        writer.running = true
    }
    function options(codes, names, current) {
        var out = []
        codes.forEach(function(c) { out.push({ code: c, name: names[c] || ("0x" + c.toString(16)) }) })
        if (current >= 0 && !codes.some(function(c) { return c === current }))
            out.push({ code: current, name: names[current] || ("0x" + current.toString(16)) })
        return out
    }
    function parseValues(text) {
        text.split("\n").forEach(function(line) {
            var f = line.trim().split(/\s+/)
            if (f[0] !== "VCP") return
            var last = f[f.length - 1]
            if (f[1] === "10" && f[2] === "C") root.brightness = parseInt(f[3])
            else if (f[1] === "12" && f[2] === "C") root.contrast = parseInt(f[3])
            else if (f[1] === "14") root.preset = parseInt(last.replace(/^x/, ""), 16)
            else if (f[1] === "60") root.input = parseInt(last.replace(/^x/, ""), 16)
        })
    }
    function parseCodes(text, vcp) {
        var m = text.match(new RegExp("[\\s(]" + vcp + "\\(([0-9A-Fa-f ]+)\\)"))
        if (!m) return []
        return m[1].trim().split(/\s+/).map(function(h) { return parseInt(h, 16) })
    }

    Timer { id: flush; interval: 80; onTriggered: root.next() }
    Component.onCompleted: refresh()

    Process {
        id: detect
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                var bus = text.match(/I2C bus:\s+\/dev\/i2c-(\d+)/)
                var model = text.match(/Monitor:\s+[^:\n]*:([^:\n]*)/)
                if (!bus) { root.error = "no DDC monitor"; return }
                root.bus = parseInt(bus[1])
                root.model = model ? model[1].trim() : ""
                caps.running = true
                read.running = true
            }
        }
    }

    Process {
        id: caps
        command: ["ddcutil", "--bus", String(root.bus), "capabilities", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.presetCodes = root.parseCodes(text, "14")
                root.inputCodes = root.parseCodes(text, "60")
            }
        }
    }

    Process {
        id: read
        command: ["ddcutil", "--bus", String(root.bus), "getvcp", "10", "12", "14", "60", "--brief"]
        stdout: StdioCollector { onStreamFinished: root.parseValues(text) }
        stderr: StdioCollector { id: readErr }
        onExited: code => { if (code !== 0) root.error = readErr.text.trim().split("\n").pop() }
    }

    Process {
        id: writer
        stdout: StdioCollector { }
        stderr: StdioCollector { id: writerErr }
        onExited: code => {
            if (code !== 0) root.error = writerErr.text.trim().split("\n").pop()
            root.next()
        }
    }
}

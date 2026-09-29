pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "nina-format.js" as Format

// Follows the running Nina over its socket: `watch` streams one line per overlay change and
// microphone level, the first line after `ok` is the current state. Settings and history are
// read from Nina's own files, the app stays the only writer.
Singleton {
    id: root

    property string state: "hidden"
    property string message: ""
    property real level: 0
    property var levels: []
    readonly property bool active: state !== "hidden"
    readonly property int bars: 24

    readonly property string configDir: env("NINA_CONFIG_DIR", env("XDG_CONFIG_HOME", env("HOME", "") + "/.config") + "/nina")
    readonly property string dataDir: env("NINA_DATA_DIR", env("XDG_DATA_HOME", env("HOME", "") + "/.local/share") + "/nina")
    readonly property string socketPath: env("XDG_RUNTIME_DIR", "/tmp") + "/nina.sock"

    property string model: ""
    property string language: ""
    property var hotkey: []
    property bool fillers: true
    readonly property string modelName: Format.modelName(model)
    readonly property string languageLabel: Format.languageLabel(language)
    readonly property string hotkeyLabel: Format.comboLabel(hotkey)

    property var history: []
    readonly property var latest: history.length > 0 ? history[0] : null
    property int copiedId: -1
    property string lastError: ""

    function env(name, fallback) {
        var value = Quickshell.env(name)
        return value ? String(value) : fallback
    }

    function reset() {
        state = "hidden"
        message = ""
        level = 0
        levels = []
    }

    function push(value) {
        var next = levels.slice(Math.max(0, levels.length + 1 - bars))
        next.push(value)
        levels = next
    }

    function read(line) {
        var space = line.indexOf(" ")
        var head = space < 0 ? line : line.slice(0, space)
        var rest = space < 0 ? "" : line.slice(space + 1)
        if (head === "level") {
            level = Number(rest) || 0
            push(level)
        } else if (head === "overlay") {
            var sep = rest.indexOf(" ")
            state = sep < 0 ? rest : rest.slice(0, sep)
            message = sep < 0 ? "" : rest.slice(sep + 1)
            if (state === "error") lastError = message
            if (state !== "recording") levels = []
        }
    }

    function refresh() {
        settingsFile.reload()
        historyFile.reload()
    }

    // A second `nina` asks the running one to show its window and exits, a first one starts it.
    function openSettings() {
        Quickshell.execDetached(["nina"])
    }

    function copy(entry) {
        if (!entry) return
        copier.command = ["wl-copy", "--", entry.text]
        copier.running = true
        copiedId = entry.id
        copiedReset.restart()
    }

    readonly property bool connected: link.item ? link.item.connected : false

    // A Socket that failed to connect does not retry when `connected` is set again, so each
    // attempt is a fresh Socket.
    Loader {
        id: link
        active: true
        sourceComponent: Socket {
            path: root.socketPath
            connected: true
            parser: SplitParser { onRead: data => root.read(data.trim()) }
            onConnectionStateChanged: {
                if (connected) write("watch\n")
                else { root.reset(); retry.restart() }
            }
            onError: retry.restart()
        }
    }

    Timer {
        id: retry
        interval: 5000
        onTriggered: {
            if (root.connected) return
            link.active = false
            link.active = true
        }
    }

    FileView {
        id: settingsFile
        path: root.configDir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        property string raw: ""
        onLoaded: {
            if (text() === raw) return
            raw = text()
            try {
                var summary = Format.settingsSummary(raw)
                root.model = summary.model
                root.language = summary.language
                root.hotkey = summary.hotkey
                root.fillers = summary.fillers
            } catch (e) {
                console.warn("nina settings.json unreadable: " + e)
            }
        }
    }

    FileView {
        id: historyFile
        path: root.dataDir + "/history.jsonl"
        watchChanges: true
        onFileChanged: reload()
        // Unchanged reloads keep the same array so an open list keeps its scroll position.
        property string raw: ""
        onLoaded: {
            if (text() === raw) return
            raw = text()
            root.history = Format.parseHistory(raw)
        }
        onLoadFailed: { raw = ""; root.history = [] }
    }

    // Atomic renames can drop the inotify watch, so the files are also re-read while Nina runs.
    Timer {
        interval: 15000
        running: root.connected
        repeat: true
        onTriggered: root.refresh()
    }

    // Each take ends in hidden, and its history line lands right before that.
    onStateChanged: if (state === "hidden") historyFile.reload()

    Process { id: copier }

    Timer {
        id: copiedReset
        interval: 1200
        onTriggered: root.copiedId = -1
    }
}

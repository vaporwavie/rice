pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Follows the running Nina over its socket: `watch` streams one line per overlay change and
// microphone level, the first line after `ok` is the current state.
Singleton {
    id: root

    property string state: "hidden"
    property string message: ""
    property real level: 0
    property var levels: []
    readonly property bool active: state !== "hidden"
    readonly property int bars: 24

    function reset() {
        state = "hidden"
        message = ""
        level = 0
        levels = []
    }

    function push(value) {
        var next = levels.slice(levels.length + 1 - bars)
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
            if (state !== "recording") levels = []
        }
    }

    readonly property bool connected: link.item ? link.item.connected : false

    // A Socket that failed to connect does not retry when `connected` is set again, so each
    // attempt is a fresh Socket.
    Loader {
        id: link
        active: true
        sourceComponent: Socket {
            path: Quickshell.env("XDG_RUNTIME_DIR") + "/nina.sock"
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
}

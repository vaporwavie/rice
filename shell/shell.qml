import QtQuick
import Quickshell
import Quickshell.Io
import qs

ShellRoot {
    GroupIndicators {}

    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }

    Variants {
        model: Quickshell.screens
        NinaOverlay { required property var modelData; screen: modelData }
    }

    IpcHandler {
        target: "theme"
        function reload(): void { Theme.reload() }
    }

    IpcHandler {
        target: "panel"
        function toggle(name: string): void { Panels.toggle(name, "") }
        function close(): void { Panels.close() }
        function state(): string { return Panels.open }
    }

    IpcHandler {
        target: "nina"
        function state(): string { return (Nina.connected ? "connected " : "disconnected ") + Nina.state }
    }

    IpcHandler {
        target: "events"
        function state(): string {
            var next = NotionCalendar.next
            return (NotionCalendar.live ? "live " : "stale ") + NotionCalendar.events.length
                + (next ? " next " + next.title + " " + NotionCalendar.remaining(next.startsAt) : "")
        }
    }

    IpcHandler {
        target: "display"
        function brightness(delta: int): void { Ddc.setBrightness(Ddc.brightness + delta) }
        function set(value: int): void { Ddc.setBrightness(value) }
    }
}

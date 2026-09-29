import QtQuick
import Quickshell
import Quickshell.Io
import qs

ShellRoot {
    Variants {
        model: Quickshell.screens
        Pillar { required property var modelData; screen: modelData }
    }

    Variants {
        id: desktops
        model: Quickshell.screens
        DesktopWidgets { required property var modelData; screen: modelData }
    }

    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }

    Variants {
        model: Quickshell.screens
        MeetingToast { required property var modelData; screen: modelData }
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
        function alert(): string { return NotionCalendar.alert ? NotionCalendar.alert.title : "" }
        function dismiss(): void { NotionCalendar.dismiss() }
    }

    IpcHandler {
        target: "display"
        function brightness(delta: int): void { Ddc.setBrightness(Ddc.brightness + delta) }
        function set(value: int): void { Ddc.setBrightness(value) }
    }
    IpcHandler {
        target: "todoist"
        function state(): string {
            return JSON.stringify({ loaded: Todoist.loaded, loading: Todoist.loading,
                error: Todoist.error, actionError: Todoist.actionError,
                count: Todoist.items.length, overdue: Todoist.overdue.length,
                next: Todoist.next })
        }
        function refresh(): void { Todoist.refresh() }
    }

    IpcHandler {
        target: "activity"
        function state(): string {
            return JSON.stringify({ cpu: Activity.cpu, cores: Activity.cores, temp: Activity.temp,
                mem: Activity.mem, online: Activity.online, iface: Activity.iface,
                rx: Activity.rx, tx: Activity.tx, top: Activity.top })
        }
    }

    IpcHandler {
        target: "desktop"
        function state(): string {
            return JSON.stringify({ shown: Desktop.shown, watching: Activity.watching,
                visible: desktops.instances.filter(w => w.visible).map(w => w.screenName),
                todoist: Todoist.agenda("").reduce((n, group) => n + group.items.length, 0),
                events: NotionCalendar.events.length, top: Activity.top.length,
                overseer: Overseer.latest ? Overseer.latest.stamp : "" })
        }
        function leave(): void { Desktop.leave() }
    }

    IpcHandler {
        target: "overseer"
        function state(): string {
            return JSON.stringify({ latest: Overseer.latest, headline: Overseer.headline, priority: Overseer.priority,
                state: Overseer.state, result: Overseer.result, next: Overseer.next, verdicts: Overseer.verdicts.length,
                error: Overseer.error })
        }
        function refresh(): void { Overseer.refresh() }
    }

}

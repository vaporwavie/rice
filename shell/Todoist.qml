pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ../td finds td under any fnm Node and runs it without PATH or fnm's shell setup.
    readonly property string command: Quickshell.env("TD_BIN") || Quickshell.shellDir + "/../td"
    readonly property string webUrl: "https://app.todoist.com/app/today"
    property var items: []
    property real now: Date.now()
    property bool loaded: false
    property string error: ""
    property string actionError: ""
    property string actingOn: ""
    property bool refreshPending: false
    property int completions: 0
    property int readStart: 0
    readonly property bool loading: reader.running
    readonly property bool busy: action.running
    readonly property var overdue: items.filter(item => isOverdue(item))
    readonly property var today: items.filter(item => !isOverdue(item) && dayKey(item.at) === dayKey(now))
    readonly property var upcoming: items.filter(item => !isOverdue(item) && dayKey(item.at) !== dayKey(now))
    readonly property var next: items.find(item => !isOverdue(item)) || null
    readonly property var dayCounts: {
        var counts = {}
        for (var item of items) {
            var key = dayKey(item.at)
            counts[key] = (counts[key] || 0) + 1
        }
        return counts
    }

    function dayKey(value) { return Qt.formatDate(new Date(value), "yyyy-MM-dd") }

    function isOverdue(item) {
        if (item.allDay) return dayKey(item.at) < dayKey(now)
        return item.at < now
    }

    // Todoist sends "2026-09-23" (all day), "2026-09-30T10:00:00" (floating local) or "2026-10-10T13:00:00Z" (fixed zone).
    function parseDue(value) {
        var match = /^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$/.exec(value || "")
        if (!match) return null
        var year = Number(match[1]), month = Number(match[2]) - 1, day = Number(match[3])
        if (match[4] === undefined) return { at: new Date(year, month, day).getTime(), allDay: true }
        if (match[7] !== undefined) return { at: new Date(value).getTime(), allDay: false }
        return { at: new Date(year, month, day, Number(match[4]), Number(match[5]), Number(match[6] || 0)).getTime(), allDay: false }
    }

    function toItem(task) {
        if (!task || typeof task.id !== "string" || typeof task.content !== "string") throw new Error("Invalid task")
        var due = task.due || {}
        var parsed = parseDue(due.date)
        if (!parsed || !Number.isFinite(parsed.at)) throw new Error("Invalid due date")
        return { id: task.id, title: task.content, at: parsed.at, allDay: parsed.allDay,
            recurring: due.isRecurring === true, priority: task.priority || 1, url: task.url || "" }
    }

    function agenda(selected) {
        if (selected) return [{ title: Qt.formatDate(new Date(selected + "T12:00:00"), "dddd, MMM d"),
            items: items.filter(item => dayKey(item.at) === selected), overdue: false }]
        return [
            { title: "Overdue", items: overdue, overdue: true },
            { title: "Today", items: today, overdue: false },
            { title: "Upcoming", items: upcoming, overdue: false }
        ].filter(group => group.items.length > 0)
    }

    function when(item) {
        var time = item.allDay ? "All day" : Qt.formatTime(new Date(item.at), "HH:mm")
        return (dayKey(item.at) === dayKey(now) ? "" : Qt.formatDate(new Date(item.at), "ddd, MMM d") + " · ") + time
    }

    // With --json, td reports failures on stderr as {"error":{"message":...}}.
    function failure(text, fallback) {
        var trimmed = text.trim()
        try {
            var { error: { message = "" } = {} } = JSON.parse(trimmed) || {}
            if (typeof message === "string" && message) return message
        } catch (error) {}
        return trimmed || fallback
    }

    function refresh() {
        if (loading || busy) { refreshPending = true; return }
        refreshPending = false
        readStart = completions
        reader.running = true
    }

    function markDone(id) {
        if (busy || !items.some(item => item.id === id)) return
        actingOn = id
        actionError = ""
        action.command = ["/usr/bin/timeout", "20s", command, "task", "complete", "id:" + id]
        action.running = true
    }

    function openApp() {
        Quickshell.execDetached(["xdg-open", webUrl])
    }

    Component.onCompleted: refresh()
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: { root.now = Date.now(); root.refresh() }
    }

    Process {
        id: reader
        command: ["/usr/bin/timeout", "20s", root.command, "upcoming", "30", "--json", "--all"]
        stdout: StdioCollector { id: listOutput }
        stderr: StdioCollector { id: listError }
        onExited: (code, status) => {
            root.now = Date.now()
            // A read that started before a completion would bring the completed task back.
            if (root.readStart !== root.completions) {
                Qt.callLater(root.refresh)
                return
            }
            if (code !== 0 || status !== 0) {
                root.error = root.failure(listError.text, "Could not load Todoist (exit " + code + ")")
            } else {
                try {
                    var output = JSON.parse(listOutput.text)
                    if (!output || !Array.isArray(output.results)) throw new Error("Invalid agenda")
                    root.items = output.results.map(task => root.toItem(task))
                        .sort((a, b) => a.at - b.at || b.priority - a.priority)
                    root.loaded = true
                    root.error = ""
                } catch (error) {
                    root.error = "Could not read Todoist's agenda"
                }
            }
            if (root.refreshPending) Qt.callLater(root.refresh)
        }
    }

    Process {
        id: action
        stdout: StdioCollector { }
        stderr: StdioCollector { id: actionOutput }
        onExited: (code, status) => {
            if (code !== 0 || status !== 0)
                root.actionError = root.failure(actionOutput.text, "Todoist action failed (exit " + code + ")")
            // Completing twice would skip a recurring occurrence, so hide the task until the refresh lands.
            else {
                root.completions += 1
                root.items = root.items.filter(item => item.id !== root.actingOn)
            }
            root.actingOn = ""
            Qt.callLater(root.refresh)
        }
    }
}

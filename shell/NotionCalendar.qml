pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "calendar-feed.mjs" as Feed

Singleton {
    id: root

    property real now: Date.now()
    property string raw: ""
    readonly property bool live: Feed.isLive(raw, now)
    readonly property var events: Feed.upcoming(Feed.parseFeed(raw, now), now)
    readonly property var next: Feed.nextToday(events, now)
    readonly property var days: Feed.groupByDay(events, now)

    property var alert: null
    property string dismissed: ""

    onEventsChanged: refreshAlert()
    onNowChanged: refreshAlert()

    function remaining(startsAt) { return Feed.remaining(startsAt, now) }
    function openApp() { Qt.openUrlExternally("cron://") }
    function refreshAlert() { alert = Feed.nextAlert(alert, dismissed, events, now) }
    function dismiss() {
        if (!alert) return
        dismissed = Feed.eventKey(alert)
        alert = null
    }
    function join() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/notion-calendar-linux", "--join"])
        dismiss()
    }

    FileView {
        id: file
        path: Quickshell.env("NOTION_CALENDAR_FEED")
            || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/notion-calendar-linux/panel.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { root.now = Date.now(); root.raw = text() }
        onLoadFailed: { root.now = Date.now(); root.raw = "" }
    }

    // The app replaces the file by rename, which can drop the watch.
    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: { root.now = Date.now(); file.reload() }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "windows.js" as Logic

Singleton {
    id: root
    readonly property var clients: Hyprland.toplevels.values.map(function(window) { return window.lastIpcObject })

    function onScreen(screen) {
        var monitor = screen ? Hyprland.monitorFor(screen) : null
        if (!monitor || !monitor.activeWorkspace) return []
        var special = monitor.lastIpcObject.specialWorkspace
        return Logic.workspaceWindows(clients, special && special.id ? special.id : monitor.activeWorkspace.id)
    }

    function focus(address) {
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + address + "\" })")
    }

    Component.onCompleted: Hyprland.refreshToplevels()

    Connections {
        target: Hyprland
        function onRawEvent(event) { refresh.restart() }
    }

    Timer {
        id: refresh
        interval: 40
        onTriggered: {
            Hyprland.refreshToplevels()
            Hyprland.refreshMonitors()
        }
    }
}

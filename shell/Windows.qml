pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "groups.js" as Logic

Singleton {
    id: root
    readonly property var clients: Hyprland.toplevels.values.map(function(window) { return window.lastIpcObject })
    readonly property var focused: Logic.focusedGroup(clients)

    Component.onCompleted: Hyprland.refreshToplevels()

    Connections {
        target: Hyprland
        function onRawEvent(event) { refresh.restart() }
    }

    Timer {
        id: refresh
        interval: 40
        onTriggered: Hyprland.refreshToplevels()
    }
}

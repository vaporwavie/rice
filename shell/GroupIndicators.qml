import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "group-dots.js" as Dots
import qs

Scope {
    id: root
    readonly property var clients: Hyprland.toplevels.values.map(function(window) { return window.lastIpcObject })
    readonly property bool hasGroups: clients.some(function(client) { return client.grouped && client.grouped.length > 1 })

    function appIcon(appId) {
        var entry = DesktopEntries.heuristicLookup(appId)
        return Quickshell.iconPath(entry && entry.icon ? entry.icon : appId, "application-x-executable")
    }

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

    // Hyprland does not emit geometry events while dragging or resizing windows.
    Timer {
        interval: 150
        repeat: true
        running: root.hasGroups
        onTriggered: Hyprland.refreshToplevels()
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: overlay
            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property var dots: Dots.indicators(root.clients, monitor ? monitor.lastIpcObject : null)
            screen: modelData
            visible: dots.length > 0
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "group-indicators"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Repeater {
                model: overlay.dots
                Row {
                    id: row
                    required property var modelData
                    x: modelData.x - width
                    y: modelData.y
                    spacing: 2
                    Repeater {
                        model: row.modelData.apps
                        Rectangle {
                            id: tile
                            required property int index
                            required property var modelData
                            readonly property bool active: index === row.modelData.active
                            width: 24
                            height: 24
                            color: Theme.bg
                            border.width: 1
                            border.color: active ? Theme.accent : Theme.muted

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 16
                                source: root.appIcon(tile.modelData.appId)
                                opacity: tile.active ? 1 : 0.6
                            }
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: 2
                                color: tile.active ? Theme.accent : "transparent"
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "groups"
        function state(): string {
            return JSON.stringify(Hyprland.monitors.values.map(function(monitor) {
                return { monitor: monitor.name, indicators: Dots.indicators(root.clients, monitor.lastIpcObject) }
            }))
        }
    }
}

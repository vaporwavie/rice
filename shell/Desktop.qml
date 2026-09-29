pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property string workspace: "desktop"
    readonly property bool shown: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.name === workspace

    onShownChanged: if (shown) { Todoist.refresh(); Nm.refresh() }

    // Apps launched from the desktop would open on it, so step back to the previous workspace first.
    function leave() {
        if (shown) Hyprland.dispatch("hl.dsp.focus({ workspace = \"previous\" })")
    }
}

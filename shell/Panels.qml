pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property string open: ""
    property string screenName: ""
    property bool fromPointer: false
    property var active: null

    function toggle(name, screen) {
        if (open === name) {
            open = ""
            return
        }
        screenName = screen || (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")
        fromPointer = !!screen
        open = name
    }

    function close() { open = "" }

    // Swaps panels on the same screen and keeps the input mode, so a keyboard hop stays keyboard driven.
    function replace(name) { open = name }

    function isOpen(name, screen) {
        return open === name && (screenName === "" || screenName === screen)
    }
}

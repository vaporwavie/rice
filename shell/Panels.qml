pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property string open: ""
    property string screenName: ""

    function toggle(name, screen) {
        if (open === name) {
            open = ""
            return
        }
        screenName = screen || (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")
        open = name
    }

    function close() { open = "" }

    function isOpen(name, screen) {
        return open === name && (screenName === "" || screenName === screen)
    }
}

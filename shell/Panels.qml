pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property string open: ""
    property string screenName: ""
    property bool fromPointer: false

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

    function isOpen(name, screen) {
        return open === name && (screenName === "" || screenName === screen)
    }
}

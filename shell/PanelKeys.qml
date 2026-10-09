import QtQuick
import qs

// A keyboard-opened panel has no pointer serial for a popup grab, so the Hyprland grab leaves focus on
// the window the panel hangs from; this hands those keys to the open panel.
Item {
    focus: true
    Keys.onPressed: event => { event.accepted = Panels.active ? Panels.active.handleKey(event) : false }
}

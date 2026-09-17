import QtQuick
import Quickshell.Bluetooth
import qs

BarButton {
    id: root
    property var bar
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connected: {
        if (!adapter) return []
        return adapter.devices.values.filter(function(d) { return d.connected })
    }

    visible: adapter !== null
    text: !adapter || !adapter.enabled ? "󰂲" : connected.length > 0 ? "󰂱" : "󰂯"
    color: adapter && adapter.enabled ? Theme.fg : Theme.muted
    tip: !adapter ? "" : !adapter.enabled ? "bluetooth off"
       : connected.length > 0 ? connected.map(function(d) { return d.name }).join(", ") : "no devices connected"
    onClicked: bar.togglePanel("bluetooth")

    BluetoothPanel { anchorItem: root; open: bar.panelOpen("bluetooth") }
}

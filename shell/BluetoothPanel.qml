import QtQuick
import Quickshell.Bluetooth
import qs

Panel {
    id: root
    name: "bluetooth"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: {
        if (!adapter || !adapter.enabled) return []
        var out = adapter.devices.values.slice()
        out.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return (a.name || "").localeCompare(b.name || "")
        })
        return out.filter(function(d) { return d.paired || (d.name && d.name !== d.address) }).slice(0, 12)
    }

    onOpenChanged: if (adapter && adapter.enabled) adapter.discovering = open

    function icon(d) {
        var i = d.icon || ""
        if (/headset|headphone/.test(i)) return "󰋋"
        if (/audio|speaker/.test(i)) return "󰓃"
        if (/mouse/.test(i)) return "󰍽"
        if (/keyboard/.test(i)) return "󰌌"
        if (/phone/.test(i)) return "󰏲"
        return "󰂯"
    }
    function trailing(d) {
        if (d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting || d.pairing) return "…"
        if (d.connected) return d.batteryAvailable ? Math.round(d.battery * 100) + "%" : "connected"
        return d.paired ? "" : "new"
    }
    function act(d) {
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else d.pair()
    }

    Column {
        width: parent.width
        PanelRow {
            icon: adapter && adapter.enabled ? "󰂯" : "󰂲"
            text: "Bluetooth"
            trailing: adapter && adapter.enabled ? (adapter.discovering ? "scanning" : "on") : "off"
            onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
        Repeater {
            model: root.devices
            PanelRow {
                required property var modelData
                icon: root.icon(modelData)
                active: modelData.connected
                text: modelData.name || modelData.address
                trailing: root.trailing(modelData)
                onClicked: root.act(modelData)
            }
        }
    }
}

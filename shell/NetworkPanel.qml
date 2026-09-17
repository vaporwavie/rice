import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs

Panel {
    id: root
    name: "network"

    readonly property var wifi: {
        var d = Networking.devices ? Networking.devices.values : []
        for (var i = 0; i < d.length; i++) if (d[i].type === DeviceType.Wifi) return d[i]
        return null
    }
    readonly property var networks: {
        if (!wifi || !wifi.networks) return []
        var out = wifi.networks.values.slice()
        out.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return b.signalStrength - a.signalStrength
        })
        return out.slice(0, 12)
    }
    property string askSsid: ""
    property string status: ""

    function secured(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }
    function signalIcon(s) { return s > 0.75 ? "󰤨" : s > 0.5 ? "󰤥" : s > 0.25 ? "󰤢" : "󰤟" }
    function act(n) {
        status = ""
        if (n.connected) { n.disconnect(); return }
        if (n.known || !secured(n)) { n.connect(); return }
        askSsid = n.name
        password.text = ""
        password.forceActiveFocus()
    }
    function submit() {
        connectProc.command = ["nmcli", "device", "wifi", "connect", askSsid, "password", password.text]
        connectProc.running = true
        status = "connecting to " + askSsid
        askSsid = ""
    }

    onOpenChanged: {
        if (wifi) wifi.scannerEnabled = open
        if (open) Nm.refresh()
        else { askSsid = ""; status = "" }
    }

    Process {
        id: connectProc
        stdout: StdioCollector { }
        stderr: StdioCollector { id: err }
        onExited: code => root.status = code === 0 ? "" : err.text.trim().split("\n").pop()
    }

    Column {
        width: parent.width

        Repeater {
            model: Nm.connections.filter(function(c) { return c.type !== "802-11-wireless" })
            PanelRow {
                required property var modelData
                icon: Nm.icon(modelData.type)
                active: modelData.active
                text: modelData.name
                trailing: modelData.active ? (modelData.ip !== "" ? modelData.ip : modelData.device) : ""
                onClicked: modelData.active ? Nm.down(modelData.name) : Nm.up(modelData.name)
            }
        }
        Repeater {
            model: Networking.wifiEnabled ? root.networks : []
            PanelRow {
                required property var modelData
                icon: root.signalIcon(modelData.signalStrength)
                active: modelData.connected
                text: modelData.name
                trailing: modelData.stateChanging ? "…" : modelData.connected ? "connected" : root.secured(modelData) ? "󰌾" : ""
                onClicked: root.act(modelData)
            }
        }
        PanelRow {
            icon: Networking.wifiEnabled ? "󰤨" : "󰤮"
            text: "Wi-Fi"
            trailing: !Networking.wifiHardwareEnabled ? "hardware off" : Networking.wifiEnabled ? "on" : "off"
            enabled: Networking.wifiHardwareEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }

        Item {
            width: parent.width
            height: root.askSsid !== "" ? Theme.rowHeight + 6 : 0
            visible: root.askSsid !== ""
            Rectangle {
                anchors { fill: parent; margins: 3; leftMargin: 6; rightMargin: 6 }
                color: Theme.bgAlt
                border.color: Theme.accent
                border.width: 1
                TextInput {
                    id: password
                    anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    color: Theme.fg
                    onAccepted: root.submit()
                    Keys.onEscapePressed: root.askSsid = ""
                    Label { visible: password.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "password for " + root.askSsid; dim: true }
                }
            }
        }
        Label {
            visible: root.status !== "" || Nm.error !== ""
            text: root.status !== "" ? root.status : Nm.error
            color: Theme.yellow
            leftPadding: 6; height: Theme.rowHeight; width: parent.width
        }
    }
}

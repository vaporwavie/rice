import QtQuick
import qs

BarButton {
    id: root
    property var bar
    readonly property var link: Nm.wired.length > 0 ? Nm.wired[0] : Nm.wifi.length > 0 ? Nm.wifi[0] : null

    text: Nm.wired.length > 0 ? "󰈀" : Nm.wifi.length > 0 ? "󰤨" : "󰤮"
    color: Nm.online ? Theme.fg : Theme.red
    tip: link ? link.name + "  " + link.device + "  " + link.ip : "disconnected"
    onClicked: bar.togglePanel("network")

    NetworkPanel { anchorItem: root; open: bar.panelOpen("network") }
}

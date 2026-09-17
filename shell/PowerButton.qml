import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

BarButton {
    id: root
    property var bar
    text: "󰐥"
    onClicked: bar.togglePanel("power")

    Panel {
        anchorItem: root
        name: "power"
        open: bar.panelOpen("power")
        contentWidth: 180
        Column {
            width: parent.width
            PanelRow { icon: "󰌾"; text: "Lock"; onClicked: { Panels.close(); Quickshell.execDetached([Quickshell.shellDir + "/../lock"]) } }
            PanelRow { icon: "󰤄"; text: "Suspend"; onClicked: { Panels.close(); Quickshell.execDetached(["systemctl", "suspend"]) } }
            PanelRow { icon: "󰍃"; text: "Log out"; onClicked: { Panels.close(); Hyprland.dispatch("hl.dsp.exit()") } }
            PanelRow { icon: "󰜉"; text: "Reboot"; onClicked: { Panels.close(); Quickshell.execDetached(["systemctl", "reboot"]) } }
            PanelRow { icon: "󰐥"; text: "Power off"; onClicked: { Panels.close(); Quickshell.execDetached(["systemctl", "poweroff"]) } }
        }
    }
}

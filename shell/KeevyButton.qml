import QtQuick
import qs

BarButton {
    id: root
    property var bar
    text: "󰌢"
    tip: "Keevy"
    color: bar.panelOpen("keevy") || Keevy.busy ? Theme.accent : Theme.fg
    onClicked: bar.togglePanel("keevy")

    KeevyPanel {
        anchorItem: root
        open: bar.panelOpen("keevy")
    }
}

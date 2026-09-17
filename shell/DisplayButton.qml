import QtQuick
import qs

BarButton {
    id: root
    property var bar

    visible: Ddc.bus >= 0
    text: Ddc.brightness < 34 ? "󰃞" : Ddc.brightness < 67 ? "󰃟" : "󰃠"
    tip: Ddc.ready ? Ddc.brightness + "%  " + Ddc.model : "reading display"
    onClicked: bar.togglePanel("display")
    onWheel: wheel => { if (Ddc.ready) Ddc.setBrightness(Ddc.brightness + (wheel.angleDelta.y > 0 ? 5 : -5)) }

    DisplayPanel { anchorItem: root; open: bar.panelOpen("display") }
}

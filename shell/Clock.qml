import QtQuick
import Quickshell
import qs

BarButton {
    id: root
    property var bar
    icon: false
    padding: 8
    text: Qt.formatDateTime(clock.date, "dddd HH:mm")
    onClicked: bar.togglePanel("calendar")

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Calendar { anchorItem: root; open: bar.panelOpen("calendar") }
}

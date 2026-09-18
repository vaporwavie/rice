import QtQuick
import Quickshell
import qs
import "clock-format.js" as ClockFormat

BarButton {
    id: root
    property var bar
    icon: false
    padding: 8
    text: Qt.formatDateTime(clock.date, "dddd ") + ClockFormat.ordinalDay(clock.date.getDate())
        + Qt.formatDateTime(clock.date, ", HH:mm")
    onClicked: bar.togglePanel("calendar")

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Calendar { anchorItem: root; open: bar.panelOpen("calendar") }
}

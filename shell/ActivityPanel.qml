import QtQuick
import qs

Panel {
    id: root
    name: "activity"
    contentWidth: 340
    onOpenChanged: if (open) Nm.refresh()

    ActivityView {
        width: root.contentWidth
        onConnections: Panels.toggle("network", Panels.screenName)
    }
}

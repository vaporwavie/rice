import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

Row {
    id: root
    readonly property var group: Groups.focused
    visible: group !== null
    leftPadding: 10
    spacing: 2

    function appIcon(appId) {
        var entry = DesktopEntries.heuristicLookup(appId)
        return Quickshell.iconPath(entry && entry.icon ? entry.icon : appId, "application-x-executable")
    }

    Repeater {
        model: root.group ? root.group.apps : []
        Item {
            id: tab
            required property int index
            required property var modelData
            readonly property bool active: index === root.group.active
            implicitWidth: 22
            implicitHeight: Theme.barHeight

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: root.appIcon(tab.modelData.appId)
                opacity: tab.active ? 1 : 0.45
            }
        }
    }
}

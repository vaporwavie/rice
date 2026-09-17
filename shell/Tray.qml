import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

RowLayout {
    id: root
    property var bar
    spacing: 0

    Repeater {
        model: SystemTray.items
        Item {
            id: entry
            required property var modelData
            readonly property string key: "tray:" + modelData.id
            implicitWidth: 26
            implicitHeight: Theme.barHeight

            IconImage {
                anchors.centerIn: parent
                implicitSize: 14
                source: entry.modelData.icon
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouse => {
                    var item = entry.modelData
                    if (mouse.button === Qt.MiddleButton) item.secondaryActivate()
                    else if (mouse.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) root.bar.togglePanel(entry.key)
                    } else item.activate()
                }
                onWheel: wheel => entry.modelData.scroll(wheel.angleDelta.y, false)
            }
            Tooltip {
                anchorItem: entry
                text: entry.modelData.tooltipTitle || entry.modelData.title
                open: area.containsMouse && text !== "" && !root.bar.panelOpen(entry.key)
            }
            TrayMenu {
                anchorItem: entry
                item: entry.modelData
                open: root.bar.panelOpen(entry.key)
            }
        }
    }
}

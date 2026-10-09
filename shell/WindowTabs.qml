import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

Row {
    id: root
    property var bar
    readonly property var windows: Windows.onScreen(bar ? bar.screen : null)
    property Item hovered: null
    property string hoveredTitle: ""
    visible: windows.length > 0
    leftPadding: 10
    spacing: 2

    function appIcon(appId) {
        var entry = DesktopEntries.heuristicLookup(appId)
        return Quickshell.iconPath(entry && entry.icon ? entry.icon : appId, "application-x-executable")
    }

    Repeater {
        model: root.windows
        Item {
            id: target
            required property var modelData
            readonly property var tabs: modelData.members.length > 0 ? modelData.members : [modelData]
            implicitWidth: strip.implicitWidth + 8
            implicitHeight: Theme.barHeight

            // A group is one Alt+Tab stop; its pill holds every tab, the shown one at full strength.
            Rectangle {
                anchors.centerIn: parent
                width: strip.implicitWidth + 4
                height: 24
                radius: 6
                color: Theme.bgElev
                border.color: Theme.border
                visible: target.modelData.members.length > 0
            }

            Row {
                id: strip
                anchors.centerIn: parent
                Repeater {
                    model: target.tabs
                    Item {
                        id: tab
                        required property var modelData
                        readonly property bool lit: target.modelData.active && (tab.modelData.shown !== false)
                        implicitWidth: 24
                        implicitHeight: Theme.barHeight

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 16
                            source: root.appIcon(tab.modelData.appId)
                            opacity: tab.lit || area.containsMouse ? 1 : target.modelData.next && tab.modelData.shown !== false ? 0.75 : 0.4
                            Behavior on opacity { NumberAnimation { duration: Theme.quick; easing.type: Theme.easing } }
                        }

                        // The next Alt+Tab stop wears a dot, the focused window the accent line.
                        Rectangle {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
                            width: 3; height: 3; radius: 1.5
                            color: Theme.fgDim
                            visible: target.modelData.next && tab.modelData.shown !== false
                        }
                        Rectangle {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                            width: 16; height: 2
                            color: Theme.accent
                            visible: tab.lit
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            onContainsMouseChanged: {
                                if (containsMouse) {
                                    root.hovered = tab
                                    root.hoveredTitle = tab.modelData.title || tab.modelData.appId
                                } else if (root.hovered === tab) {
                                    root.hovered = null
                                }
                            }
                            onClicked: Windows.focus(tab.modelData.address)
                        }
                    }
                }
            }
        }
    }

    Tooltip {
        anchorItem: root.hovered || root
        text: root.hoveredTitle
        open: root.hovered !== null
    }
}

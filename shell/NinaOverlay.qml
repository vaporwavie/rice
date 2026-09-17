import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

// Nina's recording panel as a layer-shell surface, so it never enters the tiling layout or
// takes focus. Bottom center of the focused monitor, sized like Nina's own overlay.
PanelWindow {
    id: root

    readonly property bool focusedHere: !Hyprland.focusedMonitor || !screen || Hyprland.focusedMonitor.name === screen.name
    readonly property color tone: Nina.state === "transcribing" ? Theme.yellow : Theme.red

    visible: Nina.active && focusedHere
    anchors.bottom: true
    margins.bottom: 24
    implicitWidth: 240
    implicitHeight: 72
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nina-overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.color: root.tone
        border.width: Theme.panelBorder

        Row {
            anchors.centerIn: parent
            spacing: 10
            visible: Nina.state === "recording"

            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: Theme.red
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    running: Nina.state === "recording"
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 600 }
                    NumberAnimation { to: 1; duration: 600 }
                }
            }

            Row {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: Nina.bars
                    Rectangle {
                        required property int index
                        readonly property int slot: index - (Nina.bars - Nina.levels.length)
                        readonly property real value: slot >= 0 ? Nina.levels[slot] : 0
                        width: 4
                        height: 4 + Math.round(Math.min(1, value * 1.6) * 28)
                        color: slot >= 0 ? Theme.accent : Theme.border
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on height { NumberAnimation { duration: 40 } }
                    }
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 10
            visible: Nina.state === "transcribing"

            Label {
                text: "󰑓"
                icon: true
                color: Theme.yellow
                anchors.verticalCenter: parent.verticalCenter
                RotationAnimation on rotation {
                    running: Nina.state === "transcribing"
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }
            Label { text: "Transcribing"; anchors.verticalCenter: parent.verticalCenter }
        }

        Label {
            anchors.centerIn: parent
            width: parent.width - 32
            horizontalAlignment: Text.AlignHCenter
            visible: Nina.state === "error"
            color: Theme.red
            text: Nina.message || "Something went wrong"
        }
    }
}

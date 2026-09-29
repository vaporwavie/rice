import QtQuick
import qs

// Nina in the bar: the icon takes the take's color, a small level strip slides out while
// recording. Left click opens the quick panel, right click the full one, middle click the app.
Item {
    id: root
    property var bar
    readonly property bool open: bar.panelOpen("nina") || bar.panelOpen("nina-full")
    readonly property bool recording: Nina.state === "recording"
    readonly property int strip: 8
    readonly property color tone: {
        if (!Nina.connected) return Theme.muted
        if (Nina.state === "recording" || Nina.state === "error") return Theme.red
        if (Nina.state === "transcribing") return Theme.yellow
        return area.containsMouse || root.open ? Theme.fg : Theme.fgDim
    }

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        NinaIcon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            size: Theme.iconSize
            color: root.tone
            Behavior on color { ColorAnimation { duration: Theme.quick; easing.type: Theme.easing } }

            SequentialAnimation on opacity {
                running: Nina.state === "transcribing"
                loops: Animation.Infinite
                onRunningChanged: if (!running) icon.opacity = 1
                NumberAnimation { to: 0.35; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutSine }
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            height: 16
            width: root.recording ? meter.width + 7 : 0
            clip: true
            Behavior on width { NumberAnimation { duration: Theme.quick; easing.type: Theme.easing } }

            Row {
                id: meter
                x: 7
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: root.strip
                    Rectangle {
                        required property int index
                        readonly property int slot: Nina.levels.length - root.strip + index
                        readonly property real value: slot >= 0 ? Nina.levels[slot] : 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        radius: 1
                        height: 3 + Math.round(Math.min(1, value * 1.6) * 13)
                        color: Theme.fg
                        opacity: slot >= 0 ? 1 : 0.3
                        Behavior on height { NumberAnimation { duration: 60 } }
                    }
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) Nina.openSettings()
            else root.bar.togglePanel(mouse.button === Qt.RightButton ? "nina-full" : "nina")
        }
    }

    Tooltip {
        anchorItem: root
        open: area.containsMouse && !root.open
        text: !Nina.connected ? "Nina is not running"
            : Nina.state === "recording" ? "Listening"
            : Nina.state === "transcribing" ? "Transcribing"
            : "Nina · hold " + Nina.hotkeyLabel
    }

    NinaPanel { anchorItem: root; open: root.bar.panelOpen("nina") }
    NinaFull { anchorItem: root; open: root.bar.panelOpen("nina-full") }
}

import QtQuick
import Quickshell.Services.Pipewire
import qs

BarButton {
    id: root
    property var bar
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink && sink.audio
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : true
    readonly property bool headphones: ready && /headphone|headset/i.test((sink.description || "") + (sink.name || ""))
    readonly property string glyph: !ready || muted ? "󰝟" : headphones ? "󰋋" : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"
    readonly property color tint: muted ? Theme.muted : hovered || revealed ? Theme.fg : Theme.fgDim
    property bool armed: false
    property bool revealed: false

    function reveal() {
        if (!armed) return
        revealed = true
        hide.restart()
    }

    text: ""
    implicitWidth: content.width + padding * 2
    tip: revealed ? "" : ready ? Math.round(volume * 100) + "%  " + (sink.description || sink.name) : "no sink"

    onVolumeChanged: reveal()
    onMutedChanged: reveal()

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) { if (ready) sink.audio.muted = !sink.audio.muted }
        else bar.togglePanel("audio")
    }
    onWheel: wheel => {
        if (!ready) return
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
    }

    // Pipewire reports the initial volume a beat after the sink binds; don't treat that as a change.
    Timer { running: root.ready && !root.armed; interval: 1000; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1600; onTriggered: root.revealed = false }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 0

        Label {
            anchors.verticalCenter: parent.verticalCenter
            icon: true
            text: root.glyph
            color: root.tint
        }

        Item {
            id: meter
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.barHeight
            width: root.revealed ? readout.width : 0
            clip: true
            Behavior on width { NumberAnimation { duration: Theme.quick; easing.type: Theme.easing } }

            Row {
                id: readout
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 8
                spacing: 8
                opacity: root.revealed ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.quick; easing.type: Theme.easing } }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 56
                    height: 3
                    color: Theme.bgElev
                    Rectangle {
                        width: parent.width * Math.min(1, root.volume)
                        height: parent.height
                        color: root.muted ? Theme.muted : Theme.accent
                        Behavior on width { NumberAnimation { duration: Theme.quick; easing.type: Theme.easing } }
                    }
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    horizontalAlignment: Text.AlignLeft
                    text: root.muted ? "mute" : Math.round(root.volume * 100) + "%"
                    color: root.tint
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    AudioPanel { anchorItem: root; open: bar.panelOpen("audio") }
}

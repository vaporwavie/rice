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

    text: !ready || muted ? "󰝟" : headphones ? "󰋋" : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"
    color: muted ? Theme.muted : Theme.fg
    tip: ready ? Math.round(volume * 100) + "%  " + (sink.description || sink.name) : "no sink"

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) { if (ready) sink.audio.muted = !sink.audio.muted }
        else bar.togglePanel("audio")
    }
    onWheel: wheel => {
        if (!ready) return
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    AudioPanel { anchorItem: root; open: bar.panelOpen("audio") }
}

import QtQuick
import Quickshell.Services.Pipewire
import qs

Panel {
    id: root
    name: "audio"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: nodes(true)
    readonly property var sources: nodes(false)

    function nodes(sinkSide) {
        var out = []
        var all = Pipewire.nodes.values
        for (var i = 0; i < all.length; i++) {
            var n = all[i]
            if (!n || n.isStream || n.isSink !== sinkSide || !n.audio) continue
            if (!sinkSide && !/audio\/source/i.test(n.type + "") && n.type !== PwNodeType.AudioSource) continue
            out.push(n)
        }
        return out
    }
    function label(n) { return n.description || n.nickname || n.name }
    function pct(n) { return n && n.audio && !isNaN(n.audio.volume) ? Math.round(n.audio.volume * 100) + "%" : "" }

    PwObjectTracker { objects: root.sinks }
    PwObjectTracker { objects: root.sources }

    Column {
        width: parent.width

        PanelHeader { text: "Output" }
        Slider {
            value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
            muted: root.sink && root.sink.audio ? root.sink.audio.muted : true
            onMoved: v => { if (root.sink && root.sink.audio) root.sink.audio.volume = v }
        }
        Repeater {
            model: root.sinks
            PanelRow {
                required property var modelData
                readonly property bool isDefault: root.sink === modelData
                icon: isDefault ? "󰄬" : " "
                active: isDefault
                text: root.label(modelData)
                trailing: modelData.audio.muted ? "muted" : root.pct(modelData)
                onClicked: {
                    if (isDefault) modelData.audio.muted = !modelData.audio.muted
                    else Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        Item { width: 1; height: 6 }
        PanelHeader { text: "Input" }
        Slider {
            value: root.source && root.source.audio ? root.source.audio.volume : 0
            muted: root.source && root.source.audio ? root.source.audio.muted : true
            onMoved: v => { if (root.source && root.source.audio) root.source.audio.volume = v }
        }
        Repeater {
            model: root.sources
            PanelRow {
                required property var modelData
                readonly property bool isDefault: root.source === modelData
                icon: isDefault ? "󰄬" : " "
                active: isDefault
                text: root.label(modelData)
                trailing: modelData.audio.muted ? "muted" : root.pct(modelData)
                onClicked: {
                    if (isDefault) modelData.audio.muted = !modelData.audio.muted
                    else Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }
    }
}

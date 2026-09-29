import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs

// The Altura column down the left edge, under the bar. The column and a fresh ivy plant are
// baked by pillar/pillar.mjs into a data texture; shaders/pillar.frag materializes the column
// at the landing hero's pace, then the plant grows in over the next ten minutes or so.
PanelWindow {
    id: root

    readonly property int scale: 2
    readonly property int sourceWidth: 132
    readonly property int bleed: 40
    readonly property int rows: Math.floor(height / scale)
    readonly property real rest: 0.11
    readonly property int steps: 5
    readonly property real settle: 0.15 + 0.12 * (1 + (steps - 1) * (1 - Math.exp(-2))) + 1
    readonly property string hyprDir: Quickshell.shellDir + "/.."
    readonly property string dataPath: hyprDir + "/generated/pillar-" + (screen ? screen.name : "0") + ".png"

    property real seed: Math.floor(Math.random() * 4294967296)
    property int bakedRows: 0
    property real end: 0
    property real planted: 0
    property real t: 0
    property real age: 0

    anchors { left: true; top: true; bottom: true }
    implicitWidth: sourceWidth * scale - bleed
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "altura-pillar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    onRowsChanged: settleSize.restart()

    Timer {
        id: settleSize
        interval: 150
        onTriggered: if (root.rows > 120 && root.rows !== root.bakedRows && !bake.running) bake.running = true
    }

    function materialize() {
        t = 0
        frames.restart()
    }

    Process {
        id: bake
        command: ["node", root.hyprDir + "/pillar/pillar.mjs", "bake",
            "--rows", String(root.rows), "--seed", String(root.seed), "--out", root.dataPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var out = JSON.parse(text)
                    root.bakedRows = out.rows
                    root.end = out.end
                } catch (e) {
                    console.warn("pillar bake: " + e)
                    return
                }
                image.source = ""
                image.source = "file://" + root.dataPath
                if (root.rows !== root.bakedRows) settleSize.restart()
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text !== "") console.warn("pillar bake: " + text) }
    }

    Image {
        id: image
        visible: false
        cache: false
        smooth: false
        mipmap: false
        onStatusChanged: if (status === Image.Ready && root.planted === 0) root.materialize()
    }

    FrameAnimation {
        id: frames
        onTriggered: {
            root.t = elapsedTime
            if (root.t < root.settle) return
            running = false
            if (root.planted === 0) {
                root.planted = Date.now()
                stateFile.setText(JSON.stringify({ seed: root.seed, planted: root.planted }))
                growth.running = true
            }
        }
    }

    // Ivy is far slower than a frame; 20 Hz keeps the hot-pixel fade smooth until the plant is done.
    Timer {
        id: growth
        interval: 50
        repeat: true
        onTriggered: {
            root.age = (Date.now() - root.planted) / 1000
            if (root.age > root.end) running = false
        }
    }

    FileView {
        id: stateFile
        path: root.hyprDir + "/generated/pillar.json"
        blockLoading: false
        printErrors: false
    }

    Connections {
        target: Theme
        function onModeChanged() { if (root.planted > 0) root.materialize() }
    }

    ShaderEffect {
        x: -root.bleed
        width: root.sourceWidth * root.scale
        height: root.bakedRows * root.scale
        visible: root.bakedRows > 0 && image.status === Image.Ready
        fragmentShader: "shaders/pillar.frag.qsb"
        property var source: image
        property real t: root.t
        property real age: root.age
        property real rest: root.rest
        property real rows: root.bakedRows
        property real reach: root.bakedRows / 2
        property real steps: root.steps
        property color ink: Theme.fg
    }
}

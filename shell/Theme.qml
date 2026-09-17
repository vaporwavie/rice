pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var palette: ({})
    readonly property string mode: palette.mode || "night"
    readonly property color bg: palette.bg || "#141414"
    readonly property color bgAlt: palette.bgAlt || "#1c1c1c"
    readonly property color bgElev: palette.bgElev || "#262626"
    readonly property color border: palette.border || "#2c2c2c"
    readonly property color fg: palette.fg || "#e1e1e1"
    readonly property color fgDim: palette.fgDim || "#8c8c8c"
    readonly property color muted: palette.muted || "#6c6c6c"
    readonly property color accent: palette.accent || "#7aa2f7"
    readonly property color accentAlt: palette.accentAlt || "#bb9af7"
    readonly property color red: palette.red || "#f7768e"
    readonly property color green: palette.green || "#9ece6a"
    readonly property color yellow: palette.yellow || "#e0af68"
    readonly property color cyan: palette.cyan || "#7dcfff"

    readonly property string font: "Geist Mono"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property int iconSize: 15
    readonly property int barHeight: 30
    readonly property int panelPadding: 10
    readonly property int panelBorder: 2
    readonly property int panelWidth: 320
    readonly property int rowHeight: 28

    function reload() { colors.reload() }

    FileView {
        id: colors
        path: Quickshell.shellDir + "/../generated/shell-colors.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.apply()
        onLoadFailed: console.warn("shell-colors.json missing, using fallback palette")
    }

    function apply() {
        try {
            root.palette = JSON.parse(colors.text())
        } catch (e) {
            console.warn("shell-colors.json unreadable: " + e)
        }
    }

    Component.onCompleted: apply()
}

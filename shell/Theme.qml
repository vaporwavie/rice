pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var palette: ({})
    readonly property string mode: palette.mode || "dark"
    readonly property color bg: palette.bg || "#000000"
    readonly property color bgAlt: palette.bgAlt || "#0b0b0c"
    readonly property color bgElev: palette.bgElev || "#151517"
    readonly property color border: palette.border || "#171717"
    readonly property color lineStrong: palette.lineStrong || "#292929"
    readonly property color fg: palette.fg || "#e8e8e5"
    readonly property color fgDim: palette.fgDim || "#8c8c89"
    readonly property color muted: palette.muted || "#57574f"
    readonly property color accent: palette.accent || "#f4f2ec"
    readonly property color accentAlt: palette.accentAlt || "#e8e8e5"
    readonly property color red: palette.red || "#d8826f"
    readonly property color green: palette.green || "#a3b18a"
    readonly property color yellow: palette.yellow || "#d6b370"
    readonly property color cyan: palette.cyan || "#9fb7bd"
    readonly property color glow: Qt.rgba(fg.r, fg.g, fg.b, mode === "light" ? 0.04 : 0.05)

    readonly property string font: "Geist Mono"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14
    readonly property int iconSize: 15
    readonly property int barHeight: 36
    readonly property int panelPadding: 12
    readonly property int panelBorder: 1
    readonly property int panelWidth: 320
    readonly property int rowHeight: 30

    // The landing's single curve (ease-out-expo) and its paces: hovers, entrances, the hero.
    readonly property int easing: Easing.OutExpo
    readonly property int quick: 300
    readonly property int enter: 550
    readonly property int hero: 1000

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

import QtQuick
import Quickshell.Wayland
import qs

Item {
    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string raw: toplevel ? (toplevel.title || toplevel.appId || "") : ""
    readonly property string title: raw
        .replace(/ - (Helium|Google Chrome)$/, "")
        .replace(/ — (Zen Browser|Dolphin)$/, "")
        .slice(0, 64)

    implicitWidth: title === "" ? 0 : text.implicitWidth + 20
    implicitHeight: Theme.barHeight
    Label { id: text; anchors.centerIn: parent; text: parent.title; dim: true }
}

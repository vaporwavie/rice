import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: bar

    readonly property string screenName: screen ? screen.name : ""
    function panelOpen(name) { return Panels.isOpen(name, screenName) }
    function togglePanel(name) { Panels.toggle(name, screenName) }

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: Theme.bg
    WlrLayershell.namespace: "hypr-bar"
    WlrLayershell.keyboardFocus: Panels.open !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    RowLayout {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: 4 }
        spacing: 0
        Workspaces { bar: bar }
        ActiveWindow { }
    }

    Row {
        id: center
        anchors.centerIn: parent
        Clock { bar: bar }
        NextEvent { bar: bar }
    }

    EventsPanel { anchorItem: center; open: bar.panelOpen("events") }

    RowLayout {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 8 }
        spacing: 0
        Cpu { }
        Memory { }
        NetworkButton { bar: bar }
        BluetoothButton { bar: bar }
        DisplayButton { bar: bar }
        AudioButton { bar: bar }
        PowerButton { bar: bar }
        Tray { bar: bar }
    }
}

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

    // The bar settles in like the landing nav: a short rise and fade on the site's curve.
    property real arrival: 0
    NumberAnimation on arrival { from: 0; to: 1; duration: Theme.hero; easing.type: Theme.easing }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
    }

    RowLayout {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; leftMargin: 6 }
        spacing: 0
        opacity: bar.arrival
        transform: Translate { y: (1 - bar.arrival) * -6 }
        Workspaces { bar: bar }
        GroupTabs { }
        ActiveWindow { }
    }

    Row {
        id: center
        anchors.centerIn: parent
        Clock { bar: bar }
        opacity: bar.arrival
        Clock { bar: bar }
        TodoistButton { bar: bar }
        transform: Translate { y: (1 - bar.arrival) * -6 }
        NextEvent { bar: bar }
    }
    Calendar { anchorItem: center; open: bar.panelOpen("calendar") }

    EventsPanel { anchorItem: center; open: bar.panelOpen("events") }

    RowLayout {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 10 }
        spacing: 0
        Cpu { }
        Memory { }
        NetworkButton { bar: bar }
        BluetoothButton { bar: bar }
        KeevyButton { bar: bar }
        DisplayButton { bar: bar }
        AudioButton { bar: bar }
        PowerButton { bar: bar }
        Tray { bar: bar }
    }
}

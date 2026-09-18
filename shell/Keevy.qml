pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string picker: Quickshell.env("KEEVY_PICKER")
        || Quickshell.env("HOME") + "/Workspace/kvm/linux/keevy-picker"
    property var machines: []
    property string error: ""
    property string switchingTo: ""
    readonly property bool loading: discover.running
    readonly property bool busy: action.running
    signal switched()

    function refresh() {
        if (busy || loading) return
        error = ""
        machines = []
        discover.running = true
    }

    function select(name) {
        if (busy || loading || !machines.some(m => m.name === name)) return
        error = ""
        switchingTo = name
        action.command = ["/usr/bin/python3", picker, name]
        action.running = true
    }

    Process {
        id: discover
        command: ["/usr/bin/python3", root.picker, "--list"]
        stdout: StdioCollector { id: machineList }
        stderr: StdioCollector { id: listError }
        onExited: code => {
            if (code !== 0) {
                root.error = listError.text.trim() || "Could not load Keevy machines"
                return
            }
            try {
                var machines = JSON.parse(machineList.text)
                if (!Array.isArray(machines) || !machines.every(m =>
                    typeof m.name === "string" && m.name.length > 0
                    && Number.isInteger(m.key) && m.key >= 1 && m.key <= 3))
                    throw new Error("Invalid machine list")
                root.machines = machines
            } catch (error) {
                root.error = "Could not read Keevy machines"
            }
        }
    }

    Process {
        id: action
        stdout: StdioCollector { id: switchOutput }
        stderr: StdioCollector { id: switchError }
        onExited: (code, status) => {
            if (code === 0 && status === 0) root.switched()
            else root.error = root.switchingTo + " failed: "
                + (switchError.text.trim() || switchOutput.text.trim() || "exit " + code)
            root.switchingTo = ""
        }
    }
}

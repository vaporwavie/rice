import QtQuick
import qs

Panel {
    id: root
    name: "display"
    onOpenChanged: if (open) Ddc.refresh()

    Column {
        width: parent.width

        PanelHeader { text: "Brightness  " + (Ddc.brightness < 0 ? "" : Ddc.brightness + "%") }
        Slider {
            value: Math.max(0, Ddc.brightness)
            max: 100
            onMoved: v => Ddc.setBrightness(v)
        }

        PanelHeader { text: "Contrast  " + (Ddc.contrast < 0 ? "" : Ddc.contrast + "%") }
        Slider {
            value: Math.max(0, Ddc.contrast)
            max: 100
            onMoved: v => Ddc.setContrast(v)
        }

        Item { width: 1; height: 6; visible: Ddc.presets.length > 0 }
        PanelHeader { text: "Color"; visible: Ddc.presets.length > 0 }
        Repeater {
            model: Ddc.presets
            PanelRow {
                required property var modelData
                readonly property bool current: Ddc.preset === modelData.code
                icon: current ? "󰄬" : " "
                active: current
                text: modelData.name
                onClicked: Ddc.setPreset(modelData.code)
            }
        }

        Item { width: 1; height: 6; visible: Ddc.inputs.length > 0 }
        PanelHeader { text: "Input"; visible: Ddc.inputs.length > 0 }
        Repeater {
            model: Ddc.inputs
            PanelRow {
                required property var modelData
                readonly property bool current: Ddc.input === modelData.code
                icon: current ? "󰄬" : " "
                active: current
                text: modelData.name
                onClicked: Ddc.setInput(modelData.code)
            }
        }

        PanelRow { visible: Ddc.error !== ""; icon: "󰀦"; text: Ddc.error; enabled: false }
    }
}

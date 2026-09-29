import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

PopupWindow {
    id: root

    required property Item anchorItem
    property string name: ""
    property bool grab: true
    property int contentWidth: Theme.panelWidth
    property int padding: Theme.panelPadding
    property bool open: false
    default property alias content: holder.data

    readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
    readonly property int frame: padding + Theme.panelBorder

    visible: open
    color: "transparent"
    implicitWidth: contentWidth + frame * 2
    implicitHeight: holder.childrenRect.height + frame * 2

    function close() {
        if (name !== "" && Panels.open === name) Panels.close()
        else open = false
    }

    HyprlandFocusGrab {
        active: root.open && root.grab
        windows: root.anchorWindow ? [root, root.anchorWindow] : [root]
        onCleared: root.close()
    }

    anchor {
        window: root.anchorWindow
        adjustment: PopupAdjustment.SlideX
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        rect.width: 1
        rect.height: 1
        onAnchoring: {
            var win = root.anchorWindow
            if (!win || !root.anchorItem) return
            var p = win.contentItem.mapFromItem(root.anchorItem, root.anchorItem.width / 2 - root.implicitWidth / 2, 0)
            var x = Math.max(0, Math.min(p.x, win.width - root.implicitWidth))
            root.anchor.rect.x = Math.round(x)
            root.anchor.rect.y = win.height
        }
    }

    // Panels drop out of the bar the way the landing reveals a section: fade in, settle a few px.
    property real shown: 0
    onOpenChanged: if (open) { reveal.restart() } else { reveal.stop(); shown = 0 }
    NumberAnimation {
        id: reveal
        target: root
        property: "shown"
        from: 0
        to: 1
        duration: Theme.enter
        easing.type: Theme.easing
    }

    Rectangle {
        width: parent.width
        height: parent.height
        y: (1 - root.shown) * -8
        opacity: root.shown
        color: Theme.bgAlt
        border.color: Theme.lineStrong
        border.width: Theme.panelBorder

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.panelBorder }
            height: Math.min(parent.height * 0.6, 160)
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.glow }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        Item {
            id: holder
            x: root.frame
            y: root.frame
            width: root.contentWidth
        }
    }
}

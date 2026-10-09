import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

PopupWindow {
    id: root

    required property Item anchorItem
    property string name: ""
    // A native popup grab needs the input serial from a click on the bar; keyboard opens use the Hyprland grab.
    grabFocus: Panels.fromPointer
    property bool grab: !grabFocus
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

    property Item cursor: null
    // Panel-specific keys, tried before the shared ones: event => accepted.
    property var extraKeys: null

    function rows() {
        var out = []
        function walk(item) {
            for (var child of item.children) {
                if (!child.visible) continue
                if (child.navigable === true && child.enabled) out.push(child)
                else walk(child)
            }
        }
        walk(holder)
        return out.sort((a, b) => a.mapToItem(holder, 0, 0).y - b.mapToItem(holder, 0, 0).y)
    }
    function select(item) {
        if (cursor) cursor.selected = false
        cursor = item
        if (!item) return
        item.selected = true
        reveal(item)
    }
    function reveal(item) {
        for (var view = item.parent; view; view = view.parent) {
            if (view.contentY === undefined || view.contentHeight === undefined) continue
            var y = item.mapToItem(view.contentItem, 0, 0).y
            if (y < view.contentY) view.contentY = y
            else if (y + item.height > view.contentY + view.height) view.contentY = y + item.height - view.height
            return
        }
    }
    function step(direction) {
        var list = rows()
        if (!list.length) return select(null)
        var at = list.indexOf(cursor)
        if (at < 0) return select(direction > 0 ? list[0] : list[list.length - 1])
        select(list[(at + direction + list.length) % list.length])
    }
    // Keys forwarded from the bar never reach a TextInput, so text fields take them through here.
    function type(input, event) {
        if (event.key === Qt.Key_Backspace) input.text = input.text.slice(0, -1)
        else if (event.text.length === 1 && event.text >= " " && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) input.text += event.text
        else return false
        return true
    }
    function handleKey(event) {
        if (extraKeys && extraKeys(event)) return true
        var key = event.key
        if (key === Qt.Key_Escape) close()
        else if (key === Qt.Key_J || key === Qt.Key_Down || key === Qt.Key_Tab) step(1)
        else if (key === Qt.Key_K || key === Qt.Key_Up || key === Qt.Key_Backtab) step(-1)
        else if ((key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) && cursor && cursor.activate) cursor.activate()
        else if ((key === Qt.Key_H || key === Qt.Key_Left) && cursor && cursor.nudge) cursor.nudge(-1)
        else if ((key === Qt.Key_L || key === Qt.Key_Right) && cursor && cursor.nudge) cursor.nudge(1)
        else return false
        return true
    }

    onVisibleChanged: if (!visible && open) close()
    onBackingWindowVisibleChanged: if (backingWindowVisible) Qt.callLater(() => holder.forceActiveFocus())

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
    onOpenChanged: {
        select(null)
        if (name !== "") {
            if (open) Panels.active = root
            else if (Panels.active === root) Panels.active = null
        }
        if (open) {
            arrival.restart()
            if (!Panels.fromPointer) Qt.callLater(() => { if (root.open && !root.cursor) root.step(1) })
        } else {
            arrival.stop()
            shown = 0
        }
    }
    NumberAnimation {
        id: arrival
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

        FocusScope {
            id: holder
            x: root.frame
            y: root.frame
            width: root.contentWidth
            Keys.onPressed: event => { event.accepted = root.handleKey(event) }
        }
    }
}

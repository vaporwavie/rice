import QtQuick
import qs

Canvas {
    id: root
    property var values: []
    property var under: []
    property real max: 0
    property color color: Theme.fg
    property color underColor: Theme.muted

    width: parent ? parent.width : Theme.panelWidth
    height: 34

    onValuesChanged: requestPaint()
    onUnderChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    function trace(ctx, list, top, stroke, fill) {
        if (list.length < 2) return
        var step = width / (Activity.span - 1)
        var x0 = width - (list.length - 1) * step
        ctx.beginPath()
        ctx.moveTo(x0, height)
        for (var i = 0; i < list.length; i++)
            ctx.lineTo(x0 + i * step, height - 1 - (height - 2) * Math.min(1, list[i] / top))
        ctx.lineTo(width, height)
        ctx.fillStyle = Qt.rgba(stroke.r, stroke.g, stroke.b, fill)
        ctx.fill()
        ctx.beginPath()
        for (var j = 0; j < list.length; j++)
            ctx.lineTo(x0 + j * step, height - 1 - (height - 2) * Math.min(1, list[j] / top))
        ctx.strokeStyle = stroke
        ctx.lineWidth = 1
        ctx.stroke()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = Theme.border
        ctx.fillRect(0, height - 1, width, 1)
        var top = max > 0 ? max : Math.max(1, Math.max.apply(null, values.concat(under)))
        trace(ctx, under, top, underColor, 0.06)
        trace(ctx, values, top, color, 0.10)
    }
}

import QtQuick
import qs

Text {
    property bool icon: false
    property bool dim: false
    font.family: icon ? Theme.iconFont : Theme.font
    font.pixelSize: icon ? Theme.iconSize : Theme.fontSize
    color: dim ? Theme.fgDim : Theme.fg
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    Behavior on color { ColorAnimation { duration: Theme.quick; easing.type: Theme.easing } }
}

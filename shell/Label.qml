import QtQuick
import qs

Text {
    property bool icon: false
    property bool dim: false
    font.family: icon ? Theme.iconFont : Theme.font
    font.pixelSize: icon ? Theme.iconSize : Theme.fontSize
    color: dim ? Theme.muted : Theme.fg
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}

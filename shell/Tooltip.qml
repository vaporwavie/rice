import QtQuick
import qs

Panel {
    id: root
    property string text: ""
    grab: false
    contentWidth: body.implicitWidth
    padding: 6
    Label { id: body; text: root.text; textFormat: Text.PlainText }
}

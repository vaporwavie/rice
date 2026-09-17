import QtQuick
import qs

Item {
    id: root

    property string text: ""
    property bool icon: true
    property color color: Theme.fg
    property int padding: 7
    property string tip: ""
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: label.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight

    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        icon: root.icon
        color: root.color
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }

    Tooltip {
        anchorItem: root
        text: root.tip
        open: area.containsMouse && root.tip !== ""
    }
}

import QtQuick
import QtQuick.Shapes

// Nina's symbolic icon (packaging/icons/nina-symbolic.svg in the app repo), drawn as filled
// paths on its 16 px grid so it takes any color.
Item {
    id: root
    property color color: "white"
    property real size: 16

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 16
        height: 16
        scale: root.size / 16
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg { path: "M1 8A7 7 0 0 1 15 8H13A5 5 0 0 0 3 8Z" }
        }
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg { path: "M1 8.5A1.5 1.5 0 0 1 4 8.5V13.5A1.5 1.5 0 0 1 1 13.5Z" }
        }
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg { path: "M12 8.5A1.5 1.5 0 0 1 15 8.5V13.5A1.5 1.5 0 0 1 12 13.5Z" }
        }
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg { path: "M5.75 8H6.25A.75 .75 0 0 1 7 8.75V9.25A.75 .75 0 0 1 6.25 10H5.75A.75 .75 0 0 1 5 9.25V8.75A.75 .75 0 0 1 5.75 8Z" }
        }
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg { path: "M9.75 8H10.25A.75 .75 0 0 1 11 8.75V9.25A.75 .75 0 0 1 10.25 10H9.75A.75 .75 0 0 1 9 9.25V8.75A.75 .75 0 0 1 9.75 8Z" }
        }
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg { path: "M6.25 11.5H9.75L8 13.25Z" }
        }
    }
}

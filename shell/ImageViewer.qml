import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs

FloatingWindow {
    id: root

    property url source: "file://" + Quickshell.env("IMGVIEW_FILE")
    readonly property string fileName: decodeURIComponent(source.toString().split("/").pop())
    readonly property string folder: source.toString().slice(0, source.toString().lastIndexOf("/"))
    readonly property int index: files.count > 0 ? files.indexOf(source) : -1

    title: "Image Viewer — " + fileName
    implicitWidth: 1200
    implicitHeight: 800
    color: Theme.bg

    // A closed window would otherwise leave qs alive, and its hot reload of shell/ reopens it.
    onVisibleChanged: if (!visible) Qt.quit()
    Component.onCompleted: Quickshell.watchFiles = false

    function step(delta) {
        if (files.count < 2)
            return;
        const next = ((index < 0 ? 0 : index) + delta + files.count) % files.count;
        source = files.get(next, "fileUrl");
    }

    FolderListModel {
        id: files
        folder: root.folder
        showDirs: false
        caseSensitive: false
        sortCaseSensitive: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg", "*.bmp", "*.tif", "*.tiff", "*.avif", "*.heic", "*.heif", "*.jxl", "*.ico", "*.tga", "*.qoi", "*.pnm", "*.ppm", "*.pgm", "*.pbm"]
    }

    Item {
        id: view
        anchors.fill: parent
        clip: true
        focus: true

        property real zoom: 1
        property bool fitted: true
        readonly property size natural: Qt.size(image.implicitWidth, image.implicitHeight)
        readonly property real fitZoom: natural.width > 0 ? Math.min(1, width / natural.width, (height - footer.height) / natural.height) : 1

        function fit() {
            fitted = true;
            zoom = fitZoom;
            center();
        }

        function center() {
            image.x = (width - image.width) / 2;
            image.y = (height - footer.height - image.height) / 2;
            clamp();
        }

        function clamp() {
            const room = height - footer.height;
            image.x = image.width <= width ? (width - image.width) / 2 : Math.min(0, Math.max(width - image.width, image.x));
            image.y = image.height <= room ? (room - image.height) / 2 : Math.min(0, Math.max(room - image.height, image.y));
        }

        function zoomAt(factor, px, py) {
            const next = Math.max(0.02, Math.min(32, zoom * factor));
            const ratio = next / zoom;
            fitted = false;
            image.x = px - (px - image.x) * ratio;
            image.y = py - (py - image.y) * ratio;
            zoom = next;
            clamp();
        }

        onFitZoomChanged: if (fitted) fit()
        onWidthChanged: fitted ? fit() : clamp()
        onHeightChanged: fitted ? fit() : clamp()

        AnimatedImage {
            id: image
            source: root.source
            width: implicitWidth * view.zoom
            height: implicitHeight * view.zoom
            asynchronous: true
            autoTransform: true
            smooth: view.zoom < 4
            mipmap: true
            onStatusChanged: if (status === Image.Ready) view.fit()
        }

        Label {
            anchors.centerIn: parent
            visible: image.status === Image.Error
            text: "Cannot open " + root.fileName
            dim: true
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
            property point last
            onPressed: mouse => last = Qt.point(mouse.x, mouse.y)
            onPositionChanged: mouse => {
                image.x += mouse.x - last.x;
                image.y += mouse.y - last.y;
                last = Qt.point(mouse.x, mouse.y);
                view.clamp();
            }
            onDoubleClicked: view.fitted ? view.zoomAt(1 / view.zoom, mouseX, mouseY) : view.fit()
            onWheel: wheel => view.zoomAt(Math.pow(1.0015, wheel.angleDelta.y), wheel.x, wheel.y)
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
            case Qt.Key_Q:
                Qt.quit();
                break;
            case Qt.Key_Right:
            case Qt.Key_L:
            case Qt.Key_Space:
                root.step(1);
                break;
            case Qt.Key_Left:
            case Qt.Key_H:
            case Qt.Key_Backspace:
                root.step(-1);
                break;
            case Qt.Key_Plus:
            case Qt.Key_Equal:
                view.zoomAt(1.25, view.width / 2, (view.height - footer.height) / 2);
                break;
            case Qt.Key_Minus:
                view.zoomAt(0.8, view.width / 2, (view.height - footer.height) / 2);
                break;
            case Qt.Key_1:
                view.zoomAt(1 / view.zoom, view.width / 2, (view.height - footer.height) / 2);
                break;
            case Qt.Key_0:
                view.fit();
                break;
            case Qt.Key_Home:
                root.source = files.get(0, "fileUrl");
                break;
            case Qt.Key_End:
                root.source = files.get(files.count - 1, "fileUrl");
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        Rectangle {
            id: footer
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Theme.barHeight
            color: Theme.bgAlt

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: Theme.panelBorder
                color: Theme.border
            }

            Label {
                anchors { left: parent.left; right: meta.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.panelPadding; rightMargin: Theme.panelPadding }
                text: root.fileName
            }

            Label {
                id: meta
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.panelPadding }
                dim: true
                elide: Text.ElideNone
                text: {
                    const parts = [];
                    if (files.count > 0 && root.index >= 0)
                        parts.push((root.index + 1) + "/" + files.count);
                    if (view.natural.width > 0)
                        parts.push(view.natural.width + "×" + view.natural.height);
                    parts.push(Math.round(view.zoom * 100) + "%");
                    return parts.join("  ·  ");
                }
            }
        }
    }
}

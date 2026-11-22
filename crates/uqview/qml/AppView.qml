import QtQuick
import org.uqview.app
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import "logic.js" as L

// The window's content: the top bar, the picture, the strip of thumbnails, the details panel
// and Mark up. Everything it knows comes from `backend` (the Rust Backend, or a fake in tests).
Item {
    id: app

    required property var backend
    property bool fullscreen: false
    property bool showInfo: false
    property bool marking: false
    readonly property var files: backend.filesJson !== "" ? JSON.parse(backend.filesJson) : []
    readonly property var cfg: backend.configJson !== "" ? JSON.parse(backend.configJson) : ({})
    readonly property int index: backend.index
    readonly property string path: index >= 0 && index < files.length ? files[index] : ""
    readonly property var info: path !== "" ? JSON.parse(backend.info(path)) : ({})
    readonly property bool chrome: !fullscreen || reveal.active
    // Mark up is open with marks not yet saved: closing this tab or the window asks first.
    readonly property bool unsaved: marking && markup.dirty

    signal openRequested()
    signal fullscreenToggled()
    signal quitRequested()

    function go(dir) {
        var j = L.step(index, files.length, dir, cfg.wrap_around !== false);
        if (j >= 0)
            backend.index = j;
    }
    function goTo(j) {
        if (j >= 0 && j < files.length)
            backend.index = j;
    }
    function trashCurrent() {
        if (path === "")
            return;
        if (cfg.confirm_delete)
            confirmTrash.open();
        else
            backend.trash(path);
    }
    function startMarkup() {
        if (path !== "" && !viewer.failed)
            marking = true;
    }
    // Save the marks as Mark up's Save would; true when they were saved (Mark up then closes).
    function saveMarks() {
        markup.save("save");
        return !unsaved;
    }
    function discardMarks() {
        markup.reset();
        marking = false;
    }
    // Keys to Mark up when it is open, else to the viewer.
    function refocus() {
        if (marking)
            markup.forceActiveFocus();
        else
            forceActiveFocus();
    }
    function notice(kind, text) {
        toast.show(kind, text);
    }

    Connections {
        target: app.backend
        function onNotice(kind, text) {
            toast.show(kind, text);
        }
    }

    focus: true
    Keys.onPressed: function (ev) {
        if (marking)
            return;
        var k = ev.key, mods = ev.modifiers & ~Qt.KeypadModifier;
        if (k === Qt.Key_Right || k === Qt.Key_PageDown || k === Qt.Key_Space)
            go(1);
        else if (k === Qt.Key_Left || k === Qt.Key_PageUp || k === Qt.Key_Backspace)
            go(-1);
        else if (k === Qt.Key_Home)
            goTo(0);
        else if (k === Qt.Key_End)
            goTo(files.length - 1);
        else if (k === Qt.Key_Plus || k === Qt.Key_Equal)
            viewer.zoomStep(1);
        else if (k === Qt.Key_Minus)
            viewer.zoomStep(-1);
        else if ((k === Qt.Key_0 || k === Qt.Key_F) && mods === Qt.NoModifier)
            viewer.fitToView();
        else if (k === Qt.Key_1 && mods === Qt.NoModifier)
            viewer.actualSize();
        else if (k === Qt.Key_R && mods === Qt.NoModifier)
            viewer.rotate(90);
        else if (k === Qt.Key_R && mods === Qt.ShiftModifier)
            viewer.rotate(-90);
        else if (k === Qt.Key_Delete)
            trashCurrent();
        else if (ev.matches(StandardKey.Copy))
            backend.copyImage(path);
        else if (ev.matches(StandardKey.Undo) && backend.canUndo)
            backend.undo();
        else if (k === Qt.Key_M && mods === Qt.NoModifier)
            startMarkup();
        else if (k === Qt.Key_I && mods === Qt.NoModifier)
            showInfo = !showInfo;
        else if (k === Qt.Key_F11)
            fullscreenToggled();
        else if (k === Qt.Key_Escape && fullscreen)
            fullscreenToggled();
        else if (ev.matches(StandardKey.Open))
            openRequested();
        else if (ev.matches(StandardKey.Quit) || (k === Qt.Key_Q && mods === Qt.NoModifier) || (k === Qt.Key_Escape && !fullscreen))
            quitRequested();
        else
            return;
        ev.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: fullscreen ? "#000000" : Theme.bg
    }

    // In full screen the bars come back while the pointer is near the top or bottom edge.
    HoverHandler {
        id: reveal
        readonly property bool active: hovered && (point.position.y < Theme.barHeight + 8 || point.position.y > app.height - (strip.implicitHeight + 8))
    }

    // ---- Top bar
    Rectangle {
        id: bar
        z: 2
        anchors.left: parent.left
        anchors.right: parent.right
        y: app.chrome ? 0 : -height
        Behavior on y { NumberAnimation { duration: Theme.motionBase; easing.type: Theme.easing } }
        height: Theme.barHeight
        color: Theme.surface
        visible: !app.marking
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.gap
            anchors.rightMargin: Theme.gap
            spacing: 2

            IconButton { iconName: "go-previous"; tip: "Previous"; shortcut: "←"; enabled: app.files.length > 1; onClicked: app.go(-1) }
            IconButton { iconName: "go-next"; tip: "Next"; shortcut: "→"; enabled: app.files.length > 1; onClicked: app.go(1) }
            ColumnLayout {
                Layout.leftMargin: 8
                Layout.fillWidth: true
                spacing: 0
                QQC2.Label {
                    Layout.fillWidth: true
                    text: app.path !== "" ? L.baseName(app.path) : "uQview"
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pointSize: Theme.bodySize
                    font.bold: true
                    elide: Text.ElideMiddle
                    textFormat: Text.PlainText
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: [L.counter(app.index, app.files.length), L.dims(app.info), app.info.size || ""].filter(function (s) { return s !== ""; }).join("  ·  ")
                    color: Theme.textMuted
                    font.family: Theme.fontUi
                    font.pointSize: Theme.smallSize
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }
            IconButton { iconName: "zoom-out"; tip: "Zoom out"; shortcut: "−"; enabled: app.path !== ""; onClicked: viewer.zoomStep(-1) }
            IconButton {
                text: L.percent(viewer.scale)
                showText: true
                tip: "Fit to the window"
                enabled: app.path !== ""
                implicitWidth: 64
                onClicked: viewer.zoomed ? viewer.fitToView() : viewer.actualSize()
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: viewer.zoomed ? "Fit to the window (F)" : "Actual size (1)"
                QQC2.ToolTip.delay: 500
            }
            IconButton { iconName: "zoom-in"; tip: "Zoom in"; shortcut: "+"; enabled: app.path !== ""; onClicked: viewer.zoomStep(1) }
            IconButton { iconName: "object-rotate-left"; tip: "Rotate left"; shortcut: "Shift+R"; enabled: app.path !== ""; onClicked: viewer.rotate(-90) }
            IconButton { iconName: "object-rotate-right"; tip: "Rotate right"; shortcut: "R"; enabled: app.path !== ""; onClicked: viewer.rotate(90) }
            Rectangle { width: 1; height: 22; color: Theme.border; Layout.leftMargin: 6; Layout.rightMargin: 6 }
            IconButton {
                iconName: "document-edit"
                text: "Mark up"
                primary: true
                tip: "Mark up"
                shortcut: "M"
                enabled: app.path !== "" && !viewer.failed
                onClicked: app.startMarkup()
            }
            IconButton {
                iconName: "preferences-desktop-wallpaper"
                tip: "Set as wallpaper"
                visible: app.backend.canSetWallpaper
                enabled: app.path !== "" && !viewer.failed
                onClicked: app.backend.setWallpaper(app.path)
            }
            IconButton { iconName: "edit-copy"; tip: "Copy"; shortcut: "Ctrl+C"; enabled: app.path !== ""; onClicked: app.backend.copyImage(app.path) }
            IconButton { iconName: "user-trash"; tip: "Move to the trash"; shortcut: "Del"; enabled: app.path !== ""; onClicked: app.trashCurrent() }
            IconButton { iconName: "documentinfo"; tip: "Details"; shortcut: "I"; checkable: true; checked: app.showInfo; onClicked: app.showInfo = !app.showInfo }
            IconButton {
                iconName: "application-menu"
                tip: "More"
                onClicked: more.open()
                QQC2.Menu {
                    id: more
                    y: parent.height
                    QQC2.MenuItem { text: "Open…"; onTriggered: app.openRequested() }
                    QQC2.MenuItem { text: "Show in folder"; enabled: app.path !== ""; onTriggered: app.backend.showInFolder(app.path) }
                    QQC2.MenuItem { text: app.fullscreen ? "Leave full screen" : "Full screen"; onTriggered: app.fullscreenToggled() }
                    QQC2.MenuSeparator {}
                    QQC2.MenuItem {
                        text: "Sort by name"
                        checkable: true
                        checked: app.cfg.sort === "name"
                        onTriggered: app.backend.configSet("sort", "name")
                    }
                    QQC2.MenuItem {
                        text: "Sort by date"
                        checkable: true
                        checked: app.cfg.sort === "date"
                        onTriggered: app.backend.configSet("sort", "date")
                    }
                    QQC2.MenuItem {
                        text: "Sort by size"
                        checkable: true
                        checked: app.cfg.sort === "size"
                        onTriggered: app.backend.configSet("sort", "size")
                    }
                    QQC2.MenuItem {
                        text: "Show thumbnails"
                        checkable: true
                        checked: app.cfg.show_thumbnails !== false
                        onTriggered: app.backend.configSet("show_thumbnails", checked ? "on" : "off")
                    }
                }
            }
        }
    }

    // ---- The picture, the strip and the details
    Item {
        id: middle
        anchors.top: app.fullscreen ? parent.top : bar.bottom
        anchors.left: parent.left
        anchors.right: infoPanel.visible ? infoPanel.left : parent.right
        anchors.bottom: app.fullscreen || !strip.visible ? parent.bottom : strip.top

        Viewer {
            id: viewer
            anchors.fill: parent
            // Under Mark up it neither takes the pointer nor needs to draw.
            enabled: !app.marking
            visible: !app.marking
            path: app.path
            info: app.info
            nextPath: app.files.length > 1 ? app.files[(app.index + 1) % app.files.length] : ""
            prevPath: app.files.length > 2 ? app.files[(app.index + app.files.length - 1) % app.files.length] : ""
            upscale: app.cfg.upscale_small === true
            background: app.fullscreen && app.cfg.background === "theme" ? "black" : (app.cfg.background || "theme")
            onStepRequested: function (dir) { app.go(dir); }
        }

        // Side zones: click the left or right edge to step (as in most viewers).
        Repeater {
            model: app.files.length > 1 && !viewer.zoomed ? [-1, 1] : []
            Item {
                required property int modelData
                width: Math.min(96, middle.width / 6)
                height: middle.height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: modelData < 0 ? 0 : middle.width - width
                HoverHandler { id: zone; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: app.go(parent.modelData) }
                Rectangle {
                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    radius: 20
                    color: Theme.overlay
                    opacity: zone.hovered ? 0.92 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.motionBase; easing.type: Theme.easing } }
                    QQC2.Label {
                        anchors.centerIn: parent
                        text: parent.parent.modelData < 0 ? "‹" : "›"
                        color: Theme.text
                        font.pixelSize: 26
                    }
                }
            }
        }

        // Nothing open, or the picture couldn't be read.
        ColumnLayout {
            anchors.centerIn: parent
            visible: app.path === "" || viewer.failed
            spacing: 12
            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                text: app.path === "" ? "No picture open" : "Couldn't show this picture"
                color: Theme.text
                font.family: Theme.fontUi
                font.pointSize: Theme.bodySize + 4
                font.bold: true
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 420
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: app.path === "" ? "Open one, or drop pictures or a folder here." : (app.info.error || "The file may be damaged, or its format isn't supported.")
                color: Theme.textMuted
                font.family: Theme.fontUi
                font.pointSize: Theme.bodySize
                textFormat: Text.PlainText
            }
            IconButton {
                Layout.alignment: Qt.AlignHCenter
                visible: app.path === ""
                iconName: "document-open"
                text: "Open…"
                primary: true
                onClicked: app.openRequested()
            }
        }
        QQC2.BusyIndicator {
            anchors.centerIn: parent
            running: viewer.loading
            visible: running
        }

    }

    Strip {
        id: strip
        z: 2
        anchors.left: parent.left
        anchors.right: infoPanel.visible ? infoPanel.left : parent.right
        y: app.chrome ? app.height - height : app.height
        Behavior on y { NumberAnimation { duration: Theme.motionBase; easing.type: Theme.easing } }
        height: implicitHeight
        visible: app.cfg.show_thumbnails !== false && app.files.length > 1 && !app.marking
        files: app.files
        current: app.index
        onPicked: function (i) { app.goTo(i); }
    }

    InfoPanel {
        id: infoPanel
        z: 2
        anchors.top: app.fullscreen ? parent.top : bar.bottom
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: implicitWidth
        visible: app.showInfo && app.path !== "" && !app.marking
        info: app.info
        zoom: viewer.scale
        onShowInFolder: app.backend.showInFolder(app.path)
    }

    Markup {
        id: markup
        z: 5
        anchors.fill: parent
        visible: app.marking
        backend: app.backend
        path: app.marking ? app.path : ""
        onClosed: {
            app.marking = false;
            app.forceActiveFocus();
        }
        onSaved: {
            app.marking = false;
            app.forceActiveFocus();
        }
        onMessage: function (kind, text) { toast.show(kind, text); }
        onVisibleChanged: if (visible) forceActiveFocus()
    }

    // Above Mark up too, so its saves are reported.
    Toast {
        id: toast
        z: 6
        anchors.horizontalCenter: middle.horizontalCenter
        anchors.bottom: middle.bottom
        anchors.bottomMargin: 16
        onUndoRequested: app.backend.undo()
    }

    QQC2.Dialog {
        id: confirmTrash
        anchors.centerIn: parent
        modal: true
        title: "Move to the trash?"
        // A set width: the Basic style's own sizing loops between the title and the buttons.
        implicitWidth: Math.min(parent.width - 32, 360)
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        onAccepted: app.backend.trash(app.path)
        QQC2.Label {
            text: L.baseName(app.path)
            width: confirmTrash.availableWidth
            elide: Text.ElideMiddle
            color: Theme.text
            textFormat: Text.PlainText
        }
    }
}

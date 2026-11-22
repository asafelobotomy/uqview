import QtQuick
import org.uqview.app
import QtQuick.Controls as QQC2
import QtQuick.Layouts

// A short message at the bottom of the window; "trashed" ones offer Undo.
Rectangle {
    id: toast

    property string kind: "ok"
    property string text: ""
    signal undoRequested()

    function show(k, t) {
        kind = k;
        text = t;
        opacity = 1;
        timer.interval = k === "trashed" ? 6000 : (k === "error" ? 5000 : 2500);
        timer.restart();
    }

    visible: opacity > 0
    opacity: 0
    Behavior on opacity { NumberAnimation { duration: Theme.motionBase; easing.type: Theme.easing } }
    implicitWidth: row.implicitWidth + 28
    implicitHeight: 40
    radius: Theme.radius
    color: Theme.overlay
    border.color: kind === "error" ? Theme.error : Theme.border
    Accessible.role: Accessible.AlertMessage
    Accessible.name: text

    HoverHandler { id: hover }
    Timer {
        id: timer
        onTriggered: hover.hovered ? restart() : (toast.opacity = 0)
    }
    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12
        QQC2.Label {
            text: toast.text
            color: toast.kind === "error" ? Theme.error : Theme.text
            font.family: Theme.fontUi
            font.pointSize: Theme.bodySize
            textFormat: Text.PlainText
        }
        IconButton {
            visible: toast.kind === "trashed"
            text: "Undo"
            showText: true
            tip: "Undo"
            onClicked: {
                toast.opacity = 0;
                toast.undoRequested();
            }
        }
    }
}

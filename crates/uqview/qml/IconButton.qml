import QtQuick
import org.uqview.app
import QtQuick.Controls as QQC2
import QtQuick.Controls.impl as QQCImpl

// A flat toolbar button: a theme icon (or a short text), a tooltip with its shortcut, and the
// accent fill when `checked`. `primary` fills it with the accent and shows the text beside it.
QQC2.AbstractButton {
    id: b

    property string iconName: ""
    property string tip: ""
    property string shortcut: ""
    property bool primary: false
    property bool showText: primary
    property color fg: primary || checked ? Theme.accentText : Theme.text

    implicitHeight: 34
    implicitWidth: showText || !ic.visible ? row.implicitWidth + 20 : 34
    focusPolicy: Qt.NoFocus
    hoverEnabled: true
    opacity: enabled ? 1 : 0.4
    Accessible.name: b.tip !== "" ? b.tip : b.text

    QQC2.ToolTip.visible: hovered && tip !== "" && !showText
    QQC2.ToolTip.delay: 500
    QQC2.ToolTip.text: shortcut !== "" ? tip + "  (" + shortcut + ")" : tip

    background: Rectangle {
        radius: Math.max(4, Theme.radiusControl)
        color: b.primary || b.checked ? (b.hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
             : (b.down ? Theme.overlay : (b.hovered ? Theme.surfaceAlt : "transparent"))
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
        border.color: b.visualFocus ? Theme.accent : "transparent"
    }
    contentItem: Item {
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6
            // Tinted with the text colour, so every icon theme looks like part of uQ's.
            QQCImpl.IconImage {
                id: ic
                anchors.verticalCenter: parent.verticalCenter
                visible: b.iconName !== "" && status === Image.Ready
                name: b.iconName
                color: b.fg
                sourceSize: Qt.size(18, 18)
                width: 18
                height: 18
            }
            QQC2.Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: b.showText || !ic.visible
                text: b.text !== "" ? b.text : b.tip
                color: b.fg
                font.family: Theme.fontUi
                font.pointSize: Theme.bodySize
                font.bold: b.primary
            }
        }
    }
}

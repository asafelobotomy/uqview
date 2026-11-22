import QtQuick
import org.uqview.app
import QtQuick.Controls as QQC2
import QtQuick.Layouts

// The row of tabs above the picture, shown once two or more are open. A dot marks a tab with
// marks not yet saved. Middle-click or × closes a tab; + opens pictures in a new one.
Rectangle {
    id: bar

    // [{title, unsaved}], one per tab.
    property var tabs: []
    property int current: 0

    signal picked(int index)
    signal closeRequested(int index)
    signal newRequested()

    implicitHeight: 38
    color: Theme.bg

    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 5
        spacing: 4

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 2
            clip: true
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            model: bar.tabs.length
            currentIndex: bar.current
            highlightFollowsCurrentItem: false
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                id: t
                required property int index
                readonly property var tab: bar.tabs[index] || ({ title: "", unsaved: false })
                readonly property bool isCurrent: index === bar.current

                width: Math.max(120, Math.min(220, (list.width - list.spacing * (bar.tabs.length - 1)) / Math.max(1, bar.tabs.length)))
                height: list.height
                radius: Theme.radius
                color: isCurrent ? Theme.surface : (hover.hovered ? Theme.surfaceAlt : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                border.color: isCurrent ? Theme.border : "transparent"
                // Square off the bottom so the current tab runs into the bar under it.
                Rectangle {
                    visible: t.isCurrent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 1
                    anchors.rightMargin: 1
                    height: Theme.radius + 1
                    color: Theme.surface
                }
                Accessible.role: Accessible.PageTab
                Accessible.name: tab.title + (tab.unsaved ? ", marks not saved" : "")

                HoverHandler { id: hover }
                TapHandler { acceptedButtons: Qt.LeftButton; onTapped: bar.picked(t.index) }
                TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: bar.closeRequested(t.index) }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 4
                    spacing: 6
                    Rectangle {
                        visible: t.tab.unsaved
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.accent
                        QQC2.ToolTip.visible: dotHover.hovered
                        QQC2.ToolTip.text: "Marks not saved"
                        QQC2.ToolTip.delay: 500
                        HoverHandler { id: dotHover }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: t.tab.title
                        color: t.isCurrent ? Theme.text : Theme.textMuted
                        font.family: Theme.fontUi
                        font.pointSize: Theme.smallSize
                        font.bold: t.isCurrent
                        elide: Text.ElideMiddle
                        textFormat: Text.PlainText
                    }
                    IconButton {
                        iconName: "window-close"
                        tip: "Close tab"
                        shortcut: t.isCurrent ? "Ctrl+W" : ""
                        implicitWidth: 24
                        implicitHeight: 24
                        opacity: t.isCurrent || hover.hovered ? 1 : 0.5
                        onClicked: bar.closeRequested(t.index)
                    }
                }
            }
        }
        IconButton {
            Layout.alignment: Qt.AlignVCenter
            iconName: "list-add"
            tip: "Open in a new tab"
            shortcut: "Ctrl+O"
            implicitWidth: 28
            implicitHeight: 28
            onClicked: bar.newRequested()
        }
    }
}

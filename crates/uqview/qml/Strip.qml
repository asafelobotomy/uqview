import QtQuick
import org.uqview.app
import "logic.js" as L

// The folder's pictures as thumbnails, the current one framed in the accent. Small decodes only,
// loaded as they scroll into view.
Rectangle {
    id: strip

    property var files: []
    property int current: -1
    signal picked(int index)

    color: Theme.surface
    implicitHeight: 76
    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }

    ListView {
        id: list
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        orientation: ListView.Horizontal
        spacing: 6
        model: strip.files
        currentIndex: strip.current
        highlightMoveDuration: 120
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: width / 2 - 40
        preferredHighlightEnd: width / 2 + 40
        cacheBuffer: 600
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        delegate: Rectangle {
            id: cell
            required property string modelData
            required property int index
            readonly property bool isCurrent: index === strip.current
            width: 80
            height: list.height
            radius: Math.max(3, Theme.radius - 4)
            color: Theme.surfaceAlt
            border.width: isCurrent ? 2 : 0
            border.color: Theme.accent
            Accessible.role: Accessible.ListItem
            Accessible.name: L.baseName(modelData)
            Image {
                anchors.fill: parent
                anchors.margins: cell.isCurrent ? 3 : 1
                source: L.fileUrl(cell.modelData)
                sourceSize: Qt.size(160, 120)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                autoTransform: true
                opacity: cell.isCurrent ? 1 : (hover.hovered ? 0.95 : 0.7)
                Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easing } }
            }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: strip.picked(cell.index) }
        }
    }
}

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: scrollBar

    property Flickable flickableSource: null
    property Item topAnchorItem: null

    width: 8
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.top: topAnchorItem ? topAnchorItem.bottom : parent.top
    opacity: (flickableSource && (flickableSource.flicking || flickableSource.pressed)) ? 0.7 : 0.0
    Behavior on opacity { NumberAnimation { duration: 200 } }
    visible: flickableSource && (flickableSource.contentHeight > flickableSource.height)

    Rectangle {
        x: 1
        y: (flickableSource ? flickableSource.visibleArea.yPosition : 0) * (parent.height - 2) + 1

        width: parent.width - 2
        height: (flickableSource ? flickableSource.visibleArea.heightRatio : 0) * (parent.height - 2)

        radius: (parent.width - 2) / 2
        color: "white"
        opacity: 0.7
    }

    Component.onCompleted: {
        if (!flickableSource) {
            console.warn("ScrollBar (ID: " + scrollBar.id + "): 'flickableSource' property is not set. Scrollbar will not function correctly.");
        }
    }
}

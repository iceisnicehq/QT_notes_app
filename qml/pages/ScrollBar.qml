// Scrollbar.qml
import QtQuick 2.0
import Sailfish.Silica 1.0 

Item {
    id: scrollBar

    property Flickable flickableSource: null
    property Item topAnchorItem: null

    width: 8 // Fixed width for the scrollbar component itself
    // Anchors to the right and bottom of the parent (the Page)
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    // The top anchor now depends on topAnchorItem.
    // If topAnchorItem is provided, it anchors to its bottom.
    // Otherwise, it anchors to the parent's top (start from the very top of the page).
    anchors.top: topAnchorItem ? topAnchorItem.bottom : parent.top
    // Opacity logic: Visible if flicking OR pressed, otherwise fades out
    // Includes checks for 'flickableSource' being null to prevent errors
    opacity: (flickableSource && (flickableSource.flicking || flickableSource.pressed)) ? 0.7 : 0.0
    Behavior on opacity { NumberAnimation { duration: 200 } }
    // Visibility logic: Only visible if content height is greater than flickable height
    // Includes checks for 'flickableSource' being null
    visible: flickableSource && (flickableSource.contentHeight > flickableSource.height)

    // The actual moving scroll bar handle
    Rectangle {
        x: 1 // 1 pixel inset from the left edge of 'scrollBar' Item
        // y position dynamically changes based on scroll progress of flickableSource
        y: (flickableSource ? flickableSource.visibleArea.yPosition : 0) * (parent.height - 2) + 1

        // Width of the bar: parent.width is the width of 'scrollBar' (which is 8px)
        width: parent.width - 2 // This will be 6px wide (8 - 2)
        // Height dynamically changes based on the visible portion of the content
        height: (flickableSource ? flickableSource.visibleArea.heightRatio : 0) * (parent.height - 2)

        radius: (parent.width - 2) / 2 // Still (8 - 2) / 2 = 3px radius for perfect rounding
        color: "white" // The color of the scrollbar handle
        opacity: 0.7   // Initial opacity (fades out/in controlled by 'scrollBar.opacity')
    }

    // Add a warning if flickableSource is not set
    Component.onCompleted: {
        if (!flickableSource) {
            console.warn("ScrollBar (ID: " + scrollBar.id + "): 'flickableSource' property is not set. Scrollbar will not function correctly.");
        }
    }
}

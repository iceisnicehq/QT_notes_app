// NavigationButton.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent.width
    height: Theme.itemSizeMedium

    property string icon: ""
    property string text: ""
    property bool selected: false
    // New property for note count
    property int noteCount: -1 // Default to -1 or 0 if no count is provided

    signal clicked()

    Rectangle {
        anchors.fill: parent
        color: selected ? "#2a2b38" : "transparent"
        visible: mouseArea.pressed || selected
    }

    // Icon (left-aligned)
    Icon {
        id: navIcon
        source: root.icon
        width: Theme.iconSizeSmall
        height: Theme.iconSizeSmall
        color: selected ? "#e2e3e8" : "#a0a1ab"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingLarge
    }

    // Note Count Label (right-aligned)
    Label {
        id: countLabel
        visible: root.noteCount !== -1 // Only show if a count is provided
        text: root.noteCount >= 100 ? "99+" : root.noteCount.toString()
        color: selected ? "#e2e3e8" : "#a0a1ab"
        font.pixelSize: Theme.fontSizeSmall * 0.9 // Make it a tiny bit smaller
        font.bold: true // Optional: make count bold for better readability
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        // Fixed width for the count label to ensure consistent spacing for "99+"
        width: Theme.fontSizeMedium * 1.5
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
    }

    // Tag Name Label (between icon and count)
    Label {
        id: tagNameLabel
        text: root.text
        color: selected ? "#e2e3e8" : "#a0a1ab"
        font.pixelSize: Theme.fontSizeMedium
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: navIcon.right
        anchors.leftMargin: Theme.paddingMedium // Spacing between icon and text
        // Anchor right to the left of the count label, with spacing
        anchors.right: countLabel.left
        anchors.rightMargin: Theme.paddingMedium
        elide: Text.ElideRight // Ensure long names are elided
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            root.clicked()
        }
    }
}

// NavigationButton.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB // Assuming this contains actual DB operations like getAllNotes, searchNotes, etc.
Item {
    id: root
    width: parent.width
    height: Theme.itemSizeMedium

    property string icon: ""
    property string text: ""
    property bool selected: false
    // New property for note count
    property int noteCount: -1 // Default to -1 or 0 if no count is provided
    // Changed 'activeColor' to 'selectedColor' to match the property passed from SidePanel.qml
    property string selectedColor: DB.getThemeColor() // Default to theme color if not explicitly set
    signal clicked()

    Rectangle {
        anchors.fill: parent
        // Use 'root.selectedColor' when the button is selected
        color: selected ? root.selectedColor : "transparent"
        visible: mouseArea.pressed || selected
        // Adding rounded corners as per general instructions for aesthetics
        radius: Theme.itemSizeSmall * 0.1 // A small radius for a subtle rounded look
    }

    // Icon (left-aligned)
    Icon {
        id: navIcon
        source: root.icon
        width: Theme.iconSizeSmall
        height: Theme.iconSizeSmall
        // Use theme colors for selected/unselected states
        color: selected ? Theme.primaryColor : Theme.secondaryColor // Example: white/light gray for selected, dark gray for unselected
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingLarge
    }

    // Note Count Label (right-aligned)
    Label {
        id: countLabel
        visible: root.noteCount !== -1 // Only show if a count is provided
        text: root.noteCount >= 1000 ? "999+" : root.noteCount.toString()
        // Use theme colors for selected/unselected states
        color: selected ? Theme.primaryColor : Theme.secondaryColor
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
        // Use theme colors for selected/unselected states
        color: selected ? Theme.primaryColor : Theme.secondaryColor
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

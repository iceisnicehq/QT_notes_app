// qml/components/TrashArchiveNoteCard.qml
// This component displays an individual note card within the Trash or Archive pages.

import QtQuick 2.0
import Sailfish.Silica 1.0 // Ensure this import correctly defines Theme properties
import QtQuick.Layouts 1.1 // Import for ColumnLayout
import "DatabaseManager.js" as DB // Keep if other DB functions are used here, otherwise can remove

Item { // Changed from Rectangle to Item as it's a better base for components that contain other visuals
    id: root
    width: parent ? parent.width : 360 // Use parent.width for better adaptability
    // Adjusted implicitHeight to now only account for the main card rectangle itself
    implicitHeight: mainCardRectangle.implicitHeight

    // --- Properties ---
    property string title: ""
    property string content: ""
    property string tags: ""
    property string cardColor: "#1c1d29"
    // isSelected property will be driven *only* by the parent (e.g., TrashPage or UnifiedNotesPage)
    property bool isSelected: false
    property int noteId: -1

    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()

    // Removed: deletionDateTimestamp and inTrashContext properties are no longer here.
    // The date display will be handled by the parent QML directly below the card.


    // Properties for selection state (now directly used by the Rectangle below)
    property color selectedBorderColor: "#00000000" // Default to transparent
    property int selectedBorderWidth: 0 // Default to no border

    // --- Signals ---
    signal selectionToggled(int noteId, bool isCurrentlySelected)
    // Updated signal to include isArchived and isDeleted flags, as they were passed previously
    signal noteClicked(int noteId, string title, string content, bool isPinned, var tags, date creationDate, date editDate, string color, bool isArchived, bool isDeleted)


    // --- UI Components ---
    Rectangle {
        id: mainCardRectangle // Main visual container for the note card
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: cardColumn.implicitHeight + (Theme.paddingLarge * 2) // Height determined by inner content + padding
        color: root.cardColor
        radius: 20
        // Initial default border
        border.color: "#43484e"
        border.width: 1

        // States for the main card's border based on selection
        states: [
            State {
                name: "selectedCard"
                when: root.isSelected === true
                PropertyChanges {
                    target: mainCardRectangle
                    border.color: "#FFFFFF" // White border
                    border.width: 4        // Width 4
                }
            },
            State {
                name: "deselectedCard"
                when: root.isSelected === false
                PropertyChanges {
                    target: mainCardRectangle
                    border.color: "#43484e" // Revert to original border color
                    border.width: 1        // Revert to original border width
                }
            }
        ]

        // Add animations for border changes
        transitions: Transition {
            PropertyAnimation { properties: "border.color,border.width"; duration: 150 }
        }


        // MouseArea for clicking the entire card (to open NotePage)
        MouseArea {
            id: wholeCardMouseArea
            anchors.fill: parent

            onClicked: {
                console.log("TrashArchiveNoteCard (ID:", root.noteId, "): Full card clicked. Emitting noteClicked signal.");
                root.noteClicked(
                    root.noteId,
                    root.title,
                    root.content,
                    root.noteIsPinned,
                    root.tags,
                    root.noteCreationDate,
                    root.noteEditDate,
                    root.cardColor,
                    false, // isArchived - This card component itself doesn't know its archive status
                    true // isDeleted - Assuming this component is always used for deleted/archived notes
                );
                Qt.inputMethod.hide();
            }
        }

        // --- Container for the checkbox with enlarged click area ---
        Item {
            id: checkboxClickArea
            anchors {  right: parent.right; rightMargin: Theme.paddingMedium }
            width: Theme.iconSizeSmall * 2.4
            height: width

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.selectionToggled(root.noteId, root.isSelected); // Pass current state to parent
                    console.log("TrashArchiveNoteCard (ID:", root.noteId, "): Checkbox click detected. Emitting selectionToggled for ID:", root.noteId, "Current isSelected:", root.isSelected);
                }
            }

            // --- The visual checkbox itself (Rectangle) ---
            Rectangle {
                id: visualCheckbox
                anchors.centerIn: parent
                height: 47
                width: 47
                radius: 17

                // Default properties for the checkbox (e.g., deselected state visual)
                color: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#32353a" // Fallback to a dark gray
                border.color: Theme.secondaryColor !== undefined ? Theme.secondaryColor : "#00bcd4" // Fallback to a teal/cyan
                border.width: 2 // Reverted to original border width for deselected state

                // Define states for the checkbox based on the isSelected property
                states: [
                    State {
                        name: "selected"
                        when: root.isSelected === true
                        PropertyChanges {
                            target: visualCheckbox
                            color: "#FFFFFF" // NEW: Make the checkbox white when selected
                            border.color: "transparent" // No border when selected
                            border.width: 0
                        }
                    },
                    State {
                        name: "deselected"
                        when: root.isSelected === false
                        PropertyChanges {
                            target: visualCheckbox
                            color: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#32353a"
                            border.color: Theme.secondaryColor !== undefined ? Theme.secondaryColor : "#00bcd4"
                            border.width: 2
                        }
                    }
                ]

                // Optional: Smooth transition between states
                transitions: Transition {
                    PropertyAnimation { properties: "color,border.color,border.width"; duration: 150 }
                }
            }
        }

        // Column for card content
        ColumnLayout { // Changed to ColumnLayout for better control over implicitHeight and alignment
            id: cardColumn
            width: parent.width - (Theme.paddingLarge * 2) // Content width inside the card
            anchors.centerIn: parent // Center content vertically within mainCardRectangle
            spacing: Theme.paddingSmall // Spacing between elements within the card

            // Note Title
            Label {
                Layout.fillWidth: true
                text: (root.title && root.title.trim()) ? root.title : qsTr("Empty")
                font.italic: !(root.title && root.title.trim())
                horizontalAlignment: "AlignHCenter"
                color: "#e8eaed"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap
            }

            // Note Content Snippet
            Label {
                Layout.fillWidth: true
                text: (root.content && root.content.trim()) ? root.content : qsTr("Empty")
                font.italic: !(root.content && root.content.trim())
                textFormat: Text.PlainText
                horizontalAlignment: "AlignJustify"
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: "#c5c8d0"
            }

            Flow {
                id: tagsFlow
                Layout.fillWidth: true
                spacing: Theme.paddingSmall
                visible: root.tags && root.tags.trim().length > 0

                // Repeater to display each tag
                Repeater {
                    model: root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" })
                    delegate: Rectangle {
                        visible: index < 2
                        color: "#32353a"
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium * 2, parent.width * 0.45)

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            elide: Text.ElideRight
                            anchors.centerIn: parent
                            width: parent.width - (Theme.paddingMedium * 2)
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // "+X" bubble for more than 2 tags
                Rectangle {
                    visible: root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" }).length > 2
                    color: "#32353a"
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" }).length - 2)
                        color: "#c5c8d0"
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }
    // Removed deletionDateText Label from here. It will be in TrashPage.qml now.
}

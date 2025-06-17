// TrashNoteCard.qml

import QtQuick 2.0
import Sailfish.Silica 1.0 // Ensure this import correctly defines Theme properties
import "DatabaseManager.js" as DB

Item {
    id: root
    width: parent ? parent.width : 360
    implicitHeight: cardColumn.implicitHeight + (Theme.paddingLarge * 2)

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

    // NEW: Properties to control the border appearance when selected (now directly used by the Rectangle below)
    // These properties are still here for compatibility if other parts of your app rely on them,
    // but the border logic is now primarily handled by states within this component.
    property color selectedBorderColor: "#00000000" // Default to transparent
    property int selectedBorderWidth: 0 // Default to no border

    // --- Signals ---
    // Signal now implies a request to toggle selection for a given noteId and its *current* state.
    // The parent will then decide the *new* state.
    signal selectionToggled(int noteId, bool isCurrentlySelected)
    signal noteClicked(int noteId, string title, string content, bool isPinned, var tags, date creationDate, date editDate, string color)


    // --- UI Components ---
    Rectangle {
        id: mainCardRectangle // Added ID for clarity when defining states
        anchors.fill: parent
        color: root.cardColor // This keeps the card's original color (not white background)
        radius: 20
        // Initial default border
        border.color: "#43484e"
        border.width: 1

        // NEW: States for the main card's border based on selection
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
                console.log("TrashNoteCard (ID:", root.noteId, "): Full card clicked. Emitting noteClicked signal.");
                root.noteClicked(
                    root.noteId,
                    root.title, // Correctly passing title
                    root.content,
                    root.noteIsPinned,
                    root.tags,
                    root.noteCreationDate,
                    root.noteEditDate,
                    root.cardColor
                );
                Qt.inputMethod.hide();
            }
        }

        // --- Container for the checkbox with enlarged click area ---
        Item {
            id: checkboxClickArea
            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: Theme.paddingMedium }
            width: Theme.iconSizeSmall * 2.4
            height: width

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.selectionToggled(root.noteId, root.isSelected); // Pass current state to parent
                    console.log("TrashNoteCard (ID:", root.noteId, "): Checkbox click detected. Emitting selectionToggled for ID:", root.noteId, "Current isSelected:", root.isSelected);
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
        Column {
            id: cardColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.topMargin: Theme.paddingLarge
            anchors.leftMargin: Theme.paddingLarge
            anchors.bottomMargin: Theme.paddingLarge
            anchors.rightMargin: checkboxClickArea.width + Theme.paddingMedium // Adjust right margin to prevent overlap with checkbox

            width: parent.width - (anchors.leftMargin + anchors.rightMargin) // Calculate width dynamically

            spacing: Theme.paddingSmall

            Text {
                id: titleText
                text: (root.title && root.title.trim()) ? root.title : qsTr("Empty")
                font.italic: !(root.title && root.title.trim())
                color: "#e8eaed"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap
                width: parent.width
            }

            Text {
                id: contentText
                text: (root.content && root.content.trim()) ? root.content : qsTr("Empty")
                font.italic: !(root.content && root.content.trim())
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: "#c5c8d0"
                width: parent.width
            }

            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall
                visible: root.tags && root.tags.trim().length > 0 // Only show if tags string is not empty

                // Repeater to display each tag
                Repeater {
                    model: root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" }) // Split string into array, filter out empty tags
                    delegate: Rectangle {
                        visible: index < 2 // Show only first 2 tags
                        color: "#32353a"
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium * 2, parent.width * 0.45) // Max width for tag bubble

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
}

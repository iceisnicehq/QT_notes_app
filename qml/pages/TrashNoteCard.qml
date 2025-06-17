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

    // --- Signals ---
    // Signal now implies a request to toggle selection for a given noteId and its *current* state.
    // The parent will then decide the *new* state.
    signal selectionToggled(int noteId, bool isCurrentlySelected)
    signal noteClicked(int noteId, string title, string content, bool isPinned, var tags, date creationDate, date editDate, string color)


    // --- UI Components ---
    Rectangle {
        anchors.fill: parent
        color: root.cardColor
        radius: 20
        border.color: "#43484e"
        border.width: 1

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
                    // IMPORTANT CHANGE: Do NOT directly set root.isSelected here.
                    // Instead, emit the signal, and let the parent (TrashPage/UnifiedNotesPage) update its selectedNoteIds list.
                    // The 'isSelected' property of THIS TrashNoteCard instance will then update automatically
                    // via its binding in the Repeater, and the visual states will react to that.
                    root.selectionToggled(root.noteId, root.isSelected); // Pass current state to parent
                    console.log("TrashNoteCard (ID:", root.noteId, "): Checkbox click detected. Emitting selectionToggled for ID:", root.noteId, "Current isSelected:", root.isSelected);
                }
            }

            // --- The visual checkbox itself (Rectangle) ---
            Rectangle {
                id: visualCheckbox
                anchors.centerIn: parent
                //width: Theme.iconSizeSmall
                //height: width
                height: 47
                width: 47
                radius: 17

                // Default properties for the checkbox (e.g., deselected state visual)
                // These are the "base" colors that will be overridden by states
                // Added fallbacks using '?:' operator to prevent 'undefined' errors
                color: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#32353a" // Fallback to a dark gray
                border.color: Theme.secondaryColor !== undefined ? Theme.secondaryColor : "#00bcd4" // Fallback to a teal/cyan
                border.width: 5

                // Define states for the checkbox based on the isSelected property
                states: [
                    State {
                        name: "selected"
                        when: root.isSelected === true
                        PropertyChanges {
                            target: visualCheckbox
                            // Use Theme.secondaryColor if defined, else a default
                            color: Theme.secondaryColor !== undefined ? Theme.secondaryColor : "#00bcd4" // Fallback to teal/cyan
                            border.color: "transparent" // No border when selected
                            border.width: 0
                        }
                    },
                    State {
                        name: "deselected"
                        when: root.isSelected === false
                        PropertyChanges {
                            target: visualCheckbox
                            // Use Theme.backgroundColor if defined, else a dark gray
                            color: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#32353a" // Fallback to dark gray
                            // Use Theme.secondaryColor if defined, else a default
                            border.color: Theme.secondaryColor !== undefined ? Theme.secondaryColor : "#00bcd4" // Fallback to teal/cyan
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
                wrapMode: Text.WordWrap
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

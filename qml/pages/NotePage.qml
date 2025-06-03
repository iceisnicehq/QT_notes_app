// qml/pages/NotePage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: notePage
    property int noteId: 0   // passed when opening for existing note

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
//        padding: Theme.paddingLarge

        // Title field
        TextField {
            id: titleField
            label: "Title"
            placeholderText: "Enter title"
            font.pixelSize: Theme.fontSizeLarge
        }

        // Content area
        TextArea {
            id: contentArea
            label: "Content"
            placeholderText: "Write your note here..."
            wrapMode: Text.Wrap
            anchors.fill: parent
        }

        // Tags field (comma-separated)
        TextField {
            id: tagsField
            label: "Tags"
            placeholderText: "tag1, tag2, ..."
        }

        // Pin toggle
        TextSwitch {
            id: pinSwitch
            text: "Pinned"
            width: parent.width
        }
    }

    Component.onCompleted: {
        if (noteId !== 0) {
            // Load existing note
            var note = Database.getNoteById(noteId);
            titleField.text = note.title;
            contentArea.text = note.content;
            tagsField.text = note.tags.join(", ");
            pinSwitch.checked = note.pinned;
        }
    }

    // Pulley menu actions (Save and Delete)
    PullDownMenu {
        id: menu
        MenuItem {
            text: "Save"
            onClicked: {
                // Split tags by comma, trim whitespace
                var tags = tagsField.text.split(",").map(function(t){ return t.trim() }).filter(function(t){ return t });
                var savedId = Database.saveNote(noteId, titleField.text, contentArea.text, tags, pinSwitch.checked);
                notePage.noteId = savedId;
                // Go back to main page
                pageStack.pop();
            }
        }
        MenuItem {
            text: "Delete"
            onClicked: {
                if (noteId !== 0) {
                    Database.deleteNote(noteId);
                }
                pageStack.pop();
            }
        }
    }
}

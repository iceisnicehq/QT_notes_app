// NewNotePage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB // Still needed for DB operations on destruction

Page { // Correctly using Page from Sailfish.Silica
    id: newNotePage

    property var onNoteSavedOrDeleted: null // Callback to refresh main page

    // These properties will hold the *current* state of the note as the user types
    property int noteId: -1 // Will be -1 for new notes, or actual ID for editing
    property string noteTitle: ""
    property string noteContent: ""
    property var noteTags: [] // Will be an array of strings
    property bool noteIsPinned: false // Default to not pinned

    // --- REMOVED: ToastManager and showToast function ---

    Component.onCompleted: {
        // Automatically focus the content area and open keyboard
        noteContentInput.forceActiveFocus();
        Qt.inputMethod.show();
        console.log("NewNotePage opened.");

        // Pre-fill fields if editing an existing note
        if (noteId !== -1) {
            noteTitleInput.text = noteTitle;
            noteContentInput.text = noteContent;
            // Set initial color for pin icon if editing
            pinIconButton.icon.color = noteIsPinned ? Theme.highlightColor : Theme.primaryColor;
            console.log("NewNotePage opened in EDIT mode for ID:", noteId);
        } else {
            console.log("NewNotePage opened in CREATE mode.");
        }
    }

    // This is crucial: save/delete on page destruction (pop from stack)
    Component.onDestruction: {
        console.log("NewNotePage being destroyed. Attempting to save/delete note.");

        var trimmedTitle = noteTitle.trim();
        var trimmedContent = noteContent.trim();

        if (trimmedTitle === "" && trimmedContent === "") {
            // If both title and content are empty, delete the note if it was ever created
            if (noteId !== -1) { // This condition would only be true if editing an an existing note
                DB.deleteNote(noteId); // Sync call
                console.log("Debug: Empty existing note deleted with ID:", noteId);
            } else {
                console.log("Debug: New empty note not saved.");
            }
            // --- REMOVED TOAST CALL ---
        } else {
            // If there's content, save or update the note
            if (noteId === -1) { // This is a brand new note
                var newId = DB.addNote(noteIsPinned, noteTitle, noteContent, noteTags); // Sync call
                // noteId = newId; // No need to update local ID as page is destroying
                console.log("Debug: New note added with ID:", newId);
                // --- REMOVED TOAST CALL ---
            } else { // This is an existing note being updated
                DB.updateNote(noteId, noteIsPinned, noteTitle, noteContent, noteTags); // Sync call
                console.log("Debug: Note updated with ID:", noteId);
                // --- REMOVED TOAST CALL ---
            }
        }

        // Always refresh main page data after potentially adding/deleting/updating
        if (onNoteSavedOrDeleted) {
            onNoteSavedOrDeleted();
        }
    }


    // --- Page Header ---
    PageHeader {
        id: header
        // --- DYNAMIC TITLE: based on whether it's a new note or existing ---
        title: newNotePage.noteId === -1 ? "New Note" : "Edit Note"

        // Left: Close Button
        IconButton {
            id: closeButton
            icon.source: "../icons/back.svg"
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Theme.paddingLarge
            }
            onClicked: {
                pageStack.pop(); // Go back to the previous page (MainPage)
            }
        }

        // Right: Pin Buttons (Placeholder for now)
        Row {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: Theme.paddingLarge
            }
            spacing: Theme.paddingMedium

            IconButton {
                id: pinIconButton // Added ID to reference it in Component.onCompleted
                icon.source: "../icons/pin.svg"
                onClicked: {
                    noteIsPinned = !noteIsPinned; // Toggle pin status
                    icon.color = noteIsPinned ? Theme.highlightColor : Theme.primaryColor;
                    // --- REMOVED TOAST CALL ---
                }
                // Initial icon color set in Component.onCompleted above for consistency
            }
            IconButton {
                icon.source: "../icons/pin.svg"
                onClicked: console.log("Pin button 2 clicked (placeholder)");
            }
            IconButton {
                icon.source: "../icons/pin.svg"
                onClicked: console.log("Pin button 3 clicked (placeholder)");
            }
        }
    }

    // --- Page Content ---
    SilicaFlickable {
        anchors.fill: parent
        anchors.topMargin: header.height
        contentHeight: columnLayout.height

        Column {
            id: columnLayout
            width: parent.width
            spacing: Theme.paddingMedium
            // --- REMOVED 'padding' property from Column ---
            // As discussed, Column does not have a padding property.
            // If you need content padding, wrap this column in an Item/Rectangle with padding
            // or apply margins to the children.

            // Title Input
            TextField {
                id: noteTitleInput
                width: parent.width
                placeholderText: "Title"
                label: "Title"
                text: newNotePage.noteTitle // Bind to the noteTitle property
                onTextChanged: newNotePage.noteTitle = text
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
                inputMethodHints: Qt.ImhNoAutoUppercase
            }

            // Note Content Input
            TextArea {
                id: noteContentInput
                width: parent.width
                height: Math.max(parent.height - noteTitleInput.height - Theme.paddingMedium * 4, Theme.itemSizeExtraLarge * 3) // Minimum height
                placeholderText: "Note"
                label: "Note"
                text: newNotePage.noteContent // Bind to the noteContent property
                onTextChanged: newNotePage.noteContent = text
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.primaryColor
                verticalAlignment: Text.AlignTop
            }
        }
    }
}

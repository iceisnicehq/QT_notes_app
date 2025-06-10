// NewNotePage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Page { // Changed from 'Page' to 'SilicaPage' for Sailfish theme consistency
    id: newNotePage
    ToastManager {
        id: toast
    }
    property var onNoteSavedOrDeleted: null // Callback to refresh main page

    // These properties will hold the *current* state of the note as the user types
    property int noteId: -1 // Will remain -1 until saved for the first time or loaded
    property string noteTitle: ""
    property string noteContent: ""
    property var noteTags: [] // Will be an array of strings
    property bool noteIsPinned: false // Default to not pinned

    // Function to show toast notification using the global ToastManager
    function showToast(message) {
        if (root && root.toastManager) {
            root.toastManager.show(message);
        } else {
            console.warn("ToastManager not found or not accessible via 'root'. Cannot show toast:", message);
            console.log("TOAST:", message);
        }
    }

    // --- No Component.onCompleted database call for adding initial note ---
    // The note will only be added/saved when the page is destroyed.

    Component.onCompleted: {
        // Automatically focus the content area and open keyboard
        noteContentInput.forceActiveFocus();
        Qt.inputMethod.show();
        console.log("NewNotePage opened. Ready for input.");
    }

    // This is crucial: save/delete on page destruction (pop from stack)
    Component.onDestruction: {
        console.log("NewNotePage being destroyed. Attempting to save/delete note.");

        var trimmedTitle = noteTitle.trim();
        var trimmedContent = noteContent.trim();

        if (trimmedTitle === "" && trimmedContent === "") {
            // If both title and content are empty, delete the note if it was ever created
            // Since we're not creating it on entry, it's safer to just *not save* it.
            // If noteId was assigned from an *existing* note being edited, then delete.
            // For *new* notes, if it's empty, we simply do nothing.
            if (noteId !== -1) { // This condition would only be true if editing an existing note
                DB.deleteNote(noteId); // Sync call
                console.log("Empty existing note deleted with ID:", noteId);
            } else {
                console.log("New empty note not saved.");
            }
            showToast("Пустая заметка не была сохранена");
        } else {
            // If there's content, save or update the note
            if (noteId === -1) { // This is a brand new note
                var newId = DB.addNote(noteIsPinned, noteTitle, noteContent, noteTags); // Sync call
                noteId = newId; // Update local ID, though page is destroying
                console.log("New note added with ID:", noteId);
                showToast("Заметка сохранена!"); // Notify user that it was saved
            } else { // This is an existing note being updated (if you implement editing later)
                DB.updateNote(noteId, noteIsPinned, noteTitle, noteContent, noteTags); // Sync call
                console.log("Note updated with ID:", noteId);
                showToast("Заметка обновлена!"); // Notify user that it was updated
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
        title: "New Note" // You can make this dynamic based on title input

        // Left: Close Button
        IconButton {
            id: closeButton
            icon.source: "../icons/back.svg" // Common back icon, or use close.svg
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
                icon.source: "../icons/pin.svg"
                onClicked: {
                    noteIsPinned = !noteIsPinned; // Toggle pin status
                    icon.color = noteIsPinned ? Theme.highlightColor : Theme.primaryColor;
                    showToast("Note is now " + (noteIsPinned ? "pinned" : "unpinned"));
                }
                // No need for Component.onCompleted here for icon color on a new note
                // as `noteIsPinned` starts as false and won't be changed before interaction.
                // If you were loading an existing note, you'd set initial color.
            }
            IconButton {
                icon.source: "../icons/pin.svg" // Placeholder
                onClicked: showToast("Pin button 2 clicked (placeholder)");
            }
            IconButton {
                icon.source: "../icons/pin.svg" // Placeholder
                onClicked: showToast("Pin button 3 clicked (placeholder)");
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
            //padding: Theme.paddingLarge // Re-added padding for better aesthetics

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
                // Adjust height dynamically, or give it a minimum height
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

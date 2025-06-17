// NotePage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB // Убедитесь, что этот путь верен и DatabaseManager.js экспортирует нужные функции

Page {
    id: newNotePage
    backgroundColor: newNotePage.noteColor
    showNavigationIndicator: false
    property var onNoteSavedOrDeleted: null
    property int noteId: -1
    property string noteTitle: ""
    property string noteContent: ""
    property var noteTags: [] // This property holds the tags for the current note being edited/created
    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()
    property string noteColor: "#121218"
    property bool noteModified: false

    property bool isFromTrash: false // мое новое для режима редакта просмотра в корзине как на яблоке в заметках (проверил там)

    // Properties for read-only mode, passed from calling page
    property bool isArchived: false // True if note is opened from ArchivePage
    property bool isDeleted: false  // True if note is opened from TrashPage
    property bool isReadOnly: isArchived || isDeleted // Derived property for overall read-only state

    // Property to track if the note was sent to trash from this page
    property bool sentToTrash: false
    property bool sentToArchive: false // ADDED: Property to track if the note was sent to archive

    // --- Undo/Redo Properties and Functions ---
    // Stores snapshots of the noteContentInput text and cursor position
    property var contentHistory: []
    property int historyIndex: -1   // Current position in the contentHistory array
    property bool isUndoingRedoing: false // Flag to prevent history updates during undo/redo operations

    // Properties for generic confirmation dialog (used by ConfirmDialog component)
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: ""
    property string confirmDialogMessage: ""
    property string confirmButtonText: ""
    property color confirmButtonHighlightColor: Theme.primaryColor // Default, will be overridden
    property var onConfirmCallback: null // Function to call when user confirms


    // Timer for continuous history saving
    Timer {
        id: historySaveTimer
        interval: 1000 // Save history every 1 second
        running: !newNotePage.isReadOnly // Only run if not in read-only mode
        repeat: true   // Repeat continuously
        onTriggered: {
            // Only save if not currently undoing/redoing AND content has actually changed from the last saved state
            if (!newNotePage.isUndoingRedoing &&
                newNotePage.contentHistory.length > 0 && // Ensure history exists before comparing
                noteContentInput.text !== newNotePage.contentHistory[newNotePage.historyIndex].text) {
                newNotePage.addToContentHistory(noteContentInput.text, noteContentInput.cursorPosition);
                console.log(qsTr("History auto-saved: \"%1\" (cursor: %2)").arg(noteContentInput.text).arg(noteContentInput.cursorPosition));
            } else if (!newNotePage.isUndoingRedoing && newNotePage.contentHistory.length === 0) {
                // If history is empty, and text is not empty, add initial state
                if (noteContentInput.text !== "") {
                    newNotePage.addToContentHistory(noteContentInput.text, noteContentInput.cursorPosition);
                    console.log(qsTr("Initial history state added by timer: \"%1\" (cursor: %2)").arg(noteContentInput.text).arg(noteContentInput.cursorPosition));
                }
            }
        }
    }

    /**
     * @brief showGeneralConfirmDialog
     * Helper function to configure and show the single ConfirmDialog component.
     * @param message Text message for the dialog.
     * @param callback Function to execute if the user confirms.
     * @param title Title for the dialog (optional, uses default if not provided).
     * @param buttonText Text for the confirm button (optional, uses default "Confirm" if not provided).
     * @param highlightColor Highlight color for the confirm button (optional, uses default Theme.primaryColor if not provided).
     */
    function showGeneralConfirmDialog(message, callback, title, buttonText, highlightColor) {
        newNotePage.confirmDialogMessage = message;
        newNotePage.onConfirmCallback = callback;
        newNotePage.confirmDialogTitle = title !== undefined ? title : qsTr("Confirm Action");
        newNotePage.confirmButtonText = buttonText !== undefined ? buttonText : qsTr("Confirm");
        newNotePage.confirmButtonHighlightColor = highlightColor !== undefined ? highlightColor : Theme.primaryColor;
        newNotePage.confirmDialogVisible = true;
    }


    /**
     * @brief handleInteractionAttempt
     * Checks if the note is in a state (deleted or archived) that requires user action
     * before allowing editing or other modifications. If so, it shows a confirmation dialog.
     * This function is intended to be called BEFORE any action that modifies the note's content or properties.
     * @returns {boolean} True if interaction is allowed (note is editable), false otherwise.
     */
    function handleInteractionAttempt() {
        var needsAction = newNotePage.isDeleted || newNotePage.isArchived;
        if (needsAction) {
            newNotePage.isReadOnly = true; // Disable inputs immediately

            var message = "";
            var title = "";
            var buttonText = "";
            var highlight = Theme.primaryColor; // Default for restore/unarchive
            var callbackFunction;

            if (newNotePage.isDeleted) {
                title = qsTr("Cannot Edit Deleted Note");
                message = qsTr("To edit this note, you need to restore it first.");
                buttonText = qsTr("Restore");
                callbackFunction = function() {
                    DB.restoreNote(newNotePage.noteId);
                    newNotePage.isDeleted = false;
                    newNotePage.isReadOnly = false; // Allow editing now
                    toastManager.show(qsTr("Note restored!"));
                    if (onNoteSavedOrDeleted) {
                        onNoteSavedOrDeleted();
                    }
                    noteContentInput.forceActiveFocus(); // Give focus to content input
                };
            } else if (newNotePage.isArchived) {
                title = qsTr("Cannot Edit Archived Note");
                message = qsTr("To edit this note, you need to unarchive it first.");
                buttonText = qsTr("Unarchive");
                callbackFunction = function() {
                    DB.unarchiveNote(newNotePage.noteId);
                    newNotePage.isArchived = false;
                    newNotePage.isReadOnly = false; // Allow editing now
                    toastManager.show(qsTr("Note unarchived!"));
                    if (onNoteSavedOrDeleted) {
                        onNoteSavedOrDeleted();
                    }
                    noteContentInput.forceActiveFocus(); // Give focus to content input
                };
            }
            newNotePage.showGeneralConfirmDialog(message, callbackFunction, title, buttonText, highlight);
            return false; // Interaction is NOT allowed yet, dialog is shown
        }
        newNotePage.isReadOnly = false;
        return true; // Interaction is allowed
    }


    // Function to add content and cursor position snapshots to history
    function addToContentHistory(content, cursorPos) {
        if (newNotePage.isUndoingRedoing || newNotePage.isReadOnly) {
            return; // Do not add to history if we are currently undoing/redoing or in read-only mode
        }

        // If new changes are made and we are not at the end of history,
        // clear any "redoable" history.
        if (newNotePage.historyIndex < newNotePage.contentHistory.length - 1) {
            newNotePage.contentHistory.splice(newNotePage.historyIndex + 1);
        }

        // Add the new content and cursor position to history
        newNotePage.contentHistory.push({ text: content, cursorPosition: cursorPos });
        newNotePage.historyIndex = newNotePage.contentHistory.length - 1;

        // Limit history size to prevent excessive memory usage (e.g., last 100 changes)
        const MAX_HISTORY_SIZE = 100; // You can adjust this value
        if (newNotePage.contentHistory.length > MAX_HISTORY_SIZE) {
            newNotePage.contentHistory.shift(); // Remove the oldest entry
            newNotePage.historyIndex--; // Adjust the index accordingly
        }

        console.log(qsTr("Added to history: \"%1\"").arg(content), qsTr("History size: %1").arg(newNotePage.contentHistory.length), qsTr("Current index: %1").arg(newNotePage.historyIndex));
    }

    // Color palette for note background selection
    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]
    // Function to darken a given hex color by a percentage


    // Actions on component completion (when page is loaded)
    Component.onCompleted: {
        console.log(qsTr("NewNotePage opened. ReadOnly mode: %1, isArchived: %2, isDeleted: %3").arg(newNotePage.isReadOnly).arg(newNotePage.isArchived).arg(newNotePage.isDeleted));
        if (noteId !== -1) {
            // If noteId is set, it's an existing note (EDIT or VIEW mode)
            noteTitleInput.text = noteTitle;
            noteContentInput.text = noteContent;
            // Убедимся, что noteTags - это массив, если он пришел как строка
            if (typeof noteTags === 'string') {
                newNotePage.noteTags = noteTags.split(' ').filter(function(tag) { return tag.length > 0; });
            }
            console.log(qsTr("NewNotePage opened in EDIT mode for ID: %1").arg(noteId));
            console.log(qsTr("Note color on open: %1").arg(noteColor));
            noteModified = false; // Reset modified status
        } else {
            // Otherwise, it's a new note (CREATE mode)
            noteContentInput.forceActiveFocus(); // Focus on content input
            Qt.inputMethod.show(); // Show keyboard
            console.log(qsTr("NewNotePage opened in CREATE mode. Default color: %1").arg(noteColor));
            noteModified = true; // New note is inherently modified
            // Для новой заметки, убесимся, что noteTags - это пустой массив
            newNotePage.noteTags = [];
        }
        // Initialize history with the current note content and cursor position after all initial setup
        // Only if not in read-only mode
        if (!newNotePage.isReadOnly) {
            newNotePage.addToContentHistory(noteContentInput.text, noteContentInput.cursorPosition);
            console.log(qsTr("Initial history state: Index %1, History: %2").arg(newNotePage.historyIndex).arg(JSON.stringify(newNotePage.contentHistory)));
        } else {
            console.log(qsTr("Note in read-only mode, history not initialized."));
        }
    }

    // Actions on component destruction (when page is closed)
    Component.onDestruction: {
        console.log(qsTr("NewNotePage being destroyed. Attempting to save/delete note."));
        var trimmedTitle = noteTitleInput.text.trim();
        var trimmedContent = noteContentInput.text.trim();

        // MODIFIED: Only save if not in read-only mode and not explicitly sent to trash/archive
        if (newNotePage.isReadOnly) {
            console.log(qsTr("Debug: In read-only mode. Skipping save/delete on destruction."));
        } else if (sentToTrash || sentToArchive) {
            // If note was explicitly sent to trash or archive, do nothing on destruction
            console.log(qsTr("Debug: Note already sent to trash/archive. Skipping save/delete on destruction."));
        } else if (trimmedTitle === "" && trimmedContent === "" && newNotePage.noteTags.length === 0 && !newNotePage.noteIsPinned) {
            // If note is empty (title, content, tags, pinned status)
            if (noteId !== -1) {
                // If it was an existing note and now empty, permanently delete it
                DB.permanentlyDeleteNote(noteId);
                console.log(qsTr("Debug: Empty existing note permanently deleted with ID: %1").arg(noteId));
            } else {
                // If it was a new empty note, simply don't save it
                console.log(qsTr("Debug: New empty note not saved."));
            }
        } else {
            // If note has content and is editable
            if (noteId === -1) {
                // If it's a new note, add it to DB
                newNotePage.noteTitle = noteTitleInput.text;
                newNotePage.noteContent = noteContentInput.text;
                var newId = DB.addNote(noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                console.log(qsTr("Debug: New note added with ID: %1, Color: %2, Tags: %3").arg(newId).arg(noteColor).arg(JSON.stringify(noteTags)));
            } else {
                // If it's an existing note, update if modified
                if (noteModified) {
                    newNotePage.noteTitle = noteTitleInput.text;
                    newNotePage.noteContent = noteContentInput.text;
                    newNotePage.noteEditDate = new Date(); // Update edit date
                    DB.updateNote(noteId, noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                    console.log(qsTr("Debug: Note updated with ID: %1, Color: %2, Tags: %3").arg(noteId).arg(noteColor).arg(JSON.stringify(noteTags)));
                } else {
                    console.log(qsTr("Debug: Note with ID: %1 not modified, skipping update.").arg(noteId));
                }
            }
        }
        // Call callback function if provided
        if (onNoteSavedOrDeleted) {
            onNoteSavedOrDeleted();
        }
    }

    ToastManager {
        id: toastManager
    }

    // --- Header Section ---
    Rectangle {
        id: header
        width: parent.width
        height: Theme.itemSizeMedium
        color: newNotePage.noteColor // Header color matches note color
        anchors.top: parent.top
        z: 2
        Column {
            anchors.centerIn: parent
            Label {
                text: newNotePage.noteId === -1 ? qsTr("New Note") : qsTr("Edit Note")
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
            }
            Column {
                visible: newNotePage.noteId !== -1 // Only visible in edit mode
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    text: qsTr("Created: %1").arg(Qt.formatDateTime(newNotePage.noteCreationDate, "dd.MM.yyyy - hh:mm"))
                    font.pixelSize: Theme.fontSizeExtraSmall * 0.7
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    // Determine the prefix based on the newNotePage properties
                    property string statusPrefix: {
                        if (newNotePage.isDeleted) {
                            return qsTr("Deleted: %1");
                        } else if (newNotePage.isArchived) {
                            return qsTr("Archived: %1");
                        } else {
                            return qsTr("Edited: %1");
                        }
                    }

                    // Use the determined prefix with the formatted date
                    text: statusPrefix.arg(Qt.formatDateTime(newNotePage.noteEditDate, "dd.MM.yyyy - hh:mm"))
                    font.pixelSize: Theme.fontSizeExtraSmall * 0.7
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }

            }
        }
        // Close/Check button
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
            RippleEffect { id: backRipple }
            Icon {
                id: closeButton
                // Dynamic source based on note status and content, and read-only mode
                source: {
                    if (newNotePage.isReadOnly) {
                        return "../icons/back.svg"; // Always back arrow in read-only
                    } else if (newNotePage.noteId === -1) { // If it's a new note
                        if (noteTitleInput.text.trim() === "" && noteContentInput.text.trim() === "") {
                            return "../icons/close.svg"; // New and empty: show close
                        } else {
                            return "../icons/check.svg"; // New and has content: show check
                        }
                    } else {
                        return "../icons/back.svg"; // Existing note: always show back
                    }
                }
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }
            MouseArea {
                anchors.fill: parent
                onPressed: backRipple.ripple(mouseX, mouseY)
                onClicked: {
                    // Check if in read-only mode and handle accordingly
                    if (newNotePage.isReadOnly) {
                        pageStack.pop(); // Simply pop back if in read-only mode (from Trash/Archive)
                    } else if (newNotePage.noteId === -1 && noteTitleInput.text.trim() === "" && noteContentInput.text.trim() === "") {
                        // New, empty note, just pop without saving
                        pageStack.pop();
                    } else {
                        // For new note with content or existing modified note, save on pop if not read-only
                        // The onDestruction handler will take care of saving
                        pageStack.pop();
                    }
                }
            }
        }
        // Pin button
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.paddingLarge }
            RippleEffect { id: pinRipple }
            Icon {
                id: pinIconButton
                source: noteIsPinned ? "../icons/pin-enabled.svg" : "../icons/pin.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                // Visually disable pin button in read-only mode
                opacity: 1.0 // Always visible
                color: newNotePage.isReadOnly ? Theme.secondaryColor : Theme.primaryColor // Color changes
            }
            MouseArea {
                anchors.fill: parent
                enabled: true // Always enabled to allow showing dialog
                onPressed: pinRipple.ripple(mouseX, mouseY)
                onClicked: {
                    if (newNotePage.noteId === -1) {
                         toastManager.show(qsTr("Cannot pin a new note. Save it first."));
                         return;
                    }
                    if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                        noteIsPinned = !noteIsPinned;
                        newNotePage.noteModified = true;
                        var msg = noteIsPinned ? qsTr("The note was pinned") : qsTr("The note was unpinned")
                        toastManager.show(msg)
                    }
                }
            }
        }
        // DUPLICATE Button - Added next to Pin button
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            // Anchor to the left of the pin button, with some margin
            anchors { right: pinIconButton.parent.left; verticalCenter: parent.verticalCenter; rightMargin: Theme.paddingMedium }
            RippleEffect { id: duplicateRipple }
            Icon {
                id: duplicateIconButton
                source: "../icons/copy.svg" // Assuming a copy icon exists in your resources
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                // Visually disable if new note
                opacity: (newNotePage.noteId !== -1) ? 1.0 : 0.5 // Always visible, opacity changes
                color: (newNotePage.noteId !== -1) ? (newNotePage.isReadOnly ? Theme.secondaryColor : Theme.primaryColor) : Theme.secondaryColor
            }
            MouseArea {
                anchors.fill: parent
                enabled: newNotePage.noteId !== -1 // Only enabled if it's an existing note
                onPressed: duplicateRipple.ripple(mouseX, mouseY)
                onClicked: {
                    if (newNotePage.noteId === -1) {
                         toastManager.show(qsTr("Cannot duplicate a new note. Save it first."));
                         return;
                    }
                    if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                        // Show the confirmation dialog
                        newNotePage.showGeneralConfirmDialog(
                            qsTr("Do you want to create a copy of this note?"),
                            function() {
                                // Original duplication logic moved here
                                console.log(qsTr("Duplicate button clicked for note ID: %1 (confirmed)").arg(newNotePage.noteId));
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                   onNoteSavedOrDeleted: newNotePage.onNoteSavedOrDeleted, // Use the same refresh callback
                                   noteId: -1, // This makes it a new note
                                   noteTitle: newNotePage.noteTitle + qsTr(" (copy)"), // Append "(copy)" to title
                                   noteContent: newNotePage.noteContent,
                                   noteIsPinned: newNotePage.noteIsPinned,
                                   noteTags: Array.isArray(newNotePage.noteTags) ? newNotePage.noteTags.slice() : [],
                                   noteColor: newNotePage.noteColor, // Copy current color
                                   noteCreationDate: new Date(), // New creation date
                                   noteEditDate: new Date(), // New edit date
                                   noteModified: true // Mark as modified so it saves automatically
                                });
                                toastManager.show(qsTr("Note duplicated!"));
                            },
                            qsTr("Confirm Duplicate"),
                            qsTr("Duplicate"),
                            Theme.positiveColor
                        );
                        console.log(qsTr("Showing duplicate confirmation dialog for note ID: %1").arg(newNotePage.noteId));
                    }
                }
            }
        }
    }

    // --- Bottom Toolbar ---
    Rectangle {
        id: bottomToolbar
        width: parent.width
        height: Theme.itemSizeSmall
        anchors.bottom: parent.bottom
        color: newNotePage.noteColor // Toolbar color matches note color
        z: 11.75
        // Adjust Y position based on keyboard visibility
        y: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.y - height) : (parent.height - height)
        Behavior on y {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        // Left group: Palette, Tag
        Row {
            id: leftToolbarButtons
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            // Color palette button
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: paletteRipple }
                Icon {
                    id: paletteIcon
                    source: "../icons/palette.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    opacity: 1.0 // Always visible
                    color: newNotePage.isReadOnly ? Theme.secondaryColor : Theme.primaryColor // Color changes
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: true // Always enabled to allow showing dialog
                    onPressed: paletteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                            console.log(qsTr("Change color/theme - toggling panel visibility"));
                            // Toggle color selection panel visibility
                            if (colorSelectionPanel.opacity > 0.01) {
                                colorSelectionPanel.opacity = 0;
                            } else {
                                colorSelectionPanel.opacity = 1;
                            }
                        }
                    }
                }
            }
            // Add Tag button - opens the tag selection panel (MOVED HERE)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: addTagRipple }
                Icon {
                    id: addTagIcon
                    source: "../icons/tag.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    opacity: 1.0 // Always visible
                    color: newNotePage.isReadOnly ? Theme.secondaryColor : Theme.primaryColor // Color changes
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: true // Always enabled to allow showing dialog
                    onPressed: addTagRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                            console.log(qsTr("Add Tag button clicked. Opening tag selection panel."));
                            // Toggle tag selection panel visibility
                            if (tagSelectionPanel.opacity > 0.01) {
                                tagSelectionPanel.opacity = 0;
                            } else {
                                tagSelectionPanel.opacity = 1;
                            }
                        }
                    }
                }
            }
        }

        // Center group: Undo, Redo
        Row {
            id: centerToolbarButtons
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.paddingMedium // Spacing between undo and redo

            // Undo button
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: undoRipple }
                Icon {
                    id: undoIcon
                    source: "../icons/undo.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    // ОБНОВЛЕННАЯ ЛОГИКА ЦВЕТА И АКТИВНОСТИ
                    opacity: (newNotePage.historyIndex > 0) ? 1.0 : 0.5
                    color: (newNotePage.historyIndex > 0) ? Theme.primaryColor : Theme.secondaryColor
                }
                MouseArea {
                    anchors.fill: parent
                    // ОБНОВЛЕННАЯ ЛОГИКА АКТИВНОСТИ
                    enabled: (newNotePage.historyIndex > 0 && !newNotePage.isReadOnly)
                    onPressed: undoRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        // handleInteractionAttempt() вызывается внутри функции.
                        // Если noteReadOnly, она покажет диалог и вернет false.
                        // Если true, то продолжит выполнение.
                        if (handleInteractionAttempt()) {
                            console.log(qsTr("Undo action triggered!"));
                            if (newNotePage.historyIndex > 0) {
                                newNotePage.isUndoingRedoing = true; // Prevent history update for this programmatic change
                                newNotePage.historyIndex--; // Move back in history
                                var historicalState = newNotePage.contentHistory[newNotePage.historyIndex];
                                noteContentInput.text = historicalState.text; // Set text to previous state
                                noteContentInput.cursorPosition = historicalState.cursorPosition; // Restore cursor position
                                newNotePage.isUndoingRedoing = false; // Re-enable history updates
                                newNotePage.noteModified = true; // Undo/Redo is a modification
                                toastManager.show(qsTr("Undo successful!"));
                            } else {
                                toastManager.show(qsTr("Nothing to undo."));
                            }
                        }
                    }
                }
            }
            // Redo button
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: redoRipple }
                Icon {
                    id: redoIcon
                    source: "../icons/redo.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    // ОБНОВЛЕННАЯ ЛОГИКА ЦВЕТА И АКТИВНОСТИ
                    opacity: (newNotePage.historyIndex < newNotePage.contentHistory.length - 1) ? 1.0 : 0.5
                    color: (newNotePage.historyIndex < newNotePage.contentHistory.length - 1) ? Theme.primaryColor : Theme.secondaryColor
                }
                MouseArea {
                    anchors.fill: parent
                    // ОБНОВЛЕННАЯ ЛОГИКА АКТИВНОСТИ
                    enabled: (newNotePage.historyIndex < newNotePage.contentHistory.length - 1 && !newNotePage.isReadOnly)
                    onPressed: redoRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                            console.log(qsTr("Redo action triggered!"));
                            if (newNotePage.historyIndex < newNotePage.contentHistory.length - 1) {
                                newNotePage.isUndoingRedoing = true; // Prevent history update for this programmatic change
                                newNotePage.historyIndex++; // Move forward in history
                                var historicalState = newNotePage.contentHistory[newNotePage.historyIndex];
                                noteContentInput.text = historicalState.text; // Set text to next state
                                noteContentInput.cursorPosition = historicalState.cursorPosition; // Restore cursor position
                                newNotePage.isUndoingRedoing = false; // Re-enable history updates
                                newNotePage.noteModified = true; // Undo/Redo is a modification
                                toastManager.show(qsTr("Redo successful!"));
                            } else {
                                toastManager.show(qsTr("Nothing to redo."));
                            }
                        }
                    }
                }
            }
        }


        Row {
            id: rightToolbarButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            // Archive button (moves note to archive)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: archiveRipple }
                Icon {
                    id: archiveIcon
                    source: "../icons/archive.svg" // Assuming you have an archive icon
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    // ОБНОВЛЕННАЯ ЛОГИКА ЦВЕТА
                    // Затемняется, если это новая заметка (noteId === -1) ИЛИ уже архивирована.
                    // Иначе обычный цвет.
                    color: (newNotePage.noteId === -1 || newNotePage.isArchived) ? Theme.secondaryColor : Theme.primaryColor
                    opacity: (newNotePage.noteId === -1 || newNotePage.isArchived) ? 0.1 : 1.0
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: newNotePage.noteId !== -1 // Всегда активна, если заметка существует
                    onPressed: archiveRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (newNotePage.noteId === -1) {
                            toastManager.show(qsTr("Cannot archive a new note. Save it first."));
                            return;
                        }
                        if (newNotePage.isArchived) {
                            toastManager.show(qsTr("Note is already archived"));
                            return;
                        } else {
                            // If note is not archived and not deleted, show archive confirmation
                            newNotePage.showGeneralConfirmDialog(
                                qsTr("Do you want to archive this note?"),
                                function() {
                                    if (newNotePage.noteId !== -1) {
                                        DB.archiveNote(newNotePage.noteId); // Call archive function
                                        console.log(qsTr("Note ID: %1 moved to archive after confirmation.").arg(newNotePage.noteId));
                                        newNotePage.sentToArchive = true; // Mark that it was sent to archive
                                        toastManager.show(qsTr("Note archived!"));
                                        if (onNoteSavedOrDeleted) {
                                            onNoteSavedOrDeleted(); // Refresh data on main page
                                        }
                                    } else {
                                        console.log(qsTr("New unsaved note discarded without archiving."));
                                    }
                                    pageStack.pop(); // Go back to the previous page after action
                                },
                                qsTr("Confirm Archive"),
                                qsTr("Archive"),
                                Theme.primaryColor
                            );
                        }
                    }
                }
            }

            // Delete button (moves note to trash)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: deleteRipple }
                Icon {
                    id: deleteIcon
                    source: "../icons/delete.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    // ОБНОВЛЕННАЯ ЛОГИКА ЦВЕТА
                    // Затемняется, если это новая заметка (noteId === -1) ИЛИ уже удалена.
                    // Иначе обычный цвет.
                    color: (newNotePage.noteId === -1 || newNotePage.isDeleted) ? Theme.secondaryColor : Theme.negativeColor
                    opacity: (newNotePage.noteId === -1 || newNotePage.isDeleted) ? 0.1 : 1.0
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: newNotePage.noteId !== -1 // Всегда активна, если заметка существует
                    onPressed: deleteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (newNotePage.noteId === -1) {
                            toastManager.show(qsTr("Cannot delete a new note. Save it first."));
                            return;
                        }
                        if (newNotePage.isDeleted) {
                            // Если заметка уже в корзине, уведомить пользователя
                            toastManager.show(qsTr("Note is already in the trash"));
                            return; // Выход, никаких действий
                        }
                        else {
                            // If note is not deleted and not archived, show delete confirmation
                            newNotePage.showGeneralConfirmDialog(
                                qsTr("Do you want to move this note to trash?"),
                                function() {
                                    if (newNotePage.noteId !== -1) {
                                        DB.deleteNote(newNotePage.noteId); // Move to trash
                                        console.log(qsTr("Note ID: %1 moved to trash after confirmation.").arg(newNotePage.noteId));
                                        newNotePage.sentToTrash = true; // Mark that it was sent to trash
                                        toastManager.show(qsTr("Note moved to trash!"));
                                        if (onNoteSavedOrDeleted) {
                                            onNoteSavedOrDeleted(); // Refresh data on main page
                                        }
                                    } else {
                                        console.log(qsTr("New unsaved note discarded without deletion."));
                                    }
                                    pageStack.pop(); // Go back to the previous page after action
                                },
                                qsTr("Confirm Delete"),
                                qsTr("Delete"),
                                Theme.negativeColor
                            );
                        }
                    }
                }
            }
        }
    }

    // --- Main Content Flickable Area (Title, Content, Tags) ---
    SilicaFlickable {
        id: mainContentFlickable
        anchors.fill: parent
        anchors.topMargin: header.height
        // Adjust bottom margin based on keyboard visibility
        anchors.bottomMargin: bottomToolbar.height + (Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0)
        contentHeight: contentColumn.implicitHeight

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Column {
            id: contentColumn
            width: parent.width * 0.98 // Slightly less than full width for padding
            anchors.horizontalCenter: parent.horizontalCenter

            // Note Title Input
            TextField {
                id: noteTitleInput
                width: parent.width
                placeholderText: qsTr("Title")
                text: newNotePage.noteTitle
                // Set read-only based on the new property
                readOnly: newNotePage.isReadOnly
                onTextChanged: {
                    newNotePage.noteTitle = text;
                    newNotePage.noteModified = true;
                }
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
                font.bold: true
                wrapMode: Text.Wrap
                inputMethodHints: Qt.ImhNoAutoUppercase
                maximumLength: 256
            }

            // Note Content Input (TextArea)
            TextArea {
                id: noteContentInput
                width: parent.width
                height: implicitHeight > 0 ? implicitHeight : Theme.itemSizeExtraLarge * 3
                placeholderText: qsTr("Note")
                text: newNotePage.noteContent
                // Set read-only based on the new property
                readOnly: newNotePage.isReadOnly
                onTextChanged: {
                    // Update the noteContent property immediately
                    newNotePage.noteContent = text;
                    newNotePage.noteModified = true;
                    // The historySaveTimer is already running and will check for changes.
                    // No need to restart it here, as it's meant to save periodically.
                }
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                color: "#e8eaed"
                verticalAlignment: Text.AlignTop
            }

            // Flow layout for displaying selected tags
            Flow {
                id: tagsFlow
                width: parent.width
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.paddingMedium
                visible: newNotePage.noteTags.length > 0 // Only visible if tags exist
                Repeater {
                    model: newNotePage.noteTags // Model for tags - напрямую используем noteTags (массив)
                    delegate: Rectangle {
                        id: tagRectangle
                        property color normalColor: "#a032353a"
                        property color pressedColor: "#c050545a"
                        color: normalColor
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium, parent.width)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: tagText
                            text: modelData // modelData - это строка тега
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.centerIn: parent
                            elide: Text.ElideRight
                            width: parent.width - Theme.paddingMedium
                            wrapMode: Text.NoWrap
                            textFormat: Text.PlainText
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: true // Always enabled to allow showing dialog
                            onPressed: tagRectangle.color = tagRectangle.pressedColor
                            onReleased: {
                                tagRectangle.color = tagRectangle.normalColor
                                console.log(qsTr("Tag clicked for editing: %1").arg(modelData))
                                Qt.inputMethod.hide();
                                // Open tag selection panel when a tag is clicked
                                if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                                    if (tagSelectionPanel.opacity > 0.01) {
                                        tagSelectionPanel.opacity = 0;
                                    } else {
                                        tagSelectionPanel.opacity = 1;
                                    }
                                }
                            }
                            onCanceled: tagRectangle.color = tagRectangle.normalColor
                        }
                    }
                }
            }

            Item { width: parent.width; height: Theme.paddingLarge * 2 }
        }

        // Overlay MouseArea for handling interaction attempts in read-only mode for main content
        MouseArea {
            anchors.fill: contentColumn // Covers both title and content inputs
            visible: newNotePage.isReadOnly // Only active when in read-only mode
            onClicked: {
                handleInteractionAttempt(); // Call the handler to show the dialog
            }
        }


        Label {
            id: noTagsLabel
            text: qsTr("No tags")
            font.italic: true
            visible: newNotePage.noteTags.length === 0 && !newNotePage.isReadOnly // Show "No tags" only if no tags and not in read-only (where it might be misleading)
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: contentColumn.bottom
            MouseArea {
                anchors.fill: parent
                enabled: true // Always enabled to allow showing dialog
                onClicked: {
                    if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                        console.log(qsTr("Add Tag button clicked. Opening tag selection panel."));
                        // Toggle tag selection panel visibility
                        if (tagSelectionPanel.opacity > 0.01) {
                            tagSelectionPanel.opacity = 0;
                        } else {
                            tagSelectionPanel.opacity = 1;
                        }
                    }
                }
            }
        }
    }

    // --- Overlay for Color Selection Panel ---
    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: "#000000"
        visible: colorSelectionPanel.opacity > 0.01
        opacity: colorSelectionPanel.opacity * 0.4
        z: 10.5

        MouseArea {
            anchors.fill: parent
            enabled: overlayRect.visible // Enabled if overlay is visible
            onClicked: {
                if (colorSelectionPanel.opacity > 0.01) {
                    colorSelectionPanel.opacity = 0;
                }
            }
        }
    }

    // --- Color Selection Panel ---
    Rectangle {
        id: colorSelectionPanel
        width: parent.width
        property real panelRadius: Theme.itemSizeSmall / 2
        height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + panelRadius
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomToolbar.bottom
        z: 12
        opacity: 0
        visible: opacity > 0.01
        color: "transparent" // Outer rectangle is transparent, visual body inside has color
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: colorPanelVisualBody
            width: parent.width
            height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + 2 * colorSelectionPanel.panelRadius
            color: newNotePage.noteColor // Color panel's background matches current note color
            //radius: colorSelectionPanel.panelRadius // Consider if this should be here or on inner content
            y: 0

            Column {
                id: colorPanelContentColumn
                width: parent.width
                height: implicitHeight
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: colorSelectionPanel.panelRadius
                anchors.bottomMargin: Theme.paddingMedium
                spacing: Theme.paddingMedium

                Label {
                    id: colorTitle
                    text: qsTr("Select Note Color")
                    font.pixelSize: Theme.fontSizeLarge
                    color: "#e8eaed"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Flow {
                    id: colorFlow
                    width: parent.width
                    spacing: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: Qt.LeftToRight
                    readonly property int columns: 6
                    readonly property real itemWidth: (parent.width - (spacing * (columns - 1))) / columns

                    Repeater {
                        model: newNotePage.colorPalette
                        delegate: Item {
                            width: parent.itemWidth
                            height: parent.itemWidth

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: (newNotePage.noteColor === modelData) ? "white" : "#707070" // Outer ring for selected color
                                border.color: "transparent"
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.95
                                height: parent.height * 0.95
                                radius: width / 2
                                color: modelData // Actual color swatch
                                border.color: "transparent"

                                Rectangle {
                                    visible: newNotePage.noteColor === modelData // Checkmark for selected color
                                    anchors.centerIn: parent
                                    width: parent.width * 0.7
                                    height: parent.height * 0.7
                                    radius: width / 2
                                    color: modelData // Match swatch color

                                    Icon {
                                        source: "../icons/check.svg"
                                        anchors.centerIn: parent
                                        width: parent.width * 0.75
                                        height: parent.height * 0.75
                                        color: "white" // Checkmark color
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: true // Always enabled to allow showing dialog
                                onClicked: {
                                    if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                                        newNotePage.noteColor = modelData; // Set new note color
                                        newNotePage.noteModified = true;
                                        colorSelectionPanel.opacity = 0; // Close panel
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ScrollBar {
        flickableSource: mainContentFlickable
        topAnchorItem: header
    }

    // --- Overlay Rectangle for Tag Picker (Darkens background) ---
    Rectangle {
        id: tagOverlayRect
        anchors.fill: parent // Fills the entire parent area
        color: "#000000" // Black color
        // Visibility and opacity are linked to the 'tagSelectionPanel.opacity' state
        visible: tagSelectionPanel.opacity > 0.01 // Only visible when the tag picker is active
        opacity: tagSelectionPanel.opacity * 0.4 // Fades in and out
        z: 11.5 // Z-order to appear above other elements but below the picker itself

        // MouseArea to detect clicks on the overlay
        MouseArea {
            anchors.fill: parent
            enabled: tagOverlayRect.visible // Enabled if overlay is visible
            onClicked: {
                // If the tag picker is open, clicking the overlay closes it.
                if (tagSelectionPanel.opacity > 0.01) {
                    tagSelectionPanel.opacity = 0;
                    console.log(qsTr("Tag picker closed by clicking overlay."));
                }
            }
        }
    }

    // --- Main Tag Selection Panel ---
    // This is the core panel where tags are displayed and managed.
    Rectangle {
        property string currentNewTagInput: "" // ADD THIS LINE: To hold the text for the new tag input field

        id: tagSelectionPanel
        width: parent.width // Panel width matches parent
        height: parent.height * 0.53 // Fixed height as per the desired layout
        color: DB.darkenColor(newNotePage.noteColor, 0.15) // Darker version of note color
        radius: 15 // Rounded corners
        anchors.horizontalCenter: parent.horizontalCenter // Centers horizontally
        anchors.bottom: bottomToolbar.bottom // Anchors to the bottom of the parent (above keyboard)
        z: 12 // Z-order to appear above the overlay
        opacity: 0 // Initial opacity (hidden)
        visible: opacity > 0.01 // Ensures visibility for animation and content loading

        // Behavior for smooth opacity transitions
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Action to perform when the panel's visibility changes
        onVisibleChanged: {
            if (visible) {
                // When the panel becomes visible, load tags and scroll to the top of the list.
                loadTagsForTagPanel();
                tagsPanelFlickable.contentY = 0; // Scroll to top
                console.log(qsTr("Tag selection panel opened. Loading tags and scrolling to top."));
            }
        }

        // List model to hold available tags and their checked state
        ListModel {
            id: availableTagsModel
        }
        function performAddTagLogic() {
            // First, check if interaction is allowed (not in read-only state)
            if (!newNotePage.handleInteractionAttempt()) {
                // If handleInteractionAttempt showed a dialog, it means we can't proceed directly.
                // It will have handled the feedback.
                return;
            }

            var trimmedTag = tagSelectionPanel.currentNewTagInput.trim();
            if (trimmedTag === "") {
                if (toastManager) toastManager.show(qsTr("Tag name cannot be empty!"));
                // You could add a visual error state here if desired (e.g., newTagInput.color = Theme.errorColor)
                return;
            }

            // Get all existing tags to check for duplicates (case-sensitive)
            var existingTags = DB.getAllTagsWithCounts();
            var tagExists = existingTags.some(function(t) {
                return t.name === trimmedTag;
            });

            if (tagExists) {
                console.log(qsTr("Error: Tag '%1' already exists.").arg(trimmedTag));
                if (toastManager) toastManager.show(qsTr("Tag '%1' already exists!").arg(trimmedTag));
            } else {
                // Add the new tag to the database
                DB.addTag(trimmedTag);
                console.log(qsTr("New tag '%1' added to DB.").arg(trimmedTag));

                // Add the newly created tag to the current note's tags immediately
                // This ensures it appears selected in the list right away.
                var updatedNoteTags = Array.isArray(newNotePage.noteTags) ? newNotePage.noteTags.slice() : [];
                if (updatedNoteTags.indexOf(trimmedTag) === -1) {
                    updatedNoteTags.push(trimmedTag);
                    newNotePage.noteTags = updatedNoteTags; // Assign new array instance to trigger updates
                    newNotePage.noteModified = true; // Mark the note as modified
                    console.log(qsTr("Tag '%1' also added to current note's tags.").arg(trimmedTag));
                }

                tagSelectionPanel.currentNewTagInput = ""; // Clear the input field
                newTagInput.forceActiveFocus(false); // Hide the keyboard

                // Refresh the list model to show the newly added tag in the list view
                loadTagsForTagPanel();

                if (toastManager) toastManager.show(qsTr("Tag '%1' created and added!").arg(trimmedTag));
            }
        }

        // Function to load tags into the ListModel for the current note
        function loadTagsForTagPanel() {
            availableTagsModel.clear(); // Clear existing items
            var allTags = DB.getAllTags(); // Get all available tags from the database (assuming DB is globally accessible)

            // Always use newNotePage.noteTags for determining selected tags
            // as it should now be up-to-date (an array).
            var currentNoteTags = Array.isArray(newNotePage.noteTags) ? newNotePage.noteTags.slice() : [];

            var selectedTags = [];
            var unselectedTags = [];

            // Populate separate arrays for selected and unselected tags
            for (var i = 0; i < allTags.length; i++) {
                var tagName = allTags[i];
                var isChecked = currentNoteTags.indexOf(tagName) !== -1; // Check for presence in the current note's tags
                if (isChecked) {
                    selectedTags.push({ name: tagName, isChecked: true });
                } else {
                    unselectedTags.push({ name: tagName, isChecked: false });
                }
            }

            // Append selected tags first, then unselected tags, to the model
            for (var i = 0; i < selectedTags.length; i++) {
                availableTagsModel.append(selectedTags[i]);
            }
            for (var i = 0; i < unselectedTags.length; i++) {
                availableTagsModel.append(unselectedTags[i]);
            }

            console.log(qsTr("TagSelectionPanel: Loaded tags for display in panel. Model items: %1").arg(availableTagsModel.count));
        }

        // Column layout for header, flickable content, and done button
        Column {
            id: tagPanelContentColumn
            anchors.fill: parent
            spacing: Theme.paddingMedium // Spacing between items in the column

            // --- Header Section for Tag Panel ---
            Rectangle {
                id: tagPanelHeader
                width: parent.width
                height: Theme.itemSizeMedium // Standard header height
                // Color now dynamically darkened version of note's color
                color: DB.darkenColor(newNotePage.noteColor, 0.15) // Darker version of note color
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.leftMargin: Theme.paddingLarge // Horizontal padding for content within header
                anchors.rightMargin: Theme.paddingLarge

            }
            // Input for new tag creation - CHANGED TO TextField
            SearchField {
                id: newTagInput
                width: parent.width * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: tagPanelHeader.verticalCenter
                placeholderText: qsTr("Add new tag...")
                font.pixelSize: Theme.fontSizeMedium
                highlighted: false
                color: Theme.primaryColor
                readOnly: newNotePage.isReadOnly // Inherit read-only state

                // ADD/MODIFY THESE LINES:
                text: tagSelectionPanel.currentNewTagInput // Bind text to the new property
                onTextChanged: tagSelectionPanel.currentNewTagInput = text // Update property on text change

                // Add functionality for Enter key press
                EnterKey.onClicked: {
                    tagSelectionPanel.performAddTagLogic(); // Call the new function to add the tag
                }

                // Add a right-hand item for the "Add" button (check/plus icon)
                rightItem: Item {
                    id: addTagButtonContainer
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 1.1
                    clip: false

                    // Opacity depends on whether there's text in the input
                    opacity: tagSelectionPanel.currentNewTagInput.trim().length > 0 && !newNotePage.isReadOnly ? 1 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Icon {
                        id: addTagPanelIcon
                        // Show check icon if there's text, otherwise show plus icon
                        source: tagSelectionPanel.currentNewTagInput.trim().length > 0 ? "../icons/plus.svg" : "../icons/plus.svg"
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        color: Theme.primaryColor // Keep icon color consistent
                    }
                    RippleEffect { id: addTagRippleEffect }
                    MouseArea {
                        anchors.fill: parent
                        // Only enabled if there's text and not in read-only mode
                        enabled: tagSelectionPanel.currentNewTagInput.trim().length > 0 && !newNotePage.isReadOnly
                        onPressed: addTagRippleEffect.ripple(mouseX, mouseY)
                        onClicked: {
                            tagSelectionPanel.performAddTagLogic(); // Call the new function to add the tag
                        }
                    }
                }
               leftItem: Item {}
            }


            // --- Flickable Area for Tag List ---
            // Allows scrolling if the list of tags exceeds the panel height.
            SilicaFlickable {
                id: tagsPanelFlickable
                width: parent.width
                anchors.top: newTagInput.bottom // Anchored below the new tag input
                anchors.bottom: doneButton.top // Anchored above the Done button
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Theme.paddingMedium // Space from new tag input
                anchors.bottomMargin: Theme.paddingMedium // Space from done button
                contentHeight: tagsPanelListView.contentHeight // Content height dynamically set by ListView
                clip: true // Clips content that overflows

                // --- List View for Individual Tags ---
                ListView {
                    id: tagsPanelListView
                    width: parent.width
                    height: contentHeight // Height adapts to content
                    model: availableTagsModel // Uses the ListModel defined above
                    orientation: ListView.Vertical // Vertical scrolling
                    spacing: Theme.paddingSmall // Spacing between list items

                    // Delegate defines how each item in the ListView looks and behaves
                    delegate: Rectangle { // Using Rectangle for delegate as per the desired style
                        id: tagPanelDelegateRoot
                        width: parent.width
                        height: Theme.itemSizeMedium // Standard item height
                        clip: true
                        // Dynamic background color based on checked state
                        // Selected tag uses the note's color, unselected uses a standard darker shade
                        color: model.isChecked ? DB.darkenColor(newNotePage.noteColor, -0.25) : DB.darkenColor(newNotePage.noteColor, 0.25) // New styling colors

                        // Ripple effect for visual feedback on touch/click
                        RippleEffect { id: tagPanelDelegateRipple }

                        // MouseArea for handling clicks on each tag item
                        MouseArea {
                            anchors.fill: parent
                            enabled: true // Always enabled to allow showing dialog
                            onPressed: tagPanelDelegateRipple.ripple(mouseX, mouseY) // Trigger ripple on press
                            onClicked: {
                                if (handleInteractionAttempt()) { // Check read-only state and show dialog if needed
                                    var newCheckedState = !model.isChecked; // Toggle checked state

                                    // Update the model for immediate UI reflection
                                    availableTagsModel.set(index, { name: model.name, isChecked: newCheckedState });

                                    // Logic to update newNotePage.noteTags
                                    var currentNoteTagsCopy = Array.isArray(newNotePage.noteTags) ? newNotePage.noteTags.slice() : [];

                                    if (newCheckedState) {
                                        // Add tag if it's checked and not already in the array
                                        if (currentNoteTagsCopy.indexOf(model.name) === -1) {
                                            currentNoteTagsCopy.push(model.name);
                                        }
                                    } else {
                                        // Remove tag if it's unchecked
                                        currentNoteTagsCopy = currentNoteTagsCopy.filter(function(tag) {
                                            return tag !== model.name;
                                        });
                                    }
                                    newNotePage.noteTags = currentNoteTagsCopy; // Assign the new array instance

                                    // Update the database if it's an existing note
                                    if (newNotePage.noteId !== -1) {
                                        if (newCheckedState) {
                                            DB.addTagToNote(newNotePage.noteId, model.name);
                                            console.log(qsTr("Added tag '%1' to note ID %2").arg(model.name).arg(newNotePage.noteId));
                                        } else {
                                            DB.deleteTagFromNote(newNotePage.noteId, model.name);
                                            console.log(qsTr("Removed tag '%1' from note ID %2").arg(model.name).arg(newNotePage.noteId));
                                        }
                                    }

                                    newNotePage.noteModified = true; // Mark note as modified
                                    console.log(qsTr("Note's tags updated: %1").arg(JSON.stringify(newNotePage.noteTags)));
                                }
                            }
                        }

                        // Row layout for icon, tag name, and checkbox
                        Row {
                            id: tagPanelRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge // Left padding
                            anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge // Right padding
                            spacing: Theme.paddingMedium // Spacing between elements in the row

                            // Tag icon
                            Icon {
                                id: tagPanelTagIcon
                                source: "../icons/tag-white.svg" // Path to tag icon
                                color: "#e2e3e8" // Icon color
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                // Icon component typically handles fillMode and color tinting for SVGs
                            }

                            // Label for the tag name
                            Label {
                                id: tagPanelTagNameLabel
                                text: model.name // Display tag name from model
                                color: "#e2e3e8" // Text color
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight // Elide long text with "..."
                                // Flexible width, positioned between icon and checkbox
                                anchors.left: tagPanelTagIcon.right
                                anchors.leftMargin: tagPanelRow.spacing
                                anchors.right: tagPanelCheckButtonContainer.left
                                anchors.rightMargin: tagPanelRow.spacing
                            }

                            // Container for the checkbox icon
                            Item {
                                id: tagPanelCheckButtonContainer
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right // Anchored to the far right of the row
                                clip: false

                                // Checkbox icon (changes based on model.isChecked)
                                Image { // Changed from Icon to Image for flexibility, if Icon causes issues for dynamic source
                                    id: tagPanelCheckIcon
                                    source: model.isChecked ? "../icons/box-checked.svg" : "../icons/box.svg" // Checked or unchecked box icon
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                        }
                    }
                }
            }
            // Scrollbar for the flickable area
            ScrollBar {
                flickableSource: tagsPanelFlickable
                anchors.top: tagsPanelFlickable.top
                anchors.bottom: tagsPanelFlickable.bottom
                anchors.right: parent.right
                width: Theme.paddingSmall
            }

            // --- Done Button for Tag Panel ---
            Button {
                id: doneButton
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Done") // Localized text for the button
                onClicked: {
                    tagSelectionPanel.opacity = 0; // Close the tag picker when Done is clicked
                    // No need to explicitly re-sync noteTags here, as it's updated on each click within the delegate
                    // Ensure the note is marked as modified if any tag changes happened
                    newNotePage.noteModified = true;
                    console.log(qsTr("Tag picker closed by Done button."));
                }
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge // Space from the bottom of the panel
            }
        }
    }

    // --- Integrated Generic Confirmation Dialog Component ---
    ConfirmDialog {
        id: generalConfirmDialog
        // Bind properties from newNotePage to ConfirmDialog
        dialogVisible: newNotePage.confirmDialogVisible
        dialogTitle: newNotePage.confirmDialogTitle
        dialogMessage: newNotePage.confirmDialogMessage
        confirmButtonText: newNotePage.confirmButtonText
        confirmButtonHighlightColor: newNotePage.confirmButtonHighlightColor
        // Pass the dynamically darkened note color for the dialog background
        dialogBackgroundColor: DB.darkenColor(newNotePage.noteColor, 0.15)

        // Connect signals from ConfirmDialog back to newNotePage's logic
        onConfirmed: {
            if (newNotePage.onConfirmCallback) {
                newNotePage.onConfirmCallback(); // Execute the stored callback
            }
            newNotePage.confirmDialogVisible = false; // Hide the dialog after confirmation
        }
        onCancelled: {
            newNotePage.confirmDialogVisible = false; // Hide the dialog
            console.log(qsTr("Action cancelled by user."));
            // Special handling for actionRequiredDialog cancellation:
            // Re-set isReadOnly to true if it was a read-only note and user cancelled restore/unarchive
            // This ensures inputs remain disabled if user cancels restore/unarchive
            if (newNotePage.isArchived || newNotePage.isDeleted) {
                newNotePage.isReadOnly = true;
            }
        }
    }
}

// ArchivePage.qml
// This page displays either archived motes,
// It provides functionality
// for selecting notes, restoring/unarchiving them, and permanently deleting them.

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB // Import JavaScript for database operations

Page {
    id: archivePage
    objectName: "archivePage" // Used for easier pageStack checks in SidePanel
    backgroundColor: archivePage.customBackgroundColor !== undefined ? archivePage.customBackgroundColor : "#121218"

    // Property to hold the currently selected custom background color, loaded from DB
    property string customBackgroundColor: DB.getThemeColor() || "#121218"
    showNavigationIndicator: false // Hides the default navigation indicator
    property int noteMargin: 20 // Margin for individual note cards

    // Determines if the page displays "archive" or "trash" content. Translated for consistency.
    property string pageMode: qsTr("archive")
    property var notesToDisplay: [] // List of notes fetched from the database
    property var selectedNoteIds: [] // IDs of currently selected notes for bulk actions
    property bool panelOpen: false // Controls the visibility of the SidePanel

    // Properties to control the confirmation dialog, passed to the ConfirmDialog component
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Deletion") // Default title for confirmation dialog
    property string confirmDialogMessage: "" // Message displayed in the confirmation dialog
    property string confirmButtonText: qsTr("Delete") // Text for the confirm button
    property var onConfirmCallback: null // Function to execute when the dialog is confirmed
    property color confirmButtonHighlightColor: Theme.errorColor // Highlight color for the confirm button

    // Helper properties for UI visibility based on data state
    property bool showEmptyLabel: notesToDisplay.length === 0 // Controls visibility of "Empty" message
    property bool selectionControlsVisible: notesToDisplay.length > 0 // Controls visibility of bulk action buttons

    // Helper property to determine if all notes are selected, for "Select All" button state
    property bool allNotesSelected: (selectedNoteIds.length === notesToDisplay.length) && (notesToDisplay.length > 0)


    Component.onCompleted: {
        // Called when the page is fully loaded and ready
        console.log(qsTr("UNIFIED_NOTES_PAGE: archivePage opened in %1 mode. Calling refreshNotes.").arg(pageMode));
        refreshNotes(); // Initial data load
        sidePanelInstance.currentPage = pageMode; // Inform the SidePanel about the current page mode
    }

    // Function to refresh the list of notes based on the current page mode
    function refreshNotes() {
        if (pageMode === qsTr("trash")) {
            notesToDisplay = DB.getDeletedNotes();
            console.log(qsTr("DB_MGR: getDeletedNotes found %1 deleted notes.").arg(notesToDisplay.length));
        } else if (pageMode === qsTr("archive")) {
            notesToDisplay = DB.getArchivedNotes();
            console.log(qsTr("DB_MGR: getArchivedNotes found %1 archived notes.").arg(notesToDisplay.length));
        }
        selectedNoteIds = []; // Clear selected notes whenever notes are refreshed
        console.log(qsTr("UNIFIED_NOTES_PAGE: refreshNotes completed for %1. Count: %2").arg(pageMode).arg(notesToDisplay.length));
    }

    // Function to display the confirmation dialog with dynamic content and callback
    function showConfirmDialog(message, callback, title, buttonText, highlightColor) {
        confirmDialogMessage = message;
        onConfirmCallback = callback;
        if (title !== undefined) confirmDialogTitle = title;
        else confirmDialogTitle = qsTr("Confirm Deletion"); // Reset to default if not provided

        if (buttonText !== undefined) confirmButtonText = buttonText;
        else confirmButtonText = qsTr("Delete"); // Reset to default if not provided

        if (highlightColor !== undefined) confirmButtonHighlightColor = highlightColor;
        else confirmButtonHighlightColor = Theme.errorColor; // Reset to default if not provided

        confirmDialogVisible = true; // Make the dialog visible
    }

    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge // Standard header height

        // Menu/Close button on the left of the header
        Item {
            id: menuButton
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 0.95
            clip: false
            anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }

            RippleEffect { id: menuRipple } // Visual feedback on button press

            // Dynamic Icon: "close" when notes are selected, "menu" otherwise
            Icon {
                id: leftIcon
                source: archivePage.selectedNoteIds.length > 0 ? "../icons/close.svg" : "../icons/menu.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor // Consistent primary color for the icon
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY)
                onClicked: {
                    // If notes are selected, clicking clears selection; otherwise, it opens the side panel.
                    if (archivePage.selectedNoteIds.length > 0) {
                        archivePage.selectedNoteIds = []; // Clear selected notes
                        console.log(qsTr("Selected notes cleared in archivePage."));
                    } else {
                        archivePage.panelOpen = true // Open the side panel
                        console.log(qsTr("Menu button clicked in archivePage → panelOpen = true"))
                    }
                }
            }
        }

        // Page title in the center of the header
        Label {
            text: pageMode === qsTr("trash") ? qsTr("Trash") : qsTr("Archive") // Translated title based on pageMode
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: pageHeader.height // Positions mainLayout below the header
        spacing: 0

        // Row containing the selection control buttons (Select All, Restore/Unarchive, Delete)
        Row {
            id: selectionControls
            Layout.fillWidth: true
            // Adjust height based on visibility, providing a smooth transition
            height: selectionControlsVisible ? Theme.buttonHeightSmall + Theme.paddingSmall : 0
            visible: selectionControlsVisible // Only visible when there are notes to select
            spacing: Theme.paddingSmall // Spacing between buttons

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: archivePage.noteMargin
            anchors.rightMargin: archivePage.noteMargin

            // Calculate button width to consistently fit buttons
            property real calculatedButtonWidth: (archivePage.width) / 2.13

            // "Select All / Deselect All" Button
            Button {
                id: selectAllButton
                width: parent.calculatedButtonWidth // Use calculated width for responsiveness
                highlightColor: Theme.highlightColor // Standard highlight color

                // Column to stack Icon and Label for consistent button styling
                Column {
                    anchors.centerIn: parent

                    Item { // Wrapper for the Icon to control size and centering
                        width: Theme.fontSizeExtraLarge * 0.9 // Adjusted size for icons in buttons
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Icon changes based on whether all notes are selected
                        Icon {
                            source: archivePage.allNotesSelected ? "../icons/deselect_all.svg" : "../icons/select_all.svg"
                            anchors.fill: parent
                            color: Theme.primaryColor // Match menu icon color style
                        }
                    }
                    Label {
                        text: qsTr("Select") // Always "Select" as it toggles
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    var newSelectedIds = [];
                    // If not all notes are selected, select all; otherwise, deselect all.
                    if (!archivePage.allNotesSelected) {
                        for (var i = 0; i < archivePage.notesToDisplay.length; i++) {
                            newSelectedIds.push(archivePage.notesToDisplay[i].id);
                        }
                    }
                    archivePage.selectedNoteIds = newSelectedIds; // Update the list of selected IDs
                    console.log(qsTr("Selected note IDs after Select All/Deselect All: %1").arg(JSON.stringify(archivePage.selectedNoteIds)));
                }
                enabled: notesToDisplay.length > 0 // Button enabled only if there are notes to select
            }

            // Primary Action Button (Restore for Trash, Unarchive for Archive)
            Button {
                id: primaryActionButton
                width: parent.calculatedButtonWidth
                highlightColor: Theme.highlightColor

                Column {
                    anchors.centerIn: parent

                    Item {
                        width: Theme.fontSizeExtraLarge * 0.9
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Icon changes based on page mode (Restore or Unarchive)
                        Icon {
                            source: pageMode === qsTr("trash") ? "../icons/restore_notes.svg" : "../icons/unarchive.svg"
                            anchors.fill: parent
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        // Text changes based on page mode (Restore or Unarchive)
                        text: pageMode === qsTr("trash") ? qsTr("Restore") : qsTr("Unarchive")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    // Only proceed if notes are selected
                    if (selectedNoteIds.length > 0) {
                        var message = "";
                        var confirmTitle = "";
                        var confirmButton = "";
                        var highlight = Theme.highlightColor;
                        var callbackFunction;

                        // Set dialog content and callback based on page mode
                        if (pageMode === qsTr("trash")) {
                            message = qsTr("Are you sure you want to restore %1 selected notes to your main notes?").arg(selectedNoteIds.length);
                            confirmTitle = qsTr("Confirm Restoration");
                            confirmButton = qsTr("Restore");
                            callbackFunction = function() {
                                var restoredCount = selectedNoteIds.length;
                                DB.restoreNotes(selectedNoteIds); // Database call to restore notes
                                refreshNotes(); // Refresh the list after action
                                toastManager.show(qsTr("%1 note(s) restored!").arg(restoredCount)); // Show toast notification
                                console.log(qsTr("%1 note(s) restored from trash.").arg(restoredCount));
                            };
                        } else if (pageMode === qsTr("archive")) {
                            message = qsTr("Are you sure you want to unarchive %1 selected notes?").arg(selectedNoteIds.length);
                            confirmTitle = qsTr("Confirm Unarchive");
                            confirmButton = qsTr("Unarchive");
                            callbackFunction = function() {
                                var unarchivedCount = selectedNoteIds.length;
                                DB.bulkUnarchiveNotes(selectedNoteIds); // Database call to unarchive notes
                                refreshNotes();
                                toastManager.show(qsTr("%1 note(s) unarchived!").arg(unarchivedCount));
                                console.log(qsTr("%1 note(s) unarchived.").arg(unarchivedCount));
                            };
                        }

                        // Show the generic confirmation dialog with specific content
                        archivePage.showConfirmDialog(
                            message,
                            callbackFunction,
                            confirmTitle,
                            confirmButton,
                            highlight
                        );
                        console.log(qsTr("Showing confirmation dialog for %1 notes in %2 mode.").arg(selectedNoteIds.length).arg(pageMode));
                    }
                }
                enabled: selectedNoteIds.length > 0 // Button enabled only if notes are selected
            }

            // Permanently Delete Button (only visible in "trash" mode)
            Button {
                id: deleteSelectedButton
                visible: archivePage.pageMode === qsTr("trash") // Only shown in trash mode
                width: parent.calculatedButtonWidth
                highlightColor: Theme.errorColor // Error color for destructive action

                Column {
                    anchors.centerIn: parent

                    Item {
                        width: Theme.fontSizeExtraLarge * 0.9
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/delete.svg"
                            anchors.fill: parent
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: qsTr("Delete") // Text for permanent deletion
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        var message = qsTr("Are you sure you want to permanently delete %1 selected notes? This action cannot be undone.").arg(selectedNoteIds.length);
                        // Show confirmation dialog for permanent deletion
                        archivePage.showConfirmDialog(
                            message,
                            function() {
                                var deletedCount = selectedNoteIds.length;
                                DB.permanentlyDeleteNotes(selectedNoteIds); // Database call to permanently delete
                                refreshNotes(); // Refresh the list
                                toastManager.show(qsTr("%1 note(s) permanently deleted!").arg(deletedCount));
                                console.log(qsTr("%1 note(s) permanently deleted.").arg(deletedCount));
                            },
                            qsTr("Confirm Permanent Deletion"), // Specific title for permanent delete
                            qsTr("Delete Permanently"), // Specific button text
                            Theme.errorColor // Red highlight for warning
                        );
                        console.log(qsTr("Showing permanent delete confirmation dialog for %1 notes.").arg(selectedNoteIds.length));
                    }
                }
                enabled: selectedNoteIds.length > 0 // Enabled only if notes are selected
            }
        }

        // Spacer to provide vertical separation when selection controls are visible
        Item {
            id: selectionSpacer
            Layout.fillWidth: true
            Layout.preferredHeight: selectionControlsVisible ? Theme.paddingMedium : 0
            visible: selectionControlsVisible
        }

        // Flickable area to display the list of notes
        SilicaFlickable {
            id: notesFlickable
            Layout.fillWidth: true
            // Calculates height to fill remaining space after header and selection controls
            Layout.preferredHeight: parent.height
                                  - selectionControls.height
                                  - selectionSpacer.height
            contentHeight: notesColumn.implicitHeight // Adapts content height to actual notes column height
            clip: true // Ensures content doesn't overflow flickable bounds

            // Column to arrange individual note cards
            Column {
                id: notesColumn
                width: parent.width
                spacing: Theme.paddingMedium // Spacing between note cards
                visible: !archivePage.showEmptyLabel // Hides if there are no notes
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium

                // Repeater to create a TrashArchiveNoteCard for each note in notesToDisplay
                Repeater {
                    model: notesToDisplay
                    delegate: Column { // Each delegate is wrapped in a Column for consistent spacing
                        width: parent.width
                        spacing: Theme.paddingLarge

                        TrashArchiveNoteCard {
                            id: noteCardInstance
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: archivePage.noteMargin
                                rightMargin: archivePage.noteMargin
                            }
                            width: parent.width - (Theme.paddingMedium * 2) // Adjust width for margins
                            noteId: modelData.id
                            title: modelData.title
                            content: modelData.content
                            // Tags are joined for passing as a single string, then parsed back in the card
                            tags: modelData.tags ? modelData.tags.join("_||_") : ''
                            cardColor: modelData.color || "#1c1d29" // Default card color if not specified
                            height: implicitHeight // Allows card to determine its own height based on content
                            // Checks if the current note ID is in the selectedNoteIds array
                            isSelected: archivePage.selectedNoteIds.indexOf(modelData.id) !== -1
                            selectedBorderColor: noteCardInstance.isSelected ? "#FFFFFF" : "#00000000" // White border when selected
                            selectedBorderWidth: noteCardInstance.isSelected ? Theme.borderWidthSmall : 0 // Border width when selected

                            // Callback for when a note's selection state is toggled
                            onSelectionToggled: {
                                if (isCurrentlySelected) {
                                    // Remove note from selection if it was selected
                                    var index = archivePage.selectedNoteIds.indexOf(noteId);
                                    if (index !== -1) {
                                        archivePage.selectedNoteIds.splice(index, 1);
                                    }
                                } else {
                                    // Add note to selection if it was not selected
                                    if (archivePage.selectedNoteIds.indexOf(noteId) === -1) {
                                        archivePage.selectedNoteIds.push(noteId);
                                    }
                                }
                                // Reassign to trigger property change and UI update
                                archivePage.selectedNoteIds = archivePage.selectedNoteIds;
                                console.log(qsTr("Toggled selection for note ID: %1. Current selected: %2").arg(noteId).arg(JSON.stringify(archivePage.selectedNoteIds)));
                            }

                            // Callback for when a note card is clicked (to open NotePage)
                            onNoteClicked: {
                                console.log(qsTr("UNIFIED_NOTES_PAGE: Opening NotePage for note ID: %1 from %2.").arg(noteId).arg(archivePage.pageMode));
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: archivePage.refreshNotes, // Callback to refresh notes after editing/deleting
                                    noteId: noteId,
                                    noteTitle: title,
                                    noteContent: content,
                                    noteIsPinned: isPinned,
                                    noteTags: tags,
                                    noteCreationDate: creationDate,
                                    noteEditDate: editDate,
                                    noteColor: color,
                                    isArchived: archivePage.pageMode === qsTr("archive"), // Pass current archive state
                                    isDeleted: archivePage.pageMode === qsTr("trash") // Pass current deleted state
                                });
                            }
                        }
                    }
                }
            }
        }
        // Scroll bar for the flickable area
        ScrollBar {
            flickableSource: notesFlickable
        }
    }

    // ToastManager for displaying transient messages
    ToastManager {
        id: toastManager
    }

    // Confirmation Dialog component
    ConfirmDialog {
        id: confirmDialogInstance
        // Bind properties from archivePage to ConfirmDialog to control its behavior
        dialogVisible: archivePage.confirmDialogVisible
        dialogTitle: archivePage.confirmDialogTitle
        dialogMessage: archivePage.confirmDialogMessage
        confirmButtonText: archivePage.confirmButtonText
        confirmButtonHighlightColor: archivePage.confirmButtonHighlightColor

        // Handle signals from ConfirmDialog back to archivePage's logic
        onConfirmed: {
            if (archivePage.onConfirmCallback) {
                archivePage.onConfirmCallback(); // Execute the stored callback function
            }
            archivePage.confirmDialogVisible = false; // Hide the dialog after confirmation
        }
        onCancelled: {
            archivePage.confirmDialogVisible = false; // Hide the dialog if cancelled
            console.log(qsTr("Action cancelled by user."));
        }
    }
    // Label displayed when the notes list is empty
    Label {
        id: emptyLabel
        visible: archivePage.showEmptyLabel
        text: pageMode === qsTr("trash") ? qsTr("Trash is empty.") : qsTr("Archive is empty.") // Translated empty message
        font.italic: true
        color: Theme.secondaryColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.8
        horizontalAlignment: Text.AlignHCenter
    }
    // Side panel component
    SidePanel {
        id: sidePanelInstance
        open: archivePage.panelOpen // Controls if the panel is open
        onClosed: archivePage.panelOpen = false // Update page property when panel is closed
    }
}

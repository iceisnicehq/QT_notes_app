// ArchivePage.qml

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB

Page {
    id: archivePage
    objectName: "archivePage" // Added objectName for easier pageStack checks in SidePanel
    backgroundColor: archivePage.customBackgroundColor !== undefined ? archivePage.customBackgroundColor : "#121218" // Fallback to Theme.backgroundColor if custom is not set

    // Property to hold the currently selected custom background color
    property string customBackgroundColor: DB.getThemeColor() || "#121218" // Load from DB, default to a dark color if not found    showNavigationIndicator: false
    showNavigationIndicator: false
    property int noteMargin: 20

    property string pageMode: qsTr("archive") // Can be "archive" or "trash" // Added qsTr
    // NOTE: 'pageMode' is used internally for logic ("trash" vs "archive"), but if its *value* is ever displayed, it should be translated.
    // For now, I'll assume the displayed strings "Trash" and "Archive" in the Label below are sufficient.
    // If 'pageMode' itself needs translation for display elsewhere, it should be changed.

    property var notesToDisplay: []
    property var selectedNoteIds: []
    property bool panelOpen: false // Property to control side panel visibility

    // Properties to control the dialog from the page's logic (These will now be passed to the component)
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Deletion") // Default title
    property string confirmDialogMessage: "" // Message for the dialog
    property string confirmButtonText: qsTr("Delete") // Default button text
    property var onConfirmCallback: null // Callback function to execute on confirm
    property color confirmButtonHighlightColor: Theme.errorColor // Default highlight color for confirm button

    property bool showEmptyLabel: notesToDisplay.length === 0
    property bool selectionControlsVisible: notesToDisplay.length > 0

    // Helper property to determine if all notes are selected
    property bool allNotesSelected: (selectedNoteIds.length === notesToDisplay.length) && (notesToDisplay.length > 0)


    Component.onCompleted: {
        console.log(qsTr("UNIFIED_NOTES_PAGE: archivePage opened in %1 mode. Calling refreshNotes.").arg(pageMode));
        refreshNotes();
        // Set the current page for the side panel instance
        sidePanelInstance.currentPage = pageMode; // Use pageMode to set current page
    }

    function refreshNotes() {
        if (pageMode === qsTr("trash")) { // Added qsTr
            notesToDisplay = DB.getDeletedNotes();
            console.log(qsTr("DB_MGR: getDeletedNotes found %1 deleted notes.").arg(notesToDisplay.length));
        } else if (pageMode === qsTr("archive")) { // Added qsTr
            notesToDisplay = DB.getArchivedNotes();
            console.log(qsTr("DB_MGR: getArchivedNotes found %1 archived notes.").arg(notesToDisplay.length));
        }
        selectedNoteIds = [];
        console.log(qsTr("UNIFIED_NOTES_PAGE: refreshNotes completed for %1. Count: %2").arg(pageMode).arg(notesToDisplay.length));
    }

    // Function to show the confirmation dialog dynamically
    function showConfirmDialog(message, callback, title, buttonText, highlightColor) {
        confirmDialogMessage = message; // Set the message for the dialog
        onConfirmCallback = callback;   // Set the callback function
        if (title !== undefined) confirmDialogTitle = title; // Override default title if provided
        else confirmDialogTitle = qsTr("Confirm Deletion"); // Reset to default if not provided

        if (buttonText !== undefined) confirmButtonText = buttonText; // Override default button text if provided
        else confirmButtonText = qsTr("Delete"); // Reset to default if not provided

        if (highlightColor !== undefined) confirmButtonHighlightColor = highlightColor; // Override default highlight color
        else confirmButtonHighlightColor = Theme.errorColor; // Reset to default if not provided

        confirmDialogVisible = true; // Make the dialog visible
    }

    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        // Modified: Menu icon button to match the dynamic style from TrashPage
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

            RippleEffect { id: menuRipple }

            // Dynamic Icon based on selection state, styled like the menu button's icon
            Icon {
                id: leftIcon // Renamed for clarity
                source: archivePage.selectedNoteIds.length > 0 ? "../icons/close.svg" : "../icons/menu.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor // Ensured primary color for consistency
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY) // Keep ripple effect
                onClicked: {
                    // Logic adjusted for archivePage context
                    if (archivePage.selectedNoteIds.length > 0) {
                        archivePage.selectedNoteIds = []; // Clear selected notes
                        console.log(qsTr("Selected notes cleared in archivePage.")); // Added qsTr
                    } else {
                        archivePage.panelOpen = true // Open the side panel
                        console.log(qsTr("Menu button clicked in archivePage → panelOpen = true")) // Added qsTr
                    }
                }
            }
        }

        Label {
            text: pageMode === qsTr("trash") ? qsTr("Trash") : qsTr("Archive") // Ensured both values are translated
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: pageHeader.height // This anchors mainLayout below the header
        spacing: 0

        Row {
            id: selectionControls
            Layout.fillWidth: true
            height: selectionControlsVisible ? Theme.buttonHeightSmall + Theme.paddingSmall : 0
            visible: selectionControlsVisible
            spacing: Theme.paddingSmall // This spacing applies between buttons

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: archivePage.noteMargin
            anchors.rightMargin: archivePage.noteMargin

            // Changed: Calculate button width to consistently fit three buttons, matching TrashPage
            property real calculatedButtonWidth: (archivePage.width) / 2.13

            // "Select All / Deselect All" Button
            Button {
                id: selectAllButton
                width: parent.calculatedButtonWidth // Use calculated width
                highlightColor: Theme.highlightColor

                // NEW: Inner Column to stack Icon and Label for consistent styling
                Column {
                    anchors.centerIn: parent

                    Item { // Wrapper Item for the Icon to control its precise size and centering
                        width: Theme.fontSizeExtraLarge * 0.9 // Adjusted size for icons in buttons
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: archivePage.allNotesSelected ? "../icons/deselect_all.svg" : "../icons/select_all.svg"
                            anchors.fill: parent // Icon fills its wrapper Item
                            color: Theme.primaryColor // Match menu icon color style
                        }
                    }
                    Label {
                        text: qsTr("Select")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter // Center text
                    }
                }
                onClicked: {
                    var newSelectedIds = [];
                    if (!archivePage.allNotesSelected) {
                        for (var i = 0; i < archivePage.notesToDisplay.length; i++) {
                            newSelectedIds.push(archivePage.notesToDisplay[i].id);
                        }
                    }
                    archivePage.selectedNoteIds = newSelectedIds;
                    console.log(qsTr("Selected note IDs after Select All/Deselect All: %1").arg(JSON.stringify(archivePage.selectedNoteIds)));
                }
                enabled: notesToDisplay.length > 0
            }

            Button {
                id: primaryActionButton
                width: parent.calculatedButtonWidth // Use calculated width
                highlightColor: Theme.highlightColor

                // NEW: Inner Column to stack Icon and Label for consistent styling
                Column {
                    anchors.centerIn: parent

                    Item { // Wrapper Item for the Icon to control its precise size and centering
                        width: Theme.fontSizeExtraLarge * 0.9 // Adjusted size for icons in buttons
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: pageMode === qsTr("trash") ? "../icons/restore_notes.svg" : "../icons/unarchive.svg" // Added qsTr
                            anchors.fill: parent // Icon fills its wrapper Item
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: pageMode === qsTr("trash") ? qsTr("Restore") : qsTr("Unarchive") // Added qsTr
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        var message = "";
                        var confirmTitle = "";
                        var confirmButton = "";
                        var highlight = Theme.highlightColor;
                        var callbackFunction;

                        if (pageMode === qsTr("trash")) { // Added qsTr
                            message = qsTr("Are you sure you want to restore %1 selected notes to your main notes?").arg(selectedNoteIds.length);
                            confirmTitle = qsTr("Confirm Restoration");
                            confirmButton = qsTr("Restore");
                            callbackFunction = function() {
                                var restoredCount = selectedNoteIds.length;
                                DB.restoreNotes(selectedNoteIds);
                                refreshNotes();
                                toastManager.show(qsTr("%1 note(s) restored!").arg(restoredCount));
                                console.log(qsTr("%1 note(s) restored from trash.").arg(restoredCount));
                            };
                        } else if (pageMode === qsTr("archive")) { // Added qsTr
                            message = qsTr("Are you sure you want to unarchive %1 selected notes?").arg(selectedNoteIds.length);
                            confirmTitle = qsTr("Confirm Unarchive");
                            confirmButton = qsTr("Unarchive");
                            callbackFunction = function() {
                                var unarchivedCount = selectedNoteIds.length;
                                DB.bulkUnarchiveNotes(selectedNoteIds);
                                refreshNotes();
                                toastManager.show(qsTr("%1 note(s) unarchived!").arg(unarchivedCount));
                                console.log(qsTr("%1 note(s) unarchived.").arg(unarchivedCount));
                            };
                        }

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
                enabled: selectedNoteIds.length > 0
            }

            // NEW: Permanently Delete Button (only visible in "trash" mode)
            Button {
                id: deleteSelectedButton
                visible: archivePage.pageMode === qsTr("trash") // Added qsTr
                width: parent.calculatedButtonWidth // Use calculated width
                highlightColor: Theme.errorColor

                // NEW: Inner Column to stack Icon and Label for consistent styling
                Column {
                    anchors.centerIn: parent

                    Item { // Wrapper Item for the Icon to control its precise size and centering
                        width: Theme.fontSizeExtraLarge * 0.9 // Adjusted size for icons in buttons
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/delete.svg"
                            anchors.fill: parent // Icon fills its wrapper Item
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: qsTr("Delete")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        var message = qsTr("Are you sure you want to permanently delete %1 selected notes? This action cannot be undone.").arg(selectedNoteIds.length);
                        archivePage.showConfirmDialog(
                            message,
                            function() {
                                var deletedCount = selectedNoteIds.length;
                                DB.permanentlyDeleteNotes(selectedNoteIds);
                                refreshNotes(); // Call refreshNotes specific to this page
                                toastManager.show(qsTr("%1 note(s) permanently deleted!").arg(deletedCount));
                                console.log(qsTr("%1 note(s) permanently deleted.").arg(deletedCount));
                            },
                            qsTr("Confirm Permanent Deletion"),
                            qsTr("Delete Permanently"),
                            Theme.errorColor
                        );
                        console.log(qsTr("Showing permanent delete confirmation dialog for %1 notes.").arg(selectedNoteIds.length));
                    }
                }
                enabled: selectedNoteIds.length > 0
            }
        }

        // Added ID to the spacer Item for accurate height calculation
        Item {
            id: selectionSpacer // NEW ID
            Layout.fillWidth: true
            Layout.preferredHeight: selectionControlsVisible ? Theme.paddingMedium : 0
            visible: selectionControlsVisible
        }

        SilicaFlickable {
            id: notesFlickable
            Layout.fillWidth: true
            // --- MODIFIED: Explicit height calculation based on remaining space in ColumnLayout ---
            // The parent.height here refers to the height of mainLayout
            Layout.preferredHeight: parent.height
                                  - selectionControls.height
                                  - selectionSpacer.height
            contentHeight: notesColumn.implicitHeight
            clip: true // Explicitly ensure content is clipped to the flickable's bounds

            Column {
                id: notesColumn
                width: parent.width
                spacing: Theme.paddingMedium
                visible: !archivePage.showEmptyLabel
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium

                Repeater {
                    model: notesToDisplay
                    delegate: Column {
                        width: parent.width
                        spacing: Theme.paddingLarge

                        TrashArchiveNoteCard { // Using TrashNoteCard as it's designed for displaying deleted/archived notes
                            id: noteCardInstance
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: archivePage.noteMargin
                                rightMargin: archivePage.noteMargin
                            }
                            width: parent.width - (Theme.paddingMedium * 2)
                            noteId: modelData.id
                            title: modelData.title
                            content: modelData.content
                            tags: modelData.tags ? modelData.tags.join(' ') : ''
                            cardColor: modelData.color || "#1c1d29"
                            height: implicitHeight
                            isSelected: archivePage.selectedNoteIds.indexOf(modelData.id) !== -1
                            selectedBorderColor: noteCardInstance.isSelected ? "#FFFFFF" : "#00000000"
                            selectedBorderWidth: noteCardInstance.isSelected ? Theme.borderWidthSmall : 0

                            onSelectionToggled: {
                                if (isCurrentlySelected) {
                                    var index = archivePage.selectedNoteIds.indexOf(noteId);
                                    if (index !== -1) {
                                        archivePage.selectedNoteIds.splice(index, 1);
                                    }
                                } else {
                                    if (archivePage.selectedNoteIds.indexOf(noteId) === -1) {
                                        archivePage.selectedNoteIds.push(noteId);
                                    }
                                }
                                archivePage.selectedNoteIds = archivePage.selectedNoteIds;
                                console.log(qsTr("Toggled selection for note ID: %1. Current selected: %2").arg(noteId).arg(JSON.stringify(archivePage.selectedNoteIds)));
                            }

                            onNoteClicked: {
                                console.log(qsTr("UNIFIED_NOTES_PAGE: Opening NotePage for note ID: %1 from %2.").arg(noteId).arg(archivePage.pageMode));
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: archivePage.refreshNotes,
                                    noteId: noteId,
                                    noteTitle: title,
                                    noteContent: content,
                                    noteIsPinned: isPinned,
                                    noteTags: tags,
                                    noteCreationDate: creationDate,
                                    noteEditDate: editDate,
                                    noteColor: color,
                                    isArchived: archivePage.pageMode === qsTr("archive"), // Added qsTr
                                    isDeleted: archivePage.pageMode === qsTr("trash") // Added qsTr
                                });
                            }
                        }
                    }
                }
            }
        }
        ScrollBar {
            flickableSource: notesFlickable
        }
    }

    ToastManager {
        id: toastManager
    }

    // --- Integrated Confirmation Dialog Component ---
    ConfirmDialog {
        id: confirmDialogInstance
        // Bind properties from archivePage to ConfirmDialog
        dialogVisible: archivePage.confirmDialogVisible
        dialogTitle: archivePage.confirmDialogTitle
        dialogMessage: archivePage.confirmDialogMessage
        confirmButtonText: archivePage.confirmButtonText
        confirmButtonHighlightColor: archivePage.confirmButtonHighlightColor

        // Connect signals from ConfirmDialog back to archivePage's logic
        onConfirmed: {
            if (archivePage.onConfirmCallback) {
                archivePage.onConfirmCallback(); // Execute the stored callback
            }
            archivePage.confirmDialogVisible = false; // Hide the dialog after confirmation
        }
        onCancelled: {
            archivePage.confirmDialogVisible = false; // Hide the dialog
            console.log(qsTr("Action cancelled by user."));
        }
    }
    Label {
        id: emptyLabel
        visible: archivePage.showEmptyLabel
        text: pageMode === qsTr("trash") ? qsTr("Trash is empty.") : qsTr("Archive is empty.") // Ensured both values are translated
        font.italic: true
        color: Theme.secondaryColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.8
        horizontalAlignment: Text.AlignHCenter
    }
    SidePanel {
        id: sidePanelInstance
        open: archivePage.panelOpen
        onClosed: archivePage.panelOpen = false
    }
}

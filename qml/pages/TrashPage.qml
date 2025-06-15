// TrashPage.qml

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB

// Assuming TrashNoteCard.qml is in the same directory or its path is set in qmldir
// import "TrashNoteCard.qml" // You might uncomment this if your project setup requires explicit import here.

Page {
    id: trashPage
    backgroundColor: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#121218"
    showNavigationIndicator: false

    property var deletedNotes: []
    property var selectedNoteIds: []
    property string deleteDialogMessage: "" // For the dialog message text

    Component.onCompleted: {
        console.log("TRASH_PAGE: TrashPage opened. Calling refreshDeletedNotes.");
        refreshDeletedNotes();
    }

    // Function to refresh the list of deleted notes
    function refreshDeletedNotes() {
        deletedNotes = DB.getDeletedNotes();
        selectedNoteIds = []; // Clear selection after refresh
        console.log("DB_MGR: getDeletedNotes found", deletedNotes.length, "deleted notes.");
        console.log("TRASH_PAGE: refreshDeletedNotes completed. Count:", deletedNotes.length);
    }

    property bool showEmptyLabel: deletedNotes.length === 0
    property bool selectionControlsVisible: deletedNotes.length > 0

    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        Label {
            text: qsTr("Trash")
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: pageHeader.height // Offset from page header
        spacing: 0 // Control spacing between child elements in this layout

        // SELECTION CONTROLS PANEL - Top, fixed
        Row {
            id: selectionControls
            Layout.fillWidth: true // Fills available width in ColumnLayout
            height: selectionControlsVisible ? Theme.buttonHeightSmall + Theme.paddingSmall : 0 // Height depends on visibility
            visible: selectionControlsVisible // Visibility depends on whether there are notes
            spacing: Theme.paddingSmall // Spacing between buttons

            // Internal padding for the Row so buttons don't stick to edges
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingMedium
            anchors.rightMargin: Theme.paddingMedium

            // "Select All / Deselect All" Button
            Button {
                id: selectAllButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: "../icons/select_all.svg"
                onClicked: {
                    if (selectedNoteIds.length < deletedNotes.length) {
                        selectedNoteIds = []; // Clear current selection
                        for (var i = 0; i < deletedNotes.length; i++) {
                            selectedNoteIds.push(deletedNotes[i].id); // Select all
                        }
                    } else {
                        selectedNoteIds = []; // Deselect all
                    }
                    // Important: reassign the property to ensure QML detects the change
                    selectedNoteIds = selectedNoteIds;
                    console.log(qsTr("Selected note IDs after Select All/Deselect All: %1").arg(JSON.stringify(selectedNoteIds)));
                }
                enabled: deletedNotes.length > 0 // Button active if there are notes
            }

            // "Restore Selected" Button
            Button {
                id: restoreSelectedButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: "../icons/restore_notes.svg"
                highlightColor: Theme.highlightColor
                enabled: selectedNoteIds.length > 0 // Active if something is selected
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        var restoredCount = selectedNoteIds.length;
                        DB.restoreNotes(selectedNoteIds); // Restore notes from trash
                        refreshDeletedNotes(); // Refresh the list after action
                        toastManager.show(qsTr("%1 note(s) restored!").arg(restoredCount));
                        console.log(qsTr("%1 note(s) restored from trash.").arg(restoredCount));
                    }
                }
            }

            // "Permanently Delete Selected" Button
            Button {
                id: deleteSelectedButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: "../icons/delete.svg"
                highlightColor: Theme.errorColor
                enabled: selectedNoteIds.length > 0 // Active if something is selected
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        deleteDialogMessage = qsTr("Are you sure you want to permanently delete %1 selected notes? This action cannot be undone.").arg(selectedNoteIds.length);
                        manualConfirmDialog.visible = true; // Show the custom confirmation dialog
                        console.log(qsTr("Showing permanent delete confirmation dialog for %1 notes.").arg(selectedNoteIds.length));
                    }
                }
            }
        } // End selectionControls Row

        // Small spacing item between buttons and Flickable
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: selectionControlsVisible ? Theme.paddingMedium : 0
            visible: selectionControlsVisible // Visible only if selection controls are visible
        }

        // Main scrollable area for displaying notes
        SilicaFlickable {
            id: trashFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentHeight: trashColumn.implicitHeight + (trashPage.showEmptyLabel ? 0 : Theme.paddingLarge * 2) // Dynamic content height

            Column {
                id: trashColumn
                width: parent.width
                spacing: Theme.paddingMedium // Spacing between note cards
                visible: !trashPage.showEmptyLabel // Visibility depends on whether there are notes
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium // Top margin

                // Repeater to display each note
                Repeater {
                    model: deletedNotes // Data model - list of deleted notes
                    delegate: Column {
                        width: parent.width
                        spacing: Theme.paddingLarge // Spacing between individual note cards

                        TrashNoteCard { // Using TrashNoteCard for display
                            id: trashNoteCardInstance
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: Theme.paddingMedium
                                rightMargin: Theme.paddingMedium
                            }
                            width: parent.width - (Theme.paddingMedium * 2) // Adjust width for margins
                            noteId: modelData.id
                            title: modelData.title
                            content: modelData.content
                            tags: modelData.tags ? modelData.tags.join(' ') : '' // Tags as space-separated string
                            cardColor: modelData.color || "#1c1d29" // Card color
                            height: implicitHeight // Height adapts to content
                            isSelected: selectedNoteIds.indexOf(modelData.id) !== -1 // Determine if the current note is selected

                            // Handler for toggling note selection
                            onSelectionToggled: {
                                if (isSelected) {
                                    // Add ID to selected list if not already there
                                    if (selectedNoteIds.indexOf(noteId) === -1) {
                                        selectedNoteIds.push(noteId);
                                    }
                                } else {
                                    // Remove ID from selected list
                                    var index = selectedNoteIds.indexOf(noteId);
                                    if (index !== -1) {
                                        selectedNoteIds.splice(index, 1);
                                    }
                                }
                                // Important: reassign property to ensure QML detects list change
                                selectedNoteIds = selectedNoteIds;
                                console.log(qsTr("Toggled selection for note ID: %1. Current selected: %2").arg(noteId).arg(JSON.stringify(selectedNoteIds)));
                            }

                            // Handler for opening a note for viewing from TrashNoteCard's signal
                            onNoteClicked: {
                                console.log(qsTr("TRASH_PAGE: Opening NotePage for note ID: %1 from Trash.").arg(noteId));
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: trashPage.refreshDeletedNotes, // Callback to refresh this page
                                    noteId: noteId,
                                    noteTitle: title,
                                    noteContent: content,
                                    noteIsPinned: isPinned,
                                    noteTags: tags, // Ensure 'tags' is passed as an array if NotePage expects it
                                    noteCreationDate: creationDate,
                                    noteEditDate: editDate,
                                    noteColor: color,
                                    isDeleted: true // Explicitly indicate it's from trash
                                });
                            }
                        }
                    }
                }
            }

            // Label displayed if the notes list is empty (Trash is empty)
            Label {
                id: emptyLabel
                visible: trashPage.showEmptyLabel
                text: qsTr("Trash is empty.")
                font.italic: true
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Scrollbar for SilicaFlickable
        ScrollBar {
            flickableSource: trashFlickable
        }
    } // End mainLayout ColumnLayout

    // Toast Manager for displaying pop-up messages
    ToastManager {
        id: toastManager
    }

    // Manual Overlay / Confirmation Dialog for permanent deletion
    Item {
        id: manualConfirmDialog
        anchors.fill: parent
        visible: false // Hidden by default
        z: 100 // Ensure dialog is on top of other elements

        // Background to dim the page
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.9125
        }

        // The dialog content itself (centered rectangle)
        Rectangle {
            id: dialogContent
            width: parent.width * 0.8 // 80% width of parent
            height: dialogColumn.implicitHeight + Theme.paddingLarge * 2 // Height based on content with padding
            color: Theme.backgroundColor // Dialog background color
            radius: Theme.itemCornerRadius // Rounded corners
            anchors.centerIn: parent // Centered within parent Item

            Column {
                id: dialogColumn
                width: parent.width
                spacing: Theme.paddingMedium // Spacing between elements in the column
                anchors.margins: Theme.paddingLarge // Internal padding for the column

                Label {
                    width: parent.width
                    text: qsTr("Confirm Deletion") // Dialog title
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.highlightColor
                }

                Label {
                    width: parent.width
                    text: trashPage.deleteDialogMessage // Message text from page property
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.primaryColor
                }

                RowLayout {
                    width: parent.width
                    spacing: Theme.paddingMedium // Spacing between buttons
                    anchors.horizontalCenter: parent.horizontalCenter // Center buttons

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Cancel")
                        onClicked: manualConfirmDialog.visible = false // Hide dialog on cancel
                    }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Delete") // Delete button text
                        highlightColor: Theme.errorColor // Highlight color (red)
                        onClicked: {
                            var deletedCount = selectedNoteIds.length; // Save count before clearing selectedNoteIds
                            DB.permanentlyDeleteNotes(selectedNoteIds); // Call permanent delete function
                            refreshDeletedNotes(); // Refresh notes list (this also clears selectedNoteIds)
                            toastManager.show(qsTr("%1 note(s) permanently deleted!").arg(deletedCount)); // Notification
                            manualConfirmDialog.visible = false // Hide dialog after action
                            console.log(qsTr("%1 note(s) permanently deleted from Trash.").arg(deletedCount));
                        }
                    }
                }
            }
        }
    } // End manualConfirmDialog
}

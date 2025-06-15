// trashArchivePage.qml

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB

Page {
    id: unifiedNotesPage
    // Color of the page background. Using Theme color if defined, otherwise a default.
    backgroundColor: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#121218"
    showNavigationIndicator: false // Don't show navigation indicator (e.g., for Sailfish OS)

    // New property to define the page's mode: "trash" or "archive"
    property string pageMode: "archive" // Default mode is "archive" if not specified

    // Properties for storing data and page state
    property var notesToDisplay: [] // List of notes (either deleted or archived)
    property var selectedNoteIds: [] // List of IDs of selected notes for bulk operations
    property string dialogMessage: "" // Message for confirmation dialogs (restore/unarchive/delete)

    // Determine visibility of selection controls and empty label
    property bool showEmptyLabel: notesToDisplay.length === 0
    property bool selectionControlsVisible: notesToDisplay.length > 0

    // Actions on component completion (when page is loaded)
    Component.onCompleted: {
        console.log(qsTr("UNIFIED_NOTES_PAGE: UnifiedNotesPage opened in %1 mode. Calling refreshNotes.").arg(pageMode));
        refreshNotes(); // Load notes based on the current mode
    }

    // Function to refresh the list of notes based on pageMode
    function refreshNotes() {
        if (pageMode === "trash") {
            notesToDisplay = DB.getDeletedNotes(); // Get deleted notes for trash mode
            console.log(qsTr("DB_MGR: getDeletedNotes found %1 deleted notes.").arg(notesToDisplay.length));
        } else if (pageMode === "archive") {
            notesToDisplay = DB.getArchivedNotes(); // Get archived notes for archive mode
            console.log(qsTr("DB_MGR: getArchivedNotes found %1 archived notes.").arg(notesToDisplay.length));
        }
        selectedNoteIds = []; // Reset selected notes
        console.log(qsTr("UNIFIED_NOTES_PAGE: refreshNotes completed for %1. Count: %2").arg(pageMode).arg(notesToDisplay.length));
    }

    // Page Header (Title changes based on mode)
    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        Label {
            text: pageMode === "trash" ? qsTr("Trash") : qsTr("Archive") // Dynamic title
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            //color: Theme.highlightColor
            font.bold: true
        }
    }

    // Main layout using ColumnLayout for vertical arrangement
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
                    var newSelectedIds = [];
                    // Проверяем, выбраны ли все элементы из notesToDisplay
                    // Если selectedNoteIds.length === notesToDisplay.length, и notesToDisplay не пуст, значит, все выбраны
                    var currentlyAllSelected = (unifiedNotesPage.selectedNoteIds.length === unifiedNotesPage.notesToDisplay.length) && (unifiedNotesPage.notesToDisplay.length > 0);

                    if (!currentlyAllSelected) { // Если не все выбраны, выбираем все
                        for (var i = 0; i < unifiedNotesPage.notesToDisplay.length; i++) {
                            newSelectedIds.push(unifiedNotesPage.notesToDisplay[i].id);
                        }
                    } // else { newSelectedIds останется пустым, что снимет выбор }

                    // Важно: переприсваиваем свойство, чтобы QML обнаружил изменение
                    unifiedNotesPage.selectedNoteIds = newSelectedIds;
                    console.log(qsTr("Selected note IDs after Select All/Deselect All: %1").arg(JSON.stringify(unifiedNotesPage.selectedNoteIds)));
                }
                enabled: notesToDisplay.length > 0 // Кнопка активна, если есть заметки
            }

            // "Restore" / "Unarchive" Selected Button (Dynamic based on pageMode)
            Button {
                id: primaryActionButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: pageMode === "trash" ? "../icons/restore_notes.svg" : "../icons/unarchive.svg" // Dynamic icon
                text: pageMode === "trash" ? qsTr("Restore") : qsTr("Unarchive") // Dynamic text
                highlightColor: Theme.highlightColor // Highlight color
                enabled: selectedNoteIds.length > 0 // Active if something is selected
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        if (pageMode === "trash") {
                            DB.restoreNotes(selectedNoteIds); // Restore notes from trash
                            toastManager.show(qsTr("%1 note(s) restored!").arg(selectedNoteIds.length));
                            console.log(qsTr("%1 note(s) restored from trash.").arg(selectedNoteIds.length));
                        } else if (pageMode === "archive") {
                            DB.bulkUnarchiveNotes(selectedNoteIds); // Unarchive notes
                            toastManager.show(qsTr("%1 note(s) unarchived!").arg(selectedNoteIds.length));
                            console.log(qsTr("%1 note(s) unarchived.").arg(selectedNoteIds.length));
                        }
                        refreshNotes(); // Refresh the list after action
                    }
                }
            }

            // "Permanently Delete" Selected Button
//            Button {
//                id: deleteSelectedButton
//                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
//                Layout.preferredHeight: Theme.buttonHeightSmall
//                icon.source: "../icons/delete.svg" // Delete icon
//                highlightColor: Theme.errorColor // Highlight color (red)
//                enabled: selectedNoteIds.length > 0 // Active if something is selected
//                onClicked: {
//                    if (selectedNoteIds.length > 0) {
//                        // Formulate confirmation dialog message dynamically
//                        dialogMessage = qsTr("Are you sure you want to permanently delete %1 selected notes from %2? This action cannot be undone.")
//                                          .arg(selectedNoteIds.length)
//                                          .arg(pageMode === "trash" ? qsTr("trash") : qsTr("archive"));
//                        // Show the custom confirmation dialog
//                        manualConfirmDialog.visible = true;
//                        console.log(qsTr("Showing permanent delete confirmation dialog for %1 notes.").arg(pageMode));
//                    }
//                }
//            }
        } // End selectionControls Row

        // Small spacing item between buttons and Flickable
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: selectionControlsVisible ? Theme.paddingMedium : 0
            visible: selectionControlsVisible // Visible only if selection controls are visible
        }

        // Main scrollable area for displaying notes
        SilicaFlickable {
            id: notesFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentHeight: notesColumn.implicitHeight + (unifiedNotesPage.showEmptyLabel ? 0 : Theme.paddingLarge * 2) // Dynamic content height

            Column {
                id: notesColumn
                width: parent.width
                spacing: Theme.paddingMedium
                visible: !unifiedNotesPage.showEmptyLabel // Visibility depends on whether there are notes
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium // Top margin

                // Repeater to display each note
                Repeater {
                    model: notesToDisplay // Data model - list of notes (deleted or archived)
                    delegate: Column {
                        width: parent.width
                        spacing: Theme.paddingLarge // Spacing between note cards

                        TrashNoteCard { // Using TrashNoteCard for display
                            id: noteCardInstance
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: Theme.paddingMedium
                                rightMargin: Theme.paddingMedium
                            }
                            width: parent.width - (Theme.paddingMedium * 2)
                            noteId: modelData.id
                            title: modelData.title
                            content: modelData.content
                            tags: modelData.tags ? modelData.tags.join(' ') : '' // Tags as space-separated string
                            cardColor: modelData.color || "#1c1d29" // Card color
                            height: implicitHeight // Height adapts to content
                            // Determine if the current note is selected
                            isSelected: unifiedNotesPage.selectedNoteIds.indexOf(modelData.id) !== -1

                            // Handler for toggling note selection
                            onSelectionToggled: {
                                if (isSelected) {
                                    // Add ID to selected list if not already there
                                    if (unifiedNotesPage.selectedNoteIds.indexOf(noteId) === -1) {
                                        unifiedNotesPage.selectedNoteIds.push(noteId);
                                    }
                                } else {
                                    // Remove ID from selected list
                                    var index = unifiedNotesPage.selectedNoteIds.indexOf(noteId);
                                    if (index !== -1) {
                                        unifiedNotesPage.selectedNoteIds.splice(index, 1);
                                    }
                                }
                                // Important: reassign property to ensure QML detects list change
                                unifiedNotesPage.selectedNoteIds = unifiedNotesPage.selectedNoteIds;
                                console.log(qsTr("Toggled selection for note ID: %1. Current selected: %2").arg(noteId).arg(JSON.stringify(unifiedNotesPage.selectedNoteIds)));
                            }
                            // Handler for opening a note for viewing
                            onNoteClicked: { // This is the signal handler now
                                console.log(qsTr("UNIFIED_NOTES_PAGE: Opening NotePage for note ID: %1 from %2.").arg(noteId).arg(pageMode));
                                // Pass all necessary data to NotePage, including the read-only flags
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: unifiedNotesPage.refreshNotes, // Callback to refresh this page
                                    noteId: noteId, // Use the parameter from the signal
                                    noteTitle: title, // Use the parameter from the signal
                                    noteContent: content, // Use the parameter from the signal
                                    noteIsPinned: isPinned, // Use the parameter from the signal
                                    noteTags: tags, // Use the parameter from the signal (ensure it's an array if NotePage expects it)
                                    noteCreationDate: creationDate, // Use the parameter from the signal
                                    noteEditDate: editDate, // Use the parameter from the signal
                                    noteColor: color, // Use the parameter from the signal
                                    isArchived: isArchived, // Use the parameter from the signal
                                    isDeleted: isDeleted // Use the parameter from the signal
                                });
                            }
                        }
                    }
                }
            }

            // Label displayed if the notes list is empty (Trash is empty / Archive is empty)
            Label {
                id: emptyLabel
                visible: unifiedNotesPage.showEmptyLabel
                text: pageMode === "trash" ? qsTr("Trash is empty.") : qsTr("Archive is empty.") // Dynamic text
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
            flickableSource: notesFlickable
        }
    } // End mainLayout ColumnLayout

    // Toast Manager for displaying pop-up messages
    ToastManager {
        id: toastManager
    }

//    // Manual Overlay / Confirmation Dialog for permanent deletion
//    Item {
//        id: manualConfirmDialog
//        anchors.fill: parent
//        visible: false // Hidden by default
//        z: 100 // Ensure dialog is on top of other elements
//        // Background to dim the page
//        Rectangle {
//            anchors.fill: parent
//            radius: Theme.itemSizeSmall / 2
//            color: "#000000"
//            opacity: 0.6
//        }
//        // The dialog content itself (centered rectangle)
//        Rectangle {
//            id: dialogContent
//            width: parent.width * 0.8 // 80% width of parent
//            height: dialogColumn.implicitHeight + Theme.paddingLarge * 2 // Height based on content with padding
//            color: Theme.backgroundColor // Dialog background color
//            radius: Theme.itemCornerRadius // Rounded corners
//            anchors.centerIn: parent // Centered within parent Item
//            Column {
//                id: dialogColumn
//                width: parent.width
//                spacing: Theme.paddingMedium // Spacing between elements in the column
//                anchors.margins: Theme.paddingLarge // Internal padding for the column
//                Label {
//                    width: parent.width
//                    text: qsTr("Confirm Permanent Deletion") // Dialog title
//                    font.pixelSize: Theme.fontSizeLarge
//                    font.bold: true
//                    horizontalAlignment: Text.AlignHCenter
//                    color: Theme.highlightColor
//                }
//                Label {
//                    width: parent.width
//                    text: unifiedNotesPage.dialogMessage // Message text from page property
//                    wrapMode: Text.WordWrap
//                    horizontalAlignment: Text.AlignHCenter
//                    color: Theme.primaryColor
//                }
//                RowLayout {
//                    width: parent.width
//                    spacing: Theme.paddingMedium // Spacing between buttons
//                    anchors.horizontalCenter: parent.horizontalCenter // Center buttons
//                    Button {
//                        Layout.fillWidth: true
//                        text: qsTr("Cancel")
//                        onClicked: manualConfirmDialog.visible = false // Hide dialog on cancel
//                    }
//                    Button {
//                        Layout.fillWidth: true
//                        text: qsTr("Delete") // Delete button text
//                        highlightColor: Theme.errorColor // Highlight color (red)
//                        onClicked: {
//                            DB.permanentlyDeleteNotes(selectedNoteIds); // Call permanent delete function
//                            refreshNotes(); // Refresh notes list
//                            toastManager.show(qsTr("%1 note(s) permanently deleted!").arg(selectedNoteIds.length)); // Notification
//                            manualConfirmDialog.visible = false // Hide dialog after action
//                            console.log(qsTr("%1 note(s) permanently deleted from %2.").arg(selectedNoteIds.length).arg(unifiedNotesPage.pageMode));
//                        }
//                    }
//                }
//            }
//        }
//    } // End manualConfirmDialog
}

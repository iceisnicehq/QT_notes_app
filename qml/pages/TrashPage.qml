// /qml/pages/TrashPage.qml
import QtQuick.LocalStorage 2.0 
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "../services/DatabaseManagerService.js" as DB
import "../dialogs"
import "../components"
import "../services"
import "../note_cards"

Page {
    id: trashPage
    objectName: "trashPage" 
    backgroundColor: trashPage.customBackgroundColor !== undefined ? trashPage.customBackgroundColor : "#121218" // Fallback to Theme.backgroundColor if custom is not set
    showNavigationIndicator: false
    // Property to hold the currently selected custom background color
    property string customBackgroundColor: DB.getThemeColor() || "#121218" // Load from DB, default to a dark color if not found    showNavigationIndicator: false
    property int noteMargin: 20

    property var deletedNotes: []
    property var selectedNoteIds: []
    property bool panelOpen: false // Property to control side panel visibility

    // Properties to control the dialog from the page's logic (These will now be passed to the component)
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Deletion") // Default title
    property string confirmDialogMessage: "" // Message for the dialog
    property string confirmButtonText: qsTr("Delete") // Default button text
    property var onConfirmCallback: null // Callback function to execute on confirm
    property color confirmButtonHighlightColor: Theme.errorColor // Default highlight color for confirm button


    Component.onCompleted: {
        console.log("TRASH_PAGE: TrashPage opened. Initializing DB and calling refreshDeletedNotes.");
        // Initialize the DatabaseManager with the LocalStorage object
        DB.initDatabase(LocalStorage); // Pass the LocalStorage object here
        // Clean up expired notes immediately when entering the trash page
        DB.permanentlyDeleteExpiredDeletedNotes();
        // Then refresh the displayed notes
        refreshDeletedNotes();
        // Add logging to see the actual count of notes loaded
        console.log("TRASH_PAGE: Deleted notes after refresh. Count: " + deletedNotes.length);
        // Set the current page for the side panel instance
        sidePanelInstance.currentPage = qsTr("trash");
    }

    function refreshDeletedNotes() {
        deletedNotes = DB.getDeletedNotes(); // Get notes that remain after cleanup
        selectedNoteIds = []; // Clear any existing selections
        console.log("DB_MGR: getDeletedNotes found " + deletedNotes.length + " deleted notes.");
        console.log("TRASH_PAGE: refreshDeletedNotes completed. Count: " + deletedNotes.length);
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


    property bool showEmptyLabel: deletedNotes.length === 0
    property bool selectionControlsVisible: deletedNotes.length > 0
    property bool allNotesSelected: (selectedNoteIds.length === deletedNotes.length) && (deletedNotes.length > 0)

    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        
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

            RippleEffectComponent { id: menuRipple }

            // Dynamic Icon based on selection state, styled like the menu button's icon
            Icon {
                id: leftIcon 
                source: trashPage.selectedNoteIds.length > 0 ? "../icons/close.svg" : "../icons/menu.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor // Ensured primary color for consistency
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY) // Keep ripple effect
                onClicked: {
                    
                    if (trashPage.selectedNoteIds.length > 0) {
                        trashPage.selectedNoteIds = []; // Clear selected notes
                        console.log("Selected notes cleared.");
                    } else {
                        trashPage.panelOpen = true // Open the side panel
                        console.log("Menu button clicked → panelOpen = true");
                    }
                }
            }
        }

        Label {
            id: titleLabel
            text: qsTr("Trash")
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
        Label {
            id: infoLabel
            text: qsTr("Notes in trash are deleted after 30 days.")
            font.pixelSize: Theme.fontSizeSmall * 0.9 // Smaller font size
            font.italic: true // Italicized text
            color: Theme.secondaryColor // A subtle color for auxiliary text
            horizontalAlignment: Text.AlignHCenter // Center horizontally
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: titleLabel.bottom // Position below the main title
            anchors.topMargin: Theme.paddingSmall // Small margin between title and info
            width: parent.width * 0.9 // Ensure it doesn't span full width, add some padding
            wrapMode: Text.Wrap // Allow text to wrap if too long
        }

    }


    ColumnLayout {
        id: mainLayout
        // Changed anchoring to explicitly define vertical space
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: pageHeader.bottom // Anchor directly to the bottom of the pageHeader
        anchors.bottom: parent.bottom // Anchor to the bottom of the Page
        spacing: 0

        Row {
            id: selectionControls
            Layout.fillWidth: true
            height: selectionControlsVisible ? Theme.buttonHeightSmall + Theme.paddingSmall : 0
            visible: selectionControlsVisible
            spacing: Theme.paddingSmall // This spacing applies between buttons

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: trashPage.noteMargin
            anchors.rightMargin: trashPage.noteMargin
            property real calculatedButtonWidth: (trashPage.width) /  3.23

            // "Select All / Deselect All" Button
            Button {
                id: selectAllButton
                width: parent.calculatedButtonWidth // Use calculated width
                highlightColor: Theme.highlightColor

                
                Column {
                    anchors.centerIn: parent

                    Item { 
                        width: Theme.fontSizeExtraLarge * 0.9 
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: trashPage.allNotesSelected ? "../icons/deselect_all.svg" : "../icons/select_all.svg"
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
                    if (!trashPage.allNotesSelected) {
                        for (var i = 0; i < trashPage.deletedNotes.length; i++) {
                            newSelectedIds.push(trashPage.deletedNotes[i].id);
                        }
                    }
                    trashPage.selectedNoteIds = newSelectedIds;
                    console.log("Selected note IDs after Select All/Deselect All: " + JSON.stringify(trashPage.selectedNoteIds));
                }
                enabled: deletedNotes.length > 0
            }

            Button {
                id: restoreSelectedButton
                width: parent.calculatedButtonWidth // Use calculated width
                highlightColor: Theme.highlightColor

                
                Column {
                    anchors.centerIn: parent

                    Item { // Wrapper Item for the Icon to control its precise size and centering
                        width: Theme.fontSizeExtraLarge * 0.9 // Adjusted size for icons in buttons
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/restore_notes.svg"
                            anchors.fill: parent // Icon fills its wrapper Item
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: qsTr("Restore")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        var message = qsTr("Are you sure you want to restore %1 selected notes to your main notes?").arg(selectedNoteIds.length);
                        trashPage.showConfirmDialog(
                            message,
                            function() {
                                var restoredCount = selectedNoteIds.length;
                                DB.restoreNotes(selectedNoteIds);
                                refreshDeletedNotes();
                                toastManager.show(qsTr("%1 note(s) restored!").arg(restoredCount));
                                console.log(restoredCount + " note(s) restored from trash.");
                            },
                            qsTr("Confirm Restoration"), // Title for restore dialog
                            qsTr("Restore"), // Button text for restore dialog
                            Theme.highlightColor // Highlight color for restore button
                        );
                        console.log("Showing restore confirmation dialog for " + selectedNoteIds.length + " notes.");
                    }
                }
                enabled: selectedNoteIds.length > 0
            }

            Button {
                id: deleteSelectedButton
                width: parent.calculatedButtonWidth // Use calculated width
                highlightColor: Theme.errorColor

                
                Column {
                    anchors.centerIn: parent

                    Item { // Wrapper Item for the Icon to control its precise size and centering
                        width: Theme.fontSizeExtraLarge * 0.9 // Adjusted size for icons in buttons
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/perma_delete.svg"
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
                        trashPage.showConfirmDialog(
                            message,
                            function() {
                                console.log("CONFIRMATION: selectedNoteIds contents:", JSON.stringify(selectedNoteIds)); // Add this!
                                var deletedCount = selectedNoteIds.length;
                                DB.permanentlyDeleteNotes(selectedNoteIds);
                                refreshDeletedNotes();
                                toastManager.show(qsTr("%1 note(s) permanently deleted!").arg(deletedCount));
                                console.log(deletedCount + " note(s) permanently deleted.");
                            },
                            qsTr("Confirm Permanent Deletion"),
                            qsTr("Delete"), 
                            Theme.errorColor
                        );
                        console.log("Showing permanent delete confirmation dialog for " + selectedNoteIds.length + " notes.");
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
            id: trashFlickable
            Layout.fillWidth: true
            
            // The parent.height here refers to the height of mainLayout
            Layout.preferredHeight: parent.height // mainLayout's height
                                  - selectionControls.height
                                  - selectionSpacer.height
            contentHeight: trashColumn.implicitHeight
            clip: true // Explicitly ensure content is clipped to the flickable's bounds

            Column {
                id: trashColumn
                width: parent.width
                spacing: Theme.paddingMedium // Spacing between each full note entry (card + date label)
                visible: !trashPage.showEmptyLabel
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium

                Repeater {
                    model: deletedNotes
                    delegate: Column {
                        // This Column acts as the container for a single note card AND its deletion date label
                        width: parent.width
                        spacing: Theme.paddingSmall // Spacing between the card and the label below it

                        TrashArchiveNoteCard {
                            id: trashNoteCardInstance
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: trashPage.noteMargin
                                rightMargin: trashPage.noteMargin
                            }
                            width: parent.width - (Theme.paddingMedium * 2)
                            noteId: modelData.id
                            title: modelData.title
                            content: modelData.content
                            tags: modelData.tags ? modelData.tags.join("_||_") : ''
                            cardColor: modelData.color || "#1c1d29"
                            height: implicitHeight // Let the card determine its height based on its content

                            isSelected: selectedNoteIds.indexOf(modelData.id) !== -1
                            selectedBorderColor: trashNoteCardInstance.isSelected ? "#FFFFFF" : "#00000000"
                            selectedBorderWidth: trashNoteCardInstance.isSelected ? Theme.borderWidthSmall : 0

                            onSelectionToggled: {
                                if (isCurrentlySelected) {
                                    var index = selectedNoteIds.indexOf(noteId);
                                    if (index !== -1) {
                                        selectedNoteIds.splice(index, 1);
                                    }
                                } else {
                                    if (selectedNoteIds.indexOf(noteId) === -1) {
                                        selectedNoteIds.push(noteId);
                                    }
                                }
                                selectedNoteIds = selectedNoteIds;
                                console.log("Toggled selection for note ID: " + noteId + ". Current selected: " + JSON.stringify(selectedNoteIds));
                            }

                            onNoteClicked: {
                                console.log("TRASH_PAGE: Opening NotePage for note ID: " + noteId + " from Trash.");
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: trashPage.refreshDeletedNotes,
                                    noteId: noteId,
                                    noteTitle: title,
                                    noteContent: content,
                                    noteIsPinned: isPinned,
                                    noteTags: tags,
                                    noteCreationDate: noteCreationDate,
                                    noteEditDate: editDate,
                                    noteColor: color,
                                    isDeleted: true
                                });
                            }
                        }

                    }
                }
            }

        }

        ScrollBarComponent {
            flickableSource: trashFlickable
        }
    }

    ToastManagerService {
        id: toastManager
    }

    // --- Integrated Confirmation Dialog Component ---
    ConfirmDialog {
        id: confirmDialogInstance
        // Bind properties from TrashPage to ConfirmDialog
        dialogVisible: trashPage.confirmDialogVisible
        dialogTitle: trashPage.confirmDialogTitle
        dialogMessage: trashPage.confirmDialogMessage
        confirmButtonText: trashPage.confirmButtonText
        confirmButtonHighlightColor: trashPage.confirmButtonHighlightColor
        dialogBackgroundColor: DB.darkenColor(trashPage.customBackgroundColor, 0.30) // Use DB.darkenColor

        // Connect signals from ConfirmDialog back to TrashPage's logic
        onConfirmed: {
            if (trashPage.onConfirmCallback) {
                trashPage.onConfirmCallback(); // Execute the stored callback
            }
            trashPage.confirmDialogVisible = false; // Hide the dialog after confirmation
        }
        onCancelled: {
            trashPage.confirmDialogVisible = false; // Hide the dialog
            console.log("Action cancelled by user.");
        }
    }
    Label {
        id: emptyLabel
        visible: trashPage.showEmptyLabel
        text: qsTr("Trash is empty.")
        font.italic: true
        color: Theme.secondaryColor
        anchors.centerIn: trashPage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: trashPage.verticalCenter
        width: parent.width * 0.8
        horizontalAlignment: Text.AlignHCenter
    }
    SidePanelComponent {
        id: sidePanelInstance
        open: trashPage.panelOpen
        onClosed: trashPage.panelOpen = false
        
        customBackgroundColor:  DB.darkenColor(trashPage.customBackgroundColor, 0.30)
        activeSectionColor: trashPage.customBackgroundColor
    }
}

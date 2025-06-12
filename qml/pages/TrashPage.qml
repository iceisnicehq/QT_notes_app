// TrashPage.qml (UPDATED - Improved Layout for Deleted Notes - AGAIN)

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import "DatabaseManager.js" as DB

Page {
    id: trashPage
    backgroundColor: Theme.backgroundColor
    property var deletedNotes: []

    Component.onCompleted: {
        console.log("TRASH_PAGE: TrashPage opened. Calling refreshDeletedNotes.");
        refreshDeletedNotes();
    }

    function refreshDeletedNotes() {
        deletedNotes = DB.getDeletedNotes();
        console.log("TRASH_PAGE: refreshDeletedNotes completed. Count:", deletedNotes.length);
        trashPage.showEmptyLabel = deletedNotes.length === 0; // Update visibility directly
    }

    property bool showEmptyLabel: deletedNotes.length === 0

    // Header
    PageHeader {
        Label {
            text: qsTr("Trash")
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            color: Theme.highlightColor
            font.bold: true
        }
    }

    // Main content area for deleted notes
    SilicaFlickable {
        id: trashFlickable
        anchors.fill: parent
        anchors.top: pageHeader.bottom
        contentHeight: trashColumn.implicitHeight // Use implicitHeight for proper content sizing

        Column {
            id: trashColumn
            width: parent.width
            spacing: Theme.paddingMedium // Increased spacing between note items

            // Repeater for deleted notes
            Repeater {
                model: deletedNotes
                delegate: Column { // Each deleted note item is a Column
                    width: parent.width // Make sure the column takes full width

                    // The NoteCard itself
                    NoteCard {
                        id: noteCardInTrash
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: Theme.paddingMedium
                            rightMargin: Theme.paddingMedium
                        }
                        width: parent.width - (Theme.paddingMedium * 2) // Match the parent's width minus margins
                        title: modelData.title
                        content: modelData.content
                        tags: modelData.tags ? modelData.tags.join(' ') : ''
                        cardColor: modelData.color || "#1c1d29"
                        height: implicitHeight // Let the NoteCard determine its own height
                    }

                    // Row for action buttons (Restore, Delete Permanently)
                    Row {
                        width: parent.width - (Theme.paddingMedium * 2) // Match NoteCard's horizontal margins
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.paddingSmall // Spacing between buttons
                        anchors.top: noteCardInTrash.bottom // Position below the NoteCard
                        anchors.topMargin: Theme.paddingSmall // Add some space between NoteCard and buttons

                        Button {
                            width: (parent.width - (Theme.paddingMedium * 2) - parent.spacing) / 2 // Divide available space between buttons
                            height: Theme.buttonHeight // Use standard button height
                            text: qsTr("Restore")
                            onClicked: {
                                DB.restoreNote(modelData.id);
                                refreshDeletedNotes(); // Re-fetch notes after restore
                                toastManager.show("Note restored!");
                            }
                        }

                        Button {
                            width: (parent.width - (Theme.paddingMedium * 2) - parent.spacing) / 2 // Divide available space
                            height: Theme.buttonHeight // Use standard button height
                            text: qsTr("Delete Permanently")
                            highlightColor: Theme.errorColor
                            onClicked: {
                                var dialog = pageStack.push(Qt.resolvedUrl("ConfirmationDialog.qml"), {
                                    message: qsTr("Are you sure you want to permanently delete this note? This action cannot be undone."),
                                    acceptText: qsTr("Delete"),
                                    cancelText: qsTr("Cancel")
                                });
                                dialog.accepted.connect(function() {
                                    DB.permanentlyDeleteNote(modelData.id);
                                    refreshDeletedNotes(); // Re-fetch notes after permanent delete
                                    console.log("TRASH_PAGE: Permanently deleted note ID:", modelData.id);
                                    toastManager.show("Note permanently deleted!");
                                });
                            }
                        }
                    } // End of Row for buttons
                } // End of delegate Column
            } // End of Repeater

            // Empty state label
            Label {
                visible: trashPage.showEmptyLabel
                text: qsTr("Trash is empty.")
                font.italic: true
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: trashColumn.children.length === 0 ? parent.top : trashColumn.bottom
                anchors.topMargin: Theme.itemSizeExtraLarge
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
            }
        } // End of trashColumn
    } // End of SilicaFlickable

    ScrollBar {
        flickableSource: trashFlickable
    }

    ToastManager {
        id: toastManager
    }
}

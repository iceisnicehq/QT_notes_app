// TrashPage.qml (No changes from your last provided version)

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB

Page {
    id: trashPage
    backgroundColor: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#121218"
    showNavigationIndicator: false

    property var deletedNotes: []
    property var selectedNoteIds: []
    property string deleteDialogMessage: ""

    Component.onCompleted: {
        console.log("TRASH_PAGE: TrashPage opened. Calling refreshDeletedNotes.");
        refreshDeletedNotes();
    }

    function refreshDeletedNotes() {
        deletedNotes = DB.getDeletedNotes();
        selectedNoteIds = [];
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
        anchors.topMargin: pageHeader.height
        spacing: 0

        Row {
            id: selectionControls
            Layout.fillWidth: true
            height: selectionControlsVisible ? Theme.buttonHeightSmall + Theme.paddingSmall : 0
            visible: selectionControlsVisible
            spacing: Theme.paddingSmall

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingMedium
            anchors.rightMargin: Theme.paddingMedium

            Button {
                id: selectAllButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: "../icons/select_all.svg"
                onClicked: {
                    if (selectedNoteIds.length < deletedNotes.length) {
                        selectedNoteIds = [];
                        for (var i = 0; i < deletedNotes.length; i++) {
                            selectedNoteIds.push(deletedNotes[i].id);
                        }
                    } else {
                        selectedNoteIds = [];
                    }
                    selectedNoteIds = selectedNoteIds; // Reassign to trigger update
                    console.log(qsTr("Selected note IDs after Select All/Deselect All: %1").arg(JSON.stringify(selectedNoteIds)));
                }
                enabled: deletedNotes.length > 0
            }

            Button {
                id: restoreSelectedButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: "../icons/restore_notes.svg"
                highlightColor: Theme.highlightColor
                enabled: selectedNoteIds.length > 0
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        var restoredCount = selectedNoteIds.length;
                        DB.restoreNotes(selectedNoteIds);
                        refreshDeletedNotes();
                        toastManager.show(qsTr("%1 note(s) restored!").arg(restoredCount));
                        console.log(qsTr("%1 note(s) restored from trash.").arg(restoredCount));
                    }
                }
            }

            Button {
                id: deleteSelectedButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: "../icons/delete.svg"
                highlightColor: Theme.errorColor
                enabled: selectedNoteIds.length > 0
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        deleteDialogMessage = qsTr("Are you sure you want to permanently delete %1 selected notes? This action cannot be undone.").arg(selectedNoteIds.length);
                        manualConfirmDialog.visible = true;
                        console.log(qsTr("Showing permanent delete confirmation dialog for %1 notes.").arg(selectedNoteIds.length));
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: selectionControlsVisible ? Theme.paddingMedium : 0
            visible: selectionControlsVisible
        }

        SilicaFlickable {
            id: trashFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentHeight: trashColumn.implicitHeight + (trashPage.showEmptyLabel ? 0 : Theme.paddingLarge * 2)

            Column {
                id: trashColumn
                width: parent.width
                spacing: Theme.paddingMedium
                visible: !trashPage.showEmptyLabel
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium

                Repeater {
                    model: deletedNotes
                    delegate: Column {
                        width: parent.width
                        spacing: Theme.paddingLarge

                        TrashNoteCard {
                            id: trashNoteCardInstance
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
                            tags: modelData.tags ? modelData.tags.join(' ') : ''
                            cardColor: modelData.color || "#1c1d29"
                            height: implicitHeight
                            // This binding is crucial and remains the single source of truth for isSelected
                            isSelected: selectedNoteIds.indexOf(modelData.id) !== -1

                            onSelectionToggled: {
                                // Based on the current state of isSelected (passed from TrashNoteCard),
                                // update the selectedNoteIds list
                                if (isCurrentlySelected) { // If it was selected, user wants to deselect
                                    var index = selectedNoteIds.indexOf(noteId);
                                    if (index !== -1) {
                                        selectedNoteIds.splice(index, 1);
                                    }
                                } else { // If it was deselected, user wants to select
                                    if (selectedNoteIds.indexOf(noteId) === -1) {
                                        selectedNoteIds.push(noteId);
                                    }
                                }
                                selectedNoteIds = selectedNoteIds; // Reassign to trigger QML updates
                                console.log(qsTr("Toggled selection for note ID: %1. Current selected: %2").arg(noteId).arg(JSON.stringify(selectedNoteIds)));
                            }

                            onNoteClicked: {
                                console.log(qsTr("TRASH_PAGE: Opening NotePage for note ID: %1 from Trash.").arg(noteId));
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: trashPage.refreshDeletedNotes,
                                    noteId: noteId,
                                    noteTitle: title,
                                    noteContent: content,
                                    noteIsPinned: isPinned,
                                    noteTags: tags,
                                    noteCreationDate: creationDate,
                                    noteEditDate: editDate,
                                    noteColor: color,
                                    isDeleted: true
                                });
                            }
                        }
                    }
                }
            }

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

        ScrollBar {
            flickableSource: trashFlickable
        }
    }

    ToastManager {
        id: toastManager
    }

    Item {
        id: manualConfirmDialog
        anchors.fill: parent
        visible: false
        z: 100

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.9125
        }

        Rectangle {
            id: dialogContent
            width: parent.width * 0.8
            height: implicitHeight
            color: Theme.backgroundColor
            radius: Theme.itemCornerRadius
            anchors.centerIn: parent

            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                anchors.margins: Theme.paddingLarge

                Label {
                    width: parent.width
                    text: qsTr("Confirm Deletion")
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.highlightColor
                }

                Label {
                    width: parent.width
                    text: trashPage.deleteDialogMessage
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.primaryColor
                }

                RowLayout {
                    width: parent.width
                    spacing: Theme.paddingMedium
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Cancel")
                        onClicked: manualConfirmDialog.visible = false
                    }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Delete")
                        highlightColor: Theme.errorColor
                        onClicked: {
                            var deletedCount = selectedNoteIds.length;
                            DB.permanentlyDeleteNotes(selectedNoteIds);
                            refreshDeletedNotes();
                            toastManager.show(qsTr("%1 note(s) permanently deleted!").arg(deletedCount));
                            manualConfirmDialog.visible = false
                        }
                    }
                }
            }
        }
    }
}

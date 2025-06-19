import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB

Page {
    id: archivePage
    objectName: "archivePage"
    backgroundColor: archivePage.customBackgroundColor !== undefined ? archivePage.customBackgroundColor : "#121218"
    property string customBackgroundColor: DB.getThemeColor() || "#121218"
    showNavigationIndicator: false
    property int noteMargin: 20
    property string pageMode: qsTr("archive")
    property var notesToDisplay: []
    property var selectedNoteIds: []
    property bool panelOpen: false
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Deletion")
    property string confirmDialogMessage: ""
    property string confirmButtonText: qsTr("Delete")
    property var onConfirmCallback: null
    property color confirmButtonHighlightColor: Theme.errorColor
    property bool showEmptyLabel: notesToDisplay.length === 0
    property bool selectionControlsVisible: notesToDisplay.length > 0
    property bool allNotesSelected: (selectedNoteIds.length === notesToDisplay.length) && (notesToDisplay.length > 0)

    Component.onCompleted: {
        console.log("UNIFIED_NOTES_PAGE: archivePage opened in %1 mode. Calling refreshNotes.".arg(pageMode));
        refreshNotes();
        sidePanelInstance.currentPage = pageMode;
    }

    function refreshNotes() {
        if (pageMode === qsTr("trash")) {
            notesToDisplay = DB.getDeletedNotes();
            console.log("DB_MGR: getDeletedNotes found %1 deleted notes.".arg(notesToDisplay.length));
        } else if (pageMode === qsTr("archive")) {
            notesToDisplay = DB.getArchivedNotes();
            console.log("DB_MGR: getArchivedNotes found %1 archived notes.".arg(notesToDisplay.length));
        }
        selectedNoteIds = [];
        console.log("UNIFIED_NOTES_PAGE: refreshNotes completed for %1. Count: %2".arg(pageMode).arg(notesToDisplay.length));
    }

    function showConfirmDialog(message, callback, title, buttonText, highlightColor) {
        confirmDialogMessage = message;
        onConfirmCallback = callback;
        if (title !== undefined) confirmDialogTitle = title;
        else confirmDialogTitle = qsTr("Confirm Deletion");

        if (buttonText !== undefined) confirmButtonText = buttonText;
        else confirmButtonText = qsTr("Delete");

        if (highlightColor !== undefined) confirmButtonHighlightColor = highlightColor;
        else confirmButtonHighlightColor = Theme.errorColor;

        confirmDialogVisible = true;
    }

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

            RippleEffect { id: menuRipple }

            Icon {
                id: leftIcon
                source: archivePage.selectedNoteIds.length > 0 ? "../icons/close.svg" : "../icons/menu.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY)
                onClicked: {
                    if (archivePage.selectedNoteIds.length > 0) {
                        archivePage.selectedNoteIds = [];
                        console.log("Selected notes cleared in archivePage.");
                    } else {
                        archivePage.panelOpen = true
                        console.log("Menu button clicked in archivePage → panelOpen = true")
                    }
                }
            }
        }

        Label {
            text: pageMode === qsTr("trash") ? qsTr("Trash") : qsTr("Archive")
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
            anchors.leftMargin: archivePage.noteMargin
            anchors.rightMargin: archivePage.noteMargin

            property real calculatedButtonWidth: (archivePage.width) / 2.13

            Button {
                id: selectAllButton
                width: parent.calculatedButtonWidth
                highlightColor: Theme.highlightColor

                Column {
                    anchors.centerIn: parent

                    Item {
                        width: Theme.fontSizeExtraLarge * 0.9
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: archivePage.allNotesSelected ? "../icons/deselect_all.svg" : "../icons/select_all.svg"
                            anchors.fill: parent
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: qsTr("Select")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
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
                    console.log("Selected note IDs after Select All/Deselect All: %1".arg(JSON.stringify(archivePage.selectedNoteIds)));
                }
                enabled: notesToDisplay.length > 0
            }

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

                        Icon {
                            source: pageMode === qsTr("trash") ? "../icons/restore_notes.svg" : "../icons/unarchive.svg"
                            anchors.fill: parent
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: pageMode === qsTr("trash") ? qsTr("Restore") : qsTr("Unarchive")
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

                        if (pageMode === qsTr("trash")) {
                            message = qsTr("Are you sure you want to restore %1 selected notes to your main notes?").arg(selectedNoteIds.length);
                            confirmTitle = qsTr("Confirm Restoration");
                            confirmButton = qsTr("Restore");
                            callbackFunction = function() {
                                var restoredCount = selectedNoteIds.length;
                                DB.restoreNotes(selectedNoteIds);
                                refreshNotes();
                                toastManager.show(qsTr("%1 note(s) restored!").arg(restoredCount));
                                console.log("%1 note(s) restored from trash.".arg(restoredCount));
                            };
                        } else if (pageMode === qsTr("archive")) {
                            message = qsTr("Are you sure you want to unarchive %1 selected notes?").arg(selectedNoteIds.length);
                            confirmTitle = qsTr("Confirm Unarchive");
                            confirmButton = qsTr("Unarchive");
                            callbackFunction = function() {
                                var unarchivedCount = selectedNoteIds.length;
                                DB.bulkUnarchiveNotes(selectedNoteIds);
                                refreshNotes();
                                toastManager.show(qsTr("%1 note(s) unarchived!").arg(unarchivedCount));
                                console.log("%1 note(s) unarchived.".arg(unarchivedCount));
                            };
                        }

                        archivePage.showConfirmDialog(
                            message,
                            callbackFunction,
                            confirmTitle,
                            confirmButton,
                            highlight
                        );
                        console.log("Showing confirmation dialog for %1 notes in %2 mode.".arg(selectedNoteIds.length).arg(pageMode));
                    }
                }
                enabled: selectedNoteIds.length > 0
            }

            Button {
                id: deleteSelectedButton
                visible: archivePage.pageMode === qsTr("trash")
                width: parent.calculatedButtonWidth
                highlightColor: Theme.errorColor

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
                                refreshNotes();
                                toastManager.show(qsTr("%1 note(s) permanently deleted!").arg(deletedCount));
                                console.log("%1 note(s) permanently deleted.".arg(deletedCount));
                            },
                            qsTr("Confirm Permanent Deletion"),
                            qsTr("Delete Permanently"),
                            Theme.errorColor
                        );
                        console.log("Showing permanent delete confirmation dialog for %1 notes.".arg(selectedNoteIds.length));
                    }
                }
                enabled: selectedNoteIds.length > 0
            }
        }

        Item {
            id: selectionSpacer
            Layout.fillWidth: true
            Layout.preferredHeight: selectionControlsVisible ? Theme.paddingMedium : 0
            visible: selectionControlsVisible
        }

        SilicaFlickable {
            id: notesFlickable
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height
                                  - selectionControls.height
                                  - selectionSpacer.height
            contentHeight: notesColumn.implicitHeight
            clip: true

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

                        TrashArchiveNoteCard {
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
                            tags: modelData.tags ? modelData.tags.join("_||_") : ''
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
                                console.log("Toggled selection for note ID: %1. Current selected: %2".arg(noteId).arg(JSON.stringify(archivePage.selectedNoteIds)));
                            }

                            onNoteClicked: {
                                console.log("UNIFIED_NOTES_PAGE: Opening NotePage for note ID: %1 from %2.".arg(noteId).arg(archivePage.pageMode));
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
                                    isArchived: archivePage.pageMode === qsTr("archive"),
                                    isDeleted: archivePage.pageMode === qsTr("trash")
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

    ConfirmDialog {
        id: confirmDialogInstance
        dialogVisible: archivePage.confirmDialogVisible
        dialogTitle: archivePage.confirmDialogTitle
        dialogMessage: archivePage.confirmDialogMessage
        confirmButtonText: archivePage.confirmButtonText
        confirmButtonHighlightColor: archivePage.confirmButtonHighlightColor

        onConfirmed: {
            if (archivePage.onConfirmCallback) {
                archivePage.onConfirmCallback();
            }
            archivePage.confirmDialogVisible = false;
        }
        onCancelled: {
            archivePage.confirmDialogVisible = false;
            console.log("Action cancelled by user.");
        }
    }
    Label {
        id: emptyLabel
        visible: archivePage.showEmptyLabel
        text: pageMode === qsTr("trash") ? qsTr("Trash is empty.") : qsTr("Archive is empty.")
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

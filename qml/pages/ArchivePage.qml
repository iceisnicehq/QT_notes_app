// unifiedNotesPage.qml

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB

Page {
    id: unifiedNotesPage
    backgroundColor: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#121218"
    showNavigationIndicator: false

    property string pageMode: "archive"

    property var notesToDisplay: []
    property var selectedNoteIds: []
    property string dialogMessage: ""

    property bool showEmptyLabel: notesToDisplay.length === 0
    property bool selectionControlsVisible: notesToDisplay.length > 0

    // Новое вспомогательное свойство для определения, выбраны ли все заметки
    property bool allNotesSelected: (selectedNoteIds.length === notesToDisplay.length) && (notesToDisplay.length > 0)


    Component.onCompleted: {
        console.log(qsTr("UNIFIED_NOTES_PAGE: UnifiedNotesPage opened in %1 mode. Calling refreshNotes.").arg(pageMode));
        refreshNotes();
    }

    function refreshNotes() {
        if (pageMode === "trash") {
            notesToDisplay = DB.getDeletedNotes();
            console.log(qsTr("DB_MGR: getDeletedNotes found %1 deleted notes.").arg(notesToDisplay.length));
        } else if (pageMode === "archive") {
            notesToDisplay = DB.getArchivedNotes();
            console.log(qsTr("DB_MGR: getArchivedNotes found %1 archived notes.").arg(notesToDisplay.length));
        }
        selectedNoteIds = [];
        console.log(qsTr("UNIFIED_NOTES_PAGE: refreshNotes completed for %1. Count: %2").arg(pageMode).arg(notesToDisplay.length));
    }

    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        Label {
            text: pageMode === "trash" ? qsTr("Trash") : qsTr("Archive")
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
                // *** ИЗМЕНЕНИЕ ЗДЕСЬ: Динамическая иконка ***
                icon.source: unifiedNotesPage.allNotesSelected ? "../icons/deselect_all.svg" : "../icons/select_all.svg"
                onClicked: {
                    var newSelectedIds = [];
                    // Используем вспомогательное свойство allNotesSelected
                    if (!unifiedNotesPage.allNotesSelected) { // Если не все выбраны, выбираем все
                        for (var i = 0; i < unifiedNotesPage.notesToDisplay.length; i++) {
                            newSelectedIds.push(unifiedNotesPage.notesToDisplay[i].id);
                        }
                    } // Иначе newSelectedIds останется пустым, что развыберет все

                    unifiedNotesPage.selectedNoteIds = newSelectedIds; // Переназначить для обновления QML
                    console.log(qsTr("Selected note IDs after Select All/Deselect All: %1").arg(JSON.stringify(unifiedNotesPage.selectedNoteIds)));
                }
                enabled: notesToDisplay.length > 0
            }

            Button {
                id: primaryActionButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: pageMode === "trash" ? "../icons/restore_notes.svg" : "../icons/unarchive.svg"
                text: pageMode === "trash" ? qsTr("Restore") : qsTr("Unarchive")
                highlightColor: Theme.highlightColor
                enabled: selectedNoteIds.length > 0
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        if (pageMode === "trash") {
                            DB.restoreNotes(selectedNoteIds);
                            toastManager.show(qsTr("%1 note(s) restored!").arg(selectedNoteIds.length));
                            console.log(qsTr("%1 note(s) restored from trash.").arg(selectedNoteIds.length));
                        } else if (pageMode === "archive") {
                            DB.bulkUnarchiveNotes(selectedNoteIds);
                            toastManager.show(qsTr("%1 note(s) unarchived!").arg(selectedNoteIds.length));
                            console.log(qsTr("%1 note(s) unarchived.").arg(selectedNoteIds.length));
                        }
                        refreshNotes();
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
            id: notesFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentHeight: notesColumn.implicitHeight + (unifiedNotesPage.showEmptyLabel ? 0 : Theme.paddingLarge * 2)

            Column {
                id: notesColumn
                width: parent.width
                spacing: Theme.paddingMedium
                visible: !unifiedNotesPage.showEmptyLabel
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium

                Repeater {
                    model: notesToDisplay
                    delegate: Column {
                        width: parent.width
                        spacing: Theme.paddingLarge

                        TrashNoteCard {
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
                            tags: modelData.tags ? modelData.tags.join(' ') : ''
                            cardColor: modelData.color || "#1c1d29"
                            height: implicitHeight
                            isSelected: unifiedNotesPage.selectedNoteIds.indexOf(modelData.id) !== -1

                            onSelectionToggled: {
                                if (isCurrentlySelected) {
                                    var index = unifiedNotesPage.selectedNoteIds.indexOf(noteId);
                                    if (index !== -1) {
                                        unifiedNotesPage.selectedNoteIds.splice(index, 1);
                                    }
                                } else {
                                    if (unifiedNotesPage.selectedNoteIds.indexOf(noteId) === -1) {
                                        unifiedNotesPage.selectedNoteIds.push(noteId);
                                    }
                                }
                                unifiedNotesPage.selectedNoteIds = unifiedNotesPage.selectedNoteIds;
                                console.log(qsTr("Toggled selection for note ID: %1. Current selected: %2").arg(noteId).arg(JSON.stringify(unifiedNotesPage.selectedNoteIds)));
                            }

                            onNoteClicked: {
                                console.log(qsTr("UNIFIED_NOTES_PAGE: Opening NotePage for note ID: %1 from %2.").arg(noteId).arg(unifiedNotesPage.pageMode));
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: unifiedNotesPage.refreshNotes,
                                    noteId: noteId,
                                    noteTitle: title,
                                    noteContent: content,
                                    noteIsPinned: isPinned,
                                    noteTags: tags,
                                    noteCreationDate: creationDate,
                                    noteEditDate: editDate,
                                    noteColor: color,
                                    isArchived: unifiedNotesPage.pageMode === "archive",
                                    isDeleted: unifiedNotesPage.pageMode === "trash"
                                });
                            }
                        }
                    }
                }
            }

            Label {
                id: emptyLabel
                visible: unifiedNotesPage.showEmptyLabel
                text: pageMode === "trash" ? qsTr("Trash is empty.") : qsTr("Archive is empty.")
                font.italic: true
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
            }
        }
        ScrollBar {
            flickableSource: notesFlickable
        }
    }
    ToastManager {
        id: toastManager
    }
}

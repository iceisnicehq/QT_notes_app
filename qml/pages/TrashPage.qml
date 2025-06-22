/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/pages/TrashPage.qml
 * Эта страница отображает заметки, которые были перемещены в корзину.
 * Функционал.
 * - Отображение удаленных заметок: выводит список заметок из корзины.
 * - Автоматическая очистка: при загрузке страницы вызывает функцию
 * для окончательного удаления заметок, находящихся в корзине более
 * 30 дней.
 * - Массовые действия: позволяет пользователям выбирать несколько
 * заметок для их восстановления или окончательного удаления.
 * - Информационный заголовок: уведомляет пользователя о 30-дневном
 * сроке хранения заметок в корзине.
 */

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
    backgroundColor: trashPage.customBackgroundColor !== undefined ? trashPage.customBackgroundColor : "#121218"
    showNavigationIndicator: false
    property string customBackgroundColor: DB.getThemeColor() || "#121218"
    property int noteMargin: 20

    property var deletedNotes: []
    property var selectedNoteIds: []
    property bool panelOpen: false

    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Deletion")
    property string confirmDialogMessage: ""
    property string confirmButtonText: qsTr("Delete")
    property var onConfirmCallback: null
    property color confirmButtonHighlightColor: Theme.errorColor


    Component.onCompleted: {
        console.log("TRASH_PAGE: TrashPage opened. Initializing DB and calling refreshDeletedNotes.");
        DB.initDatabase(LocalStorage);
        DB.permanentlyDeleteExpiredDeletedNotes();
        refreshDeletedNotes();
        console.log("TRASH_PAGE: Deleted notes after refresh. Count: " + deletedNotes.length);
        sidePanelInstance.currentPage = "trash";
    }

    function refreshDeletedNotes() {
        deletedNotes = DB.getDeletedNotes();
        selectedNoteIds = [];
        console.log("DB_MGR: getDeletedNotes found " + deletedNotes.length + " deleted notes.");
        console.log("TRASH_PAGE: refreshDeletedNotes completed. Count: " + deletedNotes.length);
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

            Icon {
                id: leftIcon
                source: trashPage.selectedNoteIds.length > 0 ? "../icons/close.svg" : "../icons/menu.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY)
                onClicked: {

                    if (trashPage.selectedNoteIds.length > 0) {
                        trashPage.selectedNoteIds = [];
                        console.log("Selected notes cleared.");
                    } else {
                        trashPage.panelOpen = true
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
            font.pixelSize: Theme.fontSizeSmall * 0.9
            font.italic: true
            color: Theme.secondaryColor
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: titleLabel.bottom
            anchors.topMargin: Theme.paddingSmall
            width: parent.width * 0.9
            wrapMode: Text.Wrap
        }

    }


    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: pageHeader.bottom
        anchors.bottom: parent.bottom
        spacing: 0

        Row {
            id: selectionControls
            Layout.fillWidth: true
            height: selectionControlsVisible ? Theme.buttonHeightSmall + Theme.paddingSmall : 0
            visible: selectionControlsVisible
            spacing: Theme.paddingSmall

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: trashPage.noteMargin
            anchors.rightMargin: trashPage.noteMargin
            property real calculatedButtonWidth: (trashPage.width) /  3.23

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
                            source: trashPage.allNotesSelected ? "../icons/deselect_all.svg" : "../icons/select_all.svg"
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
                width: parent.calculatedButtonWidth
                highlightColor: Theme.highlightColor


                Column {
                    anchors.centerIn: parent

                    Item {
                        width: Theme.fontSizeExtraLarge * 0.9
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/restore_notes.svg"
                            anchors.fill: parent
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
                            qsTr("Confirm Restoration"),
                            qsTr("Restore"),
                            Theme.highlightColor
                        );
                        console.log("Showing restore confirmation dialog for " + selectedNoteIds.length + " notes.");
                    }
                }
                enabled: selectedNoteIds.length > 0
            }

            Button {
                id: deleteSelectedButton
                width: parent.calculatedButtonWidth
                highlightColor: Theme.errorColor


                Column {
                    anchors.centerIn: parent

                    Item {
                        width: Theme.fontSizeExtraLarge * 0.9
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/perma_delete.svg"
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
                        trashPage.showConfirmDialog(
                            message,
                            function() {
                                console.log("CONFIRMATION: selectedNoteIds contents:", JSON.stringify(selectedNoteIds));
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

        Item {
            id: selectionSpacer
            Layout.fillWidth: true
            Layout.preferredHeight: selectionControlsVisible ? Theme.paddingMedium : 0
            visible: selectionControlsVisible
        }

        SilicaFlickable {
            id: trashFlickable
            Layout.fillWidth: true

            Layout.preferredHeight: parent.height
                                  - selectionControls.height
                                  - selectionSpacer.height
            contentHeight: trashColumn.implicitHeight
            clip: true

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
                        spacing: Theme.paddingSmall

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
                            height: implicitHeight

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

    ConfirmDialog {
        id: confirmDialogInstance
        dialogVisible: trashPage.confirmDialogVisible
        dialogTitle: trashPage.confirmDialogTitle
        dialogMessage: trashPage.confirmDialogMessage
        confirmButtonText: trashPage.confirmButtonText
        confirmButtonHighlightColor: trashPage.confirmButtonHighlightColor
        dialogBackgroundColor: DB.darkenColor(trashPage.customBackgroundColor, 0.30)

        onConfirmed: {
            if (trashPage.onConfirmCallback) {
                trashPage.onConfirmCallback();
            }
            trashPage.confirmDialogVisible = false;
        }
        onCancelled: {
            trashPage.confirmDialogVisible = false;
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

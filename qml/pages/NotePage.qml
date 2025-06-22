/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/pages/NotePage.qml
 * Эта страница является основной для создания, просмотра и редактирования
 * отдельной заметки. Она обладает высокой степенью адаптивности и
 * обрабатывает множество сценариев, включая создание новой заметки,
 * редактирование существующей и режим "только для чтения" для заметок
 * из архива или корзины.
 *
 * Ключевые функции:
 * - Обработка взаимодействия: при попытке редактирования архивированной
 * или удаленной заметки предлагает пользователю восстановить ее.
 * - История изменений: реализует механизм отмены (Undo) и повтора (Redo)
 * для текстового содержимого.
 * - Управление свойствами: управляет заголовком, содержанием, тегами,
 * цветом и статусом закрепления заметки.
 * - Логика сохранения: автоматически сохраняет изменения при закрытии,
 * создает новую заметку или удаляет пустую.
 * - Пользовательский интерфейс: включает заголовок, нижнюю панель
 * инструментов с кнопками действий и всплывающие панели для выбора
 * цвета и управления тегами.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "../services/DatabaseManagerService.js" as DB
import "../dialogs"
import "../components"
import "../services"

Page {
    id: newNotePage
    backgroundColor: newNotePage.noteColor
    showNavigationIndicator: false
    property var onNoteSavedOrDeleted: null
    property int noteId: -1
    property string noteTitle: ""
    property string noteContent: ""
    property var noteTags: []
    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()
    property string noteColor: "#121218"
    property bool noteModified: false
    property bool isFromTrash: false

    property bool isArchived: false
    property bool isDeleted: false
    property bool isReadOnly: isArchived || isDeleted

    property bool sentToTrash: false
    property bool sentToArchive: false

    property var contentHistory: []
    property int historyIndex: -1
    property bool isUndoingRedoing: false

    property bool confirmDialogVisible: false
    property string confirmDialogTitle: ""
    property string confirmDialogMessage: ""
    property string confirmButtonText: ""
    property color confirmButtonHighlightColor: Theme.primaryColor
    property var onConfirmCallback: null


    Timer {
        id: historySaveTimer
        interval: 1000
        running: !newNotePage.isReadOnly
        repeat: true
        onTriggered: {
            if (!newNotePage.isUndoingRedoing &&
                newNotePage.contentHistory.length > 0 &&
                noteContentInput.text !== newNotePage.contentHistory[newNotePage.historyIndex].text) {
                newNotePage.addToContentHistory(noteContentInput.text, noteContentInput.cursorPosition);
                console.log("History auto-saved: \"%1\" (cursor: %2)".arg(noteContentInput.text).arg(noteContentInput.cursorPosition));
            } else if (!newNotePage.isUndoingRedoing && newNotePage.contentHistory.length === 0) {
                if (noteContentInput.text !== "") {
                    newNotePage.addToContentHistory(noteContentInput.text, noteContentInput.cursorPosition);
                    console.log("Initial history state added by timer: \"%1\" (cursor: %2)".arg(noteContentInput.text).arg(noteContentInput.cursorPosition));
                }
            }
        }
    }

    function showGeneralConfirmDialog(message, callback, title, buttonText, highlightColor) {
        newNotePage.confirmDialogMessage = message;
        newNotePage.onConfirmCallback = callback;
        newNotePage.confirmDialogTitle = title !== undefined ? title : qsTr("Confirm Action");
        newNotePage.confirmButtonText = buttonText !== undefined ? buttonText : qsTr("Confirm");
        newNotePage.confirmButtonHighlightColor = highlightColor !== undefined ? highlightColor : Theme.primaryColor;
        newNotePage.confirmDialogVisible = true;
    }

    function handleInteractionAttempt() {
        var needsAction = newNotePage.isDeleted || newNotePage.isArchived;
        if (needsAction) {
            newNotePage.isReadOnly = true;

            var message = "";
            var title = "";
            var buttonText = "";
            var highlight = Theme.primaryColor;
            var callbackFunction;

            if (newNotePage.isDeleted) {
                title = qsTr("Cannot Edit Deleted Note");
                message = qsTr("To edit this note, you need to restore it first.");
                buttonText = qsTr("Restore");
                callbackFunction = function() {
                    DB.restoreNote(newNotePage.noteId);
                    newNotePage.isDeleted = false;
                    newNotePage.isReadOnly = false;
                    toastManager.show(qsTr("Note restored!"));
                    if (onNoteSavedOrDeleted) {
                        onNoteSavedOrDeleted();
                    }
                    noteContentInput.forceActiveFocus();
                };
            } else if (newNotePage.isArchived) {
                title = qsTr("Cannot Edit Archived Note");
                message = qsTr("To edit this note, you need to unarchive it first.");
                buttonText = qsTr("Unarchive");
                callbackFunction = function() {
                    DB.unarchiveNote(newNotePage.noteId);
                    newNotePage.isArchived = false;
                    newNotePage.isReadOnly = false;
                    toastManager.show(qsTr("Note unarchived!"));
                    if (onNoteSavedOrDeleted) {
                        onNoteSavedOrDeleted();
                    }
                    noteContentInput.forceActiveFocus();
                };
            }
            newNotePage.showGeneralConfirmDialog(message, callbackFunction, title, buttonText, highlight);
            return false;
        }
        newNotePage.isReadOnly = false;
        return true;
    }


    function addToContentHistory(content, cursorPos) {
        if (newNotePage.isUndoingRedoing || newNotePage.isReadOnly) {
            return;
        }

        if (newNotePage.historyIndex < newNotePage.contentHistory.length - 1) {
            newNotePage.contentHistory.splice(newNotePage.historyIndex + 1);
        }

        newNotePage.contentHistory.push({ text: content, cursorPosition: cursorPos });
        newNotePage.historyIndex = newNotePage.contentHistory.length - 1;

        const MAX_HISTORY_SIZE = 100;
        if (newNotePage.contentHistory.length > MAX_HISTORY_SIZE) {
            newNotePage.contentHistory.shift();
            newNotePage.historyIndex--;
        }

        console.log("Added to history: \"%1\"".arg(content), "History size: %1".arg(newNotePage.contentHistory.length), "Current index: %1".arg(newNotePage.historyIndex));
    }

    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]

    Component.onCompleted: {
        console.log("NewNotePage opened. ReadOnly mode: %1, isArchived: %2, isDeleted: %3".arg(newNotePage.isReadOnly).arg(newNotePage.isArchived).arg(newNotePage.isDeleted));
        if (noteId !== -1) {
            noteTitleInput.text = noteTitle;
            noteContentInput.text = noteContent;
            if (typeof noteTags === 'string') {
                newNotePage.noteTags = noteTags.split("_||_").filter(function(tag) { return tag.length > 0; });
            }
            console.log("NewNotePage opened in EDIT mode for ID: %1".arg(noteId));
            console.log("Note color on open: %1".arg(noteColor));
            noteModified = false;
        } else {
            noteContentInput.forceActiveFocus();
            Qt.inputMethod.show();
            console.log("NewNotePage opened in CREATE mode. Default color: %1".arg(noteColor));
            noteModified = true;
        }
        if (!newNotePage.isReadOnly) {
            newNotePage.addToContentHistory(noteContentInput.text, noteContentInput.cursorPosition);
            console.log("Initial history state: Index %1, History: %2".arg(newNotePage.historyIndex).arg(JSON.stringify(newNotePage.contentHistory)));
        } else {
            console.log("Note in read-only mode, history not initialized.");
        }
    }

    Component.onDestruction: {
        console.log("NewNotePage being destroyed. Attempting to save/delete note.");
        var trimmedTitle = noteTitleInput.text.trim();
        var trimmedContent = noteContentInput.text.trim();

        if (newNotePage.isReadOnly) {
            console.log("Debug: In read-only mode. Skipping save/delete on destruction.");
        } else if (sentToTrash || sentToArchive) {
            console.log("Debug: Note already sent to trash/archive. Skipping save/delete on destruction.");
        } else if (trimmedTitle === "" && trimmedContent === "" && newNotePage.noteTags.length === 0 && !newNotePage.noteIsPinned) {
            if (noteId !== -1) {
                DB.permanentlyDeleteNote(noteId);
                console.log("Debug: Empty existing note permanently deleted with ID: %1".arg(noteId));
            } else {
                console.log("Debug: New empty note not saved.");
            }
        } else {
            if (noteId === -1) {
                newNotePage.noteTitle = noteTitleInput.text;
                newNotePage.noteContent = noteContentInput.text;
                if (newNotePage.noteTitle === "" && newNotePage.noteContent === "") {
                    console.log("Debug: New empty note not saved.")
                }
                else {
                    var newId = DB.addNote(noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                    console.log("Debug: New note added with ID: %1, Color: %2, Tags: %3".arg(newId).arg(noteColor).arg(JSON.stringify(noteTags)));
                }
           } else {
                if (noteModified) {
                    newNotePage.noteTitle = noteTitleInput.text;
                    newNotePage.noteContent = noteContentInput.text;
                    newNotePage.noteEditDate = new Date();
                    DB.updateNote(noteId, noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                    console.log("Debug: Note updated with ID: %1, Color: %2, Tags: %3".arg(noteId).arg(noteColor).arg(JSON.stringify(noteTags)));
                } else {
                    console.log("Debug: Note with ID: %1 not modified, skipping update.".arg(noteId));
                }
            }
        }
        if (onNoteSavedOrDeleted) {
            onNoteSavedOrDeleted();
        }
    }

    ToastManagerService {
        id: toastManager
    }

    Rectangle {
        id: header
        width: parent.width
        height: Theme.itemSizeMedium
        color: newNotePage.noteColor
        anchors.top: parent.top
        z: 2
        Column {
            anchors.centerIn: parent
            Label {
                text: newNotePage.noteId === -1 ? qsTr("New Note") : qsTr("Edit Note")
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
            }
            Column {
                visible: newNotePage.noteId !== -1
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    text: qsTr("Created: %1").arg(Qt.formatDateTime(newNotePage.noteCreationDate, "dd.MM.yyyy - hh:mm"))
                    font.pixelSize: Theme.fontSizeExtraSmall * 0.7
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    property string statusPrefix: {
                        if (newNotePage.isDeleted) {
                            return qsTr("Deleted: %1");
                        } else if (newNotePage.isArchived) {
                            return qsTr("Archived: %1");
                        } else {
                            return qsTr("Edited: %1");
                        }
                    }

                    text: statusPrefix.arg(Qt.formatDateTime(newNotePage.noteEditDate, "dd.MM.yyyy - hh:mm"))
                    font.pixelSize: Theme.fontSizeExtraSmall * 0.7
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }

            }
        }
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
            RippleEffectComponent { id: backRipple }
            Icon {
                id: closeButton
                source: {
                        if (newNotePage.noteId === -1) {
                        if (noteTitleInput.text.trim() === "" && noteContentInput.text.trim() === "") {
                            return "qrc:/qml/icons/close.svg";
                        } else {
                            return "qrc:/qml/icons/check.svg";
                        }
                    } else {
                        return "qrc:/qml/icons/back.svg";
                    }
                }
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }
            MouseArea {
                anchors.fill: parent
                onPressed: backRipple.ripple(mouseX, mouseY)
                onClicked: {
                        pageStack.pop();

                }
            }
        }
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.paddingLarge }
            RippleEffectComponent { id: pinRipple }
            Icon {
                id: pinIconButton
                source: noteIsPinned ? "qrc:/qml/icons/pin-enabled.svg" : "qrc:/qml/icons/pin.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                opacity: 1.0
                color: newNotePage.isReadOnly ? Theme.secondaryColor : Theme.primaryColor
            }
            MouseArea {
                anchors.fill: parent
                enabled: true
                onPressed: pinRipple.ripple(mouseX, mouseY)
                onClicked: {
                    if (handleInteractionAttempt()) {
                        noteIsPinned = !noteIsPinned;
                        newNotePage.noteModified = true;
                        var msg = noteIsPinned ? qsTr("The note was pinned") : qsTr("The note was unpinned")
                        toastManager.show(msg)
                    }
                }
            }
        }
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { right: pinIconButton.parent.left; verticalCenter: parent.verticalCenter; rightMargin: Theme.paddingMedium }
            RippleEffectComponent { id: duplicateRipple }
            Icon {
                id: duplicateIconButton
                source: "qrc:/qml/icons/copy.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                opacity: (newNotePage.noteId !== -1) ? 1.0 : 0.5
                color: (newNotePage.noteId !== -1) ? (newNotePage.isReadOnly ? Theme.secondaryColor : Theme.primaryColor) : Theme.secondaryColor
            }
            MouseArea {
                anchors.fill: parent
                enabled: newNotePage.noteId !== -1
                onPressed: duplicateRipple.ripple(mouseX, mouseY)
                onClicked: {
                    if (newNotePage.noteId === -1) {
                         toastManager.show(qsTr("Cannot duplicate a new note. Save it first."));
                         return;
                    }
                    if (handleInteractionAttempt()) {
                        newNotePage.showGeneralConfirmDialog(
                            qsTr("Do you want to create a copy of this note?"),
                            function() {
                                console.log("Duplicate button clicked for note ID: %1 (confirmed)".arg(newNotePage.noteId));
                                pageStack.replace(Qt.resolvedUrl("../pages/NotePage.qml"), {
                                   onNoteSavedOrDeleted: newNotePage.onNoteSavedOrDeleted,
                                   noteId: -1,
                                   noteTitle: newNotePage.noteTitle + qsTr(" (copy)"),
                                   noteContent: newNotePage.noteContent,
                                   noteIsPinned: newNotePage.noteIsPinned,
                                   noteTags: Array.isArray(newNotePage.noteTags) ? newNotePage.noteTags.slice() : [],
                                   noteColor: newNotePage.noteColor,
                                   noteCreationDate: new Date(),
                                   noteEditDate: new Date(),
                                   noteModified: true
                                });
                                toastManager.show(qsTr("Note duplicated!"));
                            },
                            qsTr("Confirm Duplicate"),
                            qsTr("Duplicate"),
                            Theme.positiveColor
                        );
                        console.log("Showing duplicate confirmation dialog for note ID: %1".arg(newNotePage.noteId));
                    }
                }
            }
        }
    }

    Rectangle {
        id: bottomToolbar
        width: parent.width
        height: Theme.itemSizeSmall
        anchors.bottom: parent.bottom
        color: newNotePage.noteColor
        z: 11.75
        y: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.y - height) : (parent.height - height)
        Behavior on y {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Row {
            id: leftToolbarButtons
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffectComponent { id: paletteRipple }
                Icon {
                    id: paletteIcon
                    source: "qrc:/qml/icons/palette.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    opacity: 1.0
                    color: newNotePage.isReadOnly ? Theme.secondaryColor : Theme.primaryColor
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: true
                    onPressed: paletteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (handleInteractionAttempt()) {
                            console.log("Change color/theme - toggling panel visibility");
                            if (colorSelectionPanel.opacity > 0.01) {
                                colorSelectionPanel.opacity = 0;
                            } else {
                                colorSelectionPanel.opacity = 1;
                            }
                        }
                    }
                }
            }
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffectComponent { id: addTagRipple }
                Icon {
                    id: addTagIcon
                    source: "qrc:/qml/icons/tag.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    opacity: 1.0
                    color: newNotePage.isReadOnly ? Theme.secondaryColor : Theme.primaryColor
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: true
                    onPressed: addTagRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (handleInteractionAttempt()) {
                            console.log("Add Tag button clicked. Opening tag selection panel.");
                            if (tagSelectionPanel.opacity > 0.01) {
                                tagSelectionPanel.opacity = 0;
                            } else {
                                tagSelectionPanel.opacity = 1;
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: centerToolbarButtons
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.paddingMedium

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffectComponent { id: undoRipple }
                Icon {
                    id: undoIcon
                    source: "qrc:/qml/icons/undo.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    opacity: (newNotePage.historyIndex > 0) ? 1.0 : 0.5
                    color: (newNotePage.historyIndex > 0) ? Theme.primaryColor : Theme.secondaryColor
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: (newNotePage.historyIndex > 0 && !newNotePage.isReadOnly)
                    onPressed: undoRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (handleInteractionAttempt()) {
                            console.log("Undo action triggered!");
                            if (newNotePage.historyIndex > 0) {
                                newNotePage.isUndoingRedoing = true;
                                newNotePage.historyIndex--;
                                var historicalState = newNotePage.contentHistory[newNotePage.historyIndex];
                                noteContentInput.text = historicalState.text;
                                noteContentInput.cursorPosition = historicalState.cursorPosition;
                                newNotePage.isUndoingRedoing = false;
                                newNotePage.noteModified = true;
                                toastManager.show(qsTr("Undo successful!"));
                            } else {
                                toastManager.show(qsTr("Nothing to undo."));
                            }
                        }
                    }
                }
            }
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffectComponent { id: redoRipple }
                Icon {
                    id: redoIcon
                    source: "qrc:/qml/icons/redo.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    opacity: (newNotePage.historyIndex < newNotePage.contentHistory.length - 1) ? 1.0 : 0.5
                    color: (newNotePage.historyIndex < newNotePage.contentHistory.length - 1) ? Theme.primaryColor : Theme.secondaryColor
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: (newNotePage.historyIndex < newNotePage.contentHistory.length - 1 && !newNotePage.isReadOnly)
                    onPressed: redoRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (handleInteractionAttempt()) {
                            console.log("Redo action triggered!");
                            if (newNotePage.historyIndex < newNotePage.contentHistory.length - 1) {
                                newNotePage.isUndoingRedoing = true;
                                newNotePage.historyIndex++;
                                var historicalState = newNotePage.contentHistory[newNotePage.historyIndex];
                                noteContentInput.text = historicalState.text;
                                noteContentInput.cursorPosition = historicalState.cursorPosition;
                                newNotePage.isUndoingRedoing = false;
                                newNotePage.noteModified = true;
                                toastManager.show(qsTr("Redo successful!"));
                            } else {
                                toastManager.show(qsTr("Nothing to redo."));
                            }
                        }
                    }
                }
            }
        }


        Row {
            id: rightToolbarButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffectComponent { id: archiveRipple }
                Icon {
                    id: archiveIcon
                    source: "qrc:/qml/icons/archive.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    color: (newNotePage.noteId === -1 || newNotePage.isArchived) ? Theme.secondaryColor : Theme.primaryColor
                    opacity: (newNotePage.noteId === -1 || newNotePage.isArchived) ? 0.1 : 1.0
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: newNotePage.noteId !== -1
                    onPressed: archiveRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (newNotePage.noteId === -1) {
                            toastManager.show(qsTr("Cannot archive a new note. Save it first."));
                            return;
                        }
                        if (newNotePage.isArchived) {
                            toastManager.show(qsTr("Note is already archived"));
                            return;
                        } else {
                            newNotePage.showGeneralConfirmDialog(
                                qsTr("Do you want to archive this note?"),
                                function() {
                                    if (newNotePage.noteId !== -1) {
                                        DB.archiveNote(newNotePage.noteId);
                                        console.log("Note ID: %1 moved to archive after confirmation.".arg(newNotePage.noteId));
                                        newNotePage.sentToArchive = true;
                                        toastManager.show(qsTr("Note archived!"));
                                        if (onNoteSavedOrDeleted) {
                                            onNoteSavedOrDeleted();
                                        }
                                    } else {
                                        console.log("New unsaved note discarded without archiving.");
                                    }
                                    pageStack.pop();
                                },
                                qsTr("Confirm Archive"),
                                qsTr("Archive"),
                                Theme.primaryColor
                            );
                        }
                    }
                }
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffectComponent { id: deleteRipple }
                Icon {
                    id: deleteIcon
                    source: "qrc:/qml/icons/delete.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    color: (newNotePage.noteId === -1 || newNotePage.isDeleted) ? Theme.secondaryColor : Theme.negativeColor
                    opacity: (newNotePage.noteId === -1 || newNotePage.isDeleted) ? 0.1 : 1.0
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: newNotePage.noteId !== -1
                    onPressed: deleteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (newNotePage.noteId === -1) {
                            toastManager.show(qsTr("Cannot delete a new note. Save it first."));
                            return;
                        }
                        if (newNotePage.isDeleted) {
                            toastManager.show(qsTr("Note is already in the trash"));
                            return;
                        }
                        else {
                            newNotePage.showGeneralConfirmDialog(
                                qsTr("Do you want to move this note to trash?"),
                                function() {
                                    if (newNotePage.noteId !== -1) {
                                        DB.deleteNote(newNotePage.noteId);
                                        console.log("Note ID: %1 moved to trash after confirmation.".arg(newNotePage.noteId));
                                        newNotePage.sentToTrash = true;
                                        toastManager.show(qsTr("Note moved to trash!"));
                                        if (onNoteSavedOrDeleted) {
                                            onNoteSavedOrDeleted();
                                        }
                                    } else {
                                        console.log("New unsaved note discarded without deletion.");
                                    }
                                    pageStack.pop();
                                },
                                qsTr("Confirm Delete"),
                                qsTr("Delete"),
                                Theme.negativeColor
                            );
                        }
                    }
                }
            }
        }
    }

    SilicaFlickable {
        id: mainContentFlickable
        anchors.fill: parent
        anchors.topMargin: header.height
        anchors.bottomMargin: bottomToolbar.height + (Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0)
        contentHeight: contentColumn.implicitHeight

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Column {
            id: contentColumn
            width: parent.width * 0.98
            anchors.horizontalCenter: parent.horizontalCenter

            TextField {
                id: noteTitleInput
                width: parent.width
                placeholderText: qsTr("Title")
                text: newNotePage.noteTitle
                readOnly: newNotePage.isReadOnly
                onTextChanged: {
                    newNotePage.noteTitle = text;
                    newNotePage.noteModified = true;
                }
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
                font.bold: true
                wrapMode: Text.Wrap
                inputMethodHints: Qt.ImhNoAutoUppercase
                maximumLength: 256
            }

            TextArea {
                id: noteContentInput
                width: parent.width
                height: implicitHeight > 0 ? implicitHeight : Theme.itemSizeExtraLarge * 3
                placeholderText: qsTr("Note")
                text: newNotePage.noteContent
                readOnly: newNotePage.isReadOnly
                onTextChanged: {
                    newNotePage.noteContent = text;
                    newNotePage.noteModified = true;
                }
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                color: "#e8eaed"
                verticalAlignment: Text.AlignTop
            }

            Flow {
                id: tagsFlow
                width: parent.width
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.paddingMedium
                visible: newNotePage.noteTags.length > 0
                Repeater {
                    model: newNotePage.noteTags
                    delegate: Rectangle {
                        id: tagRectangle
                        property color normalColor: "#a032353a"
                        property color pressedColor: "#c050545a"
                        color: normalColor
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium, parent.width)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.centerIn: parent
                            elide: Text.ElideRight
                            width: parent.width - Theme.paddingMedium
                            wrapMode: Text.NoWrap
                            textFormat: Text.PlainText
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: true
                            onPressed: tagRectangle.color = tagRectangle.pressedColor
                            onReleased: {
                                tagRectangle.color = tagRectangle.normalColor
                                console.log("Tag clicked for editing: %1".arg(modelData))
                                Qt.inputMethod.hide();
                                if (handleInteractionAttempt()) {
                                    if (tagSelectionPanel.opacity > 0.01) {
                                        tagSelectionPanel.opacity = 0;
                                    } else {
                                        tagSelectionPanel.opacity = 1;
                                    }
                                }
                            }
                            onCanceled: tagRectangle.color = tagRectangle.normalColor
                        }
                    }
                }
            }

            Item { width: parent.width; height: Theme.paddingLarge * 2 }
        }

        MouseArea {
            anchors.fill: contentColumn
            visible: newNotePage.isReadOnly
            onClicked: {
                handleInteractionAttempt();
            }
        }


        Label {
            id: noTagsLabel
            text: qsTr("No tags")
            font.italic: true
            visible: newNotePage.noteTags.length === 0 && !newNotePage.isReadOnly
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: contentColumn.bottom
            MouseArea {
                anchors.fill: parent
                enabled: true
                onClicked: {
                    if (handleInteractionAttempt()) {
                        console.log("Add Tag button clicked. Opening tag selection panel.");
                        if (tagSelectionPanel.opacity > 0.01) {
                            tagSelectionPanel.opacity = 0;
                        } else {
                            tagSelectionPanel.opacity = 1;
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: "#000000"
        visible: colorSelectionPanel.opacity > 0.01
        opacity: colorSelectionPanel.opacity * 0.4
        z: 10.5

        MouseArea {
            anchors.fill: parent
            enabled: overlayRect.visible
            onClicked: {
                if (colorSelectionPanel.opacity > 0.01) {
                    colorSelectionPanel.opacity = 0;
                }
            }
        }
    }

    Rectangle {
        id: colorSelectionPanel
        width: parent.width
        property real panelRadius: Theme.itemSizeSmall / 2
        height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + panelRadius
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomToolbar.bottom
        z: 12
        opacity: 0
        visible: opacity > 0.01
        color: "transparent"
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: colorPanelVisualBody
            width: parent.width
            height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + 2 * colorSelectionPanel.panelRadius
            color: newNotePage.noteColor
            y: 0

            Column {
                id: colorPanelContentColumn
                width: parent.width
                height: implicitHeight
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: colorSelectionPanel.panelRadius
                anchors.bottomMargin: Theme.paddingMedium
                spacing: Theme.paddingMedium

                Label {
                    id: colorTitle
                    text: qsTr("Select Note Color")
                    font.pixelSize: Theme.fontSizeLarge
                    color: "#e8eaed"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Flow {
                    id: colorFlow
                    width: parent.width
                    spacing: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: Qt.LeftToRight
                    readonly property int columns: 6
                    readonly property real itemWidth: (parent.width - (spacing * (columns - 1))) / columns

                    Repeater {
                        model: newNotePage.colorPalette
                        delegate: Item {
                            width: parent.itemWidth
                            height: parent.itemWidth

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: (newNotePage.noteColor === modelData) ? "white" : "#707070"
                                border.color: "transparent"
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.95
                                height: parent.height * 0.95
                                radius: width / 2
                                color: modelData
                                border.color: "transparent"

                                Rectangle {
                                    visible: newNotePage.noteColor === modelData
                                    anchors.centerIn: parent
                                    width: parent.width * 0.7
                                    height: parent.height * 0.7
                                    radius: width / 2
                                    color: modelData

                                    Icon {
                                        source: "qrc:/qml/icons/check.svg"
                                        anchors.centerIn: parent
                                        width: parent.width * 0.75
                                        height: parent.height * 0.75
                                        color: "white"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: true
                                onClicked: {
                                    if (handleInteractionAttempt()) {
                                        newNotePage.noteColor = modelData;
                                        newNotePage.noteModified = true;
                                        colorSelectionPanel.opacity = 0;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ScrollBarComponent {
        flickableSource: mainContentFlickable
        topAnchorItem: header
    }

    Rectangle {
        id: tagOverlayRect
        anchors.fill: parent
        color: "#000000"
        visible: tagSelectionPanel.opacity > 0.01
        opacity: tagSelectionPanel.opacity * 0.4
        z: 11.5

        MouseArea {
            anchors.fill: parent
            enabled: tagOverlayRect.visible
            onClicked: {
                if (tagSelectionPanel.opacity > 0.01) {
                    tagSelectionPanel.opacity = 0;
                    console.log("Tag picker closed by clicking overlay.");
                }
            }
        }
    }

    Rectangle {
        property string currentNewTagInput: ""

        id: tagSelectionPanel
        width: parent.width
        height: parent.height * 0.53
        color: DB.darkenColor(newNotePage.noteColor, 0.15)
        radius: 15
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomToolbar.bottom
        z: 12
        opacity: 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        onVisibleChanged: {
            if (visible) {
                loadTagsForTagPanel();
                tagsPanelFlickable.contentY = 0;
                console.log("Tag selection panel opened. Loading tags and scrolling to top.");
            }
        }

        ListModel {
            id: availableTagsModel
        }
        function performAddTagLogic() {
            if (!newNotePage.handleInteractionAttempt()) {
                return;
            }

            var trimmedTag = tagSelectionPanel.currentNewTagInput.trim();
            if (trimmedTag === "") {
                if (toastManager) toastManager.show(qsTr("Tag name cannot be empty!"));
                return;
            }

            var existingTags = DB.getAllTagsWithCounts();
            var tagExists = existingTags.some(function(t) {
                return t.name === trimmedTag;
            });

            if (tagExists) {
                console.log("Error: Tag '%1' already exists.".arg(trimmedTag));
                if (toastManager) toastManager.show(qsTr("Tag '%1' already exists!").arg(trimmedTag));
            } else {
                DB.addTag(trimmedTag);
                console.log("New tag '%1' added to DB.".arg(trimmedTag));

                var updatedNoteTags = Array.isArray(newNotePage.noteTags) ? newNotePage.noteTags.slice() : [];
                if (updatedNoteTags.indexOf(trimmedTag) === -1) {
                    updatedNoteTags.push(trimmedTag);
                    newNotePage.noteTags = updatedNoteTags;
                    newNotePage.noteModified = true;
                    console.log("Tag '%1' also added to current note's tags.".arg(trimmedTag));
                }

                tagSelectionPanel.currentNewTagInput = "";
                newTagInput.forceActiveFocus(false);

                loadTagsForTagPanel();

                if (toastManager) toastManager.show(qsTr("Tag '%1' created and added!").arg(trimmedTag));
            }
        }

        function loadTagsForTagPanel() {
            availableTagsModel.clear();
            var allTags = DB.getAllTags();

            var currentNoteTags = Array.isArray(newNotePage.noteTags) ? newNotePage.noteTags.slice() : [];

            var selectedTags = [];
            var unselectedTags = [];

            for (var i = 0; i < allTags.length; i++) {
                var tagName = allTags[i];
                var isChecked = currentNoteTags.indexOf(tagName) !== -1;
                if (isChecked) {
                    selectedTags.push({ name: tagName, isChecked: true });
                } else {
                    unselectedTags.push({ name: tagName, isChecked: false });
                }
            }

            for (var i = 0; i < selectedTags.length; i++) {
                availableTagsModel.append(selectedTags[i]);
            }
            for (var i = 0; i < unselectedTags.length; i++) {
                availableTagsModel.append(unselectedTags[i]);
            }

            console.log("TagSelectionPanel: Loaded tags for display in panel. Model items: %1".arg(availableTagsModel.count));
        }

        Column {
            id: tagPanelContentColumn
            anchors.fill: parent
            spacing: Theme.paddingMedium

            Rectangle {
                id: tagPanelHeader
                width: parent.width
                height: Theme.itemSizeMedium
                color: DB.darkenColor(newNotePage.noteColor, 0.15)
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

            }
            SearchField {
                id: newTagInput
                width: parent.width * 0.95
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: tagPanelHeader.verticalCenter
                placeholderText: qsTr("Add new tag...")
                font.pixelSize: Theme.fontSizeMedium
                highlighted: false
                color: Theme.primaryColor
                readOnly: newNotePage.isReadOnly

                text: tagSelectionPanel.currentNewTagInput
                onTextChanged: tagSelectionPanel.currentNewTagInput = text

                EnterKey.onClicked: {
                    tagSelectionPanel.performAddTagLogic();
                }

                rightItem: Item {
                    id: addTagButtonContainer
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 1.1
                    clip: false

                    opacity: tagSelectionPanel.currentNewTagInput.trim().length > 0 && !newNotePage.isReadOnly ? 1 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Icon {
                        id: addTagPanelIcon
                        source: tagSelectionPanel.currentNewTagInput.trim().length > 0 ? "qrc:/qml/icons/plus.svg" : "qrc:/qml/icons/plus.svg"
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        color: Theme.primaryColor
                    }
                    RippleEffectComponent { id: addTagRippleEffect }
                    MouseArea {
                        anchors.fill: parent
                        enabled: tagSelectionPanel.currentNewTagInput.trim().length > 0 && !newNotePage.isReadOnly
                        onPressed: addTagRippleEffect.ripple(mouseX, mouseY)
                        onClicked: {
                            tagSelectionPanel.performAddTagLogic();
                        }
                    }
                }
               leftItem: Item {}
            }


            SilicaFlickable {
                id: tagsPanelFlickable
                width: parent.width
                anchors.top: newTagInput.bottom
                anchors.bottom: doneButton.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Theme.paddingMedium
                anchors.bottomMargin: Theme.paddingMedium
                contentHeight: tagsPanelListView.contentHeight
                clip: true

                ListView {
                    id: tagsPanelListView
                    width: parent.width
                    height: contentHeight
                    model: availableTagsModel
                    orientation: ListView.Vertical
                    spacing: Theme.paddingSmall

                    delegate: Rectangle {
                        id: tagPanelDelegateRoot
                        width: parent.width
                        height: Theme.itemSizeMedium
                        clip: true
                        color: model.isChecked ? DB.darkenColor(newNotePage.noteColor, -0.25) : DB.darkenColor(newNotePage.noteColor, 0.25)

                        RippleEffectComponent { id: tagPanelDelegateRipple }

                        MouseArea {
                            anchors.fill: parent
                            enabled: true
                            onPressed: tagPanelDelegateRipple.ripple(mouseX, mouseY)
                            onClicked: {
                                if (handleInteractionAttempt()) {
                                    var newCheckedState = !model.isChecked;

                                    availableTagsModel.set(index, { name: model.name, isChecked: newCheckedState });

                                    var currentNoteTagsCopy = Array.isArray(newNotePage.noteTags) ? newNotePage.noteTags.slice() : [];

                                    if (newCheckedState) {
                                        if (currentNoteTagsCopy.indexOf(model.name) === -1) {
                                            currentNoteTagsCopy.push(model.name);
                                        }
                                    } else {
                                        currentNoteTagsCopy = currentNoteTagsCopy.filter(function(tag) {
                                            return tag !== model.name;
                                        });
                                    }
                                    newNotePage.noteTags = currentNoteTagsCopy;

                                    if (newNotePage.noteId !== -1) {
                                        if (newCheckedState) {
                                            DB.addTagToNote(newNotePage.noteId, model.name);
                                            console.log("Added tag '%1' to note ID %2".arg(model.name).arg(newNotePage.noteId));
                                        } else {
                                            DB.deleteTagFromNote(newNotePage.noteId, model.name);
                                            console.log("Removed tag '%1' from note ID %2".arg(model.name).arg(newNotePage.noteId));
                                        }
                                    }

                                    newNotePage.noteModified = true;
                                    console.log("Note's tags updated: %1".arg(JSON.stringify(newNotePage.noteTags)));
                                }
                            }
                        }

                        Row {
                            id: tagPanelRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge
                            anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge
                            spacing: Theme.paddingMedium

                            Icon {
                                id: tagPanelTagIcon
                                source: "qrc:/qml/icons/tag-white.svg"
                                color: "#e2e3e8"
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Label {
                                id: tagPanelTagNameLabel
                                text: model.name
                                color: "#e2e3e8"
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                anchors.left: tagPanelTagIcon.right
                                anchors.leftMargin: tagPanelRow.spacing
                                anchors.right: tagPanelCheckButtonContainer.left
                                anchors.rightMargin: tagPanelRow.spacing
                            }

                            Item {
                                id: tagPanelCheckButtonContainer
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                clip: false

                                Image {
                                    id: tagPanelCheckIcon
                                    source: model.isChecked ? "qrc:/qml/icons/box-checked.svg" : "qrc:/qml/icons/box.svg"
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                        }
                    }
                }
            }

            ScrollBarComponent {
                flickableSource: tagsPanelFlickable
                anchors.top: tagsPanelFlickable.top
                anchors.bottom: tagsPanelFlickable.bottom
                anchors.right: parent.right
                width: Theme.paddingSmall
            }

            Button {
                id: doneButton
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Done")
                onClicked: {
                    tagSelectionPanel.opacity = 0;
                    newNotePage.noteModified = true;
                    console.log("Tag picker closed by Done button.");
                }
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge
            }
        }
    }

    ConfirmDialog {
        id: generalConfirmDialog
        dialogVisible: newNotePage.confirmDialogVisible
        dialogTitle: newNotePage.confirmDialogTitle
        dialogMessage: newNotePage.confirmDialogMessage
        confirmButtonText: newNotePage.confirmButtonText
        confirmButtonHighlightColor: newNotePage.confirmButtonHighlightColor
        dialogBackgroundColor: DB.darkenColor(newNotePage.noteColor, 0.15)

        onConfirmed: {
            if (newNotePage.onConfirmCallback) {
                newNotePage.onConfirmCallback();
            }
            newNotePage.confirmDialogVisible = false;
        }
        onCancelled: {
            newNotePage.confirmDialogVisible = false;
            console.log("Action cancelled by user.");
            if (newNotePage.isArchived || newNotePage.isDeleted) {
                newNotePage.isReadOnly = true;
            }
        }
    }
}

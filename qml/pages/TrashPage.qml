// TrashPage.qml (ПОЛНЫЙ ФАЙЛ, ИСПРАВЛЕНЫ topMargin В ДИАЛОГЕ)

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB
// import "TrashNoteCard.qml" // Оставлено без импорта.

Page {
    id: trashPage
    backgroundColor: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#121218"
    showNavigationIndicator: false
    property var deletedNotes: []
    property var selectedNoteIds: []
    property string deleteDialogMessage: "" // Для текста сообщения диалога

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

    // *** НОВЫЙ БЛОК: ColumnLayout для управления компоновкой
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: pageHeader.height // Отступ от заголовка страницы
        spacing: 0 // Управляем отступами внутри элементов

        // ПАНЕЛЬ С КНОПКАМИ ВЫБОРА - СВЕРХУ, ЗАКРЕПЛЕНА
        Row {
            id: selectionControls
            Layout.fillWidth: true // Заполняем всю доступную ширину в ColumnLayout
            height: selectionControlsVisible ? Theme.buttonHeightSmall + Theme.paddingSmall : 0
            visible: selectionControlsVisible
            spacing: Theme.paddingSmall

            // Внутренние отступы для Row, чтобы кнопки не прилипали к краям
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.paddingMedium
            anchors.rightMargin: Theme.paddingMedium

            // Кнопка "Выбрать все" (с иконкой из ресурсов)
            Button {
                id: selectAllButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3 // Ширина через Layout
                Layout.preferredHeight: Theme.buttonHeightSmall // Высота через Layout
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
                    selectedNoteIds = selectedNoteIds;
                }
                enabled: deletedNotes.length > 0
            }

            // Кнопка "Восстановить выбранные" (с иконкой из ресурсов)
            Button {
                id: restoreSelectedButton
                Layout.preferredWidth: (parent.width - (parent.spacing * 2)) / 3
                Layout.preferredHeight: Theme.buttonHeightSmall
                icon.source: "../icons/restore_notes.svg"
                highlightColor: Theme.highlightColor
                enabled: selectedNoteIds.length > 0
                onClicked: {
                    if (selectedNoteIds.length > 0) {
                        // Сохраняем количество восстанавливаемых заметок до refreshDeletedNotes()
                        var restoredCount = selectedNoteIds.length;
                        DB.restoreNotes(selectedNoteIds);
                        refreshDeletedNotes();
                        toastManager.show(qsTr("%1 note(s) restored!").arg(restoredCount));
                    }
                }
            }

            // Кнопка "Удалить навсегда выбранные" (с иконкой из ресурсов)
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
                        // Открываем вручную созданный диалог
                        manualConfirmDialog.visible = true;
                    }
                }
            }
        } // Конец selectionControls Row

        // Небольшой отступ между кнопками и первым элементом Flickable
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: selectionControlsVisible ? Theme.paddingMedium : 0
            visible: selectionControlsVisible
        }

        // Основная прокручиваемая область для отображения заметок
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
                            isSelected: selectedNoteIds.indexOf(modelData.id) !== -1

                            onSelectionToggled: {
                                if (isSelected) {
                                    if (selectedNoteIds.indexOf(noteId) === -1) {
                                        selectedNoteIds.push(noteId);
                                    }
                                } else {
                                    var index = selectedNoteIds.indexOf(noteId);
                                    if (index !== -1) {
                                        selectedNoteIds.splice(index, 1);
                                    }
                                }
                                selectedNoteIds = selectedNoteIds;
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
    } // Конец mainLayout ColumnLayout

    ToastManager {
        id: toastManager
    }

    // *** Ручная имитация Overlay / Диалога
    Item {
        id: manualConfirmDialog
        anchors.fill: parent
        visible: false // Изначально скрыт

        // Фон, затемняющий страницу
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.9125
        }

        // Сам диалог (прямоугольник в центре)
        Rectangle {
            id: dialogContent
            width: parent.width * 0.8 // Ширина 80% от родителя
            height: implicitHeight // Высота по содержимому
            color: Theme.backgroundColor // Цвет фона диалога
            radius: Theme.itemCornerRadius // Скругленные углы
            anchors.centerIn: parent // По центру родительского Item

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
                    text: trashPage.deleteDialogMessage // Используем свойство страницы для текста
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.primaryColor
                }

                RowLayout {
                    width: parent.width
                    spacing: Theme.paddingMedium
                    anchors.horizontalCenter: parent.horizontalCenter // Центрируем кнопки
                    // Layout.topMargin: Theme.paddingLarge // *** УДАЛЕНА ПРОБЛЕМНАЯ СТРОКА

                    // Чтобы добавить отступ сверху для кнопок, если spacing Column выше недостаточен
                    // Можно использовать Item с preferredHeight, если нужен дополнительный вертикальный отступ
                    // Item { Layout.preferredHeight: Theme.paddingLarge; } // Пример, если нужно

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Cancel")
                        onClicked: manualConfirmDialog.visible = false // Скрываем диалог
                    }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Delete")
                        highlightColor: Theme.errorColor
                        onClicked: {
                            // ИСПРАВЛЕНИЕ: Сохраняем количество удаляемых заметок перед сбросом selectedNoteIds
                            var deletedCount = selectedNoteIds.length;
                            DB.permanentlyDeleteNotes(selectedNoteIds);
                            refreshDeletedNotes();
                            toastManager.show(qsTr("%1 note(s) permanently deleted!").arg(deletedCount)); // Используем сохраненное количество
                            manualConfirmDialog.visible = false // Скрываем диалог после выполнения
                        }
                    }
                }
            }
        }
    } // Конец manualConfirmDialog
}

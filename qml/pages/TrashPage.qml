// qml/pages/TrashPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import "DatabaseManager.js" as DB // Импортируем наш менеджер БД

Page {
    id: trashPage
    objectName: "TrashPage"

    // Обязательно объявляем этот callback, чтобы MainPage мог его слушать
    property var onTrashPageClosed: function() {}

    // Заголовок страницы
    PageHeader {
        title: qsTr("Trash")
    }

    SilicaListView {
        id: trashNotesListView
        anchors.fill: parent
        model: ListModel { id: trashNotesModel }

        PullDownMenu {
            MenuItem {
                text: qsTr("Empty Trash")
                onClicked: {
                    var confirmDialog = PageStack.push("Sailfish.Silica.ConfirmDialog", {
                        title: qsTr("Empty Trash?"),
                        text: qsTr("Are you sure you want to permanently delete all notes from trash? This action cannot be undone.")
                    });
                    confirmDialog.accepted.connect(function() {
                        DB.emptyTrash();
                        trashNotesModel.clear(); // Очищаем модель после удаления
                        onTrashPageClosed(); // Вызываем callback, чтобы MainPage обновилась
                    });
                }
            }
        }

        VerticalScrollDecorator {}

        delegate: BackgroundItem {
            width: parent.width
            height: Theme.itemHeightLarge * 1.2
            clip: true // Для скругленных углов

            Rectangle {
                anchors.fill: parent
                color: model.color || Theme.rgba(Theme.highlightColor.r, Theme.highlightColor.g, Theme.highlightColor.b, 0.2)
                radius: Theme.itemRadius
            }

            Row {
                anchors.fill: parent
                spacing: Theme.paddingMedium

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.paddingMedium
                    width: parent.width - Theme.paddingMedium * 2 - Theme.itemSizeLarge * 2
                    spacing: Theme.paddingSmall

                    Label {
                        text: model.title || qsTr("No Title")
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                        wrapMode: Text.WordWrap
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Label {
                        text: model.content || qsTr("No Content")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.primaryColor
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    x: -Theme.paddingMedium
                    spacing: Theme.paddingSmall

                    IconButton {
                        icon.source: "image://theme/icon-m-restore"
                        onClicked: {
                            var confirmDialog = PageStack.push("Sailfish.Silica.ConfirmDialog", {
                                title: qsTr("Restore Note?"),
                                text: qsTr("Are you sure you want to restore this note from trash?")
                            });
                            confirmDialog.accepted.connect(function() {
                                DB.restoreNote(model.id);
                                loadTrashNotes(); // Перезагружаем список на этой странице
                                onTrashPageClosed(); // Вызываем callback, чтобы MainPage обновилась
                            });
                        }
                    }

                    IconButton {
                        icon.source: "image://theme/icon-m-delete"
                        onClicked: {
                            var confirmDialog = PageStack.push("Sailfish.Silica.ConfirmDialog", {
                                title: qsTr("Delete Permanently?"),
                                text: qsTr("Are you sure you want to permanently delete this note? This action cannot be undone.")
                            });
                            confirmDialog.accepted.connect(function() {
                                DB.permanentlyDeleteNote(model.id);
                                loadTrashNotes(); // Перезагружаем список на этой странице
                                onTrashPageClosed(); // Вызываем callback, чтобы MainPage обновилась
                            });
                        }
                    }
                }
            }
        }

        Label {
            visible: trashNotesModel.count === 0
            text: qsTr("Trash is empty")
            anchors.centerIn: parent
            color: Theme.secondaryColor
        }
    }

    // Используем Connections для обработки сигнала 'activated'
    Connections {
        target: trashPage
        onActivated: {
            loadTrashNotes();
            DB.cleanupOldTrashNotes(); // Очистка старых заметок при активации страницы
            console.log("TrashPage activated!");
        }
        onExited: {
            onTrashPageClosed(); // Вызываем callback при выходе со страницы
        }
    }

    function loadTrashNotes() {
        var notes = DB.getTrashNotes();
        trashNotesModel.clear();
        for (var i = 0; i < notes.length; i++) {
            trashNotesModel.append(notes[i]);
        }
        console.log("Loaded " + notes.length + " trash notes.");
    }

    Component.onCompleted: {
        loadTrashNotes(); // Загружаем заметки при первом создании страницы
        DB.cleanupOldTrashNotes(); // Очистка при первом создании тоже
    }
}

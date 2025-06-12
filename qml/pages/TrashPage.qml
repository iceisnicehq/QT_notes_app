// TrashPage.qml (ФИНАЛЬНЫЙ ПОЛНЫЙ ФАЙЛ, с увеличенными отступами и фиксированной высотой кнопок)

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import "DatabaseManager.js" as DB // Убедитесь, что DatabaseManager.js находится в той же папке

Page {
    id: trashPage
    // Используем Theme.backgroundColor, с запасным вариантом на случай undefined
    backgroundColor: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#1c1d29"
    property var deletedNotes: []

    Component.onCompleted: {
        console.log("TRASH_PAGE: TrashPage opened. Calling refreshDeletedNotes.");
        refreshDeletedNotes();
    }

    function refreshDeletedNotes() {
        deletedNotes = DB.getDeletedNotes();
        console.log("TRASH_PAGE: refreshDeletedNotes completed. Count:", deletedNotes.length);
    }

    property bool showEmptyLabel: deletedNotes.length === 0

    // Заголовок страницы
    PageHeader {
        id: pageHeader
        Label {
            text: qsTr("Trash") // "Корзина"
            anchors.centerIn: parent // Центрируем текст заголовка по горизонтали и вертикали
            font.pixelSize: Theme.fontSizeExtraLarge
            color: Theme.highlightColor
            font.bold: true
        }
    }

    // Основная прокручиваемая область для отображения заметок
    SilicaFlickable {
        id: trashFlickable
        anchors.fill: parent
        anchors.top: pageHeader.bottom // Начинаем сразу под заголовком
        // Высота контента flickable будет определяться неявно по содержимому trashColumn
        // или position of emptyLabel, так как они переключаются видимостью.
        contentHeight: trashColumn.implicitHeight + (trashPage.showEmptyLabel ? 0 : Theme.paddingLarge)
        // Добавляем небольшой отступ снизу, если заметки есть, для лучшего скроллинга

        Column {
            id: trashColumn
            width: parent.width
            spacing: Theme.paddingMedium // Отступ между каждым блоком (карточка + кнопки)
            visible: !trashPage.showEmptyLabel // Показываем колонку только если заметки есть
            anchors.top: parent.top // Колонка начинается вверху SilicaFlickable
            anchors.topMargin: Theme.paddingMedium // Добавляем отступ сверху колонки, чтобы первая карточка не прилипала к заголовку

            // Повторитель для создания элементов удаленных заметок
            Repeater {
                model: deletedNotes
                delegate: Column { // Каждый элемент заметки - это отдельная Колонка
                    width: parent.width
                    // УВЕЛИЧЕНО: spacing между NoteCard и кнопками теперь больше
                    spacing: Theme.paddingLarge // Увеличиваем отступ здесь до Theme.paddingLarge

                    // Сама карточка заметки (компонент NoteCard)
                    NoteCard {
                        // Горизонтальные отступы внутри Column делегата
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: Theme.paddingMedium
                            rightMargin: Theme.paddingMedium
                            // bottomMargin на NoteCard не так важен, если spacing Column делегата большой.
                            // Его можно удалить, если spacing в Column-делегате справляется.
                            // bottomMargin: Theme.paddingSmall // Опционально, для очень мелкого отступа
                        }
                        width: parent.width - (Theme.paddingMedium * 2) // Ширина карточки с учетом боковых отступов
                        title: modelData.title
                        content: modelData.content
                        tags: modelData.tags ? modelData.tags.join(' ') : ''
                        cardColor: modelData.color || "#1c1d29" // Цвет карточки из данных, или дефолтный
                        height: implicitHeight // Пусть NoteCard сама определяет свою высоту
                    }

                    // Ряд для кнопок действий (Восстановить, Удалить навсегда)
                    // ЭТОТ РЯД ДОЛЖЕН БЫТЬ ВНУТРИ ДЕЛЕГАТА Column, чтобы кнопки были под каждой заметкой.
                    Row {
                        width: parent.width - (Theme.paddingMedium * 2) // Ширина ряда кнопок соответствует ширине карточки
                        anchors.horizontalCenter: parent.horizontalCenter // Центрируем ряд горизонтально
                        spacing: Theme.paddingSmall // Отступ между кнопками

                        Button {
                            width: (parent.width - parent.spacing) / 2 // Делим доступное пространство поровну между кнопками
                            height: 30 // Фиксированная высота, как вы протестировали
                            text: qsTr("Restore")
                            onClicked: {
                                DB.restoreNote(modelData.id);
                                refreshDeletedNotes(); // Обновляем список заметок после восстановления
                                toastManager.show("Note restored!");
                            }
                        }

                        Button {
                            width: (parent.width - parent.spacing) / 2 // Делим доступное пространство поровну
                            height: 30 // Фиксированная высота
                            text: qsTr("Delete Permanently")
                            highlightColor: Theme.errorColor // Цвет для кнопки удаления
                            onClicked: {
                                var dialog = pageStack.push(Qt.resolvedUrl("ConfirmationDialog.qml"), {
                                    message: qsTr("Are you sure you want to permanently delete this note? This action cannot be undone."),
                                    acceptText: qsTr("Delete"),
                                    cancelText: qsTr("Cancel")
                                });
                                dialog.accepted.connect(function() {
                                    DB.permanentlyDeleteNote(modelData.id);
                                    refreshDeletedNotes(); // Обновляем список заметок после удаления
                                    console.log("TRASH_PAGE: Permanently deleted note ID:", modelData.id);
                                    toastManager.show("Note permanently deleted!");
                                });
                            }
                        }
                    } // Конец Row для кнопок
                } // Конец Column-делегата
            } // Конец Repeater
        } // Конец trashColumn

        // Метка "Корзина пуста" - отображается, когда нет удаленных заметок
        Label {
            id: emptyLabel
            visible: trashPage.showEmptyLabel // Видима, только если корзина пуста
            text: qsTr("Trash is empty.") // "Корзина пуста."
            font.italic: true
            color: Theme.secondaryColor
            anchors.horizontalCenter: parent.horizontalCenter // Центрируем по горизонтали
            anchors.verticalCenter: parent.verticalCenter // Центрируем по вертикали в видимой области flickable
            width: parent.width * 0.8 // Ширина метки 80% от ширины родителя
            horizontalAlignment: Text.AlignHCenter // Выравнивание текста по центру
        }
    } // Конец SilicaFlickable

    // Полоса прокрутки для SilicaFlickable
    ScrollBar {
        flickableSource: trashFlickable
    }

    // Менеджер всплывающих уведомлений
    ToastManager {
        id: toastManager
    }
}

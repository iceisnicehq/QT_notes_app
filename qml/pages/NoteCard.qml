// NoteCard.qml (ФИНАЛЬНЫЙ ПОЛНЫЙ ФАЙЛ)

import QtQuick 2.0
import Sailfish.Silica 1.0 // Убедитесь, что этот импорт присутствует

Item {
    id: root
    // Ширина карточки будет определяться родителем (например, делегатом Repeater в TrashPage)
    // Fallback на 360, если родительская ширина недоступна (для тестирования компонента отдельно)
    width: parent ? parent.width : 360

    // Высота root Item определяется неявно, исходя из содержимого cardColumn
    // cardColumn.implicitHeight - это высота всех элементов внутри колонки + их spacing.
    // Theme.paddingLarge * 2 - это sum of topMargin and bottomMargin applied to cardColumn via anchors.margins
    implicitHeight: cardColumn.implicitHeight + (Theme.paddingLarge * 2)

    // Определяем свойства для данных заметки
    property string title: ""
    property string content: ""
    // tags теперь ожидается как строка, например "tag1 tag2 tag3"
    property string tags: ""
    // Свойство для цвета фона карточки, по умолчанию нейтральный серый
    property string cardColor: "#1c1d29"

    // Основной прямоугольник, который служит фоном карточки
    Rectangle {
        anchors.fill: parent // Прямоугольник заполняет весь корневой Item
        color: root.cardColor // Используем заданный цвет фона
        radius: 20 // Закругленные углы
        border.color: "#43484e" // Цвет рамки
        border.width: 2 // Толщина рамки

        // Колонка для всего содержимого заметки (заголовок, текст, теги)
        Column {
            id: cardColumn
            // FIX: Вместо anchors.top/bottom/left/right используем anchors.fill с anchors.margins.
            // Это решает проблему "Binding loop detected for property topMargin".
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge // Внутренний отступ от краев Rectangle
            spacing: Theme.paddingSmall // Отступ между элементами внутри этой колонки (заголовок, текст, теги)

            // Заголовок заметки
            Text {
                id: titleText
                // Показываем "Empty", если заголовок пуст, и делаем его курсивом
                text: (root.title && root.title.trim()) ? root.title : qsTr("Empty")
                font.italic: !(root.title && root.title.trim())
                textFormat: Text.PlainText // Для предотвращения проблем с форматированием HTML
                color: "#e8eaed" // Цвет текста
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap // Перенос слов
                width: parent.width // Заголовок занимает всю доступную ширину колонки
            }

            // Основное содержание заметки (текст)
            Text {
                id: contentText
                // Показываем "Empty", если контент пуст, и делаем его курсивом
                text: (root.content && root.content.trim()) ? root.content : qsTr("Empty")
                font.italic: !(root.content && root.content.trim())
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                maximumLineCount: 5 // Ограничение на 5 строк
                elide: Text.ElideRight // Добавляем многоточие, если текст длиннее
                font.pixelSize: Theme.fontSizeSmall
                color: "#e8eaed"
                width: parent.width
            }

            // Flow Layout для тегов
            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall // Отступ между тегами
                // Видим только если есть теги (после обрезки пробелов)
                visible: root.tags && root.tags.trim().length > 0

                // Повторитель для создания отдельных тегов
                Repeater {
                    // Разделяем строку тегов по пробелу, чтобы получить массив
                    model: root.tags.split(" ")
                    delegate: Rectangle {
                        // Показываем только первые 2 тега (индекс 0 и 1)
                        visible: index < 2 && modelData.trim().length > 0 // Также проверяем, что тег не пуст
                        color: "#32353a" // Цвет фона тега
                        radius: 12 // Закругленные углы тега
                        height: tagText.implicitHeight + Theme.paddingSmall // Высота тега по тексту + отступы
                        // Ширина тега: текст + отступы, но не более 45% от ширины карточки
                        // Это предотвращает слишком широкие теги и заставляет elide работать.
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium * 2, root.width * 0.45)

                        Text {
                            id: tagText
                            text: modelData // Сам текст тега
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            elide: Text.ElideRight // Многоточие для очень длинных тегов
                            anchors.centerIn: parent // Центрируем текст внутри Rectangle тега
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            // Ширина текста внутри тега (немного меньше родительского Rectangle)
                            width: parent.width - Theme.paddingSmall * 2
                            wrapMode: Text.NoWrap // Не переносим теги на новую строку
                            textFormat: Text.PlainText
                        }
                    }
                }

                // Кнопка "+X" для скрытых тегов
                Rectangle {
                    // Видим только если тегов больше двух
                    visible: root.tags && root.tags.split(" ").length > 2
                    color: "#32353a"
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (root.tags.split(" ").length - 2) // Количество скрытых тегов
                        color: "#c5c8d0"
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.NoWrap
                    }
                }
            }
        }
    }
}

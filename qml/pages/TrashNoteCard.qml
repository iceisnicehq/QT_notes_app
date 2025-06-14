import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent ? parent.width : 360
    implicitHeight: cardColumn.implicitHeight + (Theme.paddingLarge * 2)

    // --- Properties ---
    property string title: ""
    property string content: ""
    property string tags: ""
    property string cardColor: "#1c1d29"
    property bool isSelected: false
    property int noteId: -1

    // --- Signals ---
    signal selectionToggled(int noteId, bool isSelected)

    // --- UI Components ---
    Rectangle {
        anchors.fill: parent
        color: root.cardColor
        radius: 20
        border.color: "#43484e"
        border.width: 1 // Slightly thinner border for a cleaner look

        // Custom Checkbox
        Rectangle {
            id: selectionIndicator
            anchors { right: parent.right; top: parent.top; rightMargin: Theme.paddingMedium; topMargin: Theme.paddingMedium }
            width: Theme.iconSizeSmall; height: width; radius: width / 2
            color: root.isSelected ? Theme.highlightColor : Theme.primaryColor // Вернул исходные цвета, чтобы избежать "белых квадратов"
            border.color: root.isSelected ? "transparent" : Theme.secondaryColor
            border.width: root.isSelected ? 0 : 2

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.isSelected = !root.isSelected;
                    root.selectionToggled(root.noteId, root.isSelected);
                }
            }
        }

        Column {
            id: cardColumn
            anchors.fill: parent
            anchors.margins: Theme.paddingLarge
            spacing: Theme.paddingSmall

            Text {
                id: titleText
                text: (root.title && root.title.trim()) ? root.title : qsTr("Empty")
                font.italic: !(root.title && root.title.trim())
                color: "#e8eaed" // Вернул исходный цвет
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap
                // Adjust width to not overlap with the selection indicator
                width: parent.width - selectionIndicator.width - Theme.paddingMedium
            }

            Text {
                id: contentText
                text: (root.content && root.content.trim()) ? root.content : qsTr("Empty")
                font.italic: !(root.content && root.content.trim())
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: "#c5c8d0" // Slightly different color for content
                width: parent.width
            }

            // Tags Flow - Исправлена проблема с обрезкой текста и белыми квадратами
            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall
                visible: root.tags && root.tags.trim().length > 0

                Repeater {
                    model: root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" })
                    delegate: Rectangle {
                        visible: index < 2 // Показывать только первые 2 тега
                        color: "#32353a" // ВОССТАНОВЛЕН ИСХОДНЫЙ ЦВЕТ ФОНА ТЕГА
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        // Управление шириной: берем минимум из implicitWidth текста + отступы ИЛИ 45% от родителя.
                        // Это позволяет тегу расширяться, но не бесконечно, и обрезать текст, если он слишком длинный.
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium * 2, root.width * 0.45)

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0" // ВОССТАНОВЛЕН ИСХОДНЫЙ ЦВЕТ ТЕКСТА ТЕГА
                            font.pixelSize: Theme.fontSizeExtraSmall
                            elide: Text.ElideRight // Обязательно для сокращения текста
                            anchors.centerIn: parent
                            // Ширина текста внутри Rectangle тега, чтобы он мог сокращаться
                            width: parent.width - (Theme.paddingMedium * 2)
                            horizontalAlignment: Text.AlignHCenter // Центрирование текста внутри тега
                        }
                    }
                }

                Rectangle {
                    visible: root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" }).length > 2
                    color: "#32353a" // ВОССТАНОВЛЕН ИСХОДНЫЙ ЦВЕТ ФОНА
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" }).length - 2)
                        color: "#c5c8d0" // ВОССТАНОВЛЕН ИСХОДНЫЙ ЦВЕТ ТЕКСТА
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }
}

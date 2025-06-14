// TrashNoteCard.qml (Финальная версия с чуть более закругленными краями)

import QtQuick 2.0
import Sailfish.Silica 1.0
import "DatabaseManager.js" as DB





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
    property var trashPageInstance: null

    // --- Signals ---
    signal selectionToggled(int noteId, bool isSelected)
    signal noteClicked(int noteId)



    // Refreshes all notes and tags from the database
    function refreshData() {
        allNotes = DB.getAllNotes(); // This now only gets non-deleted notes
        allTags = DB.getAllTags(); // This now only gets tags linked to non-deleted notes
        // After refreshing all data, perform a search with current criteria
        performSearch(currentSearchText, selectedTags);
        loadTagsForDrawer(); // Ensure tags in drawer are updated
    }



    // --- UI Components ---
    Rectangle {
        anchors.fill: parent
        color: root.cardColor
        radius: 20
        border.color: "#43484e"
        border.width: 1

        // MouseArea для клика по всей карточке (для открытия NotePage или переключения выделения)
        MouseArea {
            anchors.fill: parent
            enabled: fabButton.visible // Enable/disable based on fabButton's visible property
            onClicked: {
                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                    onNoteSavedOrDeleted: root.mainPageInstance ? root.mainPageInstance.refreshData : null, // Pass refreshData callback
                    noteId: root.noteId,
                    noteTitle: root.title,
                    noteContent: root.content, // Corrected: Use root.content
                    noteIsPinned: root.noteIsPinned, // Corrected: Use root.noteIsPinned
                    noteTags: root.tags, // Corrected: Use root.tags
                    noteCreationDate: root.noteCreationDate, // Corrected: Use root.noteCreationDate
                    noteEditDate: root.noteEditDate, // Corrected: Use root.noteEditDate
                    noteColor: root.cardColor

                });
                console.log("Opening NewNotePage in edit mode (from FAB).");
                Qt.inputMethod.hide();
                searchField.focus = false;
            }
        }

        // --- Контейнер для чекбокса с увеличенной зоной клика ---
        Item {
            id: checkboxClickArea
            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: Theme.paddingMedium }
            width: Theme.iconSizeSmall * 1.5
            height: width

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.isSelected = !root.isSelected;
                    root.selectionToggled(root.noteId, root.isSelected);
                    console.log("TrashNoteCard (ID:", root.noteId, "): Checkbox clicked. isSelected:", root.isSelected);
                }
            }

            // --- Сам визуальный чекбокс (Rectangle) ---
            Rectangle {
                id: visualCheckbox
                anchors.centerIn: parent
                width: Theme.iconSizeSmall
                height: width
                // КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: УСТАНАВЛИВАЕМ КОНКРЕТНОЕ ЗНАЧЕНИЕ РАДИУСА ДЛЯ СЛЕГКА ЗАКРУГЛЕННЫХ УГЛОВ
                radius: 4 // Например, 4 пикселя. Можно настроить по желанию (например, 2, 6, 8)

                // Цвет фона: серый, когда выбран, прозрачный, когда не выбран
                color: root.isSelected ? Theme.secondaryColor : "transparent"

                // Граница: серый, когда не выбран, прозрачная, когда выбран
                border.color: root.isSelected ? "transparent" : Theme.secondaryColor
                border.width: root.isSelected ? 0 : 2
            }
        }

        // Колонка для содержимого карточки
        Column {
            id: cardColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.topMargin: Theme.paddingLarge
            anchors.leftMargin: Theme.paddingLarge
            anchors.bottomMargin: Theme.paddingLarge
            anchors.rightMargin: checkboxClickArea.width + Theme.paddingMedium

            width: parent.width - (anchors.leftMargin + anchors.rightMargin)

            spacing: Theme.paddingSmall

            Text {
                id: titleText
                text: (root.title && root.title.trim()) ? root.title : qsTr("Empty")
                font.italic: !(root.title && root.title.trim())
                color: "#e8eaed"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap
                width: parent.width
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
                color: "#c5c8d0"
                width: parent.width
            }

            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall
                visible: root.tags && root.tags.trim().length > 0

                Repeater {
                    model: root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" })
                    delegate: Rectangle {
                        visible: index < 2
                        color: "#32353a"
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium * 2, parent.width * 0.45)

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            elide: Text.ElideRight
                            anchors.centerIn: parent
                            width: parent.width - (Theme.paddingMedium * 2)
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Rectangle {
                    visible: root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" }).length > 2
                    color: "#32353a"
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (root.tags.split(" ").filter(function(tag) { return tag.trim() !== "" }).length - 2)
                        color: "#c5c8d0"
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }
}

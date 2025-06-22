/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/note_cards/NoteCard.qml
 * Этот файл определяет компонент карточки заметки для главного экрана.
 * Он отображает заголовок, фрагмент содержимого и теги. Компонент
 * поддерживает два режима взаимодействия: короткое нажатие для открытия
 * заметки на редактирование и долгое нажатие для активации режима
 * выбора и выделения заметки. Внешний вид карточки (в частности,
 * граница) изменяется при ее выборе.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../services/DatabaseManagerService.js" as DB

Item {
    id: root
    width: parent ? parent.width : 360
    height: cardColumn.implicitHeight + Theme.paddingLarge * 2 + 20

    property string title: ""
    property string content: ""
    property var tags: []
    property string cardColor: DB.getThemeColor() || "#121218"
    property string borderColor:  DB.darkenColor((root.cardColor), -0.3)
    property int noteId: -1
    property bool isSelected: false
    property var mainPageInstance: null
    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()

    onIsSelectedChanged: {
        console.log("NoteCard ID:", root.noteId, "isSelected changed to:", root.isSelected, "Border width:", root.isSelected ? 8 : 2);
    }

    property bool pressActive: false
    property int pressX: 0
    property int pressY: 0
    Timer {
        id: longPressTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            console.log("Long press detected for note ID:", root.noteId);
            if (root.mainPageInstance) {
                if (!root.mainPageInstance.selectionMode) {
                    root.mainPageInstance.selectionMode = true;
                }
                root.mainPageInstance.toggleNoteSelection(root.noteId);
            }
            mouseArea.mouse.accepted = false;
            root.pressActive = false;
            root.scale = 1.0;
        }
    }

    scale: 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.cardColor
        radius: 20
        border.color: root.isSelected ? "white" : root.borderColor
        border.width: root.isSelected ? 4 : 2
        anchors.bottomMargin: 20
        Column {
            id: cardColumn
            anchors {
                left: parent.left; leftMargin: Theme.paddingLarge
                right: parent.right; rightMargin: Theme.paddingLarge
                top: parent.top; topMargin: Theme.paddingLarge
                bottom: parent.bottom; bottomMargin: Theme.paddingLarge
            }
            spacing: Theme.paddingSmall

            Text {
                id: titleText
                text: (root.title && root.title.trim()) ? root.title : qsTr("Empty")
                font.italic: !(root.title && root.title.trim())
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                color: "#e8eaed"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap
                width: parent.width
            }
            Rectangle {
                width: parent.width
                height: 8
                color: "transparent"
            }
            Text {
                id: contentText
                text: (root.content && root.content.trim()) ? root.content : qsTr("Empty")
                font.italic: !(root.content && root.content.trim())
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: "#c5c8d0"
                width: parent.width
            }
            Rectangle {
                width: parent.width
                height: 4
                color: "transparent"
            }
            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall
                visible: tags.trim().length > 0

                Repeater {
                    model: tags.split("_||_")
                    delegate: Rectangle {
                        visible: index < 2
                        color: "#a032353a"
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium, parent.width)

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            elide: Text.ElideRight
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width - Theme.paddingMedium
                            wrapMode: Text.NoWrap
                            textFormat: Text.PlainText
                        }
                    }
                }

                Rectangle {
                    visible: tags.split("_||_").length > 2
                    color: "#a032353a"
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (tags.split("_||_").length - 2)
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
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPressed: {
            longPressTimer.start();
            root.pressActive = true;
            root.pressX = mouse.x;
            root.pressY = mouse.y;
            mouse.accepted = true;
            root.scale = 0.97;
        }
        onReleased: {
            root.scale = 1.0;
            if (longPressTimer.running) {
                longPressTimer.stop();
                if (root.pressActive) {
                    if (root.mainPageInstance && root.mainPageInstance.selectionMode) {
                        root.mainPageInstance.toggleNoteSelection(root.noteId);

                    } else {
                        pageStack.push(Qt.resolvedUrl("../pages/NotePage.qml"), {
                            onNoteSavedOrDeleted: root.mainPageInstance ? root.mainPageInstance.refreshData : null,
                            noteId: root.noteId,
                            noteTitle: root.title,
                            noteContent: root.content,
                            noteIsPinned: root.noteIsPinned,
                            noteTags: root.tags,
                            noteCreationDate: root.noteCreationDate,
                            noteEditDate: root.noteEditDate,
                            noteColor: root.cardColor

                        });
                        console.log("Opening NotePage in EDIT mode for ID:", root.noteId, "from NoteCard. Color:", root.cardColor);
                        Qt.inputMethod.hide();
                        if (root.mainPageInstance && typeof root.mainPageInstance.searchField !== 'undefined') {
                           root.mainPageInstance.searchField.focus = false;
                        }
                    }
                }
            }
            root.pressActive = false;
        }
        onCanceled: {
            longPressTimer.stop();
            root.pressActive = false;
            root.scale = 1.0;
        }
        onPositionChanged: {
            var threshold = 10;
            if (root.pressActive && (Math.abs(mouse.x - root.pressX) > threshold || Math.abs(mouse.y - root.pressY) > threshold)) {
                longPressTimer.stop();
                root.pressActive = false;
                root.scale = 1.0;
            }
        }
    }
}

/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/note_cards/TrashArchiveNoteCard.qml
 * Этот файл представляет собой специализированный компонент карточки
 * для отображения заметок в корзине или архиве. Отличается от
 * обычной карточки наличием чекбокса для массового выбора.
 * Нажатие на саму карточку открывает заметку для просмотра, а нажатие
 * на чекбокс изменяет состояние ее выбора. Также отображает информацию
 * о дате окончательного удаления для заметок в корзине.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "../services/DatabaseManagerService.js" as DB

Item {
    id: root
    width: parent ? parent.width : 360

    implicitHeight: mainCardRectangle.implicitHeight + 10
    property string title: ""
    property string content: ""
    property string tags: ""
    property string cardColor: DB.getThemeColor() || "#121218"
    property string borderColor:  DB.darkenColor((root.cardColor), -0.3)
    property bool isSelected: false
    property int noteId: -1

    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()

    property color selectedBorderColor: "#00000000"
    property int selectedBorderWidth: 0

    signal selectionToggled(int noteId, bool isCurrentlySelected)
    signal noteClicked(int noteId, string title, string content, bool isPinned, var tags, date creationDate, date editDate, string color, bool isArchived, bool isDeleted)

    Rectangle {
        id: mainCardRectangle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 20
        implicitHeight: cardColumn.implicitHeight + (Theme.paddingLarge * 2)
        color: root.cardColor
        radius: 20
        border.color: root.borderColor
        border.width: 2

        states: [
            State {
                name: "selectedCard"
                when: root.isSelected === true
                PropertyChanges {
                    target: mainCardRectangle
                    border.color: "#FFFFFF"
                    border.width: 4
                }
            },
            State {
                name: "deselectedCard"
                when: root.isSelected === false
                PropertyChanges {
                    target: mainCardRectangle
                    border.color: root.borderColor
                    border.width: 2
                }
            }
        ]

        transitions: Transition {
            PropertyAnimation { properties: "border.color,border.width"; duration: 150 }
        }

        MouseArea {
            id: wholeCardMouseArea
            anchors.fill: parent

            onClicked: {
                console.log("TrashArchiveNoteCard (ID:", root.noteId, "): Full card clicked. Emitting noteClicked signal.");
                root.noteClicked(
                    root.noteId,
                    root.title,
                    root.content,
                    root.noteIsPinned,
                    root.tags,
                    root.noteCreationDate,
                    root.noteEditDate,
                    root.cardColor,
                    false,
                    true
                );
                Qt.inputMethod.hide();
            }
        }

        Item {
            id: checkboxClickArea
            anchors {  right: parent.right; rightMargin: Theme.paddingMedium }
            width: Theme.iconSizeSmall * 2.4
            height: width

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.selectionToggled(root.noteId, root.isSelected);
                    console.log("TrashArchiveNoteCard (ID:", root.noteId, "): Checkbox click detected. Emitting selectionToggled for ID:", root.noteId, "Current isSelected:", root.isSelected);
                }
            }

            Rectangle {
                id: visualCheckbox
                anchors.centerIn: parent
                height: 47
                width: 47
                radius: 17

                color: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#32353a"
                border.color: Theme.secondaryColor !== undefined ? Theme.secondaryColor : "#00bcd4"
                border.width: 2

                states: [
                    State {
                        name: "selected"
                        when: root.isSelected === true
                        PropertyChanges {
                            target: visualCheckbox
                            color: "#FFFFFF"
                            border.color: "transparent"
                            border.width: 0
                        }
                    },
                    State {
                        name: "deselected"
                        when: root.isSelected === false
                        PropertyChanges {
                            target: visualCheckbox
                            color: Theme.backgroundColor !== undefined ? Theme.backgroundColor : "#32353a"
                            border.color: Theme.secondaryColor !== undefined ? Theme.secondaryColor : "#00bcd4"
                            border.width: 2
                        }
                    }
                ]

                transitions: Transition {
                    PropertyAnimation { properties: "color,border.color,border.width"; duration: 150 }
                }
            }
        }

        ColumnLayout {
            id: cardColumn
            anchors {
                left: parent.left; leftMargin: Theme.paddingLarge
                right: parent.right; rightMargin: Theme.paddingLarge
                top: parent.top; topMargin: Theme.paddingLarge
                bottom: parent.bottom; bottomMargin: Theme.paddingLarge
            }
            spacing: Theme.paddingSmall

            Label {
                Layout.fillWidth: true
                text: (root.title && root.title.trim()) ? root.title : qsTr("Empty")
                font.italic: !(root.title && root.title.trim())
                horizontalAlignment: "AlignHCenter"
                color: "#e8eaed"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap

            }
            Rectangle {
                width: parent.width
                height: 8
                color: "transparent"
            }
            Label {
                Layout.fillWidth: true
                text: (root.content && root.content.trim()) ? root.content : qsTr("Empty")
                font.italic: !(root.content && root.content.trim())
                textFormat: Text.PlainText
                horizontalAlignment: "AlignJustify"
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: "#c5c8d0"
            }
            Rectangle {
                width: parent.width
                height: 4
                color: "transparent"
            }

            Flow {
                id: tagsFlow
                Layout.fillWidth: true
                spacing: Theme.paddingSmall
                visible: root.tags && root.tags.trim().length > 0

                Repeater {
                    model: root.tags.split("_||_").filter(function(tag) { return tag.trim() !== "" })
                    delegate: Rectangle {
                        visible: index < 2
                        color: "#a032353a"
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
                    visible: root.tags.split("_||_").filter(function(tag) { return tag.trim() !== "" }).length > 2
                    color: "#a032353a"
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (root.tags.split("_||_").filter(function(tag) { return tag.trim() !== "" }).length - 2)
                        color: "#c5c8d0"
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                    }
                }
            }
            Label {
                visible: modelData.updated_at !== undefined && modelData.updated_at !== null && modelData.updated_at !== "" && modelData.deleted
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (modelData.updated_at) {
                        var deletedAt = new Date(modelData.updated_at);
                        var thirtyDaysLater = new Date(deletedAt);
                        thirtyDaysLater.setDate(deletedAt.getDate() + 30);

                        var formattedDate = Qt.formatDateTime(thirtyDaysLater, "dd.MM.yyyy");

                        return qsTr("Will be permanently deleted on: %1").arg(formattedDate);
                    }
                    return "";
                }
                font.italic: true
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }
}

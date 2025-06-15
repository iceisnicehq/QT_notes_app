// TrashNoteCard.qml (Corrected version)

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
    property var trashPageInstance: null // Reference to TrashPage

    // NEW: Add properties passed from NoteCard
    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()
    property bool isFromTrash: true // Default to true for TrashNoteCard

    // --- Signals ---
    signal selectionToggled(int noteId, bool isSelected)
    // CORRECTED: Declare 'noteClicked' as a signal with its parameters
    signal noteClicked(int noteId, string title, string content, bool isPinned, var tags, date creationDate, date editDate, string color, bool isArchived, bool isDeleted)


    // --- UI Components ---
    Rectangle {
        anchors.fill: parent
        color: root.cardColor
        radius: 20
        border.color: "#43484e"
        border.width: 1

        MouseArea {
            id: wholeCardMouseArea
            anchors.fill: parent

            onClicked: {
                console.log("TrashNoteCard (ID:", root.noteId, "): Full card clicked. Emitting noteClicked signal.");
                // CORRECTED: Emit the 'noteClicked' signal
                // Pass all necessary data directly from the model/root properties
                root.noteClicked(
                    root.noteId,
                    root.title,
                    root.content,
                    root.noteIsPinned,
                    root.tags, // Ensure this is handled as an array if NotePage expects it
                    root.noteCreationDate,
                    root.noteEditDate,
                    root.cardColor,
                    false, // isArchived: TrashNoteCard is not for archived notes by itself
                    true   // isDeleted: TrashNoteCard implies it's from trash
                );
                Qt.inputMethod.hide(); // Hide keyboard
            }
        }

        // --- Checkbox container with enlarged click area ---
        Item {
            id: checkboxClickArea
            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: Theme.paddingMedium }
            width: Theme.iconSizeSmall * 1.5
            height: width

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.isSelected = !root.isSelected;
                    root.selectionToggled(root.noteId, root.isSelected); // Emit signal
                    console.log("TrashNoteCard (ID:", root.noteId, "): Checkbox clicked. isSelected:", root.isSelected);
                }
            }

            Rectangle {
                id: visualCheckbox
                anchors.centerIn: parent
                width: Theme.iconSizeSmall
                height: width
                radius: 4

                color: root.isSelected ? Theme.secondaryColor : "transparent"
                border.color: root.isSelected ? "transparent" : Theme.secondaryColor
                border.width: root.isSelected ? 0 : 2
            }
        }

        // Column for card content
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

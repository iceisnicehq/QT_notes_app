// NoteCard.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent ? parent.width : 360
    height: cardColumn.implicitHeight + Theme.paddingLarge * 2 + 20 // Adjusted bottom margin

    // --- MODIFIED: Changed from 'alias' to 'property' ---
    // Using a real property allows us to add logic before displaying the text.
    property string title: ""
    property string content: ""
    property var tags: [] // This property receives a string like "tag1 tag2" or ""

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 20
        border.color: "#43484e"
        border.width: 2
        anchors.bottomMargin: 20 // This margin affects the root Item's height
        Column {
            id: cardColumn
            anchors {
                left: parent.left; leftMargin: Theme.paddingLarge
                right: parent.right; rightMargin: Theme.paddingLarge
                top: parent.top; topMargin: Theme.paddingLarge
                bottom: parent.bottom; bottomMargin: Theme.paddingLarge
            }
            spacing: Theme.paddingSmall

            // Title
            Text {
                id: titleText
                // --- MODIFIED: Logic to handle empty/null title ---
                // 1. Display "no name" if root.title is empty, null, or just whitespace.
                // 2. Set font to italic if the title is considered empty.
                text: (root.title && root.title.trim()) ? root.title : "Empty"
                font.italic: !(root.title && root.title.trim())

                // --- ADDED: Ensure title text is not parsed as HTML ---
                textFormat: Text.PlainText

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
            // Content (max 5 lines with ellipsis)
            Text {
                id: contentText
                // --- MODIFIED: Bind to the new root.content property ---
                text: (root.content && root.content.trim()) ? root.content : "Empty"
                font.italic: !(root.content && root.content.trim())
                // --- ADDED: This is the key change to fix the HTML issue ---
                // It forces the text to be rendered literally, ignoring tags like <b>.
                textFormat: Text.PlainText

                wrapMode: Text.WordWrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: "#e8eaed"
                width: parent.width
            }
            Rectangle {
                width: parent.width
                height: 4
                color: "transparent"
            }
            // Tags
            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall
                visible: tags.trim().length > 0

                Repeater {
                    model: tags.split(" ")
                    delegate: Rectangle {
                        visible: index < 2
                        color: "#32353a"
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
                    visible: tags.split(" ").length > 2
                    color: "#32353a"
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (tags.split(" ").length - 2)
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

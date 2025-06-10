// NoteCard.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent ? parent.width : 360
    height: cardColumn.implicitHeight + Theme.paddingLarge * 2 + 20 // Adjusted bottom margin
    property alias title: titleText.text
    property alias content: contentText.text
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
                text: ""
                color: "#e8eaed"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Rectangle {
                width: parent.width
                height: 8
                color: "transparent"
            }
            // Content (max 5 lines with ellipsis)
            Text {
                id: contentText
                text: ""
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
                // --- ADDED: Make the entire Flow invisible if tags string is empty ---
                visible: tags.trim().length > 0 // Checks if the trimmed tags string has content

                Repeater {
                    // Split the tags string into an array for the model
                    model: tags.split(" ")
                    delegate: Rectangle {
                        visible: index < 2 // Only show the first two tags
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
                        }
                    }
                }

                // "+N" indicator for remaining tags
                Rectangle {
                    // This will only be visible if the tags string (split into array) has more than 2 elements
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

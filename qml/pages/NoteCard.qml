// NoteCard.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent ? parent.width : 360
    height: cardColumn.implicitHeight + Theme.paddingLarge * 2 + 25
    property alias title: titleText.text
    property alias content: contentText.text
    property var tags: []

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 20
        border.color: "#43484e"
        border.width: 2
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
                height: 8  // Adjust height as needed
                color: "transparent"
            }
            // Content (max 5 lines with ellipsis)
            Text {
                id: contentText
                text: ""
                wrapMode: Text.WordWrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeMedium
                color: "#e8eaed"
                width: parent.width
            }
            Rectangle {
                width: parent.width
                height: 4  // Adjust height as needed
                color: "transparent"
            }
            // Tags
            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall

                Repeater {
                    model: tags.split(" ")
                    delegate: Rectangle {
                        color: "#32353a"  // Dark gray background
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium, parent.width)

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"  // Light gray text
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
            }
        }
    }
}

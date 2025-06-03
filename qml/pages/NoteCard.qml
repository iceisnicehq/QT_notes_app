// NoteCard.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent ? parent.width : 360
    property alias title: titleText.text
    property alias content: contentText.text
    property alias tags: tagsText.text

    Rectangle {
        anchors.fill: parent
        color: Theme.colorBackground
        radius: Theme.radiusLarge
        border.color: Theme.colorFrame
        border.width: 1

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
                font.pixelSize: Theme.fontSizeLarge
                wrapMode: Text.WordWrap
                color: Theme.colorText
            }

            // Content (max 5 lines)
            Text {
                id: contentText
                text: ""
                wrapMode: Text.WordWrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.colorSecondaryText
            }

            // Tags
            Text {
                id: tagsText
                text: ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.colorAccent
            }
        }
    }

    height: cardColumn.implicitHeight + Theme.paddingLarge * 2
}

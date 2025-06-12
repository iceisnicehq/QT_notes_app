// TrashNoteCard.qml (ПОЛНЫЙ ФАЙЛ)

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent ? parent.width : 360
    implicitHeight: cardColumn.implicitHeight + (Theme.paddingLarge * 2)

    property string title: ""
    property string content: ""
    property string tags: ""
    property string cardColor: "#1c1d29"
    property bool isSelected: false
    signal selectionToggled(int noteId, bool isSelected)
    property int noteId: -1

    Rectangle {
        anchors.fill: parent
        color: root.cardColor
        radius: 20
        border.color: "#43484e"
        border.width: 2

        // Кастомный "белый шарик" (чекбокс)
        Rectangle {
            id: selectionIndicator
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: Theme.paddingMedium
            anchors.topMargin: Theme.paddingMedium

            width: Theme.iconSizeSmall
            height: width
            radius: width / 2

            color: root.isSelected ? Theme.highlightColor
                                   : Theme.primaryColor
            border.color: root.isSelected ? "transparent"
                                          : Theme.secondaryColor
            border.width: root.isSelected ? 0 : 2

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.isSelected = !root.isSelected
                    root.selectionToggled(root.noteId, root.isSelected)
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
                textFormat: Text.PlainText
                color: "#e8eaed"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap
                width: parent.width - (Theme.paddingLarge * 2) - selectionIndicator.width - Theme.paddingMedium
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
                color: "#e8eaed"
                width: parent.width
            }

            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall
                visible: root.tags && root.tags.trim().length > 0

                Repeater {
                    model: root.tags.split(" ")
                    delegate: Rectangle {
                        visible: index < 2 && modelData.trim().length > 0
                        color: "#32353a"
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium * 2, root.width * 0.45)

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            elide: Text.ElideRight
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width - Theme.paddingSmall * 2
                            wrapMode: Text.NoWrap
                            textFormat: Text.PlainText
                        }
                    }
                }

                Rectangle {
                    visible: root.tags && root.tags.split(" ").length > 2
                    color: "#32353a"
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (root.tags.split(" ").length - 2)
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

// MainPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import "Database.js" as DB

Page {
    objectName: "mainPage"
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            // Search Bar Area
            SearchField {
                id: searchField
                width: parent.width
                placeholderText: "Search notes..."

                EnterKey.onClicked: {
                    console.log("Searching for:", text)
                }

                leftItem: IconButton {
                    icon.source: "image://theme/icon-m-menu"
                    onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                }

                rightItem: Row {
                    spacing: Theme.paddingSmall
                    IconButton {
                        icon.source: "image://theme/icon-m-plus"
                        onClicked: {
                            console.log("Create new note clicked")
                        }
                    }
                    IconButton {
                        icon.source: "image://theme/icon-m-view-list"
                        onClicked: {
                            console.log("Second button clicked")
                        }
                    }
                }
            }

            // Pinned Notes Section
            SectionHeader {
                text: qsTr("Pinned")
            }

            ListView {
                width: parent.width
                height: contentHeight
                model: DB.notes.filter(function(note) { return note.pinned; })
                delegate: NoteCard {
                    width: parent.width
                    title: modelData.title
                    content: modelData.content
                    tags: modelData.tags.join(' ')
                }
            }

            // Other Notes Section
            SectionHeader {
                text: qsTr("Others")
            }

            ListView {
                width: parent.width
                height: contentHeight
                model: DB.notes.filter(function(note) { return !note.pinned; })
                delegate: NoteCard {
                    width: parent.width
                    title: modelData.title
                    content: modelData.content
                    tags: modelData.tags.join(' ')
                }
            }
        }
    }
}

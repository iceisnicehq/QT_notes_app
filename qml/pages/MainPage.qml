// MainPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import "Database.js" as DB

Page {
    id: mainPage
    objectName: "mainPage"
    allowedOrientations: Orientation.All
    backgroundColor: "#121318"
    property int noteMargin: 20;

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingSmall

            // Search Bar Area
            Item {
                width: parent.width
                height: 80

                Rectangle {
                    id: searchBarContainer
                    anchors.fill: parent
                    color: "#2e2f34"  // Your gray background
                    radius: 80
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: noteMargin
                        rightMargin: noteMargin
                    }
                    SearchField {
                        id: searchField
                        anchors.fill: parent
                        placeholderText: "Search notes..."
//                        backgroundVisible: false  // Remove default background

                        EnterKey.onClicked: {
                            console.log("Searching for:", text)
                        }

                        leftItem: Icon {
                            source: "image://theme/icon-m-menu"
                            width: Theme.fontSizeExtraLargeBase
                            height: Theme.fontSizeExtraLargeBase * 1.3
                            IconButton {
                                onClicked: {
                                    pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                                    console.log("Second button clicked")
                                }
                            }
                        }


                        rightItem: Row {
                            spacing: Theme.paddingSmall
                            IconButton {
                                icon.source: "image://theme/icon-m-menu"  // Placeholder for plus icon
                                width: Theme.fontSizeMedium
                                height: Theme.fontSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    console.log("Create new note clicked")
                                }
                            }
                            IconButton {
                                icon.source: "image://theme/icon-m-view-list"
                                width: Theme.fontSizeMedium
                                height: Theme.fontSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    console.log("Second button clicked")
                                }
                            }
                        }
                    }
                }
            }
            // Pinned Notes Section
            Column {
                id: pinnedSection
                width: parent.width
                spacing: 0  // Adjust as needed

                SectionHeader {
                    text: qsTr("Pinned")
                    color: "#e2e3e8"
                    horizontalAlignment: Text.AlignLeft
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge + 19
                }

                ListView {
                    id: pinnedNotes

                    width: parent.width
                    height: contentHeight
                    model: DB.notes.filter(function(note) { return note.pinned; })
                    delegate: NoteCard {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: noteMargin
                            rightMargin: noteMargin
                        }
                        width: parent.width
                        title: modelData.title
                        content: modelData.content
                        tags: modelData.tags.join(' ')
                    }
                }
            }

            // Other Notes Section
            Column {
                id: othersSection
                width: parent.width
                spacing: 0 // Adjust as needed

                SectionHeader {
                    text: qsTr("Others")
                    color: "#e2e3e8"
                    horizontalAlignment: Text.AlignLeft
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge + 19
                }

                ListView {
                    id: otherNotes

                    width: parent.width
                    spacing: 0  // We'll handle spacing within the delegate
                    height: contentHeight
                    model: DB.notes.filter(function(note) { return !note.pinned; })
                    delegate: NoteCard {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: noteMargin
                            rightMargin: noteMargin
                        }
                        width: parent.width
                        title: modelData.title
                        content: modelData.content
                        tags: modelData.tags.join(' ')
                    }
                }
            }
        }
    }
}

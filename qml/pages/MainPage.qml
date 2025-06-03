// MainPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import "Database.js" as DB

Page {
    id: mainPage
    objectName: "mainPage"
    allowedOrientations: Orientation.All
    backgroundColor: "#121218"
    property int noteMargin: 20

    // Properties to track scroll behavior
    property bool headerVisible: true
    property real previousContentY: 0

    // Search Bar Area - Positioned above the Flickable
    Item {
        id: searchBarArea
        width: parent.width
        height: 80
        z: 2 // Ensures the header appears ON TOP of the list content

        // Animate the y-position based on the headerVisible property
        y: headerVisible ? 0 : -height

        // THIS IS THE FIX: The Behavior is now simplified to always be active.
        Behavior on y {
            // The "enabled" condition has been removed.
            NumberAnimation {
                duration: 250 // You can adjust this duration for speed
                easing.type: Easing.OutQuad // A nice easing for this effect
            }
        }

        Rectangle {
            id: searchBarContainer
            width: parent.width - (noteMargin * 2)
            height: parent.height
            anchors.centerIn: parent
            color: "#1c1d29"
            radius: 80

            SearchField {
                id: searchField
                anchors.fill: parent
                placeholderText: "Search notes..."

                // ... (rest of your SearchField is unchanged)
                EnterKey.onClicked: {
                    console.log("Searching for:", text)
                }

                leftItem: Icon {
                    source: "../icons/menu.svg"
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    IconButton {
                         anchors.fill: parent
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                            console.log("Menu button clicked")
                        }
                    }
                }

                rightItem: Row {
                    spacing: Theme.paddingSmall
                    IconButton {
                        icon.source: "image://theme/icon-m-add"
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

    // The main scrollable area
    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        topMargin: searchBarArea.height

        // The logic for showing/hiding the header remains the same
        onContentYChanged: {
            var scrollY = flickable.contentY;

            if (flickable.atYBeginning) {
                mainPage.headerVisible = true;
            } else if (scrollY < mainPage.previousContentY) {
                mainPage.headerVisible = true;
            } else if (scrollY > mainPage.previousContentY && scrollY > searchBarArea.height) {
                mainPage.headerVisible = false;
            }

            mainPage.previousContentY = scrollY;
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingSmall

            // Pinned Notes Section
            Column {
                id: pinnedSection
                width: parent.width
                spacing: 0

                SectionHeader {
                    text: qsTr("Pinned")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: "#e2e3e8"
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge + 19
                    horizontalAlignment: Text.AlignLeft

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
                // ... (rest of your code is unchanged) ...
                id: othersSection
                width: parent.width
                spacing: 0 // Adjust as needed

                SectionHeader {
                    text: qsTr("Others")
                    font.pixelSize: Theme.fontSizeExtraSmall
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

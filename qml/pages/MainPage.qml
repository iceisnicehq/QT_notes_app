// MainPage.qml
import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import "Database.js" as Data          // <-- здесь будет доступен массив Data.notes
import "DatabaseManager.js" as DB

Page {

    id: mainPage
    objectName: "mainPage"
    allowedOrientations: Orientation.All
    backgroundColor: "#121218"
    property int noteMargin: 20

    // Properties to track scroll behavior
    property bool headerVisible: true
    property real previousContentY: 0
    property bool panelOpen: false
    property var allNotes: []
    property var allTags: []

//    ToastManager {
//        id: toastManager // The ToastManager now lives directly within MainPage
//    }
//    Timer {
//        interval: 1000
//        repeat: true
//        running: true
//        property int i: 0
//        onTriggered: {
//            toastManager.show("This timer has triggered " + (++i) + " times!");
//        }
//    }
    Component.onCompleted: {
        DB.initDatabase()
        DB.insertTestData()  // ← Adds test data
        refreshData()
    }
    function refreshData() {
        allNotes = DB.getAllNotes();
        allTags = DB.getAllTags();
    }
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
                highlighted: false
//                focusOutBehavior: FocusBehavior.ClearPageFocus
                // ... (rest of your SearchField is unchanged)
                EnterKey.onClicked: {
                    console.log("Searching for:", text)
                }
                // Left menu button
            leftItem: Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 0.95
                clip: false  // Important: do not clip!

                Icon {
                    id: menuIcon
                    source: "../icons/menu.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }

                RippleEffect {
                    id: menuRipple
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mainPage.panelOpen = true
                        console.log("Menu button clicked → panelOpen = true")
                    }
                    onPressed: menuRipple.ripple(mouseX, mouseY)
                }
            }

            // Right plus button
            rightItem: Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false  // Important: do not clip!

                Icon {
                    id: plusIcon
                    source: "../icons/plus.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }

                RippleEffect {
                    id: plusRipple
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // --- CREATE NOTE: Push NewNotePage without pre-filling data ---
                        pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                            onNoteSavedOrDeleted: refreshData,
                            noteId: -1, // Explicitly pass -1 for new notes
                            noteTitle: "",
                            noteContent: "",
                            noteIsPinned: false,
                            noteTags: [],
                            noteCreationDate: new Date(), // New notes start with current date
                            noteEditDate: new Date()      // New notes start with current date
                        });
                        console.log("Opening NewNotePage in CREATE mode.");
                    }
                    onPressed: plusRipple.ripple(mouseX, mouseY)
                }
            }
            }
        }
    }
    SidePanel {
        id: sidePanel
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        open: panelOpen
        tags: allTags
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
                    model: allNotes.filter(function(note) { return note.pinned; })
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

                        // --- ADDED: MouseArea to make NoteCard clickable for editing ---
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: refreshData,
                                    noteId: modelData.id,        // Pass existing ID
                                    noteTitle: modelData.title,  // Pass existing title
                                    noteContent: modelData.content, // Pass existing content
                                    noteIsPinned: modelData.pinned, // Pass existing pinned status
                                    noteTags: modelData.tags,     // Pass existing tags
                                    noteCreationDate: new Date(modelData.created_at + "Z"), // Pass existing creation date
                                    noteEditDate: new Date(modelData.updated_at + "Z")
                                });
                                console.log("Opening NewNotePage in EDIT mode for ID:", modelData.id);
                            }
                        }
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
                    model: allNotes.filter(function(note) { return !note.pinned; })
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

                        // --- ADDED: MouseArea to make NoteCard clickable for editing ---
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: refreshData,
                                    noteId: modelData.id,        // Pass existing ID
                                    noteTitle: modelData.title,  // Pass existing title
                                    noteContent: modelData.content, // Pass existing content
                                    noteIsPinned: modelData.pinned, // Pass existing pinned status
                                    noteTags: modelData.tags,     // Pass existing tags
                                    noteCreationDate: new Date(modelData.created_at + "Z"), // Pass existing creation date
                                    noteEditDate: new Date(modelData.updated_at + "Z")      // Pass existing edit date
                                });
                                console.log("Opening NewNotePage in EDIT mode for ID:", modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }
    // --- YOUR SCROLLBAR GOES RIGHT HERE, as a direct child of Page ---
    ScrollBar {
        // You can still give it an ID if you want to reference it later, e.g., id: myPageScrollBar
        flickableSource: flickable // Pass the ID of your SilicaFlickable
        topAnchorItem: searchBarArea // Pass the ID of your header/search bar Item
    }
}

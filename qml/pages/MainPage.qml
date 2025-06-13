// MainPage.qml (UPDATED)

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import "Database.js" as Data
import "DatabaseManager.js" as DB

Page {
    id: mainPage
    objectName: "mainPage"
    allowedOrientations: Orientation.All
    backgroundColor: "#121218"
    property int noteMargin: 20

    property bool headerVisible: true
    property real previousContentY: 0
    property bool panelOpen: false
    property var allNotes: []
    property var allTags: []

    Component.onCompleted: {
        DB.initDatabase()
        DB.insertTestData()
        refreshData()
    }

    // Corrected: Using onStatusChanged for page activation detection
    onStatusChanged: {
        // When MainPage becomes active (topmost in PageStack), clear search field focus and hide keyboard.
        if (mainPage.status === PageStatus.Active) {
            refreshData()
            searchField.focus = false;
            Qt.inputMethod.hide(); // Explicitly hide the keyboard
            console.log("MainPage active (status changed to Active), search field focus cleared and keyboard hidden.");
        }
    }

    function refreshData() {
        allNotes = DB.getAllNotes(); // This now only gets non-deleted notes
        allTags = DB.getAllTags(); // This now only gets tags linked to non-deleted notes
    }

    // Search Bar Area - Positioned above the Flickable
    Item {
        id: searchBarArea
        width: parent.width
        height: 80
        z: 2

        y: headerVisible ? 0 : -height

        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuad
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
                EnterKey.onClicked: {
                    console.log("Searching for:", text)
                    // Optionally hide keyboard after search if not automatically done
                    Qt.inputMethod.hide();
                    searchField.focus = false; // Clear focus after search
                }
                leftItem: Item {
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    clip: false

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
                            Qt.inputMethod.hide();
                            searchField.focus = false; // Clear focus when opening panel
                        }
                        onPressed: menuRipple.ripple(mouseX, mouseY)

                    }
                }

                rightItem: Item {
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 1.1
                    clip: false

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
                                noteId: -1,
                                noteTitle: "",
                                noteContent: "",
                                noteIsPinned: false,
                                noteTags: [],
                                noteCreationDate: new Date(),
                                noteEditDate: new Date(),
                                noteColor: "#121218"
                            });
                            console.log("Opening NewNotePage in CREATE mode.");
                            Qt.inputMethod.hide();
                            searchField.focus = false; // Clear focus before navigating
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

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        topMargin: searchBarArea.height

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
                        cardColor: modelData.color || "#1c1d29"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Qt.inputMethod.hide();
                                searchField.focus = false; // Clear focus before navigating
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: refreshData,
                                    noteId: modelData.id,
                                    noteTitle: modelData.title,
                                    noteContent: modelData.content,
                                    noteIsPinned: modelData.pinned,
                                    noteTags: modelData.tags,
                                    noteCreationDate: new Date(modelData.created_at + "Z"),
                                    noteEditDate: new Date(modelData.updated_at + "Z"),
                                    noteColor: modelData.color
                                });
                                console.log("Opening NewNotePage in EDIT mode for ID:", modelData.id + ", Color:", modelData.color);
                            }
                        }
                    }
                }
            }

            // Other Notes Section
            Column {
                id: othersSection
                width: parent.width
                spacing: 0

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
                    spacing: 0
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
                        cardColor: modelData.color || "#1c1d29"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchField.focus = false; // Clear focus before navigating
                                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                    onNoteSavedOrDeleted: refreshData,
                                    noteId: modelData.id,
                                    noteTitle: modelData.title,
                                    noteContent: modelData.content,
                                    noteIsPinned: modelData.pinned,
                                    noteTags: modelData.tags,
                                    noteCreationDate: new Date(modelData.created_at + "Z"),
                                    noteEditDate: new Date(modelData.updated_at + "Z"),
                                    noteColor: modelData.color
                                });
                                console.log("Opening NewNotePage in EDIT mode for ID:", modelData.id + ", Color:", modelData.color);
                            }
                        }
                    }
                }
            }
        }
    }

    ScrollBar {
        flickableSource: flickable
        topAnchorItem: searchBarArea
    }
}

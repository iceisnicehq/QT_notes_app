// SearchPage.qml

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import "DatabaseManager.js" as DB

Page {
    id: searchPage
    objectName: "searchPage"
    allowedOrientations: Orientation.All
    backgroundColor: "#121218"
    property int noteMargin: 20

    // Callback to refresh data on the MainPage after navigating back
    property var onSearchCompleted: function() {}

    property var allTags: [] // All available tags from the database
    property var selectedTags: [] // Tags currently selected for filtering
    property var searchResults: [] // Notes matching the search criteria
    property bool tagPickerOpen: false // Controls visibility of the tag picker overlay

    Component.onCompleted: {
        DB.initDatabase();
        // Fetch all available tags when the page is loaded
        allTags = DB.getAllTags();
        // Perform an initial search with empty criteria
        performSearch("", []);
    }

    // Function to handle adding/removing tags from selectedTags
    function toggleTagSelection(tagName) {
        if (selectedTags.includes(tagName)) {
            selectedTags = selectedTags.filter(function(tag) { return tag !== tagName; });
            console.log("SEARCH_PAGE: Removed tag:", tagName, "Selected tags:", JSON.stringify(selectedTags));
        } else {
            selectedTags = selectedTags.concat(tagName);
            console.log("SEARCH_PAGE: Added tag:", tagName, "Selected tags:", JSON.stringify(selectedTags));
        }
        // Trigger search whenever selected tags change
        performSearch(searchField.text, selectedTags);
    }

    // Main search function that calls the DatabaseManager
    function performSearch(text, tags) {
        searchResults = DB.searchNotes(text, tags);
        console.log("SEARCH_PAGE: Search performed. Results count:", searchResults.length);
    }

    PageHeader {
        id: searchHeader
        title: qsTr("Search Notes")
        anchors.left: parent.left
        anchors.right: parent.right
        z: 2
        // Custom left item to go back
//        leftItem: Item {
//            width: Theme.fontSizeExtraLarge * 1.1
//            height: Theme.fontSizeExtraLarge * 1.1
//            clip: false

//            Icon {
//                source: "../icons/back.svg" // Assuming a back icon exists
//                anchors.centerIn: parent
//                width: parent.width
//                height: parent.height
//            }

//            RippleEffect { }

//            MouseArea {
//                anchors.fill: parent
//                onClicked: {
//                    pageStack.pop();
//                    onSearchCompleted(); // Trigger refresh on MainPage
//                    console.log("SEARCH_PAGE: Back button clicked.");
//                }
//            }
//        }
    }

    // Search Bar Area
    Item {
        id: searchInputArea
        width: parent.width
        height: 80
        anchors.top: searchHeader.bottom
        z: 1 // Below header, above flickable

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
                placeholderText: "Search by keywords..."
                highlighted: false
                // Trigger search on text change or Enter key
                onTextChanged: {
                    performSearch(text, selectedTags);
                }
                EnterKey.onClicked: {
                    console.log("SEARCH_PAGE: Keyword search triggered:", text);
                    performSearch(text, selectedTags);
                }
                leftItem: Item {
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    clip: false

                    // Icon for opening tag picker
                    Icon {
                        source: "../icons/tag.svg" // Assuming a tag icon exists
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                    }

                    RippleEffect {}

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchPage.tagPickerOpen = true;
                            console.log("SEARCH_PAGE: Tag picker opened.");
                        }
                    }
                }
                rightItem: Item {
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 1.1
                    clip: false

                    // Icon for clearing search or other action
                    Icon {
                        source: "../icons/clear.svg" // Assuming a clear icon exists
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                    }

                    RippleEffect { }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchField.text = ""; // Clear search text
                            selectedTags = []; // Clear selected tags
                            performSearch("", []); // Perform search with empty criteria
                            console.log("SEARCH_PAGE: Search cleared.");
                        }
                    }
                }
            }
        }
    }

    // Section to display selected tags
    Item {
        id: selectedTagsArea
        width: parent.width
        height: childrenRect.height // Adjust height based on content
        anchors.top: searchInputArea.bottom
        anchors.topMargin: Theme.paddingSmall
        visible: selectedTags.length > 0 // Only visible if tags are selected

        Column {
            width: parent.width - (noteMargin * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall / 2

            Text {
                text: qsTr("Filter Tags:")
                font.pixelSize: Theme.fontSizeSmall
                color: "#e2e3e8"
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingSmall
            }

            Flow {
                width: parent.width
                spacing: Theme.paddingSmall / 2
                // Dynamic creation of components for each selected tag
                Repeater {
                    model: selectedTags
                    delegate: BackgroundItem {
                        width: implicitWidth
                        height: Theme.itemSizeSmall
            //            radius: 10
            //            color: "#34374a"

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.paddingSmall / 2

                            Text {
                                text: modelData
                                font.pixelSize: Theme.fontSizeSmall
                                color: "#e2e3e8"
                            }

                            // Icon to remove tag
                            Icon {
                                source: "../icons/close.svg" // Assuming a close icon exists
                                width: Theme.fontSizeSmall * 0.8
                                height: Theme.fontSizeSmall * 0.8
                                color: "#e2e3e8" // Optional: color for the icon

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        searchPage.toggleTagSelection(modelData);
                                        console.log("SEARCH_PAGE: Removed tag from selected:", modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Flickable for search results
    SilicaFlickable {
        id: resultsFlickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: selectedTagsArea.bottom
        anchors.bottom: parent.bottom
        contentHeight: resultsColumn.height
        clip: true

        Column {
            id: resultsColumn
            width: parent.width
            spacing: Theme.paddingSmall
          //  padding.top: Theme.paddingSmall
        //    padding.bottom: Theme.paddingSmall

            // Display "No Results" if searchResults is empty
            Loader {
                sourceComponent: searchResults.length === 0 ? noResultsComponent : undefined
                width: parent.width
                height: childrenRect.height
            }

            Component {
                id: noResultsComponent
                Column {
                    width: parent.width
                    height: 200 // Fixed height for no results message
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingMedium
                    Text {
                        text: qsTr("No notes found matching your criteria.")
                        font.pixelSize: Theme.fontSizeMedium
                        color: "#e2e3e8"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - (noteMargin * 2)
                        wrapMode: Text.WordWrap
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: qsTr("Try a different keyword or fewer tags.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#999"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - (noteMargin * 2)
                        wrapMode: Text.WordWrap
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // List of search results
            Repeater {
                model: searchResults
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
                            // Open NotePage for editing the selected note
                            pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                                onNoteSavedOrDeleted: function() {
                                    // Refresh search results after note is saved/deleted
                                    searchPage.performSearch(searchField.text, searchPage.selectedTags);
                                    // Also notify MainPage to refresh
                                    searchPage.onSearchCompleted();
                                },
                                noteId: modelData.id,
                                noteTitle: modelData.title,
                                noteContent: modelData.content,
                                noteIsPinned: modelData.pinned,
                                noteTags: modelData.tags,
                                noteCreationDate: new Date(modelData.created_at + "Z"),
                                noteEditDate: new Date(modelData.updated_at + "Z"),
                                noteColor: modelData.color
                            });
                            console.log("SEARCH_PAGE: Opening NotePage in EDIT mode for ID:", modelData.id);
                        }
                    }
                }
            }
        }
    }

    ScrollBar {
        flickableSource: resultsFlickable
    }

    // --- Tag Picker Overlay and Panel ---
    Rectangle {
        id: tagPickerOverlay
        anchors.fill: parent
        color: "#000000" // Black background
        opacity: tagPickerOpen ? 0.6 : 0.0 // Darken effect
        z: 3 // Above all other content
        visible: tagPickerOpen // Control visibility
        smooth: true
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                searchPage.tagPickerOpen = false; // Close picker when clicking overlay
                console.log("SEARCH_PAGE: Tag picker overlay clicked, closing picker.");
            }
        }
    }

    Rectangle {
        id: tagPickerPanel
        width: parent.width * 0.8 // Panel width
        height: parent.height * 0.7 // Panel height
        color: "#1c1d29" // Panel background color
        radius: 15
        anchors.horizontalCenter: parent.horizontalCenter
        // Position off-screen and animate in
        y: tagPickerOpen ? parent.height * 0.15 : parent.height // Animate from bottom
        z: 4 // Above overlay
        smooth: true
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        visible: tagPickerOpen // Control visibility

        Column {
            anchors.fill: parent
           // padding: Theme.paddingLarge
            spacing: Theme.paddingMedium

            Text {
                text: qsTr("Select Tags")
                font.pixelSize: Theme.fontSizeLarge
                color: "#e2e3e8"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            // Section for currently selected tags within the picker
            Column {
                width: parent.width
                visible: selectedTags.length > 0
                Text {
                    text: qsTr("Selected:")
                    font.pixelSize: Theme.fontSizeSmall
                    color: "#e2e3e8"
                }
                Flow {
                    width: parent.width
                    spacing: Theme.paddingSmall / 2
                    Repeater {
                        model: searchPage.selectedTags
                        delegate: BackgroundItem {
                            width: implicitWidth
                            height: Theme.itemSizeSmall
                           // radius: 10
                            //color: "#34374a" // Darker background for selected tags in picker
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Theme.fontSizeSmall
                                color: "#e2e3e8"
                                //padding.left: Theme.paddingSmall
                                //padding.right: Theme.paddingSmall
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: searchPage.toggleTagSelection(modelData) // Deselect
                            }
                        }
                    }
                }
            }


            // List of all available tags
            Flickable {
                width: parent.width
                height: parent.height - childrenRect.height - Theme.paddingLarge * 2 // Adjust height
                contentHeight: tagListColumn.height
                clip: true

                Column {
                    id: tagListColumn
                    width: parent.width
                    spacing: Theme.paddingSmall / 2

                    Repeater {
                        model: allTags
                        delegate: BackgroundItem {
                            width: parent.width
                            height: Theme.itemSizeSmall
                        //    radius: 10
                            // Change color based on selection status
                      //      color: searchPage.selectedTags.includes(modelData) ? "#5c607a" : "#2a2c3a"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.paddingSmall
                                text: modelData
                                font.pixelSize: Theme.fontSizeSmall
                                color: "#e2e3e8"
                            }

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.paddingSmall
                                source: searchPage.selectedTags.includes(modelData) ? "../icons/check.svg" : "" // Show checkmark if selected
                                width: Theme.fontSizeSmall
                                height: Theme.fontSizeSmall
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    searchPage.toggleTagSelection(modelData);
                                    console.log("SEARCH_PAGE: Toggling tag:", modelData);
                                }
                            }
                        }
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Done")
                onClicked: {
                    searchPage.tagPickerOpen = false;
                    console.log("SEARCH_PAGE: Tag picker closed by Done button.");
                }
            }
        }
    }
}

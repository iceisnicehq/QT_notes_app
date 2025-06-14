// MainPage.qml (Further Refined with Keyboard Fix and Tag Sorting)

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import "Database.js" as Data // Assuming this contains DB initialization
import "DatabaseManager.js" as DB // Assuming this contains actual DB operations like getAllNotes, searchNotes, etc.

Page {
    id: mainPage
    objectName: "mainPage"
    allowedOrientations: Orientation.All
    backgroundColor: "#121218"
    showNavigationIndicator: false
    property int noteMargin: 20

    property bool headerVisible: true
    property real previousContentY: 0
    property bool panelOpen: false
    property var allNotes: [] // Stores all notes from the DB
    property var allTags: [] // Stores all tags from the DB

    // New properties for search functionality
    property var selectedTags: [] // Tags currently selected for filtering
    property var currentSearchText: "" // Current text in the search field
    property var searchResults: [] // Notes matching the search criteria
    property bool tagPickerOpen: false // Controls visibility of the tag picker overlay

    // Model for the tag selection panel
    ListModel {
        id: availableTagsModel // Renamed to match example for clarity in this context
    }

    Component.onCompleted: {
        DB.initDatabase()
        DB.insertTestData() // Ensure test data is available for demonstration
        refreshData()
    }

    // Corrected: Using onStatusChanged for page activation detection
    onStatusChanged: {
        // When MainPage becomes active (topmost in PageStack), clear search field focus and hide keyboard.
        if (mainPage.status === PageStatus.Active) {
            refreshData()
            searchField.focus = false;
            sidePanel.currentPage = "notes"
            Qt.inputMethod.hide(); // Explicitly hide the keyboard
            console.log("MainPage active (status changed to Active), search field focus cleared and keyboard hidden.");
        }
    }

    // Refreshes all notes and tags from the database
    function refreshData() {
        allNotes = DB.getAllNotes(); // This now only gets non-deleted notes
        allTags = DB.getAllTags(); // This now only gets tags linked to non-deleted notes
        // After refreshing all data, perform a search with current criteria
        performSearch(currentSearchText, selectedTags);
    }

    // Main search function that calls the DatabaseManager and updates searchResults
    function performSearch(text, tags) {
        // Assume DB.searchNotes exists and handles text and tag filtering
        searchResults = DB.searchNotes(text, tags);
        console.log("MAIN_PAGE: Search performed. Keyword:", text, "Tags:", JSON.stringify(tags), "Results count:", searchResults.length);
    }

    // Function to handle adding/removing tags from selectedTags
    function toggleTagSelection(tagName) {
        if (selectedTags.indexOf(tagName) !== -1) {
            selectedTags = selectedTags.filter(function(tag) { return tag !== tagName; });
            console.log("MAIN_PAGE: Removed tag:", tagName, "Selected tags:", JSON.stringify(selectedTags));
        } else {
            selectedTags = selectedTags.concat(tagName);
            console.log("MAIN_PAGE: Added tag:", tagName, "Selected tags:", JSON.stringify(selectedTags));
        }
        // Trigger search whenever selected tags change
        performSearch(currentSearchText, selectedTags);
    }

    // Function to load tags into the ListModel for the tag selection panel
    function loadTagsForTagPanel() {
        availableTagsModel.clear();
        var selectedOnlyTags = [];
        var unselectedTags = [];

        // Separate tags into selected and unselected lists
        for (var i = 0; i < allTags.length; i++) {
            var tagName = allTags[i];
            if (selectedTags.indexOf(tagName) !== -1) {
                selectedOnlyTags.push({ name: tagName, isChecked: true });
            } else {
                unselectedTags.push({ name: tagName, isChecked: false });
            }
        }

        // Add selected tags first
        for (var i = 0; i < selectedOnlyTags.length; i++) {
            availableTagsModel.append(selectedOnlyTags[i]);
        }
        // Then add unselected tags
        for (var i = 0; i < unselectedTags.length; i++) {
            availableTagsModel.append(unselectedTags[i]);
        }

        console.log("TagSelectionPanel: Loaded tags for display in panel. Model items:", availableTagsModel.count);
    }

    // Wrapper for the search bar (selected tags area is now hidden)
    Column {
        id: searchAreaWrapper
        width: parent.width
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 2 // Ensure it's above the flickable

        // Adjust visibility and position based on headerVisible
        y: headerVisible ? 0 : -searchBarArea.height
        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuad
            }
        }

        // Search Bar Area
        Item {
            id: searchBarArea
            width: parent.width
            height: 80

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
                    text: currentSearchText // Bind text to currentSearchText property

                    // Real-time search on text change
                    onTextChanged: {
                        mainPage.currentSearchText = text;
                        performSearch(text, selectedTags);
                    }

                    EnterKey.onClicked: {
                        console.log("Searching for:", text)
                        // Just hide keyboard, search already happens onTextChanged
                        Qt.inputMethod.hide();
                        searchField.focus = false; // Clear focus after search
                    }

                    // Left Item: Menu / Clear Search
                    leftItem: Item {
                        width: Theme.fontSizeExtraLarge * 1.1
                        height: Theme.fontSizeExtraLarge * 0.95
                        clip: false

                        Icon {
                            id: leftIcon
                            source: (searchField.text.length > 0 || selectedTags.length > 0) ? "../icons/close.svg" : "../icons/menu.svg"
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                        }

                        RippleEffect {
                            id: leftRipple
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (searchField.text.length > 0 || selectedTags.length > 0) {
                                    // Clear search and tags
                                    mainPage.currentSearchText = "";
                                    searchField.text = ""; // Also update the SearchField's internal text
                                    mainPage.selectedTags = [];
                                    performSearch("", []);
                                    console.log("Search cleared (text and tags).");
                                } else {
                                    // Open side panel
                                    mainPage.panelOpen = true
                                    console.log("Menu button clicked → panelOpen = true")
                                }
                                Qt.inputMethod.hide();
                                searchField.focus = false; // Clear focus
                            }
                            onPressed: leftRipple.ripple(mouseX, mouseY)
                        }
                    }

                    // Right Item: Open Tag Picker (always)
                    rightItem: Item {
                        width: Theme.fontSizeExtraLarge * 1.25
                        height: Theme.fontSizeExtraLarge * 1.25
                        clip: false

                        Icon {
                            id: rightIcon
                            source: selectedTags.length > 0 ? "../icons/tag_filled.svg" : "../icons/tag-white.svg"
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                        }

                        RippleEffect {
                            id: rightRipple
                        }

                        MouseArea {
                            anchors.fill: parent
                            // Removed Qt.inputMethod.hide() and searchField.focus = false; here
                            // The keyboard should now remain visible when opening the tag picker.
                            onClicked: {
                                // Always open tag picker
                                mainPage.tagPickerOpen = true;
                                console.log("MAIN_PAGE: Tag picker opened from right icon.");
                            }
                            onPressed: rightRipple.ripple(mouseX, mouseY)
                        }
                    }
                }
            }
        }
        // Removed the Item with id: selectedTagsArea as per request.
        // It was previously responsible for displaying chosen tags on the main page.
    }


    SidePanel {
        id: sidePanel
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        open: panelOpen
        tags: allTags // Pass all tags to the side panel
    }

    SilicaFlickable {
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: searchAreaWrapper.bottom // Anchor below the combined search area
        contentHeight: column.height
        clip: true // Ensure content doesn't overflow outside

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
            // No padding properties here for Column

            // Display "No Results" if searchResults is empty
            Loader {
                sourceComponent: searchResults.length === 0 && (currentSearchText.length > 0 || selectedTags.length > 0) ? noResultsComponent : undefined
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


            // Pinned Notes Section
            Column {
                id: pinnedSection
                width: parent.width
                spacing: 0
                visible: searchResults.filter(function(note) { return note.pinned; }).length > 0

                SectionHeader {
                    text: qsTr("Pinned") + " (" + searchResults.filter(function(note) { return note.pinned; }).length + ")"
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
                    // Filter searchResults for pinned notes
                    model: searchResults.filter(function(note) { return note.pinned; })
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
                                    onNoteSavedOrDeleted: refreshData, // Pass refreshData as callback
                                    noteId: modelData.id,
                                    noteTitle: modelData.title,
                                    noteContent: modelData.content,
                                    noteIsPinned: modelData.pinned,
                                    noteTags: modelData.tags,
                                    noteCreationDate: new Date(modelData.created_at + "Z"),
                                    noteEditDate: new Date(modelData.updated_at + "Z"),
                                    noteColor: modelData.color
                                });
                                console.log("Opening NotePage in EDIT mode for ID:", modelData.id + ", Color:", modelData.color);
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
                visible: searchResults.filter(function(note) { return !note.pinned; }).length > 0


                SectionHeader {
                    text: qsTr("Others") + " (" + searchResults.filter(function(note) { return !note.pinned; }).length + ")"
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
                    // Filter searchResults for non-pinned notes
                    model: searchResults.filter(function(note) { return !note.pinned; })
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
                                    onNoteSavedOrDeleted: refreshData, // Pass refreshData as callback
                                    noteId: modelData.id,
                                    noteTitle: modelData.title,
                                    noteContent: modelData.content,
                                    noteIsPinned: modelData.pinned,
                                    noteTags: modelData.tags,
                                    noteCreationDate: new Date(modelData.created_at + "Z"),
                                    noteEditDate: new Date(modelData.updated_at + "Z"),
                                    noteColor: modelData.color
                                });
                                console.log("Opening NotePage in EDIT mode for ID:", modelData.id + ", Color:", modelData.color);
                            }
                        }
                    }
                }
            }
        }
    }

    ScrollBar {
        flickableSource: flickable
        topAnchorItem: searchAreaWrapper // Anchor to the new search area wrapper
    }

    // --- Floating Plus Button for Add New Note ---
     Rectangle {
         id: fabButton
         width: Theme.itemSizeLarge // Made smaller
         height: Theme.itemSizeLarge // Made smaller
         radius: width / 2 // Make it round
         color: Theme.highlightColor // A prominent color for the FAB
         anchors.right: parent.right
         anchors.bottom: parent.bottom
         anchors.rightMargin: Theme.paddingLarge * 2
         anchors.bottomMargin: Theme.paddingLarge * 2
         z: 5 // Ensure it floats above other content
         antialiasing: true
         visible: !mainPage.tagPickerOpen && (opacity > 0.05) // Hide when tag picker is open, and if too transparent

         property real baseOpacity: 0.8 // Base transparency
         property real minOpacity: 0.1 // Minimum opacity when fully faded
         property real fadeDistance: Theme.itemSizeExtraLarge * 1.5 // Distance over which fade happens

         opacity: {
             if (flickable.contentHeight <= flickable.height || flickable.contentHeight - flickable.height <= 0) {
                 // Content not scrollable, or too small, keep base opacity
                 return baseOpacity;
             }

             var maxScrollY = flickable.contentHeight - flickable.height;
             var fadeStartScrollY = maxScrollY - fadeDistance;

             if (flickable.contentY < fadeStartScrollY) {
                 return baseOpacity; // Full base opacity when not in fade region
             } else {
                 // Calculate progress within the fade region (0 to 1)
                 var progress = (flickable.contentY - fadeStartScrollY) / fadeDistance;
                 progress = Math.max(0, Math.min(1, progress)); // Clamp between 0 and 1

                 // Linearly interpolate opacity from baseOpacity to minOpacity
                 return baseOpacity - (progress * (baseOpacity - minOpacity));
             }
         }

         Behavior on opacity {
             NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
         }

         Icon {
             source: "../icons/plus.svg"
             color: Theme.primaryColor // Color of the plus icon
             anchors.centerIn: parent
             width: parent.width * 0.5
             height: parent.height * 0.5
         }

         RippleEffect {} // Add ripple effect for visual feedback

         MouseArea {
             anchors.fill: parent
             onClicked: {
                 // Create New Note
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
                 console.log("Opening NewNotePage in CREATE mode (from FAB).");
                 Qt.inputMethod.hide(); // Still hide keyboard on navigating away from current page
                 searchField.focus = false; // Clear focus before navigating
             }
         }
     }


    // --- Tag Picker Overlay ---
    Rectangle {
        id: tagPickerOverlay
        anchors.fill: parent
        color: "#000000" // Black background
        opacity: tagPickerPanel.opacity * 0.4 // Opacity linked to panel's opacity
        z: 3 // Above main content, below panel
        visible: tagPickerPanel.visible // Use panel's explicit visibility
        smooth: true
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            enabled: tagPickerOverlay.visible // Only enabled when visible
            onClicked: {
                // Clicking overlay closes the panel
                mainPage.tagPickerOpen = false; // Set state to false
                console.log("MAIN_PAGE: Tag picker overlay clicked, closing picker.");
            }
        }
    }

    // --- Tag Picker Panel ---
    Rectangle {
        id: tagPickerPanel
        width: parent.width // Panel width - as per new example
        height: parent.height * 0.53 // Fixed height as per example
        color: "#1c1d29" // Panel background color (matching original)
        radius: 15 // Radius from previous version, or adjust if example implies different
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom // Anchored to page bottom as per example
        z: 4 // Above overlay
        opacity: mainPage.tagPickerOpen ? 1 : 0 // Controlled by tagPickerOpen, animated by behavior
        visible: mainPage.tagPickerOpen || opacity > 0.01 // Directly control visibility to ensure onVisibleChanged fires

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic } // Easing from example
        }

        onVisibleChanged: {
            if (visible) {
                loadTagsForTagPanel(); // Load tags when the panel becomes visible
                tagsPanelFlickable.contentY = 0; // Scroll to top when opening
                console.log("Tag picker panel opened. Loading tags and scrolling to top.");
            }
        }

        Column {
            id: tagPanelContentColumn
            anchors.fill: parent
            spacing: Theme.paddingMedium // Spacing between elements in this column

            Rectangle { // Header container for "Select Tags"
                id: tagPanelHeader
                width: parent.width
                height: Theme.itemSizeExtraSmall
                // radius should come from parent tagPickerPanel if it covers the entire width
                color: "#1c1d29" // Match panel color
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                // Use anchors.margins for horizontal padding within the header itself
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge


                Label { // Changed from Text to Label for style consistency if it's a header
                    id: selectTagsText // Renamed ID to match example
                    text: "Select Tags"
                    font.pixelSize: Theme.fontSizeLarge
                    color: "#e8eaed" // Color from example
                    anchors.centerIn: parent
                }
            }

            // --- No "Selected Tags" section here as per request ---

            // List of all available tags
            SilicaFlickable { // Using SilicaFlickable as it was used elsewhere
                id: tagsPanelFlickable // Renamed ID to match example
                width: parent.width
                anchors.top: tagPanelHeader.bottom // Anchored below the header
                anchors.bottom: doneButton.top // Anchored above the Done button
                // Horizontal anchors for flickable content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Theme.paddingMedium // Space from header
                anchors.bottomMargin: Theme.paddingMedium // Space from done button
                contentHeight: tagsPanelListView.contentHeight
                clip: true
                ScrollBar { flickableSource: parent }

                ListView {
                    id: tagsPanelListView // Renamed ID to match example
                    width: parent.width
                    height: contentHeight
                    model: availableTagsModel // Now using the ListModel
                    orientation: ListView.Vertical
                    spacing: Theme.paddingSmall

                    delegate: Rectangle { // Used Rectangle as per your previous request
                        id: tagPanelDelegateRoot // Renamed ID to match example
                        width: parent.width
                        height: Theme.itemSizeMedium
                        clip: true
                        color: model.isChecked ? "#5c607a" : "#2a2c3a" // Dynamic background color

                        RippleEffect { id: tagPanelDelegateRipple }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: tagPanelDelegateRipple.ripple(mouseX, mouseY)
                            onClicked: {
                                var newCheckedState = !model.isChecked;
                                // Update the ListModel
                                availableTagsModel.set(index, { name: model.name, isChecked: newCheckedState });

                                // Update mainPage's selectedTags property for search logic
                                if (newCheckedState) {
                                    if (mainPage.selectedTags.indexOf(model.name) === -1) {
                                        mainPage.selectedTags = mainPage.selectedTags.concat(model.name);
                                    }
                                } else {
                                    mainPage.selectedTags = mainPage.selectedTags.filter(function(tag) { return tag !== model.name; });
                                }
                                console.log("MAIN_PAGE: Toggling tag from picker: " + model.name + ", isChecked: " + newCheckedState + ", Current selectedTags:", JSON.stringify(mainPage.selectedTags));
                                // Trigger immediate search update in MainPage
                                mainPage.performSearch(mainPage.currentSearchText, mainPage.selectedTags);
                            }
                        }

                        Row {
                            id: tagPanelRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge // Padding from left edge of delegate
                            anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge // Padding from right edge of delegate
                            spacing: Theme.paddingMedium

                            Icon {
                                id: tagPanelTagIcon // Renamed ID to match example
                                source: "../icons/tag-white.svg"
                                color: "#e2e3e8" // Color from example
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                            }

                            Text { // Changed from Label to Text as per previous fixes.
                                id: tagPanelTagNameLabel // Renamed ID to match example
                                text: model.name
                                color: "#e2e3e8" // Color from example (for selected, or consider a softer color for unselected)
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight // Enable eliding for long text
                                // Anchored to be between tag icon and check button for flexible width
                                anchors.left: tagPanelTagIcon.right
                                anchors.leftMargin: tagPanelRow.spacing
                                anchors.right: tagPanelCheckButtonContainer.left // Anchor left to the right-aligned check button container
                                anchors.rightMargin: tagPanelRow.spacing
                            }

                            Item {
                                id: tagPanelCheckButtonContainer // Renamed ID to match example
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right // Anchored to the far right of the row
                                clip: false

                                Image {
                                    id: tagPanelCheckIcon // Renamed ID to match example
                                    source: model.isChecked ? "../icons/box-checked.svg" : "../icons/box.svg"
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                        }
                    }
                }
            }
            ScrollBar {
                flickableSource: tagsPanelFlickable
                anchors.top: tagsPanelFlickable.top
                anchors.bottom: tagsPanelFlickable.bottom
                anchors.right: parent.right
                width: Theme.paddingSmall
            }

            Button {
                id: doneButton // Retained ID
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Done")
                onClicked: {
                    mainPage.tagPickerOpen = false; // Set state to false
                    console.log("MAIN_PAGE: Tag picker closed by Done button.");
                }
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge // Space from the panel bottom
            }
        }
    }
}

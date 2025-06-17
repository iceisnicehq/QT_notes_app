// MainPage.qml (Re-integrated Features from Clean Base)

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "Database.js" as Data // Assuming this contains DB initialization
import "DatabaseManager.js" as DB // Assuming this contains actual DB operations like getAllNotes, searchNotes, etc.

Page {
    id: mainPage
    objectName: "mainPage"
    allowedOrientations: Orientation.All
    backgroundColor: mainPage.customBackgroundColor !== undefined ? mainPage.customBackgroundColor : "#121218" // Fallback to Theme.backgroundColor if custom is not set

    // Property to hold the currently selected custom background color
    property string customBackgroundColor: DB.getThemeColor() || "#121218" // Load from DB, default to a dark color if not found
    showNavigationIndicator: false
    property int noteMargin: 20

    property bool headerVisible: true
    property real previousContentY: 0
    property bool panelOpen: false
    property var allNotes: [] // Stores all notes from the DB
    property var allTags: [] // Stores all tags from the DB

    // New properties for search functionality
    property var selectedTags: [] // Tags currently selected for filtering
    property var currentSearchText: "" // Current text in the main note search field
    property var searchResults: [] // Notes matching the search criteria
    property bool tagPickerOpen: false // Controls visibility of the tag picker overlay

    // --- New properties for selection mode ---
    property bool selectionMode: false
    // List to store IDs of selected notes
    property var selectedNoteIds: []
    // New properties for generic confirmation dialog
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: ""
    property string confirmDialogMessage: ""
    property string confirmButtonText: ""
    property color confirmButtonHighlightColor: Theme.primaryColor // Default, will be overridden
    property var onConfirmCallback: null // Function to call when user confirms
    // --- ToastManager definition (Crucial for showing messages) ---
    ToastManager {
        id: toastManager
    }

    // Model for the tag selection panel
    ListModel {
        id: availableTagsModel
    }

    // Model for tags displayed in the DrawerMenu (used in the Drawer)
    ListModel {
        id: tagsModel
    }

    Component.onCompleted: {
        console.log(qsTr("MainPage created."));
        DB.initDatabase()
        DB.insertTestData() // Ensure test data is available for demonstration
        DB.permanentlyDeleteExpiredDeletedNotes();
        refreshData()
    }

    onStatusChanged: {
        if (mainPage.status === PageStatus.Active) {
            refreshData()
            searchField.focus = false;
            sidePanel.currentPage = "notes"
            Qt.inputMethod.hide(); // Explicitly hide the keyboard
            resetSelection(); // Reset selection mode when page becomes active
            console.log("MainPage active (status changed to Active), search field focus cleared and keyboard hidden.");
        }
    }

    // Refreshes all notes and tags from the database
    function refreshData() {
        allNotes = DB.getAllNotes(); // This now only gets non-deleted notes
        allTags = DB.getAllTags(); // This now only gets tags linked to non-deleted notes
        // After refreshing all data, perform a search with current criteria
        performSearch(currentSearchText, selectedTags);
        loadTagsForDrawer(); // Ensure tags in drawer are updated
    }

    // Main search function that calls the DatabaseManager and updates searchResults
    function performSearch(text, tags) {
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
        performSearch(currentSearchText, selectedTags);
    }

    // Function to load tags into the ListModel for the tag selection panel
    // This function now accepts an optional 'filterText' parameter
    function loadTagsForTagPanel(filterText) {
        availableTagsModel.clear();
        var currentSearchLower = (filterText || "").toLowerCase(); // Use the provided filterText

        var selectedOnlyTags = [];
        var unselectedTags = [];

        for (var i = 0; i < allTags.length; i++) {
            var tagName = allTags[i];
            // Filter logic: if filterText is provided, include only matching tags.
            if (currentSearchLower === "" || tagName.toLowerCase().indexOf(currentSearchLower) !== -1) {
                if (selectedTags.indexOf(tagName) !== -1) {
                    selectedOnlyTags.push({ name: tagName, isChecked: true });
                } else {
                    unselectedTags.push({ name: tagName, isChecked: false });
                }
            }
        }

        for (var i = 0; i < selectedOnlyTags.length; i++) {
            availableTagsModel.append(selectedOnlyTags[i]);
        }
        for (var i = 0; i < unselectedTags.length; i++) {
            availableTagsModel.append(unselectedTags[i]);
        }

        console.log("MAIN_PAGE: loadTagsForTagPanel executed. Filter:", filterText, "Model items:", availableTagsModel.count);
    }

    // Function to load tags for the drawer menu
    function loadTagsForDrawer() {
        tagsModel.clear();
        var tagsWithCounts = DB.getAllTagsWithCounts();
        for (var i = 0; i < tagsWithCounts.length; i++) {
            tagsModel.append(tagsWithCounts[i]);
        }
        console.log(qsTr("Loaded %1 tags for drawer.").arg(tagsWithCounts.length));
    }

    // --- Selection Mode Functions ---
    function isNoteSelected(noteId) {
        return mainPage.selectedNoteIds.indexOf(noteId) !== -1;
    }

    function toggleNoteSelection(noteId) {
        // Create a new array reference to ensure property change detection in QML
        var newSelectedIds = mainPage.selectedNoteIds.slice(); // Use slice to create a shallow copy

        var index = newSelectedIds.indexOf(noteId);
        if (index === -1) {
            newSelectedIds.push(noteId);
            console.log(qsTr("Selected note ID: %1").arg(noteId));
        } else {
            newSelectedIds.splice(index, 1);
            console.log(qsTr("Deselected note ID: %1").arg(noteId));
        }

        mainPage.selectedNoteIds = newSelectedIds; // Assign the new array reference
        mainPage.selectionMode = mainPage.selectedNoteIds.length > 0;
        Qt.inputMethod.hide();
        if (pinnedNotes) pinnedNotes.forceLayout();
        if (otherNotes) otherNotes.forceLayout();
    }

    function resetSelection() {
        mainPage.selectedNoteIds = [];
        mainPage.selectionMode = false;
        console.log(qsTr("Selection reset."));
        if (pinnedNotes) pinnedNotes.forceLayout();
        if (otherNotes) otherNotes.forceLayout();
    }


    // Wrapper for the search bar and selection toolbar
    Column {
        id: searchAreaWrapper
        width: parent.width
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 2

        y: headerVisible ? 0 : -searchBarArea.height
        Behavior on y {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
        }

        // Search Bar Area and Selection Toolbar Container
        Item {
            id: searchBarArea
            width: parent.width
            height: 80

            // Search Field Container (Visible in default mode)
            Rectangle {
                id: searchBarContainer
                width: parent.width - (noteMargin * 2)
                height: parent.height
                anchors.centerIn: parent
                color: mainPage.backgroundColor // Changed to match page background
                radius: 80
                visible: !mainPage.selectionMode
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                SearchField {
                    id: searchField
                    anchors.fill: parent
                    placeholderText: "Search notes..."
                    highlighted: false
                    text: currentSearchText // This binds to mainPage.currentSearchText

                    onTextChanged: {
                        mainPage.currentSearchText = text; // Update mainPage's property
                        performSearch(text, selectedTags);
                    }

                    EnterKey.onClicked: {
                        console.log("Searching for:", text)
                        Qt.inputMethod.hide();
                        searchField.focus = false;
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

                        RippleEffect { id: menuRipple }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (searchField.text.length > 0 || selectedTags.length > 0) {
                                    mainPage.currentSearchText = "";
                                    searchField.text = ""; // Clears the main search field
                                    mainPage.selectedTags = [];
                                    performSearch("", []);
                                    console.log("Search cleared (text and tags).");
                                } else {
                                    mainPage.panelOpen = true
                                    console.log("Menu button clicked → panelOpen = true")
                                }
                                onPressed: menuRipple.ripple(mouseX, mouseY)
                                Qt.inputMethod.hide();
                                searchField.focus = false;
                            }
                        }
                    }

                    // Right Item: Open Tag Picker
                    rightItem: Item {
                        width: Theme.fontSizeExtraLarge * 1.25
                        height: Theme.fontSizeExtraLarge * 1.25
                        clip: false

                        Icon {
                            id: rightIcon
                            source: selectedTags.length > 0 ? "../icons/tag-filled.svg" : "../icons/tag-white.svg"
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                        }

                        RippleEffect { id: rightRipple }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mainPage.tagPickerOpen = true;
                                console.log("MAIN_PAGE: Tag picker opened from right icon.");
                            }
                            onPressed: rightRipple.ripple(mouseX, mouseY)
                        }
                    }
                }
            }

            // Selection Mode Toolbar (Replaces SearchField visually when active)
            Rectangle {
                id: selectionToolbarBackground
                width: parent.width - (noteMargin * 2)
                height: parent.height
                anchors.centerIn: parent
                color: mainPage.backgroundColor // Changed to match page background
                radius: 80
                visible: mainPage.selectionMode
                opacity: visible ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                // Left: Close button
                Item {
                    id: closeButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge

                    Icon { source: "../icons/close.svg"; anchors.centerIn: parent; width: parent.width; height: parent.height }
                    RippleEffect { id: closeRipple }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mainPage.resetSelection()
                        onPressed: closeRipple.ripple(mouseX, mouseY)
                    }
                }

                // Right: Delete button (rightmost)
                Item {
                    id: deleteButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge

                    Icon { source: "../icons/delete.svg"; color: Theme.errorColor; anchors.centerIn: parent; width: parent.width; height: parent.height }
                    RippleEffect { id: deleteRipple }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mainPage.selectedNoteIds.length > 0) {
                                // Configure and show the generic confirmation dialog for deletion
                                mainPage.confirmDialogTitle = qsTr("Confirm Deletion");
                                mainPage.confirmDialogMessage = qsTr("Are you sure you want to move %1 selected note(s) to trash?").arg(mainPage.selectedNoteIds.length);
                                mainPage.confirmButtonText = qsTr("Delete");
                                mainPage.confirmButtonHighlightColor = Theme.errorColor;
                                mainPage.onConfirmCallback = function() {
                                    var idsToMove = mainPage.selectedNoteIds;
                                    DB.bulkMoveToTrash(idsToMove);
                                    toastManager.show(qsTr("%1 note(s) moved to trash!").arg(idsToMove.length));
                                    mainPage.resetSelection();
                                    mainPage.refreshData();
                                };
                                mainPage.confirmDialogVisible = true;
                                console.log("Showing delete confirmation dialog.");
                            } else {
                                toastManager.show(qsTr("No notes selected."));
                            }
                        }
                        onPressed: deleteRipple.ripple(mouseX, mouseY)
                    }
                }
                // Right: Archive button (left of delete button)
                Item {
                    id: archiveButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: deleteButton.left
                    anchors.rightMargin: Theme.paddingMedium

                    Icon { source: "../icons/archive.svg"; color: Theme.primaryColor; anchors.centerIn: parent; width: parent.width; height: parent.height }
                    RippleEffect { id: archiveRipple }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mainPage.selectedNoteIds.length > 0) {
                                // Configure and show the generic confirmation dialog for archiving
                                mainPage.confirmDialogTitle = qsTr("Confirm Archiving");
                                mainPage.confirmDialogMessage = qsTr("Are you sure you want to archive %1 selected note(s)?").arg(mainPage.selectedNoteIds.length);
                                mainPage.confirmButtonText = qsTr("Archive");
                                mainPage.confirmButtonHighlightColor = Theme.primaryColor; // Or a custom archive color if you have one
                                mainPage.onConfirmCallback = function() {
                                    var idsToArchive = mainPage.selectedNoteIds;
                                    DB.bulkArchiveNotes(idsToArchive);
                                    toastManager.show(qsTr("%1 note(s) archived!").arg(idsToArchive.length));
                                    mainPage.resetSelection();
                                    mainPage.refreshData();
                                };
                                mainPage.confirmDialogVisible = true;
                                console.log("Showing archive confirmation dialog.");
                            } else {
                                toastManager.show(qsTr("No notes selected."));
                            }
                        }
                        onPressed: archiveRipple.ripple(mouseX, mouseY)
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
        onClosed: mainPage.panelOpen = false // Listen for the 'closed' signal and update page's property
    }

    SilicaFlickable {
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        // Dynamic bottom anchor: if in selection mode or tag picker is open, extend to parent bottom.
        // Otherwise, anchor above the fabButton.
        anchors.bottom: parent.bottom
        anchors.top: searchAreaWrapper.bottom
        contentHeight: column.height
        clip: true

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

            Loader {
                sourceComponent: searchResults.length === 0 && (currentSearchText.length > 0 || selectedTags.length > 0) ? noResultsComponent : undefined
                width: parent.width
                height: childrenRect.height
            }

            Component {
                id: noResultsComponent
                Column {
                    width: parent.width
                    height: 200
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
                    model: searchResults.filter(function(note) { return note.pinned; })
                    delegate: NoteCard {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: mainPage.noteMargin
                            rightMargin: mainPage.noteMargin
                        }
                        width: parent.width
                        title: modelData.title
                        content: modelData.content
                        tags: modelData.tags.join(' ') // Passing tags as space-separated string
                        cardColor: modelData.color || "#1c1d29"
                        noteId: modelData.id
                        isSelected: mainPage.isNoteSelected(modelData.id)
                        mainPageInstance: mainPage
                        noteIsPinned: modelData.pinned
                        noteCreationDate: new Date(modelData.created_at + "Z")
                        noteEditDate: new Date(modelData.updated_at + "Z")
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
                    model: searchResults.filter(function(note) { return !note.pinned; })
                    delegate: NoteCard {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: mainPage.noteMargin
                            rightMargin: mainPage.noteMargin
                        }
                        width: parent.width
                        title: modelData.title
                        content: modelData.content
                        tags: modelData.tags.join(' ') // Passing tags as space-separated string
                        cardColor: modelData.color || "#1c1d29"
                        noteId: modelData.id
                        isSelected: mainPage.isNoteSelected(modelData.id)
                        mainPageInstance: mainPage
                        noteIsPinned: modelData.pinned
                        noteCreationDate: new Date(modelData.created_at + "Z")
                        noteEditDate: new Date(modelData.updated_at + "Z")
                    }
                }
            }
        }
    }

    ScrollBar {
        flickableSource: flickable
        topAnchorItem: searchAreaWrapper
    }

    // --- Floating Plus Button for Add New Note ---
    Rectangle {
        id: fabButton
        width: Theme.itemSizeLarge
        height: Theme.itemSizeLarge
        radius: width / 2
        color:  DB.getLighterColor(mainPage.customBackgroundColor)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.paddingLarge * 2
        anchors.bottomMargin: Theme.paddingLarge * 2
        z: 5
        antialiasing: true
        // Set visible based on selection mode and tag picker.
        visible: !mainPage.selectionMode && !mainPage.tagPickerOpen

        property real baseOpacity: 0.8
        property real minOpacity: 0.1
        property real fadeDistance: Theme.itemSizeExtraLarge * 1.5

        opacity: {
            if (flickable.contentHeight <= flickable.height || flickable.contentHeight - flickable.height <= 0) {
                return baseOpacity;
            }

            var maxScrollY = flickable.contentHeight - flickable.height;
            var fadeStartScrollY = maxScrollY - fadeDistance;

            if (flickable.contentY < fadeStartScrollY) {
                return baseOpacity;
            } else {
                var progress = (flickable.contentY - fadeStartScrollY) / fadeDistance;
                progress = Math.max(0, Math.min(1, progress));
                return baseOpacity - (progress * (baseOpacity - minOpacity));
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        Icon {
            source: "../icons/plus.svg"
            color: Theme.primaryColor
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: parent.height * 0.5
        }

        RippleEffect { id: plusButtonRipple }

        MouseArea {
            anchors.fill: parent
            enabled: fabButton.visible // Enable/disable based on fabButton's visible property
            onPressed: plusButtonRipple.ripple(mouseX, mouseY)
            onClicked: {
                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                    onNoteSavedOrDeleted: refreshData,
                    noteId: -1,
                    noteTitle: "",
                    noteContent: "",
                    noteIsPinned: false,
                    noteTags: "", // Pass empty string for new note tags
                    noteCreationDate: new Date(),
                    noteEditDate: new Date(),
                    noteColor: DB.getThemeColor() || "#121218" // Load from DB, default to a dark color if not found    showNavigationIndicator: false

                });
                console.log("Opening NewNotePage in CREATE mode (from FAB).");
                Qt.inputMethod.hide();
                searchField.focus = false;
            }
        }
    }


    // --- Tag Picker Overlay ---
    Rectangle {
        id: tagPickerOverlay
        anchors.fill: parent
        color: "#000000"
        opacity: tagPickerPanel.opacity * 0.4
        z: 3
        visible: tagPickerPanel.visible
        smooth: true
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            enabled: tagPickerOverlay.visible
            onClicked: {
                mainPage.tagPickerOpen = false;
                console.log("MAIN_PAGE: Tag picker overlay clicked, closing picker.");
            }
        }
    }

    // --- Tag Picker Panel ---
        Rectangle {
            id: tagPickerPanel
            // New property for the tag picker's internal search text
            property string tagPickerSearchText: "" // Initialize as empty

            width: parent.width
            height: parent.height * 0.53
            color: mainPage.customBackgroundColor // Tag picker panel background color
            radius: 15
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            z: 4
            opacity: mainPage.tagPickerOpen ? 1 : 0
            visible: mainPage.tagPickerOpen || opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            onVisibleChanged: {
                if (visible) {
                    // When the panel opens, use its own search text property to filter tags.
                    // Initialize it from mainPage.currentSearchText, if that's desired,
                    // but it should probably start fresh for tag filtering.
                    // For now, let's keep it isolated.
                    tagPickerPanel.tagPickerSearchText = ""; // Clear on open for a fresh search in picker
                    mainPage.loadTagsForTagPanel(tagPickerPanel.tagPickerSearchText);
                    tagsPanelFlickable.contentY = 0; // Scroll to the top of the flickable area.
                    console.log("Tag picker panel opened. Loading tags and scrolling to top.");
                } else {
                    // When the panel closes, clear its internal search text.
                    tagPickerPanel.tagPickerSearchText = "";
                }
            }

            // Note: availableTagsModel is defined in mainPage's scope, as per our last conversation.
            // So, no ListModel definition needed here.

            Column {
                id: tagPanelContentColumn
                anchors.fill: parent
                spacing: Theme.paddingMedium

                // Header section for the tag picker panel, now including the search field.
                Rectangle {
                    id: tagPanelHeader
                    width: parent.width
                    // Adjusted height to accommodate both the "Select Tags" label and the search field.
                    height: Theme.itemSizeMedium // Increased height for both label and search field
                    color: DB.darkenColor(mainPage.customBackgroundColor, 0.15) // Header background color
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.rightMargin: Theme.paddingLarge

                    // Column to stack the label and the search field vertically within the header.
                    Column {
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent
                        spacing: Theme.paddingSmall // Spacing between the label and the search field.

                        // SearchField for filtering the list of available tags.
                        SearchField {
                            id: tagSearchInput
                            width: parent.width * 0.95 // Take up 90% of the parent's width.
                            anchors.horizontalCenter: parent.horizontalCenter // Center horizontally within the column.
                            placeholderText: qsTr("Search tags...") // Placeholder text for the input field.
                            font.pixelSize: Theme.fontSizeMedium
                            highlighted: false
                            color: "#e2e3e8" // Text color for the input.
                            readOnly: false // The search field should always be editable.

                            // *** IMPORTANT CHANGE HERE ***
                            // Bind the text property of the SearchField to tagPickerPanel.tagPickerSearchText.
                            text: tagPickerPanel.tagPickerSearchText

                            // When the text in the search field changes, update tagPickerPanel.tagPickerSearchText
                            // and then call mainPage's function to reload/filter the tags in the list view.
                            onTextChanged: {
                                tagPickerPanel.tagPickerSearchText = text; // Update the internal property
                                mainPage.loadTagsForTagPanel(tagPickerPanel.tagPickerSearchText); // Use the internal property for filtering
                            }

                            // Left Item: Search Icon (Static as requested)
                            leftItem: Item { }

                            // Right Item: Close/Clear Search Icon
                            rightItem: Item {
                                width: Theme.fontSizeExtraLarge * 1.25
                                height: Theme.fontSizeExtraLarge * 1.25
                                clip: false

                                // Opacity depends on whether the tag picker's search field has text.
                                opacity: tagSearchInput.text.length > 0 ? 1 : 0.3
                                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Icon {
                                    id: rightIconCloseTagSearch
                                    source: "../icons/close.svg" // Static close icon.
                                    color: Theme.primaryColor
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                }

                                RippleEffect { id: rightClearRippleTagSearch }

                                MouseArea {
                                    anchors.fill: parent
                                    // Enabled only if there is text in the search field to clear.
                                    enabled: tagSearchInput.text.length > 0
                                    onPressed: rightClearRippleTagSearch.ripple(mouseX, mouseY)
                                    onClicked: {
                                        // Clear the tag picker's search field and its internal property.
                                        tagPickerPanel.tagPickerSearchText = "";
                                        tagSearchInput.text = ""; // Update UI
                                        // Reload tags to show all tags after clearing search.
                                        mainPage.loadTagsForTagPanel(""); // Use empty filter for all tags
                                        console.log("Tag picker search field cleared by right icon.");
                                    }
                                }
                            }
                        }
                    }
                }

                // Flickable area for the list of tags, allowing scrolling.
                SilicaFlickable {
                    id: tagsPanelFlickable
                    width: parent.width
                    anchors.top: tagPanelHeader.bottom // Anchored below the header.
                    anchors.bottom: doneButton.top // Anchored above the Done button.
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: Theme.paddingMedium
                    anchors.bottomMargin: Theme.paddingMedium
                    contentHeight: tagsPanelListView.contentHeight // Content height is driven by the ListView.
                    clip: true // Clip content that extends beyond the flickable's bounds.
                    ScrollBar { flickableSource: tagsPanelFlickable; z: 5 } // Scrollbar for the flickable.

                    // ListView to display the individual tag items.
                    ListView {
                        id: tagsPanelListView
                        width: parent.width
                        height: contentHeight // Height adapts to the content of the model.
                        model: availableTagsModel // Uses the ListModel defined above.
                        orientation: ListView.Vertical // Tags are arranged vertically.
                        spacing: Theme.paddingSmall // Spacing between each tag item.

                        // Delegate defines how each item in the ListView looks and behaves.
                        delegate: Rectangle {
                            id: tagPanelDelegateRoot
                            width: parent.width
                            height: Theme.itemSizeMedium // Fixed height for each tag item.
                            clip: true
                            // Background color changes based on whether the tag is checked/selected.
                            color: model.isChecked ? DB.darkenColor(mainPage.customBackgroundColor, -0.25) : DB.darkenColor(mainPage.customBackgroundColor, 0.25)

                            RippleEffect { id: tagPanelDelegateRipple } // Visual feedback on touch/click.

                            MouseArea {
                                anchors.fill: parent
                                onPressed: tagPanelDelegateRipple.ripple(mouseX, mouseY) // Trigger ripple effect.
                                onClicked: {
                                    var newCheckedState = !model.isChecked; // Toggle the checked state.
                                    // Update the model immediately to reflect the change in UI.
                                    availableTagsModel.set(index, { name: model.name, isChecked: newCheckedState });

                                    // Use mainPage.toggleTagSelection to update the global selectedTags and trigger a note search.
                                    mainPage.toggleTagSelection(model.name);
                                    console.log("MAIN_PAGE: Toggling tag from picker: " + model.name + ", isChecked: " + newCheckedState + ", Current selectedTags:", JSON.stringify(mainPage.selectedTags));
                                    // mainPage.performSearch is called by mainPage.toggleTagSelection, so no need to call it here.
                                }
                            }

                            // Row layout for icon, tag name, and checkbox icon.
                            Row {
                                id: tagPanelRow
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge // Left padding.
                                anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge // Right padding.
                                spacing: Theme.paddingMedium // Spacing between elements in the row.

                                // Icon for the tag.
                                Icon {
                                    id: tagPanelTagIcon
                                    source: "../icons/tag-white.svg" // Path to the tag icon SVG.
                                    color: "#e2e3e8" // Color of the tag icon.
                                    width: Theme.iconSizeMedium
                                    height: Theme.iconSizeMedium
                                    anchors.verticalCenter: parent.verticalCenter
                                    fillMode: Image.PreserveAspectFit
                                }

                                // Label to display the tag name.
                                Text {
                                    id: tagPanelTagNameLabel
                                    text: model.name // Display the tag name from the model.
                                    color: "#e2e3e8" // Text color.
                                    font.pixelSize: Theme.fontSizeMedium
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight // Elide long tag names with "..."
                                    // Positioned flexibly between the icon and the checkbox.
                                    anchors.left: tagPanelTagIcon.right
                                    anchors.leftMargin: tagPanelRow.spacing
                                    anchors.right: tagPanelCheckButtonContainer.left
                                    anchors.rightMargin: tagPanelRow.spacing
                                }

                                // Container for the checkbox icon.
                                Item {
                                    id: tagPanelCheckButtonContainer
                                    width: Theme.iconSizeMedium
                                    height: Theme.iconSizeMedium
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right // Anchored to the far right.
                                    clip: false

                                    // Image component for the checkbox icon (checked or unchecked).
                                    Image {
                                        id: tagPanelCheckIcon
                                        source: model.isChecked ? "../icons/box-checked.svg" : "../icons/box.svg" // Dynamic source based on checked state.
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
                // Scrollbar for the tag list.
                ScrollBar {
                    flickableSource: tagsPanelFlickable
                    anchors.top: tagsPanelFlickable.top
                    anchors.bottom: tagsPanelFlickable.bottom
                    anchors.right: parent.right
                    width: Theme.paddingSmall
                }

                // Done button to close the tag picker panel.
                Button {
                    id: doneButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Done") // Localized text for the button.
                    onClicked: {
                        mainPage.tagPickerOpen = false; // Close the tag picker panel.
                        console.log("MAIN_PAGE: Tag picker closed by Done button.");
                    }
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingLarge // Space from the bottom of the panel.
                }
            }
        }
    // --- Integrated Generic Confirmation Dialog ---
    ConfirmDialog {
        id: confirmDialogInstance
        // Bind properties from mainPage to ConfirmDialog
        dialogVisible: mainPage.confirmDialogVisible
        dialogTitle: mainPage.confirmDialogTitle
        dialogMessage: mainPage.confirmDialogMessage
        confirmButtonText: mainPage.confirmButtonText
        confirmButtonHighlightColor: mainPage.confirmButtonHighlightColor

        // Connect signals from ConfirmDialog back to mainPage's logic
        onConfirmed: {
            if (mainPage.onConfirmCallback) {
                mainPage.onConfirmCallback(); // Execute the stored callback
            }
            mainPage.confirmDialogVisible = false; // Hide the dialog after confirmation
        }
        onCancelled: {
            mainPage.confirmDialogVisible = false; // Hide the dialog
            console.log(qsTr("Action cancelled by user."));
        }
    }
}

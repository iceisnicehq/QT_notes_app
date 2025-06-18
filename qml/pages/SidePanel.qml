// SidePanel.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Item {
    id: sidePanel
    anchors.fill: parent
    z: 1000 // Ensure it's on top of everything
    visible: opacity > 0
    opacity: open ? 1 : 0
    property string customBackgroundColor:  DB.darkenColor(DB.getThemeColor(), 0.30)
    property string activeSectionColor: DB.getThemeColor()
    property bool open: false
    property string currentPage: "notes" // Tracks the currently selected item in the side panel
    // tags property now holds objects with name and count
    property var tags: [] // [{name: "tag1", count: 5}, {name: "tag2", count: 2}]
    property int totalNotesCount: 0 // New property for total notes count
    property int trashNotesCount: 0 // New property for trash notes count
    property int archivedNotesCount: 0 // НОВОЕ СВОЙСТВО: для количества заметок в архиве

    // NEW: Define a signal to notify the parent when the panel requests to be closed
    signal closed();

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }

    // Function to refresh the tags and their counts from the database
    function refreshTagsInSidePanel() {
        tags = DB.getAllTagsWithCounts();
        // Sort tags by count in descending order for consistency if desired
        tags.sort(function(a, b) {
            return b.count - a.count;
        });
        console.log(("SidePanel: Tags refreshed with counts.", JSON.stringify(tags)));
    }

    // Function to refresh general note counts
    function refreshNoteCounts() {
        totalNotesCount = DB.getAllNotes().length; // Assuming this function exists
        trashNotesCount = DB.getDeletedNotes().length; // Assuming this function exists
        archivedNotesCount = DB.getArchivedNotes().length; // НОВОЕ: Получаем количество заметок в архиве
        console.log("SidePanel: Total notes count:", totalNotesCount);
        console.log("SidePanel: Trash notes count:", trashNotesCount);
        console.log("SidePanel: Archived notes count:", archivedNotesCount); // Логируем
    }

    // Helper function to handle navigation logic for main sections
    function navigateAndManageStack(targetPageUrl, newCurrentPageProperty, targetPageObjectName) {
        if (sidePanel.currentPage === newCurrentPageProperty) {
            // If already on this page type (based on side panel's selected state), just close the side panel
            sidePanel.closed();
            return;
        }

        sidePanel.currentPage = newCurrentPageProperty;
        var currentStackPageObjectName = pageStack.currentPage ? pageStack.currentPage.objectName : "";

        if (currentStackPageObjectName === "mainPage") {
            // If the current page on the stack is MainPage, push the new page onto the stack.
            // This allows swiping back to MainPage.
            pageStack.push(targetPageUrl);
        } else {
            if (targetPageUrl === Qt.resolvedUrl("MainPage.qml")) {
               pageStack.pop();
            }
            else {
            // If we are on any other page (not MainPage), replace it with the new page.
            // This ensures the stack never gets deeper than [MainPage, SidePanelNavigatedPage]
                pageStack.replace(targetPageUrl);
            }
        }
        sidePanel.closed(); // Close the side panel after navigation
    }

    Component.onCompleted: {
        DB.permanentlyDeleteExpiredDeletedNotes();
        refreshTagsInSidePanel(); // Load tags when the panel component is ready
        refreshNoteCounts(); // Load note counts when the panel component is ready
    }

    onOpenChanged: {
        if (open) {
            refreshTagsInSidePanel(); // Refresh tags whenever the panel opens
            refreshNoteCounts(); // Refresh note counts whenever the panel opens
        }
    }

    // Semi-transparent overlay for the rest of the screen
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "black"
        opacity: 0.6
    }

    MouseArea {
        anchors.fill: parent
        enabled: open
        onClicked: {
            sidePanel.closed(); // Emit the signal instead of directly modifying a global property
        }
    }

    // The actual panel content
    Rectangle {
        id: panelContent
        width: parent.width * 0.75
        height: parent.height
        color: sidePanel.customBackgroundColor // старый #1c1d29
        x: open ? 0 : -width

        Behavior on x {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        // The main scrollable area of the side panel
        SilicaFlickable {
            id: sidePanelFlickable // <-- Give the Flickable an ID
            anchors.fill: parent
            contentHeight: contentColumn.height // This drives the scrollability

            Column {
                id: contentColumn
                width: parent.width
                spacing: Theme.paddingMedium

                // Header of the SidePanel
                Item {
                    id: sidePanelHeader // <-- Give the header an ID for the scrollbar
                    width: parent.width
                    height: Theme.itemSizeLarge

                    Label {
                        text: qsTr("Aurora Notes")
                        color: "#e2e3e8"
                        font.pixelSize: Theme.fontSizeExtraLarge
                        font.bold: true
                        anchors {
                            left: parent.left
                            leftMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                    }
                    Item {
                        width: Theme.fontSizeExtraLarge * 1.1
                        height: Theme.fontSizeExtraLarge * 1.1
                        clip: false  // Important: do not clip!
                        anchors {
                            right: parent.right
                            rightMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                        RippleEffect {
                            id: closeRipple
                        }
                        Icon {
                            id: pinIconButton
                            source: "../icons/close.svg"
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: closeRipple.ripple(mouseX, mouseY)
                            onClicked: {
                                sidePanel.closed(); // Emit the signal instead of directly modifying a global property
                            }

                        }
                    }
                }

                // Navigation Section
                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    SectionHeader {
                        text: qsTr("Navigation")
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#a0a1ab"
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        horizontalAlignment: Text.AlignLeft
                    }


                    // Notes Button
                    NavigationButton {
                        icon: "../icons/notes.svg"
                        text: qsTr("Notes")
                        selected: sidePanel.currentPage === "notes"
                        noteCount: sidePanel.totalNotesCount
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("MainPage.qml"), "notes", "mainPage");
                        }
                    }

                    NavigationButton {
                        icon: "../icons/archive.svg"
                        text: qsTr("Archive")
                        selected: sidePanel.currentPage === "archive"
                        noteCount: sidePanel.archivedNotesCount
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("ArchivePage.qml"), "archive", "archivePage");
                        }
                    }

                    NavigationButton {
                        icon: "../icons/trash.svg"
                        text: qsTr("Trash")
                        selected: sidePanel.currentPage === "trash"
                        noteCount: sidePanel.trashNotesCount
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("TrashPage.qml"), "trash", "trashPage");
                        }
                    }

                    // Import & Export Button
                    NavigationButton {
                        icon: "../icons/import_export.svg"
                        text: qsTr("Import & Export")
                        selected: sidePanel.currentPage === "import/export"
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("ImportExportPage.qml"), "import/export", "importExportPage");
                        }
                    }

                    NavigationButton {
                        icon: "../icons/settings.svg"
                        text: qsTr("Settings")
                        selected: sidePanel.currentPage === "settings"
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("SettingsPage.qml"), "settings", "settingsPage");
                        }
                    }

                    NavigationButton {
                        icon: "../icons/about.svg"
                        text: qsTr("About")
                        selected: sidePanel.currentPage === "about"
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("AboutPage.qml"), "about", "aboutPage");
                        }
                    }
                }

                // Delimiter
                Rectangle {
                    width: parent.width - Theme.paddingLarge * 2
                    height: 1
                    color: "#80ffffff"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Tags Section
                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    SectionHeader {
                        text: qsTr("Tags")
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#a0a1ab"
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        horizontalAlignment: Text.AlignLeft
                    }

                    // Edit Tags Button
                    NavigationButton {
                        width: parent.width
                        icon: "../icons/edit.svg"
                        text: qsTr("Edit Tags")
                        selected: sidePanel.currentPage === "edit"
                        selectedColor: sidePanel.activeSectionColor
                        onClicked: {
                            navigateAndManageStack(Qt.resolvedUrl("TagEditPage.qml"), "edit", "tagEditPage");
                        }
                    }
                    Label {
                        id: noTagsLabel
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: qsTr("You have no tags.\n Go to edit tags page\nto create one!")
                        font.italic: true
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        visible: tags.length === 0
                    }
                    Repeater {
                        model: tags // Model now contains {name, count} objects
                        delegate: NavigationButton {
                            icon: "../icons/tag.svg"
                            text: modelData.name // Pass the tag name
                            noteCount: modelData.count // Pass the note count
                            selectedColor: sidePanel.activeSectionColor
                            onClicked: {
                                console.log(("Tag selected:", modelData.name));

                                // Check if the current page object in the stack is MainPage
                                var isMainPageActive = pageStack.currentPage && pageStack.currentPage.objectName === "mainPage";

                                if (isMainPageActive) {
                                    // If MainPage is currently active, update its properties directly
                                    // This assumes MainPage.qml has properties like 'selectedTags' and 'currentSearchText'
                                    // that it observes and uses to filter its content.
                                    pageStack.currentPage.selectedTags = [modelData.name];
//                                    pageStack.currentPage.currentSearchText = ""; // Clear search text when a tag is applied
                                    console.log(("Updated existing MainPage with tag filter: %1").arg(modelData.name));
                                    mainPage.performSearch("", [modelData.name])
                                    // If you want the 'Notes' navigation button to appear 'selected' when a tag is applied
                                    sidePanel.currentPage = "notes";
                                } else {
                                    // If not MainPage, navigate to a new MainPage instance, applying the filter.
                                    // This uses 'replace' so that if you're on, say, 'ArchivePage', it goes directly
                                    // to the filtered 'MainPage' and clears 'ArchivePage' from the stack.
                                    pageStack.pop();
                                    pageStack.completeAnimation();
                                    pageStack.replace(Qt.resolvedUrl("MainPage.qml"), { selectedTags: [modelData.name], currentSearchText: "" });
                                    console.log(("Navigating to new MainPage with tag filter: %1").arg(modelData.name));

                                    // Update the side panel's internal state to reflect "notes" section is active
                                    sidePanel.currentPage = "notes";
                                }

                                sidePanel.closed(); // Always close the side panel after tag selection
                            }
                        }
                    }
                }
            }
        }
    }
}

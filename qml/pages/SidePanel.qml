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
        console.log(qsTr("SidePanel: Tags refreshed with counts.", JSON.stringify(tags)));
    }

    // Function to refresh general note counts
    function refreshNoteCounts() {
        totalNotesCount = DB.getAllNotes().length; // Assuming this function exists
        trashNotesCount = DB.getDeletedNotes().length; // Assuming this function exists
        archivedNotesCount = DB.getArchivedNotes().length; // НОВОЕ: Получаем количество заметок в архиве
        console.log(qsTr("SidePanel: Total notes count:", totalNotesCount));
        console.log(qsTr("SidePanel: Trash notes count:", trashNotesCount));
        console.log(qsTr("SidePanel: Archived notes count:", archivedNotesCount)); // Логируем
    }

    // Helper function to handle navigation logic
    function navigateAndManageStack(targetPageUrl, newCurrentPageProperty, targetPageObjectName) {
        if (sidePanel.currentPage === newCurrentPageProperty) {
            // If already on this page type, just close the side panel
            sidePanel.closed();
            return;
        }

        sidePanel.currentPage = newCurrentPageProperty;
        var currentStackPageObjectName = pageStack.currentPage ? pageStack.currentPage.objectName : "";

        if (currentStackPageObjectName === "mainPage") {
            // If the current page on the stack is MainPage, push the new page
            pageStack.push(targetPageUrl);
        } else {
            // If we are on any other page (not MainPage), replace it with the new page
            // This ensures the stack never gets deeper than [MainPage, SidePanelNavigatedPage]
            pageStack.replace(targetPageUrl);
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

                    Repeater {
                        model: tags // Model now contains {name, count} objects
                        delegate: NavigationButton {
                            icon: "../icons/tag.svg"
                            text: modelData.name // Pass the tag name
                            noteCount: modelData.count // Pass the note count
                            selectedColor: sidePanel.activeSectionColor
                            onClicked: {
                                console.log(qsTr("Tag selected:", modelData.name));
                                sidePanel.closed(); // Emit signal to close the panel

                                // Tags are handled slightly differently as they filter MainPage
                                // We replace the current page with a new MainPage instance, applying the filter.
                                // This ensures that swiping back from a tag filter will go to the previous
                                // page before the tag filter was applied (e.g., main notes list without filter).
                                pageStack.replace(Qt.resolvedUrl("MainPage.qml"), { selectedTags: [modelData.name], currentSearchText: "" });

                                // Update sidePanel.currentPage to reflect that 'notes' view is active, but with a tag filter
                                // This assumes that "notes" is the primary section for tag filtering.
                                sidePanel.currentPage = "notes";
                                console.log(qsTr("Navigating to search with tag: %1").arg(modelData.name));
                            }
                        }
                    }
                }
            }
        }
    }
}

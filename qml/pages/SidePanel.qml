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

    property bool open: false
    property string currentPage: "notes"
    // tags property now holds objects with name and count
    property var tags: [] // [{name: "tag1", count: 5}, {name: "tag2", count: 2}]
    property int totalNotesCount: 0 // New property for total notes count
    property int trashNotesCount: 0 // New property for trash notes count

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
        console.log("SidePanel: Tags refreshed with counts.", JSON.stringify(tags));
    }

    // Function to refresh general note counts
    function refreshNoteCounts() {
        totalNotesCount = DB.getAllNotes().length; // Assuming this function exists
        trashNotesCount = DB.getDeletedNotes().length; // Assuming this function exists
        console.log("SidePanel: Total notes count:", totalNotesCount);
        console.log("SidePanel: Trash notes count:", trashNotesCount);
    }

    Component.onCompleted: {
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
            mainPage.panelOpen = false
        }
    }

    // The actual panel content
    Rectangle {
        id: panelContent
        width: parent.width * 0.75
        height: parent.height
        color: "#121218" // старый #1c1d29
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
                        text: "Aurora Notes"
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
                                mainPage.panelOpen = false
                            }

                        }
                    }
                }

                // Navigation Section
                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    SectionHeader {
                        text: "Navigation"
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#a0a1ab"
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        horizontalAlignment: Text.AlignLeft
                    }

                    // Notes Button
                    NavigationButton {
                        icon: "../icons/notes.svg"
                        text: "Notes"
                        selected: sidePanel.currentPage === "notes"
                        noteCount: sidePanel.totalNotesCount // Pass total notes count
                        onClicked: {
                            sidePanel.currentPage = "notes"
                            mainPage.panelOpen = false
                        }
                    }

                    // Reminders Button
//                    NavigationButton {
//                        icon: "../icons/reminders.svg"
//                        text: "Reminders"
//                        selected: sidePanel.currentPage === "reminders"
//                        onClicked: {
//                            sidePanel.currentPage = "reminders"
//                            mainPage.panelOpen = false
//                        }
//                    }
                    NavigationButton {
                        icon: "../icons/archive.svg"
                        text: "Archive"
                        selected: sidePanel.currentPage === "archive"
                        onClicked: {
                            sidePanel.currentPage = "archive"
                            pageStack.push(Qt.resolvedUrl("trashArchivePage.qml"), {
                                pageMode: "archive"
                            });
                            mainPage.panelOpen = false
                        }
                    }

                    NavigationButton {
                        icon: "../icons/trash.svg"
                        text: "Trash"
                        selected: sidePanel.currentPage === "trash"
                        noteCount: sidePanel.trashNotesCount // Pass trash notes count
                        onClicked: {
                            sidePanel.currentPage = "trash"
                            pageStack.push(Qt.resolvedUrl("TrashPage.qml"))
                            mainPage.panelOpen = false
                        }
                    }

                    NavigationButton {
                        icon: "../icons/settings.svg"
                        text: "Settings"
                        selected: sidePanel.currentPage === "settings"
                        onClicked: {
                            sidePanel.currentPage = "settings"
                            mainPage.panelOpen = false
                        }
                    }

                    NavigationButton {
                        icon: "../icons/about.svg"
                        text: "About"
                        selected: sidePanel.currentPage === "about"
                        onClicked: {
                            sidePanel.currentPage = "about"
                            pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                            mainPage.panelOpen = false
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

                    SectionHeader { // "Tags" header remains
                        text: "Tags"
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#a0a1ab"
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        horizontalAlignment: Text.AlignLeft
                    }

                    // New Row to hold "Add Tag" and "Edit Tags" buttons side-by-side
                    NavigationButton {
                        width: parent.width // Make it take the full width of the parent Row
                        icon: "../icons/edit.svg"
                        text: "Edit Tags"
                        selected: sidePanel.currentPage === "edit"
                        onClicked: {
                            sidePanel.currentPage = "edit"
                            pageStack.push(Qt.resolvedUrl("TagEditPage.qml"), {
                                onTagsChanged: mainPage.refreshData // Pass callback to refresh main page data
                            })
                            mainPage.panelOpen = false
                        }
                    }

                    // Tags List
                    Repeater {
                        model: tags // Model now contains {name, count} objects
                        delegate: NavigationButton {
                            icon: "../icons/tag.svg"
                            text: modelData.name // Pass the tag name
                            noteCount: modelData.count // Pass the note count
                            onClicked: {
                                console.log("Tag selected:", modelData.name)
                                mainPage.panelOpen = false
                                // pageStack.push(Qt.resolvedUrl("TagNotesPage.qml"), {tag: modelData.name})
                            }
                        }
                    }
                }
            }
        }
    }
}

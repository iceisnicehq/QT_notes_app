// NoteTags.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DatabaseManager // Adjust this path if your DatabaseManager.js is elsewhere

Page {
    id: noteTagsPage
    // Set the background color of the page dynamically from the parent page
    property string noteBackgroundColor: "#121218" // New property to receive the color
    backgroundColor: noteBackgroundColor // Use the received color for the page background

    // Properties passed from the calling page (e.g., NewNotePage)
    // 'noteId' is crucial to know which note's tags we are managing.
    property int noteId: -1
    // Callback to notify the parent page (NewNotePage) when tags might have changed.
    property var onTagsChanged: function() {}

    // ListModel to hold all available tags and their checked status for the current note.
    ListModel {
        id: availableTagsModel
        // Each item in the model will have 'name' (string) and 'isChecked' (boolean).
    }

    // Load tag data when this page becomes active and visible.
    Component.onCompleted: {
        console.log("NoteTagsPage: Initializing for note ID:", noteId);
        loadTags();
    }

    // Function to fetch all tags from the database and determine their checked state
    // based on whether they are associated with the current note.
    function loadTags() {
        availableTagsModel.clear(); // Clear existing model data
        var allTags = DatabaseManager.getAllTags(); // Get all tag names from the DB
        var noteSpecificTags = [];

        // If a valid noteId is provided, fetch its associated tags.
        if (noteId !== -1) {
            noteSpecificTags = DatabaseManager.getTagsForNote(null, noteId);
        } else {
            console.warn("NoteTagsPage: No valid noteId provided. Cannot load note-specific tags.");
        }

        // Populate the ListModel with all tags and their checked status.
        for (var i = 0; i < allTags.length; i++) {
            var tagName = allTags[i];
            var isChecked = noteSpecificTags.indexOf(tagName) !== -1; // Check if tag is in the note's tags
            availableTagsModel.append({
                name: tagName,
                isChecked: isChecked
            });
        }
        console.log("NoteTagsPage: Loaded tags for display.");
        // Add debug logs for scrolling
        console.log("tagsFlickable height after load:", tagsFlickable.height);
        console.log("tagsListView contentHeight after load:", tagsListView.contentHeight);
    }

    // Custom Header Area
    Item {
        id: customHeaderArea
        width: parent.width
        height: Theme.itemSizeLarge
        z: 2

        Rectangle {
            id: headerContainer
            width: parent.width
            height: parent.height
            color: noteTagsPage.noteBackgroundColor
        }

        // Back Button
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
            RippleEffect { id: backRipple }
            Icon {
                id: backButtonIcon
                source: "../icons/back.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }
            MouseArea {
                anchors.fill: parent
                onPressed: backRipple.ripple(mouseX, mouseY)
                onClicked: {
                    pageStack.pop();
                    onTagsChanged();
                }
            }
        }

        // Page Title
        Label {
            text: "Note Tags"
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeLarge
            color: "#e2e3e8"
        }
    }

    // Main content area: A flickable list to display all tags.
    SilicaFlickable {
        id: tagsFlickable
        anchors.fill: parent
        anchors.topMargin: customHeaderArea.height
        // Ensure contentHeight is correctly tied to the ListView's total content height
        contentHeight: tagsListView.contentHeight

        // Add debug logs for flickable height changes
        onHeightChanged: {
            console.log("tagsFlickable height changed:", height);
        }

        // ListView to display individual tag items.
        ListView {
            id: tagsListView
            width: parent.width
            // CRUCIAL FIX: ListView height should be its own contentHeight for correct scrolling
            height: contentHeight // This will make the ListView expand to fit all its items

            model: availableTagsModel
            orientation: ListView.Vertical
            spacing: Theme.paddingSmall

            // Delegate defines the appearance and behavior of each item in the ListView.
            delegate: BackgroundItem {
                id: tagDelegateRoot
                width: parent.width
                height: Theme.itemSizeMedium
                clip: true // Ensure ripple effect is clipped to the item's bounds

                // Ripple effect for the entire row
                RippleEffect { id: delegateRipple }

                // MouseArea covering the entire delegate for full row clickability and ripple.
                MouseArea {
                    anchors.fill: parent
                    onPressed: delegateRipple.ripple(mouseX, mouseY) // Trigger ripple on the whole row
                    onClicked: {
                        // Toggle the checked state in the model immediately for UI responsiveness
                        var newCheckedState = !model.isChecked;
                        availableTagsModel.set(index, { name: model.name, isChecked: newCheckedState });

                        // Perform database operation based on the new state
                        if (noteId === -1) {
                            console.warn("Note ID is -1. Cannot modify tags.");
                            return;
                        }

                        if (newCheckedState) {
                            DatabaseManager.addTagToNote(noteId, model.name);
                            console.log("Added tag '" + model.name + "' to note ID " + noteId);
                        } else {
                            DatabaseManager.deleteTagFromNote(noteId, model.name);
                            console.log("Removed tag '" + model.name + "' from note ID " + noteId);
                        }
                    }
                }

                // Row layout for icon, tag name, and toggle button.
                Row {
                    id: tagRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge
                    spacing: Theme.paddingMedium

                    // Tag Icon (now correctly using Icon component for tinting)
                    Icon {
                        id: tagIcon
                        source: "../icons/tag-white.svg"
                        color: "#e2e3e8"
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                        anchors.verticalCenter: parent.verticalCenter
                        fillMode: Image.PreserveAspectFit
                    }

                    // Tag Name Label
                    Label {
                        id: tagNameLabel
                        text: model.name
                        color: "#e2e3e8"
                        font.pixelSize: Theme.fontSizeMedium
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        width: parent.width - tagIcon.width - checkButtonContainer.width - (tagRow.spacing * 2)
                    }

                    // Custom Toggle Button (visuals only, interaction is on parent MouseArea)
                    Item {
                        id: checkButtonContainer
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                        anchors.verticalCenter: parent.verticalCenter
                        clip: false

                        Image {
                            id: checkIcon
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
    // ScrollBar
    ScrollBar {
        flickableSource: tagsFlickable
        topAnchorItem: customHeaderArea
    }
}

// TagEditPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Page {
    id: tagEditPage
    backgroundColor: "#121218"

    property var onTagsChanged: null // Callback for MainPage to refresh tags

    // Properties to control header visibility (similar to MainPage)
    property bool headerVisible: true
    property real previousContentY: 0

    // Properties for new tag creation
    property bool creatingNewTag: false
    property string newTagNameInput: ""
    property bool newTagInputError: false // Kept for logic, but visual feedback removed

    // Property to hold all tags with their note counts
    property var allTagsWithCounts: [] // Will store [{name: "tag1", count: 5}, {name: "tag2", count: 2}]
    property var editingTagData: null // {name: "oldName", count: 5, id: 123} // When editing an existing tag

    Component.onCompleted: {
        console.log("TagEditPage opened.");
        refreshTags();
    }

    function refreshTags() {
        allTagsWithCounts = DB.getAllTagsWithCounts();
        // Sort tags by count in descending order
        allTagsWithCounts.sort(function(a, b) {
            return b.count - a.count;
        });
        console.log("Tags refreshed:", JSON.stringify(allTagsWithCounts));
    }

    // Header Area - Positioned above the Flickable
    Item {
        id: headerArea
        width: parent.width
        height: Theme.itemSizeLarge // Sufficient height for header elements
        z: 2 // Ensures the header appears ON TOP of the list content

        // Animate the y-position based on the headerVisible property
        y: headerVisible ? 0 : -height

        Behavior on y {
            NumberAnimation {
                duration: 250 // You can adjust this duration for speed
                easing.type: Easing.OutQuad
            }
        }

        Rectangle {
            id: headerContainer
            width: parent.width
            height: parent.height
            color: "#121218" // Match page background

            // Back Button (Left side)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
                RippleEffect { id: backRipple }
                Icon {
                    id: backIcon
                    source: "../icons/back.svg" // Changed to explicit back icon
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: backRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        // If tags were changed, notify MainPage
                        if (onTagsChanged) {
                            onTagsChanged();
                        }
                        pageStack.pop();
                    }
                }
            }

            Label {
                text: "Edit Tags"
                anchors.centerIn: parent
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
            }
        }
    }

    // Main scrollable area
    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: headerArea.height
        contentHeight: contentColumn.height // This makes the Flickable scrollable

        // The logic for showing/hiding the header
        onContentYChanged: {
            var scrollY = flickable.contentY;

            if (flickable.atYBeginning) {
                tagEditPage.headerVisible = true;
            } else if (scrollY < tagEditPage.previousContentY) {
                tagEditPage.headerVisible = true;
            } else if (scrollY > tagEditPage.previousContentY && scrollY > headerArea.height) {
                tagEditPage.headerVisible = false;
            }
            tagEditPage.previousContentY = scrollY;
        }

        Column {
            id: contentColumn
            width: parent.width

            Item {
                id: newTagInputArea
                width: parent.width // contentColumn.width
                height: 80
                Rectangle {
                    id: newTagInputContainer
                    width: parent.width + 2 // Adjusted to match noteMargin behavior
                    height: parent.height
                    anchors.centerIn: parent
                    color: "transparent" // A background color like the search bar
                    border.color: "#43484e"
                    border.width: 2
                    // The TextField is now the main component inside this container
                    SearchField {
                        id: tagInput
                        anchors.fill: parent // TextField fills its parent container
// Removed these as SearchField's leftItem/rightItem handle margins internally
//                        anchors.leftMargin: newTagPlusXItem.width + Theme.paddingMedium
//                        anchors.rightMargin: newTagCheckItem.width + Theme.paddingMedium
                        highlighted: false
                        placeholderText: "Create new tag"
                        text: newTagNameInput
                        onTextChanged: newTagNameInput = text
                        font.pixelSize: Theme.fontSizeMedium
                        color: "#e8eaed" // Always default color, no error color change
                        inputMethodHints: Qt.ImhNoAutoUppercase

                        focus: creatingNewTag // Keep focus when creating
                        onClicked: { creatingNewTag = true } // This sets creation mode when clicked
                        // Handle Enter key to trigger tag creation
                        EnterKey.onClicked: {
                            if (newTagCheckItem.enabled) { // Check 'enabled' state of the right item
                                newTagCheckItem.MouseArea.onClicked();
                            }
                        }

                        // Allow clicking on the TextField to activate creation mode
                        MouseArea {
                            anchors.fill: parent
                            enabled: !creatingNewTag // Only clickable when not in creation mode
                            onClicked: {
                                tagEditPage.creatingNewTag = true;
                                newTagNameInput = "";
                                tagInput.forceActiveFocus(true);
                            }
                        }

                        // <<< START ADDED BLOCK >>>
                        // Handle loss of focus: If input is empty and we lose focus, exit creation mode
                        onActiveFocusChanged: {
                            if (!activeFocus && creatingNewTag) { // If focus was lost AND we are in creation mode
                                if (newTagNameInput.trim() === "") { // And the input field is empty
                                    creatingNewTag = false; // Exit creation mode
                                    // newTagNameInput is already empty, no need to clear again
                                    // newTagInputError is not used for visual feedback here, so no need to reset immediately
                                    console.log("Tag creation cancelled (empty field, lost focus).");
                                }
                            }
                        }
                        // <<< END ADDED BLOCK >>>

                        // Left Icon (Plus or X) - as leftItem of TextField equivalent
                        leftItem: Item {
                            id: newTagPlusXItem // Renamed for clarity
                            width: Theme.fontSizeExtraLarge * 1.1
                            height: Theme.fontSizeExtraLarge * 1.1
                            clip: false

                            Icon {
                                id: plusXIcon
                                source: "../icons/plus.svg" // Always use plus.svg for rotation effect
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                rotation: creatingNewTag ? 45 : 0 // Rotate to X (45 degrees)
                                Behavior on rotation { NumberAnimation { duration: 150 } }
                            }
                            RippleEffect { id: plusXRipple }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: plusXRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    if (creatingNewTag) {
                                        // If already creating (showing X), cancel
                                        creatingNewTag = false;
                                        newTagNameInput = "";
                                        tagInput.forceActiveFocus(false); // Hide keyboard
                                        if (toastManager) toastManager.show("Tag creation cancelled.");
                                    } else {
                                        // Start creating
                                        creatingNewTag = true;
                                        newTagNameInput = ""; // Clear input when starting new tag
                                        tagInput.forceActiveFocus(true); // Show keyboard
                                    }
                                }
                            }
                        }

                        // Right Check Button - as rightItem of TextField equivalent
                        rightItem: Item {
                            id: newTagCheckItem // Renamed for clarity
                            width: Theme.fontSizeExtraLarge * 1.1
                            height: Theme.fontSizeExtraLarge * 1.1
                            clip: false

                            visible: true // Always visible
                            opacity: creatingNewTag ? 1 : 0.3 // Full opacity when creating, greyed out otherwise
                            Behavior on opacity { NumberAnimation { duration: 150 } } // Smooth transition

                            RippleEffect { id: checkRipple }
                            Icon {
                                id: checkIcon
                                source: "../icons/check.svg"
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: creatingNewTag // Only enabled when creating a new tag
                                onPressed: checkRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    var trimmedTag = newTagNameInput.trim();
                                    if (trimmedTag === "") {
                                        if (toastManager) toastManager.show("Tag name cannot be empty!");
                                    } else {
                                        var tagExists = allTagsWithCounts.some(function(t) {
                                            return t.name.toLowerCase() === trimmedTag.toLowerCase();
                                        });

                                        if (tagExists) {
                                            console.log("Error: Tag '" + trimmedTag + "' already exists.");
                                            if (toastManager) toastManager.show("Tag '" + trimmedTag + "' already exists!");
                                        } else {
                                            DB.addTag(trimmedTag); // Add tag to database
                                            refreshTags(); // Refresh list
                                            newTagNameInput = ""; // Clear input
                                            creatingNewTag = false; // Exit creation mode
                                            tagInput.forceActiveFocus(false); // Hide keyboard
                                            if (onTagsChanged) { onTagsChanged(); } // Notify MainPage
                                            if (toastManager) toastManager.show("Tag '" + trimmedTag + "' created!");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Tags List
            Column {
                width: parent.width
                visible: allTagsWithCounts.length > 0
                // Add spacing between tag list items

                Repeater {
                    model: allTagsWithCounts
                    delegate: TagListItem {
                        id: tagListItemDelegate // Changed ID for clarity
                        width: parent.width
                        tagName: modelData.name
                        noteCount: modelData.count // This is correct and passes the count

                        // Reference to the parent TagEditPage
                        parentPage: tagEditPage
                        // Pass toast manager
                        toastManager: tagEditPage.toastManager
                        // Callback to refresh tags when something changes in a list item
                        onTagEditedOrDeleted: tagEditPage.refreshTags

                        // Pass the current editing tag data for single edit session
                        property var currentEditingTag: tagEditPage.editingTagData

                        // Handle when this item is set to edit mode
                        onStartEditing: {
                            // If another item is already being edited, cancel its edit mode
                            if (tagEditPage.editingTagData && tagEditPage.editingTagData.name !== tagName) {
                                // Find the old editing item and reset it
                                // Iterate children of the Repeater's parent (Column)
                                for (var i = 0; i < parent.children.length; ++i) {
                                    var child = parent.children[i];
                                    // Use objectName for more robust lookup if multiple instances of TagListItem
                                    // Or simply rely on the fact that only one is in editing mode
                                    if (child.objectName === "tagListItemDelegate" && child.isEditing) {
                                        child.resetEditState(); // Call the internal reset function
                                        child.cancelEditing(); // Emit the signal
                                        break;
                                    }
                                }
                            }
                            // Store the full data for editing
                            tagEditPage.editingTagData = { id: modelData.id, name: tagName, count: modelData.count };
                            console.log("Start editing:", tagEditPage.editingTagData.name);
                        }
                        // Handle when this item finishes editing
                        onFinishEditing: {
                            tagEditPage.editingTagData = null;
                            console.log("Finish editing.");
                            if (onTagsChanged) { onTagsChanged(); } // Notify MainPage
                        }
                        // Handle when this item cancels editing
                        onCancelEditing: {
                            tagEditPage.editingTagData = null;
                            console.log("Cancel editing.");
                        }

                        // Ensure only one item is in edit mode at a time
                        isEditing: tagEditPage.editingTagData && tagEditPage.editingTagData.name === modelData.name

                        // Add a unique objectName for delegates for more robust lookup if needed
                        objectName: "tagListItemDelegate"
                    }
                }
            }
        }
    }
    // Scrollbar for the flickable
    ScrollBar {
        flickableSource: flickable
        topAnchorItem: headerArea
    }

    ToastManager {
        id: toastManager
    }
}

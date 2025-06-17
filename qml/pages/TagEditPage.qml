import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Page {
    id: tagEditPage
    backgroundColor: tagEditPage.customBackgroundColor !== undefined ? tagEditPage.customBackgroundColor : "#121218" // Fallback to Theme.backgroundColor if custom is not set
    showNavigationIndicator: false
    property bool panelOpen: false // Property to control side panel visibility

    // Property to hold the currently selected custom background color
    property string customBackgroundColor: DB.getThemeColor() || "#121218" // Load from DB, default to a dark color if not found    showNavigationIndicator: false
    property var onTagsChanged: null // Callback for MainPage to refresh tags
    property string borderColor:  DB.getLighterColor(tagEditPage.customBackgroundColor)

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

    // NEW: Reference to the currently editing delegate instance
    property var currentlyEditingTagDelegate: null

    // NEW: Flag to temporarily ignore focus loss during new tag creation
    property bool ignoreNextFocusLossCancellation: false

    Component.onCompleted: {
        console.log("TagEditPage opened.");
        sidePanelInstance.currentPage = "edit"; // Highlight 'settings' in the side panel
        refreshTags();
    }

    function refreshTags() {
        // Crucial: Create a new array object to force Repeater re-evaluation
        allTagsWithCounts = [];
        var fetchedTags = DB.getAllTagsWithCounts();
        // Sort tags by count in descending order
        fetchedTags.sort(function(a, b) {
            return b.count - a.count;
        });
        allTagsWithCounts = fetchedTags;
        console.log("Tags refreshed and re-assigned:", JSON.stringify(allTagsWithCounts));

        // If a tag that was being edited is no longer in the list (e.g., deleted),
        // clear the editing state.
        if (editingTagData) {
            var found = false;
            for (var i = 0; i < allTagsWithCounts.length; ++i) {
                if (allTagsWithCounts[i].name === editingTagData.name) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                editingTagData = null;
                currentlyEditingTagDelegate = null;
                console.log("Edited tag no longer exists after refresh, clearing editing state.");
            }
        }
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
            color: tagEditPage.customBackgroundColor // Match page background

            // Back Button (Left side)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
                RippleEffect { id: menuRipple }
                Icon {
                    id: menuIcon
                    source: "../icons/menu.svg" // Changed to explicit back icon
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: menuRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        tagEditPage.panelOpen = true // Open the side panel
                        console.log("Menu button clicked in TagEditPage → panelOpen = true")
                    }
                }
            }

            Label {
                text: qsTr("Edit Tags")
                anchors.centerIn: parent
                font.pixelSize: Theme.fontSizeExtraLarge
                font.bold: true
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
                width: parent.width
                height: 80
                Rectangle {
                    id: newTagInputContainer
                    width: parent.width + 2
                    height: parent.height
                    anchors.centerIn: parent
                    color: "transparent"
                    border.color: tagEditPage.borderColor
                    border.width: 2
                    SearchField {
                        id: tagInput
                        anchors.fill: parent
                        highlighted: false
                        placeholderText: "Create new tag"
                        text: newTagNameInput
                        onTextChanged: newTagNameInput = text
                        font.pixelSize: Theme.fontSizeMedium
                        color: "#e8eaed"
                        inputMethodHints: Qt.ImhNoAutoUppercase

                        focus: creatingNewTag // Keep focus when creating

                        // Modified onClicked handler for the SearchField itself
                        onClicked: {
                            // If another tag is currently being edited, reset its state first.
                            if (tagEditPage.currentlyEditingTagDelegate) {
                                tagEditPage.currentlyEditingTagDelegate.resetEditState();
                            }

                            // Only activate creation mode and clear input if not already in creation mode
                            if (!creatingNewTag) { // Check if we are NOT already creating a new tag
                                tagEditPage.ignoreNextFocusLossCancellation = true;
                                tagEditPage.creatingNewTag = true; // Activate creation mode
                                tagInput.forceActiveFocus(true); // Force active focus on this new tag input field.
                                newTagNameInput = ""; // Clear input ONLY when starting a new creation session
                            } else {
                                // If already in creatingNewTag mode, simply ensure focus
                                tagInput.forceActiveFocus(true);
                            }
                        }

                        // Handle Enter key to trigger tag creation
                        EnterKey.onClicked: {
                            if (newTagCheckItem.enabled) { // Ensure button is logically enabled
                                newTagCheckItem.performCreationLogic(); // Call the new function
                            }
                        }

                        // Modified onActiveFocusChanged to use the new flag
                        onActiveFocusChanged: {
                            if (!activeFocus) { // Focus lost
                                if (creatingNewTag) { // Only check if currently in creation mode
                                    if (tagEditPage.ignoreNextFocusCancellation) {
                                        // This focus loss was expected during a transition, ignore it.
                                        console.log("Ignoring momentary focus loss for new tag creation.");
                                        tagEditPage.ignoreNextFocusCancellation = false; // Reset the flag
                                        return;
                                    }
                                    // If not ignoring, and input is empty, then genuinely cancel.
                                    if (newTagNameInput.trim() === "") {
                                        creatingNewTag = false; // This will hide the keyboard
                                        if (toastManager) toastManager.show("Tag creation cancelled.");
                                        console.log("Tag creation cancelled (empty field, lost focus).");
                                    }
                                }
                            } else { // Focus gained
                                // Reset the flag as focus has been successfully gained
                                if (tagEditPage.ignoreNextFocusCancellation) {
                                    tagEditPage.ignoreNextFocusCancellation = false;
                                    console.log("New tag input gained focus, reset ignore flag.");
                                }
                            }
                        }

                        // Left Icon (Plus or X) - as leftItem of TextField equivalent
                        leftItem: Item {
                            id: newTagPlusXItem
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
                                        // Start creating (showing Plus), so activate creation mode
                                        // If another tag is currently being edited, reset its state first.
                                        if (tagEditPage.currentlyEditingTagDelegate) {
                                            tagEditPage.currentlyEditingTagDelegate.resetEditState();
                                        }
                                        // Set flag BEFORE setting creatingNewTag and forcing focus
                                        tagEditPage.ignoreNextFocusLossCancellation = true;
                                        creatingNewTag = true;
                                        tagInput.forceActiveFocus(true); // Show keyboard
                                        newTagNameInput = ""; // Clear input when starting new tag
                                    }
                                }
                            }
                        }

                        // Right Check Button - as rightItem of TextField equivalent
                        rightItem: Item {
                            id: newTagCheckItem
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

                            // New function to encapsulate tag creation logic
                            function performCreationLogic() {
                                var trimmedTag = newTagNameInput.trim();
                                if (trimmedTag === "") {
                                    if (toastManager) toastManager.show("Tag name cannot be empty!");
                                } else {
                                    // Removed toLowerCase() for case-sensitive check
                                    var tagExists = allTagsWithCounts.some(function(t) {
                                        return t.name === trimmedTag;
                                    });

                                    if (tagExists) {
                                        console.log("Error: Tag '" + trimmedTag + "' already exists.");
                                        if (toastManager) toastManager.show("Tag '" + trimmedTag + "' already exists!");
                                    } else {
                                        // Pass the tag with its original casing to the database manager
                                        DB.addTag(trimmedTag);
                                        refreshTags(); // Refresh list
                                        newTagNameInput = ""; // Clear input
                                        creatingNewTag = false; // Exit creation mode
                                        tagInput.forceActiveFocus(false); // Hide keyboard
                                        if (onTagsChanged) { onTagsChanged(); } // Notify MainPage
                                        if (toastManager) toastManager.show("Tag '" + trimmedTag + "' created!");
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: creatingNewTag // Only enabled when creating a new tag
                                onPressed: checkRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    newTagCheckItem.performCreationLogic(); // Call the new function
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

                Repeater {
                    model: allTagsWithCounts
                    delegate: Item { // This is the new delegate structure, formerly TagListItem.qml
                        id: tagListItemDelegate // Now this is the ID of the delegate instance
                        height: 80 // Match the height of the new tag input area for consistency
                        width: parent.width

                        // These properties are now internal to the delegate
                        property string tagName: modelData.name // Directly from modelData
                        property int noteCount: modelData.count // Directly from modelData
                        // isEditing property now derived from the global currentlyEditingTagDelegate
                        property bool isEditing: tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate

                        property string editingTagName: tagName // Temporary property for TextField
                        property bool editingInputError: false // For visual feedback on invalid edit
                        property bool isTagNameChanged: false // NEW: Track if name has been changed during edit

                        // Function to reset state for this specific delegate
                        function resetEditState() {
                            editingTagName = tagName; // Reset to original name (modelData.name)
                            editingInputError = false;
                            isTagNameChanged = false; // Reset changed state
                            // The 'focus: isEditing' property will handle hiding the keyboard when isEditing becomes false.

                            // CRITICAL: Only clear the global state if THIS delegate is the one currently editing
                            if (tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate) {
                                tagEditPage.currentlyEditingTagDelegate = null;
                                tagEditPage.editingTagData = null;
                            }
                            console.log("Delegate reset: " + tagName);
                        }

                        // Main Container - styled like the new tag input field
                        Rectangle {
                            id: tagContainer
                            width: parent.width + 2
                            height: parent.height
                            anchors.centerIn: parent
                            color: "transparent"
                            border.color: tagEditPage.borderColor
                            border.width: 2

                            SearchField {
                                id: tagInputField
                                anchors.fill: parent
                                highlighted: false // Keep this false as we control highlighting via 'color' property
                                text: isEditing ? editingTagName : tagName
                                placeholderText: "Edit tag name"
                                font.pixelSize: Theme.fontSizeMedium
                                // Highlight text color when editing, error color on error
                                color: editingInputError ? Theme.errorColor : (isEditing ? Theme.highlightColor : "#e8eaed")
                                inputMethodHints: Qt.ImhNoAutoUppercase

                                focus: isEditing // Focus SearchField if this delegate is in editing mode

                                onActiveFocusChanged: {
                                    if (activeFocus) {
                                        // If this delegate gains focus and is not already the designated editor,
                                        // tell TagEditPage to set this delegate as the active editor.
                                        if (tagEditPage.currentlyEditingTagDelegate !== tagListItemDelegate) {
                                            if (tagEditPage.currentlyEditingTagDelegate) {
                                                // Call reset on the previously editing delegate
                                                tagEditPage.currentlyEditingTagDelegate.resetEditState();
                                            }
                                            tagEditPage.currentlyEditingTagDelegate = tagListItemDelegate;
                                            tagEditPage.editingTagData = { id: modelData.id, name: tagName, count: modelData.count };
                                            console.log("Delegate (re)gained focus, now editing:", tagName);
                                        }
                                        // Re-initialize editingTagName to current tag name when focusing
                                        editingTagName = tagName;
                                        isTagNameChanged = false; // Reset changed state on focus gain
                                    } else {
                                        // If this delegate loses focus while in editing mode (and is the current editor)
                                        if (tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate) {
                                            var trimmedCurrentText = tagInputField.text.trim();
                                            // Case-sensitive comparison for original tag name check
                                            var originalTagNameTrimmed = tagName.trim();

                                            // Removed toLowerCase()
                                            if (trimmedCurrentText === "" || trimmedCurrentText === originalTagNameTrimmed) {
                                                // No change, just reset state
                                                tagListItemDelegate.resetEditState();
                                                console.log("Delegate lost focus, cancelled edit due to empty/unchanged name (no toast).");
                                            } else {
                                                // Changes were made but not saved explicitly (e.g., clicked away after typing)
                                                tagListItemDelegate.resetEditState();
                                                if (toastManager) toastManager.show("Edit cancelled."); // Show toast for unsaved changes
                                                console.log("Delegate lost focus, changes made but not explicitly saved. Resetting state.");
                                            }
                                        }
                                    }
                                }

                                onTextChanged: {
                                    if (isEditing) {
                                        editingTagName = text;
                                        // Set isTagNameChanged based on current input vs original tag name (case-sensitive)
                                        isTagNameChanged = (editingTagName.trim() !== tagName);

                                        // Reset error state on text change
                                        if (editingInputError) {
                                            editingInputError = false;
                                        }
                                    }
                                }

                                EnterKey.onClicked: {
                                    if (isEditing) {
                                        tagInputField.performSaveLogic(); // Call internal save logic
                                    }
                                }

                                // Left Icon (Trash when editing, Tag when displaying)
                                leftItem: Item {
                                    id: leftIconItem
                                    width: Theme.fontSizeExtraLarge * 1.1
                                    height: Theme.fontSizeExtraLarge * 1.1
                                    clip: false

                                    Icon {
                                        source: tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate ? "../icons/trash.svg" : "../icons/tag-white.svg"
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                    }
                                    RippleEffect { id: leftRipple }
                                    MouseArea {
                                        anchors.fill: parent
                                        onPressed: leftRipple.ripple(mouseX, mouseY)
                                        onClicked: {
                                            if (tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate) {
                                                // Delete action - IMPORTANT: DB.deleteTag might internally convert to lower case depending on its implementation
                                                // If your DB.deleteTag relies on case-insensitive matching, keep that in mind.
                                                // For this QML side, we are passing the exact tagName from the model.
                                                DB.deleteTag(tagName);
                                                tagListItemDelegate.resetEditState(); // Reset delegate and clear global state
                                                if (toastManager) toastManager.show("Deleted tag '" + tagName + "'");
                                                tagEditPage.refreshTags(); // Refresh list in parent
                                                if (tagEditPage.onTagsChanged) { tagEditPage.onTagsChanged(); }
                                            } else {
                                                // If not editing THIS specific tag, clicking should initiate edit
                                                tagInputField.forceActiveFocus(true);
                                                console.log("Tag icon clicked, forcing focus to start edit.");
                                            }
                                        }
                                    }
                                }

                                // Right Icon (Check when editing, Edit when displaying)
                                rightItem: Item {
                                    id: rightIconItem
                                    width: Theme.fontSizeExtraLarge * 1.1
                                    height: Theme.fontSizeExtraLarge * 1.1
                                    clip: false

                                    Icon {
                                        // Dynamically set source based on editing state and changes
                                        source: {
                                            if (!isEditing) {
                                                return "../icons/edit_filled.svg"; // Not editing, show pen
                                            } else {
                                                if (isTagNameChanged) {
                                                    return "../icons/check.svg"; // Editing and changed, show check
                                                } else {
                                                    return "../icons/close.svg"; // Editing but no change, show cross
                                                }
                                            }
                                        }
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                    }
                                    RippleEffect { id: rightRipple }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: true
                                        onPressed: rightRipple.ripple(mouseX, mouseY)
                                        onClicked: {
                                            if (isEditing) {
                                                if (isTagNameChanged) {
                                                    // This is effectively the "Save" action
                                                    tagInputField.performSaveLogic();
                                                } else {
                                                    // This is effectively the "Cancel" action (cross button)
                                                    tagListItemDelegate.resetEditState();
                                                    if (toastManager) toastManager.show("Edit cancelled.");
                                                }
                                            } else {
                                                // If not editing THIS specific tag, clicking should initiate edit
                                                tagInputField.forceActiveFocus(true);
                                            }
                                        }
                                    }
                                }

                                // Internal function to perform save logic
                                function performSaveLogic() {
                                    var trimmedEditTag = editingTagName.trim();
                                    if (trimmedEditTag === "") {
                                        editingInputError = true;
                                        if (toastManager) toastManager.show("Tag name cannot be empty!");
                                        return;
                                    }
                                    // Case-sensitive check for no change in tag name
                                    if (trimmedEditTag === tagName) {
                                        console.log("No change in tag name, finishing edit.");
                                        if (toastManager) toastManager.show("Edit cancelled.");
                                        tagListItemDelegate.resetEditState();
                                        return;
                                    }

                                    // Tag existence check for conflict with *other* tags (case-sensitive)
                                    var tagExists = tagEditPage.allTagsWithCounts.some(function(t) {
                                        // Check if the new tag name conflicts with any *other* existing tag (case-sensitive)
                                        // and ensure it's not the original tag itself (which is allowed if no change in value, but is caught above).
                                        return t.name === trimmedEditTag && t.name !== tagName;
                                    });

                                    if (tagExists) {
                                        editingInputError = true;
                                        console.log("Error: Tag '" + trimmedEditTag + "' already exists.");
                                        if (toastManager) toastManager.show("Tag '" + trimmedEditTag + "' already exists!");
                                    } else {
                                        // Pass original tag name and the new, user-provided casing
                                        // IMPORTANT: Ensure your DB.updateTagName can handle exact case matching for original tag name.
                                        DB.updateTagName(tagName, trimmedEditTag);
                                        tagListItemDelegate.resetEditState(); // Resets delegate and clears global state
                                        if (toastManager) toastManager.show("Updated tag '" + tagName + "' to '" + trimmedEditTag + "'");
                                        tagEditPage.refreshTags(); // Call refresh after showing toast
                                        if (tagEditPage.onTagsChanged) { tagEditPage.onTagsChanged(); }
                                    }
                                }
                            }
                        }
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
    SidePanel {
        id: sidePanelInstance
        open: tagEditPage.panelOpen
        onClosed: tagEditPage.panelOpen = false
    }
    ToastManager {
        id: toastManager
    }
}

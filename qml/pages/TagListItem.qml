import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Item {
    id: tagListItem
    height: 80 // Match the height of the new tag input area for consistency
    width: parent.width

    property string tagName: "Untitled Tag"
    property int noteCount: 0 // Default value
    property var parentPage: null // Reference to TagEditPage for refresh/toast
    property var toastManager: null // Pass the toast manager from parent
    property bool isEditing: false // Controls display mode (label vs. textfield)

    signal startEditing()
    signal finishEditing()
    signal cancelEditing()
    signal tagEditedOrDeleted() // Emitted when a tag is successfully edited or deleted

    property string editingTagName: tagName // Temporary property for TextField
    property bool editingInputError: false // For visual feedback on invalid edit

    // Function to reset state when another item starts editing
    function resetEditState() {
        if (isEditing) {
            isEditing = false;
            editingTagName = tagName; // Reset to original name
            editingInputError = false;
            tagInputField.forceActiveFocus(false); // Ensure keyboard is hidden
        }
    }

    // Main Container - styled like the new tag input field
    Rectangle {
        id: tagContainer
        width: parent.width + 2 // Matching the SearchField container
        height: parent.height
        anchors.centerIn: parent
        color: "transparent"
        border.color: "#43484e"
        border.width: 2

        // Using SearchField for both display (when not focused/editing) and input (when focused/editing)
        SearchField {
            id: tagInputField
            anchors.fill: parent
            highlighted: false // No highlight on focus
            // Dynamically set text: when not editing, show the actual tagName; when editing, show editingTagName
            text: isEditing ? editingTagName : tagName
            placeholderText: "Edit tag name"
            font.pixelSize: Theme.fontSizeMedium
            color: editingInputError && isEditing ? Theme.highlightColor : "#e8eaed"
            inputMethodHints: Qt.ImhNoAutoUppercase

            // Focus management: only focus when editing
            focus: isEditing
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // This click handler will activate editing mode if not already editing
                    isEditing = true;
                    editingTagName = tagName; // Initialize TextField with current name
                    tagListItem.startEditing(); // Signal to parent
                    tagInputField.forceActiveFocus(true); // Focus the TextField to show keyboard
                }
            }

            onTextChanged: {
                // Only update editingTagName if in editing mode
                if (isEditing) {
                    editingTagName = text;
                    editingInputError = false; // Reset error on text change
                }
            }

            // Handle Enter key to trigger save when editing
            EnterKey.onClicked: {
                if (isEditing && rightIconItem.MouseArea.enabled) {
                    rightIconItem.MouseArea.onClicked(); // Simulate click on the check button
                }
            }

            // Handle loss of focus: If input is empty or unchanged and we lose focus, cancel editing
            onActiveFocusChanged: {
                if (!activeFocus && isEditing) {
                    if (editingTagName.trim() === "" || editingTagName.trim().toLowerCase() === tagName.toLowerCase()) {
                        cancelEditingClicked();
                    }
                }
            }

            // Left Icon (Trash when editing, Tag when displaying)
            leftItem: Item {
                id: leftIconItem
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false

                Icon {
                    source: isEditing ? "../icons/trash.svg" : "../icons/tag.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                RippleEffect { id: leftRipple }
                MouseArea {
                    anchors.fill: parent
                    onPressed: leftRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (isEditing) {
                            // If editing, this is the trash icon: DELETE action
                            // Ensure no other item is in edit mode
                            tagListItem.parentPage.editingTagData = null;
                            tagListItem.parentPage.allTagsWithCounts.forEach(function(tagData, index) {
                                var delegate = tagListItem.parent.children[index];
                                if (delegate && delegate.objectName === "tagListItemDelegate" && delegate !== tagListItem) {
                                    delegate.resetEditState();
                                }
                            });

                            DB.deleteTag(tagName); // Direct delete
                            tagEditedOrDeleted(); // Signal parent to refresh list, this will trigger TagEditPage.refreshTags()
                            isEditing = false; // Exit editing mode
                            tagInputField.forceActiveFocus(false); // Hide keyboard
                            if (toastManager) toastManager.show("Deleted tag '" + tagName + "'", 200); // Toast notification with duration
                            // The onTagsChanged() callback on parentPage is also important for MainPage refresh
                            if (parentPage.onTagsChanged) { parentPage.onTagsChanged(); }
                        } else {
                            // If not editing, this is the tag icon: START EDITING action
                            // This click will be handled by the SearchField's internal MouseArea too,
                            // but explicitly setting it here for clarity or if there's a slight
                            // timing difference. The SearchField's MouseArea should now handle it primarily.
                            isEditing = true;
                            editingTagName = tagName;
                            tagListItem.startEditing();
                            tagInputField.forceActiveFocus(true);
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

                // <<< FIX: Change icon source to edit_filled.svg when not editing >>>
                Icon {
                    source: isEditing ? "../icons/check.svg" : "../icons/edit_filled.svg" // Corrected icon source
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                RippleEffect { id: rightRipple }
                MouseArea {
                    anchors.fill: parent
                    // Enabled based on mode: editable when editing, clickable when not editing
                    enabled: true // Always enabled, logic handled inside
                    onPressed: rightRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (isEditing) {
                            // If editing, this is the check icon: SAVE action
                            var trimmedEditTag = editingTagName.trim();
                            if (trimmedEditTag === "") {
                                editingInputError = true;
                                if (toastManager) toastManager.show("Tag name cannot be empty!", 200); // Toast with duration
                                return;
                            }
                            if (trimmedEditTag.toLowerCase() === tagName.toLowerCase()) {
                                // No change, just exit edit mode
                                console.log("No change in tag name, cancelling edit.");
                                cancelEditingClicked();
                                return;
                            }

                            var tagExists = parentPage.allTagsWithCounts.some(function(t) {
                                return t.name.toLowerCase() === trimmedEditTag.toLowerCase() && t.name.toLowerCase() !== tagName.toLowerCase();
                            });

                            if (tagExists) {
                                editingInputError = true;
                                console.log("Error: Tag '" + trimmedEditTag + "' already exists.");
                                if (toastManager) toastManager.show("Tag '" + trimmedEditTag + "' already exists!", 200); // Toast with duration
                            } else {
                                DB.updateTagName(tagName, trimmedEditTag);
                                tagEditedOrDeleted(); // Signal parent to refresh list
                                isEditing = false;
                                tagInputField.forceActiveFocus(false);
                                tagListItem.finishEditing();
                                if (toastManager) toastManager.show("Updated tag '" + tagName + "' to '" + trimmedEditTag + "'", 200); // Toast with duration
                                // The onTagsChanged() callback on parentPage is also important for MainPage refresh
                                if (parentPage.onTagsChanged) { parentPage.onTagsChanged(); }
                            }
                        } else {
                            // If not editing, this is the edit icon: START EDITING action
                            isEditing = true;
                            editingTagName = tagName;
                            tagListItem.startEditing();
                            tagInputField.forceActiveFocus(true);
                        }
                    }
                }
            }
        }
    }

    // Separate function for cancel logic to avoid duplication
    function cancelEditingClicked() {
        isEditing = false;
        editingTagName = tagName; // Reset to original name
        editingInputError = false;
        tagInputField.forceActiveFocus(false); // Hide keyboard
        tagListItem.cancelEditing(); // Signal to parent
        if (toastManager) toastManager.show("Edit cancelled.", 200); // Toast with duration
    }
     ToastManager {
         id: toastManager
     }

}

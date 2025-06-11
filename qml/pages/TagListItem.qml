// TagListItem.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Item {
    id: tagListItem
    width: parent.width
    height: Theme.itemSizeMedium // Height for each tag row
    property string tagName: ""
    property int noteCount: 0
    property bool isEditing: false // Controls state of this specific item
    property var parentPage: null // Reference to TagEditPage for database calls
    property var toastManager: null // Reference to toastManager

    // Signals to notify parent page about state changes
    signal startEditing()
    signal finishEditing(string oldName, string newName)
    signal cancelEditing() // <-- Corrected signal name here (was cancelEdit previously)
    signal tagEditedOrDeleted() // General signal for parent to refresh its list

    property string currentEditedName: tagName
    property bool editError: false

    // This function is for internal use within TagListItem to reset its state
    function resetEditState() {
        isEditing = false;
        currentEditedName = tagName; // Reset input to original tag name
        editError = false;
    }

    Rectangle {
        id: tagBackground
        anchors.fill: parent
        color: "#1c1d29" // Background for each tag item
        radius: 8
        anchors.leftMargin: Theme.paddingLarge
        anchors.rightMargin: Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - Theme.paddingExtraSmall * 2

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.paddingLarge
            anchors.rightMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium
            anchors.verticalCenter: parent.verticalCenter

            // Left Icon (Tag or Delete)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                anchors.verticalCenter: parent.verticalCenter
                RippleEffect { id: tagDeleteRipple }
                Icon {
                    id: tagDeleteIcon
                    source: isEditing ? "../icons/delete.svg" : "../icons/tag.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: tagDeleteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (isEditing) {
                            // Delete Tag Logic
                            console.log("Delete tag:", tagName);
                            DB.deleteTag(tagName); // Assuming DB.deleteTag by name
                            if (toastManager) toastManager.show("Tag '" + tagName + "' deleted!");
                            tagEditedOrDeleted(); // Notify parent to refresh
                        } else {
                            // Default tag icon click action (e.g., filter notes)
                            console.log("Tag icon clicked for:", tagName);
                            if (toastManager) toastManager.show("Filtering by tag '" + tagName + "' (feature not implemented)");
                        }
                    }
                }
            }

            // Note Count (only if not editing)
            Label {
                id: noteCountLabel // Added ID to reference it in TextField anchors
                text: noteCount
                color: "#a0a1ab"
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                visible: !isEditing
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            // Tag Name / Input Field
            TextField {
                id: editableTagName
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                // Corrected anchoring for TextField based on whether editing or not
                anchors.rightMargin: isEditing ? editCheckButtonContainer.width + Theme.paddingMedium : Theme.paddingLarge
                anchors.left: isEditing ? tagDeleteIcon.right : noteCountLabel.right // If editing, starts after delete icon, otherwise after count
                anchors.leftMargin: Theme.paddingMedium
                width: parent.width - (anchors.leftMargin + anchors.rightMargin + tagDeleteIcon.width + noteCountLabel.width) // More dynamic width based on anchors
                placeholderText: "Tag name"
                text: currentEditedName
                onTextChanged: currentEditedName = text
                font.pixelSize: Theme.fontSizeMedium
                color: editError ? Theme.errorColor : "#e8eaed" // Error color if empty
                inputMethodHints: Qt.ImhNoAutoUppercase
                readOnly: !isEditing // Make it read-only unless editing
                focus: isEditing // Force focus when editing
                MouseArea {
                    anchors.fill: parent
                    enabled: !isEditing // Only clickable when not in edit mode
                    onClicked: {
                        tagListItem.startEditing();
                    }
                }
            }

            // Edit / Check Button (Right side)
            Item {
                id: editCheckButtonContainer
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                RippleEffect { id: editCheckRipple }
                Icon {
                    id: editCheckIcon
                    source: isEditing ? "../icons/check.svg" : "../icons/edit_filled.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: editCheckRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        if (isEditing) {
                            // Save Edit Logic
                            var trimmedName = currentEditedName.trim();
                            if (trimmedName === "") {
                                editError = true;
                                if (toastManager) toastManager.show("Tag name cannot be empty!");
                            } else if (trimmedName.toLowerCase() === tagName.toLowerCase()) {
                                // No change, just exit edit mode
                                tagListItem.resetEditState(); // Reset state
                                editableTagName.forceActiveFocus(false); // Hide keyboard
                                tagListItem.cancelEditing(); // Signal to parent
                            }
                            else {
                                // Check for duplicate before saving
                                var existingTags = DB.getAllTags(); // Get all tag names (just names)
                                var duplicate = existingTags.some(function(t) {
                                    return t.toLowerCase() === trimmedName.toLowerCase();
                                });

                                if (duplicate) {
                                    editError = true;
                                    if (toastManager) toastManager.show("Tag '" + trimmedName + "' already exists!");
                                } else {
                                    editError = false;
                                    DB.updateTagName(tagName, trimmedName); // Update in DB
                                    if (toastManager) toastManager.show("Tag updated to '" + trimmedName + "'!");
                                    tagListItem.resetEditState(); // Reset state
                                    editableTagName.forceActiveFocus(false); // Hide keyboard
                                    tagEditedOrDeleted(); // Notify parent to refresh list
                                    tagListItem.finishEditing(tagName, trimmedName); // Signal to parent
                                }
                            }
                        } else {
                            // Enter Edit Mode
                            tagListItem.startEditing();
                        }
                    }
                }
            }
        }
        // Error message below the input field if editing
        Label {
            text: "Tag name cannot be empty"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.errorColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: tagBackground.bottom
            visible: isEditing && editError
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }
}

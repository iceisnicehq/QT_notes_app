// NewNotePage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB // Still needed for DB operations on destruction

Page {
    id: newNotePage
    backgroundColor: "#121218"

    property var onNoteSavedOrDeleted: null // Callback to refresh main page

    // These properties will hold the *current* state of the note as the user types
    property int noteId: -1 // Will be -1 for new notes, or actual ID for editing
    property string noteTitle: "" // Keep property for data model
    property string noteContent: ""
    property var noteTags: [] // Will be an array of strings (e.g., ["family", "work", "ideas"])
    property bool noteIsPinned: false // Default to not pinned
    property date noteCreationDate: new Date() // Placeholder for creation date
    property date noteEditDate: new Date()     // Placeholder for last edit date

    Component.onCompleted: {
        // Automatically focus the content area and open keyboard
        console.log("NewNotePage opened.");

        // Pre-fill fields if editing an existing note
        if (noteId !== -1) {
            noteTitleInput.text = noteTitle;
            noteContentInput.text = noteContent;
//            pinIconButton.icon.color = noteIsPinned ? Theme.highlightColor : Theme.primaryColor;
            console.log("NewNotePage opened in EDIT mode for ID:", noteId);
        } else {
            noteContentInput.forceActiveFocus();
            Qt.inputMethod.show();
            console.log("NewNotePage opened in CREATE mode.");
        }
    }

    // This is crucial: save/delete on page destruction (pop from stack)
    Component.onDestruction: {
        console.log("NewNotePage being destroyed. Attempting to save/delete note.");

        var trimmedTitle = noteTitle.trim();
        var trimmedContent = noteContent.trim();

        if (trimmedTitle === "" && trimmedContent === "") {
            // If both title and content are empty, delete the note if it was ever created
            if (noteId !== -1) { // This condition would only be true if editing an an existing note
                DB.deleteNote(noteId); // Sync call
                console.log("Debug: Empty existing note deleted with ID:", noteId);
            } else {
                console.log("Debug: New empty note not saved.");
            }
        } else {
            // If there's content, save or update the note
            if (noteId === -1) { // This is a brand new note
                var newId = DB.addNote(noteIsPinned, noteTitle, noteContent, noteTags); // Pass noteTitle
                console.log("Debug: New note added with ID:", newId);
            } else { // This is an existing note being updated
                DB.updateNote(noteId, noteIsPinned, noteTitle, noteContent, noteTags); // Pass noteTitle
                console.log("Debug: Note updated with ID:", noteId);
            }
        }

        // Always refresh main page data after potentially adding/deleting/updating
        if (onNoteSavedOrDeleted) {
            onNoteSavedOrDeleted();
        }
    }

    ToastManager {
        id: toastManager // The ToastManager now lives directly within MainPage
    }
    // --- Custom Page Header (UPDATED) ---
     Rectangle {
         id: header
         width: parent.width
         height: Theme.itemSizeSmall
         color: "#121218"
         anchors.top: parent.top
         z: 2

         Label {
             text: newNotePage.noteId === -1 ? "New Note" : "Edit Note"
             anchors.centerIn: parent
             font.pixelSize: Theme.fontSizeLarge
             color: Theme.highlightColor
         }
         Item {
             width: Theme.fontSizeExtraLarge * 1.1
             height: Theme.fontSizeExtraLarge * 1.1
             clip: false  // Important: do not clip!
             anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
             RippleEffect {
                 id: backRipple
             }
             Icon {
                 id: closeButton
                 source: "../icons/back.svg"
                 anchors.centerIn: parent
                 width: parent.width
                 height: parent.height
             }
             MouseArea {
                 anchors.fill: parent
                 onPressed: backRipple.ripple(mouseX, mouseY)
                 onClicked: pageStack.pop()
             }
         }

         Item {
             width: Theme.fontSizeExtraLarge * 1.1
             height: Theme.fontSizeExtraLarge * 1.1
             clip: false  // Important: do not clip!
             anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.paddingLarge }
             RippleEffect {
                 id: pinRipple
             }
             Icon {
                 id: pinIconButton
                 source: noteIsPinned ? "../icons/pin-enabled.svg" : "../icons/pin.svg"
                 anchors.centerIn: parent
                 width: parent.width
                 height: parent.height
             }

             MouseArea {
                 anchors.fill: parent
                 onPressed: pinRipple.ripple(mouseX, mouseY)
                 onClicked: {
                     // This toggles the pinned status
                     noteIsPinned = !noteIsPinned;
                     var msg = noteIsPinned
                         ? "The note was pinned"
                         : "The note was unpinned"

                     // show it
                     toastManager.show(msg)
                 }

             }
         }
     }

    // --- Page Content (Main Scrollable Area) ---
    SilicaFlickable {
        id: mainContentFlickable // Gave it a clear ID
        anchors.fill: parent
        anchors.topMargin: header.height
        anchors.bottomMargin: bottomToolbar.height // Make space for the sticky bottom toolbar
        contentHeight: contentColumn.implicitHeight // Use implicitHeight for Column content

        Column {
            id: contentColumn // Renamed for clarity
            width: parent.width // This column will span the full width of the flickable
//            spacing: Theme.paddingExtraSmall
      //     padding: Theme.paddingLarge // Apply padding to the entire content column

            // Title Input
            TextField {
                id: noteTitleInput
                width: parent.width // Adjusted width for padding
                anchors.horizontalCenter: parent.horizontalCenter // Center it
                placeholderText: "Title"
                text: newNotePage.noteTitle // Bind to the noteTitle property
                onTextChanged: newNotePage.noteTitle = text
                font.pixelSize: Theme.fontSizeLarge // Title text size set to large
                color: "#e8eaed"
                font.bold: true
                wrapMode: Text.Wrap
                inputMethodHints: Qt.ImhNoAutoUppercase
            }

            // Note Content Input (Body)
            TextArea {
                id: noteContentInput
                width: parent.width // Adjusted width for padding
                anchors.horizontalCenter: parent.horizontalCenter // Center it
                height: implicitHeight > 0 ? implicitHeight : Theme.itemSizeExtraLarge * 3 // Min height, grows with content
                placeholderText: "Note"
                text: newNotePage.noteContent // Bind to the noteContent property
                onTextChanged: newNotePage.noteContent = text
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                color: "#e8eaed"
                verticalAlignment: Text.AlignTop
            }

            // --- Note Tags Section ---
            // No SectionHeader "Tags" as per your request to match NoteCard style.
            Flow {
                id: tagsFlow
                width: parent.width - (Theme.horizontalPageMargin * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium
                visible: newNotePage.noteTags.length > 0

                Repeater {
                    model: newNotePage.noteTags
                    delegate: Rectangle {
                        id: tagRectangle
                        // define your normal & pressed colors
                        property color normalColor: "#32353a"
                        property color pressedColor: "#50545a"
                        color: normalColor
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium, parent.width)

                        // animate any color change
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.centerIn: parent
                            elide: Text.ElideRight
                            width: parent.width - Theme.paddingMedium
                            wrapMode: Text.NoWrap
                        }

                        MouseArea {
                            anchors.fill: parent
                            // when you press, immediately lighten
                            onPressed: {
                                tagRectangle.color = tagRectangle.pressedColor
                            }
                            // when you release, restore then navigate
                            onReleased: {
                                tagRectangle.color = tagRectangle.normalColor
                                console.log("Tag clicked for editing:", modelData)
                                pageStack.push(Qt.resolvedUrl("TagEditPage.qml"), {
                                    noteId: newNotePage.noteId,
                                    editingTag: modelData
                                })
                            }
                            // also guard against cancel (e.g. drag-out)
                            onCanceled: tagRectangle.color = tagRectangle.normalColor
                        }
                    }
                }
            }

            // Add some padding at the bottom of the column to ensure content is not hidden by toolbar
            Item { width: parent.width; height: Theme.paddingLarge * 2 }
        }
    }

    // --- Bottom Toolbar (Footer) ---
    Rectangle {
        id: bottomToolbar
        width: parent.width
        height: Theme.itemSizeExtraLarge // Typical height for a toolbar (e.g., 80px)
        anchors.bottom: parent.bottom
        color: Theme.rgba(Theme.secondaryBackgroundColor, 0.9) // Semi-transparent for overlay effect
        z: 10 // Ensure it's above the main flickable and other content

        // Toolbar content directly inside the Rectangle (static, no scroll)
        Row {
            id: toolbarRow
            width: parent.width // Span the full width of the toolbar
            height: parent.height // Match toolbar height
            spacing: Theme.paddingMedium // Space between buttons

            // Use anchors for left/right alignment and spacers for distribution
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge
            anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge

            // Left buttons
            IconButton { icon.source: "../icons/plus.svg"; onClicked: console.log("Add something"); }
            IconButton { icon.source: "../icons/palette.svg"; onClicked: console.log("Change color/theme"); }
            IconButton { icon.source: "../icons/save.svg"; onClicked: {
                console.log("Manual Save Button Clicked");
                // Manually trigger onDestruction logic immediately then pop
                newNotePage.Component.onDestruction(); // Call the destruction logic
                pageStack.pop();
            }}

            // Center: Last Edit Date
            Label {
                id: lastEditDateLabel
                text: "Last edit: " + new Date().toLocaleDateString() // Dynamic date
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter // Center within the Row
            }

            IconButton { icon.source: "../icons/more_options.svg"; onClicked: console.log("More Options"); }
        }
    }
    ScrollBar {
        // You can still give it an ID if you want to reference it later, e.g., id: myPageScrollBar
        flickableSource: mainContentFlickable // Pass the ID of your SilicaFlickable
        topAnchorItem: header // Pass the ID of your header/search bar Item
    }
}

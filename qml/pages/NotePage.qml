import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Page {
    id: newNotePage
    backgroundColor: newNotePage.noteColor
    property var onNoteSavedOrDeleted: null
    property int noteId: -1
    property string noteTitle: ""
    property string noteContent: ""
    property var noteTags: [] // This property holds the tags for the current note being edited/created
    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()
    property string noteColor: "#121218"
    property bool noteModified: false

    // Property to track if the note was sent to trash from this page
    property bool sentToTrash: false

    // Color palette for note background selection
    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]
    // Function to darken a given hex color by a percentage
    function darkenColor(hex, percentage) {
        var r = parseInt(hex.substring(1, 3), 16);
        var g = parseInt(hex.substring(3, 5), 16);
        var b = parseInt(hex.substring(5, 7), 16);

        r = Math.round(r * (1 - percentage));
        g = Math.round(g * (1 - percentage));
        b = Math.round(b * (1 - percentage));

        r = Math.max(0, Math.min(255, r));
        g = Math.max(0, Math.min(255, g));
        b = Math.max(0, Math.min(255, b));

        // Convert back to hex string and ensure two digits for each component
        var result = "#" +
                     ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
        return result;
    }

    // Actions on component completion (when page is loaded)
    Component.onCompleted: {
        console.log("NewNotePage opened.");
        if (noteId !== -1) {
            // If noteId is set, it's an existing note (EDIT mode)
            noteTitleInput.text = noteTitle;
            noteContentInput.text = noteContent;
            console.log("NewNotePage opened in EDIT mode for ID:", noteId);
            console.log("Note color on open:", noteColor);
            noteModified = false; // Reset modified status
        } else {
            // Otherwise, it's a new note (CREATE mode)
            noteContentInput.forceActiveFocus(); // Focus on content input
            Qt.inputMethod.show(); // Show keyboard
            console.log("NewNotePage opened in CREATE mode. Default color:", noteColor);
            noteModified = true; // New note is inherently modified
        }
    }

    // Actions on component destruction (when page is closed)
    Component.onDestruction: {
        console.log("NewNotePage being destroyed. Attempting to save/delete note.");
        var trimmedTitle = noteTitleInput.text.trim();
        var trimmedContent = noteContentInput.text.trim();

        if (sentToTrash) {
            // If note was explicitly sent to trash, do nothing on destruction
            console.log("Debug: Note already sent to trash. Skipping save/delete on destruction.");
        } else if (trimmedTitle === "" && trimmedContent === "") {
            // If note is empty
            if (noteId !== -1) {
                // If it was an existing note and now empty, permanently delete it
                DB.permanentlyDeleteNote(noteId);
                console.log("Debug: Empty existing note permanently deleted with ID:", noteId);
            } else {
                // If it was a new empty note, simply don't save it
                console.log("Debug: New empty note not saved.");
            }
        } else {
            // If note has content
            if (noteId === -1) {
                // If it's a new note, add it to DB
                newNotePage.noteTitle = noteTitleInput.text;
                newNotePage.noteContent = noteContentInput.text;
                var newId = DB.addNote(noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                console.log("Debug: New note added with ID:", newId + ", Color: " + noteColor);
            } else {
                // If it's an existing note, update if modified
                if (noteModified) {
                    newNotePage.noteTitle = noteTitleInput.text;
                    newNotePage.noteContent = noteContentInput.text;
                    newNotePage.noteEditDate = new Date(); // Update edit date
                    DB.updateNote(noteId, noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                    console.log("Debug: Note updated with ID:", noteId + ", Color: " + noteColor);
                } else {
                    console.log("Debug: Note with ID:", noteId, " not modified, skipping update.");
                }
            }
        }
        // Call callback function if provided
        if (onNoteSavedOrDeleted) {
            onNoteSavedOrDeleted();
        }
    }

    ToastManager {
        id: toastManager
    }

    // --- Header Section ---
    Rectangle {
        id: header
        width: parent.width
        height: Theme.itemSizeMedium
        color: newNotePage.noteColor // Header color matches note color
        anchors.top: parent.top
        z: 2
        Column {
            anchors.centerIn: parent
            Label {
                text: newNotePage.noteId === -1 ? "New Note" : "Edit Note"
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
            }
            Column {
                visible: newNotePage.noteId !== -1 // Only visible in edit mode
                anchors.horizontalCenter: parent.horizontalCenter
                Label {
                    text: "Created: " + Qt.formatDateTime(newNotePage.noteCreationDate, "dd.MM.yyyy - hh:mm")
                    font.pixelSize: Theme.fontSizeExtraSmall * 0.7
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: "Edited: " + Qt.formatDateTime(newNotePage.noteEditDate, "dd.MM.yyyy - hh:mm")
                    font.pixelSize: Theme.fontSizeExtraSmall * 0.7
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
        // Close/Check button
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
            RippleEffect { id: backRipple }
            Icon {
                id: closeButton
                // Dynamic source based on note status and content
                source: {
                    if (newNotePage.noteId === -1) { // If it's a new note
                        if (noteTitleInput.text.trim() === "" && noteContentInput.text.trim() === "") {
                            return "../icons/close.svg"; // New and empty: show close
                        } else {
                            return "../icons/check.svg"; // New and has content: show check
                        }
                    } else {
                        return "../icons/back.svg"; // Existing note: always show back
                    }
                }
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }
            MouseArea {
                anchors.fill: parent
                onPressed: backRipple.ripple(mouseX, mouseY)
                onClicked: pageStack.pop() // Pop page on click
            }
        }
        // Pin button
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.paddingLarge }
            RippleEffect { id: pinRipple }
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
                    noteIsPinned = !noteIsPinned; // Toggle pin status
                    newNotePage.noteModified = true;
                    var msg = noteIsPinned ? "The note was pinned" : "The note was unpinned"
                    toastManager.show(msg)
                }
            }
        }
    }

    // --- Bottom Toolbar ---
    Rectangle {
        id: bottomToolbar
        width: parent.width
        height: Theme.itemSizeSmall
        anchors.bottom: parent.bottom
        color: newNotePage.noteColor // Toolbar color matches note color
        z: 11.75
        // Adjust Y position based on keyboard visibility
        y: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.y - height) : (parent.height - height)
        Behavior on y {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Row {
            id: leftToolbarButtons
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            // Color palette button
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: paletteRipple }
                Icon {
                    id: paletteIcon
                    source: "../icons/palette.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: paletteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Change color/theme - toggling panel visibility");
                        // Toggle color selection panel visibility
                        if (colorSelectionPanel.opacity > 0.01) {
                            colorSelectionPanel.opacity = 0;
                        } else {
                            colorSelectionPanel.opacity = 1;
                        }
                    }
                }
            }
            // Text edit options button (placeholder functionality)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: textEditRipple }
                Icon {
                    id: textEditIcon
                    source: "../icons/text_edit.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: textEditRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Text Edit Options");
                        toastManager.show("Text edit options clicked!");
                    }
                }
            }
            // Text alignment buttons (placeholder functionality)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: alignLeftRipple }
                Icon {
                    source: "../icons/format_align_left.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: alignLeftRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Align Left");
                        noteContentInput.horizontalAlignment = Text.AlignLeft;
                    }
                }
            }
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: alignCenterRipple }
                Icon {
                    source: "../icons/format_align_center.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: alignCenterRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Align Center");
                        noteContentInput.horizontalAlignment = Text.AlignHCenter;
                    }
                }
            }
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: alignRightRipple }
                Icon {
                    source: "../icons/format_align_right.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: alignRightRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Align Right");
                        noteContentInput.horizontalAlignment = Text.AlignRight;
                    }
                }
            }
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: alignJustifyRipple }
                Icon {
                    source: "../icons/format_align_justify.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: alignJustifyRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Align Justify");
                        noteContentInput.horizontalAlignment = Text.AlignJustify;
                    }
                }
            }
            // Undo button (placeholder functionality)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: undoRipple }
                Icon {
                    id: undoIcon
                    source: "../icons/undo.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: undoRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Undo");
                        toastManager.show("Undo action triggered!");
                    }
                }
            }
            // Redo button (placeholder functionality)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: redoRipple }
                Icon {
                    id: redoIcon
                    source: "../icons/redo.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: redoRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Redo");
                        toastManager.show("Redo action triggered!");
                    }
                }
            }
            // Add Tag button - opens the tag selection panel
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: addTagRipple }
                Icon {
                    id: addTagIcon
                    source: "../icons/tag.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: addTagRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Add Tag button clicked. Opening tag selection panel.");
                        // Toggle tag selection panel visibility
                        if (tagSelectionPanel.opacity > 0.01) {
                            tagSelectionPanel.opacity = 0;
                        } else {
                            tagSelectionPanel.opacity = 1;
                        }
                    }
                }
            }
        }

        Row {
            id: rightToolbarButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            // Archive button (placeholder functionality)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: archiveRipple }
                Icon {
                    id: archiveIcon
                    source: "../icons/archive.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: archiveRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Archive Note");
                        toastManager.show("Note archived!");
                        pageStack.pop();
                    }
                }
            }

            // Delete button (moves note to trash)
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: deleteRipple }
                Icon {
                    id: deleteIcon
                    source: "../icons/delete.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: deleteRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        // Call DB.deleteNote which now moves to trash
                        if (newNotePage.noteId !== -1) {
                            DB.deleteNote(newNotePage.noteId); // Moves to trash
                            console.log("Note ID:", newNotePage.noteId, "moved to trash.");
                            newNotePage.sentToTrash = true; // Mark that it was sent to trash
                            toastManager.show("Note moved to trash!");
                            if (onNoteSavedOrDeleted) {
                                onNoteSavedOrDeleted(); // Refresh data on main page
                            }
                        } else {
                            // If it's a new unsaved note, just pop it
                            console.log("New unsaved note discarded.");
                        }
                        pageStack.pop(); // Go back to the previous page
                    }
                }
            }
        }
    }

    // --- Main Content Flickable Area (Title, Content, Tags) ---
    SilicaFlickable {
        id: mainContentFlickable
        anchors.fill: parent
        anchors.topMargin: header.height
        // Adjust bottom margin based on keyboard visibility
        anchors.bottomMargin: bottomToolbar.height + (Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0)
        contentHeight: contentColumn.implicitHeight

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Column {
            id: contentColumn
            width: parent.width * 0.98 // Slightly less than full width for padding
            anchors.horizontalCenter: parent.horizontalCenter

            // Note Title Input
            TextField {
                id: noteTitleInput
                width: parent.width
                placeholderText: "Title"
                text: newNotePage.noteTitle
                onTextChanged: {
                    newNotePage.noteTitle = text;
                    newNotePage.noteModified = true;
                }
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
                font.bold: true
                wrapMode: Text.Wrap
                inputMethodHints: Qt.ImhNoAutoUppercase
                maximumLength: 256
            }

            // Note Content Input
            TextArea {
                id: noteContentInput
                width: parent.width
                height: implicitHeight > 0 ? implicitHeight : Theme.itemSizeExtraLarge * 3
                placeholderText: "Note"
                text: newNotePage.noteContent
                onTextChanged: {
                    newNotePage.noteContent = text;
                    newNotePage.noteModified = true;
                }
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                color: "#e8eaed"
                verticalAlignment: Text.AlignTop
            }

            // Flow layout for displaying selected tags
            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingMedium
                visible: newNotePage.noteTags.length > 0 // Only visible if tags exist

                Repeater {
                    model: newNotePage.noteTags // Model for tags
                    delegate: Rectangle {
                        id: tagRectangle
                        property color normalColor: "#a032353a"
                        property color pressedColor: "#c050545a"
                        color: normalColor
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium, parent.width)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.centerIn: parent
                            elide: Text.ElideRight
                            width: parent.width - Theme.paddingMedium
                            wrapMode: Text.NoWrap
                            textFormat: Text.PlainText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: tagRectangle.color = tagRectangle.pressedColor
                            onReleased: {
                                tagRectangle.color = tagRectangle.normalColor
                                console.log("Tag clicked for editing:", modelData)
                                Qt.inputMethod.hide();
                                // Open tag selection panel when a tag is clicked
                                if (tagSelectionPanel.opacity > 0.01) {
                                    tagSelectionPanel.opacity = 0;
                                } else {
                                    tagSelectionPanel.opacity = 1;
                                }
                            }
                            onCanceled: tagRectangle.color = tagRectangle.normalColor
                        }
                    }
                }
            }

            Item { width: parent.width; height: Theme.paddingLarge * 2 }
        }

        Label {
            id: noTagsLabel
            text: "No tags"
            font.italic: true
            visible: newNotePage.noteTags.length === 0
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: contentColumn.bottom
        }
    }

    // --- Overlay for Color Selection Panel ---
    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: "#000000"
        visible: colorSelectionPanel.opacity > 0.01
        opacity: colorSelectionPanel.opacity * 0.4
        z: 10.5

        MouseArea {
            anchors.fill: parent
            enabled: overlayRect.visible
            onClicked: {
                if (colorSelectionPanel.opacity > 0.01) {
                    colorSelectionPanel.opacity = 0;
                }
            }
        }
    }

    // --- Color Selection Panel ---
    Rectangle {
        id: colorSelectionPanel
        width: parent.width
        property real panelRadius: Theme.itemSizeSmall / 2
        height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + panelRadius
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomToolbar.bottom
        z: 12
        opacity: 0
        visible: opacity > 0.01
        color: "transparent" // Outer rectangle is transparent, visual body inside has color
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: colorPanelVisualBody
            width: parent.width
            height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + 2 * colorSelectionPanel.panelRadius
            color: newNotePage.noteColor // Color panel's background matches current note color
            //radius: colorSelectionPanel.panelRadius
            y: 0

            Column {
                id: colorPanelContentColumn
                width: parent.width
                height: implicitHeight
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: colorSelectionPanel.panelRadius
                anchors.bottomMargin: Theme.paddingMedium
                spacing: Theme.paddingMedium

                Label {
                    id: colorTitle
                    text: "Select Note Color"
                    font.pixelSize: Theme.fontSizeLarge
                    color: "#e8eaed"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Flow {
                    id: colorFlow
                    width: parent.width
                    spacing: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: Qt.LeftToRight
                    readonly property int columns: 6
                    readonly property real itemWidth: (parent.width - (spacing * (columns - 1))) / columns

                    Repeater {
                        model: newNotePage.colorPalette
                        delegate: Item {
                            width: parent.itemWidth
                            height: parent.itemWidth

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: (newNotePage.noteColor === modelData) ? "white" : "#707070" // Outer ring for selected color
                                border.color: "transparent"
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.95
                                height: parent.height * 0.95
                                radius: width / 2
                                color: modelData // Actual color swatch
                                border.color: "transparent"

                                Rectangle {
                                    visible: newNotePage.noteColor === modelData // Checkmark for selected color
                                    anchors.centerIn: parent
                                    width: parent.width * 0.7
                                    height: parent.height * 0.7
                                    radius: width / 2
                                    color: modelData // Match swatch color

                                    Icon {
                                        source: "../icons/check.svg"
                                        anchors.centerIn: parent
                                        width: parent.width * 0.75
                                        height: parent.height * 0.75
                                        color: "white" // Checkmark color
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    newNotePage.noteColor = modelData; // Set new note color
                                    newNotePage.noteModified = true;
                                    colorSelectionPanel.opacity = 0; // Close panel
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ScrollBar {
        flickableSource: mainContentFlickable
        topAnchorItem: header
    }

    // --- Overlay Rectangle for Tag Picker (Darkens background) ---
    Rectangle {
        id: tagOverlayRect
        anchors.fill: parent // Fills the entire parent area
        color: "#000000" // Black color
        // Visibility and opacity are linked to the 'tagSelectionPanel.opacity' state
        visible: tagSelectionPanel.opacity > 0.01 // Only visible when the tag picker is active
        opacity: tagSelectionPanel.opacity * 0.4 // Fades in and out
        z: 11.5 // Z-order to appear above other elements but below the picker itself

        // MouseArea to detect clicks on the overlay
        MouseArea {
            anchors.fill: parent
            enabled: tagOverlayRect.visible // Only enabled when visible
            onClicked: {
                // If the tag picker is open, clicking the overlay closes it.
                if (tagSelectionPanel.opacity > 0.01) {
                    tagSelectionPanel.opacity = 0;
                    console.log("Tag picker closed by clicking overlay.");
                }
            }
        }
    }

    // --- Main Tag Selection Panel ---
    // This is the core panel where tags are displayed and managed.
    Rectangle {
        id: tagSelectionPanel
        width: parent.width // Panel width matches parent
        height: parent.height * 0.53 // Fixed height as per the desired layout
        color: newNotePage.darkenColor(newNotePage.noteColor, 0.15) // Darker version of note color
        radius: 15 // Rounded corners
        anchors.horizontalCenter: parent.horizontalCenter // Centers horizontally
        anchors.bottom: bottomToolbar.bottom // Anchors to the bottom of the parent (above keyboard)
        z: 12 // Z-order to appear above the overlay
        opacity: 0 // Initial opacity (hidden)
        visible: opacity > 0.01 // Ensures visibility for animation and content loading

        // Behavior for smooth opacity transitions
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Action to perform when the panel's visibility changes
        onVisibleChanged: {
            if (visible) {
                // When the panel becomes visible, load tags and scroll to the top of the list.
                loadTagsForTagPanel();
                tagsPanelFlickable.contentY = 0; // Scroll to top
                console.log("Tag selection panel opened. Loading tags and scrolling to top.");
            }
        }

        // List model to hold available tags and their checked state
        ListModel {
            id: availableTagsModel
        }

        // Function to load tags into the ListModel for the current note
        function loadTagsForTagPanel() {
            availableTagsModel.clear(); // Clear existing items
            var allTags = DB.getAllTags(); // Get all available tags from the database (assuming DB is globally accessible)

            var noteSpecificTags = [];
            if (newNotePage.noteId !== -1) {
                // If it's an existing note, load tags from DB
                noteSpecificTags = DB.getTagsForNote(null, newNotePage.noteId);
            } else {
                // If it's a new note, use the local noteTags property
                noteSpecificTags = newNotePage.noteTags;
            }

            var selectedTags = [];
            var unselectedTags = [];

            // Populate separate arrays for selected and unselected tags
            for (var i = 0; i < allTags.length; i++) {
                var tagName = allTags[i];
                var isChecked = noteSpecificTags.indexOf(tagName) !== -1;
                if (isChecked) {
                    selectedTags.push({ name: tagName, isChecked: true });
                } else {
                    unselectedTags.push({ name: tagName, isChecked: false });
                }
            }

            // Append selected tags first, then unselected tags, to the model
            for (var i = 0; i < selectedTags.length; i++) {
                availableTagsModel.append(selectedTags[i]);
            }
            for (var i = 0; i < unselectedTags.length; i++) {
                availableTagsModel.append(unselectedTags[i]);
            }

            console.log("TagSelectionPanel: Loaded tags for display in panel. Model items:", availableTagsModel.count);
        }

        // Column layout for header, flickable content, and done button
        Column {
            id: tagPanelContentColumn
            anchors.fill: parent
            spacing: Theme.paddingMedium // Spacing between items in the column

            // --- Header Section for Tag Panel ---
            Rectangle {
                id: tagPanelHeader
                width: parent.width
                height: Theme.itemSizeExtraSmall // Standard header height
                // Color now dynamically darkened version of note's color
                color: newNotePage.darkenColor(newNotePage.noteColor, 0.15) // Darker version of note color
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.leftMargin: Theme.paddingLarge // Horizontal padding for content within header
                anchors.rightMargin: Theme.paddingLarge

                // Label for the header text "Select Tags"
                Label {
                    id: selectTagsText
                    text: "Select Tags"
                    font.pixelSize: Theme.fontSizeLarge
                    color: "#e8eaed" // Light text color
                    anchors.centerIn: parent
                }
            }

            // --- Flickable Area for Tag List ---
            // Allows scrolling if the list of tags exceeds the panel height.
            SilicaFlickable {
                id: tagsPanelFlickable
                width: parent.width
                anchors.top: tagPanelHeader.bottom // Anchored below the header
                anchors.bottom: doneButton.top // Anchored above the Done button
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Theme.paddingMedium // Space from header
                anchors.bottomMargin: Theme.paddingMedium // Space from done button
                contentHeight: tagsPanelListView.contentHeight // Content height dynamically set by ListView
                clip: true // Clips content that overflows

                // --- List View for Individual Tags ---
                ListView {
                    id: tagsPanelListView
                    width: parent.width
                    height: contentHeight // Height adapts to content
                    model: availableTagsModel // Uses the ListModel defined above
                    orientation: ListView.Vertical // Vertical scrolling
                    spacing: Theme.paddingSmall // Spacing between list items

                    // Delegate defines how each item in the ListView looks and behaves
                    delegate: Rectangle { // Using Rectangle for delegate as per the desired style
                        id: tagPanelDelegateRoot
                        width: parent.width
                        height: Theme.itemSizeMedium // Standard item height
                        clip: true
                        // Dynamic background color based on checked state
                        // Selected tag uses the note's color, unselected uses a standard darker shade
                        color: model.isChecked ? newNotePage.noteColor : "#2a2c3a" // New styling colors

                        // Ripple effect for visual feedback on touch/click
                        RippleEffect { id: tagPanelDelegateRipple }

                        // MouseArea for handling clicks on each tag item
                        MouseArea {
                            anchors.fill: parent
                            onPressed: tagPanelDelegateRipple.ripple(mouseX, mouseY) // Trigger ripple on press
                            onClicked: {
                                var newCheckedState = !model.isChecked; // Toggle checked state

                                // Update the model for immediate UI reflection
                                availableTagsModel.set(index, { name: model.name, isChecked: newCheckedState });

                                // Logic to update noteTags (either locally for new note or via DB for existing)
                                if (newNotePage.noteId === -1) {
                                    // For new notes, explicitly assign a new array instance to trigger UI update
                                    var currentTags = newNotePage.noteTags;
                                    if (newCheckedState) {
                                        if (currentTags.indexOf(model.name) === -1) {
                                            newNotePage.noteTags = currentTags.concat([model.name]);
                                        }
                                    } else {
                                        newNotePage.noteTags = currentTags.filter(function(tag) { return tag !== model.name; });
                                    }
                                    console.log("New note's tags updated directly (new instance assigned):", JSON.stringify(newNotePage.noteTags));
                                } else {
                                    // For existing notes, update the database
                                    if (newCheckedState) {
                                        DB.addTagToNote(newNotePage.noteId, model.name);
                                        console.log("Added tag '" + model.name + "' to note ID " + newNotePage.noteId);
                                    } else {
                                        DB.deleteTagFromNote(newNotePage.noteId, model.name);
                                        console.log("Removed tag '" + model.name + "' from note ID " + newNotePage.noteId);
                                    }
                                    // Re-fetch the tags to ensure the local array is in sync with the DB
                                    newNotePage.noteTags = DB.getTagsForNote(null, newNotePage.noteId);
                                    console.log("NewNotePage: main tagsFlow updated after DB change:", JSON.stringify(newNotePage.noteTags));
                                }
                                newNotePage.noteModified = true; // Mark note as modified
                            }
                        }

                        // Row layout for icon, tag name, and checkbox
                        Row {
                            id: tagPanelRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge // Left padding
                            anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge // Right padding
                            spacing: Theme.paddingMedium // Spacing between elements in the row

                            // Tag icon
                            Icon {
                                id: tagPanelTagIcon
                                source: "../icons/tag-white.svg" // Path to tag icon
                                color: "#e2e3e8" // Icon color
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                            }

                            // Label for the tag name
                            Label {
                                id: tagPanelTagNameLabel
                                text: model.name // Display tag name from model
                                color: "#e2e3e8" // Text color
                                font.pixelSize: Theme.fontSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight // Elide long text with "..."
                                // Flexible width, positioned between icon and checkbox
                                anchors.left: tagPanelTagIcon.right
                                anchors.leftMargin: tagPanelRow.spacing
                                anchors.right: tagPanelCheckButtonContainer.left
                                anchors.rightMargin: tagPanelRow.spacing
                            }

                            // Container for the checkbox icon
                            Item {
                                id: tagPanelCheckButtonContainer
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right // Anchored to the far right of the row
                                clip: false

                                // Checkbox icon (changes based on model.isChecked)
                                Image {
                                    id: tagPanelCheckIcon
                                    source: model.isChecked ? "../icons/box-checked.svg" : "../icons/box.svg" // Checked or unchecked box icon
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
            // Scrollbar for the flickable area
            ScrollBar {
                flickableSource: tagsPanelFlickable
                anchors.top: tagsPanelFlickable.top
                anchors.bottom: tagsPanelFlickable.bottom
                anchors.right: parent.right
                width: Theme.paddingSmall
            }

            // --- Done Button for Tag Panel ---
            Button {
                id: doneButton
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Done") // Localized text for the button
                onClicked: {
                    tagSelectionPanel.opacity = 0; // Close the tag picker when Done is clicked
                    console.log("Tag picker closed by Done button.");
                }
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge // Space from the bottom of the panel
            }
        }
    }
}

// NoteCard.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root
    width: parent ? parent.width : 360
    height: cardColumn.implicitHeight + Theme.paddingLarge * 2 + 20 // Adjusted bottom margin

    property string title: ""
    property string content: ""
    property var tags: [] // This property receives a string like "tag1 tag2" or ""
    property string cardColor: "#1c1d29" // ADDED: New property for card background color, default to a neutral grey

    // --- NEW PROPERTIES FOR SELECTION AND NAVIGATION DATA ---
    property int noteId: -1 // To identify the note for selection
    property bool isSelected: false // Controls the visual selection state
    property var mainPageInstance: null // Reference to mainPage to call its selection functions
    property bool noteIsPinned: false // Pass the pinned state from modelData
    property date noteCreationDate: new Date() // Pass creation date from modelData
    property date noteEditDate: new Date() // Pass edit date from modelData

    // Debugging: Log when isSelected changes
    onIsSelectedChanged: {
        console.log("NoteCard ID:", root.noteId, "isSelected changed to:", root.isSelected, "Border width:", root.isSelected ? 8 : 2);
    }

    // --- NEW PROPERTIES FOR CUSTOM LONG PRESS DETECTION ---
    property bool pressActive: false // Tracks if a mouse press is currently active
    property int pressX: 0 // Stores initial press X coordinate
    property int pressY: 0 // Stores initial press Y coordinate

    // Timer for detecting a long press
    Timer {
        id: longPressTimer
        interval: 500 // 500ms for a long press
        running: false
        repeat: false
        onTriggered: {
            console.log("Long press detected for note ID:", root.noteId);
            // If a long press is detected, activate selection mode and toggle this note's selection
            if (root.mainPageInstance) {
                if (!root.mainPageInstance.selectionMode) {
                    root.mainPageInstance.selectionMode = true;
                }
                root.mainPageInstance.toggleNoteSelection(root.noteId);
            }
            // Crucially, prevent the onReleased event from also triggering onClicked
            mouseArea.mouse.accepted = false; // Corrected: Use mouse.accepted
            root.pressActive = false; // Reset press active state immediately after long press
            root.scale = 1.0; // Reset scale after long press
        }
    }

    // Add scale property to the root Item for animation
    scale: 1.0 // Initial scale

    // Behavior for smooth scale animation
    Behavior on scale {
        NumberAnimation {
            duration: 100 // Quick snap to highlighted state
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        anchors.fill: parent
        // MODIFIED: Use cardColor for the background
        color: root.cardColor // Use the new property for background color
        radius: 20
        border.color: root.isSelected ? "white" : "#43484e" // White border if selected, otherwise original border
        // FIXED: Hardcoded border width to ensure visibility and rule out TypeError from Theme.borderWidthLarge
        border.width: root.isSelected ? 4 : 2 // Increased selected width significantly for immediate visibility
        anchors.bottomMargin: 20 // This margin affects the root Item's height
        Column {
            id: cardColumn
            anchors {
                left: parent.left; leftMargin: Theme.paddingLarge
                right: parent.right; rightMargin: Theme.paddingLarge
                top: parent.top; topMargin: Theme.paddingLarge
                bottom: parent.bottom; bottomMargin: Theme.paddingLarge
            }
            spacing: Theme.paddingSmall

            // Title
            Text {
                id: titleText
                text: (root.title && root.title.trim()) ? root.title : "Empty"
                font.italic: !(root.title && root.title.trim())
                textFormat: Text.PlainText
                color: "#e8eaed"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                wrapMode: Text.Wrap
                width: parent.width
            }
            Rectangle {
                width: parent.width
                height: 8
                color: "transparent"
            }
            // Content (max 5 lines with ellipsis)
            Text {
                id: contentText
                text: (root.content && root.content.trim()) ? root.content : "Empty"
                font.italic: !(root.content && root.content.trim())
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                maximumLineCount: 5
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: "#c5c8d0"
                width: parent.width
            }
            Rectangle {
                width: parent.width
                height: 4
                color: "transparent"
            }
            // Tags
            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingSmall
                visible: tags.trim().length > 0

                Repeater {
                    model: tags.split(" ")
                    delegate: Rectangle {
                        visible: index < 2
                        color: "#a032353a"
                        radius: 12
                        height: tagText.implicitHeight + Theme.paddingSmall
                        width: Math.min(tagText.implicitWidth + Theme.paddingMedium, parent.width)

                        Text {
                            id: tagText
                            text: modelData
                            color: "#c5c8d0"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            elide: Text.ElideRight
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width - Theme.paddingMedium
                            wrapMode: Text.NoWrap
                            textFormat: Text.PlainText
                        }
                    }
                }

                Rectangle {
                    visible: tags.split(" ").length > 2
                    color: "#a032353a"
                    radius: 12
                    height: tagCount.implicitHeight + Theme.paddingSmall
                    width: tagCount.implicitWidth + Theme.paddingMedium

                    Text {
                        id: tagCount
                        text: "+" + (tags.split(" ").length - 2)
                        color: "#c5c8d0"
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.NoWrap
                    }
                }
            }
        }
    }
    // MouseArea for interaction (selection and opening note)
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPressed: {
            longPressTimer.start(); // Start the long press timer
            root.pressActive = true; // Mark press as active
            root.pressX = mouse.x; // Record initial press position
            root.pressY = mouse.y;
            mouse.accepted = true; // Explicitly accept the press event
            root.scale = 0.97; // Scale down slightly on press
        }
        onReleased: {
            root.scale = 1.0; // Reset scale on release
            if (longPressTimer.running) {
                longPressTimer.stop(); // Stop timer if released before long press trigger
                if (root.pressActive) { // Ensure it wasn't a drag or canceled
                    // This is a regular click
                    if (root.mainPageInstance && root.mainPageInstance.selectionMode) {
                        // If in selection mode, toggle selection
                        root.mainPageInstance.toggleNoteSelection(root.noteId);

                    } else {
                        // Otherwise, navigate to the NotePage for editing
                        pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                            onNoteSavedOrDeleted: root.mainPageInstance ? root.mainPageInstance.refreshData : null, // Pass refreshData callback
                            noteId: root.noteId,
                            noteTitle: root.title,
                            noteContent: root.content, // Corrected: Use root.content
                            noteIsPinned: root.noteIsPinned, // Corrected: Use root.noteIsPinned
                            noteTags: root.tags, // Corrected: Use root.tags
                            noteCreationDate: root.noteCreationDate, // Corrected: Use root.noteCreationDate
                            noteEditDate: root.noteEditDate, // Corrected: Use root.noteEditDate
                            noteColor: root.cardColor

                        });
                        console.log("Opening NotePage in EDIT mode for ID:", root.noteId, "from NoteCard. Color:", root.cardColor);
                        Qt.inputMethod.hide(); // Hide keyboard
                        // Added check for existence of searchField on mainPageInstance
                        if (root.mainPageInstance && typeof root.mainPageInstance.searchField !== 'undefined') {
                           root.mainPageInstance.searchField.focus = false; // Clear search field focus
                        }
                    }
                }
            }
            root.pressActive = false; // Reset press active state
        }
        onCanceled: {
            longPressTimer.stop(); // Stop timer if press is canceled (e.g., finger slides off)
            root.pressActive = false;
            root.scale = 1.0; // Reset scale on cancel
        }
        onPositionChanged: {
            // If the mouse moves significantly, stop the long press timer (treat as a drag, not a press)
            var threshold = 10; // Pixels
            if (root.pressActive && (Math.abs(mouse.x - root.pressX) > threshold || Math.abs(mouse.y - root.pressY) > threshold)) {
                longPressTimer.stop();
                root.pressActive = false;
                root.scale = 1.0; // Reset scale if it's a drag
            }
        }
    }
}

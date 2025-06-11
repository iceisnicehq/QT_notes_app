// NotePage.qml
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
    property var noteTags: []
    property bool noteIsPinned: false
    property date noteCreationDate: new Date()
    property date noteEditDate: new Date()
    property string noteColor: "#121218"
    property bool noteModified: false // New property to track if content was changed

    readonly property var colorPalette: [
        "#121218", // Dark Grey (default)
        "#1c1d29", // Slightly Lighter Dark Grey
        "#3a2c2c", // Dark Red
        "#2c3a2c", // Dark Green
        "#2c2c3a", // Dark Blue
        "#3a3a2c", // Dark Yellow
        "#43484e", // Border color from NoteCard, nice neutral option
        "#5c4b37", // A warmer tone
        "#3e4a52", // A cooler, muted blue
        "#503232", // Another muted red
        "#325032", // Another muted green
        "#323250"  // Another muted blue
    ]

    Component.onCompleted: {
        console.log("NewNotePage opened.");

        if (noteId !== -1) {
            noteTitleInput.text = noteTitle;
            noteContentInput.text = noteContent;
            console.log("NewNotePage opened in EDIT mode for ID:", noteId);
            console.log("Note color on open:", noteColor);
            noteModified = false; // Reset modification flag when opening existing note
        } else {
            noteContentInput.forceActiveFocus();
            Qt.inputMethod.show();
            console.log("NewNotePage opened in CREATE mode. Default color:", noteColor);
            noteModified = true; // New notes are considered modified from the start for saving
        }
    }

    Component.onDestruction: {
        console.log("NewNotePage being destroyed. Attempting to save/delete note.");

        var trimmedTitle = noteTitleInput.text.trim(); // Use current input text
        var trimmedContent = noteContentInput.text.trim(); // Use current input text

        if (trimmedTitle === "" && trimmedContent === "") {
            // Note is empty
            if (noteId !== -1) {
                // It's an existing note that became empty, so delete it
                DB.deleteNote(noteId);
                console.log("Debug: Empty existing note deleted with ID:", noteId);
            } else {
                // It's a new empty note, so do nothing (don't save)
                console.log("Debug: New empty note not saved.");
            }
        } else {
            // Note has content
            if (noteId === -1) {
                // It's a new note with content, always add it
                newNotePage.noteTitle = noteTitleInput.text;
                newNotePage.noteContent = noteContentInput.text;
                var newId = DB.addNote(noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                console.log("Debug: New note added with ID:", newId + ", Color: " + noteColor);
            } else {
                // It's an existing note with content, only update if modified
                if (noteModified) {
                    newNotePage.noteTitle = noteTitleInput.text;
                    newNotePage.noteContent = noteContentInput.text;
                    newNotePage.noteEditDate = new Date(); // Update edit date only if content changed
                    DB.updateNote(noteId, noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                    console.log("Debug: Note updated with ID:", noteId + ", Color: " + noteColor);
                } else {
                    console.log("Debug: Note with ID:", noteId, " not modified, skipping update.");
                }
            }
        }

        if (onNoteSavedOrDeleted) {
            onNoteSavedOrDeleted();
        }
    }

    ToastManager {
        id: toastManager
    }

    // Custom Page Header
    Rectangle {
        id: header
        width: parent.width
        height: Theme.itemSizeMedium
        color: newNotePage.noteColor // Цвет хедера привязан к noteColor
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
                visible: newNotePage.noteId !== -1
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
        Item {
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 1.1
            clip: false
            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
            RippleEffect { id: backRipple }
            Icon {
                id: closeButton
                source: newNotePage.noteId === -1 ?  "../icons/check.svg" :  "../icons/back.svg"
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
                    noteIsPinned = !noteIsPinned;
                    newNotePage.noteModified = true; // Set flag when pin state changes
                    var msg = noteIsPinned ? "The note was pinned" : "The note was unpinned"
                    toastManager.show(msg)
                }
            }
        }
    }

    // Нижний тулбар (всегда на дне)
    Rectangle {
        id: bottomToolbar
        width: parent.width
        height: Theme.itemSizeSmall
        // Используем привязку к нижней части родителя и корректируем позицию, если клавиатура видна.
        // Это более надежно, чем динамическое изменение y.
        anchors.bottom: parent.bottom
        color: newNotePage.noteColor
        z: 10 // Важно: панель выбора цвета будет иметь z: 11, чтобы быть выше тулбара

        // Перемещаем логику поднятия тулбара при появлении клавиатуры сюда.
        // Привязываем нижнюю границу тулбара к верхней границе клавиатуры.
        // Если клавиатура не видна, bottomToolbar.y будет равен parent.height - height
        // (то есть, находиться внизу экрана).
        // Если клавиатура видна, bottomToolbar.y будет равен Qt.inputMethod.keyboardRectangle.y - height.
        y: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.y - height) : (parent.height - height)

        Behavior on y {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic } // Плавная анимация
        }

        Row {
            id: leftToolbarButtons
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            // Palette Button
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
                        Qt.inputMethod.hide(); // Hide keyboard first

                        // Toggle panel opacity for fade in/out
                        if (colorSelectionPanel.opacity > 0.01) { // If panel is currently visible or fading in
                            colorSelectionPanel.opacity = 0; // Start fade out
                        } else {
                            colorSelectionPanel.opacity = 1; // Start fade in
                        }
                    }
                }
            }

            // Text Edit Button (Placeholder for now, or might be removed if replaced by new buttons)
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
                        // Add actual undo logic here
                        toastManager.show("Undo action triggered!");
                    }
                }
            }

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
                        // Add actual redo logic here
                        toastManager.show("Redo action triggered!");
                    }
                }
            }

            // New "Add Tag" Button
            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                RippleEffect { id: addTagRipple }
                Icon {
                    id: addTagIcon
                    source: "../icons/tag.svg" // Using tag.svg as requested
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: addTagRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        console.log("Add Tag button clicked.");
                        // Push to TagEditPage, passing current noteId and a callback
                        pageStack.push(Qt.resolvedUrl("TagEditPage.qml"), {
                            noteId: newNotePage.noteId,
                            onTagsChanged: function() {
                                // This function will be called from TagEditPage when tags are updated
                                // For now, we'll just mark the note as modified
                                newNotePage.noteModified = true;
                                // In a more complex app, you might re-fetch noteTags here from DB
                                // For this example, we assume `mainPage.refreshData` will handle full reload
                            }
                        });
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
                        // Add archive logic here, e.g., setting a flag in DB
                        pageStack.pop();
                    }
                }
            }

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
                        console.log("Delete Note");
                        toastManager.show("Note deleted!");

                        if (newNotePage.noteId !== -1) {
                            DB.deleteNote(newNotePage.noteId);
                            console.log("Note deleted with ID:", newNotePage.noteId);
                            if (onNoteSavedOrDeleted) {
                                onNoteSavedOrDeleted();
                            }
                        }
                        pageStack.pop();
                    }
                }
            }
        }
    }

    // --- Flickable Content Area ---
    SilicaFlickable {
        id: mainContentFlickable
        anchors.fill: parent
        anchors.topMargin: header.height
        // ИСПРАВЛЕНИЕ: Нижний отступ теперь динамически вычисляется:
        // он равен высоте тулбара, когда клавиатуры нет,
        // и равен высоте тулбара + высоте клавиатуры, когда клавиатура видна.
        // Это гарантирует, что тулбар не будет перекрывать контент и не будет пробелов.
        anchors.bottomMargin: bottomToolbar.height + (Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0)
        contentHeight: contentColumn.implicitHeight

        // Плавная анимация для нижнего отступа
        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Column {
            id: contentColumn
            width: parent.width - Theme.horizontalPageMargin * 2 // Добавил отступы по горизонтали
            anchors.horizontalCenter: parent.horizontalCenter // Центрируем колонку

            TextField {
                id: noteTitleInput
                width: parent.width
                placeholderText: "Title"
                text: newNotePage.noteTitle
                onTextChanged: {
                    newNotePage.noteTitle = text;
                    newNotePage.noteModified = true; // Set flag on change
                }
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
                font.bold: true
                wrapMode: Text.Wrap
                inputMethodHints: Qt.ImhNoAutoUppercase
            }

            TextArea {
                id: noteContentInput
                width: parent.width
                height: implicitHeight > 0 ? implicitHeight : Theme.itemSizeExtraLarge * 3
                placeholderText: "Note"
                text: newNotePage.noteContent
                onTextChanged: {
                    newNotePage.noteContent = text;
                    newNotePage.noteModified = true; // Set flag on change
                }
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                color: "#e8eaed"
                verticalAlignment: Text.AlignTop
            }

            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingMedium
                visible: newNotePage.noteTags.length > 0 // Only visible if there are tags

                Repeater {
                    model: newNotePage.noteTags
                    delegate: Rectangle {
                        id: tagRectangle
                        property color normalColor: "#32353a"
                        property color pressedColor: "#50545a"
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
                            }
                            onCanceled: tagRectangle.color = tagRectangle.normalColor
                        }
                    }
                }

            }

        }
        // "No tags" message
        Label {
            id: noTagsLabel
            text: "<i>No tags</i>" // Italic text
            visible: newNotePage.noteTags.length === 0 // Visible only if no tags
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: contentColumn.bottom // Position below the flow area
        }
        Item { width: parent.width; height: Theme.paddingLarge * 2 }
    }

    // Overlay for Panel Background
    // This Rectangle creates a semi-transparent dark overlay over the main page content
    // when the color selection panel is active. Its visibility and opacity are directly
    // tied to the panel's opacity to create a coordinated fade effect. Clicking this
    // overlay will close the color panel.
    Rectangle {
        id: overlayRect
        anchors.fill: parent // Covers the entire page
        color: "#000000" // Pure black color
        // Visible only when the colorSelectionPanel is animating or fully opaque
        visible: colorSelectionPanel.opacity > 0.01
        // Opacity scales with the colorSelectionPanel's opacity, up to a max of 40%
        opacity: colorSelectionPanel.opacity * 0.4

        z: 10.5 // Positioned above main content but below the color selection panel

        // No Behavior on opacity needed here as it directly reflects colorSelectionPanel's opacity

        MouseArea {
            anchors.fill: parent
            // Enable mouse area only when the overlay is visually present
            enabled: overlayRect.visible
            onClicked: {
                // If the color selection panel is visible (or fading in), fade it out
                if (colorSelectionPanel.opacity > 0.01) {
                    colorSelectionPanel.opacity = 0;
                }
            }
        }
    }

    // Color Selection Panel
    // This Rectangle defines the color selection palette that slides up from the bottom.
    // It is now statically positioned at the bottom, and its appearance/disappearance
    // is controlled purely by its opacity property, allowing for a smooth fade effect.
    // It uses an inner Rectangle with clipping to achieve rounded top corners and sharp bottom edges.
    Rectangle {
        id: colorSelectionPanel
        width: parent.width
        // Define radius here for consistent use
        property real panelRadius: Theme.itemSizeSmall / 2

        // The visible height of the panel (this rectangle will act as a clipping mask)
        // It should be the content height plus the radius for the top curve
        height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + panelRadius

        anchors.horizontalCenter: parent.horizontalCenter
        // Fixed position at the bottom of the screen
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0 // Keep it snapped to the very bottom

        z: 11 // Always on top of other elements when active

        // Initial state: completely transparent and not visible
        opacity: 0
        visible: opacity > 0.01 // Only visible when fading in or fully opaque

        color: "transparent" // The clipping parent should be transparent
        clip: true // Crucial: clips anything outside this rectangle's bounds

        // Animation for opacity changes (fade in/out)
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // This inner rectangle holds the actual content and applies the rounding.
        // Its height is extended by 2*radius, and its y-position is 0,
        // so its bottom rounded part extends beyond the clipping parent and is hidden.
        Rectangle {
            id: colorPanelVisualBody
            width: parent.width
            // Height needs to be the content height + 2 * radius (for top and bottom curves)
            height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + 2 * colorSelectionPanel.panelRadius
            color: newNotePage.noteColor // This takes the dynamic color
            radius: colorSelectionPanel.panelRadius // Apply radius to all corners of this inner rectangle

            // Position this inner rectangle at y=0, so its top aligns with the clipping parent's top.
            // The bottom part will then extend below the clipping parent and be hidden.
            y: 0

            Column {
                id: colorPanelContentColumn // Renamed for clarity, was colorPanelContent
                width: parent.width
                height: implicitHeight // Let column determine its height
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: colorSelectionPanel.panelRadius // Add margin equal to radius for content clearance
                anchors.bottomMargin: Theme.paddingMedium // Ensure consistent padding for content
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
                    width: parent.width // Use the full width of the parent column
                    spacing: Theme.paddingSmall // Space between color circles
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: Qt.LeftToRight

                    // Determine the number of columns for the color grid
                    readonly property int columns: 6
                    // Calculate item width based on available width, desired columns, and spacing
                    readonly property real itemWidth: (parent.width - (spacing * (columns - 1))) / columns

                    Repeater {
                        model: newNotePage.colorPalette
                        delegate: Item {
                            width: parent.itemWidth // Use calculated itemWidth from Flow
                            height: parent.itemWidth // Make it square

                            // Outer circle (white for selected, grey for others)
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2 // Make it round
                                color: (newNotePage.noteColor === modelData) ? "white" : "#707070" // White if selected, grey otherwise
                                border.color: "transparent" // No border on the outer circle
                            }

                            // Inner circle (the actual color swatch)
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.95 // Made inner circle larger to create a thinner outer ring
                                height: parent.height * 0.95 // Made inner circle larger to create a thinner outer ring
                                radius: width / 2
                                color: modelData // The actual color from the palette
                                border.color: "transparent" // No border on the color swatch itself

                                // Checkmark for selected color (inside the color swatch)
                                Rectangle {
                                    visible: newNotePage.noteColor === modelData
                                    anchors.centerIn: parent
                                    width: parent.width * 0.7 // Size of checkmark background
                                    height: parent.height * 0.7
                                    radius: width / 2
                                    color: modelData // Use the color itself for the checkmark background

                                    Icon {
                                        source: "../icons/check.svg"
                                        anchors.centerIn: parent
                                        width: parent.width * 0.75
                                        height: parent.height * 0.75
                                        color: "white" // White checkmark
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    newNotePage.noteColor = modelData;
                                    newNotePage.noteModified = true; // Set flag on color change!
                                    colorSelectionPanel.opacity = 0; // Hide the panel after selection
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
}

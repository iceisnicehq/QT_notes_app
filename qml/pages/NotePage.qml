// NotePage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

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
            Qt.inputMethod.show(); // Показываем клавиатуру при первом открытии
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
         height: Theme.itemSizeMedium
         color: "#121218"
         anchors.top: parent.top
         z: 2

         Column {
             anchors.centerIn: parent
             //spacing: Theme.paddingExtraSmall

             Label {
                 text: newNotePage.noteId === -1 ? "New Note" : "Edit Note"
                 anchors.horizontalCenter: parent.horizontalCenter
                 font.pixelSize: Theme.fontSizeLarge
                 color: "#e8eaed"
             }

             // Created and Edited Dates - visible only for existing notes
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
             clip: false  // Important: do not clip!
             anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
             RippleEffect {
                 id: backRipple
             }
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
                     noteContentInput.forceActiveFocus(); // Return focus to TextArea
                     Qt.inputMethod.show(); // Убеждаемся, что клавиатура показывается
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
                verticalAlignment: Text.AlignTop // По умолчанию: Text.AlignLeft
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
                            textFormat: Text.PlainText
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
        height: Theme.itemSizeSmall // Made toolbar thinner
        anchors.bottom: parent.bottom
        color: "#1c261d" // Semi-transparent for overlay effect
        z: 10 // Ensure it's above the main flickable and other content

        // Left group: Palette, Text Edit, Alignment, Undo/Redo
        Row {
            id: leftToolbarButtons
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.paddingLarge // Matches your search bar's left padding
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
                        console.log("Change color/theme");
                        toastManager.show("Change color/theme clicked!");
                        noteContentInput.forceActiveFocus(); // Return focus to TextArea
                        Qt.inputMethod.show(); // Показываем клавиатуру
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
                        noteContentInput.forceActiveFocus(); // Return focus to TextArea
                        Qt.inputMethod.show(); // Показываем клавиатуру
                    }
                }
            }

            // --- Кнопки выравнивания текста ---
            // Кнопка для выравнивания по левому краю
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
                        noteContentInput.forceActiveFocus(); // ВОЗВРАЩАЕМ ФОКУС
                        Qt.inputMethod.show(); // Показываем клавиатуру
                    }
                }
            }

            // Кнопка для выравнивания по центру
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
                        noteContentInput.forceActiveFocus(); // ВОЗВРАЩАЕМ ФОКУС
                        Qt.inputMethod.show(); // Показываем клавиатуру
                    }
                }
            }

            // Кнопка для выравнивания по правому краю
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
                        noteContentInput.forceActiveFocus(); // ВОЗВРАЩАЕМ ФОКУС
                        Qt.inputMethod.show(); // Показываем клавиатуру
                    }
                }
            }

            // Кнопка для выравнивания по ширине
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
                        noteContentInput.forceActiveFocus(); // ВОЗВРАЩАЕМ ФОКУС
                        Qt.inputMethod.show(); // Показываем клавиатуру
                    }
                }
            }
            // --- КОНЕЦ КНОПОК ВЫРАВНИВАНИЯ ---

            // --- Undo и Redo кнопки ---
            // Undo Button
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
                        toastManager.show("Undo action triggered!"); // Пока оставим уведомление для отмены
                        noteContentInput.forceActiveFocus(); // Return focus to TextArea
                        Qt.inputMethod.show(); // Показываем клавиатуру
                    }
                }
            }

            // Redo Button
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
                        toastManager.show("Redo action triggered!"); // Пока оставим уведомление для повтора
                        noteContentInput.forceActiveFocus(); // Return focus to TextArea
                        Qt.inputMethod.show(); // Показываем клавиатуру
                    }
                }
            }
            // --- КОНЕЦ Undo и Redo кнопок ---
        }

        // Right group: Archive and Delete
        Row {
            id: rightToolbarButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.paddingLarge // Matches your search bar's right padding
            spacing: Theme.paddingMedium

            // Archive Button
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
                        // Implement archive logic here if needed
                        pageStack.pop();
                    }
                }
            }

            // Delete Button
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
                        pageStack.pop(); // Pop the page after deletion
                    }
                }
            }
        }
    }
    ScrollBar {
        flickableSource: mainContentFlickable // Pass the ID of your SilicaFlickable
        topAnchorItem: header // Pass the ID of your header/search bar Item
    }
}

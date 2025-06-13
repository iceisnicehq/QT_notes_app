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
    property bool noteModified: false

    // Добавим свойство для отслеживания, была ли заметка "отправлена в корзину" с этой страницы
    property bool sentToTrash: false

    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]

    Component.onCompleted: {
        console.log("NewNotePage opened.");
        if (noteId !== -1) {
            noteTitleInput.text = noteTitle;
            noteContentInput.text = noteContent;
            console.log("NewNotePage opened in EDIT mode for ID:", noteId);
            console.log("Note color on open:", noteColor);
            noteModified = false;
        } else {
            noteContentInput.forceActiveFocus();
            Qt.inputMethod.show();
            console.log("NewNotePage opened in CREATE mode. Default color:", noteColor);
            noteModified = true;
        }
    }

    Component.onDestruction: {
        console.log("NewNotePage being destroyed. Attempting to save/delete note.");
        var trimmedTitle = noteTitleInput.text.trim();
        var trimmedContent = noteContentInput.text.trim();

        if (sentToTrash) {
            // Если заметка уже отправлена в корзину через кнопку, не делаем ничего при закрытии
            console.log("Debug: Note already sent to trash. Skipping save/delete on destruction.");
        } else if (trimmedTitle === "" && trimmedContent === "") {
            if (noteId !== -1) {
                // Если заметка была пустой и уже существовала, удаляем ее безвозвратно
                DB.permanentlyDeleteNote(noteId);
                console.log("Debug: Empty existing note permanently deleted with ID:", noteId);
            } else {
                console.log("Debug: New empty note not saved.");
            }
        } else {
            if (noteId === -1) {
                // Добавляем новую заметку
                newNotePage.noteTitle = noteTitleInput.text;
                newNotePage.noteContent = noteContentInput.text;
                var newId = DB.addNote(noteIsPinned, newNotePage.noteTitle, newNotePage.noteContent, noteTags, noteColor);
                console.log("Debug: New note added with ID:", newId + ", Color: " + noteColor);
            } else {
                // Обновляем существующую заметку
                if (noteModified) {
                    newNotePage.noteTitle = noteTitleInput.text;
                    newNotePage.noteContent = noteContentInput.text;
                    newNotePage.noteEditDate = new Date();
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

    Rectangle {
        id: header
        width: parent.width
        height: Theme.itemSizeMedium
        color: newNotePage.noteColor
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
                    newNotePage.noteModified = true;
                    var msg = noteIsPinned ? "The note was pinned" : "The note was unpinned"
                    toastManager.show(msg)
                }
            }
        }
    }

    Rectangle {
        id: bottomToolbar
        width: parent.width
        height: Theme.itemSizeSmall
        anchors.bottom: parent.bottom
        color: newNotePage.noteColor
        z: 10
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
                        if (colorSelectionPanel.opacity > 0.01) {
                            colorSelectionPanel.opacity = 0;
                        } else {
                            colorSelectionPanel.opacity = 1;
                        }
                    }
                }
            }
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
                        toastManager.show("Redo action triggered!");
                    }
                }
            }
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
                        Qt.inputMethod.hide();
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
                        // MODIFIED: Call DB.deleteNote which now moves to trash
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

    SilicaFlickable {
        id: mainContentFlickable
        anchors.fill: parent
        anchors.topMargin: header.height
        anchors.bottomMargin: bottomToolbar.height + (Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0)
        contentHeight: contentColumn.implicitHeight

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Column {
            id: contentColumn
            width: parent.width * 0.98
            anchors.horizontalCenter: parent.horizontalCenter

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

            Flow {
                id: tagsFlow
                width: parent.width
                spacing: Theme.paddingMedium
                visible: newNotePage.noteTags.length > 0

                Repeater {
                    model: newNotePage.noteTags
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

    Rectangle {
        id: colorSelectionPanel
        width: parent.width
        property real panelRadius: Theme.itemSizeSmall / 2
        height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + panelRadius
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomToolbar.top
        z: 11
        opacity: 0
        visible: opacity > 0.01
        color: "transparent"
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: colorPanelVisualBody
            width: parent.width
            height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + 2 * colorSelectionPanel.panelRadius
            color: newNotePage.noteColor
            radius: colorSelectionPanel.panelRadius
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
                                color: (newNotePage.noteColor === modelData) ? "white" : "#707070"
                                border.color: "transparent"
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.95
                                height: parent.height * 0.95
                                radius: width / 2
                                color: modelData
                                border.color: "transparent"

                                Rectangle {
                                    visible: newNotePage.noteColor === modelData
                                    anchors.centerIn: parent
                                    width: parent.width * 0.7
                                    height: parent.height * 0.7
                                    radius: width / 2
                                    color: modelData

                                    Icon {
                                        source: "../icons/check.svg"
                                        anchors.centerIn: parent
                                        width: parent.width * 0.75
                                        height: parent.height * 0.75
                                        color: "white"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    newNotePage.noteColor = modelData;
                                    newNotePage.noteModified = true;
                                    colorSelectionPanel.opacity = 0;
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

    Rectangle {
        id: tagOverlayRect
        anchors.fill: parent
        color: "#000000"
        visible: tagSelectionPanel.opacity > 0.01
        opacity: tagSelectionPanel.opacity * 0.4
        z: 11.5

        MouseArea {
            anchors.fill: parent
            enabled: tagOverlayRect.visible
            onClicked: {
                if (tagSelectionPanel.opacity > 0.01) {
                    tagSelectionPanel.opacity = 0;
                }
            }
        }
    }

    Rectangle {
        id: tagSelectionPanel
        width: parent.width
        height: parent.height * 0.5
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomToolbar.top
        z: 12
        opacity: 0
        visible: opacity > 0.01
        color: newNotePage.noteColor
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        onVisibleChanged: {
            if (visible) {
                if (newNotePage.noteId !== -1) {
                    loadTagsForTagPanel();
                } else {
                    loadTagsForTagPanel();
                }
            }
        }

        Rectangle {
            id: tagPanelHeader
            width: parent.width
            height: Theme.itemSizeMedium
            color: newNotePage.noteColor
            anchors.top: parent.top
            z: 1

            Label {
                text: "Select Tags"
                font.pixelSize: Theme.fontSizeLarge
                color: "#e8eaed"
                anchors.centerIn: parent
            }

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Theme.paddingLarge }
                RippleEffect { id: closeTagPanelRipple }
                Icon {
                    source: "../icons/check.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    color: "#e8eaed"
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: closeTagPanelRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        tagSelectionPanel.opacity = 0;
                        if (newNotePage.noteModified) {
                            console.log("Tags modified, ensuring note save on panel close.");
                        }
                    }
                }
            }
        }

        ListModel {
            id: availableTagsModel
        }

        function loadTagsForTagPanel() {
            availableTagsModel.clear();
            var allTags = DB.getAllTags();
            var noteSpecificTags = [];
            if (newNotePage.noteId !== -1) {
                noteSpecificTags = DB.getTagsForNote(null, newNotePage.noteId);
            } else {
                noteSpecificTags = newNotePage.noteTags;
            }

            for (var i = 0; i < allTags.length; i++) {
                var tagName = allTags[i];
                var isChecked = noteSpecificTags.indexOf(tagName) !== -1;
                availableTagsModel.append({
                    name: tagName,
                    isChecked: isChecked
                });
            }
            console.log("TagSelectionPanel: Loaded tags for display in panel. Model items:", availableTagsModel.count);
        }

        SilicaFlickable {
            id: tagsPanelFlickable
            width: parent.width
            anchors.top: tagPanelHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            contentHeight: tagsPanelListView.contentHeight

            ListView {
                id: tagsPanelListView
                width: parent.width
                height: contentHeight
                model: availableTagsModel
                orientation: ListView.Vertical
                spacing: Theme.paddingSmall

                delegate: BackgroundItem {
                    id: tagPanelDelegateRoot
                    width: parent.width
                    height: Theme.itemSizeMedium
                    clip: true

                    RippleEffect { id: tagPanelDelegateRipple }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: tagPanelDelegateRipple.ripple(mouseX, mouseY)
                        onClicked: {
                            var newCheckedState = !model.isChecked;
                            availableTagsModel.set(index, { name: model.name, isChecked: newCheckedState });

                            if (newNotePage.noteId === -1) {
                                // For new notes, modify the local noteTags array directly
                                if (newCheckedState) {
                                    if (newNotePage.noteTags.indexOf(model.name) === -1) {
                                        newNotePage.noteTags.push(model.name);
                                    }
                                } else {
                                    var idx = newNotePage.noteTags.indexOf(model.name);
                                    if (idx !== -1) {
                                        newNotePage.noteTags.splice(idx, 1);
                                    }
                                }
                                console.log("New note's tags updated directly:", JSON.stringify(newNotePage.noteTags));
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
                            newNotePage.noteModified = true;
                        }
                    }

                    Row {
                        id: tagPanelRow
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: Theme.paddingLarge
                        anchors.right: parent.right; anchors.rightMargin: Theme.paddingLarge
                        spacing: Theme.paddingMedium

                        Icon {
                            id: tagPanelTagIcon
                            source: "../icons/tag-white.svg"
                            color: "#e2e3e8"
                            width: Theme.iconSizeMedium
                            height: Theme.iconSizeMedium
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectFit
                        }

                        Label {
                            id: tagPanelTagNameLabel
                            text: model.name
                            color: "#e2e3e8"
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - tagPanelTagIcon.width - tagPanelCheckButtonContainer.width - (tagPanelRow.spacing * 2)
                        }

                        Item {
                            id: tagPanelCheckButtonContainer
                            width: Theme.iconSizeMedium
                            height: Theme.iconSizeMedium
                            anchors.verticalCenter: parent.verticalCenter
                            clip: false

                            Image {
                                id: tagPanelCheckIcon
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
        ScrollBar {
            flickableSource: tagsPanelFlickable
            anchors.top: tagsPanelFlickable.top
            anchors.bottom: tagsPanelFlickable.bottom
            anchors.right: parent.right
            width: Theme.paddingSmall
        }
    }
}

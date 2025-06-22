/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/pages/MainPage.qml
 * Это главная и наиболее сложная страница приложения. Она отображает списки
 * закрепленных и обычных заметок. Ключевой элемент — многофункциональный
 * заголовок, который служит строкой поиска и трансформируется в панель
 * массовых действий при переходе в режим выбора. Страница поддерживает
 * поиск по тексту, фильтрацию по тегам и различные виды сортировки.
 * На ней расположены плавающие кнопки для добавления заметки и вызова
 * диалога сортировки. Реализована сложная логика для управления
 * выбором заметок и выполнения массовых операций - надо зажать заметку
 * и тогда появится меню (закрепить, архивировать, удалить, изменить цвет).
 */

import QtQuick.LocalStorage 2.0
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import "../services/DatabaseManagerService.js" as DB
import "../dialogs"
import "../components"
import "../note_cards"
import "../services"

Page {
    id: mainPage
    objectName: "mainPage"
    allowedOrientations: Orientation.All
    backgroundColor: mainPage.customBackgroundColor
    property string customBackgroundColor: DB.getThemeColor() || "#121218"
    showNavigationIndicator: false
    property int noteMargin: 20
    property bool headerVisible: true
    property real previousContentY: 0
    property bool panelOpen: false
    property var allNotes: []
    property var allTags: []
    property var selectedTags: []
    property var currentSearchText: ""
    property var searchResults: []
    property bool tagPickerOpen: false
    property bool allVisibleNotesSelected: (selectedNoteIds.length === searchResults.length) && (searchResults.length > 0)
    property bool selectionMode: false
    property var selectedNoteIds: []
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: ""
    property string confirmDialogMessage: ""
    property string confirmButtonText: ""
    property color confirmButtonHighlightColor: Theme.primaryColor
    property var onConfirmCallback: null
    property string currentSortBy: "updated_at"
    property string currentSortOrder: "desc"
    property bool sortDialogVisible: false
    property bool colorSortDialogVisible: false
    property var customColorSortOrder: []
    property bool bulkColorPickerOpen: false

    ToastManagerService {
        id: toastManager
    }

    ListModel {
        id: availableTagsModel
    }

    ListModel {
        id: tagsModel
    }

    Component.onCompleted: {
        console.log(("MainPage created."));
        DB.initDatabase()
        DB.permanentlyDeleteExpiredDeletedNotes();
        refreshData()
    }

    onStatusChanged: {
        if (mainPage.status === PageStatus.Active) {
            refreshData()
            searchField.focus = false;
            sidePanel.currentPage = "notes"
            Qt.inputMethod.hide();
            resetSelection();
            mainPage.bulkColorPickerOpen = false;
            console.log(("MainPage active (status changed to Active), search field focus cleared and keyboard hidden."));
        }
    }

    function refreshData() {
        allNotes = DB.getAllNotes();
        allTags = DB.getAllTags();
        performSearch();
        loadTagsForDrawer();
    }

    function performSearch() {
        searchResults = DB.searchNotes(
            mainPage.currentSearchText,
            mainPage.selectedTags,
            mainPage.currentSortBy,
            mainPage.currentSortOrder,
            mainPage.customColorSortOrder
        );
        console.log("MAIN_PAGE: Search performed. SortBy: " + mainPage.currentSortBy);
    }

    function toggleTagSelection(tagName) {
        if (selectedTags.indexOf(tagName) !== -1) {
            selectedTags = selectedTags.filter(function(tag) { return tag !== tagName; });
            console.log(("MAIN_PAGE: Removed tag:", tagName, "Selected tags:", JSON.stringify(selectedTags)));
        } else {
            selectedTags = selectedTags.concat(tagName);
            console.log("MAIN_PAGE: Added tag:", tagName, "Selected tags:", JSON.stringify(selectedTags));
        }
        performSearch();
    }

    function loadTagsForTagPanel(filterText) {
        availableTagsModel.clear();
        var currentSearchLower = (filterText || "").toLowerCase();

        var selectedOnlyTags = [];
        var unselectedTags = [];

        for (var i = 0; i < allTags.length; i++) {
            var tagName = allTags[i];
            if (currentSearchLower === "" || tagName.toLowerCase().indexOf(currentSearchLower) !== -1) {
                if (selectedTags.indexOf(tagName) !== -1) {
                    selectedOnlyTags.push({ name: tagName, isChecked: true });
                } else {
                    unselectedTags.push({ name: tagName, isChecked: false });
                }
            }
        }

        for (var i = 0; i < selectedOnlyTags.length; i++) {
            availableTagsModel.append(selectedOnlyTags[i]);
        }
        for (var i = 0; i < unselectedTags.length; i++) {
            availableTagsModel.append(unselectedTags[i]);
        }

        console.log(("MAIN_PAGE: loadTagsForTagPanel executed. Filter:", filterText, "Model items:", availableTagsModel.count));
    }

    function loadTagsForDrawer() {
        tagsModel.clear();
        var tagsWithCounts = DB.getAllTagsWithCounts();
        for (var i = 0; i < tagsWithCounts.length; i++) {
            tagsModel.append(tagsWithCounts[i]);
        }
        console.log(("Loaded %1 tags for drawer.").arg(tagsWithCounts.length));
    }

    function isNoteSelected(noteId) {
        return mainPage.selectedNoteIds.indexOf(noteId) !== -1;
    }

    function toggleNoteSelection(noteId) {
        var newSelectedIds = mainPage.selectedNoteIds.slice();

        var index = newSelectedIds.indexOf(noteId);
        if (index === -1) {
            newSelectedIds.push(noteId);
            console.log(("Selected note ID: %1").arg(noteId));
        } else {
            newSelectedIds.splice(index, 1);
            console.log(("Deselected note ID: %1").arg(noteId));
        }

        mainPage.selectedNoteIds = newSelectedIds;
        mainPage.selectionMode = mainPage.selectedNoteIds.length > 0;
        Qt.inputMethod.hide();
        if (pinnedNotes) pinnedNotes.forceLayout();
        if (otherNotes) otherNotes.forceLayout();
        if (!mainPage.selectionMode) {
            mainPage.bulkColorPickerOpen = false;
        }
    }

    function resetSelection() {
        mainPage.selectedNoteIds = [];
        mainPage.selectionMode = false;
        mainPage.bulkColorPickerOpen = false;
        console.log(("Selection reset."));
        if (pinnedNotes) pinnedNotes.forceLayout();
        if (otherNotes) otherNotes.forceLayout();
    }

    function pinSelectedNotes() {
        if (mainPage.selectedNoteIds.length === 0) {
            toastManager.show(qsTr("No notes selected."));
            return;
        }

        var allArePinned = true;
        for (var i = 0; i < mainPage.selectedNoteIds.length; i++) {
            var note = DB.getNoteById(mainPage.selectedNoteIds[i]);
            if (!note || !note.pinned) {
                allArePinned = false;
                break;
            }
        }

        var actionText = allArePinned ? qsTr("unpin") : qsTr("pin");
        var message = qsTr("Are you sure you want to %1 %2 selected note(s)?").arg(actionText).arg(mainPage.selectedNoteIds.length);
        var buttonText = actionText.charAt(0).toUpperCase() + actionText.slice(1);
        var highlightColor = Theme.primaryColor;

        mainPage.confirmDialogTitle = qsTr("Confirm Pin/Unpin");
        mainPage.confirmDialogMessage = message;
        mainPage.confirmButtonText = buttonText;
        mainPage.confirmButtonHighlightColor = highlightColor;
        mainPage.onConfirmCallback = function() {
            var idsToToggle = mainPage.selectedNoteIds;
            if (allArePinned) {
                DB.bulkUnpinNotes(idsToToggle);
                toastManager.show(qsTr("%1 note(s) unpinned!").arg(idsToToggle.length));
            } else {
                DB.bulkPinNotes(idsToToggle);
                toastManager.show(qsTr("%1 note(s) pinned!").arg(idsToToggle.length));
            }
            mainPage.resetSelection();
            mainPage.refreshData();
        };
        mainPage.confirmDialogVisible = true;
        console.log(("Showing pin/unpin confirmation dialog."));
    }

    function bulkChangeNoteColor(newColor) {
        if (mainPage.selectedNoteIds.length === 0) {
            toastManager.show(qsTr("No notes selected."));
            return;
        }

        mainPage.confirmDialogTitle = qsTr("Confirm Color Change");
        mainPage.confirmDialogMessage = qsTr("Are you sure you want to change the color of %1 selected note(s) to the chosen color?").arg(mainPage.selectedNoteIds.length);
        mainPage.confirmButtonText = qsTr("Change Color");
        mainPage.confirmButtonHighlightColor = Theme.primaryColor;
        mainPage.onConfirmCallback = function() {
            var idsToChangeColor = mainPage.selectedNoteIds;
            DB.bulkUpdateNoteColor(idsToChangeColor, newColor);
            toastManager.show(qsTr("Color changed for %1 note(s)!").arg(idsToChangeColor.length));
            mainPage.resetSelection();
            mainPage.refreshData();
        };
        mainPage.confirmDialogVisible = true;
        console.log(("Showing bulk color change confirmation dialog."));
    }

    Label {
        id: noNotesLabel
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: qsTr("You have no notes.\nClick on the plus button to create one!")
        font.italic: true
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        anchors.centerIn: parent
        visible: allNotes.length === 0
    }

    Column {
        id: searchAreaWrapper
        width: parent.width
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 2

        y: headerVisible ? 0 : -searchBarArea.height
        Behavior on y {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
        }

        Item {
            id: searchBarArea
            width: parent.width
            height: 80

            Rectangle {
                id: searchBarContainer
                width: parent.width - (noteMargin * 2)
                height: parent.height
                anchors.centerIn: parent
                color: mainPage.backgroundColor
                radius: 80
                visible: !mainPage.selectionMode
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                SearchField {
                    id: searchField
                    anchors.fill: parent
                    placeholderText: qsTr("Search notes...")
                    highlighted: false
                    text: currentSearchText
                    readOnly: allNotes.length === 0
                    onTextChanged: {
                        mainPage.currentSearchText = text;
                        performSearch();
                    }

                    EnterKey.onClicked: {
                        console.log(("Searching for:", text))
                        Qt.inputMethod.hide();
                        searchField.focus = false;
                    }

                    leftItem: Item {
                        width: Theme.fontSizeExtraLarge * 1.1
                        height: Theme.fontSizeExtraLarge * 0.95
                        clip: false

                        Icon {
                            id: leftIcon
                            source: (searchField.text.length > 0 || selectedTags.length > 0) ? "qrc:/qml/icons/close.svg" : "qrc:/qml/icons/menu.svg"
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                        }

                        RippleEffectComponent { id: menuRipple }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (searchField.text.length > 0 || selectedTags.length > 0) {
                                    mainPage.currentSearchText = "";
                                    searchField.text = "";
                                    mainPage.selectedTags = [];
                                    performSearch("", []);
                                    console.log(("Search cleared (text and tags)."));
                                } else {
                                    mainPage.panelOpen = true
                                    console.log(("Menu button clicked → panelOpen = true"))
                                }
                                onPressed: menuRipple.ripple(mouseX, mouseY)
                                Qt.inputMethod.hide();
                                searchField.focus = false;
                            }
                        }
                    }

                    rightItem: Item {
                        width: Theme.fontSizeExtraLarge * 1.25
                        height: Theme.fontSizeExtraLarge * 1.25
                        clip: false
                        enabled: allNotes.length !== 0
                        opacity: allNotes.length !== 0 ? 1 : 0.5

                        Icon {
                            id: rightIcon
                            source: selectedTags.length > 0 ? "qrc:/qml/icons/tag-filled.svg" : "qrc:/qml/icons/tag-white.svg"
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                        }

                        RippleEffectComponent { id: rightRipple }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mainPage.tagPickerOpen = true;
                                console.log(("MAIN_PAGE: Tag picker opened from right icon."));
                            }
                            onPressed: rightRipple.ripple(mouseX, mouseY)
                        }
                    }
                }
            }

            Rectangle {
                id: selectionToolbarBackground
                width: parent.width - (noteMargin * 2)
                height: parent.height
                anchors.centerIn: parent
                color: mainPage.backgroundColor
                radius: 80
                visible: mainPage.selectionMode
                opacity: visible ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Item {
                    id: closeButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge

                    Icon { source: "qrc:/qml/icons/close.svg"; anchors.centerIn: parent; width: parent.width; height: parent.height }
                    RippleEffectComponent { id: closeRipple }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mainPage.resetSelection()
                        onPressed: closeRipple.ripple(mouseX, mouseY)
                    }
                }

                Label {
                    id: selectedCountLabel
                    text: mainPage.selectedNoteIds.length.toString()
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    color: Theme.secondaryColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: closeButton.right
                    anchors.leftMargin: Theme.paddingSmall
                    visible: mainPage.selectionMode
                }


                Item {
                    id: selectAllButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: pinButton.left
                    anchors.rightMargin: Theme.paddingMedium

                    Icon {
                        source: mainPage.allVisibleNotesSelected ? "qrc:/qml/icons/deselect_all.svg" : "qrc:/qml/icons/select_all.svg"
                        color: Theme.primaryColor
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                    }
                    RippleEffectComponent { id: selectAllRipple }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: selectAllRipple.ripple(mouseX, mouseY)
                        onClicked: {
                            var newSelectedIds = [];
                            if (!mainPage.allVisibleNotesSelected) {
                                for (var i = 0; i < mainPage.searchResults.length; i++) {
                                    newSelectedIds.push(mainPage.searchResults[i].id);
                                }
                                console.log("Selected " + newSelectedIds.length + " visible notes.");
                            } else {
                                console.log("Deselect");
                            }
                            mainPage.selectedNoteIds = newSelectedIds;
                        }
                    }
                }

                Item {
                    id: pinButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: paletteButton.left
                    anchors.rightMargin: Theme.paddingMedium

                    Icon {
                        id: pinAllIconButton
                        property bool allSelectedPinned: {
                            if (mainPage.selectedNoteIds.length === 0) return false;
                            for (var i = 0; i < mainPage.selectedNoteIds.length; i++) {
                                var note = DB.getNoteById(mainPage.selectedNoteIds[i]);
                                if (!note || !note.pinned) {
                                    return false;
                                }
                            }
                            return true;
                        }
                        source: allSelectedPinned ? "qrc:/qml/icons/pin-enabled.svg" : "qrc:/qml/icons/pin.svg"
                        color: Theme.primaryColor
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                    }
                    RippleEffectComponent { id: pinRipple }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: pinRipple.ripple(mouseX, mouseY)
                        onClicked: {
                            mainPage.pinSelectedNotes();
                            mainPage.bulkColorPickerOpen = false;
                        }
                    }
                }

                Item {
                    id: paletteButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: archiveButton.left
                    anchors.rightMargin: Theme.paddingMedium

                    Icon {
                        id: paletteIcon
                        source: "qrc:/qml/icons/palette.svg"
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        color: Theme.primaryColor
                    }
                    RippleEffectComponent { id: paletteRipple }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: paletteRipple.ripple(mouseX, mouseY)
                        onClicked: {
                            if (mainPage.selectedNoteIds.length === 0) {
                                toastManager.show(qsTr("No notes selected."));
                                return;
                            }
                            mainPage.bulkColorPickerOpen = !mainPage.bulkColorPickerOpen;
                            console.log("Bulk color palette button clicked. bulkColorPickerOpen:", mainPage.bulkColorPickerOpen);
                        }
                    }
                }

                Item {
                    id: deleteButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge

                    Icon { source: "qrc:/qml/icons/delete.svg"; color: Theme.errorColor; anchors.centerIn: parent; width: parent.width; height: parent.height }
                    RippleEffectComponent { id: deleteRipple }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mainPage.selectedNoteIds.length > 0) {
                                mainPage.confirmDialogTitle = qsTr("Confirm Deletion");
                                mainPage.confirmDialogMessage = qsTr("Are you sure you want to move %1 selected note(s) to trash?").arg(mainPage.selectedNoteIds.length);
                                mainPage.confirmButtonText = qsTr("Delete");
                                mainPage.confirmButtonHighlightColor = Theme.errorColor;
                                mainPage.onConfirmCallback = function() {
                                    var idsToMove = mainPage.selectedNoteIds;
                                    DB.bulkMoveToTrash(idsToMove);
                                    toastManager.show(qsTr("%1 note(s) moved to trash!").arg(idsToMove.length));
                                    mainPage.resetSelection();
                                    mainPage.refreshData();
                                };
                                mainPage.confirmDialogVisible = true;
                                mainPage.bulkColorPickerOpen = false;
                                console.log(("Showing delete confirmation dialog."));
                            } else {
                                toastManager.show(qsTr("No notes selected."));
                            }
                        }
                        onPressed: deleteRipple.ripple(mouseX, mouseY)
                    }
                }
                Item {
                    id: archiveButton
                    width: Theme.fontSizeExtraLarge * 1.1
                    height: Theme.fontSizeExtraLarge * 0.95
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: deleteButton.left
                    anchors.rightMargin: Theme.paddingMedium

                    Icon { source: "qrc:/qml/icons/archive.svg"; color: Theme.primaryColor; anchors.centerIn: parent; width: parent.width; height: parent.height }
                    RippleEffectComponent { id: archiveRipple }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mainPage.selectedNoteIds.length > 0) {
                                mainPage.confirmDialogTitle = qsTr("Confirm Archiving");
                                mainPage.confirmDialogMessage = qsTr("Are you sure you want to archive %1 selected note(s)?").arg(mainPage.selectedNoteIds.length);
                                mainPage.confirmButtonText = qsTr("Archive");
                                mainPage.confirmButtonHighlightColor = Theme.primaryColor;
                                mainPage.onConfirmCallback = function() {
                                    var idsToArchive = mainPage.selectedNoteIds;
                                    DB.bulkArchiveNotes(idsToArchive);
                                    toastManager.show(qsTr("%1 note(s) archived!").arg(idsToArchive.length));
                                    mainPage.resetSelection();
                                    mainPage.refreshData();
                                };
                                mainPage.confirmDialogVisible = true;
                                mainPage.bulkColorPickerOpen = false;
                                console.log(("Showing archive confirmation dialog."));
                            } else {
                                toastManager.show(qsTr("No notes selected."));
                            }
                        }
                        onPressed: archiveRipple.ripple(mouseX, mouseY)
                    }
                }
            }
        }
    }

    SidePanelComponent {
        id: sidePanel
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        open: panelOpen
        tags: allTags
        onClosed: mainPage.panelOpen = false
    }

    SilicaFlickable {
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: searchAreaWrapper.bottom
        contentHeight: column.height
        clip: true

        onContentYChanged: {
            var scrollY = flickable.contentY;

            if (flickable.atYBeginning) {
                mainPage.headerVisible = true;
            } else if (scrollY < mainPage.previousContentY) {
                mainPage.headerVisible = true;
            } else if (scrollY > mainPage.previousContentY && scrollY > searchBarArea.height) {
                mainPage.headerVisible = false;
            }

            mainPage.previousContentY = scrollY;
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingSmall

            Loader {
                sourceComponent: searchResults.length === 0 && (currentSearchText.length > 0 || selectedTags.length > 0) ? noResultsComponent : undefined
                width: parent.width
                height: childrenRect.height
            }

            Component {
                id: noResultsComponent
                Column {
                    width: parent.width
                    height: 200
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingMedium
                    Text {
                        text: qsTr("No notes found matching your criteria.")
                        font.pixelSize: Theme.fontSizeMedium
                        color: "#e2e3e8"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - (noteMargin * 2)
                        wrapMode: Text.WordWrap
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: qsTr("Try a different keyword or fewer tags.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: "#999"
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - (noteMargin * 2)
                        wrapMode: Text.WordWrap
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Column {
                id: pinnedSection
                width: parent.width
                spacing: 0
                visible: searchResults.filter(function(note) { return note.pinned; }).length > 0

                SectionHeader {
                    text: qsTr("Pinned") + " (" + searchResults.filter(function(note) { return note.pinned; }).length + ")"
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: "#e2e3e8"
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge + 19
                    horizontalAlignment: Text.AlignLeft
                }

                ListView {
                    id: pinnedNotes
                    width: parent.width
                    height: contentHeight
                    model: searchResults.filter(function(note) { return note.pinned; })
                    delegate: NoteCard {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: mainPage.noteMargin
                            rightMargin: mainPage.noteMargin
                        }
                        width: parent.width
                        title: modelData.title
                        content: modelData.content
                        tags: modelData.tags.join("_||_")
                        cardColor: modelData.color || "#1c1d29"
                        noteId: modelData.id
                        isSelected: mainPage.isNoteSelected(modelData.id)
                        mainPageInstance: mainPage
                        noteIsPinned: modelData.pinned
                        noteCreationDate: new Date(modelData.created_at + "Z")
                        noteEditDate: new Date(modelData.updated_at + "Z")
                    }
                }
            }

            Column {
                id: othersSection
                width: parent.width
                spacing: 0
                visible: searchResults.filter(function(note) { return !note.pinned; }).length > 0


                SectionHeader {
                    text: qsTr("Others") + " (" + searchResults.filter(function(note) { return !note.pinned; }).length + ")"
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: "#e2e3e8"
                    horizontalAlignment: Text.AlignLeft
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge + 19
                }

                ListView {
                    id: otherNotes
                    width: parent.width
                    spacing: 0
                    height: contentHeight
                    model: searchResults.filter(function(note) { return !note.pinned; })
                    delegate: NoteCard {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: mainPage.noteMargin
                            rightMargin: mainPage.noteMargin
                        }
                        width: parent.width
                        title: modelData.title
                        content: modelData.content
                        tags: modelData.tags.join("_||_")
                        cardColor: modelData.color || "#1c1d29"
                        noteId: modelData.id
                        isSelected: mainPage.isNoteSelected(modelData.id)
                        mainPageInstance: mainPage
                        noteIsPinned: modelData.pinned
                        noteCreationDate: new Date(modelData.created_at + "Z")
                        noteEditDate: new Date(modelData.updated_at + "Z")
                    }
                }
            }
        }
    }

    ScrollBarComponent {
        flickableSource: flickable
        topAnchorItem: searchAreaWrapper
    }

    Rectangle {
        id: sortFabButton
        width: Theme.itemSizeLarge
        height: Theme.itemSizeLarge
        radius: width / 2
        color:  DB.darkenColor((mainPage.customBackgroundColor), -0.3)
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.paddingLarge * 2
        anchors.bottomMargin: Theme.paddingLarge * 2
        z: 5
        antialiasing: true
        visible: !mainPage.selectionMode && !mainPage.tagPickerOpen && allNotes.length > 1 && !mainPage.bulkColorPickerOpen
        property real baseOpacity: 0.8
        property real minOpacity: 0.1
        property real fadeDistance: Theme.itemSizeExtraLarge * 1.5

        opacity: {
            if (flickable.contentHeight <= flickable.height || flickable.contentHeight - flickable.height <= 0) {
                return baseOpacity;
            }
            var maxScrollY = flickable.contentHeight - flickable.height;
            var fadeStartScrollY = maxScrollY - fadeDistance;
            if (flickable.contentY < fadeStartScrollY) {
                return baseOpacity;
            } else {
                var progress = (flickable.contentY - fadeStartScrollY) / fadeDistance;
                progress = Math.max(0, Math.min(1, progress));
                return baseOpacity - (progress * (baseOpacity - minOpacity));
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        Icon {
            source: "qrc:/qml/icons/sort.svg"
            color: Theme.primaryColor
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: parent.height * 0.5
        }

        RippleEffectComponent { id: sortButtonRipple }

        MouseArea {
            anchors.fill: parent
            enabled: sortFabButton.visible
            onPressed: sortButtonRipple.ripple(mouseX, mouseY)
            onClicked: {
                console.log("Кнопка сортировки нажата. Вычисляем цвета из mainPage.searchResults.");
                var uniqueColors = [];
                var seenColors = {};
                for (var i = 0; i < mainPage.searchResults.length; i++) {
                    var color = mainPage.searchResults[i].color || "#1c1d29";
                    if (!seenColors[color]) {
                        seenColors[color] = true;
                        uniqueColors.push(color);
                    }
                }
                sortDialog.availableColors = uniqueColors;
                mainPage.sortDialogVisible = true;
                mainPage.bulkColorPickerOpen = false;
            }
        }
    }

    Rectangle {
        id: fabButton
        width: Theme.itemSizeLarge
        height: Theme.itemSizeLarge
        radius: width / 2
        color:  DB.darkenColor((mainPage.customBackgroundColor), -0.3)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Theme.paddingLarge * 2
        anchors.bottomMargin: Theme.paddingLarge * 2
        z: 5
        antialiasing: true
        visible: !mainPage.selectionMode && !mainPage.tagPickerOpen && !mainPage.bulkColorPickerOpen

        property real baseOpacity: 0.8
        property real minOpacity: 0.1
        property real fadeDistance: Theme.itemSizeExtraLarge * 1.5

        opacity: {
            if (flickable.contentHeight <= flickable.height || flickable.contentHeight - flickable.height <= 0) {
                return baseOpacity;
            }

            var maxScrollY = flickable.contentHeight - flickable.height;
            var fadeStartScrollY = maxScrollY - fadeDistance;

            if (flickable.contentY < fadeStartScrollY) {
                return baseOpacity;
            } else {
                var progress = (flickable.contentY - fadeStartScrollY) / fadeDistance;
                progress = Math.max(0, Math.min(1, progress));
                return baseOpacity - (progress * (baseOpacity - minOpacity));
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        Icon {
            source: "qrc:/qml/icons/plus.svg"
            color: Theme.primaryColor
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: parent.height * 0.5
        }

        RippleEffectComponent { id: plusButtonRipple }

        MouseArea {
            anchors.fill: parent
            enabled: fabButton.visible
            onPressed: plusButtonRipple.ripple(mouseX, mouseY)
            onClicked: {
                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {
                    onNoteSavedOrDeleted: refreshData,
                    noteId: -1,
                    noteTitle: "",
                    noteContent: "",
                    noteIsPinned: false,
                    noteTags: "",
                    noteCreationDate: new Date(),
                    noteEditDate: new Date(),
                    noteColor: DB.getThemeColor() || "#121218"

                });
                console.log(("Opening NewNotePage in CREATE mode (from FAB)."));
                Qt.inputMethod.hide();
                searchField.focus = false;
                mainPage.bulkColorPickerOpen = false;
            }
        }
    }

    Rectangle {
        id: bulkColorOverlayRect
        anchors.fill: parent
        color: "#000000"
        visible: bulkColorSelectionPanel.opacity > 0.01
        opacity: bulkColorSelectionPanel.opacity * 0.4
        z: 10.5

        MouseArea {
            anchors.fill: parent
            enabled: bulkColorOverlayRect.visible
            onClicked: {
                mainPage.bulkColorPickerOpen = false;
            }
        }
    }

    Rectangle {
        id: bulkColorSelectionPanel
        width: parent.width
        property real panelRadius: Theme.itemSizeSmall / 2
        height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + panelRadius
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        z: 12
        opacity: mainPage.bulkColorPickerOpen ? 1 : 0
        visible: opacity > 0.01
        color: "transparent"
        clip: true

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: colorPanelVisualBody
            width: parent.width
            height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + 2 * bulkColorSelectionPanel.panelRadius
            color: DB.darkenColor(mainPage.customBackgroundColor, 0.15)
            y: 0

            Column {
                id: colorPanelContentColumn
                width: parent.width
                height: implicitHeight
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: bulkColorSelectionPanel.panelRadius
                anchors.bottomMargin: Theme.paddingMedium
                spacing: Theme.paddingMedium

                Label {
                    id: bulkColorTitle
                    text: qsTr("Select Color for Notes")
                    font.pixelSize: Theme.fontSizeLarge
                    color: "#e8eaed"
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                Flow {
                    id: bulkColorFlow
                    width: parent.width
                    spacing: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: Qt.LeftToRight
                    readonly property int columns: 6
                    readonly property real itemWidth: (parent.width - (spacing * (columns - 1))) / columns

                    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
                        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]

                    property string currentSelectedBulkColor: mainPage.lastSelectedBulkColor || ""

                    Repeater {
                        model: bulkColorFlow.colorPalette
                        delegate: Item {
                            width: parent.itemWidth
                            height: parent.itemWidth

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: (bulkColorFlow.currentSelectedBulkColor === modelData) ? "white" : "#707070"
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
                                    visible: bulkColorFlow.currentSelectedBulkColor === modelData
                                    anchors.centerIn: parent
                                    width: parent.width * 0.7
                                    height: parent.height * 0.7
                                    radius: width / 2
                                    color: modelData

                                    Icon {
                                        source: "qrc:/qml/icons/check.svg"
                                        anchors.centerIn: parent
                                        width: parent.width * 0.75
                                        height: parent.height * 0.75
                                        color: "white"
                                    }
                                }
                            }

                            RippleEffectComponent { id: colorRipple }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: colorRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    mainPage.bulkChangeNoteColor(modelData);
                                    mainPage.lastSelectedBulkColor = modelData;
                                    mainPage.bulkColorPickerOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    Rectangle {
        id: tagPickerOverlay
        anchors.fill: parent
        color: "#000000"
        opacity: tagPickerPanel.opacity * 0.4
        z: 3
        visible: tagPickerPanel.visible
        smooth: true
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            enabled: tagPickerOverlay.visible
            onClicked: {
                mainPage.tagPickerOpen = false;
                console.log(("MAIN_PAGE: Tag picker overlay clicked, closing picker."));
            }
        }
    }

        Rectangle {
            id: tagPickerPanel
            property string tagPickerSearchText: ""

            width: parent.width
            height: parent.height * 0.53
            color: mainPage.customBackgroundColor
            radius: 15
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            z: 4
            opacity: mainPage.tagPickerOpen ? 1 : 0
            visible: mainPage.tagPickerOpen || opacity > 0.01

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            onVisibleChanged: {
                if (visible) {
                    tagPickerPanel.tagPickerSearchText = "";
                    mainPage.loadTagsForTagPanel(tagPickerPanel.tagPickerSearchText);
                    tagsPanelFlickable.contentY = 0;
                    console.log(("Tag picker panel opened. Loading tags and scrolling to top."));
                } else {
                    tagPickerPanel.tagPickerSearchText = "";
                }
            }

            Column {
                id: tagPanelContentColumn
                anchors.fill: parent
                spacing: Theme.paddingMedium

                Rectangle {
                    id: tagPanelHeader
                    width: parent.width
                    height: Theme.itemSizeMedium
                    color: DB.darkenColor(mainPage.customBackgroundColor, 0.15)
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.rightMargin: Theme.paddingLarge

                    Column {
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent
                        spacing: Theme.paddingSmall

                        SearchField {
                            id: tagSearchInput
                            width: parent.width * 0.95
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: qsTr("Search tags...")
                            font.pixelSize: Theme.fontSizeMedium
                            highlighted: false
                            color: "#e2e3e8"
                            readOnly: false

                            text: tagPickerPanel.tagPickerSearchText

                            onTextChanged: {
                                tagPickerPanel.tagPickerSearchText = text;
                                mainPage.loadTagsForTagPanel(tagPickerPanel.tagPickerSearchText);
                            }

                            leftItem: Item { }

                            rightItem: Item {
                                width: Theme.fontSizeExtraLarge * 1.25
                                height: Theme.fontSizeExtraLarge * 1.25
                                clip: false

                                opacity: tagSearchInput.text.length > 0 ? 1 : 0.3
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                Icon {
                                    id: rightIconCloseTagSearch
                                    source: "qrc:/qml/icons/close.svg"
                                    color: Theme.primaryColor
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                }

                                RippleEffectComponent { id: rightClearRippleTagSearch }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: tagSearchInput.text.length > 0
                                    onPressed: rightClearRippleTagSearch.ripple(mouseX, mouseY)
                                    onClicked: {
                                        tagPickerPanel.tagPickerSearchText = "";
                                        tagSearchInput.text = "";
                                        mainPage.loadTagsForTagPanel("");
                                        console.log(("Tag picker search field cleared by right icon."));
                                    }
                                }
                            }
                        }
                    }
                }

                SilicaFlickable {
                    id: tagsPanelFlickable
                    width: parent.width
                    anchors.top: tagPanelHeader.bottom
                    anchors.bottom: doneButton.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: Theme.paddingMedium
                    anchors.bottomMargin: Theme.paddingMedium
                    contentHeight: tagsPanelListView.contentHeight
                    clip: true
                    ScrollBarComponent { flickableSource: tagsPanelFlickable; z: 5 }

                    ListView {
                        id: tagsPanelListView
                        width: parent.width
                        height: contentHeight
                        model: availableTagsModel
                        orientation: ListView.Vertical
                        spacing: Theme.paddingSmall

                        delegate: Rectangle {
                            id: tagPanelDelegateRoot
                            width: parent.width
                            height: Theme.itemSizeMedium
                            clip: true
                            color: model.isChecked ? DB.darkenColor(mainPage.customBackgroundColor, -0.25) : DB.darkenColor(mainPage.customBackgroundColor, 0.25)

                            RippleEffectComponent { id: tagPanelDelegateRipple }

                            MouseArea {
                                anchors.fill: parent
                                onPressed: tagPanelDelegateRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    var newCheckedState = !model.isChecked;
                                    availableTagsModel.set(index, { name: model.name, isChecked: newCheckedState });
                                    mainPage.toggleTagSelection(model.name);
                                    console.log(("MAIN_PAGE: Toggling tag from picker: " + model.name + ", isChecked: " + newCheckedState + ", Current selectedTags:", JSON.stringify(mainPage.selectedTags)));
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
                                    source: "qrc:/qml/icons/tag-white.svg"
                                    color: "#e2e3e8"
                                    width: Theme.iconSizeMedium
                                    height: Theme.iconSizeMedium
                                    anchors.verticalCenter: parent.verticalCenter
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    id: tagPanelTagNameLabel
                                    text: model.name
                                    color: "#e2e3e8"
                                    font.pixelSize: Theme.fontSizeMedium
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    anchors.left: tagPanelTagIcon.right
                                    anchors.leftMargin: tagPanelRow.spacing
                                    anchors.right: tagPanelCheckButtonContainer.left
                                    anchors.rightMargin: tagPanelRow.spacing
                                }

                                Item {
                                    id: tagPanelCheckButtonContainer
                                    width: Theme.iconSizeMedium
                                    height: Theme.iconSizeMedium
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    clip: false

                                    Image {
                                        id: tagPanelCheckIcon
                                        source: model.isChecked ? "qrc:/qml/icons/box-checked.svg" : "qrc:/qml/icons/box.svg"
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
                ScrollBarComponent {
                    flickableSource: tagsPanelFlickable
                    anchors.top: tagsPanelFlickable.top
                    anchors.bottom: tagsPanelFlickable.bottom
                    anchors.right: parent.right
                    width: Theme.paddingSmall
                }

                Button {
                    id: doneButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Done")
                    onClicked: {
                        mainPage.tagPickerOpen = false;
                        console.log(("MAIN_PAGE: Tag picker closed by Done button."));
                    }
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingLarge
                    visible: allTags.length !== 0
                }
                Button {
                    id: createTagButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Create")
                    onClicked: {
                        mainPage.tagPickerOpen = false;
                        pageStack.push(Qt.resolvedUrl("TagEditPage.qml"), {
                                onTagsChanged: mainPage.refreshData,
                                creatingNewTag: true
                                });
                        console.log(("MAIN_PAGE: Tag creation page opened by button."));
                    }
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingLarge
                    visible: allTags.length === 0
                }
            }
            Label {
                id: noTagsFoundLabel
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: qsTr("No tags found matching your search")
                font.italic: true
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.centerIn: parent
                visible: availableTagsModel.count === 0 && tagPickerPanel.tagPickerSearchText !== ""
            }
            Label {
                id: noTagsLabel
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: qsTr("You have no tags.\nGo to edit tags page to create one!")
                font.italic: true
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.centerIn: parent
                visible: allTags.length === 0
            }
        }
    ConfirmDialog {
        id: confirmDialogInstance
        dialogVisible: mainPage.confirmDialogVisible
        dialogTitle: mainPage.confirmDialogTitle
        dialogMessage: mainPage.confirmDialogMessage
        confirmButtonText: mainPage.confirmButtonText
        confirmButtonHighlightColor: mainPage.confirmButtonHighlightColor

        onConfirmed: {
            if (mainPage.onConfirmCallback) {
                mainPage.onConfirmCallback();
            }
            mainPage.confirmDialogVisible = false;
        }
        onCancelled: {
            mainPage.confirmDialogVisible = false;
            console.log(("Action cancelled by user."));
        }
    }

    SortDialog {
        id: sortDialog
        dialogVisible: mainPage.sortDialogVisible
        currentSortBy: mainPage.currentSortBy
        currentSortOrder: mainPage.currentSortOrder
        dialogBackgroundColor: DB.darkenColor(mainPage.customBackgroundColor, 0.15)

        onSortApplied: function(sortBy, sortOrder) {
            mainPage.sortDialogVisible = false;
            mainPage.currentSortBy = sortBy;
            mainPage.currentSortOrder = sortOrder;
            mainPage.performSearch();
            toastManager.show(qsTr("Notes sorted!"));

        }

        onColorSortRequested: {
            var allCurrentColors = sortDialog.availableColors;
            if (allCurrentColors.length <= 1) {
                toastManager.show(qsTr("Only one color is used in the filtered notes."));
                return;
            }

            var savedOrder = mainPage.customColorSortOrder || [];
            var finalOrderForDialog = [];
            var seenColors = {};
            savedOrder.forEach(function(color) {
                if (allCurrentColors.indexOf(color) !== -1) {
                    finalOrderForDialog.push(color);
                    seenColors[color] = true;
                }
            });
            allCurrentColors.forEach(function(color) {
                if (!seenColors[color]) {
                    finalOrderForDialog.push(color);
                }
            });

            colorSortDialog.colorsToOrder = finalOrderForDialog;
            mainPage.colorSortDialogVisible = true;
        }

        onCancelled: mainPage.sortDialogVisible = false
        onShowDisabledToast: {
            toastManager.show(qsTr("Sorting by color is not available when there is only one color."))
        }
    }

    ColorSortDialog {
        id: colorSortDialog
        dialogVisible: mainPage.colorSortDialogVisible
        dialogBackgroundColor: DB.darkenColor(mainPage.customBackgroundColor, 0.3)
        onColorOrderApplied: function(orderedColors) {
            mainPage.colorSortDialogVisible = false;
            mainPage.sortDialogVisible = false;
            mainPage.customColorSortOrder = orderedColors;
            mainPage.currentSortBy = 'color';
            mainPage.performSearch();
            toastManager.show(qsTr("Notes sorted by color!"));
        }
        onCancelled: mainPage.colorSortDialogVisible = false

    }
}

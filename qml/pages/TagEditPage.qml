/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/pages/TagEditPage.qml
 * Эта страница предназначена для управления тегами. Она позволяет
 * пользователям выполнять следующие действия:
 * - Создавать новые теги через специальное поле ввода вверху.
 * - Просматривать список существующих тегов с указанием количества
 * заметок для каждого.
 * - Редактировать названия существующих тегов в "инлайн" режиме.
 * - Удалять теги.
 * Страница имеет заголовок, который скрывается при прокрутке,
 * и взаимодействует с главной страницей для обновления данных
 * после внесения изменений в теги.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../services/DatabaseManagerService.js" as DB
import "../dialogs"
import "../components"
import "../services"

Page {
    id: tagEditPage
    backgroundColor: tagEditPage.customBackgroundColor !== undefined ? tagEditPage.customBackgroundColor : "#121218"
    showNavigationIndicator: false
    property bool panelOpen: false

    property string customBackgroundColor: DB.getThemeColor() || "#121218"
    property var onTagsChanged: null
    property string borderColor:  DB.darkenColor((tagEditPage.customBackgroundColor), -0.3)

    property bool headerVisible: true
    property real previousContentY: 0

    property bool creatingNewTag: false
    property string newTagNameInput: ""
    property bool newTagInputError: false

    property var allTagsWithCounts: []
    property var editingTagData: null

    property var currentlyEditingTagDelegate: null

    property bool ignoreNextFocusLossCancellation: false

    Component.onCompleted: {
        console.log("TagEditPage opened.");
        sidePanelInstance.currentPage = "edit";
        refreshTags();
    }

    function refreshTags() {
        allTagsWithCounts = [];
        var fetchedTags = DB.getAllTagsWithCounts();
        fetchedTags.sort(function(a, b) {
            return b.count - a.count;
        });
        allTagsWithCounts = fetchedTags;
        console.log("Tags refreshed and re-assigned:", JSON.stringify(allTagsWithCounts));

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
    Label {
        id: noTagsLabel
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: qsTr("You have no tags.\nYou can create one!")
        font.italic: true
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        anchors.centerIn: parent
        visible: allTagsWithCounts.length === 0
    }

    Item {
        id: headerArea
        width: parent.width
        height: Theme.itemSizeLarge
        z: 2

        y: headerVisible ? 0 : -height

        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuad
            }
        }

        Rectangle {
            id: headerContainer
            width: parent.width
            height: parent.height
            color: tagEditPage.customBackgroundColor

            Item {
                width: Theme.fontSizeExtraLarge * 1.1
                height: Theme.fontSizeExtraLarge * 1.1
                clip: false
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingLarge }
                RippleEffectComponent { id: menuRipple }
                Icon {
                    id: menuIcon
                    source: "qrc:/qml/icons/menu.svg"
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: menuRipple.ripple(mouseX, mouseY)
                    onClicked: {
                        tagEditPage.panelOpen = true
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

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: headerArea.height
        contentHeight: contentColumn.height

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
                        placeholderText: qsTr("Create new tag")
                        text: newTagNameInput
                        onTextChanged: newTagNameInput = text
                        font.pixelSize: Theme.fontSizeMedium
                        color: "#e8eaed"
                        inputMethodHints: Qt.ImhNoAutoUppercase

                        focus: creatingNewTag

                        onClicked: {
                            if (tagEditPage.currentlyEditingTagDelegate) {
                                tagEditPage.currentlyEditingTagDelegate.resetEditState();
                            }

                            if (!creatingNewTag) {
                                tagEditPage.ignoreNextFocusLossCancellation = true;
                                tagEditPage.creatingNewTag = true;
                                tagInput.forceActiveFocus(true);
                                newTagNameInput = "";
                            } else {
                                tagInput.forceActiveFocus(true);
                            }
                        }

                        EnterKey.onClicked: {
                            if (newTagCheckItem.enabled) {
                                newTagCheckItem.performCreationLogic();
                            }
                        }


                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                if (creatingNewTag) {
                                    if (tagEditPage.ignoreNextFocusCancellation) {
                                        console.log("Ignoring momentary focus loss for new tag creation.");
                                        tagEditPage.ignoreNextFocusCancellation = false;
                                        return;
                                    }
                                    if (newTagNameInput.trim() === "") {
                                        creatingNewTag = false;
                                        if (toastManager) toastManager.show(qsTr("Tag creation cancelled."));
                                        console.log("Tag creation cancelled (empty field, lost focus).");
                                    }
                                }
                            } else {
                                if (tagEditPage.ignoreNextFocusCancellation) {
                                    tagEditPage.ignoreNextFocusCancellation = false;
                                    console.log("New tag input gained focus, reset ignore flag.");
                                }
                            }
                        }

                        leftItem: Item {
                            id: newTagPlusXItem
                            width: Theme.fontSizeExtraLarge * 1.1
                            height: Theme.fontSizeExtraLarge * 1.1
                            clip: false

                            Icon {
                                id: plusXIcon
                                source: "qrc:/qml/icons/plus.svg"
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                rotation: creatingNewTag ? 45 : 0
                                Behavior on rotation { NumberAnimation { duration: 150 } }
                            }
                            RippleEffectComponent { id: plusXRipple }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: plusXRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    if (creatingNewTag) {
                                        creatingNewTag = false;
                                        newTagNameInput = "";
                                        tagInput.forceActiveFocus(false);
                                        if (toastManager) toastManager.show(qsTr("Tag creation cancelled."));
                                    } else {
                                        if (tagEditPage.currentlyEditingTagDelegate) {
                                            tagEditPage.currentlyEditingTagDelegate.resetEditState();
                                        }
                                        tagEditPage.ignoreNextFocusLossCancellation = true;
                                        creatingNewTag = true;
                                        tagInput.forceActiveFocus(true);
                                        newTagNameInput = "";
                                    }
                                }
                            }
                        }

                        rightItem: Item {
                            id: newTagCheckItem
                            width: Theme.fontSizeExtraLarge * 1.1
                            height: Theme.fontSizeExtraLarge * 1.1
                            clip: false

                            visible: true
                            opacity: creatingNewTag ? 1 : 0.3
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            RippleEffectComponent { id: checkRipple }
                            Icon {
                                id: checkIcon
                                source: "qrc:/qml/icons/check.svg"
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                            }


                            function performCreationLogic() {
                                var trimmedTag = newTagNameInput.trim();
                                if (trimmedTag === "") {
                                    if (toastManager) toastManager.show(qsTr("Tag name cannot be empty!"));
                                } else {

                                    var tagExists = allTagsWithCounts.some(function(t) {
                                        return t.name === trimmedTag;
                                    });

                                    if (tagExists) {
                                        console.log("Error: Tag '" + trimmedTag + "' already exists.");
                                        if (toastManager) toastManager.show(qsTr("Tag '%1' already exists!").arg(trimmedTag));
                                    } else {

                                        DB.addTag(trimmedTag);
                                        refreshTags();
                                        newTagNameInput = "";
                                        creatingNewTag = false;
                                        tagInput.forceActiveFocus(false);
                                        if (onTagsChanged) { onTagsChanged(); }
                                        if (toastManager) toastManager.show(qsTr("Tag '%1' created!").arg(trimmedTag));
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: creatingNewTag
                                onPressed: checkRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    newTagCheckItem.performCreationLogic();
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                visible: allTagsWithCounts.length > 0

                Repeater {
                    model: allTagsWithCounts
                    delegate: Item {
                        id: tagListItemDelegate
                        height: 80
                        width: parent.width

                        property string tagName: modelData.name
                        property int noteCount: modelData.count
                        property bool isEditing: tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate

                        property string editingTagName: tagName
                        property bool editingInputError: false
                        property bool isTagNameChanged: false

                        function resetEditState() {
                            editingTagName = tagName;
                            editingInputError = false;
                            isTagNameChanged = false;

                            if (tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate) {
                                tagEditPage.currentlyEditingTagDelegate = null;
                                tagEditPage.editingTagData = null;
                            }
                            console.log("Delegate reset: " + tagName);
                        }

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
                                highlighted: false
                                text: isEditing ? editingTagName : tagName
                                placeholderText: qsTr("Edit tag name")
                                font.pixelSize: Theme.fontSizeMedium
                                color: editingInputError ? Theme.errorColor : (isEditing ? Theme.highlightColor : "#e8eaed")
                                inputMethodHints: Qt.ImhNoAutoUppercase

                                focus: isEditing

                                onActiveFocusChanged: {
                                    if (activeFocus) {
                                        if (tagEditPage.currentlyEditingTagDelegate !== tagListItemDelegate) {
                                            if (tagEditPage.currentlyEditingTagDelegate) {
                                                tagEditPage.currentlyEditingTagDelegate.resetEditState();
                                            }
                                            tagEditPage.currentlyEditingTagDelegate = tagListItemDelegate;
                                            tagEditPage.editingTagData = { id: modelData.id, name: tagName, count: modelData.count };
                                            console.log("Delegate (re)gained focus, now editing:", tagName);
                                        }
                                        editingTagName = tagName;
                                        isTagNameChanged = false;
                                    } else {
                                        if (tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate) {
                                            var trimmedCurrentText = tagInputField.text.trim();
                                            var originalTagNameTrimmed = tagName.trim();

                                            if (trimmedCurrentText === "" || trimmedCurrentText === originalTagNameTrimmed) {
                                                tagListItemDelegate.resetEditState();
                                                console.log("Delegate lost focus, cancelled edit due to empty/unchanged name (no toast).");
                                            } else {
                                                tagListItemDelegate.resetEditState();
                                                if (toastManager) toastManager.show(qsTr("Edit cancelled."));
                                                console.log("Delegate lost focus, changes made but not explicitly saved. Resetting state.");
                                            }
                                        }
                                    }
                                }

                                onTextChanged: {
                                    if (isEditing) {
                                        editingTagName = text;
                                        isTagNameChanged = (editingTagName.trim() !== tagName);

                                        if (editingInputError) {
                                            editingInputError = false;
                                        }
                                    }
                                }

                                EnterKey.onClicked: {
                                    if (isEditing) {
                                        tagInputField.performSaveLogic();
                                    }
                                }

                                leftItem: Item {
                                    id: leftIconItem
                                    width: Theme.fontSizeExtraLarge * 1.1
                                    height: Theme.fontSizeExtraLarge * 1.1
                                    clip: false

                                    Icon {
                                        source: tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate ? "qrc:/qml/icons/trash.svg" : "qrc:/qml/icons/tag-white.svg"
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                    }
                                    RippleEffectComponent { id: leftRipple }
                                    MouseArea {
                                        anchors.fill: parent
                                        onPressed: leftRipple.ripple(mouseX, mouseY)
                                        onClicked: {
                                            if (tagEditPage.currentlyEditingTagDelegate === tagListItemDelegate) {
                                                DB.deleteTag(tagName);
                                                tagListItemDelegate.resetEditState();
                                                if (toastManager) toastManager.show(qsTr("Deleted tag '%1'").arg(tagName));
                                                tagEditPage.refreshTags();
                                                if (tagEditPage.onTagsChanged) { tagEditPage.onTagsChanged(); }
                                            } else {
                                                tagInputField.forceActiveFocus(true);
                                                console.log("Tag icon clicked, forcing focus to start edit.");
                                            }
                                        }
                                    }
                                }

                                rightItem: Item {
                                    id: rightIconItem
                                    width: Theme.fontSizeExtraLarge * 1.1
                                    height: Theme.fontSizeExtraLarge * 1.1
                                    clip: false

                                    Icon {
                                        source: {
                                            if (!isEditing) {
                                                return "qrc:/qml/icons/edit_filled.svg";
                                            } else {
                                                if (isTagNameChanged) {
                                                    return "qrc:/qml/icons/check.svg";
                                                } else {
                                                    return "qrc:/qml/icons/close.svg";
                                                }
                                            }
                                        }
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                    }
                                    RippleEffectComponent { id: rightRipple }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: true
                                        onPressed: rightRipple.ripple(mouseX, mouseY)
                                        onClicked: {
                                            if (isEditing) {
                                                if (isTagNameChanged) {
                                                    tagInputField.performSaveLogic();
                                                } else {
                                                    tagListItemDelegate.resetEditState();
                                                    if (toastManager) toastManager.show(qsTr("Edit cancelled."));
                                                }
                                            } else {
                                                tagInputField.forceActiveFocus(true);
                                            }
                                        }
                                    }
                                }

                                function performSaveLogic() {
                                    var trimmedEditTag = editingTagName.trim();
                                    if (trimmedEditTag === "") {
                                        editingInputError = true;
                                        if (toastManager) toastManager.show(qsTr("Tag name cannot be empty!"));
                                        return;
                                    }
                                    if (trimmedEditTag === tagName) {
                                        console.log("No change in tag name, finishing edit.");
                                        if (toastManager) toastManager.show(qsTr("Edit cancelled."));
                                        tagListItemDelegate.resetEditState();
                                        return;
                                    }

                                    var tagExists = tagEditPage.allTagsWithCounts.some(function(t) {
                                        return t.name === trimmedEditTag && t.name !== tagName;
                                    });

                                    if (tagExists) {
                                        editingInputError = true;
                                        console.log("Error: Tag '" + trimmedEditTag + "' already exists.");
                                        if (toastManager) toastManager.show(qsTr("Tag '%1' already exists!").arg(trimmedEditTag));
                                    } else {
                                        DB.updateTagName(tagName, trimmedEditTag);
                                        tagListItemDelegate.resetEditState();
                                        if (toastManager) toastManager.show(qsTr("Updated tag '%1' to '%2'").arg(tagName).arg(trimmedEditTag));
                                        tagEditPage.refreshTags();
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
    ScrollBarComponent {
        flickableSource: flickable
        topAnchorItem: headerArea
    }
    SidePanelComponent {
        id: sidePanelInstance
        open: tagEditPage.panelOpen
        onClosed: tagEditPage.panelOpen = false
    }
    ToastManagerService {
        id: toastManager
    }
}

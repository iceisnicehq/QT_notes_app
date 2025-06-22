import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "../services/DatabaseManager.js" as DB
import "../dialogs"

Page {
    id: settingsPage
    backgroundColor: settingsPage.customBackgroundColor !== undefined ? settingsPage.customBackgroundColor : "#121218"
    showNavigationIndicator: false


    property bool panelOpen: false

    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]

    readonly property var languageModel: [
        { name: qsTr("English"), code: "en" },
        { name: qsTr("Русский"), code: "ru" },
        { name: qsTr("Deutsch"), code: "de" },
        { name: qsTr("Français"), code: "fr" },
        { name: qsTr("Español"), code: "es" },
        { name: qsTr("中國人"), code: "ch" },
    ]

    property string customBackgroundColor: DB.getThemeColor() || "#121218"
    property string currentLanguageSetting: DB.getLanguage()

    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Action")
    property string confirmDialogMessage: ""
    property string confirmButtonText: qsTr("Confirm")
    property var onConfirmCallback: null
    property color confirmButtonHighlightColor: Theme.primaryColor

    property bool hasAnyNotes: false
    property bool hasNonArchivedNonDeletedNotes: false
    property bool hasNonDeletedNotes: false

    function getCurrentLanguageDisplayName() {
        var currentLangCode = DB.getLanguage() || "en";
        for (var i = 0; i < settingsPage.languageModel.length; i++) {
            if (settingsPage.languageModel[i].code === currentLangCode) {
                return settingsPage.languageModel[i].name;
            }
        }
        return "English"; // Fallback
    }

    Component.onCompleted: {
        console.log("SettingsPage opened. Initializing settings.");
        sidePanelInstance.currentPage = "settings";
        var storedColor = DB.getThemeColor();
        if (storedColor) {
            settingsPage.customBackgroundColor = storedColor;
        } else {
            DB.setThemeColor("#121218");
            settingsPage.customBackgroundColor = "#121218";
        }
        settingsPage.currentLanguageSetting = DB.getLanguage() || "en";
        updateNoteCounts();
    }

    function applyLanguageChange(newLangCode) {
        if (AppSettings.setApplicationLanguage(newLangCode)) {
            DB.setLanguage(newLangCode);
            settingsPage.currentLanguageSetting = newLangCode; // Update for getCurrentLanguageDisplayName

            toastManager.show(qsTr("Language changed to %1").arg(settingsPage.getCurrentLanguageDisplayName()));
            if (pageStack.currentPage === settingsPage) { // Ensure we are on settings page
                refreshPageStack();
                console.log("SettingsPage: Replaced current SettingsPage instance to apply language changes.");
            } else {
                // If the language was changed from somewhere else (e.g., via DB direct edit, unlikely for this UI),
                // or if it wasn't the current page, just log.
                console.log("SettingsPage: Language changed, but SettingsPage is not current page. UI will update on next visit.");
            }
            // --- END CRITICAL CHANGE ---

        } else {
            toastManager.show(qsTr("Failed to change language."));
        }
    }
    // --- END MODIFIED section ---


    function updateNoteCounts() {
        var activeNotes = DB.getAllNotes();
        var deletedNotes = DB.getDeletedNotes();
        var archivedNotes = DB.getArchivedNotes();

        settingsPage.hasAnyNotes = (activeNotes.length > 0 || deletedNotes.length > 0 || archivedNotes.length > 0);
        settingsPage.hasNonArchivedNonDeletedNotes = (activeNotes.length > 0);
        settingsPage.hasNonDeletedNotes = (activeNotes.length > 0 || archivedNotes.length > 0);

        console.log("updateNoteCounts called:");
        console.log("  hasAnyNotes:", settingsPage.hasAnyNotes);
        console.log("  hasNonArchivedNonDeletedNotes (for Archive All):", settingsPage.hasNonArchivedNonDeletedNotes);
        console.log("  hasNonDeletedNotes (for Move to Trash):", settingsPage.hasNonDeletedNotes);
    }

    function showConfirmDialog(message, callback, title, buttonText, highlightColor) {
        confirmDialogMessage = message;
        onConfirmCallback = callback;
        confirmDialogTitle = (title !== undefined) ? title : qsTr("Confirm Action");
        confirmButtonText = (buttonText !== undefined) ? buttonText : qsTr("Confirm");
        confirmButtonHighlightColor = (highlightColor !== undefined) ? highlightColor : Theme.primaryColor;
        confirmDialogVisible = true;
    }

    function refreshPageStack() {
        pageStack.clear();
        pageStack.completeAnimation();
        pageStack.push(Qt.resolvedUrl("MainPage.qml"));
        pageStack.completeAnimation();
        pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
        pageStack.completeAnimation();
    }

    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        Item {
            id: menuButton
            width: Theme.fontSizeExtraLarge * 1.1
            height: Theme.fontSizeExtraLarge * 0.95
            clip: false
            anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }

            RippleEffect { id: menuRipple }

            Icon {
                id: leftIcon
                source: "../icons/menu.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY)
                onClicked: {
                    settingsPage.panelOpen = true
                    console.log("Menu button clicked in SettingsPage → panelOpen = true")
                }
            }
        }

        Label {
            text: qsTr("Settings")
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        anchors.topMargin: pageHeader.height
        contentHeight: contentContainer.implicitHeight + Theme.paddingLarge * 2
        flickableDirection: Flickable.VerticalFlick
        clip: true

        Item {
            id: contentContainer
            width: parent.width - (2 * Theme.paddingLarge)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: Theme.paddingLarge

            Column {
                id: languageSection
                width: parent.width
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                // MODIFIED: Use anchors to center the RowLayout containing the icon and label
                RowLayout {
                    id: languageHeaderRow
                    anchors.horizontalCenter: parent.horizontalCenter // This centers THIS RowLayout within languageSection
                    spacing: Theme.paddingSmall

                    Item {
                        Layout.preferredWidth: Theme.iconSizeSmallPlus
                        Layout.preferredHeight: Theme.iconSizeSmallPlus
                        Layout.alignment: Qt.AlignVCenter

                        Icon {
                            source: "../icons/language.svg"
                            color: "white"
                            fillMode: Image.PreserveAspectFit
                            width: parent.width
                            height: parent.height
                        }
                    }

                    Label {
                        id: langlabel
                        text: qsTr("Language")
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: Theme.itemSizeLarge
                    color: DB.darkenColor(settingsPage.customBackgroundColor, 0.15)
                    radius: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter

                    RowLayout {
                        anchors.fill: parent
                        Layout.maximumWidth: parent.width
                        spacing: Theme.paddingMedium

                        Item {
                            Layout.preferredWidth: Theme.iconSizeSmallPlus
                            Layout.preferredHeight: Theme.iconSizeSmallPlus
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                            Icon {
                                source: "../icons/back.svg"
                                anchors.fill: parent
                                color: Theme.primaryColor
                                fillMode: Image.PreserveAspectFit
                            }
                            RippleEffect { id: leftArrowRipple }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: leftArrowRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    var currentIndex = -1;
                                    for (var i = 0; i < settingsPage.languageModel.length; i++) {
                                        if (settingsPage.languageModel[i].code === settingsPage.currentLanguageSetting) {
                                            currentIndex = i;
                                            break;
                                        }
                                    }
                                    var newIndex = (currentIndex - 1 + settingsPage.languageModel.length) % settingsPage.languageModel.length;
                                    var newLangCode = settingsPage.languageModel[newIndex].code;
                                    settingsPage.applyLanguageChange(newLangCode);
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            Layout.preferredHeight: parent.height
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                            text: settingsPage.getCurrentLanguageDisplayName()
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeLarge
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Item {
                            Layout.preferredWidth: Theme.iconSizeSmallPlus
                            Layout.preferredHeight: Theme.iconSizeSmallPlus
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                            Icon {
                                source: "../icons/right.svg" // сюда правую
                                anchors.fill: parent
                                color: Theme.primaryColor
                                fillMode: Image.PreserveAspectFit
                            }
                            RippleEffect { id: rightArrowRipple }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: rightArrowRipple.ripple(mouseX, mouseY)
                                onClicked: {
                                    var currentIndex = -1;
                                    for (var i = 0; i < settingsPage.languageModel.length; i++) {
                                        if (settingsPage.languageModel[i].code === settingsPage.currentLanguageSetting) {
                                            currentIndex = i;
                                            break;
                                        }
                                    }
                                    var newIndex = (currentIndex + 1) % settingsPage.languageModel.length;
                                    var newLangCode = settingsPage.languageModel[newIndex].code;
                                    settingsPage.applyLanguageChange(newLangCode);
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: spacer1
                width: parent.width
                height: Theme.paddingLarge
                anchors.top: languageSection.bottom
            }

            Column {
                id: themeColorSection
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: spacer1.bottom
                spacing: Theme.paddingMedium

                RowLayout {
                    id: themeHeaderRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingSmallPlus

                    Item {
                        Layout.preferredWidth: Theme.iconSizeSmallPlus
                        Layout.preferredHeight: Theme.iconSizeSmallPlus
                        Layout.alignment: Qt.AlignVCenter

                        Icon {
                            source: "../icons/palette.svg"
                            color: "white"
                            fillMode: Image.PreserveAspectFit
                            width: parent.width
                            height: parent.height
                        }
                    }

                    Label {
                        id: colorThemeLabel
                        text: qsTr("Theme Color")
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        color: "white"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Rectangle {
                    id: colorSelectionArea
                    width: parent.width
                    height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + (Theme.itemSizeSmall / 2) * 2
                    color: settingsPage.customBackgroundColor
                    radius: Theme.itemSizeSmall / 2

                    Column {
                        id: colorPanelContentColumn
                        width: parent.width
                        height: implicitHeight
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: Theme.paddingMedium
                        anchors.bottomMargin: Theme.paddingMedium
                        spacing: Theme.paddingMedium

                        Label {
                            id: colorTitle
                            text: qsTr("Select Theme Color")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Flow {
                            id: colorFlow
                            width: parent.width
                            spacing: Theme.paddingSmall
                            anchors.horizontalCenter: parent.horizontalCenter
                            layoutDirection: Qt.LeftToRight
                            readonly property int columns: 6
                            readonly property real itemWidth: (width - (spacing * (columns - 1))) / columns

                            Repeater {
                                model: settingsPage.colorPalette
                                delegate: Item {
                                    width: parent.itemWidth
                                    height: parent.itemWidth

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: (settingsPage.customBackgroundColor === modelData) ? DB.darkenColor(settingsPage.customBackgroundColor, -0.65) : DB.darkenColor(settingsPage.customBackgroundColor, -0.15)
                                        border.color: "transparent"
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.85
                                        height: parent.height * 0.85
                                        radius: width / 2
                                        color: modelData
                                        border.color: "transparent"

                                        Rectangle {
                                            visible: settingsPage.customBackgroundColor === modelData
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
                                                color: DB.darkenColor(settingsPage.customBackgroundColor, -0.65)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: true
                                        onClicked: {
                                            settingsPage.customBackgroundColor = modelData;
                                            DB.setThemeColor(modelData);
                                            settingsPage.applyLanguageChange(settingsPage.currentLanguageSetting);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: spacer2
                width: parent.width
                height: Theme.paddingSmall
                anchors.top: themeColorSection.bottom
            }

            Column {
                id: dataManagementSection
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: spacer2.bottom
                spacing: Theme.paddingMedium




                RowLayout {
                    id: dataHeaderRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 55

                    Item {
                        Layout.preferredWidth: Theme.iconSizeSmallPlus
                        Layout.preferredHeight: Theme.iconSizeSmallPlus
                        Layout.alignment: Qt.AlignVCenter

                        Icon {
                            source: "../icons/edit.svg"
                            color: "white"
                            fillMode: Image.PreserveAspectFit
                            width: parent.width
                            height: parent.height
                        }
                    }

                    Label {
                        id: dataManagmentLabel
                        text: qsTr("Data Management Actions")
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: "AlignHCenter"
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        color: "white"
                    }
                }

                ColumnLayout {
                    id: dataButtons
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Button {
                        id: archiveAllButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                        highlightColor: Theme.highlightColor
                        enabled: settingsPage.hasNonArchivedNonDeletedNotes
                        opacity: enabled ? 1 : 0.5
                        Column {
                            anchors.centerIn: parent
                            Label {
                                text: qsTr("Archive All Notes")
                                color: Theme.primaryColor
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: "AlignHCenter"
                            }
                        }
                        onClicked: {
                            console.log("Archive all notes clicked");
                            settingsPage.showConfirmDialog(
                                qsTr("Are you sure you want to archive all your notes?"),
                                function() {
                                    DB.archiveAllNotes();
                                    settingsPage.updateNoteCounts();
                                    settingsPage.applyLanguageChange(settingsPage.currentLanguageSetting);
                                },
                                qsTr("Confirm Archive"),
                                qsTr("Archive All"),
                                Theme.highlightColor
                            );
                        }
                    }

                    Button {
                        id: moveAllToTrashButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                        highlightColor: Theme.highlightColor
                        enabled: settingsPage.hasNonDeletedNotes
                        opacity: enabled ? 1 : 0.5
                        Column {
                            anchors.centerIn: parent
                            Label {
                                text: qsTr("Move All Notes to Trash")
                                color: Theme.primaryColor
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: "AlignHCenter"
                            }
                        }
                        onClicked: {
                            console.log("Move all notes to trash clicked");
                            settingsPage.showConfirmDialog(
                                qsTr("Are you sure you want to move all your notes to trash?"),
                                function() {
                                    DB.moveAllNotesToTrash();
                                    settingsPage.updateNoteCounts();
                                    settingsPage.applyLanguageChange(settingsPage.currentLanguageSetting);
                                },
                                qsTr("Confirm Move to Trash"),
                                qsTr("Move to Trash"),
                                Theme.highlightColor
                            );
                        }
                    }

                    Button {
                        id: permanentDeleteButton
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                        backgroundColor: "#A03030"
                        highlightColor: Theme.errorColor
                        enabled: settingsPage.hasAnyNotes
                        opacity: enabled ? 1 : 0.5

                        Column {
                            anchors.centerIn: parent
                            Label {
                                text: qsTr("Permanently Delete All Notes")
                                color: "white"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                horizontalAlignment: "AlignHCenter"
                            }
                        }
                        onClicked: {
                            console.log("Permanently delete all notes clicked");
                            settingsPage.showConfirmDialog(
                                qsTr("Are you sure you want to permanently delete ALL your notes and associated tags? This action cannot be undone."),
                                function() {
                                    DB.permanentlyDeleteAllNotes();
                                    settingsPage.updateNoteCounts();
                                    settingsPage.applyLanguageChange(settingsPage.currentLanguageSetting);
                                },
                                qsTr("Confirm Permanent Deletion"),
                                qsTr("Delete"),
                                Theme.errorColor
                            );
                        }
                    }
                }
            }

        }
    }

    ToastManager {
        id: toastManager
    }

    ConfirmDialog {
        id: confirmDialogInstance
        dialogVisible: settingsPage.confirmDialogVisible
        dialogTitle: settingsPage.confirmDialogTitle
        dialogMessage: settingsPage.confirmDialogMessage
        confirmButtonText: settingsPage.confirmButtonText
        confirmButtonHighlightColor: settingsPage.confirmButtonHighlightColor
        dialogBackgroundColor: DB.darkenColor(settingsPage.customBackgroundColor, 0.30)
        onConfirmed: {
            if (settingsPage.onConfirmCallback) {
                settingsPage.onConfirmCallback();
            }
            settingsPage.confirmDialogVisible = false;
        }
        onCancelled: {
            settingsPage.confirmDialogVisible = false;
            console.log("Action cancelled by user.");
        }
    }

    SidePanel {
        id: sidePanelInstance
        open: settingsPage.panelOpen
        onClosed: settingsPage.panelOpen = false
        Component.onCompleted: sidePanelInstance.currentPage = "settings";
        customBackgroundColor:  DB.darkenColor(settingsPage.customBackgroundColor, 0.30)
        activeSectionColor: settingsPage.customBackgroundColor
    }
}

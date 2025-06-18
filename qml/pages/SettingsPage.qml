// qml/pages/SettingsPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB // Import DatabaseManager

Page {
    id: settingsPage
    // Dynamically adapt background color based on custom setting or default
    backgroundColor: settingsPage.customBackgroundColor !== undefined ? settingsPage.customBackgroundColor : "#121218"
    showNavigationIndicator: false

    // Controls side panel visibility
    property bool panelOpen: false

    // Predefined color palette for theme selection
    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]

    // Holds the currently selected custom background color, loaded from DB
    property string customBackgroundColor: DB.getThemeColor() || "#121218"

    // Updates to reflect the current language setting for highlighting
    property string currentLanguageSetting: DB.getLanguage()

    // Properties for controlling the confirmation dialog
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Action")
    property string confirmDialogMessage: ""
    property string confirmButtonText: qsTr("Confirm")
    property var onConfirmCallback: null
    property color confirmButtonHighlightColor: Theme.primaryColor

    // Properties for dynamic button enablement based on note counts
    property bool hasAnyNotes: false
    property bool hasNonArchivedNonDeletedNotes: false
    property bool hasNonDeletedNotes: false

    Component.onCompleted: {
        console.log("SettingsPage opened. Initializing settings.");
        sidePanelInstance.currentPage = "settings"; // Highlight 'settings' in the side panel

        // Load and apply initial custom background color from database
        var storedColor = DB.getThemeColor();
        if (storedColor) {
            settingsPage.customBackgroundColor = storedColor;
        } else {
            // Set and save a default color if none is found
            DB.setThemeColor("#121218");
            settingsPage.customBackgroundColor = "#121218";
        }

        // Update current language setting for UI highlighting
        settingsPage.currentLanguageSetting = DB.getLanguage();

        // Refresh button enablement states
        updateNoteCounts();
    }

    // Updates boolean properties that control button enablement based on note counts
    function updateNoteCounts() {
        var activeNotes = DB.getAllNotes(); // Notes that are not deleted and not archived
        var deletedNotes = DB.getDeletedNotes(); // Notes that are deleted
        var archivedNotes = DB.getArchivedNotes(); // Notes that are archived

        settingsPage.hasAnyNotes = (activeNotes.length > 0 || deletedNotes.length > 0 || archivedNotes.length > 0);
        settingsPage.hasNonArchivedNonDeletedNotes = (activeNotes.length > 0);
        settingsPage.hasNonDeletedNotes = (activeNotes.length > 0 || archivedNotes.length > 0);

        console.log("updateNoteCounts called:");
        console.log("  hasAnyNotes:", settingsPage.hasAnyNotes);
        console.log("  hasNonArchivedNonDeletedNotes (for Archive All):", settingsPage.hasNonArchivedNonDeletedNotes);
        console.log("  hasNonDeletedNotes (for Move to Trash):", settingsPage.hasNonDeletedNotes);
    }

    // Displays a confirmation dialog with a customizable message and callback
    function showConfirmDialog(message, callback, title, buttonText, highlightColor) {
        confirmDialogMessage = message;
        onConfirmCallback = callback;
        confirmDialogTitle = (title !== undefined) ? title : qsTr("Confirm Action");
        confirmButtonText = (buttonText !== undefined) ? buttonText : qsTr("Confirm");
        confirmButtonHighlightColor = (highlightColor !== undefined) ? highlightColor : Theme.primaryColor;
        confirmDialogVisible = true;
    }

    // Clears the page stack and navigates back to MainPage, then SettingsPage
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

        // Menu icon button to open the side panel
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

    // Allows content to be scrolled if it overflows
    SilicaFlickable {
        anchors.fill: parent
        anchors.topMargin: pageHeader.height
        contentHeight: contentLayout.implicitHeight
        flickableDirection: Flickable.VerticalFlick
        clip: true
        // Layout for all page content
        ColumnLayout {
            id: contentLayout
            anchors.margins: Theme.paddingLarge
            spacing: Theme.paddingMedium
            width: parent.width - (2 * Theme.paddingLarge)
            anchors.horizontalCenter: parent.horizontalCenter

            // Language section header
            Label {
                text: qsTr("Language")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white"
            }

            RowLayout { // Horizontal arrangement for language selection buttons
                Layout.fillWidth: true
                spacing: Theme.paddingSmall
                // Button for Russian language selection
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    Layout.preferredWidth: parent.width / 2 - (parent.spacing / 2)
                    backgroundColor: Theme.rgba(Theme.primaryColor, 0.1)

                    Column {
                        anchors.centerIn: parent
                        Label {
                            text: qsTr("Russian")
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: settingsPage.currentLanguageSetting === "ru"
                            color: (settingsPage.currentLanguageSetting === "ru") ? DB.darkenColor(settingsPage.customBackgroundColor, -0.80) : DB.darkenColor(settingsPage.customBackgroundColor, -0.50)
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    onClicked: {
                        console.log("Selected language: Russian");
                        if (AppSettings.setApplicationLanguage("ru")) {
                            DB.setLanguage("ru");
                            settingsPage.currentLanguageSetting = "ru";
                            toastManager.show(qsTr("Language changed to Russian"));
                            settingsPage.refreshPageStack();
                        } else {
                            toastManager.show(qsTr("Failed to change language."));
                        }
                    }
                }

                // Button for English language selection
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    Layout.preferredWidth: parent.width / 2 - (parent.spacing / 2)
                    backgroundColor: Theme.rgba(Theme.primaryColor, 0.1)

                    Column {
                        anchors.centerIn: parent
                        Label {
                            text: qsTr("English")
                            color: (settingsPage.currentLanguageSetting === "en") ? DB.darkenColor(settingsPage.customBackgroundColor, -0.80) : DB.darkenColor(settingsPage.customBackgroundColor, -0.50)
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: settingsPage.currentLanguageSetting === "en"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }


                    onClicked: {
                        console.log("Selected language: English");
                        if (AppSettings.setApplicationLanguage("en")) {
                            DB.setLanguage("en");
                            settingsPage.currentLanguageSetting = "en";
                            toastManager.show(qsTr("Language changed to English"));
                            settingsPage.refreshPageStack();
                        } else {
                            toastManager.show(qsTr("Failed to change language."));
                        }
                    }
                }
            }

            // Spacer
            Item {
                Layout.preferredHeight: Theme.paddingLarge
                Layout.fillWidth: true
            }

            // Theme Color section header
            Label {
                text: qsTr("Theme Color")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white"
            }

            // Area for color selection
            Rectangle {
                id: colorSelectionArea
                Layout.fillWidth: true
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

                        // Repeater to generate color selection circles
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

                                    // Checkmark for the currently selected color
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
                                        settingsPage.refreshPageStack();
                                    }
                                }
                            }
                        }
                    }
                }
            }


            // Data Management Actions section header
            Label {
                id: dataManagmentLabel
                text: qsTr("Data Management Actions")
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 15
                anchors.topMargin: 30
                anchors.bottom: colorSelectionArea.bottom
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white"
            }
            // Column for data management buttons
            ColumnLayout {
                id: dataButtons
                Layout.fillWidth: true
                spacing: Theme.paddingSmall
                anchors.top: dataManagmentLabel.bottom
                anchors.topMargin: 20

                // Button for archiving all notes
                Button {
                    id: archiveAllButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    highlightColor: Theme.highlightColor
                    enabled: settingsPage.hasNonArchivedNonDeletedNotes // Enabled if there are notes to archive
                    opacity: enabled ? 1 : 0.5 // Dim if disabled
                    Column {
                        anchors.centerIn: parent
                        Label {
                            text: qsTr("Archive All Notes")
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    onClicked: {
                        console.log("Archive all notes clicked");
                        settingsPage.showConfirmDialog(
                            qsTr("Are you sure you want to archive all your notes?"),
                            function() {
                                DB.archiveAllNotes();
                                settingsPage.updateNoteCounts(); // Refresh note counts after action
                                settingsPage.refreshPageStack();
                            },
                            qsTr("Confirm Archive"),
                            qsTr("Archive All"),
                            Theme.highlightColor
                        );

                    }
                }

                // Button for moving all notes to trash
                Button {
                    id: moveAllToTrashButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    highlightColor: Theme.highlightColor
                    enabled: settingsPage.hasNonDeletedNotes // Enabled if there are notes not yet in trash
                    opacity: enabled ? 1 : 0.5 // Dim if disabled
                    Column {
                        anchors.centerIn: parent
                        Label {
                            text: qsTr("Move All Notes to Trash")
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    onClicked: {
                        console.log("Move all notes to trash clicked");
                        settingsPage.showConfirmDialog(
                            qsTr("Are you sure you want to move all your notes to trash?"),
                            function() {
                                DB.moveAllNotesToTrash();
                                settingsPage.updateNoteCounts(); // Refresh note counts after action
                                settingsPage.refreshPageStack();
                            },
                            qsTr("Confirm Move to Trash"),
                            qsTr("Move to Trash"),
                            Theme.highlightColor
                        );
                    }
                }

                // Button for permanently deleting all notes
                Button {
                    id: permanentDeleteButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    backgroundColor: "#A03030" // Red color for destructive action
                    highlightColor: Theme.errorColor
                    enabled: settingsPage.hasAnyNotes // Enabled if any notes exist
                    opacity: enabled ? 1 : 0.5 // Dim if disabled

                    Column {
                        anchors.centerIn: parent
                        Label {
                            text: qsTr("Permanently Delete All Notes")
                            color: "white"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    onClicked: {
                        console.log("Permanently delete all notes clicked");
                        settingsPage.showConfirmDialog(
                            qsTr("Are you sure you want to permanently delete ALL your notes and associated tags? This action cannot be undone."),
                            function() {
                                DB.permanentlyDeleteAllNotes();
                                settingsPage.updateNoteCounts(); // Refresh note counts after action
                                settingsPage.refreshPageStack();
                            },
                            qsTr("Confirm Permanent Deletion"),
                            qsTr("Delete"),
                            Theme.errorColor // Use error color for the confirm button in the dialog
                        );
                    }
                }
            }
        }
    }

    ToastManager {
        id: toastManager
    }

    // Integrated Confirmation Dialog Component
    ConfirmDialog {
        id: confirmDialogInstance
        // Bind properties from settingsPage to ConfirmDialog
        dialogVisible: settingsPage.confirmDialogVisible
        dialogTitle: settingsPage.confirmDialogTitle
        dialogMessage: settingsPage.confirmDialogMessage
        confirmButtonText: settingsPage.confirmButtonText
        confirmButtonHighlightColor: settingsPage.confirmButtonHighlightColor
        dialogBackgroundColor: DB.darkenColor(settingsPage.customBackgroundColor, 0.30)
        // Connect signals from ConfirmDialog back to settingsPage's logic
        onConfirmed: {
            if (settingsPage.onConfirmCallback) {
                settingsPage.onConfirmCallback(); // Execute the stored callback
            }

            settingsPage.confirmDialogVisible = false; // Hide the dialog after confirmation
        }
        onCancelled: {
            settingsPage.confirmDialogVisible = false; // Hide the dialog
            console.log(qsTr("Action cancelled by user."));
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

// qml/pages/SettingsPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB // Import DatabaseManager

Page {
    id: settingsPage
    // The background color will dynamically adapt based on the active theme
    // It will now primarily be driven by customBackgroundColor or default
    backgroundColor: settingsPage.customBackgroundColor !== undefined ? settingsPage.customBackgroundColor : "#121218" // Fallback to Theme.backgroundColor if custom is not set
    showNavigationIndicator: false

    // Property to control side panel visibility, similar to ArchivePage
    property bool panelOpen: false

    // --- NEW: Theme Color Palette and Custom Color Property ---
    // The predefined color palette for the color picker
    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]

    // Property to hold the currently selected custom background color
    property string customBackgroundColor: DB.getThemeColor() || "#121218" // Load from DB, default to a dark color if not found

    // --- Language Highlighting Property ---
    // This property will be updated to ensure the language selection highlights reactively.
    property string currentLanguageSetting: DB.getLanguage() // Initialize from DB

    // --- NEW: Data Management Statistics Properties (kept for data management actions, even if not displayed) ---
    property string lastExportDate: ""
    property int notesExportedCount: 0
    property string lastImportDate: ""
    property int notesImportedCount: 0

    // --- NEW: Properties for Confirmation Dialog ---
    property bool confirmDialogVisible: false
    property string confirmDialogTitle: qsTr("Confirm Action") // Default title
    property string confirmDialogMessage: "" // Message for the dialog
    property string confirmButtonText: qsTr("Confirm") // Default button text
    property var onConfirmCallback: null // Callback function to execute on confirm
    property color confirmButtonHighlightColor: Theme.primaryColor // Default highlight color for confirm button

    Component.onCompleted: {
        console.log("SettingsPage opened. Initializing settings and statistics.");
        sidePanelInstance.currentPage = "settings"; // Highlight 'settings' in the side panel

        // Load initial custom background color from DB
        var storedColor = DB.getThemeColor();
        if (storedColor) {
            settingsPage.customBackgroundColor = storedColor;
            // When the page loads, ensure the global Theme.backgroundColor is also updated
            // if AppSettings (C++) manages global theme changes based on DB.getThemeColor()
            // This part assumes C++ side observes changes in DB or AppSettings property.
            // For immediate QML effect on this page, it's already bound above.
            // If other pages are to react to this, they also need to bind their background.
        } else {
            // If no custom color is set, ensure a default is used and saved
            DB.setThemeColor("#121218"); // Set initial default
            settingsPage.customBackgroundColor = "#121218";
        }

        // Ensure current language setting is updated on page load for highlighting
        settingsPage.currentLanguageSetting = DB.getLanguage();

        // Load data management statistics (still called, but no longer displayed)
        updateDataManagementStats();
    }

    function updateDataManagementStats() {
        // Retrieve values from DB and update properties (properties are kept for potential future use or debugging, even if not displayed)
        settingsPage.lastExportDate = DB.getSetting('lastExportDate') || qsTr("N/A");
        settingsPage.notesExportedCount = DB.getSetting('notesExportedCount') || 0;
        settingsPage.lastImportDate = DB.getSetting('lastImportDate') || qsTr("N/A");
        settingsPage.notesImportedCount = DB.getSetting('notesImportedCount') || 0;
    }

    // Function to show the confirmation dialog dynamically
    function showConfirmDialog(message, callback, title, buttonText, highlightColor) {
        confirmDialogMessage = message; // Set the message for the dialog
        onConfirmCallback = callback;   // Set the callback function
        if (title !== undefined) confirmDialogTitle = title; // Override default title if provided
        else confirmDialogTitle = qsTr("Confirm Action"); // Reset to default if not provided

        if (buttonText !== undefined) confirmButtonText = buttonText; // Override default button text if provided
        else confirmButtonText = qsTr("Confirm"); // Reset to default if not provided

        if (highlightColor !== undefined) confirmButtonHighlightColor = highlightColor; // Override default highlight color
        else confirmButtonHighlightColor = Theme.primaryColor; // Reset to default if not provided

        confirmDialogVisible = true; // Make the dialog visible
    }


    PageHeader {
        id: pageHeader
        height: Theme.itemSizeExtraLarge

        // Menu icon button, copied from ArchivePage for consistent styling
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
                source: "../icons/menu.svg" // Always menu icon for settings page
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                color: Theme.primaryColor // Ensured primary color for consistency
            }

            MouseArea {
                anchors.fill: parent
                onPressed: menuRipple.ripple(mouseX, mouseY)
                onClicked: {
                    settingsPage.panelOpen = true // Open the side panel
                    console.log("Menu button clicked in SettingsPage → panelOpen = true")
                }
            }
        }

        Label {
            text: qsTr("Settings") // Page title, translatable
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
    }

    // Flickable for broader compatibility and scrollability
    SilicaFlickable {
        anchors.fill: parent
        anchors.topMargin: pageHeader.height // Only top margin, side margins handled by contentLayout
        contentHeight: contentLayout.implicitHeight // Ensure Flickable can scroll the full content height
        flickableDirection: Flickable.VerticalFlick // Only allow vertical scrolling
        clip: true
        // The content of the Flickable, organized in a ColumnLayout
        ColumnLayout {
            id: contentLayout // Added ID to reference its implicitHeight
            anchors.margins: Theme.paddingLarge // General margins for the content
            spacing: Theme.paddingMedium // Spacing between sections and elements
            width: parent.width - (2 * Theme.paddingLarge) // Ensure content fills Flickable width, accounting for margins
            anchors.horizontalCenter: parent.horizontalCenter // Center the column within the flickable

            // --- Language Section Header (Now a Label and centered) ---
            Label {
                text: qsTr("Language") // Section header for language selection
                anchors.horizontalCenter: parent.horizontalCenter // Centered
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true // Make it bold like a header
                color: "white" // Consistent header color
            }

            RowLayout { // Use RowLayout for horizontal arrangement
                Layout.fillWidth: true
                spacing: Theme.paddingSmall // Spacing between buttons in the row
                // Button for Russian language selection, styled consistently
                Button {
                    Layout.fillWidth: true // Allow button to fill available width in the row
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    Layout.preferredWidth: parent.width / 2 - (parent.spacing / 2) // Distribute width evenly
                    // Background color is now static, removing the highlight effect
                    backgroundColor: Theme.rgba(Theme.primaryColor, 0.1)

                    Column {
                        anchors.centerIn: parent
                        Label {
                            text: qsTr("Russian")
                            // Text color is now static, removing the highlight effect
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
                            settingsPage.currentLanguageSetting = "ru"; // Update the QML property to trigger highlighting
                            toastManager.show(qsTr("Language changed to Russian"));
                            pageStack.clear();
                            pageStack.completeAnimation();
                            pageStack.push(Qt.resolvedUrl("MainPage.qml"));
                            pageStack.completeAnimation();
                            pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
                            pageStack.completeAnimation();
                        } else {
                            toastManager.show(qsTr("Failed to change language."));
                        }
                    }
                }

                // Button for English language selection, styled consistently
                Button {
                    Layout.fillWidth: true // Allow button to fill available width in the row
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    Layout.preferredWidth: parent.width / 2 - (parent.spacing / 2) // Distribute width evenly
                    // Background color is now static, removing the highlight effect
                    backgroundColor: Theme.rgba(Theme.primaryColor, 0.1)

                    Column {
                        anchors.centerIn: parent
                        Label {
                            text: qsTr("English")
                            // Text color is now static, removing the highlight effect
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
                            settingsPage.currentLanguageSetting = "en"; // Update the QML property to trigger highlighting
                            toastManager.show(qsTr("Language changed to English"));
                            pageStack.clear();
                            pageStack.completeAnimation();
                            pageStack.push(Qt.resolvedUrl("MainPage.qml"));
                            pageStack.completeAnimation();
                            pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
                            pageStack.completeAnimation();
                        } else {
                            toastManager.show(qsTr("Failed to change language."));
                        }
                    }
                }
            }

            // --- Spacer before Theme Color Section ---
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2 // Maintain consistent spacing
                Layout.fillWidth: true
            }

            // --- Theme Color Section Header (Now a Label and centered) ---
            Label {
                text: qsTr("Theme Color")
                anchors.horizontalCenter: parent.horizontalCenter // Centered
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium // Match other headers
                font.bold: true // Ensure it looks like a header
                color: "white" // Consistent header color
            }

            // --- Integrated Color Selection Area ---
            Rectangle {
                id: colorSelectionArea
                Layout.fillWidth: true // Make it fill the width of the ColumnLayout
                // Calculate height based on its content dynamically
                height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + (Theme.itemSizeSmall / 2) * 2 // panelRadius equivalent
                color: settingsPage.customBackgroundColor // Background color of the selection area itself
                radius: Theme.itemSizeSmall / 2 // Rounded corners for the area itself

                Column {
                    id: colorPanelContentColumn
                    width: parent.width // Fill the width of colorSelectionArea
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
                        color: Theme.secondaryColor // This was already Theme.highlightColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Flow {
                        id: colorFlow
                        width: parent.width // Account for internal padding
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
                                        // No panel to hide anymore as it's integrated
                                        pageStack.clear();
                                        pageStack.completeAnimation();
                                        pageStack.push(Qt.resolvedUrl("MainPage.qml"));
                                        pageStack.completeAnimation();
                                        pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
                                        pageStack.completeAnimation();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- Spacer before Data Management Actions Section ---
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2 // Maintain consistent spacing
                Layout.fillWidth: true
            }


            Label {
                text: qsTr("Data Management Actions")
                anchors.horizontalCenter: parent.horizontalCenter // Centered
                anchors.bottomMargin: 15
                anchors.bottom: dataButtons.top
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium // Match other headers
                font.bold: true // Ensure it looks like a header
                color: "white" // Consistent header color
            }
            // --- Column for Data Management Buttons ---
            ColumnLayout {
                id: dataButtons
                Layout.fillWidth: true
                spacing: Theme.paddingSmall // Spacing between buttons within this column
                anchors.top: colorSelectionArea.bottom
                anchors.bottomMargin: 20
                // Button for archiving all notes
                // --- Data Management Actions Section Header (Now a Label and centered) ---

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    highlightColor: Theme.highlightColor // Retain highlight color for press effect
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
                                toastManager.show(qsTr("All eligible notes archived."));
                            },
                            qsTr("Confirm Archive"),
                            qsTr("Archive All"),
                            Theme.highlightColor
                        );
                    }
                }

                // Button for moving all notes to trash
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    highlightColor: Theme.highlightColor // Retain highlight color for press effect
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
                                toastManager.show(qsTr("All eligible notes moved to trash."));
                            },
                            qsTr("Confirm Move to Trash"),
                            qsTr("Move to Trash"),
                            Theme.highlightColor
                        );
                    }
                }

                // Button for permanently deleting all notes (RED)
                Button {
                    id: permanentDeleteButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                    backgroundColor: "#A03030" // Red color for destructive action
                    highlightColor: Theme.errorColor // Use error color for highlight effect on press

                    Column {
                        anchors.centerIn: parent
                        Label {
                            text: qsTr("Permanently Delete All Notes")
                            color: "white" // White text for better contrast on red background
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
                                // After deletion, notes count becomes 0, so update stats.
                                settingsPage.lastExportDate = qsTr("N/A");
                                settingsPage.notesExportedCount = 0;
                                settingsPage.lastImportDate = qsTr("N/A");
                                settingsPage.notesImportedCount = 0;
                                toastManager.show(qsTr("All notes and associated tags permanently deleted!"));
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

    // --- Integrated Confirmation Dialog Component ---
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

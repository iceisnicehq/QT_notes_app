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
    backgroundColor: settingsPage.customBackgroundColor !== undefined ? settingsPage.customBackgroundColor : Theme.backgroundColor // Fallback to Theme.backgroundColor if custom is not set
    showNavigationIndicator: false

    // Property to control side panel visibility, similar to ArchivePage
    property bool panelOpen: false

    // --- NEW: Theme Color Palette and Custom Color Property ---
    // The predefined color palette for the color picker
    readonly property var colorPalette: ["#121218", "#1c1d29", "#3a2c2c", "#2c3a2c", "#2c2c3a", "#3a3a2c",
        "#43484e", "#5c4b37", "#3e4a52", "#503232", "#325032", "#323250"]

    // Property to hold the currently selected custom background color
    property string customBackgroundColor: DB.getThemeColor() || "#121218" // Load from DB, default to a dark color if not found

    // --- NEW: Data Management Statistics Properties ---
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


        // Load data management statistics
        updateDataManagementStats();
    }

    function updateDataManagementStats() {
        // Retrieve values from DB and update properties
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
    Flickable {
        anchors.fill: parent
        anchors.topMargin: pageHeader.height
        contentHeight: contentLayout.implicitHeight // Ensure Flickable can scroll the full content height
        flickableDirection: Flickable.VerticalFlick // Only allow vertical scrolling

        // The content of the Flickable, organized in a ColumnLayout
        ColumnLayout {
            id: contentLayout // Added ID to reference its implicitHeight
            anchors.margins: Theme.paddingLarge // General margins for the content
            spacing: Theme.paddingMedium // Spacing between sections and elements
            width: parent.width - (2 * Theme.paddingLarge) // Ensure content fills Flickable width, accounting for margins

            // --- Language Section ---
            SectionHeader {
                text: qsTr("Language") // Section header for language selection
            }

            // Button for Russian language selection, styled consistently
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Label {
                        text: qsTr("Russian")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                highlighted: AppSettings.currentLanguage === "ru"

                onClicked: {
                    console.log("Selected language: Russian");
                    if (AppSettings.setApplicationLanguage("ru")) {
                        DB.setLanguage("ru");
                        toastManager.show(qsTr("Language changed to Russian"));
                        pageStack.pop();
                    } else {
                        toastManager.show(qsTr("Failed to change language."));
                    }
                }
            }

            // Button for English language selection, styled consistently
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Label {
                        text: qsTr("English")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                highlighted: AppSettings.currentLanguage === "en"

                onClicked: {
                    console.log("Selected language: English");
                    if (AppSettings.setApplicationLanguage("en")) {
                        DB.setLanguage("en");
                        toastManager.show(qsTr("Language changed to English"));
                        pageStack.pop();
                    } else {
                        toastManager.show(qsTr("Failed to change language."));
                    }
                }
            }

            // --- Theme Color Section ---
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2
                Layout.fillWidth: true
            }
            SectionHeader {
                text: qsTr("Theme Color")
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Label {
                        text: qsTr("Dark Theme")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                highlighted: AppSettings.currentTheme === "dark"

                onClicked: {
                    console.log("Selected theme: Dark");
                    if (AppSettings.setApplicationTheme("dark")) {
                        DB.setThemeColor(Theme.backgroundColor);
                        settingsPage.customBackgroundColor = Theme.backgroundColor;
                        toastManager.show(qsTr("Theme changed to Dark"));
                    } else {
                        toastManager.show(qsTr("Failed to change theme."));
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Label {
                        text: qsTr("Light Theme")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                highlighted: AppSettings.currentTheme === "light"

                onClicked: {
                    console.log("Selected theme: Light");
                    if (AppSettings.setApplicationTheme("light")) {
                        DB.setThemeColor(Theme.backgroundColor);
                        settingsPage.customBackgroundColor = Theme.backgroundColor;
                        toastManager.show(qsTr("Theme changed to Light"));
                    } else {
                        toastManager.show(qsTr("Failed to change theme."));
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                highlightColor: Theme.highlightColor

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Rectangle {
                        width: Theme.iconSizeSmall * 0.9
                        height: Theme.iconSizeSmall * 0.9
                        radius: width / 2
                        color: settingsPage.customBackgroundColor
                        border.color: Theme.primaryColor
                        border.width: Theme.borderWidthSmall
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Label {
                        text: qsTr("Custom Background Color")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    colorSelectionPanel.opacity = 1;
                }
            }


            // --- Data Management Section (Import/Export) ---
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2
                Layout.fillWidth: true
            }
            SectionHeader {
                text: qsTr("Data Management")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.paddingSmall
                Label {
                    text: qsTr("Last Export:") + " " + settingsPage.lastExportDate
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
                Label {
                    text: qsTr("Notes Exported:") + " " + settingsPage.notesExportedCount
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny

                    Item {
                        width: Theme.fontSizeExtraLarge * 0.8
                        height: Theme.fontSizeExtraLarge * 0.8
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/export.svg"
                            anchors.fill: parent
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: qsTr("Export Notes")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    console.log("Export notes clicked");
                    if (AppSettings.exportNotes()) {
                        var dummyCount = DB.getAllNotes().length;
                        DB.updateLastExportDate();
                        DB.updateNotesExportedCount(dummyCount);
                        updateDataManagementStats();
                        toastManager.show(qsTr("Notes exported successfully!"));
                    } else {
                        toastManager.show(qsTr("Failed to export notes."));
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.paddingSmall
                Label {
                    text: qsTr("Last Import:") + " " + settingsPage.lastImportDate
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
                Label {
                    text: qsTr("Notes Imported:") + " " + settingsPage.notesImportedCount
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny

                    Item {
                        width: Theme.fontSizeExtraLarge * 0.8
                        height: Theme.fontSizeExtraLarge * 0.8
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/import.svg"
                            anchors.fill: parent
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: qsTr("Import Notes")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    console.log("Import notes clicked");
                    if (AppSettings.importNotes()) {
                        var dummyCount = 5;
                        DB.updateLastImportDate();
                        DB.updateNotesImportedCount(dummyCount);
                        updateDataManagementStats();
                        toastManager.show(qsTr("Notes imported successfully!"));
                    } else {
                        toastManager.show(qsTr("Failed to import notes."));
                    }
                }
            }

            // --- Data Management Actions Section ---
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2
                Layout.fillWidth: true
            }
            SectionHeader {
                text: qsTr("Data Management Actions")
            }

            // Button for archiving all notes
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall * 0.9
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
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
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
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
                highlightColor: Theme.errorColor // Use error color for highlight

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
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
                        qsTr("Delete Permanently"),
                        Theme.errorColor // Use error color for the confirm button in the dialog
                    );
                }
            }
        }
    }

    ToastManager {
        id: toastManager
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
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        z: 12
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
            color: settingsPage.customBackgroundColor
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
                    text: qsTr("Select Theme Color")
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.highlightColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Flow {
                    id: colorFlow
                    width: parent.width - (2 * Theme.paddingLarge)
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
                                color: (settingsPage.customBackgroundColor === modelData) ? Theme.highlightColor : "#707070"
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
                                        color: Qt.darker(settingsPage.customBackgroundColor, 1.2)
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: true
                                onClicked: {
                                    settingsPage.customBackgroundColor = modelData;
                                    DB.setThemeColor(modelData);
                                    colorSelectionPanel.opacity = 0;
                                }
                            }
                        }
                    }
                }
            }
        }
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
    }
}

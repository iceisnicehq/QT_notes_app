// qml/pages/SettingsPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
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
                Layout.preferredHeight: Theme.buttonHeightSmall // Consistent button height
                highlightColor: Theme.highlightColor // Consistent highlight color
                // Inner Column to stack Label for consistent styling
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny // Small spacing for consistent look
                    Label {
                        text: qsTr("Russian") // Button text, translatable
                        color: Theme.primaryColor // Consistent text color
                        font.pixelSize: Theme.fontSizeSmall // Consistent font size
                        horizontalAlignment: Text.AlignHCenter // Center text
                    }
                }
                // Set highlight if current language is Russian
                highlighted: AppSettings.currentLanguage === "ru"

                onClicked: {
                    console.log("Selected language: Russian");
                    if (AppSettings.setApplicationLanguage("ru")) {
                        DB.setLanguage("ru"); // Save language to DB
                        toastManager.show(qsTr("Language changed to Russian"));
                        pageStack.pop(); // Return to previous page after language change
                    } else {
                        toastManager.show(qsTr("Failed to change language."));
                    }
                }
            }

            // Button for English language selection, styled consistently
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall
                highlightColor: Theme.highlightColor
                // Inner Column to stack Label for consistent styling
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Label {
                        text: qsTr("English") // Button text, translatable
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                // Set highlight if current language is English
                highlighted: AppSettings.currentLanguage === "en"

                onClicked: {
                    console.log("Selected language: English");
                    if (AppSettings.setApplicationLanguage("en")) {
                        DB.setLanguage("en"); // Save language to DB
                        toastManager.show(qsTr("Language changed to English"));
                        pageStack.pop(); // Return to previous page after language change
                    } else {
                        toastManager.show(qsTr("Failed to change language."));
                    }
                }
            }

            // --- Theme Color Section ---
            // Spacer Item for vertical separation instead of Layout.topMargin on SectionHeader
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2 // Increase height for better visual separation
                Layout.fillWidth: true // Ensures the item is recognized by the layout
            }
            SectionHeader {
                text: qsTr("Theme Color") // Section header for theme color selection
            }

            // Button for Dark Theme selection, styled consistently
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall
                highlightColor: Theme.highlightColor
                Column { // Inner Column to stack Label for consistent styling
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Label {
                        text: qsTr("Dark Theme") // Button text, translatable
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                highlighted: AppSettings.currentTheme === "dark" // Highlight if "dark" theme is active

                onClicked: {
                    console.log("Selected theme: Dark");
                    if (AppSettings.setApplicationTheme("dark")) {
                        DB.setThemeColor(Theme.backgroundColor); // Save current Theme.backgroundColor to DB
                        settingsPage.customBackgroundColor = Theme.backgroundColor; // Update QML property
                        toastManager.show(qsTr("Theme changed to Dark"));
                    } else {
                        toastManager.show(qsTr("Failed to change theme."));
                    }
                }
            }

            // Button for Light Theme selection, styled consistently
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall
                highlightColor: Theme.highlightColor
                Column { // Inner Column to stack Label for consistent styling
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Label {
                        text: qsTr("Light Theme") // Button text, translatable
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                highlighted: AppSettings.currentTheme === "light" // Highlight if "light" theme is active

                onClicked: {
                    console.log("Selected theme: Light");
                    if (AppSettings.setApplicationTheme("light")) {
                        DB.setThemeColor(Theme.backgroundColor); // Save current Theme.backgroundColor to DB
                        settingsPage.customBackgroundColor = Theme.backgroundColor; // Update QML property
                        toastManager.show(qsTr("Theme changed to Light"));
                    } else {
                        toastManager.show(qsTr("Failed to change theme."));
                    }
                }
            }

            // Button to open the custom color picker panel
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall
                highlightColor: Theme.highlightColor

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny
                    Rectangle { // Visual representation of the current custom color
                        width: Theme.iconSizeSmall
                        height: Theme.iconSizeSmall
                        radius: width / 2
                        color: settingsPage.customBackgroundColor
                        border.color: Theme.primaryColor // Border to make it visible against similar backgrounds
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
                    colorSelectionPanel.opacity = 1; // Make color selection panel visible
                }
            }


            // --- Data Management Section (Import/Export) ---
            // Spacer Item for vertical separation
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2 // Increase height for better visual separation
                Layout.fillWidth: true
            }
            SectionHeader {
                text: qsTr("Data Management") // Section header for data management features
            }

            // Display for last export date and count
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

            // Button for exporting notes, styled consistently
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny

                    Item { // Wrapper Item for the Icon to control its precise size and centering
                        width: Theme.fontSizeExtraLarge * 0.9
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/export.svg" // Assuming you have an export icon
                            anchors.fill: parent
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: qsTr("Export Notes") // Button text, translatable
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    console.log("Export notes clicked");
                    // Placeholder for export logic
                    if (AppSettings.exportNotes()) { // This C++ call would handle file dialog and actual export
                        // Simulate updating stats for now
                        var dummyCount = DB.getAllNotes().length; // Get actual count from DB
                        DB.updateLastExportDate();
                        DB.updateNotesExportedCount(dummyCount);
                        updateDataManagementStats(); // Refresh displayed stats
                        toastManager.show(qsTr("Notes exported successfully!"));
                    } else {
                        toastManager.show(qsTr("Failed to export notes."));
                    }
                }
            }

            // Display for last import date and count
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

            // Button for importing notes, styled consistently
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.buttonHeightSmall
                highlightColor: Theme.highlightColor
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingTiny

                    Item { // Wrapper Item for the Icon to control its precise size and centering
                        width: Theme.fontSizeExtraLarge * 0.9
                        height: Theme.fontSizeExtraLarge * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        Icon {
                            source: "../icons/import.svg" // Assuming you have an import icon
                            anchors.fill: parent
                            color: Theme.primaryColor
                        }
                    }
                    Label {
                        text: qsTr("Import Notes") // Button text, translatable
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    console.log("Import notes clicked");
                    // Placeholder for import logic
                    if (AppSettings.importNotes()) { // This C++ call would handle file dialog and actual import
                        // Simulate updating stats for now
                        var dummyCount = 5; // Replace with actual imported count
                        DB.updateLastImportDate();
                        DB.updateNotesImportedCount(dummyCount);
                        updateDataManagementStats(); // Refresh displayed stats
                        toastManager.show(qsTr("Notes imported successfully!"));
                        // After import, you might want to signal a refresh for the main note list
                    } else {
                        toastManager.show(qsTr("Failed to import notes."));
                    }
                }
            }
        }
    }

    // ToastManager for displaying temporary messages to the user
    ToastManager {
        id: toastManager
    }


    // --- Overlay for Color Selection Panel ---
    // This rectangle covers the entire page and makes it darker when the color picker is open.
    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: "#000000" // Black color
        visible: colorSelectionPanel.opacity > 0.01 // Only visible if the panel is mostly visible
        opacity: colorSelectionPanel.opacity * 0.4 // Semi-transparent based on panel's opacity
        z: 10.5 // Ensures it's above other content but below the color picker itself

        MouseArea {
            anchors.fill: parent
            enabled: overlayRect.visible // Enabled only when the overlay is visible
            onClicked: {
                // If the panel is visible, clicking the overlay closes it
                if (colorSelectionPanel.opacity > 0.01) {
                    colorSelectionPanel.opacity = 0; // Fade out the panel
                }
            }
        }
    }

    // --- Color Selection Panel ---
    // This rectangle contains the color swatches.
    Rectangle {
        id: colorSelectionPanel
        width: parent.width // Make it full width
        property real panelRadius: Theme.itemSizeSmall / 2 // Rounded corners for the panel
        // Height dynamically adjusted based on content and padding/radius
        height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + panelRadius
        anchors.horizontalCenter: parent.horizontalCenter
        // Anchor to the bottom of the parent (the Page) with some margin
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0 // No extra margin to make it flush with bottom
        z: 12 // Ensures it's on top of the overlay and other content
        opacity: 0 // Starts hidden
        visible: opacity > 0.01 // Only render if not fully transparent
        color: "transparent" // The outer rectangle itself is transparent
        clip: true // Clip content that goes beyond its bounds (for rounded corners)

        // Animation for showing/hiding the panel
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: colorPanelVisualBody
            width: parent.width
            // Height includes content and space for rounded corners/padding
            height: colorPanelContentColumn.implicitHeight + Theme.paddingMedium * 2 + 2 * colorSelectionPanel.panelRadius
            // Background color of the panel visually matches the currently selected custom background color
            color: settingsPage.customBackgroundColor // Or Theme.backgroundColor if a distinct panel background is preferred
            radius: colorSelectionPanel.panelRadius // Apply rounded corners to the visual body
            y: 0 // Position at the top of its parent (colorSelectionPanel)

            Column {
                id: colorPanelContentColumn
                width: parent.width
                height: implicitHeight // Auto-adjust height based on content
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: colorSelectionPanel.panelRadius // Padding from top edge, accounting for radius
                anchors.bottomMargin: Theme.paddingMedium // Padding at the bottom
                spacing: Theme.paddingMedium // Spacing between elements within the column

                Label {
                    id: colorTitle
                    text: qsTr("Select Theme Color") // Title for the color picker
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.highlightColor // Using highlight color for better visibility
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Flow {
                    id: colorFlow
                    width: parent.width - (2 * Theme.paddingLarge) // Adjust width for internal padding
                    spacing: Theme.paddingSmall // Spacing between individual color swatches
                    anchors.horizontalCenter: parent.horizontalCenter // Center the flow layout
                    layoutDirection: Qt.LeftToRight // Colors flow from left to right
                    readonly property int columns: 6 // Fixed number of columns for grid-like layout
                    // Calculate item width based on parent width and spacing to fit all columns
                    readonly property real itemWidth: (width - (spacing * (columns - 1))) / columns

                    Repeater {
                        model: settingsPage.colorPalette // Use the color palette defined in settingsPage
                        delegate: Item {
                            width: parent.itemWidth
                            height: parent.itemWidth // Make swatches square

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2 // Make the outer ring circular
                                // Outer ring color: white if this color is selected, otherwise transparent (or a subtle gray)
                                color: (settingsPage.customBackgroundColor === modelData) ? Theme.highlightColor : "#707070" // Highlight selected color with Theme.highlightColor
                                border.color: "transparent" // No border for the outer ring
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.85 // Make inner swatch slightly smaller
                                height: parent.height * 0.85
                                radius: width / 2 // Make inner swatch circular
                                color: modelData // The actual color of the swatch
                                border.color: "transparent" // No border for the inner swatch

                                // Checkmark for the selected color
                                Rectangle {
                                    visible: settingsPage.customBackgroundColor === modelData // Visible only if this color is selected
                                    anchors.centerIn: parent
                                    width: parent.width * 0.7 // Checkmark background size
                                    height: parent.height * 0.7
                                    radius: width / 2 // Circular checkmark background
                                    color: modelData // Checkmark background matches swatch color (subtle effect)

                                    Icon {
                                        source: "../icons/check.svg" // Checkmark icon
                                        anchors.centerIn: parent
                                        width: parent.width * 0.75 // Size of the checkmark icon
                                        height: parent.height * 0.75
                                        color: Qt.darker(settingsPage.customBackgroundColor, 1.2) // Make checkmark visible by contrasting with its background
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: true // Always enabled to allow selection
                                onClicked: {
                                    settingsPage.customBackgroundColor = modelData; // Update the custom background color property
                                    DB.setThemeColor(modelData); // Persist the new theme color to the database
                                    colorSelectionPanel.opacity = 0; // Close the color selection panel
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    SidePanel {
        id: sidePanelInstance
        open: settingsPage.panelOpen
        onClosed: settingsPage.panelOpen = false
        // Set the current page for the side panel instance to highlight 'settings'
        Component.onCompleted: sidePanelInstance.currentPage = "settings";
    }
}

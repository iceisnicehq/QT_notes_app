// ConfirmDialog.qml
// This component provides a customizable confirmation dialog with a dimming overlay.
// It can be used across different pages to confirm user actions.

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB // Import JavaScript for database operations

Item {
    id: confirmDialog
    // Expose properties for external control by the parent component
    property bool dialogVisible: false // Controls overall visibility of the dialog and overlay
    property string dialogTitle: qsTr("") // Title text for the dialog
    property string dialogMessage: "" // Main message text displayed in the dialog
    property string confirmButtonText: qsTr("Confirm") // Text for the confirmation button
    property color confirmButtonHighlightColor: Theme.highlightColor // Highlight color for the confirm button
    // Customizable background color for the dialog, defaults to a darkened theme color
    property color dialogBackgroundColor: DB.darkenColor(DB.getThemeColor(), 0.30)

    // Signals to communicate user's action (confirmed or cancelled) back to the parent
    signal confirmed()
    signal cancelled()

    // Make the root Item fill its parent to allow the dialog to be centered on the whole page
    // and the overlay to cover the entire screen.
    anchors.fill: parent
    visible: dialogVisible // The entire component's visibility is tied to this property
    z: 100 // Ensures the dialog appears on top of other content

    // Background overlay for dimming effect when the dialog is visible
    Rectangle {
        id: overlayRect
        anchors.fill: parent // Fills the entire 'confirmDialog' Item
        color: "#000000" // Black color for dimming
        opacity: 0 // Start hidden
        Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth opacity transition

        // Animate opacity based on dialog visibility
        onVisibleChanged: opacity = confirmDialog.dialogVisible ? 0.5 : 0

        // MouseArea to detect clicks on the dimmed overlay, which cancel the dialog
        MouseArea {
            anchors.fill: parent
            // Enable clicks only when the dialog is visible to prevent unwanted interactions
            enabled: confirmDialog.dialogVisible
            onClicked: {
                confirmDialog.cancelled() // Emit cancelled signal if overlay is clicked
            }
        }
    }

    // The actual dialog box rectangle
    Rectangle {
        id: dialogBody
        color: confirmDialog.dialogBackgroundColor // Uses the customizable background color
        radius: Theme.itemSizeSmall / 2 // Rounded corners for the dialog box
        anchors.centerIn: parent // Centers the dialog box within the screen

        // Bind visibility directly to the exposed property
        visible: confirmDialog.dialogVisible

        // Set initial opacity and scale for entry/exit animations
        opacity: 0
        scale: 0.9

        // Animations for opacity and scale
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

        // Logic to trigger animations based on visibility changes
        onVisibleChanged: {
            if (visible) {
                dialogBody.opacity = 1;
                dialogBody.scale = 1.0;
            } else {
                dialogBody.opacity = 0;
                dialogBody.scale = 0.9;
            }
        }

        // Set width and height of dialogBody dynamically based on content and constraints
        width: Math.min(confirmDialog.width * 0.8, Theme.itemSizeExtraLarge * 8) // Max width for responsiveness
        height: contentColumnLayout.implicitHeight + (Theme.paddingLarge * 2) // Height determined by content plus padding

        // ColumnLayout for organizing the dialog content (title, message, buttons)
        ColumnLayout {
            id: contentColumnLayout
            width: parent.width - (Theme.paddingLarge * 2) // Fills dialogBody's width minus its internal padding
            anchors.horizontalCenter: parent.horizontalCenter // Centers content horizontally
            spacing: Theme.paddingMedium // Spacing between elements in the column

            // Top padding for visual balance
            Rectangle {
            height: Theme.paddingLarge * 0.9
            color: "transparent" // Invisible spacer
            }
            // Label for the dialog title
            Label {
                Layout.fillWidth: true // Fills available width
                text: confirmDialog.dialogTitle // Binds to exposed title property
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                horizontalAlignment: Text.AlignHCenter // Centers text
                color: "white" // White text color
                wrapMode: Text.Wrap // Allows text to wrap to multiple lines
            }

            // Label for the dialog message
            Label {
                Layout.fillWidth: true // Fills available width
                text: confirmDialog.dialogMessage // Binds to exposed message property
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.primaryColor // Primary theme color for message text
            }

            // RowLayout for the action buttons (Cancel and Confirm)
            RowLayout {
                Layout.fillWidth: true // Fills available width
                spacing: Theme.paddingMedium // Spacing between buttons

                // Cancel button
                Button {
                    Layout.fillWidth: true
                    text: qsTr("Cancel") // Translated text
                    onClicked: confirmDialog.cancelled() // Emits cancelled signal on click
                }

                // Confirm button
                Button {
                    Layout.fillWidth: true
                    text: confirmDialog.confirmButtonText // Binds to exposed confirm button text property
                    highlightColor: confirmDialog.confirmButtonHighlightColor // Binds to exposed highlight color
                    onClicked: confirmDialog.confirmed() // Emits confirmed signal on click
                }
            }
        }
    }
}

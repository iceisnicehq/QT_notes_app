// ConfirmDialog.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import "DatabaseManager.js" as DB

Item {
    id: confirmDialog
    // Expose properties for external control
    property bool dialogVisible: false
    property string dialogTitle: qsTr("") // Added qsTr() here for completeness
    property string dialogMessage: ""
    property string confirmButtonText: qsTr("Confirm")
    property color confirmButtonHighlightColor: Theme.highlightColor
    // NEW: Customizable background color for the dialog, with a default
    property color dialogBackgroundColor: DB.darkenColor(DB.getThemeColor(), 0.30)

    // Signals to communicate user's action back to the parent
    signal confirmed()
    signal cancelled()

    // CRITICAL: Make the root Item fill its parent
    // This allows the dialog to be centered on the whole page and the overlay to cover it.
    anchors.fill: parent
    visible: dialogVisible // The entire component's visibility is tied to this property
    z: 100 // Ensure it's on top of other content

    // Background overlay for dimming effect
    Rectangle {
        anchors.fill: parent // This will now fill the entire 'confirmDialog' Item
        color: "#000000"
        opacity: 0 // Start hidden
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Animate opacity when confirmDialog.dialogVisible changes
        onVisibleChanged: opacity = confirmDialog.dialogVisible ? 0.5 : 0
    }

    // Actual dialog box (background, rounded corners, centering, scale animation)
    Rectangle {
        id: dialogBody
        color: confirmDialog.dialogBackgroundColor // USE NEW PROPERTY HERE
        radius: Theme.itemSizeSmall / 2
        anchors.centerIn: parent // Center within the 'confirmDialog' Item (which now fills the screen)

        // Bind visibility directly to the exposed property
        visible: confirmDialog.dialogVisible

        // Set initial opacity and scale for animation
        opacity: 0
        scale: 0.9

        // Animate opacity and scale when dialogBody's own visible state changes
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

        onVisibleChanged: {
            if (visible) {
                dialogBody.opacity = 1;
                dialogBody.scale = 1.0;
            } else {
                dialogBody.opacity = 0;
                dialogBody.scale = 0.9;
            }
        }

        // Set width and height of dialogBody based on its content's implicit size + padding
        // Maximum width for the dialog to prevent it from becoming too wide on larger screens
        width: Math.min(confirmDialog.width * 0.8, Theme.itemSizeExtraLarge * 8) // Limit max width to 8 times ExtraLarge size or 80% of page width
        height: contentColumnLayout.implicitHeight + (Theme.paddingLarge * 2) // Height determined by content + padding

        // Content ColumnLayout inside the dialogBody
        ColumnLayout {
            id: contentColumnLayout
            width: parent.width - (Theme.paddingLarge * 2) // Fill dialogBody's width minus its own padding
            anchors.horizontalCenter: parent.horizontalCenter // Center content within dialogBody
            spacing: Theme.paddingMedium
          //  padding: Theme.paddingLarge // Apply padding directly to the ColumnLayout for its children

            // Labels for title and message
            Label {
                Layout.fillWidth: true // Label fills the width of contentColumnLayout
                text: confirmDialog.dialogTitle
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true // Label fills the width of contentColumnLayout
                text: confirmDialog.dialogMessage
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.primaryColor
            }

            // Buttons row
            RowLayout {
                Layout.fillWidth: true // RowLayout fills the width of contentColumnLayout
                spacing: Theme.paddingMedium

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    onClicked: confirmDialog.cancelled()
                }

                Button {
                    Layout.fillWidth: true
                    text: confirmDialog.confirmButtonText
                    highlightColor: confirmDialog.confirmButtonHighlightColor
                    onClicked: confirmDialog.confirmed()
                }
            }
        }
    }
}

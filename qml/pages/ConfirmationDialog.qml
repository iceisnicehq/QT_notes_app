// ConfirmationDialog.qml (CORRECTED AGAIN - Sailfish Silica Dialog structure)
import Sailfish.Silica 1.0
import QtQuick 2.0

Dialog {
    // These properties will be set by the caller (e.g., TrashPage)
    // The DialogHeader automatically uses acceptText and cancelText from Dialog properties
    property string acceptText: qsTr("Yes")
    property string cancelText: qsTr("No")
    // Use a separate property for the message content
    property string message: qsTr("Are you sure?")

    // DialogHeader provides the "Accept" and "Cancel" buttons by default
    // It automatically uses the 'acceptText' and 'cancelText' properties of the Dialog itself.
    DialogHeader {
        id: dialogHeader
        // You can set a title for the header if needed, but for a simple confirmation,
        // the message in the content might be enough.
        // title: qsTr("Confirm Action") // Optional header title
    }

    // The main content of the dialog goes directly inside the Dialog,
    // usually anchored below the DialogHeader.
    // It is common to wrap it in a Column for layout.
    Column {
        width: parent.width // Ensure it takes full width
        spacing: Theme.paddingMedium
        anchors.top: dialogHeader.bottom // Position below the header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.horizontalPageMargin // Add standard page margins
        anchors.rightMargin: Theme.horizontalPageMargin

        Label {
            text: message
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.primaryColor
            // Centering within the column (which has margins)
            horizontalAlignment: Text.AlignHCenter
            width: parent.width // Take full width of the column
        }
    }

    // Buttons for action are typically handled by DialogHeader itself,
    // or if you need custom buttons, you would place them directly in the Dialog
    // and handle their layout.
    // However, for confirmation dialogs, DialogHeader's built-in functionality
    // is usually sufficient and preferred.

    // If you explicitly wanted custom buttons outside of DialogHeader's control:
    // (This is less common for simple confirmation, but possible)
    /*
    Row {
        width: parent.width
        anchors.bottom: parent.bottom // Anchor to the bottom of the dialog
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.horizontalPageMargin // Use standard margins
        spacing: Theme.paddingSmall
        // You'd need to manually connect signals here if DialogHeader isn't used
        // or if you want different behavior for accept/reject
        Button {
            text: cancelText
            width: (parent.width - parent.spacing) / 2
            onClicked: dialog.reject() // Direct access to dialog's reject method
        }
        Button {
            text: acceptText
            highlightColor: Theme.errorColor
            width: (parent.width - parent.spacing) / 2
            onClicked: dialog.accept() // Direct access to dialog's accept method
        }
    }
    */
}

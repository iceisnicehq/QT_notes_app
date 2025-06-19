// ImportExportPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0 
import Sailfish.Pickers 1.0
import QtQuick.Layouts 1.1
import Nemo.Configuration 1.0 
import "DatabaseManager.js" as DB 
import QtQuick.LocalStorage 2.0 

Page {
    id: importExportPage
    // Set background color using DB.getThemeColor()
    property string customBackgroundColor: DB.getThemeColor()
    backgroundColor: customBackgroundColor || "#121218" // Fallback to a dark color if not found
    allowedOrientations: Orientation.All
    showNavigationIndicator: false
    property string statusText: ""
    property bool processInProgress: false

    // Property to control side panel visibility, similar to ArchivePage
    property bool panelOpen: false

    // Properties to hold export/import statistics
    property var lastExportDate: null
    property int notesExportedCount: 0
    property var lastImportDate: null
    property int notesImportedCount: 0

    // ConfigurationValue for getting the documents path
    ConfigurationValue {
        id: documentsPathConfig
        key: "/desktop/nemo/preferences/documents_path"
        defaultValue: StandardPaths.documents // Fallback option
        onValueChanged: {
            console.log(qsTr("APP_DEBUG: Documents path is: ") + value); // Log the path
        }
    }
    ToastManager {
        id: toastManager
    }

    // COMPONENT FOR FILE SELECTION (FOR IMPORT)
    Component {
        id: filePickerComponent

        FilePickerPage {
            title: qsTr("Select file for import")
            nameFilters: ["*.json"]
            // No nameFilters set, will show all files, user must pick .json

            onSelectedContentPropertiesChanged: {
                if (selectedContentProperties !== null) {
                    // Use .toString() to explicitly get the string from QUrl or similar object
                    var filePathRaw = selectedContentProperties.filePath.toString();

                    // Now remove the "file://" prefix
                    var filePathClean;
                    if (filePathRaw.indexOf("file://") === 0) {
                        filePathClean = filePathRaw.substring(7);
                    } else {
                        filePathClean = filePathRaw; // If no prefix, use as is
                    }
                    // Start import with cleaned and guaranteed string path, also pass the new optional tag
                    importFromFile(filePathClean, newTagForImportField.text.trim());
                }
            }
        }
    }

    Item {
        id: exportResultDialog // Direct Item instance, not a Component
        // Expose properties for external control by the parent page
        property bool dialogVisible: false // Controls overall visibility of the dialog and overlay
        property string dialogFileName: "" // File name for display
        property string dialogFilePath: "" // Full path for display
        property int dialogDataSize: 0 // File size in bytes
        property int dialogOperationsCount: 0 // Number of notes exported

        // Signal to communicate dismissal back to the parent page
        signal dismissed()

        // Make the root Item fill its parent to allow the dialog to be centered on the whole page
        // and the overlay to cover the entire screen.
        anchors.fill: parent
        visible: dialogVisible // The entire component's visibility is tied to this property
        z: 100 // Ensures the dialog appears on top of other content

        // Handle dismissal from the parent (e.g., when the button is clicked or overlay is tapped)
        onDismissed: {
            dialogVisible = false // Hide the dialog
        }

        // Background overlay for dimming effect when the dialog is visible
        Rectangle {
            id: overlayRect
            anchors.fill: parent // Fills the entire 'exportResultDialog' Item
            color: "#000000" // Black color for dimming
            opacity: 0 // Start hidden
            Behavior on opacity { NumberAnimation { duration: 200 } } // Smooth opacity transition

            // Animate opacity based on dialog visibility
            onVisibleChanged: opacity = exportResultDialog.dialogVisible ? 0.5 : 0

            // MouseArea to detect clicks on the dimmed overlay, which dismiss the dialog
            MouseArea {
                anchors.fill: parent
                // Enable clicks only when the dialog is visible to prevent unwanted interactions
                enabled: exportResultDialog.dialogVisible
                // This MouseArea will ONLY receive clicks that are NOT consumed by children
                onClicked: {
                    exportResultDialog.dismissed() // Emit dismissed signal if overlay is clicked
                }
            }
        }

        // The actual dialog box rectangle (main visual container for dialog content)
        Rectangle {
            id: exportDialogBody // Specific ID for this dialog's body
            color: DB.darkenColor(importExportPage.customBackgroundColor, 0.30) // Use page's background color
            radius: Theme.itemSizeSmall / 2 // Rounded corners for the dialog box
            anchors.centerIn: parent // Centers the dialog box within the screen

            // MouseArea to consume clicks on the dialog body itself,
            // preventing them from propagating to the overlayRect's MouseArea.
            // An onClicked handler must be present (even empty) to consume the event.
            MouseArea {
                anchors.fill: parent
                onClicked: { /* Do nothing, just consume the click */ }
            }

            // Bind visibility directly to the exposed property
            visible: exportResultDialog.dialogVisible

            // Set initial opacity and scale for entry/exit animations
            opacity: 0
            scale: 0.9

            // Animations for opacity and scale
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

            // Logic to trigger animations based on visibility changes
            onVisibleChanged: {
                if (visible) {
                    exportDialogBody.opacity = 1;
                    exportDialogBody.scale = 1.0;
                } else {
                    exportDialogBody.opacity = 0;
                    exportDialogBody.scale = 0.9;
                }
            }

            // Set width and height of dialogBody dynamically based on content and constraints
            // height calculated based on contentColumn implicit height
            width: Math.min(exportResultDialog.width * 0.8, Theme.itemSizeExtraLarge * 8) // Max width for responsiveness
            height: exportContentColumn.implicitHeight + (Theme.paddingLarge * 2) // Height determined by content plus padding

            // ColumnLayout for organizing the dialog content (title, message, buttons)
            Column {
                id: exportContentColumn // Specific ID for this dialog's content column
                width: parent.width - (Theme.paddingLarge * 2) // Fills dialogBody's width minus its internal padding
                anchors.horizontalCenter: parent.horizontalCenter // Centers content horizontally
                spacing: Theme.paddingMedium // Spacing between elements in the column
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge // Top padding for visual balance

                // Title Label - "Export completed"
                Label {
                    width: parent.width
                    text: qsTr("Export completed")
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    wrapMode: Text.Wrap
                }

                // Spacer for visual separation between title and content
                Rectangle {
                    width: parent.width
                    height: Theme.paddingMedium
                    color: "transparent"
                }

                // Centered Labels for key parts
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap 
                    color: Theme.highlightColor
                    text: qsTr("File: ") + "<b>" + exportResultDialog.dialogFileName + "</b>" 
                    textFormat: Text.StyledText
                    horizontalAlignment: Text.AlignHCenter 
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap 
                    text: qsTr("Path: ") + exportResultDialog.dialogFilePath 
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter 
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap 
                    color: Theme.highlightColor
                    text: qsTr("Notes exported: ") + exportResultDialog.dialogOperationsCount 
                    horizontalAlignment: Text.AlignHCenter 
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap 
                    color: Theme.highlightColor
                    text: qsTr("File size: ") + (exportResultDialog.dialogDataSize / 1024).toFixed(2) + qsTr(" KB") 
                    horizontalAlignment: Text.AlignHCenter 
                }

                // "Great!" button to dismiss the dialog
                Button {
                    text: qsTr("Great!")
                    anchors.horizontalCenter: parent.horizontalCenter 
                    onClicked: {
                        exportResultDialog.dismissed() // Emit dismissed signal
                    }
                }
            }
        }
    }

    Item {
        id: importResultDialog // Direct Item instance
        property bool dialogVisible: false // Controls overall visibility
        property string dialogFileName: ""
        property string dialogFilePath: ""
        property int dialogNotesImportedCount: 0
        property int dialogTagsCreatedCount: 0 // Placeholder for tags created

        signal dismissed()

        // Handle dismissal for the import dialog
        onDismissed: {
            dialogVisible = false
            pageStack.clear();
            pageStack.completeAnimation();
            pageStack.push(Qt.resolvedUrl("MainPage.qml"));
            pageStack.completeAnimation();
            pageStack.push(Qt.resolvedUrl("ImportExportPage.qml"));
            pageStack.completeAnimation();
        }

        anchors.fill: parent
        visible: dialogVisible
        z: 100

        Rectangle {
            id: importOverlayRect 
            anchors.fill: parent
            color: "#000000"
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            onVisibleChanged: opacity = importResultDialog.dialogVisible ? 0.5 : 0
            MouseArea {
                anchors.fill: parent
                enabled: importResultDialog.dialogVisible
                onClicked: { importResultDialog.dismissed() } 
            }
        }

        Rectangle {
            id: importDialogBody 
            color: DB.darkenColor(importExportPage.customBackgroundColor, 0.30)
            radius: Theme.itemSizeSmall / 2
            anchors.centerIn: parent

            MouseArea {
                anchors.fill: parent
                onClicked: { /* Consume click */ }
            }

            visible: importResultDialog.dialogVisible
            opacity: 0
            scale: 0.9
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }
            onVisibleChanged: {
                if (visible) {
                    importDialogBody.opacity = 1;
                    importDialogBody.scale = 1.0;
                } else {
                    importDialogBody.opacity = 0;
                    importDialogBody.scale = 0.9;
                }
            }

            width: Math.min(importResultDialog.width * 0.8, Theme.itemSizeExtraLarge * 8)
            height: importContentColumn.implicitHeight + (Theme.paddingLarge * 2)

            Column {
                id: importContentColumn 
                width: parent.width - (Theme.paddingLarge * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge

                Label {
                    width: parent.width
                    text: qsTr("Import completed")
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    width: parent.width
                    height: Theme.paddingMedium
                    color: "transparent"
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: qsTr("File: ") + "<b>" + importResultDialog.dialogFileName + "</b>"
                    textFormat: Text.StyledText
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Path: ") + importResultDialog.dialogFilePath
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: qsTr("Notes imported: ") + importResultDialog.dialogNotesImportedCount
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: qsTr("Tags created: ") + importResultDialog.dialogTagsCreatedCount
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    text: qsTr("Great!")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        importResultDialog.dismissed() 
                    }
                }
            }
        }
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
                    importExportPage.panelOpen = true // Open the side panel
                    console.log("Menu button clicked in ImportExportPage → panelOpen = true")
                }
            }
        }

        Label {
            id: headerText
            text: qsTr("Import/Export") // Page title for Import/Export, translatable
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
        }
        
        Label {
            text: qsTr("In JSON Format")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: headerText.bottom
            horizontalAlignment: "AlignHCenter"
            font.pixelSize: Theme.fontSizeExtraSmall
            font.italic: true
            color: Theme.secondaryColor
            wrapMode: Text.Wrap
        }
    }


    
    SilicaFlickable {
        anchors.fill: parent
        
        anchors.topMargin: pageHeader.height
        contentHeight: column.implicitHeight 

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter 
            anchors.margins: Theme.paddingLarge // General margins for the content

            // --- EXPORT SECTION ---
            Label { 
                id: exportNotes
                text: qsTr("Export Notes")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white" 
            }

            TextField {
                id: fileNameField
                width: parent.width
                label: qsTr("File Name")
                placeholderText: qsTr("e.g., notes_backup")
            }
 
            TextField {
                id: newTagField
                width: parent.width
                label: qsTr("This Tag Will Be Added To Exported Notes") 
                placeholderText: qsTr("Add Tag to Exported Notes (Optional)") 
            }

            Label {
                text: qsTr("Notes in the trash don't get exported")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeExtraSmall
                font.italic: true
                color: Theme.secondaryColor
            }
            Button {
                text: qsTr("Export All Notes")
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !processInProgress && fileNameField.text.length > 0 // Button inactive during process
                onClicked: exportData(newTagField.text.trim()) // Pass the trimmed value of the new tag field
            }

            // Export Statistics Display
            Label {
                width: parent.width - (2 * Theme.paddingLarge)
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                text: (notesExportedCount > 0 && lastExportDate) ?
                      qsTr("Last export: %1 (%2 notes)").arg(Qt.formatDateTime(new Date(lastExportDate), "yyyy-MM-dd HH:mm")).arg(notesExportedCount) :
                      qsTr("No export detected.");
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: Theme.paddingSmall
                bottomPadding: Theme.paddingSmall
            }

            // --- Spacer before Import Section ---
            Rectangle {
                height: Theme.paddingLarge * 2 // Consistent spacing
                width: parent.width
                color: "transparent"
            }

            // --- IMPORT SECTION ---
            Label { 
                text: qsTr("Import Notes")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white" 
            }

            TextField {
                id: newTagForImportField
                width: parent.width
                label: qsTr("This Tag Will Get Added To Imported Notes") 
                placeholderText: qsTr("Add Tag to Imported Notes (Optional)") 
            }

            Button {
                text: qsTr("Import from File")
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !processInProgress
                onClicked: {
                    statusText = "";
                    pageStack.push(filePickerComponent);
                }
            }

            // Import Statistics Display
            Label {
                width: parent.width - (2 * Theme.paddingLarge)
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                text: (notesImportedCount > 0 && lastImportDate) ?
                      qsTr("Last import: %1 (%2 notes)").arg(Qt.formatDateTime(new Date(lastImportDate), "yyyy-MM-dd HH:mm")).arg(notesImportedCount) :
                      qsTr("No import detected.");
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: Theme.paddingSmall
                bottomPadding: Theme.paddingSmall
            }

            // --- Spacer before Status ---
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2 
                width: parent.width
            }

            
            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: processInProgress
                running: processInProgress
                size: BusyIndicatorSize.Large
            }

            Label {
                id: statusLabel
                width: parent.width - (2 * Theme.paddingLarge) 
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white" 
                wrapMode: Text.Wrap
                text: statusText
                visible: statusText !== ""
            }
        }
    }

    // --- INITIALIZATION ---
    Component.onCompleted: {
        console.log(qsTr("APP_DEBUG: Export/Import Page: Component.onCompleted started."));
        // Database initialization
        DB.initDatabase(LocalStorage)
        if (DB.db === null) {
            console.error(qsTr("APP_DEBUG: DB.db is NULL after initDatabase call! Export/Import will likely fail."));
            statusText = qsTr("Error: Database not initialized. Please restart the application.");
        } else {
            console.log(qsTr("APP_DEBUG: DB.db is successfully initialized."));

            // Fetch export/import stats from AppSettings
            lastExportDate = DB.getSetting("lastExportDate");
            notesExportedCount = DB.getSetting("notesExportedCount");
            lastImportDate = DB.getSetting("lastImportDate");
            notesImportedCount = DB.getSetting("notesImportedCount");

            // Ensure counts are 0 if no data (getSetting returns null)
            if (notesExportedCount === null) notesExportedCount = 0;
            if (notesImportedCount === null) notesImportedCount = 0;

            console.log("APP_DEBUG: Loaded export/import stats:",
                        "Export Date:", lastExportDate,
                        "Export Count:", notesExportedCount,
                        "Import Date:", lastImportDate,
                        "Import Count:", notesImportedCount);
        }

        // Set initial filename with a default name, without enforcing .json on display
        var initialBaseName = qsTr("notes_backup_") + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
        fileNameField.text = initialBaseName; 

        console.log(qsTr("APP_DEBUG: Export/Import Page: Component.onCompleted finished."));
    }

    // --- EXPORT LOGIC ---
    function exportData(optionalNewTag) { 
        processInProgress = true; 
        statusText = qsTr("Gathering data for export...");
        console.log(qsTr("APP_DEBUG: exportData started. Optional tag: ") + optionalNewTag);

        // Get the filename as typed by the user
        var userFileName = fileNameField.text;

        // Add .json extension if it's missing
        var finalFileName = userFileName;
        if (finalFileName.indexOf(".json", finalFileName.length - ".json".length) === -1) {
            finalFileName += ".json";
        }

        // Call function from DatabaseManager.js
        DB.getNotesForExport(
            // 1. Success callback function
            function(notes) {
                console.log(qsTr("APP_DEBUG: getNotesForExport SUCCESS. Notes count: ") + (notes ? notes.length : 0));
                if (!notes || notes.length === 0) {
                    toastManager.show(qsTr("No notes to export."));

                    statusText = qsTr("");
                    processInProgress = false;
                    return;
                }

                statusText = qsTr("Preparing ") + notes.length + qsTr(" notes...");
                var generatedData = JSON.stringify(notes, null, 2);

                var finalPath = documentsPathConfig.value + "/" + finalFileName; 
                console.log(qsTr("APP_DEBUG: Attempting to write file to: ") + finalPath);
                writeToFile(finalPath, generatedData);
            },
            // 2. Error callback function
            function(error) {
                console.error(qsTr("APP_DEBUG: getNotesForExport FAILED: ") + error.message);
                statusText = qsTr("Export error: ") + error.message;
                processInProgress = false;
            },
            optionalNewTag 
        );
        console.log(qsTr("APP_DEBUG: exportData finished, waiting for callbacks."));
    }

    function writeToFile(filePath, textData) {
        statusText = qsTr("Saving file...");
        console.log(qsTr("APP_DEBUG: writeToFile started for path: ") + filePath);

        try {
            if (typeof FileIO !== 'undefined' && FileIO.write) {
                FileIO.write(filePath, textData);
                console.log(qsTr("APP_DEBUG: File saved via FileIO: ") + filePath);
                var notesCount = JSON.parse(textData).length;

                DB.updateLastExportDate();
                DB.updateNotesExportedCount(notesCount);

                lastExportDate = DB.getSetting("lastExportDate");
                notesExportedCount = DB.getSetting("notesExportedCount");

                exportResultDialog.dialogFileName = filePath.split('/').pop();
                exportResultDialog.dialogFilePath = filePath;
                exportResultDialog.dialogOperationsCount = notesCount;
                exportResultDialog.dialogDataSize = textData.length;

                exportResultDialog.dialogVisible = true; 

                statusText = ""; // Clear status after dialog appears
            } else {
                // FALLBACK: Use XMLHttpRequest to save file if FileIO is not available
                console.warn(qsTr("APP_DEBUG: FileIO not defined or write method missing, attempting to save via XMLHttpRequest."));
                var xhr = new XMLHttpRequest();
                // Synchronous PUT request to local file. 'file://' is mandatory.
                xhr.open("PUT", "file://" + filePath, false);
                xhr.send(textData);

                if (xhr.status === 0 || xhr.status === 200) { // status 0 often means success for local files
                    console.log(qsTr("APP_DEBUG: File saved via XMLHttpRequest: ") + filePath);
                    // For JSON, parse the data to get the count
                    var notesCount = JSON.parse(textData).length;

                    DB.updateLastExportDate();
                    DB.updateNotesExportedCount(notesCount);

                    // Update QML properties after successful export
                    lastExportDate = DB.getSetting("lastExportDate");
                    notesExportedCount = DB.getSetting("notesExportedCount");

                    // SHOW the dialog and pass properties directly
                    exportResultDialog.dialogFileName = filePath.split('/').pop();
                    exportResultDialog.dialogFilePath = filePath;
                    exportResultDialog.dialogOperationsCount = notesCount;
                    exportResultDialog.dialogDataSize = textData.length;
                    exportResultDialog.dialogVisible = true; // Make the dialog visible
                    statusText = "";
                } else {
                    statusText = qsTr("File save error (XHR): ") + xhr.statusText + " (" + xhr.status + ")";
                    console.error(qsTr("APP_DEBUG: Error saving file via XHR: ") + xhr.statusText + " (" + xhr.status + ")");
                }
            }
        } catch (e) {
            console.error(qsTr("APP_DEBUG: EXCEPTION caught during file saving: ") + e.message);
            statusText = qsTr("File save error: ") + e.message;
        } finally {
            processInProgress = false; // Always reset indicator
            console.log(qsTr("APP_DEBUG: writeToFile finished."));
        }
    }

    // --- IMPORT LOGIC ---
    function importFromFile(filePath, optionalNewTagForImport) { 
        processInProgress = true;
        var absoluteFilePathString = String(filePath); 

        statusText = qsTr("Reading file: ") + absoluteFilePathString.split('/').pop();
        console.log(qsTr("APP_DEBUG: importFromFile started for path: ") + absoluteFilePathString);
        console.log(qsTr("APP_DEBUG: Type of absoluteFilePathString: ") + typeof absoluteFilePathString);
        console.log(qsTr("APP_DEBUG: Optional tag for import: ") + optionalNewTagForImport);


        if (!DB.db) {
            console.error(qsTr("DB_MGR: Database not initialized for importFromFile."));
            statusText = qsTr("Error: Database not initialized for import.");
            processInProgress = false;
            console.log("APP_DEBUG: processInProgress set to false due to DB not initialized.");
            return;
        }

        // --- Step 1: Get tag count BEFORE import ---
        var tagsBeforeImport = DB.getAllTags().length;
        console.log("APP_DEBUG: Tags before import: " + tagsBeforeImport);

        try {
            var fileContent;
            if (typeof FileIO !== 'undefined' && FileIO.read) {
                fileContent = FileIO.read(absoluteFilePathString);
                console.log(qsTr("APP_DEBUG: File read via FileIO: ") + absoluteFilePathString);
            } else {
                console.warn(qsTr("APP_DEBUG: FileIO not defined or read method missing, attempting to read via XMLHttpRequest."));
                var xhr = new XMLHttpRequest();
                xhr.open("GET", "file://" + absoluteFilePathString, false);
                xhr.send();

                if (xhr.status === 0 || xhr.status === 200) {
                    fileContent = xhr.responseText;
                    console.log(qsTr("APP_DEBUG: File read via XMLHttpRequest: ") + absoluteFilePathString);
                } else {
                    statusText = qsTr("File read error (XHR): ") + xhr.statusText + " (" + xhr.status + ")";
                    console.error(qsTr("APP_DEBUG: Error reading file via XHR: ") + xhr.statusText + " (" + xhr.status + ")");
                    processInProgress = false;
                    console.log("APP_DEBUG: processInProgress set to false due to XHR file read error.");
                    return;
                }
            }

            if (fileContent) {
                var notes;   
                if (absoluteFilePathString.indexOf(".json", absoluteFilePathString.length - ".json".length) !== -1) {
                    notes = JSON.parse(fileContent);
                } else {
                    statusText = qsTr("Unsupported file format. Only JSON is supported.");
                    processInProgress = false;
                    console.log("APP_DEBUG: processInProgress set to false due to unsupported file format.");
                    return;
                }

                if (notes && notes.length > 0) {
                    statusText = qsTr("Importing ") + notes.length + qsTr(" notes...");
                    var importedCount = 0; 

                    console.log("APP_DEBUG: Initiating DB transaction for import.");
                    DB.db.transaction(
                        function(tx) { 
                            console.log("APP_DEBUG: Inside DB transaction function.");
                            for (var i = 0; i < notes.length; i++) {
                                try {
                                    DB.addImportedNote(notes[i], tx, optionalNewTagForImport);
                                    importedCount++;
                                    console.log("APP_DEBUG: Added note " + notes[i].id + ", count: " + importedCount);
                                } catch (noteAddError) {
                                    console.error("APP_DEBUG: Error within addImportedNote for note " + notes[i].id + ": " + noteAddError.message);
                                }
                            }
                            console.log("APP_DEBUG: Finished loop in DB transaction function. Total processed in loop: " + importedCount);
                        }
                    );
                    console.log("APP_DEBUG: DB transaction call returned. Proceeding with UI updates.");

                    // --- Step 2: Get tag count AFTER import ---
                    var tagsAfterImport = DB.getAllTags().length;
                    var newlyCreatedTagsCount = tagsAfterImport - tagsBeforeImport;
                    console.log("APP_DEBUG: Tags after import: " + tagsAfterImport);
                    console.log("APP_DEBUG: Newly created tags: " + newlyCreatedTagsCount);

                    DB.updateLastImportDate();
                    DB.updateNotesImportedCount(notes.length);

                    lastImportDate = DB.getSetting("lastImportDate");
                    notesImportedCount = DB.getSetting("notesImportedCount");

                    importResultDialog.dialogFileName = absoluteFilePathString.split('/').pop();
                    importResultDialog.dialogFilePath = absoluteFilePathString;
                    importResultDialog.dialogNotesImportedCount = notes.length;
                    importResultDialog.dialogTagsCreatedCount = newlyCreatedTagsCount; 

                    importResultDialog.dialogVisible = true; 
                    statusText = ""; 

                    processInProgress = false;
                    console.log("APP_DEBUG: processInProgress set to false after transaction initiation. Imported: " + notes.length);

                } else {
                    statusText = qsTr("File contains no notes to import.");
                    processInProgress = false;
                    console.log("APP_DEBUG: No notes to import, processInProgress set to false.");
                }

            } else {
                statusText = qsTr("File is empty.");
                processInProgress = false;
                console.log("APP_DEBUG: File empty, processInProgress set to false.");
            }
        } catch (e) {
            statusText = qsTr("File processing error: ") + e.message;
            console.error(qsTr("APP_DEBUG: EXCEPTION caught during file processing for import: ") + e.message);
            processInProgress = false; 
            console.log("APP_DEBUG: General catch block, processInProgress set to false due to exception.");
        }
    }

    // --- SidePanel ---
    SidePanel {
        id: sidePanelInstance
        open: importExportPage.panelOpen
        onClosed: importExportPage.panelOpen = false
        Component.onCompleted: sidePanelInstance.currentPage = "import/export";
        customBackgroundColor:  DB.darkenColor(importExportPage.customBackgroundColor, 0.30)
        activeSectionColor: importExportPage.customBackgroundColor
    }
}

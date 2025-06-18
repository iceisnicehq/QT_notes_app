// ImportExportPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import QtQuick.Layouts 1.1
import Nemo.Configuration 1.0 // For getting the documents path
import "DatabaseManager.js" as DB // Your database manager

import QtQuick.LocalStorage 2.0 // Explicitly import LocalStorage

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
                    // Start import with cleaned and guaranteed string path
                    importFromFile(filePathClean); // Pass the already cleaned string
                }
            }
        }
    }

    // --- Page Header (Copied from SettingsPage) ---
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
        // New label for JSON format
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


    // --- Main page interface ---
    SilicaFlickable {
        anchors.fill: parent
        // Adjust top margin to account for the new PageHeader
        anchors.topMargin: pageHeader.height
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter // Center the column within the flickable
            anchors.margins: Theme.paddingLarge // General margins for the content


            // --- EXPORT SECTION ---
            Label { // Changed from SectionHeader to Label and centered
                id: exportNotes
                text: qsTr("Export Notes")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white" // Changed from Theme.highlightColor to "white"
            }


            TextField {
                id: fileNameField
                width: parent.width
                label: qsTr("File Name")
                placeholderText: qsTr("e.g., notes_backup")
            }

            // New: Optional Tag Field for Exported Notes
            TextField {
                id: newTagField
                width: parent.width
                label: qsTr("Exported Notes Will Have This Tag")
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
            Item {
                Layout.preferredHeight: Theme.paddingLarge * 2 // Consistent spacing
                Layout.fillWidth: true
            }

            // --- IMPORT SECTION ---
            Label { // Changed from SectionHeader to Label and centered
                text: qsTr("Import Notes")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white" // Changed from Theme.highlightColor to "white"
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
                Layout.preferredHeight: Theme.paddingLarge * 2 // Consistent spacing
                Layout.fillWidth: true
            }

            // --- GENERAL STATUS ---
            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: processInProgress
                running: processInProgress
                size: BusyIndicatorSize.Large
            }

            Label {
                id: statusLabel
                width: parent.width - (2 * Theme.paddingLarge) // Adjusted width for margins
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white" // Changed from Theme.highlightColor to "white"
                wrapMode: Text.Wrap
                text: statusText
                visible: statusText !== ""
            }
        }
    }

    // Removed updateFileName function. The filename will be handled directly in exportData.

    // --- INITIALIZATION (VERY IMPORTANT PLACE) ---
    Component.onCompleted: {
        console.log(qsTr("APP_DEBUG: Export/Import Page: Component.onCompleted started."));
        // Database initialization - ONLY HERE!
        // Pass LocalStorage, which is available in QML context, to the JS module.
        DB.initDatabase(LocalStorage)
        // Check if the database initialized successfully
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
        fileNameField.text = initialBaseName; // No .json added here, user can type freely

        // Disconnect textChanged signal as we don't want to modify input as user types.
        // fileNameField.textChanged.disconnect(updateFileName); // This line is now effectively removed by removing the function.

        console.log(qsTr("APP_DEBUG: Export/Import Page: Component.onCompleted finished."));
    }

    // --- EXPORT LOGIC ---
    function exportData(optionalNewTag) { // Added optionalNewTag parameter
        processInProgress = true; // Show indicator
        statusText = qsTr("Gathering data for export...");
        console.log(qsTr("APP_DEBUG: exportData started. Optional tag: ") + optionalNewTag);

        // Get the filename as typed by the user
        var userFileName = fileNameField.text;

        // Add .json extension if it's missing (ES5 compatible check)
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
                    statusText = qsTr("No notes to export.");
                    processInProgress = false;
                    return;
                }

                statusText = qsTr("Preparing ") + notes.length + qsTr(" notes...");
                // Always generate JSON
                var generatedData = generateJson(notes);

                var finalPath = documentsPathConfig.value + "/" + finalFileName; // Use the corrected filename
                console.log(qsTr("APP_DEBUG: Attempting to write file to: ") + finalPath);
                writeToFile(finalPath, generatedData);
            },
            // 2. Error callback function
            function(error) {
                console.error(qsTr("APP_DEBUG: getNotesForExport FAILED: ") + error.message);
                statusText = qsTr("Export error: ") + error.message;
                processInProgress = false;
            },
            optionalNewTag // Pass the new parameter here
        );
        console.log(qsTr("APP_DEBUG: exportData finished, waiting for callbacks."));
    }

    function generateJson(data) {
        return JSON.stringify(data, null, 2);
    }

    // The writeToFile function handles saving and updating UI elements based on the outcome.
    function writeToFile(filePath, textData) {
        statusText = qsTr("Saving file...");
        console.log(qsTr("APP_DEBUG: writeToFile started for path: ") + filePath);

        try {
            // Attempt to use global FileIO object if provided (from C++)
            if (typeof FileIO !== 'undefined' && FileIO.write) {
                FileIO.write(filePath, textData);
                console.log(qsTr("APP_DEBUG: File saved via FileIO: ") + filePath);
                // Continue updating statistics and showing dialog
                var notesCount = JSON.parse(textData).length;

                DB.updateLastExportDate();
                DB.updateNotesExportedCount(notesCount);

                // Update QML properties after successful export
                lastExportDate = DB.getSetting("lastExportDate");
                notesExportedCount = DB.getSetting("notesExportedCount");

                pageStack.push(Qt.resolvedUrl("ExportResultDialog.qml"), {
                    fileName: filePath.split('/').pop(),
                    filePath: filePath,
                    operationsCount: notesCount,
                    dataSize: textData.length,
                    sampleData: textData.substring(0, 250) + (textData.length > 250 ? "..." : "")
                });
                statusText = ""; // Clear status after dialog completes
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

                    pageStack.push(Qt.resolvedUrl("ExportResultDialog.qml"), {
                        fileName: filePath.split('/').pop(),
                        filePath: filePath,
                        operationsCount: notesCount,
                        dataSize: textData.length,
                        sampleData: textData.substring(0, 250) + (textData.length > 250 ? "..." : "")
                    });
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
    function importFromFile(filePath) {
        processInProgress = true;
        var absoluteFilePathString = String(filePath); // Keep this line for reliability

        statusText = qsTr("Reading file: ") + absoluteFilePathString.split('/').pop();
        console.log(qsTr("APP_DEBUG: importFromFile started for path: ") + absoluteFilePathString);
        console.log(qsTr("APP_DEBUG: Type of absoluteFilePathString: ") + typeof absoluteFilePathString);

        if (!DB.db) {
            console.error(qsTr("DB_MGR: Database not initialized for importFromFile."));
            statusText = qsTr("Error: Database not initialized for import.");
            processInProgress = false;
            console.log("APP_DEBUG: processInProgress set to false due to DB not initialized.");
            return;
        }

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
                // Check if the string ends with ".json" using ES5 compatible method
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
                    var importedCount = 0; // Declare outside transaction for scope

                    console.log("APP_DEBUG: Initiating DB transaction for import.");
                    DB.db.transaction(
                        function(tx) { // Transaction callback
                            console.log("APP_DEBUG: Inside DB transaction function.");
                            for (var i = 0; i < notes.length; i++) {
                                try {
                                    // Make sure DB.addImportedNote is robust and handles its own tx.executeSql errors
                                    DB.addImportedNote(notes[i], tx);
                                    importedCount++;
                                    console.log("APP_DEBUG: Added note " + notes[i].id + ", count: " + importedCount);
                                } catch (noteAddError) {
                                    console.error("APP_DEBUG: Error within addImportedNote for note " + notes[i].id + ": " + noteAddError.message);
                                    // Do NOT re-throw here. If the transaction itself isn't reliably closing,
                                    // re-throwing could contribute to the hang.
                                }
                            }
                            console.log("APP_DEBUG: Finished loop in DB transaction function. Total processed in loop: " + importedCount);
                        }
                    );
                    console.log("APP_DEBUG: DB transaction call returned. Proceeding with UI updates.");

                    // Manually update UI and reset processInProgress immediately after the transaction call returns
                    statusText = qsTr("Import completed! Processed: ") + notes.length + qsTr(" notes."); // Use notes.length for consistency
                    DB.updateLastImportDate();
                    DB.updateNotesImportedCount(notes.length); // Update with total notes from file

                    // Update QML properties after successful import (using notes.length as the count)
                    lastImportDate = DB.getSetting("lastImportDate");
                    notesImportedCount = DB.getSetting("notesImportedCount");

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
            processInProgress = false; // Ensure reset on any parsing/file read error
            console.log("APP_DEBUG: General catch block, processInProgress set to false due to exception.");
        }
    }

    // --- SidePanel (assuming it's a shared component and not defined here) ---
    SidePanel {
        id: sidePanelInstance
        open: importExportPage.panelOpen
        onClosed: importExportPage.panelOpen = false
        // Changed to "import/export" to match the NavigationButton's 'selected' logic
        Component.onCompleted: sidePanelInstance.currentPage = "import/export";
        customBackgroundColor:  DB.darkenColor(importExportPage.customBackgroundColor, 0.30)
        activeSectionColor: importExportPage.customBackgroundColor
    }
}

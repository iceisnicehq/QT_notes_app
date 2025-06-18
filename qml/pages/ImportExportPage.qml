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

    // NEW: Properties to hold export/import statistics
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
            backgroundColor: DB.getThemeColor()
            // nameFilters: [qsTr("Резервные копии (*.json *.csv)"), qsTr("JSON файлы (*.json)"), qsTr("CSV файлы (*.csv)")] // These lines were already wrapped, commented out to show they haven't changed.

            onSelectedContentPropertiesChanged: {
                if (selectedContentProperties !== null) {
                    // Make sure this part remains as we fixed it:
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
            text: qsTr("Import/Export") // Page title for Import/Export, translatable
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
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
                text: qsTr("Export Notes")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: Theme.highlightColor
            }

            ComboBox {
                id: exportFormatCombo
                label: qsTr("File Format")
                width: parent.width
                currentIndex: 1 // JSON by default
                menu: ContextMenu {
                    MenuItem { text: qsTr("CSV (simple table)") }
                    MenuItem { text: qsTr("JSON (recommended)") }
                }
            }

            TextField {
                id: fileNameField
                width: parent.width
                label: qsTr("File Name")
                placeholderText: qsTr("e.g., notes_backup")
            }

            Button {
                text: qsTr("Export All Notes")
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !processInProgress && fileNameField.text.length > 0 // Button inactive during process
                onClicked: exportData()
            }

            // NEW: Export Statistics Display
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
                color: Theme.highlightColor
            }
            Label {
                width: parent.width - (2 * Theme.paddingLarge) // Adjusted width for margins
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("Warning: Importing will overwrite notes with the same IDs if they already exist in the database. Note tags will be fully updated.")
                anchors.horizontalCenter: parent.horizontalCenter
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

            // NEW: Import Statistics Display
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

            // --- Spacer before Status/Return Button ---
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
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                text: statusText
                visible: statusText !== ""
            }

            Button {
                text: qsTr("Return to Main Page")
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !processInProgress // Visible when process is not active
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("MainPage.qml"));
                }
            }

        }
    }

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

            // NEW: Fetch export/import stats from AppSettings
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
                        "Import Date:", notesImportedCount,
                        "Import Count:", notesImportedCount);
        }

        var updateFileName = function() {
            var fileExtension = exportFormatCombo.currentIndex === 0 ? ".csv" : ".json";
            var baseName = qsTr("notes_backup_") + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
            fileNameField.text = baseName + fileExtension;
        };
        updateFileName();
        exportFormatCombo.currentIndexChanged.connect(updateFileName);
        console.log(qsTr("APP_DEBUG: Export/Import Page: Component.onCompleted finished."));
    }

    // --- EXPORT LOGIC ---
    function exportData() {
        processInProgress = true; // Show indicator
        statusText = qsTr("Gathering data for export...");
        console.log(qsTr("APP_DEBUG: exportData started."));

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
                var generatedData;
                if (exportFormatCombo.currentIndex === 0) { // CSV
                    generatedData = generateCsv(notes);
                } else { // JSON
                    generatedData = generateJson(notes);
                }

                var finalPath = documentsPathConfig.value + "/" + fileNameField.text;
                console.log(qsTr("APP_DEBUG: Attempting to write file to: ") + finalPath);
                writeToFile(finalPath, generatedData); // Call save function
            },
            // 2. Error callback function
            function(error) {
                console.error(qsTr("APP_DEBUG: getNotesForExport FAILED: ") + error.message);
                statusText = qsTr("Export error: ") + error.message;
                processInProgress = false;
            }
        );
        console.log(qsTr("APP_DEBUG: exportData finished, waiting for callbacks."));
    }

    function generateCsv(data) {

        var headers = ["id", "title", "content", "color", "pinned", "deleted", "archived", "created_at", "updated_at", "tags"]; // These headers are usually not localized as they are internal CSV/JSON format
        var csv = headers.join(",") + "\n";
        var escapeCsvField = function(field) {
            return "\"" + String(field || '').replace(/"/g, '""') + "\"";
        };
        for (var i = 0; i < data.length; i++) {
            var note = data[i];
            var row = [
                note.id,
                escapeCsvField(note.title),
                escapeCsvField(note.content),
                escapeCsvField(note.color),
                note.pinned ? 1 : 0,
                note.deleted ? 1 : 0,
                note.archived ? 1 : 0,
                escapeCsvField(note.created_at),
                escapeCsvField(note.updated_at),
                escapeCsvField(note.tags.join(';'))
            ];
            csv += row.join(",") + "\n";
        }
        return csv;
    }

    function generateJson(data) {
        return JSON.stringify(data, null, 2);
    }

    function writeToFile(filePath, textData) {
        statusText = qsTr("Saving file...");
        console.log(qsTr("APP_DEBUG: writeToFile started for path: ") + filePath);

        try {
            // Attempt to use global FileIO object if provided (from C++)
            if (typeof FileIO !== 'undefined' && FileIO.write) {
                FileIO.write(filePath, textData);
                console.log(qsTr("APP_DEBUG: File saved via FileIO: ") + filePath);
                // Continue updating statistics and showing dialog
                var notesCount = (exportFormatCombo.currentIndex === 0)
                                 ? (textData.split('\n').length - 2) // For CSV: minus header and potential empty line
                                 : JSON.parse(textData).length; // For JSON

                DB.updateLastExportDate();
                DB.updateNotesExportedCount(notesCount);

                // NEW: Update QML properties after successful export
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
                    var notesCount = (exportFormatCombo.currentIndex === 0)
                                     ? (textData.split('\n').length - 2)
                                     : JSON.parse(textData).length;

                    DB.updateLastExportDate();
                    DB.updateNotesExportedCount(notesCount);

                    // NEW: Update QML properties after successful export
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
                    return;
                }
            }

            if (fileContent) {
                var notes;
                // --- CHANGE HERE: Using regular expressions ---
                // Check if the string ends with ".json"
                if (/\.json$/.test(absoluteFilePathString)) { // <--- CHANGED: .json
                    notes = JSON.parse(fileContent);
                }
                // Check if the string ends with ".csv"
                else if (/\.csv$/.test(absoluteFilePathString)) { // <--- CHANGED: .csv
                    notes = parseCsv(fileContent);
                } else {
                    statusText = qsTr("Unsupported file format.");
                    processInProgress = false;
                    return;
                }

                if (notes && notes.length > 0) {
                    statusText = qsTr("Importing ") + notes.length + qsTr(" notes...");
                    var importedCount = 0; // Declare outside transaction for scope

                    DB.db.transaction(
                        function(tx) { // Transaction callback
                            for (var i = 0; i < notes.length; i++) {
                                DB.addImportedNote(notes[i], tx);
                                importedCount++;
                            }
                        },
                        function(error) { // Error callback
                            statusText = qsTr("Import error: ") + error.message;
                            console.error(qsTr("APP_DEBUG: Error during import transaction: ") + error.message);
                            processInProgress = false;
                        },
                        function() { // Success callback
                            statusText = qsTr("Import completed! Processed: ") + importedCount + qsTr(" notes.");
                            DB.updateLastImportDate();
                            DB.updateNotesImportedCount(importedCount);

                            // NEW: Update QML properties after successful import
                            lastImportDate = DB.getSetting("lastImportDate");
                            notesImportedCount = DB.getSetting("notesImportedCount");

                            processInProgress = false;
                            console.log(qsTr("APP_DEBUG: Import finished. Imported: ") + importedCount);
                        }
                    );
                } else {
                    statusText = qsTr("File contains no notes to import.");
                    processInProgress = false;
                }

            } else {
                statusText = qsTr("File is empty.");
                processInProgress = false;
            }
        } catch (e) {
            statusText = qsTr("File processing error: ") + e.message;
            console.error(qsTr("APP_DEBUG: EXCEPTION caught during file processing for import: ") + e.message);
            processInProgress = false;
        }
    }

    function parseCsv(content) {
        var lines = content.split('\n');
        if (lines.length < 2) return [];
        var headers = lines[0].trim().split(',');
        var notes = [];
        for (var i = 1; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue;
            var values = line.split(',');
            var note = {};
            for(var j = 0; j < headers.length; j++) {
                if (values[j] !== undefined) {
                    note[headers[j].trim()] = values[j].replace(/^"|"$/g, '').replace(/""/g, '"');
                }

            }
            note.id = parseInt(note.id, 10);
            note.pinned = parseInt(note.pinned, 10) === 1;
            note.deleted = parseInt(note.deleted, 10) === 1;
            note.archived = parseInt(note.archived, 10) === 1;
            note.tags = note.tags ? note.tags.split(';') : [];
            if (!isNaN(note.id)) {
               notes.push(note);
            }
        }
        return notes;
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

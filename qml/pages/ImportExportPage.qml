import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0 // FolderPickerPage находится здесь
import QtQuick.Layouts 1.1
import Nemo.Configuration 1.0
import "DatabaseManager.js" as DB
import QtQuick.LocalStorage 2.0

Page {
    id: importExportPage
    property string customBackgroundColor: DB.getThemeColor()
    backgroundColor: customBackgroundColor || "#121218"
    allowedOrientations: Orientation.All
    showNavigationIndicator: false
    property string statusText: ""
    property bool processInProgress: false
    property string selectedExportFormat: "json"

    property bool panelOpen: false

    property var lastExportDate: null
    property int notesExportedCount: 0
    property var lastImportDate: null
    property int notesImportedCount: 0

    // Property to store the selected export directory
    // This will now be initialized from saved settings
    property string selectedExportDirectory: ""  // Initialize as empty, will be set in Component.onCompleted

    ConfigurationValue {
        id: documentsPathConfig
        key: "/desktop/nemo/preferences/documents_path"
        defaultValue: StandardPaths.documents
        onValueChanged: {
            console.log("APP_DEBUG: Documents path is: " + value);
            // This ConfigurationValue is mainly used to provide a fallback default path.
            // selectedExportDirectory is set in Component.onCompleted based on saved settings.
            // We specifically avoid setting selectedExportDirectory here to prevent conflicts with DB loading.
            // The fallback is handled in Component.onCompleted.
        }
    }
    ToastManager {
        id: toastManager
    }

    // FilePickerComponent for import (remains unchanged)
    Component {
        id: filePickerComponent

        FilePickerPage {
            title: qsTr("Select file for import")
            nameFilters: ["*.json", "*.csv"]

            onSelectedContentPropertiesChanged: {
                if (selectedContentProperties !== null) {
                    var filePathRaw = selectedContentProperties.filePath.toString();

                    var filePathClean;
                    if (filePathRaw.indexOf("file://") === 0) {
                        filePathClean = filePathRaw.substring(7);
                    } else {
                        filePathClean = filePathRaw;
                    }
                    importFromFile(filePathClean, newTagForImportField.text.trim());
                }
            }
        }
    }

    // FolderPickerComponent for export
    Component {
        id: folderPickerComponent

        FolderPickerPage { // Using FolderPickerPage
            id: folderSelectPage
            title: qsTr("Select Export Directory")

            onSelectedPathChanged: {
                console.log("APP_DEBUG: FolderPickerPage: selectedPath triggered.");
                console.log("APP_DEBUG: selectedPath (raw):", selectedPath);

                if (selectedPath !== null && selectedPath.filePath !== null) {
                    var folderPathRaw = selectedPath.toString();
                    var folderPathClean;

                    if (folderPathRaw.indexOf("file://") === 0) {
                        folderPathClean = folderPathRaw.substring(7);
                    } else {
                        folderPathClean = folderPathRaw;
                    }
                    importExportPage.selectedExportDirectory = folderPathClean;
                    console.log("APP_DEBUG: Export directory selected via FolderPickerPage: " + importExportPage.selectedExportDirectory);

                    // --- SAVE THE SELECTED DIRECTORY FOR PERSISTENCE ---
                    DB.setSetting("exportDirectoryPath", folderPathClean);
                    console.log("APP_DEBUG: Saved selected export directory: " + folderPathClean);
                    // --- END SAVE ---

                } else {
                    console.warn("APP_DEBUG: Folder selection via FolderPickerPage accepted, but selectedContentProperties or filePath is invalid or empty.");
                    toastManager.show(qsTr("Selected folder path is invalid or empty. Using default documents path."));
                    // No change to selectedExportDirectory, it will retain its previous value (default or last valid)
                }
            }

            onCanceled: {
                console.log("APP_DEBUG: Folder selection via FolderPickerPage cancelled.");
                toastManager.show(qsTr("Folder selection cancelled.")); // Inform the user
            }
        }
    }


    Item {
        id: exportResultDialog
        property bool dialogVisible: false
        property string dialogFileName: ""
        property string dialogFilePath: ""
        property int dialogDataSize: 0
        property int dialogOperationsCount: 0

        signal dismissed()

        onDismissed: {
            dialogVisible = false
        }

        anchors.fill: parent
        visible: dialogVisible
        z: 100

        Rectangle {
            id: overlayRect
            anchors.fill: parent
            color: "#000000"
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            onVisibleChanged: opacity = exportResultDialog.dialogVisible ? 0.5 : 0
            MouseArea {
                anchors.fill: parent
                enabled: exportResultDialog.dialogVisible
                onClicked: { exportResultDialog.dismissed() }
            }
        }

        Rectangle {
            id: exportDialogBody
            color: DB.darkenColor(importExportPage.customBackgroundColor, 0.30)
            radius: Theme.itemSizeSmall / 2
            anchors.centerIn: parent

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            visible: exportResultDialog.dialogVisible
            opacity: 0
            scale: 0.9

            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { PropertyAnimation { property: "scale"; duration: 200; easing.type: Easing.OutBack } }

            onVisibleChanged: {
                if (visible) {
                    exportDialogBody.opacity = 1;
                    exportDialogBody.scale = 1.0;
                } else {
                    exportDialogBody.opacity = 0;
                    exportDialogBody.scale = 0.9;
                }
            }

            width: Math.min(exportResultDialog.width * 0.8, Theme.itemSizeExtraLarge * 8)
            height: exportContentColumn.implicitHeight + (Theme.paddingLarge * 2)

            Column {
                id: exportContentColumn
                width: parent.width - (Theme.paddingLarge * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge

                Label {
                    width: parent.width
                    text: qsTr("Export completed")
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    horizontalAlignment: "AlignHCenter"
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
                    text: qsTr("File: ") + "<b>" + exportResultDialog.dialogFileName + "</b>"
                    textFormat: Text.StyledText
                    horizontalAlignment: "AlignHCenter"
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Path: ") + exportResultDialog.dialogFilePath
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: "AlignHCenter"
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: qsTr("Notes exported: ") + exportResultDialog.dialogOperationsCount
                    horizontalAlignment: "AlignHCenter"
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: qsTr("File size: ") + (exportResultDialog.dialogDataSize / 1024).toFixed(2) + qsTr(" KB")
                    horizontalAlignment: "AlignHCenter"
                }

                Button {
                    text: qsTr("Great!")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        exportResultDialog.dismissed()
                    }
                }
            }
        }
    }

    Item {
        id: importResultDialog
        property bool dialogVisible: false
        property string dialogFileName: ""
        property string dialogFilePath: ""
        property int dialogNotesImportedCount: 0
        property int dialogTagsCreatedCount: 0
        property int dialogNotesSkippedCount: 0
        property int tagsBeforeImportCount: 0

        signal dismissed()

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
                onClicked: {}
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
                    horizontalAlignment: "AlignHCenter"
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
                    horizontalAlignment: "AlignHCenter"
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Path: ") + importResultDialog.dialogFilePath
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    horizontalAlignment: "AlignHCenter"
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: qsTr("Notes imported: ") + importResultDialog.dialogNotesImportedCount
                    horizontalAlignment: "AlignHCenter"
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: qsTr("Tags created: ") + importResultDialog.dialogTagsCreatedCount
                    horizontalAlignment: "AlignHCenter"
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
                    importExportPage.panelOpen = true
                    console.log("Menu button clicked in ImportExportPage → panelOpen = true")
                }
            }
        }

        Label {
            id: headerText
            text: qsTr("Import/Export")
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraLarge
            font.bold: true
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
            anchors.margins: Theme.paddingLarge

            Label {
                id: exportNotes
                text: qsTr("Export notes")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white"
            }

            // --- Export Directory Section, now with FolderPickerPage ---
            RowLayout {
                id: exportActionsRow
                anchors.horizontalCenter: parent.horizontalCenter // Center this row
                width: parent.width - (2 * Theme.paddingLarge) // Give it some horizontal padding
                spacing: Theme.paddingMedium // Spacing between elements in this row

                Button {
                    id: exportDirectoryButton
                    text: qsTr("Select export directory")
                    onClicked: {
                        pageStack.push(folderPickerComponent);
                    }
                }


                Label {
                    Layout.alignment: Qt.AlignHCenter // Center the label itself
                    id: exportPathLabel
                    text: importExportPage.selectedExportDirectory // Bound to selectedExportDirectory
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    verticalAlignment: Text.AlignVCenter
                }
            }
            // --- End Export Directory Section ---

            TextField {
                id: fileNameField
                width: parent.width
                label: qsTr("File Name")
                placeholderText: qsTr("e.g., notes_backup")
            }

            Label {
                text: qsTr("Notes in the trash don't get exported")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeExtraSmall
                font.italic: true
                color: Theme.secondaryColor
            }

            Label {
                text: qsTr("Choose file format")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: "white"
                topPadding: Theme.paddingMedium
            }

            RowLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                Button {
                    text: qsTr("Export as JSON")
                    opacity: selectedExportFormat === "json" ? 1.0 : 0.6
                    onClicked: {
                        selectedExportFormat = "json";
                        fileNameField.text = fileNameField.text.replace(/\.(json|csv)$/, "") + ".json";
                    }
                }

                Button {
                    text: qsTr("Export as CSV")
                    opacity: selectedExportFormat === "csv" ? 1.0 : 0.6
                    onClicked: {
                        selectedExportFormat = "csv";
                        fileNameField.text = fileNameField.text.replace(/\.(json)$/, "") + ".csv";
                    }
                }
            }

            Button {
                text: qsTr("Export all notes")
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !processInProgress && fileNameField.text.length > 0
                onClicked: exportData(selectedExportFormat)
            }

            Label {
                width: parent.width - (2 * Theme.paddingLarge)
                horizontalAlignment: "AlignHCenter"
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

            Rectangle {
                height: Theme.paddingLarge * 2
                width: parent.width
                color: "transparent"
            }

            Label {
                text: qsTr("Import notes")
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: "AlignHCenter"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: "white"
            }

            TextField {
                id: newTagForImportField
                width: parent.width
                label: qsTr("This tag will get added to imported notes")
                placeholderText: qsTr("Add tag to imported notes (optional)")
            }

            Button {
                text: qsTr("Import from file")
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !processInProgress
                onClicked: {
                    statusText = "";
                    pageStack.push(filePickerComponent);
                }
            }

            Label {
                width: parent.width - (2 * Theme.paddingLarge)
                horizontalAlignment: "AlignHCenter"
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
                horizontalAlignment: "AlignHCenter"
                color: "white"
                wrapMode: Text.Wrap
                text: statusText
                visible: statusText !== ""
            }
        }
    }

    Component.onCompleted: {
        console.log("APP_DEBUG: Export/Import Page: Component.onCompleted started.");
        DB.initDatabase(LocalStorage)
        if (DB.db === null) {
            console.error("APP_DEBUG: DB.db is NULL after initDatabase call! Export/Import will likely fail.");
            statusText = qsTr("Error: Database not initialized. Please restart the application.");
        } else {
            console.log("APP_DEBUG: DB.db is successfully initialized.");

            lastExportDate = DB.getSetting("lastExportDate");
            notesExportedCount = DB.getSetting("notesExportedCount");
            lastImportDate = DB.getSetting("lastImportDate");
            notesImportedCount = DB.getSetting("notesImportedCount");

            if (notesExportedCount === null) notesExportedCount = 0;
            if (notesImportedCount === null) notesImportedCount = 0;

            console.log("APP_DEBUG: Loaded export/import stats:",
                        "Export Date:", lastExportDate,
                        "Export Count:", notesExportedCount,
                        "Import Date:", lastImportDate,
                        "Import Count:", notesImportedCount);
        }

        var initialBaseName = qsTr("notes_backup_") + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
        fileNameField.text = initialBaseName + ".json";

        // --- LOAD SAVED EXPORT DIRECTORY ---
        var savedExportPath = DB.getSetting("exportDirectoryPath");
        if (savedExportPath && savedExportPath.length > 0) {
            selectedExportDirectory = savedExportPath;
            console.log("APP_DEBUG: Loaded saved export directory from DB: " + selectedExportDirectory);
        } else {
            // If no saved path, use the default documents path
            selectedExportDirectory = documentsPathConfig.value;
            console.log("APP_DEBUG: No saved export directory in DB. Using default documents path: " + selectedExportDirectory);
        }
        // --- END LOAD ---

        console.log("APP_DEBUG: Export/Import Page: Component.onCompleted finished.");
    }

    function generateCsv(data) {
        var headers = ["id", "title", "content", "color", "pinned", "deleted", "archived", "created_at", "updated_at", "tags"];
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
                escapeCsvField(note.tags ? note.tags.join(';') : '')
            ];
            csv += row.join(",") + "\n";
        }
        return csv;
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

    // exportData function (no optionalNewTag parameter, uses selectedExportDirectory)
    function exportData(format) {
        processInProgress = true;
        statusText = qsTr("Gathering data for export...");
        console.log("APP_DEBUG: exportData started. Format: " + format);

        var userFileName = fileNameField.text;
        var finalFileName = userFileName;

        if (format === "json" && finalFileName.indexOf(".json", finalFileName.length - ".json".length) === -1) {
            finalFileName = finalFileName.replace(/\.(csv)$/, "") + ".json";
        } else if (format === "csv" && finalFileName.indexOf(".csv", finalFileName.length - ".csv".length) === -1) {
            finalFileName = finalFileName.replace(/\.(json)$/, "") + ".csv";
        }

        DB.getNotesForExport(
            function(notes) {
                console.log("APP_DEBUG: getNotesForExport SUCCESS. Notes count: " + (notes ? notes.length : 0));
                if (!notes || notes.length === 0) {
                    toastManager.show(qsTr("No notes to export."));
                    statusText = qsTr("");
                    processInProgress = false;
                    return;
                }

                statusText = qsTr("Preparing ") + notes.length + qsTr(" notes...");
                var generatedData;

                if (format === "json") {
                    generatedData = JSON.stringify(notes, null, 2);
                } else if (format === "csv") {
                    generatedData = generateCsv(notes);
                } else {
                    console.error("APP_DEBUG: Unsupported export format: " + format);
                    statusText = qsTr("Error: Unsupported export format.");
                    processInProgress = false;
                    return;
                }

                // Use the dynamically selectedExportDirectory
                var finalPath = importExportPage.selectedExportDirectory + "/" + finalFileName;
                console.log("APP_DEBUG: Attempting to write file to: " + finalPath);
                writeToFile(finalPath, generatedData, notes.length);
            },
            function(error) {
                console.error("APP_DEBUG: getNotesForExport FAILED: " + error.message);
                statusText = qsTr("Export error: ") + error.message;
                processInProgress = false;
            }
        );
        console.log("APP_DEBUG: exportData finished, waiting for callbacks.");
    }

    function writeToFile(filePath, textData, notesCount) {
        statusText = qsTr("Saving file...");
        console.log("APP_DEBUG: writeToFile started for path: " + filePath);

        try {
            if (typeof FileIO !== 'undefined' && FileIO.write) {
                FileIO.write(filePath, textData);
                console.log("APP_DEBUG: File saved via FileIO: " + filePath);

                DB.updateLastExportDate();
                DB.updateNotesExportedCount(notesCount);

                lastExportDate = DB.getSetting("lastExportDate");
                notesExportedCount = DB.getSetting("notesExportedCount");

                exportResultDialog.dialogFileName = filePath.split('/').pop();
                exportResultDialog.dialogFilePath = filePath;
                exportResultDialog.dialogOperationsCount = notesCount;
                exportResultDialog.dialogDataSize = textData.length;
                exportResultDialog.dialogVisible = true;

                statusText = "";
            } else {
                console.warn("APP_DEBUG: FileIO not defined or write method missing, attempting to save via XMLHttpRequest.");
                var xhr = new XMLHttpRequest();
                xhr.open("PUT", "file://" + filePath, false);
                xhr.send(textData);

                if (xhr.status === 0 || xhr.status === 200) {
                    console.log("APP_DEBUG: File saved via XMLHttpRequest: " + filePath);

                    DB.updateLastExportDate();
                    DB.updateNotesExportedCount(notesCount);

                    lastExportDate = DB.getSetting("lastExportDate");
                    notesExportedCount = DB.getSetting("notesExportedCount");

                    exportResultDialog.dialogFileName = filePath.split('/').pop();
                    exportResultDialog.dialogFilePath = filePath;
                    exportResultDialog.dialogOperationsCount = notesCount;
                    exportResultDialog.dialogDataSize = textData.length;
                    exportResultDialog.dialogVisible = true;
                    statusText = "";
                } else {
                    statusText = qsTr("File save error (XHR): ") + xhr.statusText + " (" + xhr.status + ")";
                    console.error("APP_DEBUG: Error saving file via XHR: " + xhr.statusText + " (" + xhr.status + ")");
                }
            }
        } catch (e) {
            console.error("APP_DEBUG: EXCEPTION caught during file saving: " + e.message);
            statusText = qsTr("File save error: ") + e.message;
        } finally {
            processInProgress = false;
            console.log("APP_DEBUG: writeToFile finished.");
        }
    }

    function importFromFile(filePath, optionalNewTagForImport) {
        processInProgress = true;
        var absoluteFilePathString = String(filePath);

        statusText = qsTr("Reading file: ") + absoluteFilePathString.split('/').pop();
        console.log("APP_DEBUG: importFromFile started for path: " + absoluteFilePathString);
        console.log("APP_DEBUG: Type of absoluteFilePathString: " + typeof absoluteFilePathString);
        console.log("APP_DEBUG: Optional tag for import: " + optionalNewTagForImport);

        if (!DB.db) {
            console.error("DB_MGR: Database not initialized for importFromFile.");
            statusText = qsTr("Error: Database not initialized for import.");
            processInProgress = false;
            console.log("APP_DEBUG: processInProgress set to false due to DB not initialized.");
            return;
        }
        var tagsBeforeImportCount = DB.getAllTags().length;
        //console.log("APP_DEBUG: Tags before import: " + tagsBeforeImport);

        try {
            var fileContent;
            if (typeof FileIO !== 'undefined' && FileIO.read) {
                fileContent = FileIO.read(absoluteFilePathString);
                console.log("APP_DEBUG: File read via FileIO: " + absoluteFilePathString);
            } else {
                console.warn("APP_DEBUG: FileIO not defined or read method missing, attempting to read via XMLHttpRequest.");
                var xhr = new XMLHttpRequest();
                xhr.open("GET", "file://" + absoluteFilePathString, false);
                xhr.send();

                if (xhr.status === 0 || xhr.status === 200) {
                    fileContent = xhr.responseText;
                    console.log("APP_DEBUG: File read via XMLHttpRequest: " + absoluteFilePathString);
                } else {
                    statusText = qsTr("File read error (XHR): ") + xhr.statusText + " (" + xhr.status + ")";
                    console.error("APP_DEBUG: Error reading file via XHR: " + xhr.statusText + " (" + xhr.status + ")");
                    processInProgress = false;
                    console.log("APP_DEBUG: processInProgress set to false due to XHR file read error.");
                    return;
                }
            }

            if (fileContent) {
                var notesToImport;
                var fileExtension = absoluteFilePathString.split('.').pop().toLowerCase();

                console.log("APP_DEBUG: File extension detected: " + fileExtension);
                console.log("APP_DEBUG: First 200 chars of fileContent: " + fileContent.substring(0, 200));

                if (fileExtension === "json") {
                    try {
                        notesToImport = JSON.parse(fileContent);
                        console.log("APP_DEBUG: Successfully parsed JSON. Number of notes: " + (notesToImport ? notesToImport.length : 'null/undefined'));
                    } catch (jsonError) {
                        console.error("APP_DEBUG: JSON parsing failed: " + jsonError.message);
                        statusText = qsTr("Error parsing JSON file: ") + jsonError.message;
                        processInProgress = false;
                        return;
                    }
                } else if (fileExtension === "csv") {
                    try {
                        notesToImport = parseCsv(fileContent);
                        console.log("APP_DEBUG: Successfully parsed CSV. Number of notes: " + (notesToImport ? notesToImport.length : 'null/undefined'));
                    } catch (csvError) {
                        console.error("APP_DEBUG: CSV parsing failed: " + csvError.message);
                        statusText = qsTr("Error parsing CSV file: ") + csvError.message;
                        processInProgress = false;
                        return;
                    }
                }
                else {
                    statusText = qsTr("Unsupported file format. Only JSON and CSV are supported.");
                    processInProgress = false;
                    console.log("APP_DEBUG: processInProgress set to false due to unsupported file format.");
                    return;
                }

                console.log("APP_DEBUG: notesToImport variable after parsing attempt:");
                console.log(JSON.stringify(notesToImport, null, 2));


                if (notesToImport && notesToImport.length > 0) {
                    statusText = qsTr("Importing ") + notesToImport.length + qsTr(" notes...");

                    console.log("APP_DEBUG: Calling DB.importNotes...");
                    DB.importNotes(
                        notesToImport,
                        optionalNewTagForImport,
                        function(results) { // successCallback for DB.importNotes
                            console.log("APP_DEBUG: DB.importNotes SUCCESS. Imported: " + results.importedCount + ", Skipped: " + results.skippedCount);

                            notesImportedCount = results.importedCount;
                            lastImportDate = DB.getSetting("lastImportDate");

                            var tagsAfterImportCount = DB.getAllTags().length;
                            var newlyCreatedTagsCount = tagsAfterImportCount - tagsBeforeImportCount;
                            if (newlyCreatedTagsCount < 0) newlyCreatedTagsCount = 0;

                            importResultDialog.dialogFileName = absoluteFilePathString.split('/').pop();
                            importResultDialog.dialogFilePath = absoluteFilePathString;
                            importResultDialog.dialogNotesImportedCount = results.importedCount;
                            importResultDialog.dialogNotesSkippedCount = results.skippedCount;
                            importResultDialog.dialogTagsCreatedCount = newlyCreatedTagsCount;
                            importResultDialog.dialogVisible = true;

                            statusText = "";
                            processInProgress = false;
                            console.log("APP_DEBUG: Import process finished successfully.");
                        },
                        function(error) { // errorCallback for DB.importNotes
                            console.error("APP_DEBUG: DB.importNotes FAILED: " + error.message);
                            statusText = qsTr("Import error: ") + error.message;
                            processInProgress = false;
                        }
                    );
                } else {
                    toastManager.show(qsTr("No valid notes found in file."));
                    statusText = "";
                    processInProgress = false;
                }
            } else {
                statusText = qsTr("File is empty.");
                processInProgress = false;
                console.log("APP_DEBUG: File empty, processInProgress set to false.");
            }
        } catch (e) {
            statusText = qsTr("File processing error: ") + e.message;
            console.error("APP_DEBUG: EXCEPTION caught during file processing for import: " + e.message);
            processInProgress = false;
            console.log("APP_DEBUG: General catch block, processInProgress set to false due to exception.");
        }
    }

    SidePanel {
        id: sidePanelInstance
        open: importExportPage.panelOpen
        onClosed: importExportPage.panelOpen = false
        Component.onCompleted: sidePanelInstance.currentPage = "import/export";
        customBackgroundColor:  DB.darkenColor(importExportPage.customBackgroundColor, 0.30)
        activeSectionColor: importExportPage.customBackgroundColor
    }
}

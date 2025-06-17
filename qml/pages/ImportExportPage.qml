import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0 // ЗАМЕНА: Используем стандартный модуль для выбора файлов
import QtQuick.Layouts 1.1
import "DatabaseManager.js" as DB

Page {
    id: importExportPage
    allowedOrientations: Orientation.All

    property string statusText: ""
    property bool processInProgress: false

    // КОМПОНЕНТ ДЛЯ ВЫБОРА ФАЙЛА (ДЛЯ ИМПОРТА)
    Component {
        id: filePickerComponent

        FilePickerPage {
            title: qsTr("Выберите файл для импорта")
            nameFilters: [qsTr("Резервные копии (*.json *.csv)"), qsTr("JSON файлы (*.json)"), qsTr("CSV файлы (*.csv)")]

            // Этот обработчик сработает, когда пользователь выберет файл
            onSelectedContentPropertiesChanged: {
                if (selectedContentProperties !== null) {
                    var filePath = "" + selectedContentProperties.filePath;
                    // Убираем префикс "file://" из пути
                    if (filePath.indexOf("file://") === 0) {
                        filePath = filePath.substring(7);
                    }
                    // Запускаем импорт с выбранным файлом
                    importFromFile(filePath);
                }
            }
        }
    }


    // --- Основной интерфейс страницы ---
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter

            // --- СЕКЦИЯ ЭКСПОРТА ---
            SectionHeader { text: qsTr("Экспорт заметок") }

            ComboBox {
                id: exportFormatCombo
                label: qsTr("Формат файла")
                width: parent.width
                currentIndex: 1 // JSON по умолчанию
                menu: ContextMenu {
                    MenuItem { text: qsTr("CSV (простая таблица)") }
                    MenuItem { text: qsTr("JSON (рекомендуется)") }
                }
            }

            TextField {
                id: fileNameField
                width: parent.width
                label: qsTr("Имя файла")
                placeholderText: qsTr("Например, notes_backup")
            }

            Button {
                text: qsTr("Экспортировать все заметки")
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !processInProgress && fileNameField.text.length > 0
                onClicked: exportData() // Логика экспорта теперь прямая
            }

            // --- СЕКЦИЯ ИМПОРТА ---
            SectionHeader { text: qsTr("Импорт заметок") }
            Label {
                width: parent.width - 2 * Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("Внимание: импорт перезапишет заметки с одинаковыми ID, если они уже существуют в базе. Теги заметки будут полностью обновлены.")
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Button {
                text: qsTr("Импортировать из файла")
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !processInProgress
                onClicked: {
                    statusText = "";
                    // Открываем страницу выбора файла
                    pageStack.push(filePickerComponent);
                }
            }

            // --- ОБЩИЙ СТАТУС ---
            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: processInProgress
                running: processInProgress
                size: BusyIndicatorSize.Large
            }

            Label {
                id: statusLabel
                width: parent.width - 2 * Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                text: statusText
                visible: statusText !== ""
            }
        }
    }

    // --- ИНИЦИАЛИЗАЦИЯ ---
    Component.onCompleted: {
        var updateFileName = function() {
            var fileExtension = exportFormatCombo.currentIndex === 0 ? ".csv" : ".json";
            var baseName = "notes_backup_" + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
            fileNameField.text = baseName + fileExtension;
        };
        updateFileName();
        exportFormatCombo.currentIndexChanged.connect(updateFileName);
    }

    // --- ЛОГИКА ЭКСПОРТА (ПЕРЕПИСАНА ПОД КОЛБЭКИ) ---
    function exportData() {
        processInProgress = true;
        statusText = qsTr("Сбор данных для экспорта...");

        // Вызываем функцию с двумя колбэками: для успеха и для ошибки
        DB.getNotesForExport(
            // 1. Функция, которая выполнится при успехе
            function(notes) {
                if (!notes || notes.length === 0) {
                    statusText = qsTr("Нет заметок для экспорта.");
                    processInProgress = false;
                    return;
                }

                statusText = qsTr("Подготовка ") + notes.length + qsTr(" заметок...");
                var generatedData;
                if (exportFormatCombo.currentIndex === 0) { // CSV
                    generatedData = generateCsv(notes);
                } else { // JSON
                    generatedData = generateJson(notes);
                }

                var documentsPath = StandardPaths.writableLocation(StandardPaths.DocumentsLocation);
                var finalPath = documentsPath + "/" + fileNameField.text;
                writeToFile(finalPath, generatedData);
            },
            // 2. Функция, которая выполнится при ошибке
            function(error) {
                statusText = qsTr("Ошибка экспорта: ") + error.message;
                processInProgress = false;
            }
        );
    }

    // --- Остальные функции остаются без изменений ---

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
        statusText = qsTr("Сохранение файла...");
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;

            if (xhr.status === 200 || xhr.status === 0) {
                var notesCount = (exportFormatCombo.currentIndex === 0)
                                 ? (textData.split('\n').length - 2)
                                 : JSON.parse(textData).length;

                DB.updateLastExportDate();
                DB.updateNotesExportedCount(notesCount);

                pageStack.push(Qt.resolvedUrl("ExportResultDialog.qml"), {
                    fileName: filePath.split('/').pop(),
                    filePath: filePath,
                    operationsCount: notesCount,
                    dataSize: textData.length,
                    sampleData: textData.substring(0, 250) + (textData.length > 250 ? "..." : "")
                });
                statusText = "";

            } else {
                statusText = qsTr("Ошибка сохранения файла: Код ") + xhr.status;
            }
            processInProgress = false;
        }
        xhr.open("PUT", "file://" + filePath, true);
        xhr.send(textData);
    }

    function importFromFile(filePath) {
        processInProgress = true;
        statusText = qsTr("Чтение файла: ") + filePath.split('/').pop();
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;

            if (xhr.status === 200 || xhr.status === 0) {
                try {
                    var fileContent = xhr.responseText;
                    var notes;
                    statusText = qsTr("Анализ данных...");
                    if (filePath.endsWith(".csv")) {
                        notes = parseCsv(fileContent);
                    } else if (filePath.endsWith(".json")) {
                        notes = JSON.parse(fileContent);
                    } else {
                        throw new Error(qsTr("Неподдерживаемый формат файла."));
                    }
                    if (notes && notes.length > 0) {
                        statusText = qsTr("Найдено ") + notes.length + qsTr(" заметок. Запуск импорта...");
                        DB.db.transaction(function(tx) {
                            for (var i = 0; i < notes.length; i++) {
                                DB.addImportedNote(notes[i], tx);
                            }
                        }, function(error) {
                            statusText = qsTr("Ошибка транзакции при импорте: ") + error.message;
                            processInProgress = false;
                        }, function() {
                            statusText = qsTr("Импорт завершен! Обработано: ") + notes.length + qsTr(" заметок.");
                            DB.updateLastImportDate();
                            DB.updateNotesImportedCount(notes.length);
                            processInProgress = false;
                        });
                    } else {
                        statusText = qsTr("В файле нет заметок для импорта.");
                        processInProgress = false;
                    }
                } catch (e) {
                    statusText = qsTr("Ошибка обработки файла: ") + e.message;
                    processInProgress = false;
                }
            } else {
                statusText = qsTr("Ошибка чтения файла: Код ") + xhr.status;
                processInProgress = false;
            }
        }
        xhr.open("GET", "file://" + filePath, true);
        xhr.send();
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
}

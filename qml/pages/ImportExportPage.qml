// ImportExportPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import QtQuick.Layouts 1.1
import Nemo.Configuration 1.0 // Для получения пути к документам
import "DatabaseManager.js" as DB // Ваш менеджер базы данных



import QtQuick.LocalStorage 2.0 // Explicitly import LocalStorage



Page {
    id: importExportPage
    allowedOrientations: Orientation.All
    showNavigationIndicator: false
    property string statusText: ""
    property bool processInProgress: false

    // ConfigurationValue для получения пути к документам
    ConfigurationValue {
        id: documentsPathConfig
        key: "/desktop/nemo/preferences/documents_path"
        defaultValue: StandardPaths.documents // Запасной вариант
        onValueChanged: {
            console.log(qsTr("APP_DEBUG: Documents path is: ") + value); // Логируем путь, обернул в qsTr
        }
    }

    // КОМПОНЕНТ ДЛЯ ВЫБОРА ФАЙЛА (ДЛЯ ИМПОРТА)
    Component {
        id: filePickerComponent

        FilePickerPage {
            title: qsTr("Выберите файл для импорта")
            // nameFilters: [qsTr("Резервные копии (*.json *.csv)"), qsTr("JSON файлы (*.json)"), qsTr("CSV файлы (*.csv)")] // Эти строки уже были обернуты, закомментировал, чтобы показать, что они не изменились.

            onSelectedContentPropertiesChanged: {
                if (selectedContentProperties !== null) {
                    // Убедитесь, что эта часть осталась как мы поправили:
                    // Используем .toString() для явного получения строки из QUrl или аналогичного объекта
                    var filePathRaw = selectedContentProperties.filePath.toString();

                    // Теперь убираем префикс "file://"
                    var filePathClean;
                    if (filePathRaw.indexOf("file://") === 0) {
                        filePathClean = filePathRaw.substring(7);
                    } else {
                        filePathClean = filePathRaw; // Если префикса нет, используем как есть
                    }
                    // Запускаем импорт с очищенным и гарантированно строковым путем
                    importFromFile(filePathClean); // Передаем уже очищенную строку
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
                enabled: !processInProgress && fileNameField.text.length > 0 // Кнопка неактивна во время процесса
                onClicked: exportData()
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

            Button {
                text: qsTr("Вернуться на главную")
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !processInProgress // Видна, когда процесс не идет
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("MainPage.qml"));
                }
            }

        }
    }

    // --- ИНИЦИАЛИЗАЦИЯ (ОЧЕНЬ ВАЖНОЕ МЕСТО) ---
    Component.onCompleted: {
        console.log(qsTr("APP_DEBUG: Export/Import Page: Component.onCompleted started.")); // обернул в qsTr
        // Инициализация базы данных - ТОЛЬКО ЗДЕСЬ!
        // Передаем LocalStorage, который доступен в QML-контексте, в JS-модуль.
        //DB.initDatabase(LocalStorage);
        DB.initDatabase(LocalStorage)
        // Проверяем, успешно ли инициализировалась база данных
        if (DB.db === null) {
            console.error(qsTr("APP_DEBUG: DB.db is NULL after initDatabase call! Export/Import will likely fail.")); // обернул в qsTr
            statusText = qsTr("Ошибка: База данных не инициализирована. Перезапустите приложение.");
        } else {
            console.log(qsTr("APP_DEBUG: DB.db is successfully initialized.")); // обернул в qsTr
        }

        var updateFileName = function() {
            var fileExtension = exportFormatCombo.currentIndex === 0 ? ".csv" : ".json";
            var baseName = qsTr("notes_backup_") + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss"); // обернул в qsTr
            fileNameField.text = baseName + fileExtension;
        };
        updateFileName();
        exportFormatCombo.currentIndexChanged.connect(updateFileName);
        console.log(qsTr("APP_DEBUG: Export/Import Page: Component.onCompleted finished.")); // обернул в qsTr
    }

    // --- ЛОГИКА ЭКСПОРТА ---
    function exportData() {
        processInProgress = true; // <-- РАСКОММЕНТИРУЙТЕ ЭТО! Показываем индикатор
        statusText = qsTr("Сбор данных для экспорта...");
        console.log(qsTr("APP_DEBUG: exportData started.")); // обернул в qsTr

//        // Проверяем, инициализирована ли DB здесь, перед вызовом getNotesForExport
//        if (!DB.db) {
//            statusText = qsTr("Ошибка: База данных не инициализирована для экспорта. (Повторная проверка)");
//            processInProgress = false;
//            console.error(qsTr("APP_DEBUG: База данных не инициализирована при попытке экспорта.")); // обернул в qsTr
//            return;
//        }

        // Вызываем функцию из DatabaseManager.js
        DB.getNotesForExport(
            // 1. Функция, которая выполнится при успехе
            function(notes) {
                console.log(qsTr("APP_DEBUG: getNotesForExport SUCCESS. Notes count: ") + (notes ? notes.length : 0)); // обернул в qsTr
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

                var finalPath = documentsPathConfig.value + "/" + fileNameField.text;
                console.log(qsTr("APP_DEBUG: Attempting to write file to: ") + finalPath); // обернул в qsTr
                writeToFile(finalPath, generatedData); // Вызов функции сохранения
            },
            // 2. Функция, которая выполнится при ошибке
            function(error) {
                console.error(qsTr("APP_DEBUG: getNotesForExport FAILED: ") + error.message); // обернул в qsTr
                statusText = qsTr("Ошибка экспорта: ") + error.message;
                processInProgress = false;
            }
        );
        console.log(qsTr("APP_DEBUG: exportData finished, waiting for callbacks.")); // обернул в qsTr
    }

    function generateCsv(data) {

        var headers = ["id", "title", "content", "color", "pinned", "deleted", "archived", "created_at", "updated_at", "tags"]; // Эти заголовки обычно не локализуются, т.к. это внутренний формат CSV/JSON
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
        // processInProgress = true; // Уже установлено в exportData
        statusText = qsTr("Сохранение файла...");
        console.log(qsTr("APP_DEBUG: writeToFile started for path: ") + filePath); // обернул в qsTr

        try {
            // Пытаемся использовать глобальный объект FileIO, если он предоставлен (из C++)
            if (typeof FileIO !== 'undefined' && FileIO.write) {
                FileIO.write(filePath, textData);
                console.log(qsTr("APP_DEBUG: File saved via FileIO: ") + filePath); // обернул в qsTr
                // Продолжаем обновлять статистику и показывать диалог
                var notesCount = (exportFormatCombo.currentIndex === 0)
                                 ? (textData.split('\n').length - 2) // Для CSV: минус заголовок и потенциальная пустая строка
                                 : JSON.parse(textData).length; // Для JSON

                DB.updateLastExportDate();
                DB.updateNotesExportedCount(notesCount);

                pageStack.push(Qt.resolvedUrl("ExportResultDialog.qml"), {
                    fileName: filePath.split('/').pop(),
                    filePath: filePath,
                    operationsCount: notesCount,
                    dataSize: textData.length,
                    sampleData: textData.substring(0, 250) + (textData.length > 250 ? "..." : "")
                });
                statusText = ""; // Очищаем статус после завершения диалога
            } else {
                // FALLBACK: Используем XMLHttpRequest для записи файла, если FileIO недоступен
                console.warn(qsTr("APP_DEBUG: FileIO not defined or write method missing, attempting to save via XMLHttpRequest.")); // обернул в qsTr
                var xhr = new XMLHttpRequest();
                // Синхронный PUT запрос на локальный файл. 'file://' обязателен.
                xhr.open("PUT", "file://" + filePath, false);
                xhr.send(textData);

                if (xhr.status === 0 || xhr.status === 200) { // status 0 часто означает успех для локальных файлов
                    console.log(qsTr("APP_DEBUG: File saved via XMLHttpRequest: ") + filePath); // обернул в qsTr
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
                    statusText = qsTr("Ошибка сохранения файла (XHR): ") + xhr.statusText + " (" + xhr.status + ")";
                    console.error(qsTr("APP_DEBUG: Error saving file via XHR: ") + xhr.statusText + " (" + xhr.status + ")"); // обернул в qsTr
                }
            }
        } catch (e) {
            console.error(qsTr("APP_DEBUG: EXCEPTION caught during file saving: ") + e.message); // обернул в qsTr
            statusText = qsTr("Ошибка сохранения файла: ") + e.message;
        } finally {
            processInProgress = false; // Важно всегда сбрасывать индикатор
            console.log(qsTr("APP_DEBUG: writeToFile finished.")); // обернул в qsTr
        }
    }

    // --- ЛОГИКА ИМПОРТА (без изменений) ---
    function importFromFile(filePath) {
        processInProgress = true;
        var absoluteFilePathString = String(filePath); // Оставляем эту строку для надежности

        statusText = qsTr("Чтение файла: ") + absoluteFilePathString.split('/').pop();
        console.log(qsTr("APP_DEBUG: importFromFile started for path: ") + absoluteFilePathString); // обернул в qsTr
        console.log(qsTr("APP_DEBUG: Type of absoluteFilePathString: ") + typeof absoluteFilePathString); // обернул в qsTr

        if (!DB.db) {
            console.error(qsTr("DB_MGR: Database not initialized for importFromFile.")); // обернул в qsTr
            statusText = qsTr("Ошибка: База данных не инициализирована для импорта.");
            processInProgress = false;
            return;
        }

        try {
            var fileContent;
            if (typeof FileIO !== 'undefined' && FileIO.read) {
                fileContent = FileIO.read(absoluteFilePathString);
                console.log(qsTr("APP_DEBUG: File read via FileIO: ") + absoluteFilePathString); // обернул в qsTr
            } else {
                console.warn(qsTr("APP_DEBUG: FileIO not defined or read method missing, attempting to read via XMLHttpRequest.")); // обернул в qsTr
                var xhr = new XMLHttpRequest();
                xhr.open("GET", "file://" + absoluteFilePathString, false);
                xhr.send();

                if (xhr.status === 0 || xhr.status === 200) {
                    fileContent = xhr.responseText;
                    console.log(qsTr("APP_DEBUG: File read via XMLHttpRequest: ") + absoluteFilePathString); // обернул в qsTr
                } else {
                    statusText = qsTr("Ошибка чтения файла (XHR): ") + xhr.statusText + " (" + xhr.status + ")";
                    console.error(qsTr("APP_DEBUG: Error reading file via XHR: ") + xhr.statusText + " (" + xhr.status + ")"); // обернул в qsTr
                    processInProgress = false;
                    return;
                }
            }

            if (fileContent) {
                var notes;
                // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Использование регулярных выражений ---
                // Проверяем, заканчивается ли строка на ".json"
                if (/\.json$/.test(absoluteFilePathString)) { // <--- ИЗМЕНЕНО: .json
                    notes = JSON.parse(fileContent);
                }
                // Проверяем, заканчивается ли строка на ".csv"
                else if (/\.csv$/.test(absoluteFilePathString)) { // <--- ИЗМЕНЕНО: .csv
                    notes = parseCsv(fileContent);
                } else {
                    statusText = qsTr("Неподдерживаемый формат файла.");
                    processInProgress = false;
                    return;
                }

                if (notes && notes.length > 0) {
                    statusText = qsTr("Импорт ") + notes.length + qsTr(" заметок...");
                    var importedCount = 0;
                    DB.db.transaction(function(tx) {
                        for (var i = 0; i < notes.length; i++) {
                            DB.addImportedNote(notes[i], tx);
                            importedCount++;
                            console.log(importedCount); // Это отладочный лог, можно оставить без qsTr, если не предполагается для пользователя.
                        }


                        console.log(qsTr("test")); // обернул в qsTr

                    });
                    console.log(qsTr("test2")); // обернул в qsTr
//                    , function(error) {
//                        console.log(qsTr("test1")); // обернул в qsTr
//                        statusText = qsTr("Ошибка импорта: ") + error.message;
//                        console.error(qsTr("APP_DEBUG: Error during import transaction: ") + error.message); // обернул в qsTr
//                        processInProgress = false;


//                        console.log(qsTr("test1")); // обернул в qsTr
//                    }, function() {
//                        console.log(qsTr("test2")); // обернул в qsTr
//                        statusText = qsTr("Импорт завершен! Обработано: ") + importedCount + qsTr(" заметок."); // обернул в qsTr
//                        DB.updateLastImportDate();
//                        DB.updateNotesImportedCount(importedCount);
//                        processInProgress = false;
//                        console.log(qsTr("APP_DEBUG: Import finished. Imported: ") + importedCount); // обернул в qsTr


//                        console.log(qsTr("test3")); // обернул в qsTr
//                    }
//                    );
                } else {
                    statusText = qsTr("Файл не содержит заметок для импорта.");
                    processInProgress = false;
                }

            } else {
                statusText = qsTr("Файл пуст.");
                processInProgress = false;
            }
        } catch (e) {
            statusText = qsTr("Ошибка обработки файла: ") + e.message;
            console.error(qsTr("APP_DEBUG: EXCEPTION caught during file processing for import: ") + e.message); // обернул в qsTr
            processInProgress = false;
        }
        processInProgress = false;
        // IMPORTANT: ImportedCount might be undefined here if the transaction callback logic is incomplete or commented out.
        // Make sure 'importedCount' is reliably set before this point if these updates are critical.
        DB.updateLastImportDate();
        DB.updateNotesImportedCount(importedCount); // This will only work if importedCount is set outside the transaction.

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

// ImportExportPage.qml

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import QtQuick.Layouts 1.1
import Nemo.Configuration 1.0 // Для получения пути к документам
import "DatabaseManager.js" as DB // Ваш менеджер базы данных

Page {
    id: importExportPage // Теперь это главная страница для импорта/экспорта
    allowedOrientations: Orientation.All

    property string statusText: ""
    property bool processInProgress: false

    // ConfigurationValue для получения пути к документам
    ConfigurationValue {
        id: documentsPathConfig
        key: "/desktop/nemo/preferences/documents_path"
        defaultValue: StandardPaths.documents // Запасной вариант
    }

    // КОМПОНЕНТ ДЛЯ ВЫБОРА ФАЙЛА (ДЛЯ ИМПОРТА)
    Component {
        id: filePickerComponent

        FilePickerPage {
            title: qsTr("Выберите файл для импорта")
            nameFilters: [qsTr("Резервные копии (*.json *.csv)"), qsTr("JSON файлы (*.json)"), qsTr("CSV файлы (*.csv)")]

            onSelectedContentPropertiesChanged: {
                if (selectedContentProperties !== null) {
                    var filePath = "" + selectedContentProperties.filePath;
                    // Убираем префикс "file://" из пути, если он есть
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
            // якоря top, bottom, verticalCenter, fill или centerIn для items внутри Column не нужны

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
        // Инициализация базы данных
        // Убедитесь, что LocalStorage доступен в вашем контексте
        //DB.initDatabase();

        var updateFileName = function() {
            var fileExtension = exportFormatCombo.currentIndex === 0 ? ".csv" : ".json";
            var baseName = "notes_backup_" + Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss");
            fileNameField.text = baseName + fileExtension;
        };
        updateFileName();
        exportFormatCombo.currentIndexChanged.connect(updateFileName);
    }

    // --- ЛОГИКА ЭКСПОРТА ---
    function exportData() {
        processInProgress = true; // Сразу показываем индикатор прогресса
        statusText = qsTr("Сбор данных для экспорта...");
        statusText = qsTr("Метка 1");

        DB.getNotesForExport(
            // 1. Функция, которая выполнится при успехе
            function(notes) {
                if (!notes || notes.length === 0) {
                    statusText = qsTr("Нет заметок для экспорта.");
                    processInProgress = false;
                    return;
                }



                statusText = qsTr("Метка 1/1");



                statusText = qsTr("Подготовка ") + notes.length + qsTr(" заметок...");
                var generatedData;
                if (exportFormatCombo.currentIndex === 0) { // CSV
                    generatedData = generateCsv(notes);
                } else { // JSON
                    generatedData = generateJson(notes);
                }




                statusText = qsTr("Метка 1/2");




                // Используем значение из ConfigurationValue для пути к документам
                var finalPath = documentsPathConfig.value + "/" + fileNameField.text;
                writeToFile(finalPath, generatedData);
            },
            // 2. Функция, которая выполнится при ошибке
            function(error) {
                statusText = qsTr("Ошибка экспорта: ") + error.message;
                processInProgress = false;
            }
        );
        statusText = qsTr("Метка 2");
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
        processInProgress = true;
        statusText = qsTr("Сохранение файла...");

        try {
            // Пытаемся использовать глобальный объект FileIO, если он предоставлен (как в примере коллеги)
            // Это предпочтительный способ, если у вас есть C++ плагин FileIO
            if (typeof FileIO !== 'undefined' && FileIO.write) {
                FileIO.write(filePath, textData);
                console.log("DB_MGR: Файл сохранен через FileIO: " + filePath);
                // Продолжаем обновлять статистику и показывать диалог
                var notesCount = (exportFormatCombo.currentIndex === 0)
                                 ? (textData.split('\n').length - 2) // Для CSV: минус заголовок и потенциальная пустая строка в конце
                                 : JSON.parse(textData).length; // Для JSON

                DB.updateLastExportDate();
                DB.updateNotesExportedCount(notesCount);

                // Переход на страницу с результатом экспорта
                pageStack.push(Qt.resolvedUrl("ExportResultDialog.qml"), {
                    fileName: filePath.split('/').pop(),
                    filePath: filePath,
                    operationsCount: notesCount,
                    dataSize: textData.length,
                    sampleData: textData.substring(0, 250) + (textData.length > 250 ? "..." : "")
                });
                statusText = ""; // Очищаем статус после завершения
            } else {
                // FALLBACK: Используем XMLHttpRequest для записи файла, если FileIO недоступен
                console.warn("DB_MGR: FileIO не определен, попытка сохранить через XMLHttpRequest.");
                var xhr = new XMLHttpRequest();
                xhr.open("PUT", "file://" + filePath, false); // false делает запрос синхронным
                xhr.send(textData);

                if (xhr.status === 0 || xhr.status === 200) { // status 0 часто означает успех для локальных файлов
                    console.log("DB_MGR: Файл сохранен через XMLHttpRequest: " + filePath);
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
                    console.error("DB_MGR: Ошибка сохранения файла через XHR: " + xhr.statusText + " (" + xhr.status + ")");
                }
            }
        } catch (e) {
            console.error("DB_MGR: Ошибка при сохранении файла: " + e.message);
            statusText = qsTr("Ошибка сохранения файла: ") + e.message;
        } finally {
            processInProgress = false; // Важно всегда сбрасывать индикатор
        }
    }

    // --- ЛОГИКА ИМПОРТА ---
    function importFromFile(filePath) {
        processInProgress = true;
        statusText = qsTr("Чтение файла: ") + filePath.split('/').pop();

        // Проверяем, инициализирована ли DB, перед началом импорта
        if (!DB.db) {
            statusText = qsTr("Ошибка: База данных не инициализирована для импорта.");
            processInProgress = false;
            console.error("DB_MGR: База данных не инициализирована при попытке импорта.");
            return;
        }

        try {
            var fileContent;
            // Пробуем читать через FileIO, если доступен
            if (typeof FileIO !== 'undefined' && FileIO.read) {
                fileContent = FileIO.read(filePath);
                console.log("DB_MGR: Файл прочитан через FileIO: " + filePath);
            } else {
                // FALLBACK: Используем XMLHttpRequest для чтения файла
                console.warn("DB_MGR: FileIO не определен, попытка прочитать через XMLHttpRequest.");
                var xhr = new XMLHttpRequest();
                xhr.open("GET", "file://" + filePath, false); // Синхронный запрос
                xhr.send();

                if (xhr.status === 0 || xhr.status === 200) {
                    fileContent = xhr.responseText;
                    console.log("DB_MGR: Файл прочитан через XMLHttpRequest: " + filePath);
                } else {
                    statusText = qsTr("Ошибка чтения файла (XHR): ") + xhr.statusText + " (" + xhr.status + ")";
                    console.error("DB_MGR: Ошибка чтения файла через XHR: " + xhr.statusText + " (" + xhr.status + ")");
                    processInProgress = false;
                    return;
                }
            }

            if (fileContent) {
                var notes;
                // Определяем формат по расширению файла
                if (filePath.endsWith(".json")) {
                    notes = JSON.parse(fileContent);
                } else if (filePath.endsWith(".csv")) {
                    notes = parseCsv(fileContent);
                } else {
                    statusText = qsTr("Неподдерживаемый формат файла.");
                    processInProgress = false;
                    return;
                }

                if (notes && notes.length > 0) {
                    statusText = qsTr("Импорт ") + notes.length + qsTr(" заметок...");
                    var importedCount = 0;
                    // Оборачиваем импорт всех заметок в одну транзакцию для производительности и целостности
                    DB.db.transaction(function(tx) {
                        for (var i = 0; i < notes.length; i++) {
                            // addImportedNote теперь может использовать переданную транзакцию
                            DB.addImportedNote(notes[i], tx);
                            importedCount++;
                        }
                    }, function(error) {
                        // Обработка ошибок транзакции
                        statusText = qsTr("Ошибка импорта: ") + error.message;
                        console.error("DB_MGR: Ошибка транзакции импорта: " + error.message);
                        processInProgress = false;
                    }, function() {
                        // Успешное завершение транзакции
                        statusText = qsTr("Импорт завершен! Обработано: ") + importedCount + qsTr(" заметок.");
                        DB.updateLastImportDate();
                        DB.updateNotesImportedCount(importedCount);
                        processInProgress = false;
                    });
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
            console.error("DB_MGR: Ошибка обработки файла при импорте: " + e.message);
            processInProgress = false;
        }
    }

    // Вспомогательная функция для парсинга CSV
    function parseCsv(content) {
        var lines = content.split('\n');
        if (lines.length < 2) return []; // Минимум заголовок и одна строка данных
        var headers = lines[0].trim().split(',');
        var notes = [];
        for (var i = 1; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue; // Пропускаем пустые строки
            var values = line.split(',');
            var note = {};
            for(var j = 0; j < headers.length; j++) {
                if (values[j] !== undefined) {
                    // Удаляем внешние кавычки и заменяем двойные кавычки на одинарные внутри поля
                    note[headers[j].trim()] = values[j].replace(/^"|"$/g, '').replace(/""/g, '"');
                }
            }
            // Преобразование типов данных
            note.id = parseInt(note.id, 10);
            note.pinned = parseInt(note.pinned, 10) === 1;
            note.deleted = parseInt(note.deleted, 10) === 1;
            note.archived = parseInt(note.archived, 10) === 1;
            note.tags = note.tags ? note.tags.split(';') : []; // Теги в виде массива
            if (!isNaN(note.id)) { // Добавляем заметку только если ID корректен
               notes.push(note);
            }
        }
        return notes;
    }
}

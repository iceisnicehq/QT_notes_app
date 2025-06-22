/* Студенты РГУ нефти и газа имени И.М. Губкина
 * Поляков К.А., Сабиров Д.С.
 * группы КС-22-03
 * курсовая работа на тему "Разработка приложения для организации заметок с поддержкой тегов и поиска"
 *
 * /qml/services/DatabaseManagerService.js
 * Этот файл является сервисом управления базой данных, который
 * инкапсулирует всю логику взаимодействия с SQLite через LocalStorage.
 * Он отвечает за инициализацию БД, создание таблиц (Notes, Tags, NoteTags, AppSettings)
 * и проведение миграций для обновления структуры.
 *
 * Сервис предоставляет полный набор CRUD-операций для заметок и тегов,
 * управляет настройками приложения (тема, язык), а также реализует
 * сложную логику для поиска, фильтрации, сортировки, импорта/экспорта
 * и массовых операций с заметками.
 * + Миграция БД. В случае расширения структуры необходимо будет проработать версию 3.
 */

var db = null;
var dbName = "AuroraNotesDB";
var dbDescription = "Aurora Notes Database";
var dbSize = 1000000;
var defaultNoteColor = "#1c1d29";

var LATEST_DB_VERSION = 2;
var migrations = [
    {
        version: 1,
        migrate: function(tx) {
            console.log("DB_MIGRATOR: Applying migration to version 1...");
            tx.executeSql(
                'CREATE TABLE Notes (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'pinned BOOLEAN NOT NULL DEFAULT 0, ' +
                'title TEXT, ' +
                'content TEXT, ' +
                'color TEXT, ' + // Убрали DEFAULT, т.к. он будет в миграции v2
                'created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
                'updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP' +
                ')'
            );
            tx.executeSql(
                'CREATE TABLE Tags (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'name TEXT UNIQUE NOT NULL' +
                ')'
            );
            tx.executeSql(
                'CREATE TABLE NoteTags (' +
                'note_id INTEGER NOT NULL, ' +
                'tag_id INTEGER NOT NULL, ' +
                'PRIMARY KEY (note_id, tag_id), ' +
                'FOREIGN KEY(note_id) REFERENCES Notes(id) ON DELETE CASCADE, ' +
                'FOREIGN KEY(tag_id) REFERENCES Tags(id) ON DELETE CASCADE' +
                ')'
            );
            tx.executeSql(
                'CREATE TABLE AppSettings (' +
                'id INTEGER PRIMARY KEY, ' +
                'themeColor TEXT, ' +
                'language TEXT' +
                ')'
            );
             tx.executeSql(
                'INSERT INTO AppSettings (id, themeColor, language) VALUES (?, ?, ?)',
                [1, "#121218", "en"]
            );
        }
    },
    {
        version: 2,
        migrate: function(tx) {
            console.log("DB_MIGRATOR: Applying migration to version 2...");

            tx.executeSql('ALTER TABLE Notes ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT 0');
            tx.executeSql('ALTER TABLE Notes ADD COLUMN archived BOOLEAN NOT NULL DEFAULT 0');
            tx.executeSql('ALTER TABLE Notes ADD COLUMN checksum TEXT');
            tx.executeSql('ALTER TABLE Notes ADD COLUMN color TEXT DEFAULT "' + defaultNoteColor + '"');

            tx.executeSql('ALTER TABLE AppSettings ADD COLUMN lastExportDate TIMESTAMP');
            tx.executeSql('ALTER TABLE AppSettings ADD COLUMN notesExportedCount INTEGER DEFAULT 0');
            tx.executeSql('ALTER TABLE AppSettings ADD COLUMN lastImportDate TIMESTAMP');
            tx.executeSql('ALTER TABLE AppSettings ADD COLUMN notesImportedCount INTEGER DEFAULT 0');
            tx.executeSql('ALTER TABLE AppSettings ADD COLUMN sort_by TEXT');
            tx.executeSql('ALTER TABLE AppSettings ADD COLUMN sort_order TEXT');
            tx.executeSql('ALTER TABLE AppSettings ADD COLUMN color_sort_order TEXT');
            tx.executeSql('ALTER TABLE AppSettings ADD COLUMN exportDirectoryPath TEXT');

            var result = tx.executeSql('SELECT id, pinned, title, content, color, deleted, archived FROM Notes WHERE checksum IS NULL OR checksum = ""');
            if (result.rows.length > 0) {
                console.log('DB_MIGRATOR: Found ' + result.rows.length + ' notes with missing checksums. Populating now.');
                for (var i = 0; i < result.rows.length; i++) {
                    var note = result.rows.item(i);
                    var generatedChecksum = generateNoteChecksum(note);
                    if (generatedChecksum) {
                        tx.executeSql('UPDATE Notes SET checksum = ? WHERE id = ?', [generatedChecksum, note.id]);
                    }
                }
            }
        }
    }
];

function initDatabase(localStorageInstance) {
    if (!localStorageInstance) {
        console.error("DB_MGR: LocalStorage instance not provided to initDatabase.");
        return;
    }
    if (db) return;

    try {
        db = localStorageInstance.openDatabaseSync(dbName, "1.0", dbDescription, dbSize);

        db.transaction(function(tx) {
            // 1. Создаем таблицу для хранения версии БД, если ее нет
            tx.executeSql('CREATE TABLE IF NOT EXISTS DB_Info (version INTEGER)');

            // 2. Получаем текущую версию БД
            var result = tx.executeSql('SELECT version FROM DB_Info');
            var currentVersion = 0;
            if (result.rows.length > 0) {
                currentVersion = result.rows.item(0).version;
            } else {
                // Если таблицы нет или она пуста, вставляем версию 0
                tx.executeSql('INSERT INTO DB_Info (version) VALUES (?)', [0]);
            }

            console.log("DB_MGR: Current DB version: " + currentVersion, " | Target DB version: " + LATEST_DB_VERSION);

            // 3. Последовательно применяем все необходимые миграции
            if (currentVersion < LATEST_DB_VERSION) {
                console.log("DB_MIGRATOR: Database update required. Applying migrations...");

                for (var i = currentVersion; i < LATEST_DB_VERSION; i++) {
                    var migration = migrations[i]; // Получаем миграцию (индекс = версия - 1)
                    if (migration && migration.version === i + 1) {
                        migration.migrate(tx); // Выполняем миграцию
                        // Обновляем версию в БД после успешного выполнения
                        tx.executeSql('UPDATE DB_Info SET version = ?', [migration.version]);
                        console.log("DB_MIGRATOR: Successfully migrated to version " + migration.version);
                    } else {
                        console.error("DB_MIGRATOR: Migration for version " + (i + 1) + " not found! Halting.");
                        throw new Error("Migration failed: Missing migration script for version " + (i + 1));
                    }
                }
            } else {
                console.log("DB_MGR: Database is up to date.");
            }
        });
        console.log("DB_MGR: Database initialization and migration check complete.");
    } catch (e) {
        console.error("DB_MGR: FATAL: Failed to initialize or migrate database: " + e.message);
    }
}

function getSetting(key) {
    if (!db) {
        console.error("DB_MGR: Database not initialized when trying to get setting:", key);
        return null;
    }
    var value = null;
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT ' + key + ' FROM AppSettings WHERE id = 1');
        if (result.rows.length > 0) {
            value = result.rows.item(0)[key];
        }
    });
    return value;
}

function setSetting(key, value) {
    if (!db) {
        console.error("DB_MGR: Database not initialized when trying to set setting:", key);
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE AppSettings SET ' + key + ' = ? WHERE id = 1',
            [value]
        );
        console.log("DB_MGR: Setting '" + key + "' updated to '" + value + "'.");
    });
}

function getThemeColor() {
    if (!db) initDatabase(LocalStorage);
    return getSetting('themeColor');
}

function darkenColor(hex, percentage) {
    if (!hex || typeof hex !== 'string' || hex.length !== 7 || hex[0] !== '#') {
        console.warn("Invalid color format passed to darkenColor:", hex);
        return "#000000";
    }

    var r = parseInt(hex.substring(1, 3), 16);
    var g = parseInt(hex.substring(3, 5), 16);
    var b = parseInt(hex.substring(5, 7), 16);

    if (percentage < 0) {
        var absPercentage = Math.abs(percentage);
        r = Math.round(r + (255 - r) * absPercentage);
        g = Math.round(g + (255 - g) * absPercentage);
        b = Math.round(b + (255 - b) * absPercentage);
    } else {
        r = Math.round(r * (1 - percentage));
        g = Math.round(g * (1 - percentage));
        b = Math.round(b * (1 - percentage));
    }

    r = Math.max(0, Math.min(255, r));
    g = Math.max(0, Math.min(255, g));
    b = Math.max(0, Math.min(255, b));

    var result = "#" +
                 ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
    return result;
}

function setThemeColor(color) {
    if (!db) initDatabase(LocalStorage);
    setSetting('themeColor', color);
}

function getLanguage() {
    if (!db) initDatabase(LocalStorage);
    return getSetting('language');
}

function setLanguage(langCode) {
    if (!db) initDatabase(LocalStorage);
    setSetting('language', langCode);
}

function updateLastExportDate() {
    if (!db) initDatabase(LocalStorage);
    setSetting('lastExportDate', new Date().toISOString());
    console.log("DB_MGR: Last export date updated.");
}

function updateNotesExportedCount(count) {
    if (!db) initDatabase(LocalStorage);
    setSetting('notesExportedCount', count);
    console.log("DB_MGR: Notes exported count updated to: " + count);
}

function updateLastImportDate() {
    if (!db) initDatabase(LocalStorage);
    setSetting('lastImportDate', new Date().toISOString());
    console.log("DB_MGR: Last import date updated.");
}

function updateNotesImportedCount(count) {
    if (!db) initDatabase(LocalStorage);
    setSetting('notesImportedCount', count);
    console.log("DB_MGR: Notes imported count updated to: " + count);
}

function addNoteInternal(tx, pinned, title, content, color, deleted, archived, checksum) {
    if (deleted === undefined || deleted === null) {
        deleted = 0;
    }
    if (archived === undefined || archived === null) {
        archived = 0;
    }
    tx.executeSql(
        'INSERT INTO Notes (pinned, title, content, color, deleted, archived, checksum) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [pinned, title, content, color, deleted, archived, checksum]
    );
    var row = tx.executeSql('SELECT last_insert_rowid() as id');
    return row.rows.item(0).id;
}

function addTagToNoteInternal(tx, noteId, tagName) {
    var tagResult = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [tagName]);
    var tagId;
    if (tagResult.rows.length === 0) {
        tx.executeSql('INSERT INTO Tags (name) VALUES (?)', [tagName]);
        var newTag = tx.executeSql('SELECT last_insert_rowid() as id');
        tagId = newTag.rows.item(0).id;
        console.log("DB_MGR: Tag '" + tagName + "' created and added to note ID " + noteId);
    } else {
        tagId = tagResult.rows.item(0).id;
        console.log("DB_MGR: Tag '" + tagName + "' already exists, linking to note ID " + noteId);
    }
    tx.executeSql(
        'INSERT OR IGNORE INTO NoteTags (note_id, tag_id) VALUES (?, ?)',
        [noteId, tagId]
    );
}

function addTagToNote(noteId, tagName) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        addTagToNoteInternal(tx, noteId, tagName);
    });
}

function deleteTagFromNote(noteId, tagName) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var tagResult = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [tagName]);
        if (tagResult.rows.length > 0) {
            var tagId = tagResult.rows.item(0).id;
            tx.executeSql('DELETE FROM NoteTags WHERE note_id = ? AND tag_id = ?', [noteId, tagId]);
            console.log("DB_MGR: Removed tag '" + tagName + "' from note ID " + noteId);
        } else {
            console.warn("DB_MGR: Attempted to remove non-existent tag '" + tagName + "'.");
        }
    });
}

function getAllNotes() {
    if (!db) initDatabase(LocalStorage);
    var notes = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM Notes WHERE deleted = 0 AND archived = 0 ORDER BY updated_at DESC');
        console.log("DB_MGR: getAllNotes found " + result.rows.length + " non-deleted, non-archived notes.");
        for (var i = 0; i < result.rows.length; i++) {
            var note = result.rows.item(i);
            if (!note.color) {
                note.color = defaultNoteColor;
            }
            note.tags = getTagsForNote(tx, note.id);
            notes.push(note);
        }
    });
    return notes;
}

function getDeletedNotes() {
    if (!db) initDatabase(LocalStorage);
    var notes = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM Notes WHERE deleted = 1 ORDER BY updated_at DESC');
        console.log("DB_MGR: getDeletedNotes found " + result.rows.length + " deleted notes.");
        for (var i = 0; i < result.rows.length; i++) {
            var note = result.rows.item(i);
            if (!note.color) {
                note.color = defaultNoteColor;
            }
            note.tags = getTagsForNote(tx, note.id);
            notes.push(note);
        }
    });
    console.log("DB_MGR: Returning " + notes.length + " deleted notes from getDeletedNotes()");
    return notes;
}

function getArchivedNotes() {
    if (!db) initDatabase(LocalStorage);
    var notes = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM Notes WHERE archived = 1 ORDER BY updated_at DESC');
        console.log("DB_MGR: getArchivedNotes found " + result.rows.length + " archived notes.");
        for (var i = 0; i < result.rows.length; i++) {
            var note = result.rows.item(i);
            if (!note.color) {
                note.color = defaultNoteColor;
            }
            note.tags = getTagsForNote(tx, note.id);
            notes.push(note);
        }
    });
    return notes;
}

function getTagsForNote(tx_param, noteId) {
    var tempTags = [];
    if (!tx_param) {
        if (!db) initDatabase(LocalStorage);
        db.readTransaction(function(tx) {
            var res = tx.executeSql(
                'SELECT t.name FROM Tags t JOIN NoteTags nt ON t.id = nt.tag_id WHERE nt.note_id = ?',
                [noteId]
            );
            for (var i = 0; i < res.rows.length; i++) {
                tempTags.push(res.rows.item(i).name);
            }
        });
    } else {
        var res = tx_param.executeSql(
            'SELECT t.name FROM Tags t JOIN NoteTags nt ON t.id = nt.tag_id WHERE nt.note_id = ?',
            [noteId]
        );
        for (var i = 0; i < res.rows.length; i++) {
            tempTags.push(res.rows.item(i).name);
        }
    }
    return tempTags;
}

function getAllTags() {
    if (!db) initDatabase(LocalStorage);
    var tags = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql(
            'SELECT DISTINCT T.name FROM Tags T ' +
            'LEFT JOIN NoteTags NT ON T.id = NT.tag_id ' +
            'LEFT JOIN Notes N ON NT.note_id = N.id ' +
            'WHERE (N.id IS NULL OR (N.deleted = 0 AND N.archived = 0)) ' +
            'ORDER BY T.name ASC'
        );
        console.log("DB_MGR: getAllTags found " + result.rows.length + " tags.");
        for (var i = 0; i < result.rows.length; i++) {
            tags.push(result.rows.item(i).name);
        }
    });
    return tags;
}

function getAllTagsWithCounts() {
    if (!db) initDatabase(LocalStorage);
    var tagsWithCounts = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql(
            'SELECT t.name, COUNT(nt.note_id) as count ' +
            'FROM Tags t ' +
            'LEFT JOIN NoteTags nt ON t.id = nt.tag_id ' +
            'LEFT JOIN Notes n ON nt.note_id = n.id ' +
            'WHERE (n.id IS NULL OR (n.deleted = 0 AND n.archived = 0)) ' +
            'GROUP BY t.name ' +
            'ORDER BY count DESC'
        );
        console.log("DB_MGR: getAllTagsWithCounts found " + result.rows.length + " tags with counts.");
        for (var i = 0; i < result.rows.length; i++) {
            tagsWithCounts.push({
                name: result.rows.item(i).name,
                count: result.rows.item(i).count
            });
        }
    });
    return tagsWithCounts;
}

function addNote(pinned, title, content, tags, color) {
    if (!db) initDatabase(LocalStorage);
    var returnedNoteId = -1;
    if (color === undefined || color === null || color === "") {
        color = defaultNoteColor;
    }

    var tempNoteForChecksum = { pinned: pinned, title: title, content: content, color: color, tags: tags };
    var noteChecksum = generateNoteChecksum(tempNoteForChecksum);
    if (!noteChecksum) {
        console.error("DB_MGR: Failed to generate checksum for new note. Aborting addNote.");
        return -1;
    }
    db.transaction(function(tx) {
        returnedNoteId = addNoteInternal(tx, pinned, title, content, color, 0, 0, noteChecksum);
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, returnedNoteId, tags[i]);
        }
    });
    console.log("DB_MGR: New note added with ID:", returnedNoteId, "and checksum:", noteChecksum);
    return returnedNoteId;
}

function updateNote(id, pinned, title, content, tags, color) {
    if (!db) initDatabase(LocalStorage);
    if (color === undefined || color === null || color === "") {
        color = defaultNoteColor;
    }

    var tempNoteForChecksum = { id: id, pinned: pinned, title: title, content: content, color: color, tags: tags };
    var newChecksum = generateNoteChecksum(tempNoteForChecksum);

    if (!newChecksum) {
        console.error("DB_MGR: Failed to generate checksum for updated note. Aborting updateNote.");
        return;
    }

    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE Notes SET pinned = ?, title = ?, content = ?, color = ?, checksum = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [pinned, title, content, color, newChecksum, id]
        );
        tx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [id]);
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, id, tags[i]);
        }
    });
    console.log("DB_MGR: Note updated with ID: ${id} and new checksum: ${newChecksum}");
}

function deleteNote(id) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var res = tx.executeSql('SELECT * FROM Notes WHERE id = ?', [id]);
        if (res.rows.length > 0) {
            var noteData = res.rows.item(0);
            noteData.deleted = 1;
            noteData.archived = 0;
            noteData.tags = getTagsForNote(tx, id);

            var newChecksum = generateNoteChecksum(noteData);

            tx.executeSql(
                'UPDATE Notes SET deleted = 1, archived = 0, checksum = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                [newChecksum, id]
            );
            console.log("DB_MGR: Note ID " + id + " moved to trash with new checksum.");
        }
    });
}

function restoreNote(id) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var res = tx.executeSql('SELECT * FROM Notes WHERE id = ?', [id]);
        if (res.rows.length > 0) {
            var noteData = res.rows.item(0);
            noteData.deleted = 0;
            noteData.archived = 0;
            noteData.tags = getTagsForNote(tx, id);

            var newChecksum = generateNoteChecksum(noteData);

            tx.executeSql(
                'UPDATE Notes SET deleted = 0, archived = 0, checksum = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                [newChecksum, id]
            );
            console.log("DB_MGR: Note ID " + id + " restored from trash with new checksum.");
        }
    });
}
function archiveNote(id) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var res = tx.executeSql('SELECT * FROM Notes WHERE id = ?', [id]);
        if (res.rows.length > 0) {
            var noteData = res.rows.item(0);
            noteData.archived = 1;
            noteData.deleted = 0;
            noteData.tags = getTagsForNote(tx, id);
            var newChecksum = generateNoteChecksum(noteData);

            tx.executeSql(
                'UPDATE Notes SET archived = 1, deleted = 0, checksum = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                [newChecksum, id]
            );
            console.log("DB_MGR: Note ID " + id + " moved to archive with new checksum.");
        }
    });
}

function unarchiveNote(id) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var res = tx.executeSql('SELECT * FROM Notes WHERE id = ?', [id]);
        if (res.rows.length > 0) {
            var noteData = res.rows.item(0);
            noteData.archived = 0;
            noteData.tags = getTagsForNote(tx, id);

            var newChecksum = generateNoteChecksum(noteData);

            tx.executeSql(
                'UPDATE Notes SET archived = 0, checksum = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                [newChecksum, id]
            );
            console.log("DB_MGR: Note ID " + id + " unarchived with new checksum.");
        }
    });
}

function permanentlyDeleteNote(id) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [id]);
        tx.executeSql('DELETE FROM Notes WHERE id = ?', [id]);
        console.log("DB_MGR: Note ID " + id + " permanently deleted.");
    });
}

function permanentlyDeleteAllNotes() {
    if (!db) {
        console.error("DB_MGR: Database not initialized. Cannot delete all notes.");
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM NoteTags');
        tx.executeSql('DELETE FROM Notes');
        tx.executeSql('DELETE FROM Tags');
        console.log("DB_MGR: All notes and associated tags permanently deleted.");
    });
}

function archiveAllNotes() {
    if (!db) {
        console.error("DB_MGR: Database not initialized. Cannot archive all notes.");
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET archived = 1, updated_at = CURRENT_TIMESTAMP WHERE deleted = 0 AND archived = 0');
        console.log("DB_MGR: All eligible notes moved to archive.");
    });
}

function moveAllNotesToTrash() {
    if (!db) {
        console.error("DB_MGR: Database not initialized. Cannot move all notes to trash.");
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET deleted = 1, archived = 0, updated_at = CURRENT_TIMESTAMP WHERE deleted = 0');
        console.log("DB_MGR: All eligible notes moved to trash.");
    });
}

function permanentlyDeleteExpiredDeletedNotes() {
    if (!db) {
        console.error("DB_MGR: Database not initialized. Cannot clean up expired deleted notes.");
        return 0;
    }

    var deletedCount = 0;
    var now = new Date();
    var thresholdDate = new Date(now);
    thresholdDate.setDate(now.getDate() - 30);

    db.transaction(function(tx) {
        var result = tx.executeSql(
            'SELECT id, updated_at FROM Notes WHERE deleted = 1'
        );

        for (var i = 0; i < result.rows.length; i++) {
            var note = result.rows.item(i);
            var noteDeletionDate = new Date(note.updated_at);

            if (noteDeletionDate < thresholdDate) {
                tx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [note.id]);
                tx.executeSql('DELETE FROM Notes WHERE id = ?', [note.id]);
                deletedCount++;
                console.log("DB_MGR: Permanently deleted expired note ID " + note.id + " (deleted on: " + note.updated_at + ").");
            }
        }
    });
    console.log("DB_MGR: Cleaned up " + deletedCount + " expired deleted notes.");
    return deletedCount;
}

function togglePinned(id, pinned) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET pinned = ? WHERE id = ?', [pinned, id]);
    });
    console.log("DB_MGR: Pinned status toggled for note ID:", id, "to", pinned);
}

function addTag(tagName) {
    if (!db) initDatabase(LocalStorage);
    var tagId = -1;
    db.transaction(function(tx) {
        var result = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [tagName]);
        if (result.rows.length === 0) {
            tx.executeSql('INSERT INTO Tags (name) VALUES (?)', [tagName]);
            var newTag = tx.executeSql('SELECT last_insert_rowid() as id');
            tagId = newTag.rows.item(0).id;
            console.log("DB_MGR: Tag '" + tagName + "' added to Tags table with ID:", tagId);
        } else {
            console.log("DB_MGR: Tag '" + tagName + "' already exists in Tags table.");
            tagId = result.rows.item(0).id;
        }
    });
    return tagId;
}

function updateTagName(oldName, newName) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var oldTagResult = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [oldName]);
        if (oldTagResult.rows.length > 0) {
            var tagId = oldTagResult.rows.item(0).id;
            tx.executeSql('UPDATE Tags SET name = ? WHERE id = ?', [newName, tagId]);
            console.log("DB_MGR: Tag '" + oldName + "' updated to '" + newName + "'");
        } else {
            console.warn("DB_MGR: Attempted to update non-existent tag:", oldName);
        }
    });
}

function deleteTag(tagName) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var tagResult = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [tagName]);
        if (tagResult.rows.length > 0) {
            var tagId = tagResult.rows.item(0).id;
            tx.executeSql('DELETE FROM NoteTags WHERE tag_id = ?', [tagId]);
            tx.executeSql('DELETE FROM Tags WHERE id = ?', [tagId]);
            console.log("DB_MGR: Tag '" + tagName + "' and its associations deleted.");
        } else {
            console.warn("DB_MGR: Attempted to delete non-existent tag:", tagName);
        }
    });
}

function restoreNotes(ids) {
    if (!db) {
        console.error("DB_MGR: Database not initialized.");
        return;
    }
    db.transaction(function(tx) {
        var placeholders = ids.map(function() { return '?'; }).join(',');
                tx.executeSql("UPDATE Notes SET deleted = 0, archived = 0 WHERE id IN (" + placeholders + ")", ids);
        console.log("DB_MGR: Restored notes with IDs:", ids);
    });
}

function permanentlyDeleteNotes(ids) {
    if (!db) {
        console.error("DB_MGR: Database not initialized.");
        return;
    }
    db.transaction(function(tx) {
        var placeholders = ids.map(function() { return '?'; }).join(',');
        tx.executeSql("DELETE FROM NoteTags WHERE note_id IN (" + placeholders + ")", ids);
        tx.executeSql("DELETE FROM Notes WHERE id IN (" + placeholders + ")", ids);
        console.log("DB_MGR: Permanently deleted notes with IDs:", ids);
    });
}

function saveSortSettings(sortBy, sortOrder, colorOrderArray) {
    if (!db) return;
    var colorOrderString = JSON.stringify(colorOrderArray);
    db.transaction(function(tx) {
        tx.executeSql('UPDATE AppSettings SET sort_by = ?, sort_order = ?, color_sort_order = ? WHERE id = 1', [sortBy, sortOrder, colorOrderString]);
        console.log("DB_MGR: Sort settings saved.", sortBy, sortOrder, colorOrderString);
    });
}

function loadSortSettings() {
    if (!db) return null;
    var settings = {};
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT sort_by, sort_order, color_sort_order FROM AppSettings WHERE id = 1');
        if (result.rows.length > 0) {
            var row = result.rows.item(0);
            settings.sortBy = row.sort_by || "updated_at";
            settings.sortOrder = row.sort_order || "desc";
            try {
                settings.colorOrder = JSON.parse(row.color_sort_order) || [];
            } catch (e) {
                settings.colorOrder = [];
            }
        }
    });
    console.log("DB_MGR: Sort settings loaded.", JSON.stringify(settings));
    return settings;
}

function searchNotes(searchText, selectedTagNames, sortBy, sortOrder, customColorOrder) {
    if (!db) return [];
    var notes = [];

    console.log("SEARCH_NOTES: --- New Search Initiated ---");
    console.log("SEARCH_NOTES: searchText:", searchText);
    console.log("SEARCH_NOTES: selectedTagNames:", JSON.stringify(selectedTagNames));
    console.log("SEARCH_NOTES: sortBy:", sortBy);
    console.log("SEARCH_NOTES: sortOrder:", sortOrder);
    console.log("SEARCH_NOTES: customColorOrder:", JSON.stringify(customColorOrder));

    db.readTransaction(function(tx) {
        var query = 'SELECT N.* FROM Notes N ';
        var params = [];
        var whereConditions = ['N.deleted = 0', 'N.archived = 0'];

        if (searchText) {
            var searchTerm = '%' + searchText + '%';
            whereConditions.push('(N.title LIKE ? OR N.content LIKE ?)');
            params.push(searchTerm, searchTerm);
        }

        if (selectedTagNames && selectedTagNames.length > 0) {
            query += 'JOIN NoteTags NT ON N.id = NT.note_id JOIN Tags T ON NT.tag_id = T.id ';
            var tagPlaceholders = selectedTagNames.map(function() { return '?'; }).join(',');
            whereConditions.push('T.name IN (' + tagPlaceholders + ')');
            params = params.concat(selectedTagNames);

            query += 'WHERE ' + whereConditions.join(' AND ') + ' ';

            query += 'GROUP BY N.id HAVING COUNT(DISTINCT T.id) = ' + selectedTagNames.length + ' ';
        } else {
            if (whereConditions.length > 0) {
                query += 'WHERE ' + whereConditions.join(' AND ') + ' ';
            }
        }

        var orderByClause = "";
        var sortDirection = (sortOrder && sortOrder.toLowerCase() === 'asc') ? "ASC" : "DESC";

        if (sortBy === 'color' && customColorOrder && customColorOrder.length > 0) {
            orderByClause = "CASE N.color ";
            for (var i = 0; i < customColorOrder.length; i++) {
                orderByClause += "WHEN ? THEN " + i + " ";
                params.push(customColorOrder[i]);
            }
            orderByClause += "ELSE 999 END, N.updated_at DESC";
        } else {
            var sortMap = {
                "updated_at": "N.updated_at",
                "created_at": "N.created_at",
                "title_alpha": "LOWER(N.title)",
                "title_length": "LENGTH(N.title)",
                "content_length": "LENGTH(N.content)",
                "color": "N.color"
            };
            var sortColumn = sortMap[sortBy] || "N.updated_at";
            orderByClause = sortColumn + " " + sortDirection;
        }

        query += " ORDER BY N.pinned DESC, " + orderByClause;

        console.log("SEARCH_NOTES: SQL Query:", query);
        console.log("SEARCH_NOTES: SQL Params:", JSON.stringify(params));

        var result = tx.executeSql(query, params);

        var tempNotes = [];
        for (var j = 0; j < result.rows.length; j++) {
            var note = result.rows.item(j);
            if (!note.color) { note.color = defaultNoteColor; }
            note.tags = getTagsForNote(tx, note.id);
            tempNotes.push(note);
        }
        notes = tempNotes;
    });

    console.log("SEARCH_NOTES: Found " + notes.length + " notes.");
    if (notes.length > 0) {
        console.log("SEARCH_NOTES: Resulting order (colors of first 5 notes):", JSON.stringify(notes.slice(0, 5).map(function(n) { return n.color; })));
    }
    console.log("SEARCH_NOTES: --- Search Finished ---");

    return notes;
}

function getUniqueNoteColors() {
    if (!db) return [];
    var colors = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT DISTINCT color FROM Notes WHERE color IS NOT NULL AND deleted = 0 AND archived = 0');
        for (var i = 0; i < result.rows.length; i++) {
            colors.push(result.rows.item(i).color);
        }
    });
    console.log("DB_MGR: getUniqueNoteColors() found colors:", JSON.stringify(colors));
    return colors;
}

function bulkMoveToTrash(ids) {
    if (!ids || ids.length === 0) {
        console.warn("DB_MGR: No IDs provided for bulkMoveToTrash.");
        return;
    }
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var placeholders = ids.map(function() { return '?'; }).join(',');
        tx.executeSql("UPDATE Notes SET deleted = 1, archived = 0, updated_at = CURRENT_TIMESTAMP WHERE id IN (" + placeholders + ")", ids);
        console.log("DB_MGR: Bulk moved notes to trash with IDs:", ids);
    });
}

function bulkArchiveNotes(ids) {
    if (!ids || ids.length === 0) {
        console.warn("DB_MGR: No IDs provided for bulkArchiveNotes.");
        return;
    }
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var placeholders = ids.map(function() { return '?'; }).join(',');
        tx.executeSql("UPDATE Notes SET archived = 1, deleted = 0, updated_at = CURRENT_TIMESTAMP WHERE id IN (" + placeholders + ")", ids);
        console.log("DB_MGR: Bulk archived notes with IDs:", ids);
    });
}

function bulkUnarchiveNotes(ids) {
    if (!ids || ids.length === 0) {
        console.warn("DB_MGR: No IDs provided for bulkUnarchiveNotes.");
        return;
    }
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var placeholders = ids.map(function() { return '?'; }).join(',');
        tx.executeSql("UPDATE Notes SET archived = 0, deleted = 0, updated_at = CURRENT_TIMESTAMP WHERE id IN (" + placeholders + ")", ids);
        console.log("DB_MGR: Bulk unarchived notes with IDs:", ids);
    });
}

function simpleStringHash(str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
        var char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash |= 0;
    }
    return (hash >>> 0).toString(16);
}

// Замените старую версию этой функции на новую

function generateNoteChecksum(note) {
    if (!note) {
        console.error("DB_MGR: generateNoteChecksum received null/undefined note.");
        return null;
    }

    var title = String(note.title || "");
    var content = String(note.content || "");
    var color = String(note.color || defaultNoteColor);
    var pinned = String(note.pinned ? "1" : "0");
    var archived = String(note.archived ? "1" : "0");
    var deleted = String(note.deleted ? "1" : "0");

    var data = title + content + color +
               "|pinned:" + pinned +
               "|archived:" + archived +
               "|deleted:" + deleted;

    var checksum = simpleStringHash(data);
    return checksum;
}

function getNotesForExport(successCallback, errorCallback) {
    if (!db) initDatabase(LocalStorage);
    console.log("DB_MGR_DEBUG: getNotesForExport вызвана.");

    if (!db) {
        console.error("DB_MGR_DEBUG: getNotesForExport: База данных НЕ инициализирована (db === null). Невозможно продолжить.");
        if (errorCallback) {
            errorCallback(new Error("База данных не инициализирована."));
        }
        return;
    }
    console.log("DB_MGR_DEBUG: База данных 'db' доступна. Начинаем транзакцию для получения заметок.");

    db.transaction(function(tx) {
        try {
            var notes = [];
            var res = tx.executeSql('SELECT id, pinned, title, content, color, created_at, updated_at, deleted, archived, checksum FROM Notes WHERE deleted = 0 ORDER BY updated_at DESC');
            console.log("DB_MGR_DEBUG: Запрос заметок выполнен. Найдено строк: " + res.rows.length);

            for (var i = 0; i < res.rows.length; i++) {
                var note = res.rows.item(i);
                note.tags = [];
                notes.push(note);
            }

            if (notes.length === 0) {
                console.log("DB_MGR_DEBUG: Нет заметок для экспорта. Вызываем successCallback с пустым массивом.");
                if (successCallback) {
                    successCallback([]);
                }
                return;
            }

            console.log("DB_MGR_DEBUG: Начинаем обработку тегов для " + notes.length + " заметок.");
            for (var j = 0; j < notes.length; j++) {
                var currentNote = notes[j];
                try {
                    var tagRes = tx.executeSql(
                        'SELECT T.name FROM Tags T JOIN NoteTags NT ON T.id = NT.tag_id WHERE NT.note_id = ?',
                        [currentNote.id]
                    );
                    for (var k = 0; k < tagRes.rows.length; k++) {
                        currentNote.tags.push(tagRes.rows.item(k).name);
                    }
                } catch (tagSqlError) {
                    console.error("DB_MGR_DEBUG: Ошибка SQL при получении тегов для заметки ID " + currentNote.id + ": " + tagSqlError.message);
                }
            }
            console.log("DB_MGR_DEBUG: Все теги обработаны.");


            console.log("DB_MGR_DEBUG: Вызываем successCallback с " + notes.length + " заметками.");
            if (successCallback) {
                successCallback(notes);
            }
        } catch (mainSqlError) {
            console.error("DB_MGR_DEBUG: Ошибка выполнения основного SQL-запроса для заметок: " + mainSqlError.message);
            if (errorCallback) {
                errorCallback(mainSqlError);
            }
        }
    }, function(error) {
        console.error("DB_MGR_DEBUG: Ошибка транзакции при получении заметок для экспорта: " + error.message);
        if (errorCallback) {
            errorCallback(error);
        }
    });
}

function addImportedNote(note, tx) {
    console.log("DB_MGR_DEBUG: addImportedNote: Processing note '${note.title}' (ID: ${note.id || 'new'}) for import.");

    var notePinned = note.pinned === undefined ? 0 : note.pinned;
    var noteColor = note.color || defaultNoteColor;
    var noteDeleted = note.deleted === undefined ? 0 : note.deleted;
    var noteArchived = note.archived === undefined ? 0 : note.archived;
    var noteTitle = note.title || "";
    var noteContent = note.content || "";

    var importedNoteChecksum = generateNoteChecksum({
        title: noteTitle,
        content: noteContent,
        color: noteColor,
        pinned: notePinned,
        deleted: noteDeleted,
        archived: noteArchived,
    });

    if (!importedNoteChecksum) {
        console.error("DB_MGR_DEBUG: addImportedNote: Failed to generate checksum for note '${noteTitle}'. Skipping.");
        return null;
    }

    var noteId = addNoteInternal(
        tx,
        notePinned,
        noteTitle,
        noteContent,
        noteColor,
        noteDeleted,
        noteArchived,
        importedNoteChecksum
    );

    if (noteId === null) {
        console.error("DB_MGR_DEBUG: addImportedNote: addNoteInternal failed for note '${noteTitle}'.");
        return null;
    }

    if (note.tags && Array.isArray(note.tags) && note.tags.length > 0) {
        console.log("DB_MGR_DEBUG: addImportedNote: Adding tags for note ID ${noteId}: ${JSON.stringify(note.tags)}");
        for (var j = 0; j < note.tags.length; j++) {
            var currentTag = note.tags[j];
            if (currentTag && currentTag.trim() !== "") {
                 addTagToNoteInternal(tx, noteId, currentTag.trim());
            } else {
                 console.warn("DB_MGR_DEBUG: addImportedNote: Skipping empty tag for note ID ${noteId}.");
            }
        }
    } else {
        console.log("DB_MGR_DEBUG: addImportedNote: No tags to add for note ID ${noteId}.");
    }

    console.log("DB_MGR_DEBUG: addImportedNote: Successfully added imported note with new DB ID: ${noteId} and checksum: ${importedNoteChecksum}");
    return noteId;
}

function importNotes(importedNotes, optionalTagForImport, successCallback, errorCallback) {
    if (!db) {
        initDatabase(LocalStorage);
        if (!db) {
            var errorMsg = "DB_MGR: Database not initialized for importNotes. Cannot proceed.";
            console.error(errorMsg);
            if (errorCallback) errorCallback(new Error(errorMsg));
            return;
        }
    }

    var importedCount = 0;
    var skippedCount = 0;
    var now = new Date();
    var pad = function(num) { return num < 10 ? '0' + num : String(num); };
    var formattedDate = pad(now.getDate()) + pad(now.getMonth() + 1) + (now.getFullYear() % 100) + '_' + pad(now.getHours()) + pad(now.getMinutes());
    var autoGeneratedConflictTag = "import-" + formattedDate;

    console.log("DB_MGR_IMPORT: --- Starting Import Process ---");
    console.log("DB_MGR_IMPORT: Auto-generated conflict tag will be: '" + autoGeneratedConflictTag + "'");
    console.log("DB_MGR_IMPORT: Optional tag from UI: '" + optionalTagForImport + "' (trimmed: '" + (optionalTagForImport ? optionalTagForImport.trim() : '') + "')");


    db.transaction(function(tx) {
        var existingNotesByChecksum = {};
        var existingNoteIds = {};

        try {
            var result = tx.executeSql('SELECT id, checksum FROM Notes');
            for (var i = 0; i < result.rows.length; i++) {
                var existingNote = result.rows.item(i);
                if (existingNote.checksum) {
                    existingNotesByChecksum[existingNote.checksum] = existingNote.id;
                }
                existingNoteIds[existingNote.id] = true;
            }
            console.log("DB_MGR_IMPORT: [INIT] Found " + Object.keys(existingNotesByChecksum).length + " existing notes by checksum.");
            console.log("DB_MGR_IMPORT: [INIT] Total " + Object.keys(existingNoteIds).length + " existing note IDs: " + JSON.stringify(Object.keys(existingNoteIds)));
        } catch (e) {
            console.error("DB_MGR_IMPORT: [FATAL] Error fetching existing notes for comparison: " + e.message);
            if (errorCallback) errorCallback(new Error("DB error: " + e.message));
            return;
        }

        for (var z = 0; z < importedNotes.length; z++) {
            var noteToImport = importedNotes[z];
            console.log("\nDB_MGR_IMPORT: --- Processing Note #" + (z + 1) + ": '" + (noteToImport.title || "No Title") + "' ---");

            noteToImport.pinned = noteToImport.pinned === undefined ? 0 : noteToImport.pinned;
            noteToImport.deleted = noteToImport.deleted === undefined ? 0 : noteToImport.deleted;
            noteToImport.archived = noteToImport.archived === undefined ? 0 : noteToImport.archived;
            noteToImport.color = noteToImport.color || defaultNoteColor;
            if (!noteToImport.tags) {
                noteToImport.tags = [];
            } else if (!Array.isArray(noteToImport.tags)) {
                 noteToImport.tags = [noteToImport.tags];
            }

            var generatedChecksumForImportedNote = generateNoteChecksum(noteToImport);
            console.log("DB_MGR_IMPORT: Generated Checksum for imported note: '" + generatedChecksumForImportedNote + "'");


            if (!generatedChecksumForImportedNote) {
                console.warn("DB_MGR_IMPORT: [SKIPPED] Failed to generate checksum for imported note (title: '" + noteToImport.title + "').");
                skippedCount++;
                continue;
            }

            var importedFileId = noteToImport.id;

            var existingNoteIdByChecksum = existingNotesByChecksum[generatedChecksumForImportedNote];

            console.log("DB_MGR_IMPORT: Comparison - importedFileId: " + importedFileId + " (type: " + typeof importedFileId + ")");
            console.log("DB_MGR_IMPORT: Comparison - existingNoteIdByChecksum (matching checksum): " + existingNoteIdByChecksum);

            if (existingNoteIdByChecksum !== undefined) {
                console.log("DB_MGR_IMPORT: [SKIPPED] Note '" + noteToImport.title + "' (checksum: '" + generatedChecksumForImportedNote + "') is identical to existing local note ID: " + existingNoteIdByChecksum + ".");
                skippedCount++;
            } else {
                var tagToAdd = null;
                console.log("DB_MGR_IMPORT: No exact checksum match found. Considering adding as new note.");

                var isConflictById = (importedFileId !== undefined && existingNoteIds[importedFileId]);
                console.log("DB_MGR_IMPORT: Conflict check - importedFileId exists: " + (importedFileId !== undefined) + ", importedFileId in existingNoteIds map: " + existingNoteIds[importedFileId] + ", Combined isConflictById: " + isConflictById);

                if (optionalTagForImport && optionalTagForImport.trim() !== '') {
                    tagToAdd = optionalTagForImport.trim();
                    console.log("DB_MGR_IMPORT: [ADDING NEW - USER TAG PATH] User provided an optional tag. Tag will be: '" + tagToAdd + "'.");
                } else {
                    tagToAdd = autoGeneratedConflictTag;
                    console.log("DB_MGR_IMPORT: [ADDING NEW - AUTO-GENERATED TAG PATH] No optional tag. Auto-generated tag will be: '" + tagToAdd + "'.");
                }

                if (tagToAdd) {
                    if (noteToImport.tags.indexOf(tagToAdd) === -1) {
                        noteToImport.tags.push(tagToAdd);
                        console.log("DB_MGR_IMPORT: Tag '" + tagToAdd + "' ADDED to noteToImport.tags for '" + noteToImport.title + "'. Note's tags now: " + JSON.stringify(noteToImport.tags));
                    } else {
                        console.log("DB_MGR_IMPORT: Tag '" + tagToAdd + "' already present in noteToImport.tags for '" + noteToImport.title + "'.");
                    }
                } else {
                    console.log("DB_MGR_IMPORT: 'tagToAdd' is null. No tag pushed to noteToImport.tags.");
                }

                var newNoteDbId = addImportedNote(noteToImport, tx);
                if (newNoteDbId !== null) {
                    importedCount++;
                    console.log("DB_MGR_IMPORT: Successfully imported note. New DB ID: " + newNoteDbId + ".");
                } else {
                    skippedCount++;
                    console.error("DB_MGR_IMPORT: Failed to import note '" + noteToImport.title + "'.");
                }
            }
        }

        updateNotesImportedCount(importedCount);
        updateLastImportDate();
        console.log("DB_MGR_IMPORT: --- Import Process Complete ---");
        console.log("DB_MGR_IMPORT: Total Added: " + importedCount + ", Total Skipped: " + skippedCount + ".");
        if (successCallback) {
            successCallback({ importedCount: importedCount, updatedCount: 0, skippedCount: skippedCount });
        }
    }, function(error) {
        console.error("DB_MGR_IMPORT: [FATAL] Transaction failed: " + error.message);
        if (errorCallback) {
            errorCallback(error);
        }
    });
}

function getNoteById(noteId) {
    if (!db) {
        console.error("DB_MGR: Database not initialized when trying to get note by ID:", noteId);
        return null;
    }
    var note = null;
    db.transaction(function(tx) {
        var rs = tx.executeSql('SELECT id, title, content, pinned, created_at, updated_at, color FROM Notes WHERE id = ?', [noteId]);
        if (rs.rows.length > 0) {
            var row = rs.rows.item(0);
            note = {
                id: row.id,
                title: row.title,
                content: row.content,
                pinned: row.pinned === 1,
                created_at: row.created_at,
                updated_at: row.updated_at,
                color: row.color
            };
            var tagRs = tx.executeSql(
                'SELECT T.name FROM Tags T JOIN NoteTags NT ON T.id = NT.tag_id WHERE NT.note_id = ?',
                [noteId]
            );
            var tags = [];
            for (var i = 0; i < tagRs.rows.length; i++) {
                tags.push(tagRs.rows.item(i).name);
            }
            note.tags = tags;
        }
    });
    console.log("DB_MGR: getNoteById for ID " + noteId + " returned:", JSON.stringify(note));
    return note;
}

function bulkPinNotes(noteIds) {
    if (!db) {
        console.error("DB_MGR: Database not initialized", key);
        return null;
    }
    db.transaction(function(tx) {
        for (var i = 0; i < noteIds.length; i++) {
            tx.executeSql('UPDATE Notes SET pinned = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [noteIds[i]]);
        }
    });
    console.log("DB: Bulk pinned notes with IDs:", JSON.stringify(noteIds));
}

function bulkUnpinNotes(noteIds) {
    if (!db) {
        console.error("DB_MGR: Database not initialized", key);
        return null;
    }
    db.transaction(function(tx) {
        for (var i = 0; i < noteIds.length; i++) {
            tx.executeSql('UPDATE Notes SET pinned = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [noteIds[i]]);
        }
    });
    console.log("DB: Bulk unpinned notes with IDs:", JSON.stringify(noteIds));
}

function bulkUpdateNoteColor(noteIds, newColor) {
    if (!noteIds || noteIds.length === 0) {
        console.warn("DB_MGR: No IDs provided for bulkUpdateNoteColor.");
        return;
    }
    if (!db) initDatabase(LocalStorage);

    db.transaction(function(tx) {
        for (var i = 0; i < noteIds.length; i++) {
            var noteId = noteIds[i];

            var currentNote = getNoteById(noteId);
            if (currentNote) {
                currentNote.color = newColor;
                currentNote.pinned = currentNote.pinned ? 1 : 0;
                currentNote.archived = currentNote.archived ? 1 : 0;
                currentNote.deleted = currentNote.deleted ? 1 : 0;

                var newChecksum = generateNoteChecksum(currentNote);

                tx.executeSql(
                    'UPDATE Notes SET color = ?, checksum = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                    [newColor, newChecksum, noteId]
                );
                console.log("DB_MGR: Updated color for note ID:", noteId, "to", newColor, "with new checksum:", newChecksum);
            } else {
                console.warn("DB_MGR: Note with ID:", noteId, "not found for color update. Skipping.");
            }
        }
    });
    console.log("DB_MGR: Bulk updated colors for notes with IDs:", JSON.stringify(noteIds), "to", newColor);
}

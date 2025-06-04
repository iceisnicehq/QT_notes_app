// DatabaseManager.js

.pragma library

var db = null;
var dbName = "AuroraNotesDB";
var dbVersion = "1.0";
var dbDescription = "Aurora Notes Database";
var dbSize = 1000000;

function initDatabase() {
    if (db) return;

    db = LocalStorage.openDatabaseSync(dbName, dbVersion, dbDescription, dbSize);

    db.transaction(function(tx) {
        // Create notes table
        tx.executeSql(
            'CREATE TABLE IF NOT EXISTS Notes (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'pinned BOOLEAN NOT NULL DEFAULT 0, ' +
            'title TEXT NOT NULL, ' +
            'content TEXT NOT NULL, ' +
            'created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
            'updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP' +
            ')'
        );

        // Create tags table
        tx.executeSql(
            'CREATE TABLE IF NOT EXISTS Tags (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'name TEXT UNIQUE NOT NULL' +
            ')'
        );

        // Create note-tag relationship table
        tx.executeSql(
            'CREATE TABLE IF NOT EXISTS NoteTags (' +
            'note_id INTEGER NOT NULL, ' +
            'tag_id INTEGER NOT NULL, ' +
            'PRIMARY KEY (note_id, tag_id), ' +
            'FOREIGN KEY(note_id) REFERENCES Notes(id) ON DELETE CASCADE, ' +
            'FOREIGN KEY(tag_id) REFERENCES Tags(id) ON DELETE CASCADE' +
            ')'
        );
    });

    migrateDummyData();
}

function migrateDummyData() {
    var dummyNotes = [
        // Здесь ваш массив с «заглушечными» заметками, например:
        // { pinned: 1, title: "Test", content: "Content", tags: ["tag1", "tag2"] },
    ];

    db.transaction(function(tx) {
        // Check if we need to migrate
        var result = tx.executeSql('SELECT COUNT(*) as count FROM Notes');
        if (result.rows.item(0).count === 0) {
            // Database is empty, migrate dummy data
            for (var i = 0; i < dummyNotes.length; i++) {
                var note = dummyNotes[i];
                var noteId = addNoteInternal(tx, note.pinned, note.title, note.content);

                // Add tags
                for (var j = 0; j < note.tags.length; j++) {
                    addTagToNoteInternal(tx, noteId, note.tags[j]);
                }
            }
        }
    });
}

// Внутренние функции, которые вызываются внутри текущей транзакции (используют tx)
function addNoteInternal(tx, pinned, title, content) {
    tx.executeSql(
        'INSERT INTO Notes (pinned, title, content) VALUES (?, ?, ?)',
        [pinned, title, content]
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
    } else {
        tagId = tagResult.rows.item(0).id;
    }

    tx.executeSql(
        'INSERT OR IGNORE INTO NoteTags (note_id, tag_id) VALUES (?, ?)',
        [noteId, tagId]
    );
}

// Public функции, которые открывают новую транзакцию
function getAllNotes() {
    initDatabase();
    var notes = [];

    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM Notes ORDER BY created_at DESC');
        for (var i = 0; i < result.rows.length; i++) {
            var note = result.rows.item(i);
            note.tags = getTagsForNote(tx, note.id);
            notes.push(note);
        }
    });

    return notes;
}

function getTagsForNote(tx, noteId) {
    var tags = [];
    var result = tx.executeSql(
        'SELECT t.name FROM Tags t ' +
        'JOIN NoteTags nt ON t.id = nt.tag_id ' +
        'WHERE nt.note_id = ?',
        [noteId]
    );

    for (var i = 0; i < result.rows.length; i++) {
        tags.push(result.rows.item(i).name);
    }
    return tags;
}

function getAllTags() {
    initDatabase();
    var tags = [];

    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT name FROM Tags');
        for (var i = 0; i < result.rows.length; i++) {
            tags.push(result.rows.item(i).name);
        }
    });

    return tags;
}

function addNote(pinned, title, content, tags) {
    initDatabase();
    var noteId;

    db.transaction(function(tx) {
        noteId = addNoteInternal(tx, pinned, title, content);

        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, noteId, tags[i]);
        }
    });

    return noteId;
}

function updateNote(id, pinned, title, content, tags) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE Notes SET pinned = ?, title = ?, content = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [pinned, title, content, id]
        );

        // Удаляем старые связи
        tx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [id]);

        // Добавляем новые теги
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, id, tags[i]);
        }
    });
}

function deleteNote(id) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM Notes WHERE id = ?', [id]);
        // Благодаря ON DELETE CASCADE в NoteTags удалятся все связанные записи
    });
}

function togglePinned(id, pinned) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET pinned = ? WHERE id = ?', [pinned, id]);
    });
}

function initializeWithDummyData() {
    initDatabase();
    db.transaction(function(tx) {
        // Очищаем таблицы
        tx.executeSql('DELETE FROM Notes');
        tx.executeSql('DELETE FROM Tags');
        tx.executeSql('DELETE FROM NoteTags');

        // Добавляем «заглушечные» данные
        var dummyNotes = [
            // Например:
            // { pinned: 0, title: "Пример", content: "Текст", tags: ["demo", "test"] }
        ];

        for (var i = 0; i < dummyNotes.length; i++) {
            var note = dummyNotes[i];
            var noteId = addNoteInternal(tx, note.pinned, note.title, note.content);

            for (var j = 0; j < note.tags.length; j++) {
                addTagToNoteInternal(tx, noteId, note.tags[j]);
            }
        }
    });
}

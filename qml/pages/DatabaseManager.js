// DatabaseManager.js
var db = null;
var dbName = "AuroraNotesDB";
var dbVersion = "1.0";
var dbDescription = "Aurora Notes Database";
var dbSize = 1000000;

function initDatabase() {
    if (db) return;
    try {
        db = LocalStorage.openDatabaseSync(dbName, dbVersion, dbDescription, dbSize);
        db.transaction(function(tx) {
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
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS Tags (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'name TEXT UNIQUE NOT NULL' +
                ')'
            );
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
        console.log("Database initialized successfully.");
    } catch (e) {
        console.error("Failed to open or initialize database: " + e);
    }
}

// Internal helpers
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

// Public functions (No Promises)
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
        'SELECT t.name FROM Tags t JOIN NoteTags nt ON t.id = nt.tag_id WHERE nt.note_id = ?',
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

// *** Crucial Fix Here ***
function addNote(pinned, title, content, tags) {
    initDatabase();
    var returnedNoteId = -1; // Initialize variable to store the ID
    db.transaction(function(tx) {
        returnedNoteId = addNoteInternal(tx, pinned, title, content); // Assign ID here
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, returnedNoteId, tags[i]);
        }
    });
    return returnedNoteId; // Now this will return the actual ID after the transaction completes
}

function updateNote(id, pinned, title, content, tags) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE Notes SET pinned = ?, title = ?, content = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [pinned, title, content, id]
        );
        tx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [id]);
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, id, tags[i]);
        }
    });
    // No return value needed for update
}

function deleteNote(id) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM Notes WHERE id = ?', [id]);
    });
    // No return value needed for delete
}

function togglePinned(id, pinned) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET pinned = ? WHERE id = ?', [pinned, id]);
    });
    // No return value needed for toggle
}

function insertTestData() {
    initDatabase();
    db.transaction(function(tx) {
        // Clear tables first
//        tx.executeSql('DELETE FROM Notes');
//        tx.executeSql('DELETE FROM Tags');
//        tx.executeSql('DELETE FROM NoteTags');

        // Add all notes from Data.notes
        // Make sure 'Data' object is defined if you use this
        if (typeof Data !== 'undefined' && Data.notes) {
            for (var i = 0; i < Data.notes.length; i++) {
                var note = Data.notes[i];
                var noteId = addNoteInternal(tx, note.pinned, note.title, note.content);
                for (var j = 0; j < note.tags.length; j++) {
                    addTagToNoteInternal(tx, noteId, note.tags[j]);
                }
            }
        } else {
            console.warn("Data.notes not found for insertTestData.");
        }
    });
}

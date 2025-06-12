// DatabaseManager.js (UPDATED)

var db = null;
var dbName = "AuroraNotesDB";
var dbVersion = "1.0";
var dbDescription = "Aurora Notes Database";
var dbSize = 1000000;

// Default color to use for new notes if not specified.
// Make sure this matches your application's base background color or a neutral default.
var defaultNoteColor = "#121218"; // Matching your current page background

function initDatabase() {
    if (db) return;
    try {
        db = LocalStorage.openDatabaseSync(dbName, dbVersion, dbDescription, dbSize);
        db.transaction(function(tx) {
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS Notes (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'pinned BOOLEAN NOT NULL DEFAULT 0, ' +
                'title TEXT, ' +
                'content TEXT, ' +
                'color TEXT DEFAULT "' + defaultNoteColor + '", ' + // ADDED: New color column with default
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
            // Handle existing databases without the 'color' column
            // This is a simple migration. For complex migrations, you might need version checks.
            try {
                tx.executeSql('SELECT color FROM Notes LIMIT 1');
            } catch (e) {
                console.log("Adding 'color' column to Notes table.");
                tx.executeSql('ALTER TABLE Notes ADD COLUMN color TEXT DEFAULT "' + defaultNoteColor + '"');
            }
        });
        console.log("Database initialized successfully.");
    } catch (e) {
        console.error("Failed to open or initialize database: " + e);
    }
}

// Internal helpers
function addNoteInternal(tx, pinned, title, content, color) {
    tx.executeSql(
        'INSERT INTO Notes (pinned, title, content, color) VALUES (?, ?, ?, ?)',
        [pinned, title, content, color]
    );
    var row = tx.executeSql('SELECT last_insert_rowid() as id');
    return row.rows.item(0).id;
}

// Internal function to add a tag to a note within a transaction
function addTagToNoteInternal(tx, noteId, tagName) {
    var tagResult = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [tagName]);
    var tagId;
    if (tagResult.rows.length === 0) {
        // Tag doesn't exist, create it
        tx.executeSql('INSERT INTO Tags (name) VALUES (?)', [tagName]);
        var newTag = tx.executeSql('SELECT last_insert_rowid() as id');
        tagId = newTag.rows.item(0).id;
        console.log("Tag '" + tagName + "' created and added to note ID " + noteId);
    } else {
        tagId = tagResult.rows.item(0).id;
        console.log("Tag '" + tagName + "' already exists, linking to note ID " + noteId);
    }
    tx.executeSql(
        'INSERT OR IGNORE INTO NoteTags (note_id, tag_id) VALUES (?, ?)',
        [noteId, tagId]
    );
}

// NEW PUBLIC FUNCTION: Add a tag to an existing note.
// This function can be called directly from QML.
function addTagToNote(noteId, tagName) {
    initDatabase();
    db.transaction(function(tx) {
        addTagToNoteInternal(tx, noteId, tagName);
    });
}

// NEW PUBLIC FUNCTION: Delete a tag from a specific note.
// This function can be called directly from QML.
function deleteTagFromNote(noteId, tagName) {
    initDatabase();
    db.transaction(function(tx) {
        var tagResult = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [tagName]);
        if (tagResult.rows.length > 0) {
            var tagId = tagResult.rows.item(0).id;
            tx.executeSql('DELETE FROM NoteTags WHERE note_id = ? AND tag_id = ?', [noteId, tagId]);
            console.log("Removed tag '" + tagName + "' from note ID " + noteId);
        } else {
            console.warn("Attempted to remove non-existent tag '" + tagName + "'.");
        }
    });
}

// Public functions

function getAllNotes() {
    initDatabase();
    var notes = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM Notes ORDER BY updated_at DESC');
        for (var i = 0; i < result.rows.length; i++) {
            var note = result.rows.item(i);
            // Ensure color is set, even for old entries without it or if default fails
            if (!note.color) {
                note.color = defaultNoteColor;
            }
            // Pass the transaction to getTagsForNote for internal use
            note.tags = getTagsForNote(tx, note.id);
            notes.push(note);
        }
    });
    return notes;
}

// Modified getTagsForNote to either use a provided transaction or run its own readTransaction
function getTagsForNote(tx_param, noteId) {
    initDatabase(); // Ensure DB is initialized
    var tempTags = [];
    if (tx_param) {
        // Use provided transaction if available (for internal use by getAllNotes)
        var res = tx_param.executeSql(
            'SELECT t.name FROM Tags t JOIN NoteTags nt ON t.id = nt.tag_id WHERE nt.note_id = ?',
            [noteId]
        );
        for (var i = 0; i < res.rows.length; i++) {
            tempTags.push(res.rows.item(i).name);
        }
    } else {
        // Create a new read transaction if called externally (e.g., from QML)
        db.readTransaction(function(tx) {
            var res = tx.executeSql(
                'SELECT t.name FROM Tags t JOIN NoteTags nt ON t.id = nt.tag_id WHERE nt.note_id = ?',
                [noteId]
            );
            for (var i = 0; i < res.rows.length; i++) {
                tempTags.push(res.rows.item(i).name);
            }
        });
    }
    return tempTags;
}

function getAllTags() {
    initDatabase();
    var tags = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT name FROM Tags ORDER BY name ASC'); // Added ORDER BY for consistency
        for (var i = 0; i < result.rows.length; i++) {
            tags.push(result.rows.item(i).name);
        }
    });
    return tags;
}

function addNote(pinned, title, content, tags, color) {
    initDatabase();
    var returnedNoteId = -1;
    // Ensure color is not undefined when adding a new note
    if (color === undefined || color === null || color === "") {
        color = defaultNoteColor;
    }
    db.transaction(function(tx) {
        returnedNoteId = addNoteInternal(tx, pinned, title, content, color);
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, returnedNoteId, tags[i]);
        }
    });
    return returnedNoteId;
}

function updateNote(id, pinned, title, content, tags, color) {
    initDatabase();
    // Ensure color is not undefined when updating
    if (color === undefined || color === null || color === "") {
        color = defaultNoteColor;
    }
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE Notes SET pinned = ?, title = ?, content = ?, color = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [pinned, title, content, color, id]
        );
        // Delete existing tag associations and re-add them
        tx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [id]);
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, id, tags[i]);
        }
    });
}

function deleteNote(id) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM Notes WHERE id = ?', [id]);
    });
}

function togglePinned(id, pinned) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET pinned = ? WHERE id = ?', [pinned, id]);
    });
}

function insertTestData() {
    initDatabase();
    db.transaction(function(tx) {
        // Clear tables first
        tx.executeSql('DELETE FROM Notes');
        tx.executeSql('DELETE FROM Tags');
        tx.executeSql('DELETE FROM NoteTags');

        if (typeof Data !== 'undefined' && Data.notes) {
            for (var i = 0; i < Data.notes.length; i++) {
                var note = Data.notes[i];
                // Pass a default color for test data if it's not specified
                var noteColor = note.color || defaultNoteColor; // Use existing color or default
                var noteId = addNoteInternal(tx, note.pinned, note.title, note.content, noteColor);
                for (var j = 0; j < note.tags.length; j++) {
                    addTagToNoteInternal(tx, noteId, note.tags[j]);
                }
            }
        } else {
            console.warn("Data.notes not found for insertTestData.");
        }
    });
}

function getAllTagsWithCounts() {
    initDatabase();
    var tagsWithCounts = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql(
            'SELECT t.name, COUNT(nt.note_id) as count ' +
            'FROM Tags t ' +
            'LEFT JOIN NoteTags nt ON t.id = nt.tag_id ' +
            'GROUP BY t.name ' +
            'ORDER BY t.name ASC'
        );
        for (var i = 0; i < result.rows.length; i++) {
            tagsWithCounts.push({
                name: result.rows.item(i).name,
                count: result.rows.item(i).count
            });
        }
    });
    return tagsWithCounts;
}

function addTag(tagName) {
    initDatabase();
    var tagId = -1;
    db.transaction(function(tx) {
        var result = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [tagName]);
        if (result.rows.length === 0) {
            tx.executeSql('INSERT INTO Tags (name) VALUES (?)', [tagName]);
            var newTag = tx.executeSql('SELECT last_insert_rowid() as id');
            tagId = newTag.rows.item(0).id;
            console.log("Tag '" + tagName + "' added to Tags table with ID:", tagId);
        } else {
            console.log("Tag '" + tagName + "' already exists in Tags table.");
            tagId = result.rows.item(0).id;
        }
    });
    return tagId;
}

function updateTagName(oldName, newName) {
    initDatabase();
    db.transaction(function(tx) {
        var oldTagResult = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [oldName]);
        if (oldTagResult.rows.length > 0) {
            var tagId = oldTagResult.rows.item(0).id;
            tx.executeSql('UPDATE Tags SET name = ? WHERE id = ?', [newName, tagId]);
            console.log("Tag '" + oldName + "' updated to '" + newName + "'");
        } else {
            console.warn("Attempted to update non-existent tag:", oldName);
        }
    });
}

function deleteTag(tagName) {
    initDatabase();
    db.transaction(function(tx) {
        var tagResult = tx.executeSql('SELECT id FROM Tags WHERE name = ?', [tagName]);
        if (tagResult.rows.length > 0) {
            var tagId = tagResult.rows.item(0).id;
            tx.executeSql('DELETE FROM Tags WHERE id = ?', [tagId]);
            console.log("Tag '" + tagName + "' deleted from Tags table.");
        } else {
            console.warn("Attempted to delete non-existent tag:", tagName);
        }
    });
}

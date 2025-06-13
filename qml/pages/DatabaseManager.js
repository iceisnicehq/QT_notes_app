// DatabaseManager.js (UPDATED - with searchNotes function)

var db = null;
var dbName = "AuroraNotesDB";
var dbVersion = "1.0";
var dbDescription = "Aurora Notes Database";
var dbSize = 1000000;

var defaultNoteColor = "#121218";

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
                'color TEXT DEFAULT "' + defaultNoteColor + '", ' +
                'created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
                'updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
                'deleted BOOLEAN NOT NULL DEFAULT 0' +
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
            try {
                tx.executeSql('SELECT color FROM Notes LIMIT 1');
            } catch (e) {
                console.log("DB_MGR: Adding 'color' column to Notes table.");
                tx.executeSql('ALTER TABLE Notes ADD COLUMN color TEXT DEFAULT "' + defaultNoteColor + '"');
            }
            // Handle existing databases without the 'deleted' column
            try {
                tx.executeSql('SELECT deleted FROM Notes LIMIT 1');
            } catch (e) {
                console.log("DB_MGR: Adding 'deleted' column to Notes table.");
                tx.executeSql('ALTER TABLE Notes ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT 0');
            }
        });
        console.log("DB_MGR: Database initialized successfully.");
    } catch (e) {
        console.error("DB_MGR: Failed to open or initialize database: " + e);
    }
}

// CORRECTED LINE: Changed default parameter syntax
function addNoteInternal(tx, pinned, title, content, color, deleted) {
    // Manually set default if 'deleted' is undefined or null
    if (deleted === undefined || deleted === null) {
        deleted = 0;
    }
    tx.executeSql(
        'INSERT INTO Notes (pinned, title, content, color, deleted) VALUES (?, ?, ?, ?, ?)',
        [pinned, title, content, color, deleted]
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
    initDatabase();
    db.transaction(function(tx) {
        addTagToNoteInternal(tx, noteId, tagName);
    });
}

function deleteTagFromNote(noteId, tagName) {
    initDatabase();
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
    initDatabase();
    var notes = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT * FROM Notes WHERE deleted = 0 ORDER BY updated_at DESC');
        console.log("DB_MGR: getAllNotes found " + result.rows.length + " non-deleted notes.");
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
    initDatabase();
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

function getTagsForNote(tx_param, noteId) {
    initDatabase();
    var tempTags = [];
    if (tx_param) {
        var res = tx_param.executeSql(
            'SELECT t.name FROM Tags t JOIN NoteTags nt ON t.id = nt.tag_id WHERE nt.note_id = ?',
            [noteId]
        );
        for (var i = 0; i < res.rows.length; i++) {
            tempTags.push(res.rows.item(i).name);
        }
    } else {
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
        var result = tx.executeSql(
            'SELECT DISTINCT T.name FROM Tags T ' +
            'LEFT JOIN NoteTags NT ON T.id = NT.tag_id ' +
            'LEFT JOIN Notes N ON NT.note_id = N.id ' +
            'WHERE N.id IS NULL OR N.deleted = 0 ' + // Only show tags for non-deleted notes
            'ORDER BY T.name ASC'
        );
        console.log("DB_MGR: getAllTags found " + result.rows.length + " tags.");
        for (var i = 0; i < result.rows.length; i++) {
            tags.push(result.rows.item(i).name);
        }
    });
    return tags;
}

function addNote(pinned, title, content, tags, color) {
    initDatabase();
    var returnedNoteId = -1;
    if (color === undefined || color === null || color === "") {
        color = defaultNoteColor;
    }
    db.transaction(function(tx) {
        // When adding a new note, it's not deleted, so pass 0 explicitly
        returnedNoteId = addNoteInternal(tx, pinned, title, content, color, 0);
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, returnedNoteId, tags[i]);
        }
    });
    console.log("DB_MGR: New note added with ID:", returnedNoteId);
    return returnedNoteId;
}

function updateNote(id, pinned, title, content, tags, color) {
    initDatabase();
    if (color === undefined || color === null || color === "") {
        color = defaultNoteColor;
    }
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE Notes SET pinned = ?, title = ?, content = ?, color = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [pinned, title, content, color, id]
        );
        tx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [id]);
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, id, tags[i]);
        }
    });
    console.log("DB_MGR: Note updated with ID:", id);
}

function deleteNote(id) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET deleted = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [id]);
        console.log("DB_MGR: Note ID " + id + " moved to trash.");
    });
}

function restoreNote(id) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET deleted = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [id]);
        console.log("DB_MGR: Note ID " + id + " restored from trash.");
    });
}

function permanentlyDeleteNote(id) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [id]);
        tx.executeSql('DELETE FROM Notes WHERE id = ?', [id]);
        console.log("DB_MGR: Note ID " + id + " permanently deleted.");
    });
}

function togglePinned(id, pinned) {
    initDatabase();
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET pinned = ? WHERE id = ?', [pinned, id]);
    });
    console.log("DB_MGR: Pinned status toggled for note ID:", id, "to", pinned);
}

function insertTestData() {
    initDatabase();
    db.transaction(function(tx) {
        // Clear all notes, including deleted ones, for a clean test setup
        tx.executeSql('DELETE FROM Notes');
        tx.executeSql('DELETE FROM NoteTags');
        tx.executeSql('DELETE FROM Tags');

        if (typeof Data !== 'undefined' && Data.notes) {
            console.log("DB_MGR: Inserting test data...");
            for (var i = 0; i < Data.notes.length; i++) {
                var note = Data.notes[i];
                var noteColor = note.color || defaultNoteColor;
                // Add notes as non-deleted (explicitly pass 0)
                var noteId = addNoteInternal(tx, note.pinned, note.title, note.content, noteColor, 0);
                for (var j = 0; j < note.tags.length; j++) {
                    addTagToNoteInternal(tx, noteId, note.tags[j]);
                }
            }
            // Add a test note that is already deleted (explicitly pass 1)
            var deletedNoteId = addNoteInternal(tx, false, "Deleted Test Note", "This note should appear in the trash.", defaultNoteColor, 1);
            addTagToNoteInternal(tx, deletedNoteId, "TrashTest");
            console.log("DB_MGR: Added a pre-deleted test note with ID:", deletedNoteId);

        } else {
            console.warn("DB_MGR: Data.notes not found for insertTestData. Skipping test data insertion.");
        }
    });
    console.log("DB_MGR: Test data insertion complete.");
}


function getAllTagsWithCounts() {
    initDatabase();
    var tagsWithCounts = [];
    db.readTransaction(function(tx) {
        var result = tx.executeSql(
            'SELECT t.name, COUNT(nt.note_id) as count ' +
            'FROM Tags t ' +
            'LEFT JOIN NoteTags nt ON t.id = nt.tag_id ' +
            'LEFT JOIN Notes n ON nt.note_id = n.id ' +
            'WHERE n.id IS NULL OR n.deleted = 0 ' +
            'GROUP BY t.name ' +
            'ORDER BY t.name ASC'
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

function addTag(tagName) {
    initDatabase();
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
    initDatabase();
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
    initDatabase();
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
        tx.executeSql("UPDATE Notes SET deleted = 0 WHERE id IN (" + placeholders + ")", ids);
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

// --- NEW FUNCTION: searchNotes ---
function searchNotes(searchText, selectedTagNames) {
    initDatabase();
    var notes = [];
    db.readTransaction(function(tx) {
        var query = 'SELECT N.* FROM Notes N ';
        var params = [];
        var conditions = ['N.deleted = 0']; // Always filter out deleted notes

        if (selectedTagNames && selectedTagNames.length > 0) {
            // Join with NoteTags and Tags to filter by selected tags
            query += 'JOIN NoteTags NT ON N.id = NT.note_id JOIN Tags T ON NT.tag_id = T.id ';
            var tagPlaceholders = selectedTagNames.map(function() { return '?'; }).join(',');
            conditions.push('T.name IN (' + tagPlaceholders + ')');
            params = params.concat(selectedTagNames);

            // Add HAVING clause to ensure notes have ALL selected tags
            query += 'GROUP BY N.id HAVING COUNT(DISTINCT T.id) = ' + selectedTagNames.length;
        }

        if (searchText) {
            var searchTerm = '%' + searchText + '%';
            conditions.push('(N.title LIKE ? OR N.content LIKE ?)');
            params.push(searchTerm, searchTerm);
        }

        if (conditions.length > 0) {
            query += 'WHERE ' + conditions.join(' AND ');
        }

        query += ' ORDER BY N.updated_at DESC';

        console.log("DB_MGR: Executing search query:", query);
        console.log("DB_MGR: With parameters:", params);

        var result = tx.executeSql(query, params);
        console.log("DB_MGR: searchNotes found " + result.rows.length + " notes.");

        for (var i = 0; i < result.rows.length; i++) {
            var note = result.rows.item(i);
            if (!note.color) {
                note.color = defaultNoteColor;
            }
            note.tags = getTagsForNote(tx, note.id); // Get tags for each found note
            notes.push(note);
        }
    });
    return notes;
}

// DatabaseManager.js
var db = null;
var dbName = "1AuroraNotesDB";
var dbVersion = "1.0";
var dbDescription = "Aurora Notes Database";
var dbSize = 1000000;

var defaultNoteColor = "#1c1d29";

function initDatabase(localStorageInstance) {

    // Only proceed if a localStorageInstance is provided and db is null
    if (!localStorageInstance) {
        console.error("DB_MGR: LocalStorage instance not provided to initDatabase.");
        return;
    }
    if (db) return;
    console.log("DB_MGR: Инициализация базы данных...");
    try {
        // Use the passed localStorageInstance
        db = localStorageInstance.openDatabaseSync(dbName, dbVersion, dbDescription, dbSize);
        db.transaction(function(tx) {
            // Create Notes table
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS Notes (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'pinned BOOLEAN NOT NULL DEFAULT 0, ' +
                'title TEXT, ' +
                'content TEXT, ' +
                'color TEXT DEFAULT "' + defaultNoteColor + '", ' +
                'created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
                'updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
                'deleted BOOLEAN NOT NULL DEFAULT 0, ' +
                'archived BOOLEAN NOT NULL DEFAULT 0, ' +
                'checksum TEXT' +
                ')'
            );
            // Create Tags table
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS Tags (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'name TEXT UNIQUE NOT NULL' +
                ')'
            );
            // Create NoteTags join table
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS NoteTags (' +
                'note_id INTEGER NOT NULL, ' +
                'tag_id INTEGER NOT NULL, ' +
                'PRIMARY KEY (note_id, tag_id), ' +
                'FOREIGN KEY(note_id) REFERENCES Notes(id) ON DELETE CASCADE, ' +
                'FOREIGN KEY(tag_id) REFERENCES Tags(id) ON DELETE CASCADE' +
                ')'
            );



            //tx.executeSql("DELETE FROM NoteTags WHERE note_id IN (71, 73, 76, 79);");
            //tx.executeSql("DELETE FROM Notes WHERE id IN (71, 73, 76, 79);");




            // --- Migrations for Notes table (if columns are missing in existing DB) ---
            try {
                tx.executeSql('SELECT color FROM Notes LIMIT 1');
            } catch (e) {
                console.log("DB_MGR: Adding 'color' column to Notes table.");
                tx.executeSql('ALTER TABLE Notes ADD COLUMN color TEXT DEFAULT "' + defaultNoteColor + '"');
            }
            try {
                tx.executeSql('SELECT checksum FROM Notes LIMIT 1');
            } catch (e) {
                console.log("DB_MGR: Adding 'checksum' column to Notes table.");
                tx.executeSql('ALTER TABLE Notes ADD COLUMN checksum TEXT'); // Добавляем столбец checksum
            }
            try {
                tx.executeSql('SELECT deleted FROM Notes LIMIT 1');
            } catch (e) {
                console.log("DB_MGR: Adding 'deleted' column to Notes table.");
                tx.executeSql('ALTER TABLE Notes ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT 0');
            }
            try {
                tx.executeSql('SELECT archived FROM Notes LIMIT 1');
            } catch (e) {
                console.log("DB_MGR: Adding 'archived' column to Notes table.");
                tx.executeSql('ALTER TABLE Notes ADD COLUMN archived BOOLEAN NOT NULL DEFAULT 0');
            }

            // --- AppSettings Table and its Migrations ---
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS AppSettings (' +
                'id INTEGER PRIMARY KEY, ' + // Use a fixed ID (e.g., 1) for a singleton row
                'themeColor TEXT, ' +
                'language TEXT, ' +
                'lastExportDate TIMESTAMP, ' +
                'notesExportedCount INTEGER, ' +
                'lastImportDate TIMESTAMP, ' +
                'notesImportedCount INTEGER' +
                ')'
            );

            // Check if AppSettings table is empty and insert default values if so
            var settingsCount = tx.executeSql('SELECT COUNT(*) AS count FROM AppSettings');
            if (settingsCount.rows.item(0).count === 0) {
                console.log("DB_MGR: AppSettings table is empty, inserting default values.");
                tx.executeSql(
                    'INSERT INTO AppSettings (id, themeColor, language, notesExportedCount, notesImportedCount) ' +
                    'VALUES (?, ?, ?, ?, ?)',
                    [1, "#121218", "en", 0, 0] // Default values: dark theme, English, 0 exported/imported
                );
            }

            // Migrations for AppSettings table (add columns if they are missing in existing DB)
            try { tx.executeSql('SELECT themeColor FROM AppSettings LIMIT 1'); }
            catch (e) { console.log("DB_MGR: Adding 'themeColor' column to AppSettings."); tx.executeSql('ALTER TABLE AppSettings ADD COLUMN themeColor TEXT'); }

            try { tx.executeSql('SELECT language FROM AppSettings LIMIT 1'); }
            catch (e) { console.log("DB_MGR: Adding 'language' column to AppSettings."); tx.executeSql('ALTER TABLE AppSettings ADD COLUMN language TEXT'); }

            try { tx.executeSql('SELECT lastExportDate FROM AppSettings LIMIT 1'); }
            catch (e) { console.log("DB_MGR: Adding 'lastExportDate' column to AppSettings."); tx.executeSql('ALTER TABLE AppSettings ADD COLUMN lastExportDate TIMESTAMP'); }

            try { tx.executeSql('SELECT notesExportedCount FROM AppSettings LIMIT 1'); }
            catch (e) { console.log("DB_MGR: Adding 'notesExportedCount' column to AppSettings."); tx.executeSql('ALTER TABLE AppSettings ADD COLUMN notesExportedCount INTEGER DEFAULT 0'); }

            try { tx.executeSql('SELECT lastImportDate FROM AppSettings LIMIT 1'); }
            catch (e) { console.log("DB_MGR: Adding 'lastImportDate' column to AppSettings."); tx.executeSql('ALTER TABLE AppSettings ADD COLUMN lastImportDate TIMESTAMP'); }

            try { tx.executeSql('SELECT notesImportedCount FROM AppSettings LIMIT 1'); }
            catch (e) { console.log("DB_MGR: Adding 'notesImportedCount' column to AppSettings."); tx.executeSql('ALTER TABLE AppSettings ADD COLUMN notesImportedCount INTEGER DEFAULT 0'); }

            try {
            // Fetch notes that have NULL checksums
            var result = tx.executeSql('SELECT id, pinned, title, content, color, deleted, archived FROM Notes WHERE checksum IS NULL OR checksum = ""');
            if (result.rows.length > 0) {
                console.log('DB_MGR_MIGRATION: Found ${result.rows.length} notes with missing checksums. Populating now.');
                for (var i = 0; i < result.rows.length; i++) {
                    var note = result.rows.item(i);
                    // Construct a temporary note object that generateNoteChecksum expects
                    var tempNote = {
                        id: note.id,
                        pinned: note.pinned,
                        title: note.title,
                        content: note.content,
                        color: note.color,
                        deleted: note.deleted,
                        archived: note.archived,
                        // Tags are not in the Notes table, so we need to fetch them
                        // or generate checksum based on what's available.
                        // For a more accurate checksum, you'd fetch tags here:
                        // var tagsResult = tx.executeSql('SELECT T.name FROM Tags T JOIN NoteTags NT ON T.id = NT.tag_id WHERE NT.note_id = ?', [note.id]);
                        // var noteTags = [];
                        // for (let j = 0; j < tagsResult.rows.length; j++) {
                        //     noteTags.push(tagsResult.rows.item(j).name);
                        // }
                        // tags: noteTags // Add this if generateNoteChecksum needs tags for old notes
                    };

                    // Generate checksum for the old note
                    var generatedChecksum = generateNoteChecksum(tempNote);

                    if (generatedChecksum) {
                        tx.executeSql('UPDATE Notes SET checksum = ? WHERE id = ?', [generatedChecksum, note.id]);
                        console.log('DB_MGR_MIGRATION: Updated note ID ${note.id} with checksum: ${generatedChecksum}');
                    } else {
                        console.warn('DB_MGR_MIGRATION: Failed to generate checksum for note ID ${note.id}. Skipping update.');
                    }
                }
                console.log("DB_MGR_MIGRATION: Checksum migration complete.");
            } else {
                console.log("DB_MGR_MIGRATION: No notes found with missing checksums. Migration skipped.");
            }
        } catch (e) {
            // This catch handles errors specifically during the checksum migration
            console.error("DB_MGR_MIGRATION: Error during checksum migration: " + e.message);
            // Important: Don't re-throw if it's just a migration error.
            // The main DB init should still proceed.
        }





            console.log("DB_MGR: Checking for notes without checksums..."); // добавление в ините
            var notesWithoutChecksum = tx.executeSql('SELECT id, title, content, color FROM Notes WHERE checksum IS NULL');
            if (notesWithoutChecksum.rows.length > 0) {
                console.log("DB_MGR: Found " + notesWithoutChecksum.rows.length + " notes without checksums. Generating them...");
                for (var i = 0; i < notesWithoutChecksum.rows.length; i++) {
                    var note = notesWithoutChecksum.rows.item(i);
                    // Fetch tags separately since generateNoteChecksum needs them
                    // This is less efficient than fetching all notes with tags initially,
                    // but practical for a one-time migration.
                    var noteTags = getTagsForNote(tx, note.id); // Re-use getTagsForNote, ensuring it works with tx
                    var tempNoteForChecksum = {
                        title: note.title,
                        content: note.content,
                        color: note.color,
                        tags: noteTags
                    };
                    var generatedChecksum = generateNoteChecksum(tempNoteForChecksum);

                    if (generatedChecksum) {
                        tx.executeSql('UPDATE Notes SET checksum = ? WHERE id = ?', [generatedChecksum, note.id]);
                        console.log("DB_MGR: Generated checksum for note ID " + note.id);
                    } else {
                        console.warn("DB_MGR: Failed to generate checksum for old note ID " + note.id);
                    }
                }
                console.log("DB_MGR: Finished generating checksums for old notes.");
            } else {
                console.log("DB_MGR: All notes already have checksums.");
            }


        });
        console.log("DB_MGR: Database initialized successfully.");
    } catch (e) {
        console.error("DB_MGR: Failed to open or initialize database: " + e);
    }
}

// Generic function to get a setting
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

// Generic function to set a setting
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

// Specific functions for settings (these will call initDatabase internally if needed)
function getThemeColor() {
    if (!db) initDatabase(LocalStorage); // Attempt to initialize if not already
    return getSetting('themeColor');
}

function darkenColor(hex, percentage) {
    if (!hex || typeof hex !== 'string' || hex.length !== 7 || hex[0] !== '#') {
        console.warn("Invalid color format passed to darkenColor:", hex);
        return "#000000"; // Fallback to black
    }

    var r = parseInt(hex.substring(1, 3), 16);
    var g = parseInt(hex.substring(3, 5), 16);
    var b = parseInt(hex.substring(5, 7), 16);

    if (percentage < 0) {
        // Lighten the color: move towards white (255)
        var absPercentage = Math.abs(percentage);
        r = Math.round(r + (255 - r) * absPercentage);
        g = Math.round(g + (255 - g) * absPercentage);
        b = Math.round(b + (255 - b) * absPercentage);
    } else {
        // Darken the color: move towards black (0)
        r = Math.round(r * (1 - percentage));
        g = Math.round(g * (1 - percentage));
        b = Math.round(b * (1 - percentage));
    }

    // Ensure RGB values stay within the valid range [0, 255]
    r = Math.max(0, Math.min(255, r));
    g = Math.max(0, Math.min(255, g));
    b = Math.max(0, Math.min(255, b));

    // Convert back to hex string and ensure two digits for each component
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
        // Fetch all notes currently marked as deleted
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
    if (!db) initDatabase(LocalStorage);
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
            noteData.deleted = 1; // Устанавливаем новое состояние
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
            noteData.deleted = 0; // Восстанавливаем состояние
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
            noteData.archived = 0; // Восстанавливаем состояние
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
        tx.executeSql('DELETE FROM NoteTags'); // Delete all note-tag associations
        tx.executeSql('DELETE FROM Notes');    // Delete all notes
        tx.executeSql('DELETE FROM Tags');     // Delete all tags 
        console.log("DB_MGR: All notes and associated tags permanently deleted.");
    });
}

function archiveAllNotes() {
    if (!db) {
        console.error("DB_MGR: Database not initialized. Cannot archive all notes.");
        return;
    }
    db.transaction(function(tx) {
        // Archive notes that are not deleted and not already archived
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
        // Move all notes to trash. Unarchive if they were archived.
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
    var now = new Date(); // Current date and time
    var thresholdDate = new Date(now);
    thresholdDate.setDate(now.getDate() - 30); // 30 days ago

    db.transaction(function(tx) {
        // Select notes in trash that are older than 30 days based on updated_at (deletion date)
        var result = tx.executeSql(
            'SELECT id, updated_at FROM Notes WHERE deleted = 1'
        );

        for (var i = 0; i < result.rows.length; i++) {
            var note = result.rows.item(i);
            var noteDeletionDate = new Date(note.updated_at); // Parse the deletion timestamp

            if (noteDeletionDate < thresholdDate) {
                // If the note's deletion date is older than the threshold, delete it permanently
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


//function permanentlyDeleteNotes(ids) {
//    if (!db) {
//        console.error("DB_MGR: Database not initialized. Cannot permanently delete notes.");
//        return;
//    }
//    if (ids.length === 0) {
//        console.warn("DB_MGR: No IDs provided for permanent deletion. Skipping.");
//        return;
//    }

//    db.transaction(function(tx) {
//        var placeholders = ids.map(function() { return '?'; }).join(',');

//        tx.executeSql(
//            "DELETE FROM NoteTags WHERE note_id IN (" + placeholders + ")",
//            ids,
//            function(tx, results) { // <-- results parameter is CRITICAL here
//                console.log("DB_MGR: NoteTags DELETE successful. Rows affected: " + results.rowsAffected);
//                if (results.rowsAffected === 0 && ids.length > 0) {
//                    console.warn("DB_MGR: WARNING: NoteTags DELETE affected 0 rows for IDs:", ids);
//                }

//                tx.executeSql(
//                    "DELETE FROM Notes WHERE id IN (" + placeholders + ")",
//                    ids,
//                    function(tx, results) { // <-- results parameter is CRITICAL here
//                        console.log("DB_MGR: Notes DELETE successful. Rows affected: " + results.rowsAffected);
//                        if (results.rowsAffected === 0 && ids.length > 0) {
//                            console.warn("DB_MGR: WARNING: Notes DELETE affected 0 rows for IDs:", ids + ". Notes may still exist!");
//                        }
//                        console.log("DB_MGR: Successfully permanently deleted Notes with IDs:", ids);

//                        // You can keep checkIfNotesExist(ids); here if you want to verify after all other logs.
//                        // checkIfNotesExist(ids);

//                    },
//                    function(tx, error) { // <-- ERROR CALLBACK for Notes DELETE
//                        console.error("DB_MGR: ERROR: Failed to permanently delete Notes (IDs: " + ids + "): " + error.message);
//                        // checkIfNotesExist(ids);
//                    }
//                );
//            },
//            function(tx, error) { // <-- ERROR CALLBACK for NoteTags DELETE
//                console.error("DB_MGR: ERROR: Failed to delete NoteTags (IDs: " + ids + "): " + error.message);
//                // checkIfNotesExist(ids);
//            }
//        );
//    }, function(error) { // <-- ERROR CALLBACK for entire transaction
//        console.error("DB_MGR: ERROR: Transaction failed during permanent deletion: " + error.message);
//        // checkIfNotesExist(ids);
//    }, function() {
//        console.log("DB_MGR: Permanent deletion transaction block initiated. Check individual SQL logs for success/failure.");
//    });
//}






// Функция checkIfNotesExist остается такой же, как в предыдущем ответе.

// Новая функция для проверки наличия заметок
function checkIfNotesExist(idsToCheck) {
    if (!db) {
        console.error("DB_MGR: Database not initialized. Cannot check for note existence.");
        return;
    }
    if (idsToCheck.length === 0) {
        console.log("DB_MGR: No IDs to check for existence.");
        return;
    }

    db.readTransaction(function(tx) {
        var placeholders = idsToCheck.map(function() { return '?'; }).join(',');
        var query = "SELECT id, title, deleted FROM Notes WHERE id IN (" + placeholders + ")";
        tx.executeSql(query, idsToCheck,
            function(tx, results) {
                if (results.rows.length > 0) {
                    console.warn("DB_MGR_CHECK: !!! ATTENTION: Found " + results.rows.length + " notes that should have been deleted:");
                    for (var i = 0; i < results.rows.length; i++) {
                        var note = results.rows.item(i);
                        console.warn("DB_MGR_CHECK: Note ID: " + note.id + ", Title: '" + note.title + "', Deleted Flag: " + note.deleted);
                    }
                } else {
                    console.log("DB_MGR_CHECK: Successfully verified that notes with IDs [" + idsToCheck.join(',') + "] do NOT exist in DB.");
                }
            },
            function(tx, error) {
                console.error("DB_MGR_CHECK: Error checking for deleted notes: " + error.message);
            }
        );
    });
}

















// DatabaseManager.js

function searchNotes(searchText, selectedTagNames, sortBy, sortOrder) {
    if (!db) initDatabase(LocalStorage);
    var notes = [];
    db.readTransaction(function(tx) {
        var query = 'SELECT N.* FROM Notes N ';
        var params = [];
        var whereConditions = ['N.deleted = 0', 'N.archived = 0'];

        if (selectedTagNames && selectedTagNames.length > 0) {
            query += 'JOIN NoteTags NT ON N.id = NT.note_id JOIN Tags T ON NT.tag_id = T.id ';
            var tagPlaceholders = selectedTagNames.map(function() { return '?'; }).join(',');
            whereConditions.push('T.name IN (' + tagPlaceholders + ')');
            params = params.concat(selectedTagNames);
            query += 'WHERE ' + whereConditions.join(' AND ') + ' ';
            query += 'GROUP BY N.id HAVING COUNT(DISTINCT T.id) = ' + selectedTagNames.length + ' ';
            if (searchText) {
                var searchTerm = '%' + searchText + '%';
                query += 'AND (N.title LIKE ? OR N.content LIKE ?)';
                params.push(searchTerm, searchTerm);
            }
        } else {
            if (searchText) {
                var searchTerm = '%' + searchText + '%';
                whereConditions.push('(N.title LIKE ? OR N.content LIKE ?)');
                params.push(searchTerm, searchTerm);
            }
            if (whereConditions.length > 0) {
                query += 'WHERE ' + whereConditions.join(' AND ') + ' ';
            }
        }

        // --- НОВАЯ ЛОГИКА СОРТИРОВКИ ---
        var orderByClause = "";
        var sortMap = {
            "updated_at": "N.updated_at",
            "created_at": "N.created_at",
            "title_alpha": "N.title",
            "title_length": "LENGTH(N.title)",
            "content_length": "LENGTH(N.content)",
            "color": "N.color"
        };

        var sortDirection = (sortOrder && sortOrder.toLowerCase() === 'asc') ? "ASC" : "DESC";

        if (sortBy && sortMap[sortBy]) {
            orderByClause = "ORDER BY " + sortMap[sortBy] + " " + sortDirection;
        } else {
            // Сортировка по умолчанию
            orderByClause = "ORDER BY N.updated_at DESC";
        }
        query += orderByClause;
        // --- КОНЕЦ НОВОЙ ЛОГИКИ ---

        console.log("DB_MGR: Executing search query:", query);
        console.log("DB_MGR: With parameters:", JSON.stringify(params));

        var result = tx.executeSql(query, params);
        console.log("DB_MGR: searchNotes found " + result.rows.length + " notes.");

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

function moveNoteFromArchiveToTrash(noteId) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE Notes SET archived = 0, deleted = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [noteId]
        );
        console.log("DB_MGR: Note moved from archive to trash. ID:", noteId);
    });
}

function moveNoteFromTrashToArchive(noteId) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
            tx.executeSql(
            'UPDATE Notes SET deleted = 0, archived = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [noteId]
        );
        console.log("DB_MGR: Note moved from trash to archive. ID:", noteId);
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


function generateNoteChecksum(note) {
    if (!note) {
        console.error("DB_MGR: generateNoteChecksum received null/undefined note.");
        return null;
    }

    var data = (note.title || "") +
               (note.content || "") +
               (note.color || "") +
               "|pinned:" + (note.pinned ? "1" : "0") +
               "|archived:" + (note.archived ? "1" : "0") +
               "|deleted:" + (note.deleted ? "1" : "0");

    var checksum = simpleStringHash(data);

    return checksum;
}


















function getNotesForExport(successCallback, errorCallback, newTagToAdd) {
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
            // Select all notes that are not marked as deleted
            var res = tx.executeSql('SELECT id, pinned, title, content, color, created_at, updated_at, deleted, archived, checksum FROM Notes WHERE deleted = 0 ORDER BY updated_at DESC');
            console.log("DB_MGR_DEBUG: Запрос заметок выполнен. Найдено строк: " + res.rows.length);

            for (var i = 0; i < res.rows.length; i++) {
                var note = res.rows.item(i);
                note.tags = []; // Initialize an empty array for tags for each note
                notes.push(note);
            }

            // If there are no notes, return an empty array immediately
            if (notes.length === 0) {
                console.log("DB_MGR_DEBUG: Нет заметок для экспорта. Вызываем successCallback с пустым массивом.");
                if (successCallback) {
                    successCallback([]);
                }
                return;
            }

            // Now get tags for each note synchronously within the transaction
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
                    // Continue, but the note might be without tags
                }
            }
            console.log("DB_MGR_DEBUG: Все теги обработаны.");

            // Apply the optional new tag *after* all existing tags are fetched
            // Ensure newTagToAdd is a non-empty string before attempting to add
            if (newTagToAdd && typeof newTagToAdd === 'string' && newTagToAdd.length > 0) {
                console.log("DB_MGR_DEBUG: Adding optional tag: '" + newTagToAdd + "' to exported notes.");
                notes.forEach(function(note) {
                    // Check if the tag already exists in the note's tags to avoid duplicates
                    if (note.tags.indexOf(newTagToAdd) === -1) {
                        note.tags.push(newTagToAdd);
                    }
                });
            }

            console.log("DB_MGR_DEBUG: Вызываем successCallback с " + notes.length + " заметками.");
            if (successCallback) {
                successCallback(notes);
            }
        } catch (mainSqlError) {
            // Error at the level of executing the main SQL query
            console.error("DB_MGR_DEBUG: Ошибка выполнения основного SQL-запроса для заметок: " + mainSqlError.message);
            if (errorCallback) {
                errorCallback(mainSqlError);
            }
        }
    }, function(error) {
        // Transaction error handling
        console.error("DB_MGR_DEBUG: Ошибка транзакции при получении заметок для экспорта: " + error.message);
        if (errorCallback) {
            errorCallback(error);
        }
    });
}

function addImportedNote(note, tx, optionalTagForImport) {
    console.log("DB_MGR_DEBUG: Processing note for import: ID " + (note.id || 'new'));
    var noteColor = note.color || defaultNoteColor;
    var importedNoteChecksum = generateNoteChecksum(note);
    if (!importedNoteChecksum) {
        console.error("DB_MGR_DEBUG: Failed to generate checksum for imported note (title: " + note.title + "). Skipping.");
        return null;
    }
    var noteId = addNoteInternal(
        tx,
        note.pinned,
        note.title,
        note.content,
        noteColor,
        note.deleted || 0,
        note.archived || 0,
        importedNoteChecksum
    );

    if (noteId === null) {
        console.error("DB_MGR_DEBUG: addNoteInternal failed for note with title: " + note.title);
        return null;
    }

    if (note.tags && note.tags.length > 0) {
        for (var j = 0; j < note.tags.length; j++) {
            addTagToNoteInternal(tx, noteId, note.tags[j]);
        }
    }
    if (optionalTagForImport && typeof optionalTagForImport === 'string' && optionalTagForImport.length > 0) {
        console.log("DB_MGR_DEBUG: Adding optional import tag '" + optionalTagForImport + "' to imported note ID " + noteId);
        addTagToNoteInternal(tx, noteId, optionalTagForImport);
    }

    console.log("DB_MGR_DEBUG: Successfully added imported note with new DB ID: " + noteId + " and checksum: " + importedNoteChecksum);
    return noteId;
}






//function importNotes(importedNotes, optionalTagForImport, successCallback, errorCallback) {
//    if (!db) {
//        initDatabase(LocalStorage);
//        if (!db) {
//            var errorMsg = "DB_MGR: Database not initialized for importNotes. Cannot proceed.";
//            console.error(errorMsg);
//            if (errorCallback) errorCallback(new Error(errorMsg));
//            return;
//        }
//    }

//    var importedCount = 0;
//    var updatedCount = 0; // Not currently used for updates, only new imports
//    var skippedCount = 0;

//    db.transaction(function(tx) {
//        var existingActiveNotesMap = {};
//        try {
//            var result = tx.executeSql('SELECT id, checksum FROM Notes'); //deleted = 0 AND archived = 0
//            for (var i = 0; i < result.rows.length; i++) {
//                var existingNote = result.rows.item(i);
//                //if (existingNote.checksum) {
//                 existingActiveNotesMap[existingNote.checksum] = existingNote.id;
//                //}
//            }
//            console.log("DB_MGR_IMPORT: Found ${Object.keys(existingActiveNotesMap).length} active notes for checksum comparison.");

//        } catch (e) {
//            console.error("DB_MGR_IMPORT: Error fetching existing notes for checksum comparison: " + e.message);
//            throw new Error("Failed to prepare for import due to DB error: " + e.message);
//        }

//        for (var z = 0; z < importedNotes.length; z++) {
//            var noteToImport = importedNotes[z];

//            var generatedChecksumForImportedNote = generateNoteChecksum(noteToImport);

//            if (!generatedChecksumForImportedNote) {
//                console.warn("DB_MGR_IMPORT: Skipping note with no generated checksum (title: ${noteToImport.title}).");
//                skippedCount++;
//                continue;
//            }

//            var existingIdByChecksum = existingActiveNotesMap[generatedChecksumForImportedNote];

//            if (existingIdByChecksum) {
//                // *** FIX 1: Use backticks for template literals in console.log ***
//                console.log("DB_MGR_IMPORT: Note with title `${noteToImport.title}` (checksum: `${generatedChecksumForImportedNote}) already exists as active note ID ${existingIdByChecksum}. Skipping import.");
//                skippedCount++;
//            } else {
//                // *** FIX 1: Use backticks for template literals in console.log ***
//                console.log("DB_MGR_IMPORT: Adding new/changed note: `${noteToImport.title}` with checksum `${generatedChecksumForImportedNote}`.");
//                var newNoteDbId = addImportedNote(noteToImport, tx, optionalTagForImport);

//                if (newNoteDbId !== null) {
//                    importedCount++;
//                } else {
//                    console.error("DB_MGR_IMPORT: Failed to add note, possibly due to an internal error in addImportedNote for title: '${noteToImport.title}'.");
//                    skippedCount++;
//                }
//            }
//        }

//        updateNotesImportedCount(importedCount);
//        updateLastImportDate();

//        // *** FIX 1: Use backticks for template literals in console.log ***
//        console.log("DB_MGR_IMPORT: Import complete. Imported: ${importedCount}, Skipped: ${skippedCount}.");

//        if (successCallback) {
//            successCallback({ importedCount: importedCount, updatedCount: updatedCount, skippedCount: skippedCount });
//        }
//    }, function(error) {
//        console.error("DB_MGR_IMPORT: Transaction failed during import: " + error.message);
//        if (errorCallback) {
//            errorCallback(error);
//        }
//    });
//}





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
    var formattedDate = pad(now.getDate()) +
                        pad(now.getMonth() + 1) +
                        (now.getFullYear()% 100) + '_' +
                        pad(now.getHours()) +
                        pad(now.getMinutes());
    var autoGeneratedTag = "import-" + formattedDate;


    db.transaction(function(tx) {
        var existingNotesById = {};
        try {
            var result = tx.executeSql('SELECT id, checksum FROM Notes');
            for (var i = 0; i < result.rows.length; i++) {
                var existingNote = result.rows.item(i);
                existingNotesById[existingNote.id] = existingNote.checksum;
            }
            console.log("DB_MGR_IMPORT: [INIT] Found " + Object.keys(existingNotesById).length + " local notes for comparison.");
        } catch (e) {
            console.error("DB_MGR_IMPORT: [FATAL] Error fetching local notes: " + e.message);
            if (errorCallback) errorCallback(new Error("DB error: " + e.message));
            return;
        }

        for (var z = 0; z < importedNotes.length; z++) {
            var noteToImport = importedNotes[z];

            noteToImport.checksum = generateNoteChecksum(noteToImport);
            if (!noteToImport.checksum) {
                console.warn("DB_MGR_IMPORT: [SKIPPED] Failed to generate checksum. Title: " + noteToImport.title);
                skippedCount++;
                continue;
            }

            var existingChecksum = existingNotesById[noteToImport.id];

            if (existingChecksum !== undefined && existingChecksum === noteToImport.checksum) {
                console.log("DB_MGR_IMPORT: [SKIPPED] Note '" + noteToImport.title + "' (ID: " + noteToImport.id + ") is identical.");
                skippedCount++;
            } else {
                // СЛУЧАЙ 2: НОВАЯ ЗАМЕТКА или КОНФЛИКТ. Будет добавлена.
                var isConflict = (existingChecksum !== undefined);
                var tagToAdd = null;

                if (optionalTagForImport && optionalTagForImport.trim() !== '') {
                    tagToAdd = optionalTagForImport.trim();
                    if(isConflict) {
                         console.log("DB_MGR_IMPORT: [DUPLICATING ON CONFLICT] Note '" + noteToImport.title + "'. Applying user tag: '" + tagToAdd + "'");
                    } else {
                         console.log("DB_MGR_IMPORT: [ADDING] New note '" + noteToImport.title + "'. Applying user tag: '" + tagToAdd + "'");
                    }
                } else if (isConflict) {
                    tagToAdd = autoGeneratedTag;
                    console.log("DB_MGR_IMPORT: [DUPLICATING ON CONFLICT] Note '" + noteToImport.title + "'. Applying auto-generated tag: '" + tagToAdd + "'");
                } else {
                     console.log("DB_MGR_IMPORT: [ADDING] New note '" + noteToImport.title + "'. No extra tag needed.");
                }

                if (tagToAdd) {
                    if (!noteToImport.tags) noteToImport.tags = [];
                    if (noteToImport.tags.indexOf(tagToAdd) === -1) {
                        noteToImport.tags.push(tagToAdd);
                    }
                }

                var newNoteDbId = addImportedNote(noteToImport, tx);
                if (newNoteDbId !== null) {
                    importedCount++;
                } else {
                    skippedCount++;
                }
            }
        }

        updateNotesImportedCount(importedCount);
        updateLastImportDate();
        console.log("DB_MGR_IMPORT: [COMPLETE] Added: " + importedCount + ", Updated: 0, Skipped: " + skippedCount + ".");
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



function updateLastExportDate() {
    initDatabase(LocalStorage)
    if (!db) {
        console.error("DB_MGR: База данных не инициализирована для обновления статистики экспорта.");
        return;
    }
    db.transaction(function(tx) {
        var now = new Date().toISOString();
        tx.executeSql(
            'INSERT OR REPLACE INTO AppSettings (key, value) VALUES (?, ?)',
            ['lastExportDate', now]
        );
        console.log("DB_MGR: Дата последнего экспорта обновлена: " + now);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении даты последнего экспорта: " + error.message);
    });
}

function updateLastExportDate() {
    if (!db) {
        console.error("DB_MGR: Database not initialized for updateLastExportDate.");
        return;
    }
    db.transaction(function(tx) {
        var now = new Date().toISOString();
        tx.executeSql(
            'UPDATE AppSettings SET lastExportDate = ? WHERE id = 1',
            [now]
        );
        console.log("DB_MGR: Дата последнего экспорта обновлена: " + now);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении даты последнего экспорта: " + error.message);
    });
}

function updateNotesExportedCount(count) {
    if (!db) {
        console.error("DB_MGR: Database not initialized for updateNotesExportedCount.");
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE AppSettings SET notesExportedCount = ? WHERE id = 1',
            [count]
        );
        console.log("DB_MGR: Количество экспортированных заметок обновлено: " + count);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении количества экспортированных заметок: " + error.message);
    });
}

function updateLastImportDate() {
    if (!db) {
        console.error("DB_MGR: Database not initialized for updateLastImportDate.");
        return;
    }
    db.transaction(function(tx) {
        var now = new Date().toISOString();
        tx.executeSql(
            'UPDATE AppSettings SET lastImportDate = ? WHERE id = 1',
            [now]
        );
        console.log("DB_MGR: Дата последнего импорта обновлена: " + now);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении даты последнего импорта: " + error.message);
    });
}

function updateNotesImportedCount(count) {
    if (!db) {
        console.error("DB_MGR: Database not initialized for updateNotesImportedCount.");
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE AppSettings SET notesImportedCount = ? WHERE id = 1',
            [count]
        );
        console.log("DB_MGR: Количество импортированных заметок обновлено: " + count);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении количества импортированных заметок: " + error.message);
    });
}

function getSetting(columnName) {
    if (!db) {
        console.error("DB_MGR: Database not initialized when trying to get setting:", columnName);
        return null;
    }
    var value = null;
    db.readTransaction(function(tx) {
        var result = tx.executeSql('SELECT ' + columnName + ' FROM AppSettings WHERE id = 1');
        if (result.rows.length > 0) {
            value = result.rows.item(0)[columnName];
        }
    });
    return value;
}

function setSetting(columnName, value) { 
    if (!db) {
        console.error("DB_MGR: Database not initialized when trying to set setting:", columnName);
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql(
            'UPDATE AppSettings SET ' + columnName + ' = ? WHERE id = 1',
            [value]
        );
        console.log("DB_MGR: Setting '" + columnName + "' updated to '" + value + "'.");
    });
}

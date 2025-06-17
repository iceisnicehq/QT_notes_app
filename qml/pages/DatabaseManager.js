// DatabaseManager.js (UPDATED - LocalStorage passed to initDatabase, with archiveAllNotes, moveAllNotesToTrash, and permanentlyDeleteExpiredDeletedNotes)

var db = null;
var dbName = "AuroraNotesDB";
var dbVersion = "1.0";
var dbDescription = "Aurora Notes Database";
var dbSize = 1000000;

var defaultNoteColor = "#1c1d29";

// Modified: initDatabase now accepts the LocalStorage object
function initDatabase(localStorageInstance) {
    // Only proceed if a localStorageInstance is provided and db is null
    if (!localStorageInstance) {
        console.error("DB_MGR: LocalStorage instance not provided to initDatabase.");
        return;
    }
    if (db) return; // Prevent re-initialization if already done
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
                'archived BOOLEAN NOT NULL DEFAULT 0' +
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

            // --- Migrations for Notes table (if columns are missing in existing DB) ---
            try {
                tx.executeSql('SELECT color FROM Notes LIMIT 1');
            } catch (e) {
                console.log("DB_MGR: Adding 'color' column to Notes table.");
                tx.executeSql('ALTER TABLE Notes ADD COLUMN color TEXT DEFAULT "' + defaultNoteColor + '"');
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

            // --- NEW: AppSettings Table and its Migrations ---
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

        });
        console.log("DB_MGR: Database initialized successfully.");
    } catch (e) {
        console.error("DB_MGR: Failed to open or initialize database: " + e);
    }
}

// Generic function to get a setting
function getSetting(key) {
    // initDatabase() is called internally by specific functions that need DB access.
    // Ensure db is not null before proceeding.
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
    // initDatabase() is called internally by specific functions that need DB access.
    // Ensure db is not null before proceeding.
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
    // Note: initDatabase is now called via main QML logic before these are used,
    // but adding a safety check here.
    if (!db) initDatabase(LocalStorage); // Attempt to initialize if not already, though primary init is in QML
    return getSetting('themeColor');
}
function getLighterColor(hex) {
    if (!hex || typeof hex !== 'string' || hex.length !== 7 || hex[0] !== '#') {
        console.warn("Invalid color format passed to getBorderColor:", hex);
        return "#606060"; // Default border color for invalid input
    }

    // Remove '#'
    hex = hex.substring(1);

    // Parse R, G, B values
    var r = parseInt(hex.substring(0, 2), 16);
    var g = parseInt(hex.substring(2, 4), 16);
    var b = parseInt(hex.substring(4, 6), 16);

    // Calculate luminance (perceived brightness) to determine if background is dark or light
    // Formula: L = 0.299*R + 0.587*G + 0.114*B (standard for sRGB)
    var luminance = (0.299 * r + 0.587 * g + 0.114 * b);

    var newR, newG, newB;
    var lightenAmount = 70; // Amount to increase RGB components to lighten a color
    var darkenAmount = 50; // Amount to decrease RGB components to darken a color

    if (luminance < 128) {
        // Background is dark, make the border a lighter version of it
        newR = Math.min(255, r + lightenAmount);
        newG = Math.min(255, g + lightenAmount);
        newB = Math.min(255, b + lightenAmount);
    } else {
        // Background is light. Making it "lighter" won't give contrast.
        // Instead, provide a darker, contrasting border.
        newR = Math.max(0, r - darkenAmount);
        newG = Math.max(0, g - darkenAmount);
        newB = Math.max(0, b - darkenAmount);
    }

    // Convert back to hex string and ensure two digits for each component
    var resultHex = "#" +
                    ("00" + newR.toString(16)).slice(-2).toUpperCase() +
                    ("00" + newG.toString(16)).slice(-2).toUpperCase() +
                    ("00" + newB.toString(16)).slice(-2).toUpperCase();

    return resultHex;
}

function darkenColor(hex, percentage) {
    // --- ПРЕДУПРЕЖДЕНИЯ (W) unknown:258, W] unknown:419 могут быть здесь, если hex undefined ---
    // Убедитесь, что hex инициализирован до вызова darkenColor
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

// Placeholder functions for import/export statistics
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


// CORRECTED LINE: Changed default parameter syntax and added 'archived' parameter
function addNoteInternal(tx, pinned, title, content, color, deleted, archived) {
    // Manually set default if 'deleted' is undefined or null
    if (deleted === undefined || deleted === null) {
        deleted = 0;
    }
    // ADDED: Manually set default if 'archived' is undefined or null
    if (archived === undefined || archived === null) {
        archived = 0;
    }
    tx.executeSql(
        'INSERT INTO Notes (pinned, title, content, color, deleted, archived) VALUES (?, ?, ?, ?, ?, ?)', // MODIFIED SQL
        [pinned, title, content, color, deleted, archived] // MODIFIED PARAMETERS
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
        // MODIFIED: Only get notes that are not deleted AND not archived
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

// ADDED: Function to get archived notes
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
    // This function is often called from within another transaction, so it might not need its own initDatabase.
    // However, if called standalone, it needs db to be ready.
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
            'WHERE (N.id IS NULL OR (N.deleted = 0 AND N.archived = 0)) ' + // MODIFIED: Only show tags for non-deleted AND non-archived notes
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
            'WHERE (n.id IS NULL OR (n.deleted = 0 AND n.archived = 0)) ' + // MODIFIED: Only show tags for non-deleted AND non-archived notes
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
    db.transaction(function(tx) {
        // When adding a new note, it's not deleted and not archived, so pass 0 for both
        returnedNoteId = addNoteInternal(tx, pinned, title, content, color, 0, 0); // MODIFIED
        for (var i = 0; i < tags.length; i++) {
            addTagToNoteInternal(tx, returnedNoteId, tags[i]);
        }
    });
    console.log("DB_MGR: New note added with ID:", returnedNoteId);
    return returnedNoteId;
}

function updateNote(id, pinned, title, content, tags, color) {
    if (!db) initDatabase(LocalStorage);
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
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        // MODIFIED: When deleting, also unarchive if it was archived
        tx.executeSql('UPDATE Notes SET deleted = 1, archived = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [id]);
        console.log("DB_MGR: Note ID " + id + " moved to trash.");
    });
}

function restoreNote(id) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        // MODIFIED: When restoring, ensure it's not deleted and not archived
        tx.executeSql('UPDATE Notes SET deleted = 0, archived = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [id]);
        console.log("DB_MGR: Note ID " + id + " restored from trash.");
    });
}

// ADDED: Function to archive a note
function archiveNote(id) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        // When archiving, also ensure it's not deleted
        tx.executeSql('UPDATE Notes SET archived = 1, deleted = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [id]);
        console.log("DB_MGR: Note ID " + id + " moved to archive.");
    });
}

// ADDED: Function to unarchive a note
function unarchiveNote(id) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        tx.executeSql('UPDATE Notes SET archived = 0, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [id]);
        console.log("DB_MGR: Note ID " + id + " unarchived.");
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

// NEW FUNCTION: Permanently delete all notes and associated tags
function permanentlyDeleteAllNotes() {
    if (!db) {
        console.error("DB_MGR: Database not initialized. Cannot delete all notes.");
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM NoteTags'); // Delete all note-tag associations
        tx.executeSql('DELETE FROM Notes');    // Delete all notes
        tx.executeSql('DELETE FROM Tags');     // Optionally delete all tags if they have no notes (clean slate)
        console.log("DB_MGR: All notes and associated tags permanently deleted.");
    });
}

// NEW FUNCTION: Archive all notes that are not already archived or deleted
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

// NEW FUNCTION: Move all notes to trash that are not already deleted
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

// NEW FUNCTION: Permanently delete notes from trash that are older than 30 days
function permanentlyDeleteExpiredDeletedNotes() {
    if (!db) {
        console.error("DB_MGR: Database not initialized. Cannot clean up expired deleted notes.");
        return 0; // Return 0 if DB is not ready
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

function insertTestData() {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
//        // Clear all notes, including deleted ones, for a clean test setup

        tx.executeSql('DELETE FROM Notes');
        tx.executeSql('DELETE FROM NoteTags');
        tx.executeSql('DELETE FROM Tags');

        if (typeof Data !== 'undefined' && Data.notes) {
            console.log("DB_MGR: Inserting test data...");
            for (var i = 0; i < Data.notes.length; i++) {
                var note = Data.notes[i];
                var noteColor = note.color || defaultNoteColor;
                // Add notes as non-deleted and non-archived (explicitly pass 0 for both)
                var noteId = addNoteInternal(tx, note.pinned, note.title, note.content, noteColor, 0, 0); // MODIFIED
                for (var j = 0; j < note.tags.length; j++) {
                    addTagToNoteInternal(tx, noteId, note.tags[j]);
                }
            }
            // Add a test note that is already deleted (explicitly pass deleted = 1, archived = 0)
            // Use a specific date for testing expiration
            var twoMonthsAgo = new Date();
            twoMonthsAgo.setDate(twoMonthsAgo.getDate() - 60); // 60 days ago
            var deletedNoteId = addNoteInternal(tx, false, "Expired Deleted Test Note", "This note should appear in the trash and then be auto-deleted.", defaultNoteColor, 1, 0); // MODIFIED
            tx.executeSql('UPDATE Notes SET updated_at = ? WHERE id = ?', [twoMonthsAgo.toISOString(), deletedNoteId]); // Manually set updated_at for testing
            addTagToNoteInternal(tx, deletedNoteId, "TrashTest");
            console.log("DB_MGR: Added an expired pre-deleted test note with ID:", deletedNoteId);

            // Add a test note that is deleted but NOT expired (e.g., deleted 5 days ago)
            var fiveDaysAgo = new Date();
            fiveDaysAgo.setDate(fiveDaysAgo.getDate() - 5);
            var nonExpiredDeletedNoteId = addNoteInternal(tx, false, "Non-Expired Deleted Test Note", "This note should appear in the trash and NOT be auto-deleted yet.", defaultNoteColor, 1, 0);
            tx.executeSql('UPDATE Notes SET updated_at = ? WHERE id = ?', [fiveDaysAgo.toISOString(), nonExpiredDeletedNoteId]);
            addTagToNoteInternal(tx, nonExpiredDeletedNoteId, "RecentTrashTest");
            console.log("DB_MGR: Added a non-expired pre-deleted test note with ID:", nonExpiredDeletedNoteId);


            // ADDED: Add a test note that is already archived (explicitly pass deleted = 0, archived = 1)
            var archivedNoteId = addNoteInternal(tx, false, "Archived Test Note", "This note should appear in the archive.", defaultNoteColor, 0, 1); // ADDED
            addTagToNoteInternal(tx, archivedNoteId, "ArchiveTest");
            console.log("DB_MGR: Added a pre-archived test note with ID:", archivedNoteId);

        } else {
            console.warn("DB_MGR: Data.notes not found for insertTestData. Skipping test data insertion.");
        }
    });
    console.log("DB_MGR: Test data insertion complete.");
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
        // MODIFIED: When restoring, set both deleted and archived to 0
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

// --- NEW FUNCTION: searchNotes ---
function searchNotes(searchText, selectedTagNames) {
    if (!db) initDatabase(LocalStorage);
    var notes = [];
    db.readTransaction(function(tx) {
        var query = 'SELECT N.* FROM Notes N ';
        var params = [];
        // MODIFIED: Always filter out deleted AND archived notes for the main view
        var whereConditions = ['N.deleted = 0', 'N.archived = 0'];
        var havingConditions = []; // Conditions for HAVING clause

        if (selectedTagNames && selectedTagNames.length > 0) {
            query += 'JOIN NoteTags NT ON N.id = NT.note_id JOIN Tags T ON NT.tag_id = T.id ';
            var tagPlaceholders = selectedTagNames.map(function() { return '?'; }).join(',');
            whereConditions.push('T.name IN (' + tagPlaceholders + ')');
            params = params.concat(selectedTagNames);
        }

        if (searchText) {
            var searchTerm = '%' + searchText + '%';
            whereConditions.push('(N.title LIKE ? OR N.content LIKE ?)');
            params.push(searchTerm, searchTerm);
        }

        // Build WHERE clause
        if (whereConditions.length > 0) {
            query += 'WHERE ' + whereConditions.join(' AND ') + ' ';
        }

        // Add GROUP BY and HAVING clause if tags are selected, AFTER the WHERE clause
        if (selectedTagNames && selectedTagNames.length > 0) {
            query += 'GROUP BY N.id ';
            havingConditions.push('COUNT(DISTINCT T.id) = ' + selectedTagNames.length);
        }

        // Build HAVING clause
        if (havingConditions.length > 0) {
            query += 'HAVING ' + havingConditions.join(' AND ') + ' ';
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


// --- NEW BULK FUNCTIONS ---

// Function to bulk move notes to trash
function bulkMoveToTrash(ids) {
    if (!ids || ids.length === 0) {
        console.warn("DB_MGR: No IDs provided for bulkMoveToTrash.");
        return;
    }
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var placeholders = ids.map(function() { return '?'; }).join(',');
        // Set deleted = 1 and archived = 0 for the given IDs
        tx.executeSql("UPDATE Notes SET deleted = 1, archived = 0, updated_at = CURRENT_TIMESTAMP WHERE id IN (" + placeholders + ")", ids);
        console.log("DB_MGR: Bulk moved notes to trash with IDs:", ids);
    });
}

// Function to bulk archive notes
function bulkArchiveNotes(ids) {
    if (!ids || ids.length === 0) {
        console.warn("DB_MGR: No IDs provided for bulkArchiveNotes.");
        return;
    }
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        var placeholders = ids.map(function() { return '?'; }).join(',');
        // Set archived = 1 and deleted = 0 for the given IDs
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
        // Устанавливаем archived = 0 и deleted = 0 для данных ID
        tx.executeSql("UPDATE Notes SET archived = 0, deleted = 0, updated_at = CURRENT_TIMESTAMP WHERE id IN (" + placeholders + ")", ids);
        console.log("DB_MGR: Bulk unarchived notes with IDs:", ids);
    });
}

// ИСПРАВЛЕНО: Теперь эти функции используют initDatabase() и глобальную переменную db
function moveNoteFromArchiveToTrash(noteId) {
    if (!db) initDatabase(LocalStorage);
    db.transaction(function(tx) {
        // Используем correct column names: 'deleted' и 'archived' вместо 'is_deleted'/'is_archived'
        // и 'updated_at' вместо 'edit_date'
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
        // Используем correct column names: 'deleted' и 'archived' вместо 'is_deleted'/'is_archived'
        // и 'updated_at' вместо 'edit_date'
        tx.executeSql(
            'UPDATE Notes SET deleted = 0, archived = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [noteId]
        );
        console.log("DB_MGR: Note moved from trash to archive. ID:", noteId);
    });
}





/**
 * Функция для получения ВСЕХ заметок (включая архивные и удаленные) для полного бэкапа.
 * ИСПОЛЬЗУЕТ КОЛБЭКИ для обработки асинхронности, а не промисы.
 * @param {function(Array)} onSuccess - Колбэк, вызываемый при успехе с массивом заметок.
 * @param {function(Error)} onError - Колбэк, вызываемый при ошибке.
 */
/**
 * Функция для получения всех заметок и их тегов для экспорта.
 * @param {function} successCallback Колбэк для успешного выполнения (принимает массив заметок).
 * @param {function} errorCallback Колбэк для ошибки (принимает объект ошибки).
 */
function getNotesForExport(successCallback, errorCallback) {
    if (!db) {
        console.error("DB_MGR: База данных не инициализирована для экспорта.");
        if (errorCallback) {
            errorCallback(new Error("База данных не инициализирована."));
        }
        return;
    }

    db.transaction(function(tx) {
        var notes = [];
        // Выбираем все заметки, которые не помечены как удаленные
        var res = tx.executeSql('SELECT id, pinned, title, content, color, created_at, updated_at, deleted, archived FROM Notes WHERE deleted = 0 ORDER BY updated_at DESC');

        for (var i = 0; i < res.rows.length; i++) {
            var note = res.rows.item(i);
            note.tags = []; // Инициализируем пустой массив для тегов каждой заметки
            notes.push(note);
        }

        // Если нет заметок, сразу возвращаем пустой массив
        if (notes.length === 0) {
            if (successCallback) {
                successCallback([]);
            }
            return;
        }

        // Теперь получаем теги для каждой заметки асинхронно или вложенными запросами
        // Этот подход обрабатывает теги для каждой заметки по очереди.
        var tagsProcessedCount = 0;
        for (var j = 0; j < notes.length; j++) {
            // Используем Immediately Invoked Function Expression (IIFE) для создания замыкания,
            // чтобы currentNote сохранялась для каждого асинхронного вызова SQL.
            (function(currentNote) {
                var tagRes = tx.executeSql(
                    'SELECT T.name FROM Tags T JOIN NoteTags NT ON T.id = NT.tag_id WHERE NT.note_id = ?',
                    [currentNote.id]
                );
                for (var k = 0; k < tagRes.rows.length; k++) {
                    currentNote.tags.push(tagRes.rows.item(k).name);
                }
                tagsProcessedCount++;

                // Когда теги для всех заметок обработаны, вызываем successCallback
                if (tagsProcessedCount === notes.length) {
                    if (successCallback) {
                        successCallback(notes);
                    }
                }
            })(notes[j]);
        }
    }, function(error) {
        // Обработка ошибок транзакции
        console.error("DB_MGR: Ошибка при получении заметок для экспорта: " + error.message);
        if (errorCallback) {
            errorCallback(error);
        }
    });
}

/**
 * Функция для добавления импортированной заметки.
 * Она более сложная, так как должна воссоздать заметку и ее теги.
 * Она также будет обновлять существующую заметку, если id уже есть в базе.
 * @param {object} note Объект заметки для импорта.
 * @param {SQLTransaction} tx Объект транзакции, если функция вызывается внутри существующей транзакции.
 */
function addImportedNote(note, tx) {
    if (!db && !tx) {
        console.error("DB_MGR: База данных не инициализирована для импорта.");
        return;
    }

    // Fixed: Replaced arrow function with traditional 'function'
    var processNote = function(currentTx) {
        // Проверяем, существует ли уже заметка с таким ID
        var existing = currentTx.executeSql('SELECT id FROM Notes WHERE id = ?', [note.id]);

        if (existing.rows.length > 0) {
            // Если да, то ОБНОВЛЯЕМ её
            console.log("DB_MGR: Обновление существующей заметки при импорте, ID:", note.id);
            currentTx.executeSql(
                'UPDATE Notes SET pinned = ?, title = ?, content = ?, color = ?, created_at = ?, updated_at = ?, deleted = ?, archived = ? WHERE id = ?',
                [note.pinned, note.title, note.content, note.color, note.created_at, note.updated_at, note.deleted, note.archived, note.id]
            );
            // Удаляем старые теги перед добавлением новых
            currentTx.executeSql('DELETE FROM NoteTags WHERE note_id = ?', [note.id]);
        } else {
            // Если нет, то ВСТАВЛЯЕМ новую заметку. Нам нужно временно разрешить вставку ID.
            console.log("DB_MGR: Вставка новой заметки при импорте, ID:", note.id);
            currentTx.executeSql(
                'INSERT INTO Notes (id, pinned, title, content, color, created_at, updated_at, deleted, archived) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [note.id, note.pinned, note.title, note.content, note.color, note.created_at, note.updated_at, note.deleted, note.archived]
            );
        }

        // Добавляем теги для этой заметки (и для новой, и для обновленной)
        if (note.tags && note.tags.length > 0) {
            for (var i = 0; i < note.tags.length; i++) {
                addTagToNoteInternal(currentTx, note.id, note.tags[i]);
            }
        }
    };

    if (tx) {
        // Если транзакция передана, используем её
        processNote(tx);
    } else {
        // Иначе, выполняем в отдельной транзакции
        db.transaction(function(newTx) {
            processNote(newTx);
        }, function(error) {
            console.error("DB_MGR: Ошибка при импорте заметки (отдельная транзакция): " + error.message);
        });
    }
}






// --- НОВЫЕ ФУНКЦИИ ДЛЯ СТАТИСТИКИ ---

/**
 * Обновляет дату последнего экспорта в базе данных.
 */
function updateLastExportDate() {
    if (!db) {
        console.error("DB_MGR: База данных не инициализирована для обновления статистики экспорта.");
        return;
    }
    db.transaction(function(tx) {
        // Changed: Replaced 'const' with 'var'
        var now = new Date().toISOString();
        // Предполагается, что у вас есть таблица для настроек или статистики.
        // Если нет, нужно будет создать: CREATE TABLE IF NOT EXISTS AppSettings (key TEXT PRIMARY KEY, value TEXT);
        tx.executeSql(
            'INSERT OR REPLACE INTO AppSettings (key, value) VALUES (?, ?)',
            ['lastExportDate', now]
        );
        console.log("DB_MGR: Дата последнего экспорта обновлена: " + now);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении даты последнего экспорта: " + error.message);
    });
}

/**
 * Обновляет количество экспортированных заметок в базе данных.
 * @param {number} count Количество заметок, экспортированных за последнюю операцию.
 */
function updateNotesExportedCount(count) {
    if (!db) {
        console.error("DB_MGR: База данных не инициализирована для обновления статистики экспорта.");
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql(
            'INSERT OR REPLACE INTO AppSettings (key, value) VALUES (?, ?)',
            ['lastExportedNotesCount', count]
        );
        console.log("DB_MGR: Количество экспортированных заметок обновлено: " + count);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении количества экспортированных заметок: " + error.message);
    });
}

/**
 * Обновляет дату последнего импорта в базе данных.
 */
function updateLastImportDate() {
    if (!db) {
        console.error("DB_MGR: База данных не инициализирована для обновления статистики импорта.");
        return;
    }
    db.transaction(function(tx) {
        // Changed: Replaced 'const' with 'var'
        var now = new Date().toISOString();
        tx.executeSql(
            'INSERT OR REPLACE INTO AppSettings (key, value) VALUES (?, ?)',
            ['lastImportDate', now]
        );
        console.log("DB_MGR: Дата последнего импорта обновлена: " + now);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении даты последнего импорта: " + error.message);
    });
}

/**
 * Обновляет количество импортированных заметок в базе данных.
 * @param {number} count Количество заметок, импортированных за последнюю операцию.
 */
function updateNotesImportedCount(count) {
    if (!db) {
        console.error("DB_MGR: База данных не инициализирована для обновления статистики импорта.");
        return;
    }
    db.transaction(function(tx) {
        tx.executeSql(
            'INSERT OR REPLACE INTO AppSettings (key, value) VALUES (?, ?)',
            ['lastImportedNotesCount', count]
        );
        console.log("DB_MGR: Количество импортированных заметок обновлено: " + count);
    }, function(error) {
        console.error("DB_MGR: Ошибка при обновлении количества импортированных заметок: " + error.message);
    });
}

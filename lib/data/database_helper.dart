import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'credential_model.dart';

/// A helper class to manage SQLite database operations for storing credentials, credit cards, and notes.
class DatabaseHelper {
  final String databaseName;
  Database? _database;

  /// Creates a [DatabaseHelper] instance with the specified [databaseName].
  DatabaseHelper(this.databaseName);

  /// Provides access to the SQLite database instance, creating it if it doesn't exist.
  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '$databaseName.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
    return _database!;
  }

  /// Creates the database schema with tables for credentials, credit cards, and notes.
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE credentials (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      website TEXT,
      email TEXT,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      totpSecret TEXT,
      is_archived INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0,
      deleted_at TEXT,
      archived_at TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE credit_cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      bank_name TEXT,
      ch_name TEXT NOT NULL,
      card_number TEXT NOT NULL,
      expiry_date TEXT NOT NULL,
      cvv TEXT NOT NULL,
      card_type TEXT,
      billing_address TEXT,
      notes TEXT,
      is_archived INTEGER DEFAULT 0,
      archived_at TEXT,
      is_deleted INTEGER DEFAULT 0,
      deleted_at TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      is_archived INTEGER DEFAULT 0,
      archived_at TEXT,
      is_deleted INTEGER DEFAULT 0,
      deleted_at TEXT
    )
    ''');
  }

  /// Deletes the database file associated with this [databaseName].
  ///
  /// This method closes the database connection and deletes the database file from the file system.
  /// After deletion, the database instance is reset to null.
  Future<void> deleteDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '$databaseName.db');
    await database; // Ensure the database is opened
    await _database?.close(); // Close the database
    _database = null; // Reset the database instance
    await sqflite.deleteDatabase(path); // Use sqflite's deleteDatabase function
  }

  /// Inserts a [credential] into the credentials table.
  ///
  /// Returns the ID of the inserted credential.
  Future<int> insertCredential(Credential credential) async {
    final db = await database;
    return db.insert(
      'credentials',
      credential.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts a [card] into the credit_cards table.
  ///
  /// Returns the ID of the inserted credit card.
  Future<int> insertCreditCard(CreditCard card) async {
    final db = await database;
    return db.insert(
      'credit_cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts a [note] into the notes table.
  ///
  /// Returns the ID of the inserted note.
  Future<int> insertNote(Note note) async {
    final db = await database;
    return db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a list of credentials from the database.
  ///
  /// - If [includeArchived] is true, includes archived credentials.
  /// - If [includeDeleted] is true, includes deleted credentials.
  /// - By default, only non-archived and non-deleted credentials are returned.
  Future<List<Credential>> getCredentials({bool includeArchived = false, bool includeDeleted = false}) async {
    final db = await database;
    final maps = await db.query(
      'credentials',
      where: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? 'is_deleted = 0'
          : includeDeleted
          ? 'is_archived = 0'
          : 'is_archived = 0 AND is_deleted = 0',
    );
    return maps.map((map) => Credential.fromMap(map)).toList();
  }

  /// Retrieves a list of credit cards from the database.
  ///
  /// - If [includeArchived] is true, includes archived credit cards.
  /// - If [includeDeleted] is true, includes deleted credit cards.
  /// - By default, only non-archived and non-deleted credit cards are returned.
  Future<List<Map<String, dynamic>>> queryAllCreditCards({bool includeArchived = false, bool includeDeleted = false}) async {
    final db = await database;
    return await db.query(
      'credit_cards',
      where: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? 'is_deleted = 0'
          : includeDeleted
          ? 'is_archived = 0'
          : 'is_archived = 0 AND is_deleted = 0',
    );
  }

  /// Retrieves a list of notes from the database.
  ///
  /// - If [includeArchived] is true, includes archived notes.
  /// - If [includeDeleted] is true, includes deleted notes.
  /// - By default, only non-archived and non-deleted notes are returned.
  Future<List<Note>> getNotes({bool includeArchived = false, bool includeDeleted = false}) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? 'is_deleted = 0'
          : includeDeleted
          ? 'is_archived = 0'
          : 'is_archived = 0 AND is_deleted = 0',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// Retrieves a credential by its [id].
  ///
  /// Returns null if no credential is found with the given [id].
  Future<Credential?> getCredentialById(int id) async {
    final db = await database;
    final maps = await db.query(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Credential.fromMap(maps.first) : null;
  }

  /// Updates a [credential] in the database.
  ///
  /// Returns the number of rows affected.
  Future<int> updateCredential(Credential credential) async {
    final db = await database;
    return db.update(
      'credentials',
      credential.toMap(),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  /// Updates a [card] in the database.
  ///
  /// Returns the number of rows affected.
  Future<int> updateCreditCard(CreditCard card) async {
    final db = await database;
    return db.update(
      'credit_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  /// Updates a [note] in the database.
  ///
  /// Returns the number of rows affected.
  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Archives a credential by its [id].
  ///
  /// Sets the `is_archived` flag to 1 and records the archival timestamp.
  /// Returns the number of rows affected.
  Future<int> archiveCredential(int id) async {
    final db = await database;
    return db.update(
      'credentials',
      {
        'is_archived': 1,
        'archived_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marks a credential as deleted by its [id].
  ///
  /// Sets the `is_deleted` flag to 1 and records the deletion timestamp.
  /// Returns the number of rows affected.
  Future<int> deleteCredential(int id) async {
    final db = await database;
    return db.update(
      'credentials',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently deletes a credential by its [id] from the database.
  ///
  /// Returns the number of rows affected.
  Future<int> permanentlyDeleteCredential(int id) async {
    final db = await database;
    return db.delete(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Restores a credential by its [id].
  ///
  /// Clears the `is_archived` and `is_deleted` flags and their timestamps.
  /// Returns the number of rows affected.
  Future<int> restoreCredential(int id) async {
    final db = await database;
    return db.update(
      'credentials',
      {
        'is_archived': 0,
        'archived_at': null,
        'is_deleted': 0,
        'deleted_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Archives a credit card by its [id].
  ///
  /// Sets the `is_archived` flag to 1 and records the archival timestamp.
  /// Returns the number of rows affected.
  Future<int> archiveCreditCard(int id) async {
    final db = await database;
    return db.update(
      'credit_cards',
      {
        'is_archived': 1,
        'archived_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marks a credit card as deleted by its [id].
  ///
  /// Sets the `is_deleted` flag to 1 and records the deletion timestamp.
  /// Returns the number of rows affected.
  Future<int> deleteCreditCard(int id) async {
    final db = await database;
    return db.update(
      'credit_cards',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently deletes a credit card by its [id] from the database.
  ///
  /// Returns the number of rows affected.
  Future<int> permanentlyDeleteCreditCard(int id) async {
    final db = await database;
    return db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Restores a credit card by its [id].
  ///
  /// Clears the `is_archived` and `is_deleted` flags and their timestamps.
  /// Returns the number of rows affected.
  Future<int> restoreCreditCard(int id) async {
    final db = await database;
    return db.update(
      'credit_cards',
      {
        'is_archived': 0,
        'archived_at': null,
        'is_deleted': 0,
        'deleted_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Archives a note by its [id].
  ///
  /// Sets the `is_archived` flag to 1 and records the archival timestamp.
  /// Returns the number of rows affected.
  Future<int> archiveNote(int id) async {
    final db = await database;
    return db.update(
      'notes',
      {
        'is_archived': 1,
        'archived_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marks a note as deleted by its [id].
  ///
  /// Sets the `is_deleted` flag to 1 and records the deletion timestamp.
  /// Returns the number of rows affected.
  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.update(
      'notes',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently deletes a note by its [id] from the database.
  ///
  /// Returns the number of rows affected.
  Future<int> permanentlyDeleteNote(int id) async {
    final db = await database;
    return db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Restores a note by its [id].
  ///
  /// Clears the `is_archived` and `is_deleted` flags and their timestamps.
  /// Returns the number of rows affected.
  Future<int> restoreNote(int id) async {
    final db = await database;
    return db.update(
      'notes',
      {
        'is_archived': 0,
        'archived_at': null,
        'is_deleted': 0,
        'deleted_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
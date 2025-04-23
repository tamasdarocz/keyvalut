import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'credential_model.dart'; // Assuming this exists

class DatabaseHelper {
  final String databaseName;
  Database? _database;

  DatabaseHelper(this.databaseName);

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

  Future<int> insertCredential(Credential credential) async {
    final db = await database;
    return db.insert(
      'credentials',
      credential.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertCreditCard(CreditCard card) async {
    final db = await database;
    return db.insert(
      'credit_cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<int> updateCredential(Credential credential) async {
    final db = await database;
    return db.update(
      'credentials',
      credential.toMap(),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  Future<int> updateCreditCard(CreditCard card) async {
    final db = await database;
    return db.update(
      'credit_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

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

  Future<int> permanentlyDeleteCredential(int id) async {
    final db = await database;
    return db.delete(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<int> permanentlyDeleteCreditCard(int id) async {
    final db = await database;
    return db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<int> permanentlyDeleteNote(int id) async {
    final db = await database;
    return db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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
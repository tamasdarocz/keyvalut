import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:keyvalut/data/credential_model.dart';

class DatabaseHelper {
  final String databaseName;
  Database? _database;

  DatabaseHelper(this.databaseName) {
    if (databaseName == 'default') {
      print('DatabaseHelper instantiated with "default" at: ${StackTrace.current}');
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '$databaseName.db');
    return await openDatabase(
      path,
      version: 4, // Incremented version to 4
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<bool> databaseExists() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '$databaseName.db');
    return await File(path).exists();
  }

  Future<void> deleteDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '$databaseName.db');
    await File(path).delete();
    _database = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        website TEXT,
        email TEXT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        totpSecret TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        archived_at TEXT,
        deleted_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
        is_archived INTEGER NOT NULL DEFAULT 0,
        archived_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        archived_at TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        deleted_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
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
          is_archived INTEGER NOT NULL DEFAULT 0,
          archived_at TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          deleted_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          is_archived INTEGER NOT NULL DEFAULT 0,
          archived_at TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          deleted_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // Previous migration (potentially problematic)
      // We'll replace this in the next step
    }

    if (oldVersion < 4) {
      // Migrate the credentials table using a temporary table
      await db.execute('''
        CREATE TABLE credentials_temp (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL DEFAULT 'Untitled',
          website TEXT,
          email TEXT,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          totpSecret TEXT,
          is_archived INTEGER NOT NULL DEFAULT 0,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          archived_at TEXT,
          deleted_at TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Copy data from the old table to the new table
      // Only include columns that exist in the old table, mapping them to the new schema
      await db.execute('''
        INSERT INTO credentials_temp (
          id, username, password, is_archived, is_deleted, created_at, updated_at,
          title, website, email, totpSecret, archived_at, deleted_at
        )
        SELECT 
          id, username, password, is_archived, is_deleted, created_at, updated_at,
          COALESCE(NULL, 'Untitled') AS title, -- title might not exist
          website, -- website might exist, will be NULL if not
          NULL AS email, -- email might not exist
          NULL AS totpSecret, -- totpSecret might not exist
          NULL AS archived_at, -- archived_at might not exist
          NULL AS deleted_at -- deleted_at might not exist
        FROM credentials
      ''');

      // Drop the old table
      await db.execute('DROP TABLE credentials');

      // Rename the temporary table to credentials
      await db.execute('ALTER TABLE credentials_temp RENAME TO credentials');
    }
  }

  Future<void> insertCredential(Credential credential) async {
    final db = await database;
    await db.insert(
      'credentials',
      credential.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Credential>> getCredentials({
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async {
    final db = await database;
    final maps = await db.query(
      'credentials',
      where: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? 'is_deleted = ?'
          : includeDeleted
          ? 'is_archived = ?'
          : 'is_archived = ? AND is_deleted = ?',
      whereArgs: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? [0]
          : includeDeleted
          ? [0]
          : [0, 0],
    );
    return maps.map((map) => Credential.fromMap(map)).toList();
  }

  Future<void> updateCredential(Credential credential) async {
    final db = await database;
    await db.update(
      'credentials',
      credential.toMap(),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  Future<void> archiveCredential(int id) async {
    final db = await database;
    await db.update(
      'credentials',
      {
        'is_archived': 1,
        'archived_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCredential(int id) async {
    final db = await database;
    await db.update(
      'credentials',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreCredential(int id) async {
    final db = await database;
    await db.update(
      'credentials',
      {
        'is_deleted': 0,
        'is_archived': 0,
        'archived_at': null,
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentlyDeleteCredential(int id) async {
    final db = await database;
    await db.delete(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertCreditCard(CreditCard card) async {
    final db = await database;
    await db.insert(
      'credit_cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAllCreditCards({
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async {
    final db = await database;
    return await db.query(
      'credit_cards',
      where: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? 'is_deleted = ?'
          : includeDeleted
          ? 'is_archived = ?'
          : 'is_archived = ? AND is_deleted = ?',
      whereArgs: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? [0]
          : includeDeleted
          ? [0]
          : [0, 0],
    );
  }

  Future<void> updateCreditCard(CreditCard card) async {
    final db = await database;
    await db.update(
      'credit_cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> archiveCreditCard(int id) async {
    final db = await database;
    await db.update(
      'credit_cards',
      {
        'is_archived': 1,
        'archived_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCreditCard(int id) async {
    final db = await database;
    await db.update(
      'credit_cards',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreCreditCard(int id) async {
    final db = await database;
    await db.update(
      'credit_cards',
      {
        'is_deleted': 0,
        'is_archived': 0,
        'archived_at': null,
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentlyDeleteCreditCard(int id) async {
    final db = await database;
    await db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getNotes({
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? 'is_deleted = ?'
          : includeDeleted
          ? 'is_archived = ?'
          : 'is_archived = ? AND is_deleted = ?',
      whereArgs: includeArchived && includeDeleted
          ? null
          : includeArchived
          ? [0]
          : includeDeleted
          ? [0]
          : [0, 0],
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> archiveNote(int id) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'is_archived': 1,
        'archived_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreNote(int id) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'is_deleted': 0,
        'is_archived': 0,
        'archived_at': null,
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentlyDeleteNote(int id) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
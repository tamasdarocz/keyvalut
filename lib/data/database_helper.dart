import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:keyvalut/data/database_model.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class DatabaseHelper {
  final String databaseName;
  Database? _database;

  DatabaseHelper(this.databaseName) {
    if (databaseName == 'default') {
    }
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (databaseName.isEmpty) {
      throw Exception('Database name cannot be empty');
    }
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '$databaseName.db');

    Database db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) {
      },
    );

    // Verify the file exists after opening
    if (await File(path).exists()) {
    } else {
    }

    return db;
  }

  Future<bool> databaseExists() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '$databaseName.db');
    bool exists = await File(path).exists();
    return exists;
  }

  Future<void> deleteDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '$databaseName.db');
    await File(path).delete();
    _database = null;
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE logins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        website TEXT,
        email TEXT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        totpSecret TEXT,
        billing_address TEXT,
        phone_number TEXT,
        billing_date TEXT,
        credit_card_id INTEGER,
        notification_setting TEXT,
        selected_period TEXT,
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
        phone_number TEXT,
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

  Future<void> insertLogins(Logins login) async {
    final db = await database;
    await db.insert(
      'logins',
      login.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Logins>> getLogins({
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async {
    final db = await database;
    final maps = await db.query(
      'logins',
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
    return maps.map((map) => Logins.fromMap(map)).toList();
  }

  Future<void> updateLogins(Logins login) async {
    final db = await database;
    await db.update(
      'logins',
      login.toMap(),
      where: 'id = ?',
      whereArgs: [login.id],
    );
  }

  Future<void> archiveLogins(int id) async {
    final db = await database;
    await db.update(
      'logins',
      {
        'is_archived': 1,
        'archived_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteLogins(int id) async {
    final db = await database;
    await db.update(
      'logins',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreLogins(int id) async {
    final db = await database;
    await db.update(
      'logins',
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

  Future<void> permanentlyDeleteLogins(int id) async {
    final db = await database;
    await db.delete(
      'logins',
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
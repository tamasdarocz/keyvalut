import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'credential_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('Credential.db');
      return _database!;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database: $e');
      }
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {

    await db.execute('''
    CREATE TABLE Credential (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      email TEXT NOT NULL,
      username TEXT NOT NULL,
      website TEXT NOT NULL,
      password TEXT NOT NULL
    )
  ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE NewTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
    }
  }

  // All CRUD methods reference 'Credential' consistently
  Future<int> insertCredential(Credential credential) async {
    try {
      final db = await database;
      return await db.insert(
        'Credential',
        credential.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
        print('Error inserting credential: $e');
      return -1; // Indicate failure
    }
  }

  // Read all credentials
  Future<List<Credential>> getCredentials() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Credential');
    return List.generate(maps.length, (i) => Credential.fromMap(maps[i]));

  }

  // Read single credential by id
  Future<Credential?> getCredentialById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'Credential',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Credential.fromMap(result.first) : null;
  }

  // Update
  Future<int> updateCredential(Credential credential) async {
    final db = await database;
    return await db.update(
      'Credential',
      credential.toMap(),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  // Delete
  Future<int> deleteCredential(int id) async {
    final db = await database;
    return await db.delete(
      'Credential',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

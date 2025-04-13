import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'credential_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('credentials.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, fileName),
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        email TEXT,
        username TEXT NOT NULL,
        website TEXT,
        password TEXT NOT NULL
      )
    ''');
  }

  // INSERT
  Future<int> insertCredential(Credential credential) async {
    final db = await database;
    return db.insert(
      'credentials',
      credential.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ ALL
  Future<List<Credential>> getCredentials() async {
    final db = await database;
    final maps = await db.query('credentials');
    return maps.map((map) => Credential.fromMap(map)).toList();
  }

  // READ SINGLE
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

  // UPDATE
  Future<int> updateCredential(Credential credential) async {
    final db = await database;
    return db.update(
      'credentials',
      credential.toMap(),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  // DELETE
  Future<int> deleteCredential(int id) async {
    final db = await database;
    return db.delete(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
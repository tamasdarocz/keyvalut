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
      version: 2, // Incremented version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns
      await db.execute('ALTER TABLE credentials ADD COLUMN totpSecret TEXT');
      await db.execute('ALTER TABLE credentials ADD COLUMN is_archived INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE credentials ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE credentials ADD COLUMN deleted_at TEXT');
      await db.execute('ALTER TABLE credentials ADD COLUMN archived_at TEXT');
    }
  }

  // For testing/debugging purposes
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'credentials.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
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
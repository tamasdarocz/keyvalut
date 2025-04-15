import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('keyvalut.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE authenticators (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_name TEXT NOT NULL,
            totp_secret TEXT NOT NULL
          )
        ''');
        // Add other tables (e.g., for passwords, API keys) if needed
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAuthenticators() async {
    final db = await database;
    return await db.query('authenticators');
  }

  Future<void> insertAuthenticator(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert('authenticators', entry);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('authenticators');
    // Clear other tables if needed
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
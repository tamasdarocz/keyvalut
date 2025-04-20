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
      version: 5,
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE credentials ADD COLUMN totpSecret TEXT');
      await db.execute('ALTER TABLE credentials ADD COLUMN is_archived INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE credentials ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE credentials ADD COLUMN deleted_at TEXT');
      await db.execute('ALTER TABLE credentials ADD COLUMN archived_at TEXT');
    }

    if (oldVersion < 3) {
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
        notes TEXT
      )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE credit_cards ADD COLUMN is_archived INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE credit_cards ADD COLUMN archived_at TEXT');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE credit_cards ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE credit_cards ADD COLUMN deleted_at TEXT');
    }
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'credentials.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
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
}
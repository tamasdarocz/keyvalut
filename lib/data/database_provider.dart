import 'package:flutter/foundation.dart';
import 'package:keyvalut/data/database_model.dart';
import 'package:keyvalut/data/database_helper.dart';

/// A provider class that manages database operations and notifies listeners of changes.
///
/// This class handles loading, adding, updating, and deleting logins, credit cards,
/// and notes from the database using [DatabaseHelper]. It maintains separate lists
/// for active, archived, and deleted items and notifies listeners when data changes.
class DatabaseProvider with ChangeNotifier {
  List<Logins> _logins = [];
  List<Logins> _archivedLogins = [];
  List<Logins> _deletedLogins = [];
  List<CreditCard> _creditCards = [];
  List<CreditCard> _archivedCreditCards = [];
  List<CreditCard> _deletedCreditCards = [];
  List<Note> _notes = [];
  List<Note> _archivedNotes = [];
  List<Note> _deletedNotes = [];

  List<Logins> get logins => _logins;
  List<Logins> get archivedLogins => _archivedLogins;
  List<Logins> get deletedLogins => _deletedLogins;
  List<CreditCard> get creditCards => _creditCards;
  List<CreditCard> get archivedCreditCards => _archivedCreditCards;
  List<CreditCard> get deletedCreditCards => _deletedCreditCards;
  List<Note> get notes => _notes;
  List<Note> get archivedNotes => _archivedNotes;
  List<Note> get deletedNotes => _deletedNotes;

  late DatabaseHelper _dbHelper;

  /// The [DatabaseHelper] instance used by this provider.
  DatabaseHelper get databaseHelper => _dbHelper;

  /// The name of the current database.
  String get databaseName => _dbHelper.databaseName;

  DatabaseProvider({String? initialDatabaseName}) {
    _dbHelper = DatabaseHelper(initialDatabaseName ?? 'default');
    if (initialDatabaseName != null && initialDatabaseName.isNotEmpty) {
      loadLogins();
      loadCreditCards();
      loadNotes();
    }
  }

  /// Closes the database connection.
  Future<void> closeDatabase() async {
    await _dbHelper.close();
  }

  /// Sets the database name and reloads all data.
  ///
  /// - [databaseName]: The name of the database to use.
  void setDatabaseName(String databaseName) {
    _dbHelper = DatabaseHelper(databaseName);
    if (databaseName.isNotEmpty) {
      loadLogins();
      loadCreditCards();
      loadNotes();
    } else {
      _logins = [];
      _archivedLogins = [];
      _deletedLogins = [];
      _creditCards = [];
      _archivedCreditCards = [];
      _deletedCreditCards = [];
      _notes = [];
      _archivedNotes = [];
      _deletedNotes = [];
    }
    notifyListeners();
  }

  /// Loads all logins from the database and updates the lists.
  Future<void> loadLogins() async {
    final allLogins = await _dbHelper.getLogins(includeArchived: true, includeDeleted: true);
    _logins = allLogins.where((c) => !c.isArchived && !c.isDeleted).toList();
    _archivedLogins = allLogins.where((c) => c.isArchived && !c.isDeleted).toList();
    _deletedLogins = allLogins.where((c) => c.isDeleted).toList();
    notifyListeners();
  }

  /// Loads all credit cards from the database and updates the lists.
  Future<void> loadCreditCards() async {
    final allCreditCardsMaps = await _dbHelper.queryAllCreditCards(includeArchived: true, includeDeleted: true);
    final allCreditCards = allCreditCardsMaps.map((map) => CreditCard.fromMap(map)).toList();
    _creditCards = allCreditCards.where((c) => !c.isArchived && !c.isDeleted).toList();
    _archivedCreditCards = allCreditCards.where((c) => c.isArchived && !c.isDeleted).toList();
    _deletedCreditCards = allCreditCards.where((c) => c.isDeleted).toList();
    notifyListeners();
  }

  /// Loads all notes from the database and updates the lists.
  Future<void> loadNotes() async {
    final allNotes = await _dbHelper.getNotes(includeArchived: true, includeDeleted: true);
    _notes = allNotes.where((n) => !n.isArchived && !n.isDeleted).toList();
    _archivedNotes = allNotes.where((n) => n.isArchived && !n.isDeleted).toList();
    _deletedNotes = allNotes.where((n) => n.isDeleted).toList();
    notifyListeners();
  }

  /// Loads archived logins, credit cards, and notes.
  Future<void> loadArchivedItems() async {
    await loadLogins();
    await loadCreditCards();
    await loadNotes();
  }

  /// Loads deleted logins, credit cards, and notes.
  Future<void> loadDeletedItems() async {
    await loadLogins();
    await loadCreditCards();
    await loadNotes();
  }

  /// Clears all logins from the database.
  Future<void> clearLogins() async {
    final db = await _dbHelper.database;
    await db.delete('logins');
    await loadLogins();
  }

  /// Clears all credit cards from the database.
  Future<void> clearCreditCards() async {
    final db = await _dbHelper.database;
    await db.delete('credit_cards');
    await loadCreditCards();
  }

  /// Clears all notes from the database.
  Future<void> clearNotes() async {
    final db = await _dbHelper.database;
    await db.delete('notes');
    await loadNotes();
  }

  /// Clears all data (logins, credit cards, and notes) from the database.
  Future<void> clearAllData() async {
    await clearLogins();
    await clearCreditCards();
    await clearNotes();
  }

  /// Adds a new login to the database.
  ///
  /// - [login]: The [Logins] object to add.
  Future<void> addLogin(Logins login) async {
    await _dbHelper.insertLogins(login);
    await loadLogins();
  }

  /// Adds a new credit card to the database.
  ///
  /// - [card]: The [CreditCard] object to add.
  Future<void> addCreditCard(CreditCard card) async {
    await _dbHelper.insertCreditCard(card);
    await loadCreditCards();
  }

  /// Adds a new note to the database.
  ///
  /// - [note]: The [Note] object to add.
  Future<void> addNote(Note note) async {
    await _dbHelper.insertNote(note);
    await loadNotes();
  }

  /// Updates an existing login in the database.
  ///
  /// - [login]: The updated [Logins] object.
  Future<void> updateLogin(Logins login) async {
    final updatedLogin = Logins(
      id: login.id,
      title: login.title,
      website: login.website,
      email: login.email,
      username: login.username,
      password: login.password,
      totpSecret: login.totpSecret,
      isArchived: login.isArchived,
      isDeleted: login.isDeleted,
      archivedAt: login.archivedAt,
      deletedAt: login.deletedAt,
      createdAt: login.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _dbHelper.updateLogins(updatedLogin);
    await loadLogins();
  }

  /// Updates an existing credit card in the database.
  ///
  /// - [card]: The updated [CreditCard] object.
  Future<void> updateCreditCard(CreditCard card) async {
    final updatedCard = CreditCard(
      id: card.id,
      title: card.title,
      bank_name: card.bank_name,
      ch_name: card.ch_name,
      card_number: card.card_number,
      expiry_date: card.expiry_date,
      cvv: card.cvv,
      card_type: card.card_type,
      billing_address: card.billing_address,
      notes: card.notes,
      isArchived: card.isArchived,
      archivedAt: card.archivedAt,
      isDeleted: card.isDeleted,
      deletedAt: card.deletedAt,
      createdAt: card.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _dbHelper.updateCreditCard(updatedCard);
    await loadCreditCards();
  }

  /// Updates an existing note in the database.
  ///
  /// - [note]: The updated [Note] object.
  Future<void> updateNote(Note note) async {
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      isArchived: note.isArchived,
      archivedAt: note.archivedAt,
      isDeleted: note.isDeleted,
      deletedAt: note.deletedAt,
      createdAt: note.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _dbHelper.updateNote(updatedNote);
    await loadNotes();
  }

  /// Archives a login by its ID.
  ///
  /// - [id]: The ID of the login to archive.
  Future<void> archiveLogins(int id) async {
    await _dbHelper.archiveLogins(id);
    await loadLogins();
  }

  /// Archives a credit card by its ID.
  ///
  /// - [id]: The ID of the credit card to archive.
  Future<void> archiveCreditCard(int id) async {
    await _dbHelper.archiveCreditCard(id);
    await loadCreditCards();
  }

  /// Moves a credit card to the archive by its ID.
  ///
  /// - [id]: The ID of the credit card to move to the archive.
  Future<void> moveCreditCardToArchive(int id) async {
    await _dbHelper.archiveCreditCard(id);
    await loadCreditCards();
  }

  /// Archives a note by its ID.
  ///
  /// - [id]: The ID of the note to archive.
  Future<void> archiveNote(int id) async {
    await _dbHelper.archiveNote(id);
    await loadNotes();
  }

  /// Deletes a login by its ID (marks it as deleted).
  ///
  /// - [id]: The ID of the login to delete.
  Future<void> deleteLogins(int id) async {
    await _dbHelper.deleteLogins(id);
    await loadLogins();
  }

  /// Deletes a credit card by its ID (marks it as deleted).
  ///
  /// - [id]: The ID of the credit card to delete.
  Future<void> deleteCreditCard(int id) async {
    await _dbHelper.deleteCreditCard(id);
    await loadCreditCards();
  }

  /// Moves a note to the trash by its ID (marks it as deleted).
  ///
  /// - [id]: The ID of the note to move to the trash.
  Future<void> moveToTrash(int id) async {
    await _dbHelper.deleteNote(id);
    await loadNotes();
  }

  /// Restores a login by its ID (unmarks it as archived or deleted).
  ///
  /// - [id]: The ID of the login to restore.
  Future<void> restoreLogins(int id) async {
    await _dbHelper.restoreLogins(id);
    await loadLogins();
  }

  /// Restores a credit card by its ID (unmarks it as archived or deleted).
  ///
  /// - [id]: The ID of the credit card to restore.
  Future<void> restoreCreditCard(int id) async {
    await _dbHelper.restoreCreditCard(id);
    await loadCreditCards();
  }

  /// Restores a note by its ID (unmarks it as archived or deleted).
  ///
  /// - [id]: The ID of the note to restore.
  Future<void> restoreNote(int id) async {
    await _dbHelper.restoreNote(id);
    await loadNotes();
  }

  /// Permanently deletes a login by its ID.
  ///
  /// - [id]: The ID of the login to permanently delete.
  Future<void> permanentlyDeleteLogin(int id) async {
    await _dbHelper.permanentlyDeleteLogins(id);
    await loadLogins();
  }

  /// Permanently deletes a credit card by its ID.
  ///
  /// - [id]: The ID of the credit card to permanently delete.
  Future<void> permanentlyDeleteCreditCard(int id) async {
    await _dbHelper.permanentlyDeleteCreditCard(id);
    await loadCreditCards();
  }

  /// Permanently deletes a note by its ID.
  ///
  /// - [id]: The ID of the note to permanently delete.
  Future<void> permanentlyDeleteNote(int id) async {
    await _dbHelper.permanentlyDeleteNote(id);
    await loadNotes();
  }
}
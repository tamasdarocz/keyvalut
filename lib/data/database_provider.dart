import 'package:flutter/foundation.dart';
import 'package:keyvalut/data/database_model.dart';
import 'package:keyvalut/data/database_helper.dart';

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

  DatabaseHelper? _dbHelper;

  DatabaseProvider({String? initialDatabaseName}) {
    if (initialDatabaseName != null && initialDatabaseName.isNotEmpty) {
      _dbHelper = DatabaseHelper(initialDatabaseName);
      loadLogins();
      loadCreditCards();
      loadNotes();
    }
  }

  void setDatabaseName(String databaseName) {
    if (databaseName.isNotEmpty) {
      _dbHelper = DatabaseHelper(databaseName);
      loadLogins();
      loadCreditCards();
      loadNotes();
    } else {
      _dbHelper = null;
      _logins = [];
      _archivedLogins = [];
      _deletedLogins = [];
      _creditCards = [];
      _archivedCreditCards = [];
      _deletedCreditCards = [];
      _notes = [];
      _archivedNotes = [];
      _deletedNotes = [];
      notifyListeners();
    }
  }

  Future<void> loadLogins() async {
    if (_dbHelper == null) {
      _logins = [];
      _archivedLogins = [];
      _deletedLogins = [];
      notifyListeners();
      return;
    }
    final allLogins = await _dbHelper!.getLogins(includeArchived: true, includeDeleted: true);
    _logins = allLogins.where((c) => !c.isArchived && !c.isDeleted).toList();
    _archivedLogins = allLogins.where((c) => c.isArchived && !c.isDeleted).toList();
    _deletedLogins = allLogins.where((c) => c.isDeleted).toList();
    notifyListeners();
  }

  Future<void> loadCreditCards() async {
    if (_dbHelper == null) {
      _creditCards = [];
      _archivedCreditCards = [];
      _deletedCreditCards = [];
      notifyListeners();
      return;
    }
    final allCreditCardsMaps = await _dbHelper!.queryAllCreditCards(includeArchived: true, includeDeleted: true);
    final allCreditCards = allCreditCardsMaps.map((map) => CreditCard.fromMap(map)).toList();
    _creditCards = allCreditCards.where((c) => !c.isArchived && !c.isDeleted).toList();
    _archivedCreditCards = allCreditCards.where((c) => c.isArchived && !c.isDeleted).toList();
    _deletedCreditCards = allCreditCards.where((c) => c.isDeleted).toList();
    notifyListeners();
  }

  Future<void> loadNotes() async {
    if (_dbHelper == null) {
      _notes = [];
      _archivedNotes = [];
      _deletedNotes = [];
      notifyListeners();
      return;
    }
    final allNotes = await _dbHelper!.getNotes(includeArchived: true, includeDeleted: true);
    _notes = allNotes.where((n) => !n.isArchived && !n.isDeleted).toList();
    _archivedNotes = allNotes.where((n) => n.isArchived && !n.isDeleted).toList();
    _deletedNotes = allNotes.where((n) => n.isDeleted).toList();
    notifyListeners();
  }

  Future<void> loadArchivedItems() async {
    await loadLogins();
    await loadCreditCards();
    await loadNotes();
  }

  Future<void> loadDeletedItems() async {
    await loadLogins();
    await loadCreditCards();
    await loadNotes();
  }

  Future<void> clearLogins() async {
    if (_dbHelper == null) {
      return;
    }
    final db = await _dbHelper!.database;
    await db.delete('logins');
    await loadLogins();
  }

  Future<void> clearCreditCards() async {
    if (_dbHelper == null) {
      return;
    }
    final db = await _dbHelper!.database;
    await db.delete('credit_cards');
    await loadCreditCards();
  }

  Future<void> clearNotes() async {
    if (_dbHelper == null) {
      return;
    }
    final db = await _dbHelper!.database;
    await db.delete('notes');
    await loadNotes();
  }

  Future<void> clearAllData() async {
    await clearLogins();
    await clearCreditCards();
    await clearNotes();
  }

  Future<void> addLogin(Logins login) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.insertLogins(login);
    await loadLogins();
  }

  Future<void> addCreditCard(CreditCard card) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.insertCreditCard(card);
    await loadCreditCards();
  }

  Future<void> addNote(Note note) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.insertNote(note);
    await loadNotes();
  }

  Future<void> updateLogin(Logins login) async {
    if (_dbHelper == null) {
      return;
    }
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
      updatedAt: DateTime.now().toIso8601String(), // Update updatedAt
    );
    await _dbHelper!.updateLogins(updatedLogin);
    await loadLogins();
  }

  Future<void> updateCreditCard(CreditCard card) async {
    if (_dbHelper == null) {
      return;
    }
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
      updatedAt: DateTime.now().toIso8601String(), // Update updatedAt
    );
    await _dbHelper!.updateCreditCard(updatedCard);
    await loadCreditCards();
  }

  Future<void> updateNote(Note note) async {
    if (_dbHelper == null) {
      return;
    }
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      isArchived: note.isArchived,
      archivedAt: note.archivedAt,
      isDeleted: note.isDeleted,
      deletedAt: note.deletedAt,
      createdAt: note.createdAt,
      updatedAt: DateTime.now().toIso8601String(), // Update updatedAt
    );
    await _dbHelper!.updateNote(updatedNote);
    await loadNotes();
  }

  Future<void> archiveLogins(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.archiveLogins(id);
    await loadLogins();
  }

  Future<void> archiveCreditCard(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.archiveCreditCard(id);
    await loadCreditCards();
  }

  Future<void> moveCreditCardToArchive(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.archiveCreditCard(id);
    await loadCreditCards();
  }

  Future<void> archiveNote(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.archiveNote(id);
    await loadNotes();
  }

  Future<void> deleteLogins(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.deleteLogins(id);
    await loadLogins();
  }

  Future<void> deleteCreditCard(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.deleteCreditCard(id);
    await loadCreditCards();
  }

  Future<void> moveToTrash(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.deleteNote(id);
    await loadNotes();
  }

  Future<void> restoreLogins(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.restoreLogins(id);
    await loadLogins();
  }

  Future<void> restoreCreditCard(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.restoreCreditCard(id);
    await loadCreditCards();
  }

  Future<void> restoreNote(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.restoreNote(id);
    await loadNotes();
  }

  Future<void> permanentlyDeleteLogin(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.permanentlyDeleteLogins(id);
    await loadLogins();
  }

  Future<void> permanentlyDeleteCreditCard(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.permanentlyDeleteCreditCard(id);
    await loadCreditCards();
  }

  Future<void> permanentlyDeleteNote(int id) async {
    if (_dbHelper == null) {
      return;
    }
    await _dbHelper!.permanentlyDeleteNote(id);
    await loadNotes();
  }
}
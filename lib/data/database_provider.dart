import 'package:flutter/foundation.dart';
import 'package:keyvalut/data/database_model.dart';
import 'package:keyvalut/data/database_helper.dart';

class CredentialProvider with ChangeNotifier {
  List<Logins> _credentials = [];
  List<Logins> _archivedCredentials = [];
  List<Logins> _deletedCredentials = [];
  List<CreditCard> _creditCards = [];
  List<CreditCard> _archivedCreditCards = [];
  List<CreditCard> _deletedCreditCards = [];
  List<Note> _notes = [];
  List<Note> _archivedNotes = [];
  List<Note> _deletedNotes = [];

  List<Logins> get credentials => _credentials;
  List<Logins> get archivedCredentials => _archivedCredentials;
  List<Logins> get deletedCredentials => _deletedCredentials;
  List<CreditCard> get creditCards => _creditCards;
  List<CreditCard> get archivedCreditCards => _archivedCreditCards;
  List<CreditCard> get deletedCreditCards => _deletedCreditCards;
  List<Note> get notes => _notes;
  List<Note> get archivedNotes => _archivedNotes;
  List<Note> get deletedNotes => _deletedNotes;

  DatabaseHelper? _dbHelper;

  CredentialProvider({String? initialDatabaseName}) {
    print('CredentialProvider - Initializing with databaseName: $initialDatabaseName');
    if (initialDatabaseName != null && initialDatabaseName.isNotEmpty) {
      _dbHelper = DatabaseHelper(initialDatabaseName);
      loadCredentials();
      loadCreditCards();
      loadNotes();
    }
  }

  void setDatabaseName(String databaseName) {
    print('CredentialProvider - Setting databaseName: $databaseName');
    if (databaseName.isNotEmpty) {
      _dbHelper = DatabaseHelper(databaseName);
      loadCredentials();
      loadCreditCards();
      loadNotes();
    } else {
      _dbHelper = null;
      _credentials = [];
      _archivedCredentials = [];
      _deletedCredentials = [];
      _creditCards = [];
      _archivedCreditCards = [];
      _deletedCreditCards = [];
      _notes = [];
      _archivedNotes = [];
      _deletedNotes = [];
      notifyListeners();
    }
  }

  Future<void> loadCredentials() async {
    if (_dbHelper == null) {
      print('CredentialProvider - loadCredentials: _dbHelper is null');
      _credentials = [];
      _archivedCredentials = [];
      _deletedCredentials = [];
      notifyListeners();
      return;
    }
    final allCredentials = await _dbHelper!.getCredentials(includeArchived: true, includeDeleted: true);
    _credentials = allCredentials.where((c) => !c.isArchived && !c.isDeleted).toList();
    _archivedCredentials = allCredentials.where((c) => c.isArchived && !c.isDeleted).toList();
    _deletedCredentials = allCredentials.where((c) => c.isDeleted).toList();
    notifyListeners();
  }

  Future<void> loadCreditCards() async {
    if (_dbHelper == null) {
      print('CredentialProvider - loadCreditCards: _dbHelper is null');
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
      print('CredentialProvider - loadNotes: _dbHelper is null');
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
    await loadCredentials();
    await loadCreditCards();
    await loadNotes();
  }

  Future<void> loadDeletedItems() async {
    await loadCredentials();
    await loadCreditCards();
    await loadNotes();
  }

  Future<void> clearCredentials() async {
    if (_dbHelper == null) {
      print('CredentialProvider - clearCredentials: _dbHelper is null');
      return;
    }
    final db = await _dbHelper!.database;
    await db.delete('credentials');
    await loadCredentials();
  }

  Future<void> clearCreditCards() async {
    if (_dbHelper == null) {
      print('CredentialProvider - clearCreditCards: _dbHelper is null');
      return;
    }
    final db = await _dbHelper!.database;
    await db.delete('credit_cards');
    await loadCreditCards();
  }

  Future<void> clearNotes() async {
    if (_dbHelper == null) {
      print('CredentialProvider - clearNotes: _dbHelper is null');
      return;
    }
    final db = await _dbHelper!.database;
    await db.delete('notes');
    await loadNotes();
  }

  Future<void> clearAllData() async {
    await clearCredentials();
    await clearCreditCards();
    await clearNotes();
  }

  Future<void> addCredential(Logins credential) async {
    if (_dbHelper == null) {
      print('CredentialProvider - addCredential: _dbHelper is null');
      return;
    }
    await _dbHelper!.insertCredential(credential);
    await loadCredentials();
  }

  Future<void> addCreditCard(CreditCard card) async {
    if (_dbHelper == null) {
      print('CredentialProvider - addCreditCard: _dbHelper is null');
      return;
    }
    await _dbHelper!.insertCreditCard(card);
    await loadCreditCards();
  }

  Future<void> addNote(Note note) async {
    if (_dbHelper == null) {
      print('CredentialProvider - addNote: _dbHelper is null');
      return;
    }
    await _dbHelper!.insertNote(note);
    await loadNotes();
  }

  Future<void> updateCredential(Logins credential) async {
    if (_dbHelper == null) {
      print('CredentialProvider - updateCredential: _dbHelper is null');
      return;
    }
    final updatedCredential = Logins(
      id: credential.id,
      title: credential.title,
      website: credential.website,
      email: credential.email,
      username: credential.username,
      password: credential.password,
      totpSecret: credential.totpSecret,
      isArchived: credential.isArchived,
      isDeleted: credential.isDeleted,
      archivedAt: credential.archivedAt,
      deletedAt: credential.deletedAt,
      createdAt: credential.createdAt,
      updatedAt: DateTime.now().toIso8601String(), // Update updatedAt
    );
    await _dbHelper!.updateCredential(updatedCredential);
    await loadCredentials();
  }

  Future<void> updateCreditCard(CreditCard card) async {
    if (_dbHelper == null) {
      print('CredentialProvider - updateCreditCard: _dbHelper is null');
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
      print('CredentialProvider - updateNote: _dbHelper is null');
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

  Future<void> archiveCredential(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - archiveCredential: _dbHelper is null');
      return;
    }
    await _dbHelper!.archiveCredential(id);
    await loadCredentials();
  }

  Future<void> archiveCreditCard(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - archiveCreditCard: _dbHelper is null');
      return;
    }
    await _dbHelper!.archiveCreditCard(id);
    await loadCreditCards();
  }

  Future<void> moveCreditCardToArchive(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - moveCreditCardToArchive: _dbHelper is null');
      return;
    }
    await _dbHelper!.archiveCreditCard(id);
    await loadCreditCards();
  }

  Future<void> archiveNote(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - archiveNote: _dbHelper is null');
      return;
    }
    await _dbHelper!.archiveNote(id);
    await loadNotes();
  }

  Future<void> deleteCredential(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - deleteCredential: _dbHelper is null');
      return;
    }
    await _dbHelper!.deleteCredential(id);
    await loadCredentials();
  }

  Future<void> deleteCreditCard(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - deleteCreditCard: _dbHelper is null');
      return;
    }
    await _dbHelper!.deleteCreditCard(id);
    await loadCreditCards();
  }

  Future<void> moveToTrash(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - moveToTrash: _dbHelper is null');
      return;
    }
    await _dbHelper!.deleteNote(id);
    await loadNotes();
  }

  Future<void> restoreCredential(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - restoreCredential: _dbHelper is null');
      return;
    }
    await _dbHelper!.restoreCredential(id);
    await loadCredentials();
  }

  Future<void> restoreCreditCard(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - restoreCreditCard: _dbHelper is null');
      return;
    }
    await _dbHelper!.restoreCreditCard(id);
    await loadCreditCards();
  }

  Future<void> restoreNote(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - restoreNote: _dbHelper is null');
      return;
    }
    await _dbHelper!.restoreNote(id);
    await loadNotes();
  }

  Future<void> permanentlyDeleteCredential(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - permanentlyDeleteCredential: _dbHelper is null');
      return;
    }
    await _dbHelper!.permanentlyDeleteCredential(id);
    await loadCredentials();
  }

  Future<void> permanentlyDeleteCreditCard(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - permanentlyDeleteCreditCard: _dbHelper is null');
      return;
    }
    await _dbHelper!.permanentlyDeleteCreditCard(id);
    await loadCreditCards();
  }

  Future<void> permanentlyDeleteNote(int id) async {
    if (_dbHelper == null) {
      print('CredentialProvider - permanentlyDeleteNote: _dbHelper is null');
      return;
    }
    await _dbHelper!.permanentlyDeleteNote(id);
    await loadNotes();
  }
}
import 'package:flutter/foundation.dart';
import 'package:keyvalut/data/credential_model.dart';
import 'package:keyvalut/data/database_helper.dart';

class CredentialProvider with ChangeNotifier {
  List<Credential> _credentials = [];
  List<Credential> _archivedCredentials = [];
  List<Credential> _deletedCredentials = [];
  List<CreditCard> _creditCards = [];
  List<CreditCard> _archivedCreditCards = [];
  List<CreditCard> _deletedCreditCards = [];
  List<Note> _notes = [];
  List<Note> _archivedNotes = [];
  List<Note> _deletedNotes = [];

  List<Credential> get credentials => _credentials;
  List<Credential> get archivedCredentials => _archivedCredentials;
  List<Credential> get deletedCredentials => _deletedCredentials;
  List<CreditCard> get creditCards => _creditCards;
  List<CreditCard> get archivedCreditCards => _archivedCreditCards;
  List<CreditCard> get deletedCreditCards => _deletedCreditCards;
  List<Note> get notes => _notes;
  List<Note> get archivedNotes => _archivedNotes;
  List<Note> get deletedNotes => _deletedNotes;

  late DatabaseHelper _dbHelper;

  CredentialProvider({String? initialDatabaseName}) {
    _dbHelper = DatabaseHelper(initialDatabaseName ?? 'default');
  }

  void setDatabaseName(String databaseName) {
    _dbHelper = DatabaseHelper(databaseName);
    // Reload data for the new database
    loadCredentials();
    loadCreditCards();
    loadNotes();
  }

  Future<void> loadCredentials() async {
    final allCredentials = await _dbHelper.getCredentials(includeArchived: true, includeDeleted: true);
    _credentials = allCredentials.where((c) => !c.isArchived && !c.isDeleted).toList();
    _archivedCredentials = allCredentials.where((c) => c.isArchived && !c.isDeleted).toList();
    _deletedCredentials = allCredentials.where((c) => c.isDeleted).toList();
    notifyListeners();
  }

  Future<void> loadCreditCards() async {
    final allCreditCardsMaps = await _dbHelper.queryAllCreditCards(includeArchived: true, includeDeleted: true);
    final allCreditCards = allCreditCardsMaps.map((map) => CreditCard.fromMap(map)).toList();
    _creditCards = allCreditCards.where((c) => !c.isArchived && !c.isDeleted).toList();
    _archivedCreditCards = allCreditCards.where((c) => c.isArchived && !c.isDeleted).toList();
    _deletedCreditCards = allCreditCards.where((c) => c.isDeleted).toList();
    notifyListeners();
  }

  Future<void> loadNotes() async {
    final allNotes = await _dbHelper.getNotes(includeArchived: true, includeDeleted: true);
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
    final db = await _dbHelper.database;
    await db.delete('credentials');
    await loadCredentials();
  }

  Future<void> clearCreditCards() async {
    final db = await _dbHelper.database;
    await db.delete('credit_cards');
    await loadCreditCards();
  }

  Future<void> clearNotes() async {
    final db = await _dbHelper.database;
    await db.delete('notes');
    await loadNotes();
  }

  Future<void> clearAllData() async {
    await clearCredentials();
    await clearCreditCards();
    await clearNotes();
  }

  Future<void> addCredential(Credential credential) async {
    await _dbHelper.insertCredential(credential);
    await loadCredentials();
  }

  Future<void> addCreditCard(CreditCard card) async {
    await _dbHelper.insertCreditCard(card);
    await loadCreditCards();
  }

  Future<void> addNote(Note note) async {
    await _dbHelper.insertNote(note);
    await loadNotes();
  }

  Future<void> updateCredential(Credential credential) async {
    await _dbHelper.updateCredential(credential);
    await loadCredentials();
  }

  Future<void> updateCreditCard(CreditCard card) async {
    await _dbHelper.updateCreditCard(card);
    await loadCreditCards();
  }

  Future<void> updateNote(Note note) async {
    await _dbHelper.updateNote(note);
    await loadNotes();
  }

  Future<void> archiveCredential(int id) async {
    await _dbHelper.archiveCredential(id);
    await loadCredentials();
  }

  Future<void> archiveCreditCard(int id) async {
    await _dbHelper.archiveCreditCard(id);
    await loadCreditCards();
  }

  Future<void> moveCreditCardToArchive(int id) async {
    await _dbHelper.archiveCreditCard(id);
    await loadCreditCards();
  }

  Future<void> archiveNote(int id) async {
    await _dbHelper.archiveNote(id);
    await loadNotes();
  }

  Future<void> deleteCredential(int id) async {
    await _dbHelper.deleteCredential(id);
    await loadCredentials();
  }

  Future<void> deleteCreditCard(int id) async {
    await _dbHelper.deleteCreditCard(id);
    await loadCreditCards();
  }

  Future<void> moveToTrash(int id) async {
    await _dbHelper.deleteNote(id);
    await loadNotes();
  }

  Future<void> restoreCredential(int id) async {
    await _dbHelper.restoreCredential(id);
    await loadCredentials();
  }

  Future<void> restoreCreditCard(int id) async {
    await _dbHelper.restoreCreditCard(id);
    await loadCreditCards();
  }

  Future<void> restoreNote(int id) async {
    await _dbHelper.restoreNote(id);
    await loadNotes();
  }

  Future<void> permanentlyDeleteCredential(int id) async {
    await _dbHelper.permanentlyDeleteCredential(id);
    await loadCredentials();
  }

  Future<void> permanentlyDeleteCreditCard(int id) async {
    await _dbHelper.permanentlyDeleteCreditCard(id);
    await loadCreditCards();
  }

  Future<void> permanentlyDeleteNote(int id) async {
    await _dbHelper.permanentlyDeleteNote(id);
    await loadNotes();
  }
}
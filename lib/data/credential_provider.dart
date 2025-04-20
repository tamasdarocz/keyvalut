import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'credential_model.dart';

class CredentialProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<CreditCard> _creditCards = [];
  List<Credential> _credentials = [];
  List<CreditCard> _archivedCreditCards = [];
  List<Credential> _archivedCredentials = [];
  List<CreditCard> _deletedCreditCards = [];
  List<Credential> _deletedCredentials = [];

  // Getters
  List<CreditCard> get creditCards => _creditCards;
  List<Credential> get credentials => _credentials;
  List<CreditCard> get archivedCreditCards => _archivedCreditCards;
  List<Credential> get archivedCredentials => _archivedCredentials;
  List<CreditCard> get deletedCreditCards => _deletedCreditCards;
  List<Credential> get deletedCredentials => _deletedCredentials;

  // Load data
  Future<void> loadCreditCards() async {
    final maps = await _dbHelper.queryAllCreditCards();
    _creditCards = maps.map((map) => CreditCard.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> loadCredentials() async {
    _credentials = await _dbHelper.getCredentials();
    notifyListeners();
  }

  Future<void> loadArchivedItems() async {
    final credentialMaps = await _dbHelper.getCredentials(includeArchived: true);
    _archivedCredentials = credentialMaps.where((cred) => cred.isArchived).toList();

    final creditCardMaps = await _dbHelper.queryAllCreditCards(includeArchived: true);
    _archivedCreditCards = creditCardMaps
        .map((map) => CreditCard.fromMap(map))
        .where((card) => card.isArchived)
        .toList();

    notifyListeners();
  }

  Future<void> loadDeletedItems() async {
    final credentialMaps = await _dbHelper.getCredentials(includeDeleted: true);
    _deletedCredentials = credentialMaps.where((cred) => cred.isDeleted).toList();

    final creditCardMaps = await _dbHelper.queryAllCreditCards(includeDeleted: true);
    _deletedCreditCards = creditCardMaps
        .map((map) => CreditCard.fromMap(map))
        .where((card) => card.isDeleted)
        .toList();

    notifyListeners();
  }

  // Clear data
  Future<void> clearCredentials() async {
    _credentials.clear();
    _archivedCredentials.clear();
    _deletedCredentials.clear();
    await _dbHelper.deleteDatabase();
    notifyListeners();
  }

  // Credential operations
  Future<int> addCredential(Credential credential) async {
    final newId = await _dbHelper.insertCredential(credential);
    await loadCredentials();
    return newId;
  }

  Future<void> updateCredential(Credential credential) async {
    await _dbHelper.updateCredential(credential);
    await loadCredentials();
    await loadArchivedItems();
    await loadDeletedItems();
  }

  Future<void> archiveCredential(int id) async {
    await _dbHelper.archiveCredential(id);
    await loadCredentials();
    await loadArchivedItems();
  }

  Future<void> deleteCredential(int id) async {
    await _dbHelper.deleteCredential(id);
    await loadCredentials();
    await loadDeletedItems();
  }

  Future<void> permanentlyDeleteCredential(int id) async {
    await _dbHelper.permanentlyDeleteCredential(id);
    await loadDeletedItems();
  }

  Future<void> restoreCredential(int id) async {
    await _dbHelper.restoreCredential(id);
    await loadCredentials();
    await loadArchivedItems();
    await loadDeletedItems();
  }

  // Credit Card operations
  Future<void> moveCreditCardToArchive(int id) async {
    await _dbHelper.archiveCreditCard(id);
    await loadCreditCards();
    await loadArchivedItems();
  }

  Future<void> deleteCreditCard(int id) async {
    await _dbHelper.deleteCreditCard(id);
    await loadCreditCards();
    await loadDeletedItems();
  }

  Future<void> permanentlyDeleteCreditCard(int id) async {
    await _dbHelper.permanentlyDeleteCreditCard(id);
    await loadDeletedItems();
  }

  Future<void> restoreCreditCard(int id) async {
    await _dbHelper.restoreCreditCard(id);
    await loadCreditCards();
    await loadArchivedItems();
    await loadDeletedItems();
  }
}
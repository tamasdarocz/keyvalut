import 'package:flutter/foundation.dart';
import 'package:keyvalut/data/credential_model.dart';
import 'package:keyvalut/data/database_helper.dart';

class CredentialProvider with ChangeNotifier {
  List<Credential> _credentials = [];

  // Get all credentials
  List<Credential> get credentials => _credentials.where((c) => !c.isArchived && !c.isDeleted).toList();

  // Get archived credentials
  List<Credential> get archivedCredentials => _credentials.where((c) => c.isArchived && !c.isDeleted).toList();

  // Get deleted credentials
  List<Credential> get deletedCredentials => _credentials.where((c) => c.isDeleted).toList();

  CredentialProvider() {
    loadCredentials();
  }

  Future<void> loadCredentials() async {
    _credentials = await DatabaseHelper.instance.getCredentials(); // Changed from getAllCredentials to getCredentials
    notifyListeners();
  }

  Future<void> addCredential(Credential credential) async {
    await DatabaseHelper.instance.insertCredential(credential);
    await loadCredentials();
  }

  Future<void> updateCredential(Credential credential) async {
    await DatabaseHelper.instance.updateCredential(credential);
    await loadCredentials();
  }

  Future<void> deleteCredential(int id) async {
    await DatabaseHelper.instance.deleteCredential(id);
    await loadCredentials();
  }

  // Add the moveToArchive method
  Future<void> moveToArchive(int id) async {
    final credential = _credentials.firstWhere((c) => c.id == id);
    final updatedCredential = Credential(
      id: credential.id,
      title: credential.title,
      website: credential.website,
      email: credential.email,
      username: credential.username,
      password: credential.password,
      totpSecret: credential.totpSecret,
      isArchived: true,
      isDeleted: credential.isDeleted,
      deletedAt: credential.deletedAt,
      archivedAt: DateTime.now(),
    );
    await updateCredential(updatedCredential);
  }

  Future<void> moveToTrash(int id) async {
    final credential = _credentials.firstWhere((c) => c.id == id);
    final updatedCredential = Credential(
      id: credential.id,
      title: credential.title,
      website: credential.website,
      email: credential.email,
      username: credential.username,
      password: credential.password,
      totpSecret: credential.totpSecret,
      isArchived: credential.isArchived,
      isDeleted: true,
      deletedAt: DateTime.now(),
      archivedAt: credential.archivedAt,
    );
    await updateCredential(updatedCredential);
  }

  // Restore from trash or archive
  Future<void> restoreCredential(int id) async {
    final credential = _credentials.firstWhere((c) => c.id == id);
    final updatedCredential = Credential(
      id: credential.id,
      title: credential.title,
      website: credential.website,
      email: credential.email,
      username: credential.username,
      password: credential.password,
      totpSecret: credential.totpSecret,
      isArchived: false,
      isDeleted: false,
      deletedAt: null,
      archivedAt: null,
    );
    await updateCredential(updatedCredential);
  }

  void clearCredentials() {
    _credentials = [];
    notifyListeners();
  }
}
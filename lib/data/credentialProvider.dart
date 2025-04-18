import 'package:flutter/foundation.dart';
import 'package:keyvalut/data/credential_model.dart';
import 'package:keyvalut/data/database_helper.dart';

class CredentialProvider with ChangeNotifier {
  List<Credential> _credentials = [];

  List<Credential> get credentials => _credentials.where((c) => !c.isArchived && !c.isDeleted).toList();
  List<Credential> get archivedCredentials => _credentials.where((c) => c.isArchived && !c.isDeleted).toList();
  List<Credential> get deletedCredentials => _credentials.where((c) => c.isDeleted).toList();

  CredentialProvider() {
    loadCredentials();
  }

  Future<void> loadCredentials() async {
    _credentials = await DatabaseHelper.instance.getCredentials();
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

  // Soft delete (move to trash)
  Future<void> moveToTrash(Credential credential) async {
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
  Future<void> restoreCredential(Credential credential) async {
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
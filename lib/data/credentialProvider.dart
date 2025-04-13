import 'package:flutter/foundation.dart';
import 'credential_model.dart';
import 'database_helper.dart';

class CredentialProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Credential> _credentials = [];

  List<Credential> get credentials => _credentials;

  // Load credentials and notify listeners
  Future<void> loadCredentials() async {
    _credentials = await _dbHelper.getCredentials();
    notifyListeners(); // Update UI after loading
  }

  // Add credential and refresh list
  Future<void> addCredential(Credential credential) async {
    await _dbHelper.insertCredential(credential);
    await loadCredentials(); // Reload data and notify
  }

  // Update credential and refresh list
  Future<void> updateCredential(Credential credential) async {
    await _dbHelper.updateCredential(credential);
    await loadCredentials(); // Reload data and notify
  }

  // Delete credential and refresh list
  Future<void> deleteCredential(int id) async {
    await _dbHelper.deleteCredential(id);
    await loadCredentials(); // Reload data and notify
  }
}
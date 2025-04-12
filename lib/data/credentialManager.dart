import 'package:flutter/foundation.dart';

import 'credential_model.dart';
import 'database_helper.dart';

class CredentialManager extends ChangeNotifier {
  List<Credential> _credentials = [];

  // Load credentials from the database
  Future<void> loadCredentials() async {
    _credentials = await DatabaseHelper.instance.getCredentials();
    notifyListeners(); // Tell the UI to update when data is loaded
  }

  // Add a new credential
  Future<void> addCredential(Credential credential) async {
    await DatabaseHelper.instance.insertCredential(credential);
    await loadCredentials(); // Reload the data and notify the UI
  }

  // Update an existing credential
  Future<void> updateCredential(Credential credential) async {
    await DatabaseHelper.instance.updateCredential(credential);
    await loadCredentials(); // Reload the data and notify the UI
  }

  // Delete a credential
  Future<void> deleteCredential(int id) async {
    await DatabaseHelper.instance.deleteCredential(id);
    await loadCredentials(); // Reload the data and notify the UI
  }
}
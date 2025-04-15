import 'package:flutter/foundation.dart';
import 'package:keyvalut/data/credential_model.dart';
import 'package:keyvalut/data/database_helper.dart';

class CredentialProvider with ChangeNotifier {
  List<Credential> _credentials = [];

  List<Credential> get credentials => _credentials;

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

  void clearCredentials() {
    _credentials = [];
    notifyListeners();
  }
}
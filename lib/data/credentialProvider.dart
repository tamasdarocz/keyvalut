import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class CredentialProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _authenticatorEntries = [];

  List<Map<String, dynamic>> get authenticatorEntries => _authenticatorEntries;

  CredentialProvider() {
    _loadAuthenticatorEntries();
  }

  Future<void> _loadAuthenticatorEntries() async {
    final entries = await _dbHelper.getAuthenticators();
    _authenticatorEntries = entries;
    notifyListeners();
  }

  Future<void> addAuthenticatorEntry({
    required String serviceName,
    required String totpSecret,
  }) async {
    await _dbHelper.insertAuthenticator({
      'service_name': serviceName,
      'totp_secret': totpSecret,
    });
    await _loadAuthenticatorEntries();
  }

  Future<void> clearCredentials() async {
    await _dbHelper.clearAll();
    _authenticatorEntries = [];
    notifyListeners();
  }
}
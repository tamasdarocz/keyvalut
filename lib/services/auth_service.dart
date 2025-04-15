import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _masterPassword;
  late List<int> _key;
  late List<int> _salt;

  AuthService() {
    _initializeKeyAndSalt();
  }

  void _initializeKeyAndSalt() {
    _key = utf8.encode('your-32-byte-key-here-1234567890'); // Must be 32 bytes
    _salt = utf8.encode('your-16-byte-salt-here-12345678'); // Must be 16 bytes
  }

  Future<void> setMasterPassword(String password) async {
    _masterPassword = password;
    final key = sha256.convert(utf8.encode(password)).bytes;
    await _secureStorage.write(key: 'masterPassword', value: base64Encode(key));
    await _secureStorage.write(key: 'key', value: base64Encode(_key));
    await _secureStorage.write(key: 'salt', value: base64Encode(_salt));
  }

  Future<bool> verifyMasterPassword(String password) async {
    final storedPassword = await _secureStorage.read(key: 'masterPassword');
    if (storedPassword == null) return false;
    final key = sha256.convert(utf8.encode(password)).bytes;
    return base64Encode(key) == storedPassword;
  }

  Future<bool> isMasterPasswordSet() async {
    final storedPassword = await _secureStorage.read(key: 'masterPassword');
    return storedPassword != null;
  }

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({String reason = 'Please authenticate to access your credentials'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason, // Use the provided reason
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: 'biometricEnabled');
    return enabled == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: 'biometricEnabled', value: enabled.toString());
  }

  List<int> get key => _key;
  List<int> get salt => _salt;
  String? get masterPassword => _masterPassword;
}
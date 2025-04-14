import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _prefsKey = 'master_password_set';
  static const _ivKey = 'encryption_iv';

  Future<bool> isMasterPasswordSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setMasterPassword(String password) async {
    // Generate secure random bytes for salt
    final random = Random.secure();
    final salt = List<int>.generate(16, (i) => random.nextInt(256));

    // Derive key using PBKDF2
    final key = await _deriveKey(password, salt);

    // Store encoded values
    await _storage.write(key: 'master_key', value: base64Encode(await key.extractBytes()));
    await _storage.write(key: 'salt', value: base64Encode(salt));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    return await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,  // Using bits parameter instead of keyLength
    ).deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  Future<bool> verifyMasterPassword(String password) async {  // <-- Correct method signature
    final saltBase64 = await _storage.read(key: 'salt');
    final storedKeyBase64 = await _storage.read(key: 'master_key');

    if (saltBase64 == null || storedKeyBase64 == null) return false;

    final salt = base64Decode(saltBase64);
    final storedKey = base64Decode(storedKeyBase64);

    final key = await _deriveKey(password, salt);
    return const DeepCollectionEquality().equals(await key.extractBytes(), storedKey);
  }
  }

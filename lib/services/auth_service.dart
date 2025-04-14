import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _prefsKey = 'master_password_set';
  static const _ivKey = 'encryption_iv';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _biometricPasswordKey = 'biometric_password';
  final _auth = LocalAuthentication();

  Future<bool> isMasterPasswordSet() async {
    final prefs = await SharedPreferences.getInstance();
    final isSet = prefs.getBool(_prefsKey) ?? false;
    if (!isSet) return false;

    final saltBase64 = await _storage.read(key: 'salt');
    final storedKeyBase64 = await _storage.read(key: 'master_key');
    if (saltBase64 == null || storedKeyBase64 == null) {
      await prefs.setBool(_prefsKey, false);
      return false;
    }
    return true;
  }

  Future<void> setMasterPassword(String password) async {
    try {
      final random = Random.secure();
      final salt = List<int>.generate(16, (i) => random.nextInt(256));
      final key = await _deriveKey(password, salt);

      await _storage.write(key: 'master_key', value: base64Encode(await key.extractBytes()));
      await _storage.write(key: 'salt', value: base64Encode(salt));

      final passwordBase64 = base64Encode(utf8.encode(password));
      await _storage.write(key: _biometricPasswordKey, value: passwordBase64);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (e) {
      rethrow;
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    return await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    ).deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  Future<bool> verifyMasterPassword(String password) async {
    final saltBase64 = await _storage.read(key: 'salt');
    final storedKeyBase64 = await _storage.read(key: 'master_key');

    if (saltBase64 == null || storedKeyBase64 == null) {
      return false;
    }

    try {
      final salt = base64Decode(saltBase64);
      final storedKey = base64Decode(storedKeyBase64);
      final key = await _deriveKey(password, salt);
      final derivedKeyBytes = await key.extractBytes();
      return const DeepCollectionEquality().equals(derivedKeyBytes, storedKey);
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await isBiometricAvailable() || !await isBiometricEnabled()) {
      return false;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock your vault',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Unlock Vault',
            biometricHint: 'Verify your identity',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: false,
        ),
      );

      if (didAuthenticate) {
        final passwordBase64 = await _storage.read(key: _biometricPasswordKey);
        if (passwordBase64 == null) {
          return false;
        }
        final password = utf8.decode(base64Decode(passwordBase64));
        return await verifyMasterPassword(password);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
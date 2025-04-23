import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:argon2/argon2.dart';

class AuthService {
  final String databaseName;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _masterCredential;
  late Uint8List _salt;

  AuthService(this.databaseName);

  Future<void> _initializeSalt() async {
    final saltKey = 'salt_$databaseName';
    final storedSalt = await _secureStorage.read(key: saltKey);
    if (storedSalt != null) {
      _salt = Uint8List.fromList(base64Decode(storedSalt));
    } else {
      final random = Random.secure();
      _salt = Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256)));
      await _secureStorage.write(key: saltKey, value: base64Encode(_salt));
    }
  }

  Future<void> setMasterCredential(String credential, {required bool isPin}) async {
    await _initializeSalt();
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_i,
      _salt,
      iterations: 2,
      memoryPowerOf2: 14,
    );
    final argon2 = Argon2BytesGenerator();
    argon2.init(parameters);
    final passwordBytes = utf8.encode(credential);
    final result = Uint8List(32);
    argon2.generateBytes(passwordBytes, result, 0, result.length);
    final masterCredentialKey = 'masterCredential_$databaseName';
    await _secureStorage.write(key: masterCredentialKey, value: base64Encode(result));
    await _secureStorage.write(key: 'isPin_$databaseName', value: isPin.toString());
  }

  Future<bool> verifyMasterCredential(String credential) async {
    await _initializeSalt();
    final masterCredentialKey = 'masterCredential_$databaseName';
    final storedCredential = await _secureStorage.read(key: masterCredentialKey);
    if (storedCredential == null) return false;
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_i,
      _salt,
      iterations: 2,
      memoryPowerOf2: 14,
    );
    final argon2 = Argon2BytesGenerator();
    argon2.init(parameters);
    final passwordBytes = utf8.encode(credential);
    final result = Uint8List(32);
    argon2.generateBytes(passwordBytes, result, 0, result.length);
    return base64Encode(result) == storedCredential;
  }

  Future<bool> isMasterCredentialSet() async {
    final masterCredentialKey = 'masterCredential_$databaseName';
    final storedCredential = await _secureStorage.read(key: masterCredentialKey);
    return storedCredential != null;
  }

  Future<bool> isPinMode() async {
    final isPinKey = 'isPin_$databaseName';
    final isPin = await _secureStorage.read(key: isPinKey);
    return isPin == 'true';
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
      final success = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: true,
        ),
      );
      if (success) {
        final storedCredential = await _secureStorage.read(key: 'masterCredential_$databaseName');
        if (storedCredential != null) {
          _masterCredential = null;
        }
      }
      return success;
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

  void clearCachedCredential() {
    _masterCredential = null;
  }
}
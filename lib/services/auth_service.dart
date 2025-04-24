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

  AuthService(this.databaseName) {
    print('AuthService initialized with databaseName: $databaseName');
  }

  Future<void> _initializeSalt() async {
    final saltKey = 'salt_$databaseName';
    final storedSalt = await _secureStorage.read(key: saltKey);
    if (storedSalt != null) {
      _salt = Uint8List.fromList(base64Decode(storedSalt));
      print('Loaded salt for $databaseName: $storedSalt');
    } else {
      final random = Random.secure();
      _salt = Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256)));
      await _secureStorage.write(key: saltKey, value: base64Encode(_salt));
      print('Generated new salt for $databaseName: ${base64Encode(_salt)}');
    }
  }

  Future<String> _generateRecoveryKey() async {
    const length = 32;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final key = StringBuffer();
    for (int i = 0; i < length; i++) {
      key.write(chars[random.nextInt(chars.length)]);
      if (i % 4 == 3 && i < length - 1) key.write('-');
    }
    return key.toString();
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
    print('Set isPin for $databaseName: $isPin');

    // Generate and store recovery key if not already set
    final recoveryKey = await _secureStorage.read(key: 'recoveryKey_$databaseName');
    if (recoveryKey == null) {
      final newRecoveryKey = await _generateRecoveryKey();
      await _secureStorage.write(key: 'recoveryKey_$databaseName', value: newRecoveryKey);
      print('Generated recovery key for $databaseName: $newRecoveryKey');
    }
  }

  Future<bool> verifyMasterCredential(String credential) async {
    print('Verifying credential for $databaseName: $credential');
    await _initializeSalt();
    final masterCredentialKey = 'masterCredential_$databaseName';
    final storedCredential = await _secureStorage.read(key: masterCredentialKey);
    print('Stored credential for $databaseName: $storedCredential');
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
    final generatedHash = base64Encode(result);
    print('Generated hash for $credential: $generatedHash');
    return generatedHash == storedCredential;
  }

  Future<bool> isMasterCredentialSet() async {
    final masterCredentialKey = 'masterCredential_$databaseName';
    final storedCredential = await _secureStorage.read(key: masterCredentialKey);
    return storedCredential != null;
  }

  Future<bool> isPinMode() async {
    final isPinKey = 'isPin_$databaseName';
    final isPin = await _secureStorage.read(key: isPinKey);
    print('Raw isPin value for $isPinKey: $isPin');
    return isPin == null || isPin == 'true';
  }

  Future<String?> getRecoveryKey() async {
    return await _secureStorage.read(key: 'recoveryKey_$databaseName');
  }

  Future<bool> verifyRecoveryKey(String recoveryKey) async {
    final storedRecoveryKey = await _secureStorage.read(key: 'recoveryKey_$databaseName');
    return storedRecoveryKey == recoveryKey;
  }

  Future<void> resetMasterCredentialWithRecoveryKey(String recoveryKey, String newCredential, {required bool isPin}) async {
    final isValid = await verifyRecoveryKey(recoveryKey);
    if (!isValid) {
      throw Exception('Invalid recovery key');
    }
    await setMasterCredential(newCredential, isPin: isPin);
    // Generate a new recovery key after reset
    final newRecoveryKey = await _generateRecoveryKey();
    await _secureStorage.write(key: 'recoveryKey_$databaseName', value: newRecoveryKey);
    print('Generated new recovery key after reset for $databaseName: $newRecoveryKey');
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
    final enabled = await _secureStorage.read(key: 'biometricEnabled_$databaseName');
    return enabled == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: 'biometricEnabled_$databaseName', value: enabled.toString());
  }

  void clearCachedCredential() {
    _masterCredential = null;
  }
}
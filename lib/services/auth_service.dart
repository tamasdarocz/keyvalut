import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:argon2/argon2.dart';

/// A service class that handles authentication-related operations for a specific database.
///
/// Manages biometric authentication, master credential (PIN or password), and recovery key operations.
class AuthService {
  String _databaseName; // Changed from final to mutable
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Uint8List _salt;

  static const int _thirdFailedAttemptThreshold = 3;
  static const int _fourthFailedAttemptThreshold = 4;
  static const int _fifthFailedAttemptThreshold = 5;
  static const int _forceResetThreshold = 6;
  static const int _thirdLockoutDurationSeconds = 1;
  static const int _fourthLockoutDurationSeconds = 120;
  static const int _fifthLockoutDurationSeconds = 300;

  AuthService(String databaseName) : _databaseName = databaseName;

  /// Updates the database name used by this [AuthService] instance.
  ///
  /// - [newDatabaseName]: The new database name to use.
  void setDatabaseName(String newDatabaseName) {
    _databaseName = newDatabaseName;
  }

  Future<void> _initializeSalt() async {
    final saltKey = 'salt_$_databaseName';
    final storedSalt = await _secureStorage.read(key: saltKey);
    if (storedSalt != null) {
      _salt = Uint8List.fromList(base64Decode(storedSalt));
    } else {
      final random = Random.secure();
      _salt = Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256)));
      await _secureStorage.write(key: saltKey, value: base64Encode(_salt));
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

  Future<void> setPinMode(bool isPin) async {
    final isPinKey = 'isPin_$_databaseName';
    await _secureStorage.write(key: isPinKey, value: isPin.toString());
  }

  Future<String> setMasterCredential(String credential, {required bool isPin}) async {
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
    final masterCredentialKey = 'masterCredential_$_databaseName';
    await _secureStorage.write(key: masterCredentialKey, value: base64Encode(result));
    await setPinMode(isPin);

    String recoveryKey = await _secureStorage.read(key: 'recoveryKey_$_databaseName') ?? '';
    if (recoveryKey.isEmpty) {
      recoveryKey = await _generateRecoveryKey();
      await _secureStorage.write(key: 'recoveryKey_$_databaseName', value: recoveryKey);
    }
    return recoveryKey;
  }

  Future<bool> verifyMasterCredential(String credential) async {
    await _initializeSalt();
    final masterCredentialKey = 'masterCredential_$_databaseName';
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
    final generatedHash = base64Encode(result);
    return generatedHash == storedCredential;
  }

  Future<bool> isMasterCredentialSet() async {
    final masterCredentialKey = 'masterCredential_$_databaseName';
    final storedCredential = await _secureStorage.read(key: masterCredentialKey);
    return storedCredential != null;
  }

  Future<bool> isPinMode() async {
    final isPinKey = 'isPin_$_databaseName';
    final isPin = await _secureStorage.read(key: isPinKey);
    return isPin == null || isPin == 'true';
  }

  Future<String?> getRecoveryKey() async {
    return await _secureStorage.read(key: 'recoveryKey_$_databaseName');
  }

  Future<bool> verifyRecoveryKey(String recoveryKey) async {
    final storedRecoveryKey = await _secureStorage.read(key: 'recoveryKey_$_databaseName');
    return storedRecoveryKey == recoveryKey;
  }

  Future<String?> recoverCredential(String recoveryKey) async {
    final isValid = await verifyRecoveryKey(recoveryKey);
    if (!isValid) return null;
    return null;
  }

  Future<void> resetMasterCredentialWithRecoveryKey(String recoveryKey, String newCredential, {required bool isPin}) async {
    final isValid = await verifyRecoveryKey(recoveryKey);
    if (!isValid) {
      throw Exception('Invalid recovery key');
    }
    await setMasterCredential(newCredential, isPin: isPin);
    final newRecoveryKey = await _generateRecoveryKey();
    await _secureStorage.write(key: 'recoveryKey_$_databaseName', value: newRecoveryKey);
    await resetBruteForceState();
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
        final storedCredential = await _secureStorage.read(key: 'masterCredential_$_databaseName');
        if (storedCredential != null) {
          // Placeholder for additional logic if needed
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: 'biometricEnabled_$_databaseName');
    return enabled == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: 'biometricEnabled_$_databaseName', value: enabled.toString());
  }

  void clearCachedCredential() {}

  Future<(int failedAttempts, DateTime? lockoutEndTime, bool forceResetRequired)> _loadBruteForceState() async {
    final failedAttempts = int.parse(await _secureStorage.read(key: 'failedAttempts_$_databaseName') ?? '0');
    final lockoutTimestamp = await _secureStorage.read(key: 'lockoutEndTime_$_databaseName');
    final lockoutEndTime = lockoutTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(lockoutTimestamp))
        : null;
    final forceResetRequired = (await _secureStorage.read(key: 'forceResetRequired_$_databaseName')) == 'true';
    return (failedAttempts, lockoutEndTime, forceResetRequired);
  }

  Future<void> _saveBruteForceState(int failedAttempts, DateTime? lockoutEndTime, bool forceResetRequired) async {
    await _secureStorage.write(key: 'failedAttempts_$_databaseName', value: failedAttempts.toString());
    await _secureStorage.write(key: 'forceResetRequired_$_databaseName', value: forceResetRequired.toString());
    if (lockoutEndTime != null) {
      await _secureStorage.write(key: 'lockoutEndTime_$_databaseName', value: lockoutEndTime.millisecondsSinceEpoch.toString());
    } else {
      await _secureStorage.delete(key: 'lockoutEndTime_$_databaseName');
    }
  }

  Future<(int failedAttempts, DateTime? lockoutEndTime, bool forceResetRequired)> incrementFailedAttempts() async {
    var (failedAttempts, lockoutEndTime, forceResetRequired) = await _loadBruteForceState();
    failedAttempts++;

    if (failedAttempts == _thirdFailedAttemptThreshold) {
      lockoutEndTime = DateTime.now().add(Duration(seconds: _thirdLockoutDurationSeconds));
    } else if (failedAttempts == _fourthFailedAttemptThreshold) {
      lockoutEndTime = DateTime.now().add(Duration(seconds: _fourthLockoutDurationSeconds));
    } else if (failedAttempts == _fifthFailedAttemptThreshold) {
      lockoutEndTime = DateTime.now().add(Duration(seconds: _fifthLockoutDurationSeconds));
    } else if (failedAttempts >= _forceResetThreshold) {
      forceResetRequired = true;
      lockoutEndTime = null;
    }

    await _saveBruteForceState(failedAttempts, lockoutEndTime, forceResetRequired);
    return (failedAttempts, lockoutEndTime, forceResetRequired);
  }

  Future<void> resetBruteForceState() async {
    await _saveBruteForceState(0, null, false);
  }

  Future<bool> isLockedOut() async {
    final (_, lockoutEndTime, forceResetRequired) = await _loadBruteForceState();
    if (forceResetRequired) return false;
    if (lockoutEndTime == null) return false;
    final now = DateTime.now();
    if (now.isBefore(lockoutEndTime)) {
      return true;
    } else {
      final (failedAttempts, _, forceResetRequired) = await _loadBruteForceState();
      await _saveBruteForceState(failedAttempts, null, forceResetRequired);
      return false;
    }
  }

  Future<bool> isForceResetRequired() async {
    final (_, _, forceResetRequired) = await _loadBruteForceState();
    return forceResetRequired;
  }

  Future<String> getRemainingLockoutTime() async {
    final (_, lockoutEndTime, _) = await _loadBruteForceState();
    if (lockoutEndTime == null) return '0 seconds';
    final remainingSeconds = lockoutEndTime.difference(DateTime.now()).inSeconds;
    if (remainingSeconds <= 0) return '0 seconds';
    final minutes = (remainingSeconds ~/ 60);
    final seconds = remainingSeconds % 60;
    return minutes > 0 ? '$minutes minutes $seconds seconds' : '$seconds seconds';
  }
}
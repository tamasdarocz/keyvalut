/// A service class that handles authentication-related functionality for a specific database.
/// This includes managing master credentials, biometric authentication, recovery keys, and brute force protection.
library;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:argon2/argon2.dart';

class AuthService {
  /// The name of the database this AuthService instance is managing authentication for.
  final String databaseName;

  /// Instance of LocalAuthentication for handling biometric authentication.
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Instance of FlutterSecureStorage for securely storing credentials and related data.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Salt used for hashing the master credential.
  late Uint8List _salt;

  /// Threshold for the third failed attempt, triggering a 1-second lockout.
  static const int _thirdFailedAttemptThreshold = 3;

  /// Threshold for the fourth failed attempt, triggering a 2-minute lockout.
  static const int _fourthFailedAttemptThreshold = 4;

  /// Threshold for the fifth failed attempt, triggering a 5-minute lockout.
  static const int _fifthFailedAttemptThreshold = 5;

  /// Threshold for the sixth failed attempt, triggering a forced reset.
  static const int _forceResetThreshold = 6;

  /// Lockout duration for the third failed attempt (1 second).
  static const int _thirdLockoutDurationSeconds = 1;

  /// Lockout duration for the fourth failed attempt (2 minutes).
  static const int _fourthLockoutDurationSeconds = 120;

  /// Lockout duration for the fifth failed attempt (5 minutes).
  static const int _fifthLockoutDurationSeconds = 300;

  /// Constructor for AuthService, requiring a database name to manage authentication.
  AuthService(this.databaseName);

  /// Initializes the salt for hashing the master credential.
  /// Loads an existing salt from secure storage or generates a new one if none exists.
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

  /// Generates a recovery key for the database.
  /// The key is a 32-character string with dashes every 4 characters (e.g., ABCD-EFGH-...).
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

  /// Sets whether the authentication mode is PIN or Password.
  /// [isPin] True to use PIN mode, false to use Password mode.
  Future<void> setPinMode(bool isPin) async {
    final isPinKey = 'isPin_$databaseName';
    await _secureStorage.write(key: isPinKey, value: isPin.toString());
  }

  /// Sets the master credential (PIN or password) for the database.
  /// [credential] The PIN or password to set.
  /// [isPin] Whether the credential is a PIN (true) or password (false).
  /// Returns the recovery key associated with the database.
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
    final masterCredentialKey = 'masterCredential_$databaseName';
    await _secureStorage.write(key: masterCredentialKey, value: base64Encode(result));
    await setPinMode(isPin); // Update the PIN mode

    // Generate and store recovery key if not already set, then return it
    String recoveryKey = await _secureStorage.read(key: 'recoveryKey_$databaseName') ?? '';
    if (recoveryKey.isEmpty) {
      recoveryKey = await _generateRecoveryKey();
      await _secureStorage.write(key: 'recoveryKey_$databaseName', value: recoveryKey);
    }
    return recoveryKey;
  }

  /// Verifies the provided credential against the stored master credential.
  /// [credential] The PIN or password to verify.
  /// Returns true if the credential matches, false otherwise.
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
    final generatedHash = base64Encode(result);
    return generatedHash == storedCredential;
  }

  /// Checks if a master credential has been set for the database.
  /// Returns true if a credential exists, false otherwise.
  Future<bool> isMasterCredentialSet() async {
    final masterCredentialKey = 'masterCredential_$databaseName';
    final storedCredential = await _secureStorage.read(key: masterCredentialKey);
    return storedCredential != null;
  }

  /// Checks if the database is using PIN mode for authentication.
  /// Returns true if PIN mode is enabled, false if password mode is enabled.
  Future<bool> isPinMode() async {
    final isPinKey = 'isPin_$databaseName';
    final isPin = await _secureStorage.read(key: isPinKey);
    return isPin == null || isPin == 'true';
  }

  /// Retrieves the recovery key for the database.
  /// Returns the recovery key if it exists, null otherwise.
  Future<String?> getRecoveryKey() async {
    return await _secureStorage.read(key: 'recoveryKey_$databaseName');
  }

  /// Verifies the provided recovery key against the stored recovery key.
  /// [recoveryKey] The recovery key to verify.
  /// Returns true if the recovery key matches, false otherwise.
  Future<bool> verifyRecoveryKey(String recoveryKey) async {
    final storedRecoveryKey = await _secureStorage.read(key: 'recoveryKey_$databaseName');
    return storedRecoveryKey == recoveryKey;
  }

  /// Recovers the master credential using the recovery key.
  /// [recoveryKey] The recovery key to verify the recovery operation.
  /// Returns the master credential if the recovery key is valid, null otherwise.
  Future<String?> recoverCredential(String recoveryKey) async {
    final isValid = await verifyRecoveryKey(recoveryKey);
    if (!isValid) return null;

    // Since we store the hashed credential, we can't retrieve the original PIN/password.
    // For recovery purposes, we'll need to store the plaintext credential securely
    // or implement a different mechanism. For now, we'll return null to indicate
    // that direct recovery of the plaintext credential isn't supported.
    // Alternatively, we could store the plaintext credential encrypted with the recovery key,
    // but this would require additional implementation.

    // Placeholder: Indicate that direct recovery isn't implemented.
    return null;
  }

  /// Resets the master credential using a recovery key.
  /// [recoveryKey] The recovery key to verify the reset operation.
  /// [newCredential] The new PIN or password to set.
  /// [isPin] Whether the new credential is a PIN (true) or password (false).
  /// Throws an exception if the recovery key is invalid.
  Future<void> resetMasterCredentialWithRecoveryKey(String recoveryKey, String newCredential, {required bool isPin}) async {
    final isValid = await verifyRecoveryKey(recoveryKey);
    if (!isValid) {
      throw Exception('Invalid recovery key');
    }
    await setMasterCredential(newCredential, isPin: isPin);
    // Generate a new recovery key after reset
    final newRecoveryKey = await _generateRecoveryKey();
    await _secureStorage.write(key: 'recoveryKey_$databaseName', value: newRecoveryKey);
    // Reset brute force state after a successful reset
    await resetBruteForceState();
  }

  /// Checks if biometric authentication is available on the device.
  /// Returns true if biometrics are available, false otherwise.
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Authenticates the user using biometrics.
  /// [reason] The message to display during biometric authentication.
  /// Returns true if authentication is successful, false otherwise.
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
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Checks if biometric authentication is enabled for this database.
  /// Returns true if biometrics are enabled, false otherwise.
  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: 'biometricEnabled_$databaseName');
    return enabled == 'true';
  }

  /// Sets whether biometric authentication is enabled for this database.
  /// [enabled] True to enable biometrics, false to disable.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: 'biometricEnabled_$databaseName', value: enabled.toString());
  }

  /// Clears the cached master credential.
  void clearCachedCredential() {
  }

  /// Loads the brute force protection state for this database from secure storage.
  /// Returns a tuple containing the number of failed attempts, the lockout end time, and whether a forced reset is required.
  Future<(int failedAttempts, DateTime? lockoutEndTime, bool forceResetRequired)> _loadBruteForceState() async {
    final failedAttempts = int.parse(await _secureStorage.read(key: 'failedAttempts_$databaseName') ?? '0');
    final lockoutTimestamp = await _secureStorage.read(key: 'lockoutEndTime_$databaseName');
    final lockoutEndTime = lockoutTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(lockoutTimestamp))
        : null;
    final forceResetRequired = (await _secureStorage.read(key: 'forceResetRequired_$databaseName')) == 'true';
    return (failedAttempts, lockoutEndTime, forceResetRequired);
  }

  /// Saves the brute force protection state for this database to secure storage.
  /// [failedAttempts] The number of failed attempts to save.
  /// [lockoutEndTime] The lockout end time to save, or null if no lockout is active.
  /// [forceResetRequired] Whether a forced reset is required.
  Future<void> _saveBruteForceState(int failedAttempts, DateTime? lockoutEndTime, bool forceResetRequired) async {
    await _secureStorage.write(key: 'failedAttempts_$databaseName', value: failedAttempts.toString());
    await _secureStorage.write(key: 'forceResetRequired_$databaseName', value: forceResetRequired.toString());
    if (lockoutEndTime != null) {
      await _secureStorage.write(key: 'lockoutEndTime_$databaseName', value: lockoutEndTime.millisecondsSinceEpoch.toString());
    } else {
      await _secureStorage.delete(key: 'lockoutEndTime_$databaseName');
    }
  }

  /// Increments the failed attempts counter and applies the appropriate lockout or forced reset.
  /// Returns the updated number of failed attempts, the lockout end time (if any), and whether a forced reset is required.
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
      lockoutEndTime = null; // No lockout time when forced reset is required
    }

    await _saveBruteForceState(failedAttempts, lockoutEndTime, forceResetRequired);
    return (failedAttempts, lockoutEndTime, forceResetRequired);
  }

  /// Resets the brute force protection state (failed attempts, lockout time, and forced reset flag).
  Future<void> resetBruteForceState() async {
    await _saveBruteForceState(0, null, false);
  }

  /// Checks if the user is currently locked out due to too many failed attempts.
  /// Returns true if locked out, false otherwise. Resets the lockout if the period has expired.
  Future<bool> isLockedOut() async {
    final (_, lockoutEndTime, forceResetRequired) = await _loadBruteForceState();
    if (forceResetRequired) return false; // Not considered "locked out" in the time-based sense
    if (lockoutEndTime == null) return false;
    final now = DateTime.now();
    if (now.isBefore(lockoutEndTime)) {
      return true;
    } else {
      // Reset lockout time but preserve failed attempts and force reset state
      final (failedAttempts, _, forceResetRequired) = await _loadBruteForceState();
      await _saveBruteForceState(failedAttempts, null, forceResetRequired);
      return false;
    }
  }

  /// Checks if a forced reset is required due to too many failed attempts.
  /// Returns true if a reset is required, false otherwise.
  Future<bool> isForceResetRequired() async {
    final (_, _, forceResetRequired) = await _loadBruteForceState();
    return forceResetRequired;
  }

  /// Gets the remaining lockout time in a user-friendly format (e.g., "4 minutes 52 seconds").
  /// Returns "0 seconds" if no lockout is active or the lockout has expired.
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
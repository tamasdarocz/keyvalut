import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:argon2/argon2.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _masterCredential;
  late Uint8List _key;
  late Uint8List _salt;

  AuthService() {
    _initializeKeyAndSalt();
  }

  Future<void> _initializeKeyAndSalt() async {
    // Check if salt and key exist in storage
    final storedSalt = await _secureStorage.read(key: 'salt');
    final storedKey = await _secureStorage.read(key: 'key');

    if (storedSalt != null && storedKey != null) {
      // Load from storage if they exist
      _salt = Uint8List.fromList(base64Decode(storedSalt));
      _key = Uint8List.fromList(base64Decode(storedKey));
    } else {
      // Generate new ones if they don't exist
      final random = Random.secure();
      _key = Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
      _salt = Uint8List.fromList(List<int>.generate(16, (_) => random.nextInt(256)));
    }
  }

  Future<void> setMasterCredential(String credential, {required bool isPin}) async {
    await _initializeKeyAndSalt(); // Ensure salt is loaded or initialized
    _masterCredential = credential;
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
    await _secureStorage.write(key: 'masterCredential', value: base64Encode(result));
    await _secureStorage.write(key: 'isPin', value: isPin.toString());
    await _secureStorage.write(key: 'key', value: base64Encode(_key));
    await _secureStorage.write(key: 'salt', value: base64Encode(_salt));
  }

  Future<bool> verifyMasterCredential(String credential) async {
    await _initializeKeyAndSalt(); // Ensure salt is loaded
    final storedCredential = await _secureStorage.read(key: 'masterCredential');
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
    final storedCredential = await _secureStorage.read(key: 'masterCredential');
    return storedCredential != null;
  }

  Future<bool> isPinMode() async {
    final isPin = await _secureStorage.read(key: 'isPin');
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
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: false,
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

  Uint8List get key => _key;
  Uint8List get salt => _salt;
  String? get masterCredential => _masterCredential;
}
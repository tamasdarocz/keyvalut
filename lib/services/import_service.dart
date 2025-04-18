import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:keyvalut/data/credential_model.dart';

class ImportService {
  static final _cipher = AesCbc.with256bits(macAlgorithm: Hmac.sha256());

  static Future<SecretKey> _deriveKeyFromPassword(String password, List<int> salt) async {
    final passwordBytes = utf8.encode(password);
    final argon2id = Argon2id(
      memory: 12288,
      iterations: 3,
      parallelism: 1,
      hashLength: 32,
    );
    final hash = await argon2id.deriveKey(
      secretKey: SecretKey(passwordBytes),
      nonce: salt,
    );
    final keyBytes = await hash.extractBytes();
    debugPrint('Import - Derived key bytes: ${base64Encode(keyBytes)}');
    return SecretKey(keyBytes);
  }

  static Future<String?> _promptForPassword(BuildContext context) async {
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Decryption Password'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter the password used to encrypt the file',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password cannot be empty')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != true) {
      return null;
    }
    return passwordController.text;
  }

  static Future<List<Credential>> importCredentials(BuildContext context) async {
    try {
      debugPrint('Opening file picker with FileType.any as fallback');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select a JSON file from Downloads to import credentials',
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.single.path == null) {
        debugPrint('No file selected by user');
        throw Exception('No file selected');
      }

      debugPrint('File selected: ${result.files.single.path}');
      debugPrint('File name: ${result.files.single.name}');
      debugPrint('File extension: ${result.files.single.extension}');

      final extension = result.files.single.extension?.toLowerCase();
      if (extension != 'json') {
        throw Exception('Please select a .json file');
      }

      final file = File(result.files.single.path!);
      final fileContent = await file.readAsString();
      debugPrint('File content length: ${fileContent.length}');

      String jsonString;

      try {
        // Try to decode as base64 (encrypted file)
        final encryptedBytes = base64Decode(fileContent);
        debugPrint('Encrypted bytes length: ${encryptedBytes.length}');

        // Prompt user for the password
        final password = await _promptForPassword(context);
        if (password == null) {
          throw Exception('Import canceled: Password not provided');
        }

        // Extract salt, nonce, MAC, and ciphertext
        const saltLength = 16;
        const nonceLength = 16;
        const macLength = 32; // HMAC-SHA256 produces a 32-byte MAC
        debugPrint('Expected salt length: $saltLength, nonce length: $nonceLength, MAC length: $macLength');

        if (encryptedBytes.length < saltLength + nonceLength + macLength) {
          throw Exception('Invalid encrypted file format: Data too short (expected at least ${saltLength + nonceLength + macLength} bytes, got ${encryptedBytes.length})');
        }

        final salt = encryptedBytes.sublist(0, saltLength);
        final nonce = encryptedBytes.sublist(saltLength, saltLength + nonceLength);
        final macBytes = encryptedBytes.sublist(saltLength + nonceLength, saltLength + nonceLength + macLength);
        final cipherText = encryptedBytes.sublist(saltLength + nonceLength + macLength);

        debugPrint('Salt length: ${salt.length}, Salt: ${base64Encode(salt)}');
        debugPrint('Nonce length: ${nonce.length}, Nonce: ${base64Encode(nonce)}');
        debugPrint('MAC length: ${macBytes.length}, MAC: ${base64Encode(macBytes)}');
        debugPrint('Ciphertext length: ${cipherText.length}');

        // Derive the encryption key from the password and salt
        final secretKey = await _deriveKeyFromPassword(password, salt);

        // Decrypt the data
        final secretBox = SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        );

        final decryptedBytes = await _cipher.decrypt(
          secretBox,
          secretKey: secretKey,
        );

        jsonString = utf8.decode(decryptedBytes);
        debugPrint('Decrypted JSON length: ${jsonString.length}');
      } catch (e) {
        if (e is FormatException && e.message.contains('Invalid base64')) {
          debugPrint('File is not encrypted. Treating as plain JSON.');
          jsonString = fileContent;
        } else if (e is SecretBoxAuthenticationError) {
          debugPrint('Decryption failed: Incorrect password or corrupted data');
          throw Exception('Failed to decrypt file: Incorrect password or corrupted data');
        } else {
          debugPrint('Decryption error: $e');
          throw Exception('Error decrypting file: $e');
        }
      }

      final jsonData = jsonDecode(jsonString);
      List<dynamic> credentialsJson;

      // Handle both new and old formats
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('credentials')) {
        // New versioned format
        credentialsJson = jsonData['credentials'] as List<dynamic>;
        debugPrint('Detected new versioned format (v${jsonData['version'] ?? 'unknown'})');
      } else if (jsonData is List) {
        // Old format (direct list of credentials)
        credentialsJson = jsonData;
        debugPrint('Detected old format (list of credentials)');
      } else {
        throw Exception('Invalid file format: Expected a JSON list or object with credentials');
      }

      final credentials = credentialsJson.map((json) {
        if (json is! Map<String, dynamic>) {
          throw Exception('Invalid credential format in file');
        }

        // Special handling for boolean/int conversions to ensure compatibility
        if (json.containsKey('is_archived') && json['is_archived'] is int) {
          json['is_archived'] = json['is_archived'] == 1;
        }

        if (json.containsKey('is_deleted') && json['is_deleted'] is int) {
          json['is_deleted'] = json['is_deleted'] == 1;
        }

        return Credential.fromJson(json);
      }).toList();

      debugPrint('Credentials imported: ${credentials.length} items');
      return credentials;
    } catch (e) {
      debugPrint('Import error: $e');
      if (e.toString().contains('jsonDecode')) {
        throw Exception('Error parsing file: Invalid JSON format');
      }
      throw Exception('Error importing credentials: $e');
    }
  }
}
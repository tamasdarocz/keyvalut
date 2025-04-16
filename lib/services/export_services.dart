import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:keyvalut/data/credential_model.dart';

class ExportService {
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
    debugPrint('Export - Derived key bytes: ${base64Encode(keyBytes)}');
    return SecretKey(keyBytes);
  }

  static Future<void> exportCredentials(
      BuildContext context,
      List<Credential> credentials,
      String fileName,
      ) async {
    try {
      // Prompt user for a password
      final passwordController = TextEditingController();
      String? password;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Encryption Password'),
          content: TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter a password to encrypt the file',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export canceled')),
        );
        return;
      }

      password = passwordController.text;

      // Convert credentials to JSON string
      final jsonList = credentials.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final jsonBytes = utf8.encode(jsonString);
      debugPrint('JSON data to encrypt: $jsonString');
      debugPrint('JSON bytes length: ${jsonBytes.length}');

      // Generate a random salt for key derivation (16 bytes)
      final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      debugPrint('Salt length: ${salt.length}, Salt: ${base64Encode(salt)}');

      final secretKey = await _deriveKeyFromPassword(password!, salt);

      // Generate a random IV (nonce) for AES-CBC (16 bytes)
      final nonce = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      debugPrint('Nonce length: ${nonce.length}, Nonce: ${base64Encode(nonce)}');

      // Encrypt the JSON data
      final secretBox = await _cipher.encrypt(
        jsonBytes,
        secretKey: secretKey,
        nonce: nonce,
      );

      debugPrint('Ciphertext length: ${secretBox.cipherText.length}');
      debugPrint('Ciphertext (base64): ${base64Encode(secretBox.cipherText)}');
      debugPrint('MAC length: ${secretBox.mac.bytes.length}');

      // Combine salt, nonce, MAC, and ciphertext
      final encryptedData = base64Encode(salt + nonce + secretBox.mac.bytes + secretBox.cipherText);
      debugPrint('Combined data length: ${salt.length + nonce.length + secretBox.mac.bytes.length + secretBox.cipherText.length}');
      debugPrint('Base64 encoded data: $encryptedData');

      // Let the user choose where to save the file
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Exported Credentials',
        fileName: '$fileName.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(encryptedData),
      );

      if (outputPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials exported successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export canceled')),
        );
      }
    } catch (e) {
      await FilePicker.platform.clearTemporaryFiles();
      debugPrint('Export error: $e');
      throw Exception('Error exporting credentials: $e');
    }
  }
}
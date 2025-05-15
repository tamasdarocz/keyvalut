import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/core/model/database_model.dart';
import 'package:keyvalut/core/services/database_helper.dart';
import 'package:keyvalut/features/ui/screens/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<void> importData(BuildContext context) async {
    try {
      // Set the file picker flag before opening the file picker
      HomePage.isFilePickerActive = true;

      debugPrint('Opening file picker with FileType.any as fallback');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select a JSON file to import core',
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

        // Decrypt the core
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
          debugPrint('Decryption failed: Incorrect password or corrupted core');
          throw Exception('Failed to decrypt file: Incorrect password or corrupted core');
        } else {
          debugPrint('Decryption error: $e');
          throw Exception('Error decrypting file: $e');
        }
      }

      final jsonData = jsonDecode(jsonString);
      if (jsonData is! Map<String, dynamic>) {
        throw Exception('Invalid file format: Expected a JSON object');
      }

      // Fetch the current database name from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final databaseName = prefs.getString('currentDatabase');
      if (databaseName == null) {
        throw Exception('No database selected. Please log in first.');
      }
      final dbHelper = DatabaseHelper(databaseName);

      // Import logins
      final List<Logins> logins = [];
      if (jsonData.containsKey('loginss')) {
        final loginsJson = jsonData['logins'] as List<dynamic>;
        logins.addAll(loginsJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw Exception('Invalid login format in file');
          }
          return Logins.fromJson(json);
        }).toList());
      }

      // Import credit cards
      final List<CreditCard> creditCards = [];
      if (jsonData.containsKey('creditCards')) {
        final creditCardsJson = jsonData['creditCards'] as List<dynamic>;
        creditCards.addAll(creditCardsJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw Exception('Invalid credit card format in file');
          }
          return CreditCard.fromJson(json);
        }).toList());
      }

      // Import notes
      final List<Note> notes = [];
      if (jsonData.containsKey('notes')) {
        final notesJson = jsonData['notes'] as List<dynamic>;
        notes.addAll(notesJson.map((json) {
          if (json is! Map<String, dynamic>) {
            throw Exception('Invalid note format in file');
          }
          return Note.fromJson(json);
        }).toList());
      }

      // Show confirmation dialog
      final totalItems = logins.length + creditCards.length + notes.length;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: Text('The file contains $totalItems items (${logins.length} logins, ${creditCards.length} credit cards, ${notes.length} notes). Do you want to import them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        Fluttertoast.showToast(msg: 'Import canceled');
        return;
      }

      // Insert all items into the database
      for (var login in logins) {
        await dbHelper.insertLogins(login);
      }
      for (var creditCard in creditCards) {
        await dbHelper.insertCreditCard(creditCard);
      }
      for (var note in notes) {
        await dbHelper.insertNote(note);
      }

      Fluttertoast.showToast(msg: 'Successfully imported $totalItems items');
    } catch (e) {
      debugPrint('Import error: $e');
      if (e.toString().contains('jsonDecode')) {
        throw Exception('Error parsing file: Invalid JSON format');
      }
      throw Exception('Error importing core: $e');
    } finally {
      // Clear the file picker flag after the operation
      HomePage.isFilePickerActive = false;
    }
  }
}
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/data/credential_model.dart'; // Adjust import based on your project structure
import 'package:keyvalut/data/database_helper.dart'; // Adjust import based on your project structure

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
    return SecretKey(await hash.extractBytes());
  }

  static Future<void> exportData(BuildContext context, String fileName) async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // Fetch all data, including archived and deleted items
      final allCredentials = await dbHelper.getCredentials(includeArchived: true, includeDeleted: true);
      final allCreditCardsMaps = await dbHelper.queryAllCreditCards(includeArchived: true, includeDeleted: true);
      final allCreditCards = allCreditCardsMaps.map((map) => CreditCard.fromMap(map)).toList();
      final allNotes = await dbHelper.getNotes(includeArchived: true, includeDeleted: true); // Assumes getNotes is implemented

      // Prompt user for encryption password
      final passwordController = TextEditingController();
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
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (passwordController.text.isEmpty) {
                  Fluttertoast.showToast(msg: 'Password cannot be empty');
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
        Fluttertoast.showToast(msg: 'Export canceled');
        return;
      }

      final password = passwordController.text;

      // Structure JSON data without id fields
      final jsonData = {
        'exportDate': DateTime.now().toIso8601String(),
        'credentials': allCredentials.map((c) => c.toExportJson()).toList(),
        'creditCards': allCreditCards.map((c) => c.toExportJson()).toList(),
        'notes': allNotes.map((n) => n.toExportJson()).toList(),
      };

      final jsonString = jsonEncode(jsonData);
      final jsonBytes = utf8.encode(jsonString);

      // Encrypt the data
      final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      final secretKey = await _deriveKeyFromPassword(password, salt);
      final nonce = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      final secretBox = await _cipher.encrypt(jsonBytes, secretKey: secretKey, nonce: nonce);

      // Combine and encode encrypted data
      final encryptedData = base64Encode(salt + nonce + secretBox.mac.bytes + secretBox.cipherText);

      // Save the file
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Exported Data',
        fileName: '$fileName.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(encryptedData),
      );

      if (outputPath != null) {
        Fluttertoast.showToast(msg: 'Data exported successfully');
      } else {
        Fluttertoast.showToast(msg: 'Export canceled');
      }
    } catch (e) {
      debugPrint('Export error: $e');
      Fluttertoast.showToast(msg: 'Error exporting data: $e');
    }
  }
}
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cryptography/cryptography.dart'; // For AES encryption
import 'dart:math'; // For random key generation
import 'package:shared_preferences/shared_preferences.dart'; // For storing the symmetric key

class RecoveryKeyDialog extends StatelessWidget {
  final String recoveryKey;

  const RecoveryKeyDialog({
    super.key,
    required this.recoveryKey,
  });

  // Encryption setup
  static final _cipher = AesCbc.with256bits(macAlgorithm: Hmac.sha256());

  // Generate a random symmetric key and store it in SharedPreferences
  Future<SecretKey> _generateAndStoreSymmetricKey() async {
    final keyBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256)); // 256-bit key
    final secretKey = SecretKey(keyBytes);

    // Store the key in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final keyBase64 = base64Encode(keyBytes);
    await prefs.setString('recovery_symmetric_key', keyBase64);

    return secretKey;
  }

  // Retrieve the symmetric key from SharedPreferences
  Future<SecretKey> _getSymmetricKey() async {
    final prefs = await SharedPreferences.getInstance();
    final keyBase64 = prefs.getString('recovery_symmetric_key');
    if (keyBase64 == null) {
      throw Exception('Symmetric key not found. Cannot export recovery key.');
    }
    final keyBytes = base64Decode(keyBase64);
    return SecretKey(keyBytes);
  }

  Future<void> _exportRecoveryKey(BuildContext context) async {
    try {
      // Generate or retrieve the symmetric key
      SecretKey secretKey;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('recovery_symmetric_key') == null) {
        secretKey = await _generateAndStoreSymmetricKey();
      } else {
        secretKey = await _getSymmetricKey();
      }

      // Prepare the recovery key content with metadata
      final content = {
        'version': '1.0', // Add metadata for future compatibility
        'type': 'recovery_key',
        'data': recoveryKey,
      };
      final contentJson = jsonEncode(content);
      final bytes = utf8.encode(contentJson);

      // Encrypt the recovery key
      final nonce = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      final secretBox = await _cipher.encrypt(bytes, secretKey: secretKey, nonce: nonce);

      // Combine nonce, MAC, and ciphertext into a single string
      final encryptedData = base64Encode([...nonce, ...secretBox.mac.bytes, ...secretBox.cipherText]);

      // Use FilePicker to save the file on all platforms
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Recovery Key File',
        fileName: 'recovery_key.keyfile',
        type: FileType.custom,
        allowedExtensions: ['keyfile'],
        bytes: utf8.encode(encryptedData),
      );

      if (outputPath != null) {
        Fluttertoast.showToast(
          msg: 'Recovery key file exported successfully. Store it securely!',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Export cancelled',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error exporting recovery key: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: recoveryKey));
    if (context.mounted) {
      Fluttertoast.showToast(
        msg: 'Recovery key copied to clipboard',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _shareRecoveryKey() {
    SharePlus.instance.share(
      ShareParams(
        text: 'KeyVault Recovery Key: $recoveryKey',
        subject: 'KeyVault Recovery Key',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'Your Recovery Key',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is your recovery key. It is crucial for resetting your master credential if you forget it. Export it as a key file and store it securely!',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SelectableText(
              recoveryKey,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _exportRecoveryKey(context),
          child: Text(
            'Export as Key File',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () => _copyToClipboard(context),
          child: Text(
            'Copy to Clipboard',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: _shareRecoveryKey,
          child: Text(
            'Share',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
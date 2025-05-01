import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io' show File;
import 'package:cryptography/cryptography.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// A dialog that displays the recovery key and allows the user to download, copy, or share it.

class RecoveryKeyDialog extends StatelessWidget {
  final String recoveryKey;

  final String databaseName;

  Future<void> _getdatabaseName() async{
    final prefs = await SharedPreferences.getInstance();
    final databaseName = prefs.getString('currentDatabase');

  }


  /// Creates a [RecoveryKeyDialog] widget.

  const RecoveryKeyDialog({
    super.key,
    required this.recoveryKey,
    required this.databaseName,
  });

  // Encryption setup using AES-CBC with 256-bit keys and HMAC-SHA256 for integrity
  static final _cipher = AesCbc.with256bits(macAlgorithm: Hmac.sha256());

  /// Generates a random 256-bit symmetric key and stores it in SharedPreferences.
  ///
  /// Returns the generated [SecretKey].
  Future<SecretKey> _generateAndStoreSymmetricKey() async {
    final keyBytes = List<int>.generate(
        32, (_) => Random.secure().nextInt(256)); // 256-bit key
    final secretKey = SecretKey(keyBytes);

    // Store the key in SharedPreferences as a base64-encoded string
    final prefs = await SharedPreferences.getInstance();
    final keyBase64 = base64Encode(keyBytes);
    await prefs.setString('recovery_symmetric_key', keyBase64);

    return secretKey;
  }

  /// Retrieves the symmetric key from SharedPreferences.
  ///
  /// Returns the stored [SecretKey]. Throws an exception if the key is not found.
  Future<SecretKey> _getSymmetricKey() async {
    final prefs = await SharedPreferences.getInstance();
    final keyBase64 = prefs.getString('recovery_symmetric_key');
    if (keyBase64 == null) {
      throw Exception('Symmetric key not found. Cannot export recovery key.');
    }
    final keyBytes = base64Decode(keyBase64);

    return SecretKey(keyBytes);
  }

  /// Downloads the recovery key as a `.keyfile` by allowing the user to choose the save location.
  ///
  /// The recovery key is encrypted using AES-CBC with HMAC-SHA256, base64-encoded, and saved to
  /// a user-selected location as a `.keyfile`. If the user isn't prompted to pick a location,
  /// falls back to saving in the Downloads directory.
  ///
  /// - [context]: The build context for showing toast messages.
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
        'version': '1.0',
        'type': 'recovery_key',
        'data': recoveryKey,
      };
      final contentJson = jsonEncode(content);
      final bytes = utf8.encode(contentJson);

      // Encrypt the recovery key
      final nonce = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      final secretBox =
          await _cipher.encrypt(bytes, secretKey: secretKey, nonce: nonce);

      // Combine nonce, MAC, and ciphertext into a single base64-encoded string
      final encryptedData = base64Encode(
          [...nonce, ...secretBox.mac.bytes, ...secretBox.cipherText]);

      // Prepare file details
      final baseFileName = 'keyvalut_${databaseName}'; // e.g., "KeyVault_MainDB"
      const extension = 'keyfile';
      final fileBytes = Uint8List.fromList(utf8.encode(encryptedData));

      // Try to save with user-selected location using file_saver
      String? savedPath;
      try {
        savedPath = await FileSaver.instance.saveAs(
          name: baseFileName,
          bytes: fileBytes,
          mimeType: MimeType.other,
          ext: extension,
        );
      } catch (e) {
        // Handle exception silently; fallback will handle it
      }

      // If saveAs didn't work or user wasn't prompted, fall back to Downloads directory
      if (savedPath == null && !kIsWeb) {
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          throw Exception('Could not access Downloads directory.');
        }

        final filePath = '${directory.path}/$baseFileName.$extension';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        Fluttertoast.showToast(
          msg:
              'Recovery key file saved to Downloads folder. Store it securely!',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else if (savedPath != null) {
        Fluttertoast.showToast(
          msg: 'Recovery key file downloaded successfully. Store it securely!',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        // On web, saveAs should trigger a download; if savedPath is null, it might still have worked
        if (kIsWeb) {
          Fluttertoast.showToast(
            msg: 'Recovery key file downloaded. Check your browser downloads.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          throw Exception('Failed to save file: No path returned.');
        }
      }
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('user cancelled') ||
          errorMessage.contains('canceled')) {
        Fluttertoast.showToast(
          msg: 'Download cancelled',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Error downloading keyfile: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  /// Shows a warning dialog before copying the recovery key to the clipboard.
  ///
  /// - [context]: The build context for showing dialogs and toast messages.
  Future<void> _copyToClipboard(BuildContext context) async {
    final theme = Theme.of(context);
    final shouldCopy = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Warning: Insecure Action',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Copying the recovery key to the clipboard in plain text is insecure. It could be accessed by other apps or users. Are you sure you want to proceed?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Proceed',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldCopy == true) {
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
  }

  /// Shows a warning dialog before sharing the recovery key.
  ///
  /// - [context]: The build context for showing dialogs.
  Future<void> _shareRecoveryKey(BuildContext context) async {
    final theme = Theme.of(context);
    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'Warning: Insecure Action',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Sharing the recovery key in plain text is highly insecure. It could be intercepted or accessed by unauthorized parties. Are you sure you want to proceed?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Proceed',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (shouldShare == true) {
      SharePlus.instance.share(
        ShareParams(
          text: 'KeyVault Recovery Key: $recoveryKey',
          subject: 'KeyVault Recovery Key',
        ),
      );
    }
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
                  'This is your recovery key. It is crucial for resetting your master credential if you forget it. Download it as a key file and store it securely!',
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
            'Download Keyfile',
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
          onPressed: () => _shareRecoveryKey(context),
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

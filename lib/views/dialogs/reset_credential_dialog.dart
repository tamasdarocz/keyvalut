import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:io' show File;

// Enum to represent the PIN/Password mode
enum PinPasswordMode {
  pin,
  password,
}

class ResetCredentialDialog extends StatefulWidget {
  final dynamic authService; // Authentication service for resetting credentials
  final bool isPinMode; // Determines if resetting PIN (true) or Password (false)
  final VoidCallback onResetSuccess; // Callback for successful reset

  const ResetCredentialDialog({
    super.key,
    required this.authService,
    required this.isPinMode,
    required this.onResetSuccess,
  });

  @override
  ResetCredentialDialogState createState() => ResetCredentialDialogState();
}

class ResetCredentialDialogState extends State<ResetCredentialDialog> {
  late PinPasswordMode _selectedMode; // Track the selected mode using enum
  final TextEditingController _recoveryKeyController = TextEditingController();
  final TextEditingController _newCredentialController = TextEditingController();
  final TextEditingController _confirmCredentialController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the selected mode based on the passed isPinMode
    _selectedMode = widget.isPinMode ? PinPasswordMode.pin : PinPasswordMode.password;
  }

  // Same cipher configuration as RecoveryKeyDialog
  static final _cipher = AesCbc.with256bits(macAlgorithm: Hmac.sha256());

  // Retrieve the symmetric key from SharedPreferences
  Future<SecretKey> _getSymmetricKey() async {
    final prefs = await SharedPreferences.getInstance();
    final keyBase64 = prefs.getString('recovery_symmetric_key');
    if (keyBase64 == null) {
      throw Exception('Symmetric key not found. Cannot decrypt recovery key.');
    }
    final keyBytes = base64Decode(keyBase64);

    if (kDebugMode) {
      print('Retrieved symmetric key in ResetCredentialDialog: $keyBase64');
    }

    return SecretKey(keyBytes);
  }

  Future<void> _selectAndLoadRecoveryKey() async {
    try {
      // Pick the recovery key file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow all file types to avoid PlatformException
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        if (!filePath.toLowerCase().endsWith('.keyfile')) {
          Fluttertoast.showToast(
            msg: 'Please select a .keyfile',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.redAccent,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }

        // Read the file content
        final file = File(filePath);
        final encryptedData = await file.readAsString();

        if (kDebugMode) {
          print('Read encrypted data from file: $encryptedData');
        }

        // Decode the base64 string
        final decodedBytes = base64Decode(encryptedData);

        // Parse nonce, MAC, and ciphertext
        const nonceLength = 16; // 16 bytes for AesCbc nonce
        const macLength = 32; // 32 bytes for Hmac.sha256()
        if (decodedBytes.length < nonceLength + macLength) {
          throw Exception('Invalid recovery key file: Data too short');
        }

        final nonce = decodedBytes.sublist(0, nonceLength);
        final macBytes = decodedBytes.sublist(nonceLength, nonceLength + macLength);
        final ciphertext = decodedBytes.sublist(nonceLength + macLength);

        if (kDebugMode) {
          print('Parsed nonce: ${base64Encode(nonce)}');
          print('Parsed MAC: ${base64Encode(macBytes)}');
          print('Parsed ciphertext: ${base64Encode(ciphertext)}');
        }

        // Get the symmetric key
        final secretKey = await _getSymmetricKey();

        // Decrypt the data
        final secretBox = SecretBox(
          ciphertext,
          nonce: nonce,
          mac: Mac(macBytes),
        );

        final decryptedBytes = await _cipher.decrypt(secretBox, secretKey: secretKey);
        final decryptedJson = utf8.decode(decryptedBytes);
        final decryptedContent = jsonDecode(decryptedJson) as Map<String, dynamic>;

        if (kDebugMode) {
          print('Decrypted JSON: $decryptedJson');
        }

        // Verify the content structure
        if (decryptedContent['type'] != 'recovery_key' || decryptedContent['data'] == null) {
          throw Exception('Invalid recovery key file: Missing or incorrect data');
        }

        // Update the UI after async work is complete
        setState(() {
          _recoveryKeyController.text = decryptedContent['data'];
        });

        Fluttertoast.showToast(
          msg: 'Recovery key loaded successfully',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'File selection cancelled',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading recovery key: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _resetCredential() async {
    try {
      final recoveryKey = _recoveryKeyController.text.trim();
      final newCredential = _newCredentialController.text.trim();
      final confirmCredential = _confirmCredentialController.text.trim();

      // Validate inputs
      if (recoveryKey.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Please enter or load a recovery key',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      if (newCredential.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Please enter a new ${_selectedMode == PinPasswordMode.pin ? 'PIN' : 'password'}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      if (newCredential != confirmCredential) {
        Fluttertoast.showToast(
          msg: 'Credentials do not match',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      // Perform the reset using authService
      await widget.authService.resetMasterCredentialWithRecoveryKey(
        recoveryKey,
        newCredential,
        isPin: _selectedMode == PinPasswordMode.pin,
      );

      // Call the success callback
      widget.onResetSuccess();

      // Show success message
      Fluttertoast.showToast(
        msg: 'Credential reset successfully',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Close the dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error resetting credential: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'Reset Master Credential',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView( // Wrap content in SingleChildScrollView to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SegmentedButton for PIN/Password toggle
            SegmentedButton<PinPasswordMode>(
              segments: const [
                ButtonSegment<PinPasswordMode>(
                  value: PinPasswordMode.pin,
                  label: Text('PIN'),
                ),
                ButtonSegment<PinPasswordMode>(
                  value: PinPasswordMode.password,
                  label: Text('Password'),
                ),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (Set<PinPasswordMode> newSelection) {
                setState(() {
                  _selectedMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recoveryKeyController,
              decoration: InputDecoration(
                labelText: 'Recovery Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.file_upload),
                  onPressed: _selectAndLoadRecoveryKey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newCredentialController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New ${_selectedMode == PinPasswordMode.pin ? 'PIN' : 'Password'}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCredentialController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New ${_selectedMode == PinPasswordMode.pin ? 'PIN' : 'Password'}',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        TextButton(
          onPressed: _resetCredential,
          child: Text(
            'Reset',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
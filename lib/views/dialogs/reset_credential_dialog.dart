import 'package:flutter/material.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/services/password_strength.dart';
import 'package:keyvalut/services/utils.dart';
import 'package:file_picker/file_picker.dart'; // For file selection
import 'dart:convert'; // For base64 decoding and JSON parsing
import 'package:cryptography/cryptography.dart'; // For AES decryption
import 'package:shared_preferences/shared_preferences.dart'; // For retrieving the symmetric key
import 'dart:io' show File, Platform; // For platform-specific file handling

class ResetCredentialDialog extends StatefulWidget {
  final AuthService authService;
  final bool isPinMode; // Current credential mode of the database
  final VoidCallback? onResetSuccess; // Callback for post-reset actions

  const ResetCredentialDialog({
    super.key,
    required this.authService,
    required this.isPinMode,
    this.onResetSuccess,
  });

  @override
  State<ResetCredentialDialog> createState() => _ResetCredentialDialogState();
}

class _ResetCredentialDialogState extends State<ResetCredentialDialog> {
  final TextEditingController _recoveryKeyController = TextEditingController();
  final TextEditingController _newCredentialController = TextEditingController();
  final TextEditingController _confirmNewCredentialController = TextEditingController();
  String? _selectedFilePath;
  String? _decryptedRecoveryKey;
  bool _obscureNewCredential = true;
  bool _obscureConfirmNewCredential = true;
  AuthMode _resetAuthMode = AuthMode.pin;

  // Encryption setup
  static final _cipher = AesCbc.with256bits(macAlgorithm: Hmac.sha256());

  @override
  void initState() {
    super.initState();
    _resetAuthMode = widget.isPinMode ? AuthMode.pin : AuthMode.password;
  }

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    _newCredentialController.dispose();
    _confirmNewCredentialController.dispose();
    super.dispose();
  }

  // Retrieve the symmetric key from SharedPreferences
  Future<SecretKey> _getSymmetricKey() async {
    final prefs = await SharedPreferences.getInstance();
    final keyBase64 = prefs.getString('recovery_symmetric_key');
    if (keyBase64 == null) {
      throw Exception('Symmetric key not found. Cannot decrypt recovery key.');
    }
    final keyBytes = base64Decode(keyBase64);
    return SecretKey(keyBytes);
  }

  // Select and decrypt the key file
  Future<void> _selectAndDecryptKeyFile() async {
    try {
      // Use FilePicker to select the .keyfile
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Recovery Key File',
        type: FileType.custom,
        allowedExtensions: ['keyfile'], // Ensure no leading dot
      ).catchError((e) {
        // Fallback: If the custom extension fails, try with any file type
        showToast('Custom extension failed, trying with all files...');
        return FilePicker.platform.pickFiles(
          dialogTitle: 'Select Recovery Key File',
          type: FileType.any,
        );
      });

      if (result == null || result.files.isEmpty) {
        showToast('No file selected');
        return;
      }

      final file = result.files.first;
      String encryptedData;

      // Handle file reading based on platform
      if (Platform.isAndroid || Platform.isIOS) {
        // Native platforms: Read from file path
        if (file.path == null) {
          showToast('Error: File path not available');
          return;
        }
        encryptedData = await File(file.path!).readAsString();
      } else {
        // Web: Read from bytes
        if (file.bytes == null) {
          showToast('Error: File bytes not available');
          return;
        }
        encryptedData = utf8.decode(file.bytes!);
      }

      // Validate file extension manually if FileType.any was used
      if (file.extension != 'keyfile') {
        showToast('Please select a .keyfile');
        return;
      }

      // Decode the base64 data
      final decodedData = base64Decode(encryptedData);

      // Extract nonce, MAC, and ciphertext
      if (decodedData.length < 16 + 16 + 16) {
        showToast('Invalid key file format');
        return;
      }
      final nonce = decodedData.sublist(0, 16);
      final macBytes = decodedData.sublist(16, 16 + 16);
      final ciphertext = decodedData.sublist(16 + 16);

      // Retrieve the symmetric key
      final secretKey = await _getSymmetricKey();

      // Decrypt the data
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(macBytes),
      );
      final decryptedBytes = await _cipher.decrypt(secretBox, secretKey: secretKey);
      final decryptedJson = utf8.decode(decryptedBytes);
      final decryptedContent = jsonDecode(decryptedJson);

      // Validate the decrypted content
      if (decryptedContent['type'] != 'recovery_key' || decryptedContent['data'] == null) {
        showToast('Invalid recovery key file');
        return;
      }

      setState(() {
        _selectedFilePath = file.name;
        _decryptedRecoveryKey = decryptedContent['data'];
        _recoveryKeyController.text = _decryptedRecoveryKey!; // Populate the TextField
      });

      showToast('Recovery key file loaded successfully');
    } catch (e) {
      showToast('Error loading recovery key: $e');
      setState(() {
        _selectedFilePath = null;
        _decryptedRecoveryKey = null;
      });
    }
  }

  Future<void> _resetCredential() async {
    final manualRecoveryKey = _recoveryKeyController.text.trim();
    final recoveryKey = _decryptedRecoveryKey ?? manualRecoveryKey;

    if (recoveryKey.isEmpty) {
      showToast('Please enter a recovery key or select a key file');
      return;
    }

    final newCredential = _newCredentialController.text;
    final confirmNewCredential = _confirmNewCredentialController.text;

    if (newCredential.isEmpty) {
      showToast('New ${_resetAuthMode == AuthMode.pin ? 'PIN' : 'password'} is required');
      return;
    }
    if (_resetAuthMode == AuthMode.pin) {
      if (newCredential.length < 6) {
        showToast('PIN must be at least 6 digits');
        return;
      }
      if (!RegExp(r'^\d+$').hasMatch(newCredential)) {
        showToast('PIN must be numeric');
        return;
      }
    } else {
      if (newCredential.length < 8) {
        showToast('Password must be at least 8 characters');
        return;
      }
    }
    if (newCredential != confirmNewCredential) {
      showToast('Credentials do not match');
      return;
    }

    try {
      await widget.authService.resetMasterCredentialWithRecoveryKey(
        recoveryKey,
        newCredential,
        isPin: _resetAuthMode == AuthMode.pin,
      );
      if (mounted) {
        showToast('Master credential reset successfully');
        widget.onResetSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showToast(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Master Credential'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: SegmentedButton<AuthMode>(
                segments: const [
                  ButtonSegment<AuthMode>(
                    value: AuthMode.pin,
                    label: Text('PIN'),
                    icon: Icon(Icons.lock),
                  ),
                  ButtonSegment<AuthMode>(
                    value: AuthMode.password,
                    label: Text('Password'),
                    icon: Icon(Icons.lock),
                  ),
                ],
                selected: {_resetAuthMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _resetAuthMode = newSelection.first;
                    _newCredentialController.clear();
                    _confirmNewCredentialController.clear();
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                  selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recoveryKeyController,
              decoration: const InputDecoration(
                labelText: 'Recovery Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedFilePath ?? 'No file selected',
                    style: TextStyle(
                      color: _selectedFilePath == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectAndDecryptKeyFile,
                  child: const Text('Select Key File'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newCredentialController,
              obscureText: _obscureNewCredential,
              keyboardType: _resetAuthMode == AuthMode.pin ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: _resetAuthMode == AuthMode.pin ? 'New PIN' : 'New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewCredential ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureNewCredential = !_obscureNewCredential);
                  },
                ),
              ),
            ),
            if (_resetAuthMode == AuthMode.password) ...[
              const SizedBox(height: 8),
              PasswordStrengthIndicator(password: _newCredentialController.text),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _confirmNewCredentialController,
              obscureText: _obscureConfirmNewCredential,
              keyboardType: _resetAuthMode == AuthMode.pin ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                labelText: _resetAuthMode == AuthMode.pin ? 'Confirm New PIN' : 'Confirm New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmNewCredential ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmNewCredential = !_obscureConfirmNewCredential);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _resetCredential,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
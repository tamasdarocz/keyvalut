import 'package:flutter/material.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/services/password_strength.dart';
import 'package:keyvalut/services/utils.dart';

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
  bool _obscureNewCredential = true;
  bool _obscureConfirmNewCredential = true;
  AuthMode _resetAuthMode = AuthMode.pin;

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

  Future<void> _resetCredential() async {
    final recoveryKey = _recoveryKeyController.text.trim();
    final newCredential = _newCredentialController.text;
    final confirmNewCredential = _confirmNewCredentialController.text;

    if (recoveryKey.isEmpty) {
      showToast('Recovery key is required');
      return;
    }
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
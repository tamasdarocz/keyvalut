import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../services/password_strength.dart';

class ChangeLoginScreen extends StatefulWidget {
  const ChangeLoginScreen({super.key});

  @override
  State<ChangeLoginScreen> createState() => _ChangeLoginScreenState();
}

enum CredentialType { pin, password }

class _ChangeLoginScreenState extends State<ChangeLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCredentialController = TextEditingController();
  final _newCredentialController = TextEditingController();
  final _confirmNewCredentialController = TextEditingController();
  CredentialType? _selectedCredentialType; // Initially null until mode is determined
  bool _isCurrentPinMode = true; // Default to true, will be updated
  bool _obscureCurrentCredential = true;
  bool _obscureNewCredential = true;
  bool _obscureConfirmNewCredential = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCredentialMode();
  }

  Future<void> _initializeCredentialMode() async {
    final authService = context.read<AuthService>();
    final isPin = await authService.isPinMode();
    // Debug log to verify the mode
    print('Database mode (isPin): $isPin');
    setState(() {
      _isCurrentPinMode = isPin;
      _selectedCredentialType = isPin ? CredentialType.pin : CredentialType.password;
    });
  }

  Future<void> _handleChangeCredential() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    setState(() => _isLoading = true);

    try {
      final currentCredential = _currentCredentialController.text;
      final newCredential = _newCredentialController.text;

      final isCurrentValid = await authService.verifyMasterCredential(currentCredential);
      if (!isCurrentValid) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: _isCurrentPinMode ? 'Current PIN is incorrect' : 'Current password is incorrect',
          gravity: ToastGravity.CENTER,
        );
        return;
      }

      await authService.setMasterCredential(
        newCredential,
        isPin: _selectedCredentialType == CredentialType.pin,
      );
      authService.clearCachedCredential(); // Clear cached credential after change

      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: _selectedCredentialType == CredentialType.pin ? 'PIN changed successfully' : 'Password changed successfully',
          gravity: ToastGravity.CENTER,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Error changing credential: $e',
          gravity: ToastGravity.CENTER,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Credential'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: _selectedCredentialType == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<CredentialType>(
                segments: const [
                  ButtonSegment<CredentialType>(
                    value: CredentialType.pin,
                    label: Text('PIN'),
                  ),
                  ButtonSegment<CredentialType>(
                    value: CredentialType.password,
                    label: Text('Password'),
                  ),
                ],
                selected: {_selectedCredentialType!},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedCredentialType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _currentCredentialController,
                obscureText: _obscureCurrentCredential,
                keyboardType: _isCurrentPinMode ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  labelText: _isCurrentPinMode ? 'Current PIN' : 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentCredential ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureCurrentCredential = !_obscureCurrentCredential);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (_isCurrentPinMode) {
                    if (value!.length < 6) return 'PIN must be at least 6 digits';
                    if (!RegExp(r'^\d+$').hasMatch(value)) return 'PIN must be numeric';
                  } else {
                    if (value!.length < 8) return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newCredentialController,
                obscureText: _obscureNewCredential,
                keyboardType: _selectedCredentialType == CredentialType.pin ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  labelText: _selectedCredentialType == CredentialType.pin ? 'New PIN' : 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewCredential ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureNewCredential = !_obscureNewCredential);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (_selectedCredentialType == CredentialType.pin) {
                    if (value!.length < 6) return 'PIN must be at least 6 digits';
                    if (!RegExp(r'^\d+$').hasMatch(value)) return 'PIN must be numeric';
                  } else {
                    if (value!.length < 8) return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              if (_selectedCredentialType == CredentialType.password) ...[
                const SizedBox(height: 8),
                PasswordStrengthIndicator(password: _newCredentialController.text),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmNewCredentialController,
                obscureText: _obscureConfirmNewCredential,
                keyboardType: _selectedCredentialType == CredentialType.pin ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  labelText: _selectedCredentialType == CredentialType.pin ? 'Confirm New PIN' : 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmNewCredential ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmNewCredential = !_obscureConfirmNewCredential);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value != _newCredentialController.text) return 'Does not match';
                  if (_selectedCredentialType == CredentialType.pin) {
                    if (value!.length < 6) return 'PIN must be at least 6 digits';
                    if (!RegExp(r'^\d+$').hasMatch(value)) return 'PIN must be numeric';
                  } else {
                    if (value!.length < 8) return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _handleChangeCredential,
                  child: const Text('Change Credential'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentCredentialController.dispose();
    _newCredentialController.dispose();
    _confirmNewCredentialController.dispose();
    super.dispose();
  }
}
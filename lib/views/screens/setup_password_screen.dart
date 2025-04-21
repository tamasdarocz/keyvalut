import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../services/password_strenght.dart';
import '../Tabs/login_screen.dart';

class SetupMasterPasswordScreen extends StatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  State<SetupMasterPasswordScreen> createState() => _SetupMasterPasswordScreenState();
}

enum CredentialType { pin, password }

class _SetupMasterPasswordScreenState extends State<SetupMasterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _credentialController = TextEditingController();
  final _confirmCredentialController = TextEditingController();
  CredentialType _selectedCredentialType = CredentialType.pin; // Default to PIN
  bool _obscureCredential = true;
  bool _obscureConfirmCredential = true;
  bool _isLoading = false;

  Future<void> _handleSetupCredential() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    setState(() => _isLoading = true);

    try {
      await authService.setMasterCredential(
        _credentialController.text,
        isPin: _selectedCredentialType == CredentialType.pin,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: _selectedCredentialType == CredentialType.pin ? 'PIN set successfully' : 'Password set successfully',
          gravity: ToastGravity.CENTER,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Error setting credential',
          gravity: ToastGravity.CENTER,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Credential'),
      ),
      body: Padding(
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
                selected: {_selectedCredentialType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedCredentialType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _credentialController,
                obscureText: _obscureCredential,
                keyboardType: _selectedCredentialType == CredentialType.pin ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  labelText: _selectedCredentialType == CredentialType.pin ? 'PIN' : 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCredential ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureCredential = !_obscureCredential);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (_selectedCredentialType == CredentialType.pin && value!.length < 6) return 'PIN must be at least 6 digits';
                  return null;
                },
              ),
              if (_selectedCredentialType == CredentialType.password) ...[
                const SizedBox(height: 8),
                PasswordStrengthIndicator(password: _credentialController.text),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmCredentialController,
                obscureText: _obscureConfirmCredential,
                keyboardType: _selectedCredentialType == CredentialType.pin ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  labelText: _selectedCredentialType == CredentialType.pin ? 'Confirm PIN' : 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmCredential ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmCredential = !_obscureConfirmCredential);
                    },
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value != _credentialController.text) return 'Does not match';
                  if (_selectedCredentialType == CredentialType.pin && value!.length < 6) return 'PIN must be at least 6 digits';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _handleSetupCredential,
                  child: const Text('Set Credential'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _confirmCredentialController.dispose();
    super.dispose();
  }
}
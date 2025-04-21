import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/password_strenght.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _currentCredentialController = TextEditingController();
  final _newCredentialController = TextEditingController();
  final _confirmCredentialController = TextEditingController();

  bool _obscureCurrentCredential = true;
  bool _obscureNewCredential = true;
  bool _obscureConfirmCredential = true;
  bool _isLoading = false;
  bool _isPinMode = false;
  bool _newIsPinMode = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
    _newCredentialController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadCurrentMode() async {
    final isPin = await _authService.isPinMode();
    if (mounted) {
      setState(() {
        _isPinMode = isPin;
        _newIsPinMode = isPin;
      });
    }
  }

  @override
  void dispose() {
    _newCredentialController.removeListener(() {});
    _currentCredentialController.dispose();
    _newCredentialController.dispose();
    _confirmCredentialController.dispose();
    super.dispose();
  }

  Future<void> _changeCredential() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isCurrentValid = await _authService.verifyMasterCredential(
        _currentCredentialController.text,
      );

      if (!isCurrentValid) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Current ${_isPinMode ? 'PIN' : 'password'} is incorrect')),
          );
        }
        return;
      }

      await _authService.setMasterCredential(
        _newCredentialController.text,
        isPin: _newIsPinMode,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_newIsPinMode ? 'PIN' : 'Password'} changed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing ${_isPinMode ? 'PIN' : 'password'}: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change ${_isPinMode ? 'PIN' : 'Master Password'}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _currentCredentialController,
                  obscureText: _obscureCurrentCredential,
                  keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Current ${_isPinMode ? 'PIN' : 'Password'}',
                    prefixIcon: const Icon(Icons.lock_outline),
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current ${_isPinMode ? 'PIN' : 'password'}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Authentication Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Password'),
                      icon: Icon(Icons.lock),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('PIN'),
                      icon: Icon(Icons.dialpad),
                    ),
                  ],
                  selected: {_newIsPinMode},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _newIsPinMode = newSelection.first;
                      _newCredentialController.clear();
                      _confirmCredentialController.clear();
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newCredentialController,
                  obscureText: _obscureNewCredential,
                  keyboardType: _newIsPinMode ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'New ${_newIsPinMode ? 'PIN' : 'Password'}',
                    prefixIcon: const Icon(Icons.lock),
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new ${_newIsPinMode ? 'PIN' : 'password'}';
                    }
                    if (_newIsPinMode) {
                      if (value.length < 6) return 'PIN must be at least 6 digits';
                      if (!RegExp(r'^\d+$').hasMatch(value)) return 'PIN must be numeric';
                    } else {
                      if (value.length < 6) return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                if (!_newIsPinMode)
                  PasswordStrengthIndicator(password: _newCredentialController.text),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCredentialController,
                  obscureText: _obscureConfirmCredential,
                  keyboardType: _newIsPinMode ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Confirm New ${_newIsPinMode ? 'PIN' : 'Password'}',
                    prefixIcon: const Icon(Icons.lock),
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
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new ${_newIsPinMode ? 'PIN' : 'password'}';
                    }
                    if (value != _newCredentialController.text) {
                      return '${_newIsPinMode ? 'PINs' : 'Passwords'} do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _changeCredential,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Change ${_newIsPinMode ? 'PIN' : 'Password'}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
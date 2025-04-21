import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../Tabs/homepage.dart';

class SetupMasterPasswordScreen extends StatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  State<SetupMasterPasswordScreen> createState() => _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState extends State<SetupMasterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _credentialController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isPinMode = false;
  bool _isLoading = false;
  bool _obscureCredential = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Set Up Authentication',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    selected: {_isPinMode},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _isPinMode = newSelection.first;
                        _credentialController.clear();
                        _confirmController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _credentialController,
                    obscureText: _obscureCredential,
                    keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _isPinMode ? 'New PIN' : 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCredential ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureCredential = !_obscureCredential);
                        },
                      ),
                    ),
                    validator: _validateCredential,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _isPinMode ? 'Confirm PIN' : 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                    ),
                    validator: _validateConfirm,
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _handleSetup,
                      child: const Text('Secure My Vault'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateCredential(String? value) {
    if (value?.isEmpty ?? true) return 'Required';
    if (_isPinMode) {
      if (value!.length < 6) return 'PIN must be at least 6 digits';
      if (!RegExp(r'^\d+$').hasMatch(value)) return 'PIN must be numeric';
    } else {
      if (value!.length < 6) return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _credentialController.text) return _isPinMode ? 'PINs must match' : 'Passwords must match';
    return null;
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await _authService.setMasterCredential(
      _credentialController.text,
      isPin: _isPinMode,
    );

    if (await _authService.isBiometricAvailable()) {
      await _authService.setBiometricEnabled(true);
    }

    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
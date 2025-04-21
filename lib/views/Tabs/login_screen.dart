import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'homepage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _credentialController = TextEditingController();
  bool _obscureCredential = true;
  bool _isLoading = false;
  bool _isPinMode = false;
  bool _biometricAvailable = false;
  bool _showManualEntry = false;

  @override
  void initState() {
    super.initState();
    _checkCredentialMode();
    _checkBiometricAvailability();
  }

  Future<void> _checkCredentialMode() async {
    final isPin = await _authService.isPinMode();
    if (mounted) {
      setState(() => _isPinMode = isPin);
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.isBiometricAvailable();
    final enabled = await _authService.isBiometricEnabled();
    final prefs = await SharedPreferences.getInstance();
    final requireBiometricsOnResume = prefs.getBool('requireBiometricsOnResume') ?? false;

    if (available && (enabled || requireBiometricsOnResume) && mounted) {
      setState(() => _biometricAvailable = true);
      _tryBiometricLogin();
    } else {
      setState(() => _showManualEntry = true);
    }
  }

  Future<void> _tryBiometricLogin() async {
    setState(() => _isLoading = true);
    try {
      final success = await _authService.authenticateWithBiometrics();
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _navigateToHomePage();
        } else {
          _showManualEntryDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMsg = 'Biometric error. Please use manual login.';
        if (e.toString().contains('NotEnrolled')) {
          errorMsg = 'No biometrics enrolled. Please set up biometrics or use manual login.';
        } else if (e.toString().contains('LockedOut')) {
          errorMsg = 'Biometrics locked out. Please use manual login.';
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          gravity: ToastGravity.CENTER,
        );
        _showManualEntryDialog();
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _authService.verifyMasterCredential(
        _credentialController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          _navigateToHomePage();
        } else {
          Fluttertoast.showToast(
            msg: _isPinMode ? 'Invalid PIN' : 'Invalid password',
            gravity: ToastGravity.CENTER,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: 'Error verifying credential',
          gravity: ToastGravity.CENTER,
        );
      }
    }
  }

  void _navigateToHomePage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
          (Route<dynamic> route) => false,
    );
  }

  void _showManualEntryDialog() {
    setState(() => _credentialController.clear());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          _isPinMode ? 'Enter PIN' : 'Enter Password',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextFormField(
          controller: _credentialController,
          obscureText: _obscureCredential,
          keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: _isPinMode ? 'PIN' : 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCredential ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                setState(() => _obscureCredential = !_obscureCredential);
              },
            ),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Required';
            if (_isPinMode && value!.length < 6) return 'PIN must be at least 6 digits';
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (_biometricAvailable) ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _tryBiometricLogin();
              },
              child: const Text('Use Biometrics'),
            ),
          ],
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleLogin();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isPinMode ? 'Enter PIN' : 'Enter Password',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_showManualEntry) ...[
                    TextFormField(
                      controller: _credentialController,
                      obscureText: _obscureCredential,
                      keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: _isPinMode ? 'PIN' : 'Password',
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
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (_isPinMode && value!.length < 6) return 'PIN must be at least 6 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        if (_showManualEntry) ...[
                          ElevatedButton(
                            onPressed: _handleLogin,
                            child: const Text('Unlock Vault'),
                          ),
                          if (_biometricAvailable) ...[
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _tryBiometricLogin,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Use Biometrics'),
                            ),
                          ],
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _credentialController.dispose();
    super.dispose();
  }
}
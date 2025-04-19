import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.isBiometricAvailable();
    final enabled = await _authService.isBiometricEnabled();
    if (available && enabled && mounted) {
      setState(() => _biometricAvailable = true);
      _tryBiometricLogin();
    } else if (available && mounted) {
      setState(() => _biometricAvailable = true);
    }
  }

  Future<void> _tryBiometricLogin() async {
    setState(() => _isLoading = true);
    try {
      if (!await _authService.isBiometricAvailable()) {
        if (mounted) {
          setState(() => _isLoading = false);
          Fluttertoast.showToast(msg: 'Biometrics not supported on this device', gravity: ToastGravity.CENTER);
        }
        return;
      }

      if (!await _authService.isBiometricEnabled()) {
        if (mounted) {
          setState(() => _isLoading = false);
          Fluttertoast.showToast(msg: 'Biometric disabled.', gravity: ToastGravity.CENTER);
        }
        return;
      }

      final success = await _authService.authenticateWithBiometrics();
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          Fluttertoast.showToast(msg: 'Biometric authentication failed', gravity: ToastGravity.CENTER);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: 'Biometric authentication failed', gravity: ToastGravity.CENTER);

      }
    }
  }


  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _authService.verifyMasterPassword(
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          Fluttertoast.showToast(msg: 'Invalid master password', gravity: ToastGravity.CENTER);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: 'Error verifying password', gravity: ToastGravity.CENTER);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
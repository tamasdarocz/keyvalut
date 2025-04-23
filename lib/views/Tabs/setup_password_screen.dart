import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';

import '../../services/password_strength.dart'; // Assuming Homepage is located here

enum AuthMode { pin, password }

class SetupMasterPasswordScreen extends StatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  State<SetupMasterPasswordScreen> createState() => _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState extends State<SetupMasterPasswordScreen> {
  final TextEditingController _databaseNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isPinVisible = false;
  bool _isConfirmPinVisible = false;
  AuthMode _authMode = AuthMode.pin;
  List<String> _existingDatabaseNames = [];

  @override
  void initState() {
    super.initState();
    _loadExistingDatabases();
  }

  @override
  void dispose() {
    _databaseNameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDatabases() async {
    try {
      // Get the app's documents directory to check for existing databases
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final databaseFiles = files
          .where((file) => file.path.endsWith('.db') && file is File)
          .map((file) => file.path.split('/').last.replaceAll('.db', ''))
          .toList();

      if (mounted) {
        setState(() {
          _existingDatabaseNames = databaseFiles;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading existing databases: $e')),
        );
      }
    }
  }

  Future<void> _createNewDatabase() async {
    final databaseName = _databaseNameController.text.trim();
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    debugPrint('Starting database creation for: $databaseName');

    if (databaseName.isEmpty) {
      debugPrint('Database creation failed: Database name is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database name cannot be empty')),
      );
      return;
    }

    if (_existingDatabaseNames.contains(databaseName)) {
      debugPrint('Database creation failed: Database "$databaseName" already exists');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database name already exists')),
      );
      return;
    }

    if (_authMode == AuthMode.pin) {
      if (pin.length < 6 || !RegExp(r'^\d+$').hasMatch(pin)) {
        debugPrint('Database creation failed: PIN must be at least 6 digits (entered: $pin)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN must be at least 6 digits')),
        );
        return;
      }
    } else {
      if (pin.length < 8) {
        debugPrint('Database creation failed: Password must be at least 8 characters (entered: $pin)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 8 characters')),
        );
        return;
      }
    }

    if (pin != confirmPin) {
      debugPrint('Database creation failed: PINs/Passwords do not match (entered: $pin, confirm: $confirmPin)');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs/Passwords do not match')),
      );
      return;
    }

    try {
      final authService = AuthService(databaseName);
      await authService.setMasterCredential(pin, isPin: _authMode == AuthMode.pin);
      // Save the database name to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentDatabase', databaseName);
      debugPrint('Database "$databaseName" created successfully with ${_authMode == AuthMode.pin ? 'PIN' : 'Password'}: $pin');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      debugPrint('Database creation failed for "$databaseName": $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating database: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Database'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<AuthMode>(
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
              selected: {_authMode},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _authMode = newSelection.first;
                  _pinController.clear();
                  _confirmPinController.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _databaseNameController,
              decoration: const InputDecoration(
                labelText: 'Database Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              obscureText: !_isPinVisible,
              decoration: InputDecoration(
                labelText: _authMode == AuthMode.pin ? 'PIN' : 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_isPinVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isPinVisible = !_isPinVisible;
                    });
                  },
                ),
              ),
              keyboardType: _authMode == AuthMode.pin ? TextInputType.number : TextInputType.text,
            ),
            if (_authMode == AuthMode.password) ...[
              const SizedBox(height: 8),
              PasswordStrengthIndicator(password: _pinController.text),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              obscureText: !_isConfirmPinVisible,
              decoration: InputDecoration(
                labelText: _authMode == AuthMode.pin ? 'Confirm PIN' : 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPinVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isConfirmPinVisible = !_isConfirmPinVisible;
                    });
                  },
                ),
              ),
              keyboardType: _authMode == AuthMode.pin ? TextInputType.number : TextInputType.text,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createNewDatabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Create New Database'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
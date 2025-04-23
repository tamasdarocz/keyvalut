import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:keyvalut/views/Tabs/setup_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // Import SetupMasterPasswordScreen
import 'package:keyvalut/views/Tabs/homepage.dart'; // Import Homepage

enum AuthMode { pin, password }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinVisible = false;
  String? _selectedDatabase;
  List<String> _databaseNames = [];
  bool _isLoading = true;
  AuthMode _authMode = AuthMode.pin;

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadDatabases() async {
    try {
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final databaseFiles = files
          .where((file) => file.path.endsWith('.db') && file is File)
          .map((file) => file.path.split('/').last.replaceAll('.db', ''))
          .toList();

      if (mounted) {
        setState(() {
          _databaseNames = databaseFiles;
          _selectedDatabase = _databaseNames.isNotEmpty ? _databaseNames.first : null;
          _isLoading = false;
        });
      }

      // If a database is selected, check its auth mode
      if (_selectedDatabase != null) {
        final authService = AuthService(_selectedDatabase!);
        final isPin = await authService.isPinMode();
        setState(() {
          _authMode = isPin ? AuthMode.pin : AuthMode.password;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading databases: $e')),
        );
      }
    }
  }

  Future<void> _unlockVault() async {
    if (_selectedDatabase == null) {
      debugPrint('Login failed: No database selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a database')),
      );
      return;
    }

    final input = _pinController.text;
    debugPrint('Attempting login for database: $_selectedDatabase with ${_authMode == AuthMode.pin ? 'PIN' : 'Password'}');

    if (_authMode == AuthMode.pin) {
      if (input.length < 6 || !RegExp(r'^\d+$').hasMatch(input)) {
        debugPrint('Login failed: PIN must be at least 6 digits (entered: $input)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN must be at least 6 digits')),
        );
        return;
      }
    } else {
      if (input.length < 8) {
        debugPrint('Login failed: Password must be at least 8 characters (entered: $input)');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 8 characters')),
        );
        return;
      }
    }

    try {
      final authService = AuthService(_selectedDatabase!);
      final isPinMode = await authService.isPinMode();
      if (isPinMode != (_authMode == AuthMode.pin)) {
        debugPrint('Login failed: Database uses ${isPinMode ? "PIN" : "password"} authentication, but ${_authMode == AuthMode.pin ? "PIN" : "password"} mode was selected');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This database uses ${_authMode == AuthMode.pin ? "password" : "PIN"} authentication. Please switch to the correct mode.',
            ),
          ),
        );
        return;
      }

      final isAuthenticated = await authService.verifyMasterCredential(input);
      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentDatabase', _selectedDatabase!);
        debugPrint('Login successful for database: $_selectedDatabase with ${_authMode == AuthMode.pin ? 'PIN' : 'Password'}: $input');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        debugPrint('Login failed for database: $_selectedDatabase - Authentication failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed')),
        );
      }
    } catch (e) {
      debugPrint('Login failed for database: $_selectedDatabase - Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _navigateToCreateNewDatabase() {
    debugPrint('Navigating to SetupMasterPasswordScreen to create a new database');
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupMasterPasswordScreen()),
      );
      debugPrint('Navigation to SetupMasterPasswordScreen completed');
    } catch (e) {
      debugPrint('Navigation to SetupMasterPasswordScreen failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Database'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Database',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Database Name',
                border: OutlineInputBorder(),
              ),
              value: _selectedDatabase,
              items: _databaseNames
                  .map((name) => DropdownMenuItem<String>(
                value: name,
                child: Text(name),
              ))
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedDatabase = value;
                  _pinController.clear();
                });
                if (value != null) {
                  final authService = AuthService(value);
                  final isPin = await authService.isPinMode();
                  setState(() {
                    _authMode = isPin ? AuthMode.pin : AuthMode.password;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToCreateNewDatabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Create New'),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Enter PIN/Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _unlockVault,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Unlock Vault'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
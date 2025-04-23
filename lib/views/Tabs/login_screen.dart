import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:keyvalut/views/Tabs/setup_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';

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
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

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

      if (_selectedDatabase != null) {
        final authService = AuthService(_selectedDatabase!);
        final isPin = await authService.isPinMode();
        final isBiometricAvailable = await authService.isBiometricAvailable();
        final isBiometricEnabled = await authService.isBiometricEnabled();
        setState(() {
          _authMode = isPin ? AuthMode.pin : AuthMode.password;
          _isBiometricAvailable = isBiometricAvailable;
          _isBiometricEnabled = isBiometricEnabled;
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

  Future<void> _unlockWithBiometrics() async {
    if (_selectedDatabase == null) {
      debugPrint('Biometric login failed: No database selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a database')),
      );
      return;
    }

    if (!_isBiometricAvailable) {
      debugPrint('Biometric login failed: Biometrics not available on this device');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometrics not available on this device')),
      );
      return;
    }

    if (!_isBiometricEnabled) {
      debugPrint('Biometric login failed: Biometrics not enabled for this database');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometrics not enabled for this database')),
      );
      return;
    }

    try {
      final authService = AuthService(_selectedDatabase!);
      final isAuthenticated = await authService.authenticateWithBiometrics(
        reason: 'Please authenticate to unlock the vault for $_selectedDatabase',
      );
      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentDatabase', _selectedDatabase!);
        debugPrint('Biometric login successful for database: $_selectedDatabase');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        debugPrint('Biometric login failed for database: $_selectedDatabase - User canceled or authentication failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication failed')),
        );
      }
    } catch (e) {
      debugPrint('Biometric login failed for database: $_selectedDatabase - Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric Error: $e')),
      );
    }
  }

  void _navigateToCreateNewDatabase() {
    debugPrint('Navigating to SetupMasterPasswordScreen to create a new database');
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupLoginScreen()),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Database'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Select Database',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
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
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: theme.colorScheme.primary,
                        selectedForegroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _databaseNames.isEmpty
                        ? Text(
                      'No databases found',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    )
                        : Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: _databaseNames.map((name) {
                        return ChoiceChip(
                          label: Text(name),
                          selected: _selectedDatabase == name,
                          onSelected: (selected) async {
                            if (selected) {
                              setState(() {
                                _selectedDatabase = name;
                                _pinController.clear();
                              });
                              final authService = AuthService(name);
                              final isPin = await authService.isPinMode();
                              final isBiometricAvailable = await authService.isBiometricAvailable();
                              final isBiometricEnabled = await authService.isBiometricEnabled();
                              setState(() {
                                _authMode = isPin ? AuthMode.pin : AuthMode.password;
                                _isBiometricAvailable = isBiometricAvailable;
                                _isBiometricEnabled = isBiometricEnabled;
                              });
                            }
                          },
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surface,
                          labelStyle: TextStyle(
                            color: _selectedDatabase == name
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Enter PIN/Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      obscureText: !_isPinVisible,
                      decoration: InputDecoration(
                        labelText: _authMode == AuthMode.pin ? 'PIN' : 'Password',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.onSurface),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        prefixIcon: Icon(Icons.lock, color: theme.colorScheme.onSurface),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPinVisible ? Icons.visibility_off : Icons.visibility,
                            color: theme.colorScheme.onSurface,
                          ),
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
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: _unlockVault,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Unlock Vault'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: (_isBiometricAvailable && _isBiometricEnabled) ? _unlockWithBiometrics : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Use Biometrics'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 180,
            right: 0,
            bottom: 32,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: _navigateToCreateNewDatabase,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                icon: const Icon(Icons.add),
                label: const Text('Create New'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
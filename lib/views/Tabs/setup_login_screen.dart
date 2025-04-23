import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';
import 'package:keyvalut/views/Tabs/login_screen.dart';
import '../../services/password_strength.dart';

enum AuthMode { pin, password }

class SetupLoginScreen extends StatefulWidget {
  final VoidCallback? onCallback;

  const SetupLoginScreen({super.key, this.onCallback});

  @override
  State<SetupLoginScreen> createState() => _SetupLoginScreenState();
}

class _SetupLoginScreenState extends State<SetupLoginScreen> {
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentDatabase', databaseName);
      debugPrint('Database "$databaseName" created successfully with ${_authMode == AuthMode.pin ? 'PIN' : 'Password'}: $pin');
      if (mounted) {
        widget.onCallback?.call();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      debugPrint('Database creation failed for "$databaseName": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating database: $e')),
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
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                selected: {_authMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _authMode = newSelection.first;
                    _pinController.clear();
                    _confirmPinController.clear();
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: theme.colorScheme.primary,
                  selectedForegroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _databaseNameController,
              decoration: InputDecoration(
                labelText: 'Database Name',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.onSurface),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                prefixIcon: Icon(Icons.storage, color: theme.colorScheme.onSurface),
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
                    _isConfirmPinVisible ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.onSurface,
                  ),
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
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: _createNewDatabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(0, 48),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Create New Database'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// A screen that allows users to create a new database by setting its name and master credential (PIN or password).
/// Displays a recovery key dialog upon successful database creation.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';
import 'package:keyvalut/views/Tabs/login_screen.dart';
import '../../services/password_strength.dart';
import '../../services/utils.dart';
import '../screens/recovery_key_dialog.dart';

class SetupLoginScreen extends StatefulWidget {
  /// A callback function to be called after a new database is successfully created.
  final VoidCallback? onCallback;

  /// Creates a SetupLoginScreen widget.
  const SetupLoginScreen({super.key, this.onCallback});

  @override
  State<SetupLoginScreen> createState() => _SetupLoginScreenState();
}

class _SetupLoginScreenState extends State<SetupLoginScreen> {
  /// Controller for the database name input field.
  final TextEditingController _databaseNameController = TextEditingController();

  /// Controller for the PIN/password input field.
  final TextEditingController _pinController = TextEditingController();

  /// Controller for the confirm PIN/password input field.
  final TextEditingController _confirmPinController = TextEditingController();

  /// Whether the PIN/password input is visible.
  bool _isPinVisible = false;

  /// Whether the confirm PIN/password input is visible.
  bool _isConfirmPinVisible = false;

  /// The current authentication mode (PIN or password).
  AuthMode _authMode = AuthMode.pin;

  /// List of existing database names to prevent duplicates.
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

  /// Loads the list of existing databases to prevent duplicate database names.
  Future<void> _loadExistingDatabases() async {
    try {
      final databaseFiles = await fetchDatabaseNames();
      if (mounted) {
        setState(() {
          _existingDatabaseNames = databaseFiles;
        });
      }
    } catch (e) {
      if (mounted) {
        handleError(e);
      }
    }
  }

  /// Shows a dialog displaying the recovery key for the newly created database.
  /// [recoveryKey] The recovery key to display.
  Future<void> _showRecoveryKeyDialog(String recoveryKey) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RecoveryKeyDialog(
        recoveryKey: recoveryKey,
      ),
    );
  }

  /// Creates a new database with the provided name and master credential.
  /// Validates inputs, shows the recovery key, and navigates to HomePage on success.
  Future<void> _createNewDatabase() async {
    final databaseName = _databaseNameController.text.trim();
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    try {
      if (databaseName.isEmpty) {
        throw AppException('Database name cannot be empty');
      }

      if (_existingDatabaseNames.contains(databaseName)) {
        throw AppException('Database name already exists');
      }

      validateInput(pin, _authMode);

      if (pin != confirmPin) {
        throw AppException('PINs/Passwords do not match');
      }

      final authService = AuthService(databaseName);
      final recoveryKey = await authService.setMasterCredential(pin, isPin: _authMode == AuthMode.pin);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentDatabase', databaseName);

      await _showRecoveryKeyDialog(recoveryKey);

      if (mounted) {
        widget.onCallback?.call();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        handleError(e);
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
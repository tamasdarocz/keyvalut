import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/views/Tabs/setup_login_screen.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';
import '../../services/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Constants for UI
  static const double _padding = 16.0;
  static const double _buttonHeight = 48.0;
  static const double _fontSizeTitle = 18.0;

  // State management class
  final _LoginState _state = _LoginState();
  final TextEditingController _pinController = TextEditingController();
  AuthService? _authService;

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

  // Load available databases
  Future<void> _loadDatabases() async {
    try {
      setState(() => _state.isLoading = true);
      final databases = await fetchDatabaseNames();
      final lastUsedDatabase = await _getLastUsedDatabase();
      setState(() {
        _state.databaseNames = databases;
        _state.selectedDatabase = _selectInitialDatabase(databases, lastUsedDatabase);
        _state.isLoading = false;
      });

      if (_state.selectedDatabase != null) {
        await _updateAuthService(_state.selectedDatabase!);
        // Set the initial authMode based on the database
        final isPin = await _authService!.isPinMode();
        setState(() {
          _state.authMode = isPin ? AuthMode.pin : AuthMode.password;
        });
        if (_state.isBiometricAvailable && _state.isBiometricEnabled) {
          await _unlockWithBiometrics();
        }
      }
    } catch (e) {
      setState(() => _state.isLoading = false);
      handleError(e);
    }
  }

  // Get last used database from preferences
  Future<String?> _getLastUsedDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentDatabase');
  }

  // Select initial database
  String? _selectInitialDatabase(List<String> databases, String? lastUsed) {
    return lastUsed != null && databases.contains(lastUsed)
        ? lastUsed
        : databases.isNotEmpty
        ? databases.first
        : null;
  }

  // Update auth service and auth mode
  Future<void> _updateAuthService(String databaseName) async {
    _authService = AuthService(databaseName);
    final isPin = await _authService!.isPinMode();
    final isBiometricAvailable = await _authService!.isBiometricAvailable();
    final isBiometricEnabled = await _authService!.isBiometricEnabled();
    setState(() {
      _state.authMode = isPin ? AuthMode.pin : AuthMode.password;
      _state.isBiometricAvailable = isBiometricAvailable;
      _state.isBiometricEnabled = isBiometricEnabled;
    });
  }

  // Unlock vault with PIN/password
  Future<void> _unlockVault() async {
    if (_state.selectedDatabase == null || _authService == null) {
      showToast('Please select a database');
      return;
    }

    try {
      final input = _pinController.text;
      validateInput(input, _state.authMode);

      final isPinMode = await _authService!.isPinMode();
      if (isPinMode != (_state.authMode == AuthMode.pin)) {
        throw AppException(
            'This database uses ${isPinMode ? "PIN" : "password"} authentication. Please switch to the correct mode.');
      }

      final isAuthenticated = await _authService!.verifyMasterCredential(input);
      if (isAuthenticated) {
        await _saveCurrentDatabase(_state.selectedDatabase!);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        _pinController.clear(); // Clear the input field on incorrect input
        showToast('Authentication failed');
      }
    } catch (e) {
      _pinController.clear(); // Clear the input field on error
      handleError(e);
    }
  }

  // Save current database to preferences
  Future<void> _saveCurrentDatabase(String databaseName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentDatabase', databaseName);
  }

  // Unlock with biometrics
  Future<void> _unlockWithBiometrics() async {
    if (_state.selectedDatabase == null || _authService == null) {
      showToast('Please select a database');
      return;
    }
    if (!_state.isBiometricAvailable) {
      showToast('Biometrics not available on this device');
      return;
    }
    if (!_state.isBiometricEnabled) {
      showToast('Biometrics not enabled for this database');
      return;
    }

    try {
      final isAuthenticated = await _authService!.authenticateWithBiometrics(
        reason: 'Please authenticate to unlock the vault for ${_state.selectedDatabase}',
      );
      if (isAuthenticated) {
        await _saveCurrentDatabase(_state.selectedDatabase!);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
      }
    } catch (e) {
      handleError(e);
    }
  }

  // Navigate to create new database
  void _navigateToCreateNewDatabase() {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SetupLoginScreen(
            onCallback: _loadDatabases,
          ),
        ),
      );
    } catch (e) {
      handleError(e);
    }
  }

  // Build database selector
  Widget _buildDatabaseSelector(ThemeData theme) {
    if (_state.databaseNames.isEmpty) {
      return Text(
        'No databases found',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: _state.databaseNames.map((name) {
        return ChoiceChip(
          label: Text(name),
          selected: _state.selectedDatabase == name,
          onSelected: (selected) async {
            if (selected) {
              setState(() {
                _state.selectedDatabase = name;
                _pinController.clear();
              });
              await _updateAuthService(name);
              if (_state.isBiometricAvailable && _state.isBiometricEnabled) {
                await _unlockWithBiometrics();
              }
            }
          },
          selectedColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          labelStyle: TextStyle(
            color: _state.selectedDatabase == name
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        );
      }).toList(),
    );
  }

  // Build auth Bond button
  Widget _buildButton({
    required VoidCallback onPressed,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(0, _buttonHeight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        child: Text(label),
      ),
    );
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
        actions: [],
      ),
      body: _state.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(_padding),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Select Database',
                style: TextStyle(
                  fontSize: _fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: _padding),
              _buildDatabaseSelector(theme),
              const SizedBox(height: _padding),
              _buildButton(
                onPressed: _navigateToCreateNewDatabase,
                label: 'Create New',
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              const SizedBox(height: _padding),
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
                  selected: {_state.authMode},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _state.authMode = newSelection.first;
                      _pinController.clear();
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: theme.colorScheme.primary,
                    selectedForegroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: _padding),
              TextField(
                controller: _pinController,
                obscureText: !_state.isPinVisible,
                decoration: InputDecoration(
                  labelText: _state.authMode == AuthMode.pin ? 'PIN' : 'Password',
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
                      _state.isPinVisible ? Icons.visibility_off : Icons.visibility,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      setState(() => _state.isPinVisible = !_state.isPinVisible);
                    },
                  ),
                ),
                keyboardType: _state.authMode == AuthMode.pin
                    ? TextInputType.number
                    : TextInputType.text,
              ),
              const SizedBox(height: _padding),
              _buildButton(
                onPressed: _unlockVault,
                label: 'Unlock Vault',
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              const SizedBox(height: 8),
              _buildButton(
                onPressed: _unlockWithBiometrics,
                label: 'Use Biometrics',
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                enabled: _state.isBiometricAvailable && _state.isBiometricEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// State management class
class _LoginState {
  bool isLoading = true;
  bool isPinVisible = false;
  String? selectedDatabase;
  List<String> databaseNames = [];
  AuthMode authMode = AuthMode.pin;
  bool isBiometricAvailable = false;
  bool isBiometricEnabled = false;
}
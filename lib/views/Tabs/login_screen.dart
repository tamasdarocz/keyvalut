// Login screen for selecting and authenticating into a database.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/views/Tabs/setup_login_screen.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';
import 'package:keyvalut/data/database_provider.dart';
import '../../data/database_helper.dart';
import '../../services/utils.dart';
import '../dialogs/reset_credential_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Constants for UI spacing and sizing.
  static const double _padding = 16.0;
  static const double _buttonHeight = 48.0;
  static const double _fontSizeTitle = 18.0;

  // State management for login UI.
  final _LoginState _state = _LoginState();
  final TextEditingController _pinController = TextEditingController();
  AuthService? _authService;
  String _remainingLockoutTime = '0 seconds';
  bool _isLockedOut = false;

  @override
  void initState() {
    super.initState();
    // Load available databases and start lockout timer.
    _loadDatabases();
    _startLockoutTimer();
  }

  @override
  void dispose() {
    // Clean up controller.
    _pinController.dispose();
    super.dispose();
  }

  // Periodically updates lockout status and remaining time.
  void _startLockoutTimer() {
    Future.doWhile(() async {
      if (!mounted) return false;
      if (_authService == null) {
        await Future.delayed(const Duration(seconds: 60));
        return true;
      }
      final isLockedOut = await _authService!.isLockedOut();
      final remainingTime = await _authService!.getRemainingLockoutTime();
      setState(() {
        _isLockedOut = isLockedOut;
        _remainingLockoutTime = remainingTime;
      });
      await Future.delayed(const Duration(seconds: 60));
      return true;
    });
  }

  // Loads database names and selects the last used one.
  Future<void> _loadDatabases() async {
    try {
      setState(() => _state.isLoading = true);
      final databases = await fetchDatabaseNames();
      final lastUsedDatabase = await _getLastUsedDatabase();

      // Filter out invalid 'default' database without credentials.
      final validDatabases = <String>[];
      for (final dbName in databases) {
        if (dbName == 'default') {
          final authService = AuthService(dbName);
          if (!await authService.isMasterCredentialSet()) {
            final dbHelper = DatabaseHelper(dbName);
            await dbHelper.deleteDatabase();
            continue;
          }
        }
        validDatabases.add(dbName);
      }

      setState(() {
        _state.databaseNames = validDatabases;
        _state.selectedDatabase = _selectInitialDatabase(validDatabases, lastUsedDatabase);
        if (_state.databaseNames.isEmpty) {
          _state.selectedDatabase = null;
        }
        _state.isLoading = false;
      });

      // Initialize auth service and check biometric/reset status.
      if (_state.selectedDatabase != null) {
        await _updateAuthService(_state.selectedDatabase!);
        final isPin = await _authService!.isPinMode();
        setState(() {
          _state.authMode = isPin ? AuthMode.pin : AuthMode.password;
        });
        if (_state.isBiometricAvailable && _state.isBiometricEnabled) {
          final authService = AuthService(_state.selectedDatabase!);
          if (!(await authService.isLockedOut()) && !(await authService.isForceResetRequired())) {
            await _unlockWithBiometrics();
          }
        }
        if (await _authService!.isForceResetRequired()) {
          _showResetMasterCredentialDialog();
        }
      } else {
        setState(() {
          _authService = null;
          _isLockedOut = false;
          _remainingLockoutTime = '0 seconds';
        });
      }
    } catch (e) {
      setState(() => _state.isLoading = false);
    }
  }

  // Retrieves the last used database from shared preferences.
  Future<String?> _getLastUsedDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDatabase = prefs.getString('currentDatabase');
    return currentDatabase;
  }

  // Selects initial database, prioritizing last used.
  String? _selectInitialDatabase(List<String> databases, String? lastUsed) {
    final selected = lastUsed != null && databases.contains(lastUsed)
        ? lastUsed
        : databases.isNotEmpty
        ? databases.first
        : null;
    return selected;
  }

  // Updates auth service and UI state for selected database.
  Future<void> _updateAuthService(String databaseName) async {
    _authService = AuthService(databaseName);
    final isPin = await _authService!.isPinMode();
    final isBiometricAvailable = await _authService!.isBiometricAvailable();
    final isBiometricEnabled = await _authService!.isBiometricEnabled();
    final isLockedOut = await _authService!.isLockedOut();
    final remainingTime = await _authService!.getRemainingLockoutTime();
    setState(() {
      _state.authMode = isPin ? AuthMode.pin : AuthMode.password;
      _state.isBiometricAvailable = isBiometricAvailable;
      _state.isBiometricEnabled = isBiometricEnabled;
      _isLockedOut = isLockedOut;
      _remainingLockoutTime = remainingTime;
    });
  }

  // Authenticates user with PIN/password and navigates to homepage.
  Future<void> _unlockVault() async {
    if (_state.selectedDatabase == null || _authService == null) {
      showToast('Please select a database');
      return;
    }

    if (await _authService!.isForceResetRequired()) {
      showToast('Too many failed attempts. Please reset your ${_state.authMode == AuthMode.pin ? 'PIN' : 'password'} using the recovery key.');
      await _showResetMasterCredentialDialog();
      return;
    }

    if (await _authService!.isLockedOut()) {
      return;
    }

    try {
      final input = _pinController.text;
      validateInput(input, _state.authMode);

      final isPinMode = await _authService!.isPinMode();
      if (isPinMode != (_state.authMode == AuthMode.pin)) {
        await _authService!.incrementFailedAttempts();
        if (await _authService!.isForceResetRequired()) {
          showToast('Too many failed attempts. Please reset your ${_state.authMode == AuthMode.pin ? 'PIN' : 'password'} using the recovery key.');
          await _showResetMasterCredentialDialog();
        }
        throw AppException('This database uses ${isPinMode ? "PIN" : "password"} authentication. Please switch to the correct mode.');
      }

      final isAuthenticated = await _authService!.verifyMasterCredential(input);
      if (isAuthenticated) {
        await _authService!.resetBruteForceState();
        await _saveCurrentDatabase(_state.selectedDatabase!);
        final provider = Provider.of<DatabaseProvider>(context, listen: false);
        provider.setDatabaseName(_state.selectedDatabase!);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        await _authService!.incrementFailedAttempts();
        _pinController.clear();
        if (await _authService!.isForceResetRequired()) {
          showToast('Too many failed attempts. Please reset your ${_state.authMode == AuthMode.pin ? 'PIN' : 'password'} using the recovery key.');
          await _showResetMasterCredentialDialog();
        } else {
          showToast('Authentication failed');
        }
      }
    } catch (e) {
      await _authService!.incrementFailedAttempts();
      _pinController.clear();
      if (await _authService!.isForceResetRequired()) {
        showToast('Too many failed attempts. Please reset your ${_state.authMode == AuthMode.pin ? 'PIN' : 'password'} using the recovery key.');
        await _showResetMasterCredentialDialog();
      }
    }
  }

  // Saves current database to shared preferences.
  Future<void> _saveCurrentDatabase(String databaseName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentDatabase', databaseName);
  }

  // Authenticates user with biometrics and navigates to homepage.
  Future<void> _unlockWithBiometrics() async {
    if (_state.selectedDatabase == null || _authService == null) {
      showToast('Please select a database');
      return;
    }
    if (await _authService!.isForceResetRequired()) {
      showToast('Too many failed attempts. Please reset your ${_state.authMode == AuthMode.pin ? 'PIN' : 'password'} using the recovery key.');
      await _showResetMasterCredentialDialog();
      return;
    }
    if (await _authService!.isLockedOut()) {
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
        await _authService!.resetBruteForceState();
        await _saveCurrentDatabase(_state.selectedDatabase!);
        final provider = Provider.of<DatabaseProvider>(context, listen: false);
        provider.setDatabaseName(_state.selectedDatabase!);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        await _authService!.incrementFailedAttempts();
        if (await _authService!.isForceResetRequired()) {
          showToast('Too many failed attempts. Please reset your ${_state.authMode == AuthMode.pin ? 'PIN' : 'password'} using the recovery key.');
          await _showResetMasterCredentialDialog();
        } else {
          showToast('Biometric authentication failed');
        }
      }
    } catch (e) {
      await _authService!.incrementFailedAttempts();
      if (await _authService!.isForceResetRequired()) {
        showToast('Too many failed attempts. Please reset your ${_state.authMode == AuthMode.pin ? 'PIN' : 'password'} using the recovery key.');
        await _showResetMasterCredentialDialog();
      }
    }
  }

  // Navigates to screen for creating a new database.
  void _navigateToCreateNewDatabase() {
    try {
      Navigator.push(
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

  // Shows dialog for resetting master credential.
  Future<void> _showResetMasterCredentialDialog() async {
    if (_state.selectedDatabase == null || _authService == null) {
      showToast('Please select a database');
      return;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => ResetCredentialDialog(
        authService: _authService!,
        isPinMode: _state.authMode == AuthMode.pin,
        onResetSuccess: () {
          _pinController.clear();
          setState(() async {
            final isPin = await _authService!.isPinMode();
            _state.authMode = isPin ? AuthMode.pin : AuthMode.password;
          });
        },
      ),
    );
  }

  // Builds UI for selecting a database.
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
              if (await _authService!.isForceResetRequired()) {
                showToast('Too many failed attempts. Please reset your ${_state.authMode == AuthMode.pin ? 'PIN' : 'password'} using the recovery key.');
                await _showResetMasterCredentialDialog();
              } else if (_state.isBiometricAvailable && _state.isBiometricEnabled) {
                final authService = AuthService(name);
                if (!(await authService.isLockedOut()) && !(await authService.isForceResetRequired())) {
                  await _unlockWithBiometrics();
                }
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

  // Builds a styled button for actions.
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
    final isDatabaseSelected = _state.selectedDatabase != null;
    // Main UI with database selector, auth mode toggle, and input field.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateNewDatabase,
            tooltip: 'Create New Database',
          ),
        ],
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
                enabled: isDatabaseSelected && !_isLockedOut,
                decoration: InputDecoration(
                  labelText: _state.authMode == AuthMode.pin ? 'PIN' : 'Password',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.onSurface),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.error),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  prefixIcon: Icon(
                    Icons.lock,
                    color: _isLockedOut
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _state.isPinVisible ? Icons.visibility_off : Icons.visibility,
                      color: _isLockedOut
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      setState(() => _state.isPinVisible = !_state.isPinVisible);
                    },
                  ),
                  helperText: _isLockedOut
                      ? 'Remaining lockout time: $_remainingLockoutTime'
                      : (isDatabaseSelected ? null : 'Create a new database to get started'),
                  helperStyle: TextStyle(
                    color: _isLockedOut
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
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
                enabled: isDatabaseSelected,
              ),
              const SizedBox(height: 8),
              _buildButton(
                onPressed: _unlockWithBiometrics,
                label: 'Use Biometrics',
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                enabled: isDatabaseSelected && _state.isBiometricAvailable && _state.isBiometricEnabled,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isDatabaseSelected ? _showResetMasterCredentialDialog : null,
                child: Text(
                  'Forgot ${_state.authMode == AuthMode.pin ? 'PIN' : 'Password'}?',
                  style: TextStyle(
                    color: isDatabaseSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// State class for managing login UI state.
class _LoginState {
  bool isLoading = true;
  bool isPinVisible = false;
  String? selectedDatabase;
  List<String> databaseNames = [];
  AuthMode authMode = AuthMode.pin;
  bool isBiometricAvailable = false;
  bool isBiometricEnabled = false;
}
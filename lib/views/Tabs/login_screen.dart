/// A screen that allows users to log in to a selected database using PIN, password, or biometrics.
/// Includes brute force protection to prevent unauthorized access.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/views/Tabs/setup_login_screen.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';
import '../../services/utils.dart';
import '../dialogs/reset_credential_dialog.dart';

class LoginScreen extends StatefulWidget {
  /// Creates a LoginScreen widget.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Padding used for UI elements.
  static const double _padding = 16.0;

  /// Height of buttons in the UI.
  static const double _buttonHeight = 48.0;

  /// Font size for section titles.
  static const double _fontSizeTitle = 18.0;

  /// State object to manage login screen data.
  final _LoginState _state = _LoginState();

  /// Controller for the PIN/password input field.
  final TextEditingController _pinController = TextEditingController();

  /// AuthService instance for the selected database.
  AuthService? _authService;

  /// Tracks the remaining lockout time for display.
  String _remainingLockoutTime = '0 seconds';

  /// Tracks whether the user is currently locked out.
  bool _isLockedOut = false;

  @override
  void initState() {
    super.initState();
    _loadDatabases();
    // Periodically check lockout status to update the UI
    _startLockoutTimer();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// Starts a timer to periodically check the lockout status and update the UI.
  void _startLockoutTimer() {
    Future.doWhile(() async {
      if (!mounted) return false; // Stop if the widget is disposed
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

  /// Also triggers biometric authentication if enabled and no lockout or forced reset is active.
  Future<void> _loadDatabases() async {
    try {
      setState(() => _state.isLoading = true);
      final databases = await fetchDatabaseNames();
      final lastUsedDatabase = await _getLastUsedDatabase();
      setState(() {
        _state.databaseNames = databases;
        _state.selectedDatabase = _selectInitialDatabase(databases, lastUsedDatabase);
        if (_state.databaseNames.isEmpty) {
          _state.selectedDatabase = null; // Explicitly clear selectedDatabase
        }
        _state.isLoading = false;
      });

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
        // Check if forced reset is required on load
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
      handleError(e);
    }
  }

  /// Retrieves the last used database from SharedPreferences.
  /// Returns the database name if it exists, null otherwise.
  Future<String?> _getLastUsedDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentDatabase');
  }

  /// Selects the initial database to display.
  /// [databases] List of available database names.
  /// [lastUsed] The last used database name.
  /// Returns the selected database name, prioritizing the last used database.
  String? _selectInitialDatabase(List<String> databases, String? lastUsed) {
    return lastUsed != null && databases.contains(lastUsed)
        ? lastUsed
        : databases.isNotEmpty
        ? databases.first
        : null;
  }

  /// Updates the AuthService instance and related state for the selected database.
  /// [databaseName] The name of the database to update settings for.
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

  /// Attempts to unlock the database using the provided PIN or password.
  /// Includes brute force protection via AuthService.
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
      // No toast, UI will display the lockout time as helper text
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
        throw AppException(
            'This database uses ${isPinMode ? "PIN" : "password"} authentication. Please switch to the correct mode.');
      }

      final isAuthenticated = await _authService!.verifyMasterCredential(input);
      if (isAuthenticated) {
        await _authService!.resetBruteForceState();
        await _saveCurrentDatabase(_state.selectedDatabase!);
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
      } else {
        handleError(e);
      }
    }
  }

  /// Saves the currently selected database to SharedPreferences.
  /// [databaseName] The name of the database to save.
  Future<void> _saveCurrentDatabase(String databaseName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentDatabase', databaseName);
  }

  /// Attempts to unlock the database using biometric authentication.
  /// Includes brute force protection via AuthService.
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
      // No toast, UI will display the lockout time as helper text
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
      } else {
        handleError(e);
      }
    }
  }

  /// Navigates to the SetupLoginScreen to create a new database.
  /// Refreshes the database list upon successful creation.
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

  /// Shows a dialog to reset the master credential using a recovery key.
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

  /// Builds the database selector UI using ChoiceChips.
  /// [theme] The current theme data for styling.
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

  /// Builds a styled button for the UI.
  /// [onPressed] The callback when the button is pressed.
  /// [label] The text label for the button.
  /// [backgroundColor] The background color of the button.
  /// [foregroundColor] The foreground color of the button.
  /// [enabled] Whether the button is enabled.
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
              if (_state.databaseNames.isNotEmpty) ...[
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
                  enabled: !_isLockedOut, // Disable input during lockout
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
                          ? theme.colorScheme.error // Red during lockout
                          : theme.colorScheme.onSurface,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _state.isPinVisible ? Icons.visibility_off : Icons.visibility,
                        color: _isLockedOut
                            ? theme.colorScheme.error // Red during lockout
                            : theme.colorScheme.onSurface,
                      ),
                      onPressed: () {
                        setState(() => _state.isPinVisible = !_state.isPinVisible);
                      },
                    ),
                    helperText: _isLockedOut ? 'Remaining lockout time: $_remainingLockoutTime' : null,
                    helperStyle: TextStyle(
                      color: theme.colorScheme.error,
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
                  label: 'Unlock Trezor',
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showResetMasterCredentialDialog,
                  child: Text(
                    'Forgot ${_state.authMode == AuthMode.pin ? 'PIN' : 'Password'}?',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A class to manage the state of the LoginScreen.
class _LoginState {
  /// Whether the screen is currently loading.
  bool isLoading = true;

  /// Whether the PIN/password input is visible.
  bool isPinVisible = false;

  /// The currently selected database name.
  String? selectedDatabase;

  /// List of available database names.
  List<String> databaseNames = [];

  /// The current authentication mode (PIN or password).
  AuthMode authMode = AuthMode.pin;

  /// Whether biometric authentication is available on the device.
  bool isBiometricAvailable = false;

  /// Whether biometric authentication is enabled for the selected database.
  bool isBiometricEnabled = false;
}
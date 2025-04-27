import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/theme/theme_provider.dart';
import 'package:keyvalut/views/screens/archived_credentials_screen.dart';
import 'package:keyvalut/views/screens/change_login_screen.dart';
import 'package:keyvalut/views/screens/deleted_credentials_screen.dart';
import 'package:keyvalut/views/screens/recovery_key_dialog.dart';
import 'package:keyvalut/views/screens/reset_credential_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/services/export_services.dart';
import 'package:keyvalut/services/import_service.dart';
import 'package:keyvalut/data/credential_provider.dart';
import 'package:keyvalut/data/database_helper.dart'; // Added import for DatabaseHelper

/// A settings menu widget that allows users to manage app settings, including theme, authentication, and database operations.
class SettingsMenu extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSettingsChanged;

  /// Creates a [SettingsMenu] widget.
  ///
  /// - [onLogout] is called when the user logs out.
  /// - [onSettingsChanged] is called when settings are modified.
  const SettingsMenu({
    super.key,
    required this.onLogout,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  int _timeoutDuration = 1;
  bool _lockImmediately = false;
  bool _requireBiometricsOnResume = false;
  bool _isPinMode = false;
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _credentialController = TextEditingController();
  String? _currentDatabase;
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  /// Loads the current credential mode (PIN or password) for the database.
  Future<void> _loadCredentialMode() async {
    if (_authService == null) return;
    final isPin = await _authService!.isPinMode();
    if (mounted) {
      setState(() => _isPinMode = isPin);
    }
  }

  /// Loads the current database name and initializes authentication settings.
  Future<void> _loadDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseName = prefs.getString('currentDatabase');
    if (databaseName != null) {
      setState(() {
        _currentDatabase = databaseName;
        _authService = AuthService(databaseName);
      });
      _loadBiometricSettings();
      _loadTimeoutSettings();
      _loadCredentialMode();
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// Loads biometric authentication settings for the database.
  Future<void> _loadBiometricSettings() async {
    if (_authService == null) return;
    final available = await _authService!.isBiometricAvailable();
    final enabled = await _authService!.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  /// Loads timeout settings from SharedPreferences.
  Future<void> _loadTimeoutSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _timeoutDuration = prefs.getInt('timeoutDuration') ?? 1;
        _lockImmediately = prefs.getBool('lockImmediately') ?? false;
        _requireBiometricsOnResume = prefs.getBool('requireBiometricsOnResume') ?? false;
      });
    }
  }

  /// Toggles biometric authentication and updates the settings.
  Future<void> _toggleBiometric(bool value) async {
    if (_authService == null) return;
    await _authService!.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _biometricEnabled = value);
      widget.onSettingsChanged();
    }
  }

  /// Sets the timeout duration for automatic logout.
  Future<void> _setTimeoutDuration(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timeoutDuration', value);
    if (mounted) {
      setState(() => _timeoutDuration = value);
      widget.onSettingsChanged();
    }
  }

  /// Toggles immediate locking when the app is sent to the background.
  Future<void> _toggleLockImmediately(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lockImmediately', value);
    if (mounted) {
      setState(() => _lockImmediately = value);
      widget.onSettingsChanged();
    }
  }

  /// Toggles requiring biometrics on app resume.
  Future<void> _toggleRequireBiometricsOnResume(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('requireBiometricsOnResume', value);
    if (mounted) {
      setState(() => _requireBiometricsOnResume = value);
      widget.onSettingsChanged();
    }
  }

  /// Shows a confirmation dialog for logging out.
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              widget.onLogout();
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to export data to a JSON file.
  ///
  /// Returns the exported file name if successful, null otherwise.
  Future<String?> _showExportDialog() async {
    _fileNameController.text = 'keyvault_backup_${_currentDatabase ?? "backup"}';
    final fileName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Data'),
        content: TextField(
          controller: _fileNameController,
          decoration: const InputDecoration(
            labelText: 'File Name',
            suffixText: '.json',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = _fileNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('File name cannot be empty')),
                );
                return;
              }
              Navigator.pop(dialogContext, name);
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (fileName == null || !mounted) return null;

    try {
      await ExportService.exportData(context, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
      return fileName;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
      return null;
    }
  }

  /// Shows a dialog to display the recovery key for the database.
  Future<void> _showRecoveryKeyDialog() async {
    if (_authService == null) return;
    final recoveryKey = await _authService!.getRecoveryKey();
    if (recoveryKey == null) {
      Fluttertoast.showToast(msg: 'Recovery key not set');
      return;
    }
    await showDialog(
      context: context,
      builder: (dialogContext) => RecoveryKeyDialog(
        recoveryKey: recoveryKey,
      ),
    );
  }

  /// Shows a dialog to reset the master credential (PIN or password).
  Future<void> _showResetMasterCredentialDialog() async {
    if (_authService == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => ResetCredentialDialog(
        authService: _authService!,
        isPinMode: _isPinMode,
        onResetSuccess: () {
          setState(() async {
            final isPin = await _authService!.isPinMode();
            _isPinMode = isPin;
          });
          widget.onLogout();
        },
      ),
    );
  }

  /// Shows a dialog to confirm database deletion, with an option to export data first.
  ///
  /// The user is first prompted to export their data. If they proceed, they must
  /// check a confirmation box and enter their PIN or password to delete the database.
  /// Upon successful deletion, the user is logged out.
  Future<void> _showDeleteDatabaseDialog() async {
    if (_authService == null || _currentDatabase == null) return;

    // Step 1: Show the export prompt dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Data Before Deletion'),
        content: const Text('Would you like to export your data before deleting the database? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false), // Cancel deletion
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true), // Skip export, proceed to deletion
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close this dialog
              final exportResult = await _showExportDialog();
              if (exportResult != null) {
                // Export successful, proceed to deletion confirmation
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _DeleteConfirmationDialog(
                        authService: _authService!,
                        isPinMode: _isPinMode,
                        currentDatabase: _currentDatabase!,
                        onDeleteSuccess: () {
                          Navigator.pop(context); // Close settings menu
                          widget.onLogout(); // Log out the user
                        },
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || !mounted) return;

    // Step 2: Show the deletion confirmation dialog if the user skipped export
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DeleteConfirmationDialog(
          authService: _authService!,
          isPinMode: _isPinMode,
          currentDatabase: _currentDatabase!,
          onDeleteSuccess: () {
            Navigator.pop(context); // Close settings menu
            widget.onLogout(); // Log out the user
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_authService == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.all(16.0).copyWith(top: 48.0),
          width: double.infinity,
          child: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ListTile(
                        title: const Text('Select Theme'),
                        trailing: DropdownButton<AppTheme>(
                          value: themeProvider.currentTheme,
                          onChanged: (AppTheme? newTheme) {
                            if (newTheme != null) {
                              themeProvider.setTheme(newTheme);
                            }
                          },
                          items: AppTheme.values.map((AppTheme theme) {
                            return DropdownMenuItem<AppTheme>(
                              value: theme,
                              child: Text(
                                theme.toString().split('.').last.replaceAllMapped(
                                  RegExp(r'([A-Z])'),
                                      (m) => ' ${m[1]}',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: Text('Change ${_isPinMode ? 'PIN' : 'Master Password'}'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangeLoginScreen(),
                        ),
                      );
                    },
                  ),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text('Recovery Options'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.vpn_key),
                          title: const Text('View Recovery Key'),
                          onTap: _showRecoveryKeyDialog,
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock_reset),
                          title: Text('Reset ${_isPinMode ? 'PIN' : 'Master Password'}'),
                          onTap: _showResetMasterCredentialDialog,
                        ),
                      ],
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Timeout Duration'),
                          subtitle: const Text('Log out after being in the background for this long'),
                          trailing: DropdownButton<int>(
                            value: _timeoutDuration,
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                _setTimeoutDuration(newValue);
                              }
                            },
                            items: List.generate(5, (index) => index + 1).map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value minute${value > 1 ? 's' : ''}'),
                              );
                            }).toList(),
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Lock immediately when sent to background'),
                          value: _lockImmediately,
                          onChanged: _toggleLockImmediately,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Require biometrics on resume'),
                          subtitle: const Text('Prompt for biometrics instead of logging out after timeout'),
                          value: _requireBiometricsOnResume,
                          onChanged: _biometricAvailable ? _toggleRequireBiometricsOnResume : null,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Colors.grey,
                        ),
                        SwitchListTile(
                          title: const Text('Enable Biometric Authentication'),
                          value: _biometricEnabled,
                          onChanged: _biometricAvailable ? _toggleBiometric : null,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text('Item Management'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.archive),
                          title: const Text('View Archived Items'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ArchivedItemsView(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('View Deleted Items'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DeletedItemsView(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text('Database Management'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: Colors.red),
                          title: const Text('Delete Database', style: TextStyle(color: Colors.red)),
                          onTap: _showDeleteDatabaseDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await ImportService.importData(context);
                                if (mounted) {
                                  final provider = Provider.of<CredentialProvider>(context, listen: false);
                                  await provider.loadCredentials();
                                  await provider.loadCreditCards();
                                  await provider.loadArchivedItems();
                                  await provider.loadDeletedItems();
                                }
                              } catch (e) {
                                String errorMessage = e.toString();
                                if (errorMessage.startsWith('Exception: ')) {
                                  errorMessage = errorMessage.substring('Exception: '.length);
                                }
                                Fluttertoast.showToast(msg: errorMessage);
                              }
                            },
                            child: const Text('Import'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: _showExportDialog,
                            child: const Text('Export'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A widget that displays a dialog to confirm database deletion with authentication.
class _DeleteConfirmationDialog extends StatefulWidget {
  final AuthService authService;
  final bool isPinMode;
  final String currentDatabase;
  final VoidCallback onDeleteSuccess;

  const _DeleteConfirmationDialog({
    required this.authService,
    required this.isPinMode,
    required this.currentDatabase,
    required this.onDeleteSuccess,
  });

  @override
  State<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final TextEditingController _credentialController = TextEditingController();
  bool _isConfirmed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _credentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Database'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to delete this database? This action cannot be undone.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isConfirmed,
                onChanged: (value) {
                  setState(() {
                    _isConfirmed = value ?? false;
                  });
                },
              ),
              const Text('I understand this action is permanent'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _credentialController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: widget.isPinMode ? 'PIN' : 'Password',
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
            keyboardType: widget.isPinMode ? TextInputType.number : TextInputType.text,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isConfirmed
              ? () async {
            final input = _credentialController.text.trim();
            if (input.isEmpty) {
              setState(() {
                _errorMessage = 'Please enter your ${widget.isPinMode ? 'PIN' : 'password'}';
              });
              return;
            }

            final isAuthenticated = await widget.authService.verifyMasterCredential(input);
            if (!isAuthenticated) {
              setState(() {
                _errorMessage = 'Incorrect ${widget.isPinMode ? 'PIN' : 'password'}';
              });
              return;
            }

            try {
              // Delete the database
              final dbHelper = DatabaseHelper(widget.currentDatabase);
              final provider = Provider.of<CredentialProvider>(context, listen: false);
              await provider.clearAllData(); // Clear in-memory data
              await (await dbHelper.database).close(); // Close the database
              await dbHelper.deleteDatabase(); // Delete the database file

              // Clear the current database from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('currentDatabase');

              // Reset CredentialProvider
              provider.setDatabaseName('default');

              if (mounted) {
                Navigator.pop(context); // Close this dialog
                Fluttertoast.showToast(msg: 'Database deleted successfully');
                widget.onDeleteSuccess(); // Trigger logout
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Error deleting database: $e';
                });
              }
            }
          }
              : null,
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
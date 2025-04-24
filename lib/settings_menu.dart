import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/theme/theme_provider.dart';
import 'package:keyvalut/views/screens/archived_credentials_screen.dart';
import 'package:keyvalut/views/screens/change_login_screen.dart';
import 'package:keyvalut/views/screens/deleted_credentials_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/services/export_services.dart';
import 'package:keyvalut/services/import_service.dart';
import 'package:keyvalut/data/credential_provider.dart';
import 'package:keyvalut/data/credential_model.dart';

class SettingsMenu extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onSettingsChanged;

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
  final TextEditingController _recoveryKeyController = TextEditingController();
  final TextEditingController _newCredentialController = TextEditingController();
  final TextEditingController _confirmNewCredentialController = TextEditingController();
  String? _currentDatabase;
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

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

  @override
  void dispose() {
    _fileNameController.dispose();
    _recoveryKeyController.dispose();
    _newCredentialController.dispose();
    _confirmNewCredentialController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentialMode() async {
    if (_authService == null) return;
    final isPin = await _authService!.isPinMode();
    if (mounted) {
      setState(() => _isPinMode = isPin);
    }
  }

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

  Future<void> _toggleBiometric(bool value) async {
    if (_authService == null) return;
    await _authService!.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _biometricEnabled = value);
      widget.onSettingsChanged();
    }
  }

  Future<void> _setTimeoutDuration(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timeoutDuration', value);
    if (mounted) {
      setState(() => _timeoutDuration = value);
      widget.onSettingsChanged();
    }
  }

  Future<void> _toggleLockImmediately(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lockImmediately', value);
    if (mounted) {
      setState(() => _lockImmediately = value);
      widget.onSettingsChanged();
    }
  }

  Future<void> _toggleRequireBiometricsOnResume(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('requireBiometricsOnResume', value);
    if (mounted) {
      setState(() => _requireBiometricsOnResume = value);
      widget.onSettingsChanged();
    }
  }

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

  Future<void> _showExportDialog() async {
    _fileNameController.text = 'keyvault_backup';
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

    if (fileName == null || !mounted) return;

    try {
      await ExportService.exportData(context, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  Future<void> _showRecoveryKeyDialog() async {
    if (_authService == null) return;
    final recoveryKey = await _authService!.getRecoveryKey();
    if (recoveryKey == null) {
      Fluttertoast.showToast(msg: 'Recovery key not set');
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recovery Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is your recovery key. Store it in a safe place. You will need it to reset your master credential if you forget it.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SelectableText(
              recoveryKey,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetMasterCredentialDialog() async {
    if (_authService == null) return;
    _recoveryKeyController.clear();
    _newCredentialController.clear();
    _confirmNewCredentialController.clear();
    bool obscureNewCredential = true;
    bool obscureConfirmNewCredential = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Reset Master Credential'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _recoveryKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newCredentialController,
                  obscureText: obscureNewCredential,
                  keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: _isPinMode ? 'New PIN' : 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewCredential ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureNewCredential = !obscureNewCredential);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmNewCredentialController,
                  obscureText: obscureConfirmNewCredential,
                  keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: _isPinMode ? 'Confirm New PIN' : 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmNewCredential ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureConfirmNewCredential = !obscureConfirmNewCredential);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final recoveryKey = _recoveryKeyController.text.trim();
                final newCredential = _newCredentialController.text;
                final confirmNewCredential = _confirmNewCredentialController.text;

                if (recoveryKey.isEmpty) {
                  Fluttertoast.showToast(msg: 'Recovery key is required');
                  return;
                }
                if (newCredential.isEmpty) {
                  Fluttertoast.showToast(msg: 'New ${_isPinMode ? 'PIN' : 'password'} is required');
                  return;
                }
                if (_isPinMode) {
                  if (newCredential.length < 6) {
                    Fluttertoast.showToast(msg: 'PIN must be at least 6 digits');
                    return;
                  }
                  if (!RegExp(r'^\d+$').hasMatch(newCredential)) {
                    Fluttertoast.showToast(msg: 'PIN must be numeric');
                    return;
                  }
                } else {
                  if (newCredential.length < 8) {
                    Fluttertoast.showToast(msg: 'Password must be at least 8 characters');
                    return;
                  }
                }
                if (newCredential != confirmNewCredential) {
                  Fluttertoast.showToast(msg: 'Credentials do not match');
                  return;
                }

                try {
                  await _authService!.resetMasterCredentialWithRecoveryKey(
                    recoveryKey,
                    newCredential,
                    isPin: _isPinMode,
                  );
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    Fluttertoast.showToast(msg: 'Master credential reset successfully');
                    widget.onLogout(); // Log out to force re-authentication
                  }
                } catch (e) {
                  if (mounted) {
                    Fluttertoast.showToast(msg: e.toString());
                  }
                }
              },
              child: const Text('Reset'),
            ),
          ],
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
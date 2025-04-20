import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/theme/theme_provider.dart';
import 'package:keyvalut/views/screens/archived_credentials_screen.dart';
import 'package:keyvalut/views/screens/change_password_screen.dart';
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
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
    _loadTimeoutSettings();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricSettings() async {
    final authService = AuthService();
    final available = await authService.isBiometricAvailable();
    final enabled = await authService.isBiometricEnabled();
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
    final authService = AuthService();
    await authService.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _biometricEnabled = value);
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

  Future<void> _showExportDialog(BuildContext context) async {
    _fileNameController.text = 'credentials'; // Default file name
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final fileName = _fileNameController.text.trim();
              if (fileName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File name cannot be empty')),
                );
                return;
              }
              try {
                await ExportService.exportData(context, fileName);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error exporting data: $e')),
                );
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showImportConfirmationDialog(int count) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Text('The file contains $count items. Do you want to import them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    title: const Text('Change Master Password'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
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
                                  Provider.of<CredentialProvider>(context, listen: false).loadCredentials();
                                  Provider.of<CredentialProvider>(context, listen: false).loadCreditCards();
                                  Provider.of<CredentialProvider>(context, listen: false).loadArchivedItems();
                                  Provider.of<CredentialProvider>(context, listen: false).loadDeletedItems();
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
                            onPressed: () => _showExportDialog(context),
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
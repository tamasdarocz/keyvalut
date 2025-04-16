import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/data/credentialProvider.dart';
import 'package:keyvalut/services/import_service.dart';
import '../../data/credential_model.dart';
import '../../data/database_helper.dart';
import '../../services/auth_service.dart';
import '../../services/export_services.dart';
import '../../theme/theme_provider.dart';
import 'first_tab.dart';
import 'second_tab.dart';
import 'third_tab.dart';
import '../Widgets/create_element_form.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentPageIndex = 0;
  final List<Widget> _pages = const [
    FirstTab(),
    SecondTab(),
    ThirdTab(),
  ];
  final List<String> _tabTitles = ['Passwords', 'Authenticator', 'API Keys'];
  int _timeoutDuration = 1;
  bool _lockImmediately = false;
  bool _requireBiometricsOnResume = false;
  static const int _gracePeriodSeconds = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _timeoutDuration = prefs.getInt('timeoutDuration') ?? 1;
      _lockImmediately = prefs.getBool('lockImmediately') ?? false;
      _requireBiometricsOnResume = prefs.getBool('requireBiometricsOnResume') ?? false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    if (state == AppLifecycleState.paused) {
      await prefs.setInt('backgroundTimestamp', DateTime.now().millisecondsSinceEpoch);
      if (_lockImmediately) {
        _logout(context);
      }
    } else if (state == AppLifecycleState.resumed) {
      final timestamp = prefs.getInt('backgroundTimestamp');
      if (timestamp == null) return;

      final elapsedSeconds = (DateTime.now().millisecondsSinceEpoch - timestamp) ~/ 1000;
      if (elapsedSeconds < _gracePeriodSeconds) return;

      if (_lockImmediately) return;

      final timeoutSeconds = _timeoutDuration * 60;
      if (elapsedSeconds >= timeoutSeconds) {
        if (_requireBiometricsOnResume) {
          final authService = AuthService();
          final authenticated = await authService.authenticateWithBiometrics(
            reason: 'Please authenticate to continue using the app',
          );
          if (authenticated) {
            await prefs.remove('backgroundTimestamp');
            return;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session timed out. Please log in again.')),
          );
          _logout(context);
        }
      }
      await prefs.remove('backgroundTimestamp');
    }
  }

  void _logout(BuildContext context) {
    final credentialProvider = Provider.of<CredentialProvider>(context, listen: false);
    credentialProvider.clearCredentials();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  void _navigateBottomBar(int index) => setState(() => _currentPageIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_tabTitles[_currentPageIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open settings',
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: Drawer(
        child: SettingsMenu(
          onLogout: () => _logout(context),
          onSettingsChanged: _loadSettings,
        ),
      ),
      body: _pages[_currentPageIndex],
      floatingActionButton: _currentPageIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateElementForm(dbHelper: DatabaseHelper.instance),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        onTap: _navigateBottomBar,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.key), label: 'Passwords'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Authenticator'),
          BottomNavigationBarItem(icon: Icon(Icons.code), label: 'API Keys'),
        ],
      ),
    );
  }
}

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
        title: const Text('Export Credentials'),
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
                final CredentialProvider provider = Provider.of<CredentialProvider>(context, listen: false);
                final List<Credential> credentials = provider.credentials;
                await ExportService.exportCredentials(
                  context,
                  credentials,
                  fileName,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error exporting credentials: $e')),
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
        title: const Text('Import Credentials'),
        content: Text('The file contains $count credentials. Do you want to import them?'),
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
        // Drawer header
        Container(
          color: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.all(16.0).copyWith(top: 48.0),
          width: double.infinity,
          child: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                  // Import and Export buttons in a row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                final credentials = await ImportService.importCredentials(context);
                                final count = credentials.length;
                                final confirm = await _showImportConfirmationDialog(count);
                                if (confirm != true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Import canceled')),
                                  );
                                  return;
                                }
                                final provider = Provider.of<CredentialProvider>(context, listen: false);
                                for (var credential in credentials) {
                                  await provider.addCredential(credential);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Credentials imported successfully')),
                                );
                              } catch (e) {
                                String errorMessage = e.toString();
                                if (errorMessage.startsWith('Exception: ')) {
                                  errorMessage = errorMessage.substring('Exception: '.length);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorMessage)),
                                );
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
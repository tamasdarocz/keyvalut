import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database_helper.dart';
import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';
import 'first_tab.dart';
import 'second_tab.dart';
import 'third_tab.dart';
import '../Widgets/create_element_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPageIndex = 0;
  final List<Widget> _pages = const [
    FirstTab(),
    SecondTab(),
    ThirdTab(),
  ];
  final List<String> _tabTitles = ['Passwords', 'Authenticator', 'API Keys'];

  void _navigateBottomBar(int index) => setState(() => _currentPageIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_tabTitles[_currentPageIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const SettingsMenu(),
              );
            },
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
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
        selectedItemColor: Colors.amber,
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
  const SettingsMenu({super.key});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
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

  Future<void> _toggleBiometric(bool value) async {
    final authService = AuthService();
    await authService.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _biometricEnabled = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
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
              ),
              SwitchListTile(
                title: const Text('Enable Biometric Authentication'),
                value: _biometricEnabled,
                onChanged: _biometricAvailable ? _toggleBiometric : null,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }
}
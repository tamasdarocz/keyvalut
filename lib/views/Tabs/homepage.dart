import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/data/credential_provider.dart';
import '../../data/database_helper.dart';
import '../../settings_menu.dart';
import 'first_tab.dart';
import 'second_tab.dart';
import 'third_tab.dart';
import '../textforms/create_element_form.dart';
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
    // Existing lifecycle code...
    // (Keep this method unchanged)
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
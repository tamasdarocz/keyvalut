import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/data/credential_provider.dart';
import '../../settings_menu.dart';
import 'credentials_tab.dart';
import 'notes_page.dart';
import 'payments_tab.dart';
import '../textforms/create_element_form.dart';
import 'login_screen.dart';
import '../../data/database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static bool isFilePickerActive = false;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentPageIndex = 0;
  final List<Widget> _pages = const [
    CredentialsTab(),
    PaymentsTab(),
    NotesPage(),
  ];
  final List<String> _tabTitles = ['Passwords', 'Payments', 'Notes'];
  int _timeoutDuration = 1;
  bool _lockImmediately = false;
  bool _requireBiometricsOnResume = false;
  static const int _gracePeriodSeconds = 5;
  bool _shouldLock = false;
  String? _currentDatabase;
  DatabaseHelper? _dbHelper;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadDatabase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseName = prefs.getString('currentDatabase');
    if (databaseName != null) {
      setState(() {
        _currentDatabase = databaseName;
        _dbHelper = DatabaseHelper(databaseName);
        // Ensure CredentialProvider uses the same database
        Provider.of<CredentialProvider>(context, listen: false).setDatabaseName(databaseName);
      });
    } else {
      // If no database is set, redirect to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
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
    if (state == AppLifecycleState.paused) {
      final prefs = await SharedPreferences.getInstance();
      final lockImmediately = prefs.getBool('lockImmediately') ?? false;
      if (lockImmediately && !HomePage.isFilePickerActive) {
        setState(() {
          _shouldLock = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_shouldLock) {
        setState(() {
          _shouldLock = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
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
    if (_dbHelper == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              builder: (context) => CreateElementForm(dbHelper: _dbHelper!),
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
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
        ],
      ),
    );
  }
}
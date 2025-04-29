import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/data/database_provider.dart';
import '../../settings_menu.dart';
import 'credentials_tab.dart';
import 'notes_page.dart';
import 'payments_tab.dart';
import '../textforms/create_element_form.dart';
import 'login_screen.dart';
import '../../data/database_helper.dart';

/// The main home page of the app, displaying tabs for credentials, payments, and notes.
///
/// This page includes a bottom navigation bar to switch between tabs and a drawer
/// for accessing the settings menu. It also handles app lifecycle events to manage
/// locking behavior based on user settings.
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

  /// Loads the current database name and initializes the [DatabaseHelper].
  ///
  /// Retrieves the current database name from [SharedPreferences] and sets up
  /// the [DatabaseHelper]. Updates the [DatabaseProvider] with the same database
  /// name. If no database is set, redirects to the login screen.
  Future<void> _loadDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseName = prefs.getString('currentDatabase');
    if (databaseName != null) {
      setState(() {
        _currentDatabase = databaseName;
        _dbHelper = DatabaseHelper(databaseName);
        // Ensure DatabaseProvider uses the same database
        Provider.of<DatabaseProvider>(context, listen: false).setDatabaseName(databaseName);
      });
    } else {
      // If no database is set, redirect to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  /// Loads app settings from [SharedPreferences].
  ///
  /// Retrieves the timeout duration, immediate lock setting, and biometrics on
  /// resume setting, and updates the state.
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

  /// Logs the user out and navigates to the login screen.
  ///
  /// - [context]: The build context for navigation.
  void _logout(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  /// Updates the current tab index in the bottom navigation bar.
  ///
  /// - [index]: The index of the tab to navigate to.
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
        title: Consumer<DatabaseProvider>(
          builder: (context, provider, child) {
            // Update _dbHelper if the database name has changed
            if (_dbHelper!.databaseName != provider.databaseName) {
              _dbHelper = DatabaseHelper(provider.databaseName);
              _currentDatabase = provider.databaseName;
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  provider.databaseName.isNotEmpty ? provider.databaseName : 'KeyVault',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _tabTitles[_currentPageIndex],
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            );
          },
        ),
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
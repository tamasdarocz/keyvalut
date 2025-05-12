import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/theme/theme_provider.dart';
import 'package:keyvalut/views/Tabs/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/database_provider.dart';
import 'services/utils.dart';
import 'data/database_helper.dart';

// LockService to manage all lock-related logic
class LockService {
  static const _lockImmediatelyKey = 'lockImmediately';
  static const _appLockedKey = 'appLocked';
  final SharedPreferences _prefs;
  final LockState _lockState;

  LockService(this._prefs, this._lockState);

  Future<bool> shouldLockImmediately() async {
    try {
      return _prefs.getBool(_lockImmediatelyKey) ?? false;
    } catch (e) {
      debugPrint('LockService: Error reading lockImmediately: $e');
      return false;
    }
  }

  Future<void> setLockImmediately(bool value) async {
    try {
      await _prefs.setBool(_lockImmediatelyKey, value);
      debugPrint('LockService: Set lockImmediately to $value');
    } catch (e) {
      debugPrint('LockService: Error setting lockImmediately: $e');
    }
  }

  Future<void> setAppLocked(bool value) async {
    try {
      await _prefs.setBool(_appLockedKey, value);
      debugPrint('LockService: Set appLocked to $value');
    } catch (e) {
      debugPrint('LockService: Error saving appLocked state: $e');
    }
  }

  Future<bool> isAppLocked() async {
    try {
      return _prefs.getBool(_appLockedKey) ?? false;
    } catch (e) {
      debugPrint('LockService: Error reading appLocked state: $e');
      return false;
    }
  }

  void handleLifecycleState(AppLifecycleState state) {
    debugPrint('LockService: Handling lifecycle state $state');
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        shouldLockImmediately().then((lockImmediately) {
          if (lockImmediately) {
            _lockState.scheduleLock(const Duration(milliseconds: 500));
            setAppLocked(true);
          }
        });
        break;
      case AppLifecycleState.resumed:
        if (_lockState.shouldLock) {
          _lockState.triggerRefresh();
          setAppLocked(false);
        }
        break;
      case AppLifecycleState.detached:
        debugPrint('LockService: App detached');
        break;
      default:
        break;
    }
  }
}

// LockState to manage lock-related state with Provider
class LockState extends ChangeNotifier {
  LockState() {
    _init();
  }
  LockService? _lockService;
  bool _shouldLock = false;
  bool _needsRefresh = false;
  Timer? _lockTimer;

  bool get shouldLock => _shouldLock;
  bool get needsRefresh => _needsRefresh;

  // Initialize lock state and load persisted state
  Future<void> _init() async {
    if (_lockService != null) {
      _shouldLock = await _lockService!.isAppLocked();
      if (_shouldLock) {
        _needsRefresh = true;
        notifyListeners();
        debugPrint('LockState: Restored shouldLock=$_shouldLock, needsRefresh=$_needsRefresh');
      }
    }
  }

  // Set lock service after construction
  void setLockService(LockService lockService) {
    _lockService = lockService;
    _init();
  }

  void setShouldLock(bool value) {
    _lockTimer?.cancel();
    _shouldLock = value;
    notifyListeners();
    debugPrint('LockState: Set shouldLock to $_shouldLock');
  }

  void scheduleLock(Duration delay) {
    _lockTimer?.cancel();
    _lockTimer = Timer(delay, () {
      setShouldLock(true);
    });
  }

  void triggerRefresh() {
    _lockTimer?.cancel();
    _needsRefresh = true;
    _shouldLock = false;
    notifyListeners();
    debugPrint('LockState: Triggered refresh, reset shouldLock');
  }

  void resetRefresh() {
    _needsRefresh = false;
    notifyListeners();
    debugPrint('LockState: Reset needsRefresh');
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialDatabaseName = await getInitialDatabaseName();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => DatabaseProvider(initialDatabaseName: initialDatabaseName),
        ),
        ChangeNotifierProvider(create: (context) => LockState()),
        Provider(
          create: (context) {
            final lockState = Provider.of<LockState>(context, listen: false);
            final lockService = LockService(prefs, lockState);
            lockState.setLockService(lockService);
            return lockService;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// Retrieves the initial database name to use when the app starts.
Future<String?> getInitialDatabaseName() async {
  final databases = await fetchDatabaseNames();
  final prefs = await SharedPreferences.getInstance();
  final currentDatabase = prefs.getString('currentDatabase');

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

  if (validDatabases.isEmpty) {
    await prefs.remove('currentDatabase');
    return null;
  }
  if (currentDatabase != null && !validDatabases.contains(currentDatabase)) {
    await prefs.setString('currentDatabase', validDatabases.first);
    return validDatabases.first;
  }
  return validDatabases.isNotEmpty ? currentDatabase : null;
}

/// The root widget of the KeyVault app.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('MyApp: Initialized lifecycle observer');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('MyApp: Disposed lifecycle observer');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockService = Provider.of<LockService>(context, listen: false);
    lockService.handleLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LockState>(
      builder: (context, themeProvider, lockState, child) {
        if (!themeProvider.isInitialized) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          themeMode: themeProvider.themeMode,
          home: FutureBuilder<String?>(
            key: ValueKey(lockState.needsRefresh),
            future: SharedPreferences.getInstance().then((prefs) => prefs.getString('currentDatabase')),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error initializing app'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            await FlutterSecureStorage().deleteAll();
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const MyApp()),
                              );
                            }
                          },
                          child: const Text('Reset and Restart'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              lockState.resetRefresh();
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:keyvalut/features/auth/services/auth_service.dart';
import 'package:keyvalut/features/ui/theme/theme_provider.dart';
import 'package:keyvalut/features/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/database_helper.dart';
import 'core/services/database_provider.dart';
import 'features/settings/services/utils.dart';
import 'features/auth/services/lock_service.dart';

/// Entry point for the KeyVault app. Initializes dependencies and runs the app.
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
        ChangeNotifierProvider(create: (context) => AppLockState()),
        Provider(
          create: (context) {
            final lockState = Provider.of<AppLockState>(context, listen: false);
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
/// Returns null if no valid databases exist.
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

/// Manages app lifecycle and UI for KeyVault.
class _MyAppState extends State<MyApp> {
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    final lockService = Provider.of<LockService>(context, listen: false);
    _lifecycleListener = AppLifecycleListener(
      onStateChange: lockService.handleLifecycleState,
      onResume: () {},
      onInactive: () {},
      onPause: () {},
      onDetach: () {},
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AppLockState>(
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
            key: ValueKey('database_${lockState.needsRefresh.hashCode}'),
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
              return LoginScreen();
            },
          ),
        );
      },
    );
  }
}
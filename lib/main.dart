import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:keyvalut/theme/theme_provider.dart';
import 'package:keyvalut/views/Tabs/login_screen.dart';
import 'package:keyvalut/views/Tabs/setup_login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/credential_provider.dart';
import 'services/utils.dart';
import 'data/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialDatabaseName = await getInitialDatabaseName();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => CredentialProvider(initialDatabaseName: initialDatabaseName),
        ),
        // Removed Provider for AuthService
      ],
      child: const MyApp(),
    ),
  );
}

Future<String?> getInitialDatabaseName() async {
  final databases = await fetchDatabaseNames();
  final prefs = await SharedPreferences.getInstance();
  return databases.isNotEmpty ? prefs.getString('currentDatabase') : null;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _needsRefresh = false;
  bool _shouldLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      final prefs = await SharedPreferences.getInstance();
      final lockImmediately = prefs.getBool('lockImmediately') ?? false;
      if (lockImmediately) {
        setState(() {
          _shouldLock = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_shouldLock) {
        setState(() {
          _needsRefresh = true;
          _shouldLock = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
            key: ValueKey(_needsRefresh),
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
              _needsRefresh = false;
              final databaseName = snapshot.data;
              if (databaseName == null) {
                return SetupLoginScreen(
                  onCallback: () {
                    // Refresh the app state after creating a new database
                    if (mounted) {
                      setState(() {});
                    }
                  },
                );
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
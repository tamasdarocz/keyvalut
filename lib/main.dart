import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:keyvalut/services/auth_service.dart';
import 'package:keyvalut/theme/theme_provider.dart';
import 'package:keyvalut/views/Tabs/login_screen.dart';
import 'package:keyvalut/views/screens/setup_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/credential_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CredentialProvider()),
        Provider(create: (_) => authService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          home: FutureBuilder<bool>(
            future: context.read<AuthService>().isMasterPasswordSet(),
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
              return snapshot.data! ? const LoginScreen() : const SetupMasterPasswordScreen();
            },
          ),
        );
      },
    );
  }
}
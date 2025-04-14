import 'package:flutter/material.dart';
import 'package:keyvalut/theme/theme_provider.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';
import 'package:keyvalut/views/Tabs/login_screen.dart';
import 'package:keyvalut/views/Tabs/setup_password_screen.dart';
import 'package:provider/provider.dart';

import 'Clients/auth_service.dart';
import 'data/credentialProvider.dart';

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

ThemeData _buildLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.light(
      primary: Colors.amber,
      secondary: Colors.amber[200]!,
      surface: Colors.white,
      background: Colors.grey[50]!,
    ),
    // Add other light theme customizations
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.dark(
      primary: Colors.amber,
      secondary: Colors.amber[800]!,
      surface: Colors.black,
    ),

    cardColor: Colors.grey,
    useMaterial3: true,

  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
      // Explicit return for all code paths
      if (!themeProvider.isInitialized) {
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      // Explicit return for initialized state
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: themeProvider.themeMode,
        home: FutureBuilder(
          future: context.read<AuthService>().isMasterPasswordSet(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            return snapshot.data!
                ? const LoginScreen()
                : const SetupMasterPasswordScreen();
          },
        ),
      );
        },
    );
  }
}
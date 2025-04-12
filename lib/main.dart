import 'package:flutter/material.dart';
import 'package:keyvalut/views/Tabs/homepage.dart';
import 'package:provider/provider.dart';

import 'data/credentialManager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }

}

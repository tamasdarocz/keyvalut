import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database_helper.dart';
import '../textforms/create_element_form.dart';
import '../Widgets/credentials_widget.dart';

class CredentialsTab extends StatefulWidget {
  const CredentialsTab({super.key});

  @override
  State<CredentialsTab> createState() => _CredentialsTabState();
}

class _CredentialsTabState extends State<CredentialsTab> {
  String? _currentDatabase;
  DatabaseHelper? _dbHelper;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseName = prefs.getString('currentDatabase');
    if (databaseName != null) {
      setState(() {
        _currentDatabase = databaseName;
        _dbHelper = DatabaseHelper(databaseName);
      });
    } else {
      // Redirect to login if no database is set
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dbHelper == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'create',
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
      ),
      body: const CredentialsWidget(),
    );
  }
}
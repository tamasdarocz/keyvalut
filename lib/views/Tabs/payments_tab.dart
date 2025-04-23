import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/views/Widgets/card_list_view.dart';
import 'package:keyvalut/views/textforms/card_input_form.dart';
import '../../data/database_helper.dart';
import '../Widgets/credentials_widget.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
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
              builder: (context) => CardInputForm(
                dbHelper: _dbHelper!,
                card: null,
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: CardListView(),
    );
  }
}
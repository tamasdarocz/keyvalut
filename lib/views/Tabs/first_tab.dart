import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database_helper.dart';
import '../../theme/theme_provider.dart';
import '../Widgets/create_element_form.dart';
import '../Widgets/credentials_widget.dart';

class FirstTab extends StatefulWidget {
  const FirstTab({super.key});

  @override
  State<FirstTab> createState() => _FirstTabState();
}

class _FirstTabState extends State<FirstTab> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateElementForm(dbHelper: DatabaseHelper.instance),
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
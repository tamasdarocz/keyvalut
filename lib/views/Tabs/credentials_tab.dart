import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
import '../textforms/create_element_form.dart';
import '../Widgets/credentials_widget.dart';

class CredentialsTab extends StatefulWidget {
  const CredentialsTab({super.key});

  @override
  State<CredentialsTab> createState() => _CredentialsTabState();
}

class _CredentialsTabState extends State<CredentialsTab> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'create',
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
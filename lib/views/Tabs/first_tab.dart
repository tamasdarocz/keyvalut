import 'package:flutter/material.dart';
import '../../data/database_helper.dart';
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
      appBar: AppBar(
        centerTitle: true,
        title: Text('Passwords'),
        backgroundColor: Colors.amber,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateElementForm(dbHelper: DatabaseHelper.instance),
            ),
          );
        },
        backgroundColor: Colors.amber,
        child: Icon(Icons.add),
      ),
      body: CredentialsWidget(),
    );
  }
}

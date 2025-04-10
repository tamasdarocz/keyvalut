import 'package:flutter/material.dart';
import 'package:keyvalut/data/credentials.dart';

import '../Widgets/create_element_view.dart';

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
            Navigator.push(context, MaterialPageRoute(builder: (context) => CreateElementForm()),
            );
          },
          backgroundColor: Colors.amber,
          child: Icon(Icons.add)),
      body: CredentialsWidget(credentials: dummyCredentials)

    );
  }
}

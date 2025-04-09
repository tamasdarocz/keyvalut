import 'package:flutter/material.dart';
import 'package:keyvalut/Widgets/password_text_field.dart';

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
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Divider(height: 10, color: Colors.white),

          TextField(
            scrollPadding: EdgeInsets.all(50),
            style: TextStyle(fontSize: 20),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.devices),
              label: Text('Platform:'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(48),
                borderSide: BorderSide(color: Colors.amber, width: 4),
              ),
            ),
          ),

          Divider(height: 10, color: Colors.white),

          TextField(
            style: TextStyle(fontSize: 20),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.email),
              label: Text('Email:'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(48),
                borderSide: BorderSide(color: Colors.amber, width: 4),
              ),
            ),
          ),

          Divider(height: 10, color: Colors.white),

          TextField(
            style: TextStyle(fontSize: 20),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person),
              label: Text('Username'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(48),
                borderSide: BorderSide(color: Colors.amber, width: 4),
              ),
            ),
          ),

          Divider(height: 10, color: Colors.white),

          TextField(
            style: TextStyle(fontSize: 20),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.alternate_email),
              label: Text('Website'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(48),
                borderSide: BorderSide(color: Colors.amber, width: 4),
              ),
            ),
          ),

          Divider(height: 10, color: Colors.white),

          PasswordTextField()
        ],
      ),
    );
  }
}

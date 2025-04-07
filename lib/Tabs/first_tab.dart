import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:keyvalut/data/database.dart';

class FirstTab extends StatefulWidget {
  @override
  State<FirstTab> createState() => _FirstTabState();
}

class _FirstTabState extends State<FirstTab> {
  bool _showPassword = false;

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

          TextField(
            style: TextStyle(fontSize: 20),
            obscureText: !this._showPassword,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.key),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.remove_red_eye,
                  color: this._showPassword ? Colors.amber : Colors.grey,
                ),
                onPressed: () {
                  setState(() => this._showPassword = !this._showPassword);
                },
              ),
              label: Text('Password'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(48),
                borderSide: BorderSide(color: Colors.amber, width: 4),
              ),
            ),
          ),

          IconButton(onPressed: () {} , icon: Icon(Icons.add)),



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
        ],
      ),
    );
  }
}

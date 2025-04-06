import 'package:flutter/material.dart';

class FirstTab extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Passwords'),
        backgroundColor: Colors.amber),
      body: Text('data'));
  }
}
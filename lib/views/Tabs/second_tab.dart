import 'package:flutter/material.dart';

class SecondTab extends StatelessWidget{
  const SecondTab({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: Text('Authenticator'),
            backgroundColor: Colors.amber),
        body: Text(''));
  }
}

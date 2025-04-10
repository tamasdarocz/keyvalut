import 'package:flutter/material.dart';

class ThirdTab extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar : AppBar (
           centerTitle: true,
           title: Text('Api keys'),
           backgroundColor: Colors.amber),
      body: Text('3')
    );
  }
}
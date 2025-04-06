import 'package:flutter/material.dart';

class ThirdTab extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Center(
appBar: AppBar (
centerTitle: true,
title: Text('Passwords'),
backgroundColor: Colors.amber)
      child: Text('3'),
    );
  }
}
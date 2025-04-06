import 'package:flutter/material.dart';

class ThirdTab extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Center(
appBar: AppBar (
centerTitle: true,
title: Text('Api keys'),
backgroundColor: Colors.amber)
      child: Text('3'),
    );
  }
}
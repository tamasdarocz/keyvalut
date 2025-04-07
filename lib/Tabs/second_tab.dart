import 'package:flutter/material.dart';

class SecondTab extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
   return Center(
							appBar: AppBar (
							centerTitle: true,
			title: Text('Authenticator'),
							backgroundColor: Colors.amber),
  	child: Text('2'),
    );
  }
}
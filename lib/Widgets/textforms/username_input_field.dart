import 'package:flutter/material.dart';

class UsernameInputField extends StatelessWidget{
  const UsernameInputField({super.key});


  @override
  Widget build(BuildContext context) {
   return TextField(
     style: TextStyle(fontSize: 20),
     decoration: InputDecoration(
       prefixIcon: Icon(Icons.person),
       label: Text('Username'),
       border: OutlineInputBorder(
         borderRadius: BorderRadius.circular(48),
         borderSide: BorderSide(color: Colors.amber, width: 4),
       ),
     ),
   );
  }}



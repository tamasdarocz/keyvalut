import 'package:flutter/material.dart';

class EmailInputField extends StatelessWidget {
   const EmailInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return  TextField(
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.email),
        label: Text('Email:'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48),
          borderSide: BorderSide(color: Colors.amber, width: 4),
        ),
      ),
    );
  }

}
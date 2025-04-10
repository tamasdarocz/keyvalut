import 'package:flutter/material.dart';

class EmailInputField extends StatefulWidget {
  final TextEditingController controller;
  const EmailInputField({super.key, required this.controller});

  @override
  State<EmailInputField> createState() => _EmailInputFieldState();
}

class _EmailInputFieldState extends State<EmailInputField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextStyle(fontSize: 20),
      keyboardType: TextInputType.emailAddress,
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

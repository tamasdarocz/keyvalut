import 'package:flutter/material.dart';

class UsernameInputField extends StatefulWidget {
  final TextEditingController controller;
  const UsernameInputField({super.key, required this.controller});

  @override
  State<UsernameInputField> createState() => _UsernameInputFieldState();
}

class _UsernameInputFieldState extends State<UsernameInputField> {
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
  }
}

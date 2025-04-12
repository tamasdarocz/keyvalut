import 'package:flutter/material.dart';

class UsernameInputField extends StatelessWidget {
  final TextEditingController controller;
  const UsernameInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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

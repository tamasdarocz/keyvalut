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
        hintText: 'Required',
        label: Text('Username (Required)'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4),
        ),
      ),
    );
  }
}

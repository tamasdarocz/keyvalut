import 'package:flutter/material.dart';

class EmailInputField extends StatelessWidget {
  final TextEditingController controller;
  const EmailInputField({super.key, required this.controller});


  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,

      decoration: InputDecoration(
        prefixIcon: Icon(Icons.email),
        label: Text('Email'),
        border: OutlineInputBorder(
          borderSide: BorderSide(color:Theme.of(context).colorScheme.primary, width: 1),
        ),
      ),
    );
  }
}

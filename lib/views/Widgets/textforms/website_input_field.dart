import 'package:flutter/material.dart';

class WebsiteInputField extends StatelessWidget {
  final TextEditingController controller;

  const WebsiteInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 20),
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.http),
          hintText: 'google.com',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color:Theme.of(context).colorScheme.primary, width: 4),
          ),
          label: const Text('Website'),
        ));
  }
}

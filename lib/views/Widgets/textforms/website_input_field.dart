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
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final cleaned = value
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'^https?://'), '')
              .replaceAll(RegExp(r'^www\.'), '');

          if (RegExp(r'^([a-z0-9-]+\.)+[a-z]{2,}(/.*)?$').hasMatch(cleaned)) {
            return 'Enter domain like: google.com';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.http),
        hintText: 'google.com',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48),
          borderSide: const BorderSide(color: Colors.amber, width: 4),
        ),
        label: const Text('Website'),
      ),
    );
  }
}
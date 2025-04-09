import 'package:flutter/material.dart';


class PlatformInputField extends StatelessWidget {
  const PlatformInputField({super.key});


  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.devices),
        label: Text('Platform:'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48),
          borderSide: BorderSide(color: Colors.amber, width: 4),
        ),
      ),
    );
  }
}


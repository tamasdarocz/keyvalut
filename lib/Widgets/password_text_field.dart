import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {

    return TextField(
      style: TextStyle(fontSize: 20),
      obscureText: !_showPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.key),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.remove_red_eye,
            color: _showPassword ? Colors.amber : Colors.grey,
          ),
          onPressed: () {
            setState(() => _showPassword = !_showPassword);
          },
        ),
        label: Text('Password'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(48),
          borderSide: BorderSide(color: Colors.amber, width: 4),
        ),
      ),
    );
  }
}
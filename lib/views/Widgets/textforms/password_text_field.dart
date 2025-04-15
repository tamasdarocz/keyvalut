import 'dart:math';
import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isObscured = true;
  bool _showPasswordOptions = false;
  bool _includeUppercase = false;
  bool _includeLowercase = true;
  bool _includeNumbers = false;
  bool _includeSymbols = false;
  int _passwordLength = 12;

  void _generatePassword() {
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (_includeLowercase) chars += lowercase;
    if (_includeUppercase) chars += uppercase;
    if (_includeNumbers) chars += numbers;
    if (_includeSymbols) chars += symbols;

    if (chars.isEmpty) {
      chars = lowercase; // Default to lowercase if no options are selected
    }

    final Random random = Random();
    String password = '';
    for (int i = 0; i < _passwordLength; i++) {
      password += chars[random.nextInt(chars.length)];
    }

    widget.controller.text = password;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _isObscured,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _showPasswordOptions = !_showPasswordOptions;
                    });
                  },
                ),
              ],
            ),
          ),
          validator: widget.validator,
        ),
        if (_showPasswordOptions) ...[
          const SizedBox(height: 8),
          const Text('Password Generator Options'),
          CheckboxListTile(
            title: const Text('Include Uppercase Letters'),
            value: _includeUppercase,
            onChanged: (value) {
              setState(() {
                _includeUppercase = value!;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Include Lowercase Letters'),
            value: _includeLowercase,
            onChanged: (value) {
              setState(() {
                _includeLowercase = value!;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Include Numbers'),
            value: _includeNumbers,
            onChanged: (value) {
              setState(() {
                _includeNumbers = value!;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Include Symbols'),
            value: _includeSymbols,
            onChanged: (value) {
              setState(() {
                _includeSymbols = value!;
              });
            },
          ),
          Slider(
            value: _passwordLength.toDouble(),
            min: 8,
            max: 32,
            divisions: 24,
            label: _passwordLength.toString(),
            onChanged: (value) {
              setState(() {
                _passwordLength = value.toInt();
              });
            },
          ),
          ElevatedButton(
            onPressed: _generatePassword,
            child: const Text('Generate Password'),
          ),
        ],
      ],
    );
  }
}